package Mojolicious::Plugin::SecurityHeader;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.03';

sub register {
    my ($self, $app, $headers) = @_;

    return if !ref $headers;
    return if 'ARRAY' ne ref $headers;

    my @headers_list = qw(
        Strict-Transport-Security Public-Key-Pins Referrer-Policy 
        X-Content-Type-Options X-Frame-Options X-Xss-Protection
    );

    my %valid_headers;
    @valid_headers{@headers_list} = (1) x @headers_list;

    my %values = (
        'Strict-Transport-Security' => \&check_sts,
        'Referrer-Policy'           => [
             "",
             "no-referrer",
             "no-referrer-when-downgrade",
             "same-origin",
             "origin",
             "strict-origin",
             "origin-when-cross-origin",
             "strict-origin-when-cross-origin",
             "unsafe-url"
         ],
         'X-Content-Type-Options' => ['nosniff'],
         'X-Xss-Protection'       => \&check_xp,
         'X-Frame-Options'        => \&check_fo,
    );

    my %options = (
         'Strict-Transport-Security' => { includeSubDomains => 1, preload => 1 }, 
    );

    my %headers_default = (
        'Referrer-Policy'           => "",
        'Strict-Transport-Security' => "max-age=31536000",
        'X-Content-Type-Options'    => "nosniff",
        'X-Xss-Protection'          => '1; mode=block',
        'X-Frame-Options'           => 'DENY',
    );

    my %security_headers;

    my $last_header;
    my $header_value;

    HEADER:
    for my $header ( @{ $headers || [] } ) {
       if ( $valid_headers{$header} ) {
           if ( $last_header ) {
               $security_headers{$last_header} = $header_value // $headers_default{$last_header};
           }

           $last_header = $header;
       }
       elsif ( $last_header ) {
           $header_value = $header;

           if ( $values{$last_header} ) {
               my $ref = ref $values{$last_header};

               if ( $ref eq 'CODE' ) {
                   $header_value = $values{$last_header}->($header_value // $headers_default{$last_header}, $options{$last_header});
               }
               elsif ( $ref eq 'ARRAY' ) {
                   ($header_value) = grep{ $header_value eq $_ }@{ $values{$last_header} };

                   undef $last_header if !$header_value;
               }
           }
       }
    }

    $security_headers{$last_header} = $header_value // $headers_default{$last_header} if $last_header;

    $app->hook( before_dispatch => sub {
        my $c = shift;

        for my $header_name ( keys %security_headers ) {
            $c->res->headers->header( $header_name => $security_headers{$header_name} );
        }
    });
}

sub check_sts {
    my ($value, $options) = @_;

    my $option = '';

    if ( ref $value ) {
        $option = $value->{opt};
        $value  = $value->{maxage};

        $option = '' if !$options->{$option};
    }

    $option = '; ' . $option if $option;

    return 'max-age=31536000' . $option if $value == -1;
    return if $value < 0;
    return if $value ne int $value;
    return 'max-age=' . $value . $option;
}

sub check_fo {
    my ($value) = @_;

    my %allowed = ('DENY' => 1, 'SAMEORIGIN' => 1);
    
    return 'DENY' if !defined $value;
    return $value if $allowed{$value};
    return if !ref $value;

    return if ref $value && !$value->{'ALLOW-FROM'};
    return 'ALLOW-FROM ' . $value->{'ALLOW-FROM'};
}

sub check_xp {
    my ($value, $options) = @_;

    if ( !ref $value ) {
        return        if $value ne '1' && $value ne '0';
        return $value if $value eq '0' || $value eq '1';
    }

    if ( ref $value && $value->{value} eq '1' ) {
       my $option = '';

       if ( $value->{mode} && $value->{mode} eq 'block' ) {
           $option = 'mode=block';
       }
       elsif ( $value->{report} ) {
           $option = 'report=' . $value->{report};
       }

       $value = '1; ' . $option if $option;
       return  $value;
    }

    return;
}

sub is_string {
    my ($value) = @_;

    return defined $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::SecurityHeader

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('SecurityHeader');

  # define which security headers should be used
  $self->plugin('SecurityHeader' => [
      'Strict-Transport-Security' => -1,
      'X-Xss-Protection',
      'X-Content-Type-Options' => 'nosniff',
  ]);

  # Mojolicious::Lite
  plugin 'SecurityHeader';

=head1 DESCRIPTION

L<Mojolicious::Plugin::SecurityHeader> is a L<Mojolicious> plugin.

=head1 NAME

Mojolicious::Plugin::SecurityHeader - Mojolicious Plugin

=head1 SECURITY HEADER

=over 4

=item * Strict-Transport-Security

=item * Public-Key-Pins

=item * Referrer-Policy 

=item * X-Content-Type-Options

=item * X-Frame-Options

=item * X-Xss-Protection

=back

=head1 METHODS

L<Mojolicious::Plugin::SecurityHeader> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
