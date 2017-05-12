package Mojolicious::Plugin::HTMLLint;
use Mojo::Base 'Mojolicious::Plugin';

use HTML::Lint;

use v5.10; # earliest occurance of feature
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

our $VERSION = '0.06';

sub register {
    my ( $self, $app, $conf ) = @_;
    $conf ||= {};

    my $skip = delete $conf->{skip} // [];

    # On error callback
    my $on_error;
    if ( $conf->{on_error} && ref($conf->{on_error}) eq 'CODE' ) {
        $on_error = delete $conf->{on_error};
    } else {
        $on_error = sub { $app->log->warn($_[1]) };
    }

    $app->hook(
        'after_dispatch' => sub {
            my ( $c ) = @_;
            my $res = $c->res;

            # Only successful response
            return if $res->code !~ m/^2/;

            ## Only html response
            return unless $res->headers->content_type;
            return if $res->headers->content_type !~ /html/;

            my $lint = HTML::Lint->new(%$conf);
            $lint->parse($res->body);
            $lint->eof();

            foreach my $error ( $lint->errors ) {
                my $err_msg = $error->as_string();
                next if $err_msg ~~ $skip;

                $on_error->( $c, "HTMLLint:" . $error->as_string );
            }
        } );
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::HTMLLint - HTML::Lint support for Mojolicious

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('HTMLLint');

  # In development mode only
  $self->plugin('HTMLLint') if $self->mode eq 'development';

  # Mojolicious (skip errors that contain "placeholder" string)
  $self->plugin( 'HTMLLint', { skip => [ qr/placeholder/ ] } );

  # Mojolicious::Lite
  plugin 'HTMLLint';

=head1 DESCRIPTION

L<Mojolicious::Plugin::HTMLLint> - allows you to validate HTML rendered by your application. The plugin uses HTML::Lint for validation. Errors will appear in Mojolicious log.

=head1 CONFIG

Config will be passed to HTML::Lint->new();
For supported options see L<HTML::Lint>

=head2 C<skip>

  $app->plugin('HTMLLint', { skip => [ qr//, qr// ]} );

This options says what message not to show.   This option plugin processes by its own(without passing to HTML::Lint).

=head2 C<on_error>

You can pass custom error handling callback. For example

    $self->plugin('HTMLLint', on_error => sub {
        my ($c, $mes) = @_;
        $c->render_text($mes);
    });

This option plugin processes by its own(without passing to HTML::Lint).

=head1 AUTHOR

Viktor Turskyi <koorchik@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/koorchik/Mojolicious-Plugin-HTMLLint>

=head1 SEE ALSO

L<Mojolicious>, L<HTML::Lint>, L<HTML::Tidy>

=head1 LICENSE

Same as Perl 5.

=cut
