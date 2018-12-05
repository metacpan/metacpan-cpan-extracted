package Mojolicious::Plugin::SecurityHeader;

# ABSTRACT: Mojolicious Plugin

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.07';

sub register {
    my ($self, $app, $headers) = @_;

    return if !$headers;
    return if !ref $headers;
    return if 'ARRAY' ne ref $headers;

    my @headers_list = qw(
        Strict-Transport-Security Referrer-Policy 
        X-Content-Type-Options X-Frame-Options X-Xss-Protection
        Content-Security-Policy Access-Control-Allow-Origin
        Access-Control-Expose-Headers Access-Control-Max-Age
        Access-Control-Allow-Credentials Access-Control-Allow-Methods
        Access-Control-Allow-Headers
    );

    my %valid_headers;
    @valid_headers{@headers_list} = (1) x @headers_list;

    my %values = (
        'X-Content-Type-Options'           => 'nosniff',
        'X-Xss-Protection'                 => \&_check_xp,
        'X-Frame-Options'                  => \&_check_fo,
        'Content-Security-Policy'          => \&_check_csp,
        'Access-Control-Allow-Methods'     => \&_check_methods,
        'Access-Control-Allow-Origin'      => \&_is_url,
        'Access-Control-Allow-Headers'     => \&_check_list,
        'Access-Control-Expose-Headers'    => \&_check_list,
        'Access-Control-Max-Age'           => \&_is_int,
        'Access-Control-Allow-Credentials' => 'true',
        'Strict-Transport-Security'        => \&_check_sts,
        'Referrer-Policy'                  => [
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
    );

    my %options = (
         'Strict-Transport-Security' => { includeSubDomains => 1, preload => 1 }, 
    );

    my %headers_default = (
        'Referrer-Policy'                  => "",
        'Strict-Transport-Security'        => "max-age=31536000",
        'X-Content-Type-Options'           => "nosniff",
        'X-Xss-Protection'                 => '1; mode=block',
        'X-Frame-Options'                  => 'DENY',
        'Content-Security-Policy'          => "default-src 'self'",
        'Access-Control-Allow-Origin'      => '*',
        'Access-Control-Allow-Credentials' => 'true',
    );

    my %security_headers;

    my $last_header;
    my $header_value;

    HEADER:
    for my $header ( @{ $headers } ) {
        next HEADER if !defined $header;

        if ( $valid_headers{$header} ) {
            if ( $last_header ) {
                $security_headers{$last_header} = $header_value // $headers_default{$last_header};
            }

            undef $header_value;
            $last_header = $header;
        }
        elsif ( $last_header ) {
            $header_value = $header;

            my $ref = ref $values{$last_header};

            if ( $ref eq 'CODE' ) {
                $header_value = $values{$last_header}->($header_value, $options{$last_header});

                undef $last_header if !defined $header_value;
            }
            elsif ( $ref eq 'ARRAY' ) {
                ($header_value) = grep{ $header_value eq $_ }@{ $values{$last_header} };

                undef $last_header if !$header_value;
            }
            else {
                undef $last_header if $header_value ne $values{$last_header};
            }
        }
    }

    $security_headers{$last_header} = $header_value // $headers_default{$last_header} if $last_header;

    $app->hook( before_dispatch => sub {
        my $c = shift;

        HEADER_NAME:
        for my $header_name ( keys %security_headers ) {
            next HEADER_NAME if !defined $security_headers{$header_name};
            $c->res->headers->header( $header_name => $security_headers{$header_name} );
        }
    });
}

sub _is_int {
    my ($value, $options) = @_;

    return if !defined $value;
    return if ref $value;
    return if $value !~ m{\A[0-9]+\z};
    return $value;
}

sub _check_methods {
    my ($value, $options) = @_;

    return if !defined $value;

    my @methods = qw(GET DELETE POST PATCH OPTIONS HEAD CONNECT TRACE PUT);
    if ( !ref $value && $value eq '*' ) {
        return join ', ', @methods;
    }

    return uc $value if !ref $value;
    return           if 'ARRAY' ne ref $value;

    my %allowed = map{ $_ => 1 }@methods;
    my $return = join ', ', map{ defined $_ && $allowed{uc $_} ? uc $_ : () }@{$value};

    return $return || undef;
}

sub _check_list {
    my ($value, $options) = @_;

    return        if !defined $value;
    return $value if !ref $value;
    return        if 'ARRAY' ne ref $value;

    my $return = join ', ', @{$value};

    return $return || undef;
}

sub _is_url {
    my ($value, $options) = @_;

    return     if !defined $value;
    return     if ref $value;
    return '*' if $value eq '*';

    return $value if $value =~ m{\Ahttps?://\S+\z}xms;
    return;
}

sub _check_csp {
    my ($value, $options) = @_;

    my $option = '';

    return $option if !ref $value;
    return $option if 'HASH' ne ref $value;

    for my $key ( reverse sort keys %{ $value } ) {
        my $tmp_value = $value->{$key};
        $option .= sprintf "%s-src %s; ", $key, $tmp_value;
    }

    return $option;
}

sub _check_sts {
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

sub _check_fo {
    my ($value) = @_;

    my %allowed = ('DENY' => 1, 'SAMEORIGIN' => 1);
    
    return 'DENY' if !defined $value;
    return $value if $allowed{$value};
    return if !ref $value;
    return if 'HASH' ne ref $value;

    return if !$value->{'ALLOW-FROM'};
    return 'ALLOW-FROM ' . $value->{'ALLOW-FROM'};
}

sub _check_xp {
    my ($value, $options) = @_;

    if ( !ref $value ) {
        $value //= '';

        return if $value ne '1' && $value ne '0';
        return $value;
    }

    return if 'HASH' ne ref $value;
    return if !exists $value->{value} || $value->{value} ne '1';

    my $option = '';

    if ( $value->{mode} && $value->{mode} eq 'block' ) {
        $option = 'mode=block';
    }
    elsif ( $value->{report} ) {
        $option = 'report=' . $value->{report};
    }

    $value  = '1; ';
    $value .= $option if $option;

    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::SecurityHeader - Mojolicious Plugin

=head1 VERSION

version 0.07

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

=head1 SECURITY HEADER

=over 4

=item * Strict-Transport-Security

=item * Public-Key-Pins

=item * Referrer-Policy 

=item * X-Content-Type-Options

=item * X-Frame-Options

=item * X-Xss-Protection

=item * Access-Control-Allow-Origin

=item * Access-Control-Expose-Headers

=item * Access-Control-Max-Age

=item * Access-Control-Allow-Credentials

=item * Access-Control-Allow-Methods

=item * Access-Control-Allow-Headers

=back

=head1 METHODS

L<Mojolicious::Plugin::SecurityHeader> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 CORS SUPPORT

Since version 0.06 this plugin also supports L<CORS|https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS>.
There's already L<Mojolicious::Plugin::CORS>, but unlike that module, with the C<SecurityHeader> plugin all
CORS related headers are configurable.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>. L<Mojolicious::Plugin::CORS>

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
