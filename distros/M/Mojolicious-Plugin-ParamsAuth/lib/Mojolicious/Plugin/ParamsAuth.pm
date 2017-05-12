package Mojolicious::Plugin::ParamsAuth;

use strict;
use warnings;

our $VERSION = '0.03';

use base 'Mojolicious::Plugin';

sub register {
    my ($plugin, $app) = @_;

    $app->renderer->add_helper(
        params_auth => sub {
            my $self       = shift;
            my $callback   = pop;
            my @param_keys = @_;

            my $params = $self->req->params->to_hash;

            # Specified parameters not in URL
            return if grep !defined $params->{$_}, @param_keys;

            # Use only first value of each param
            for (@param_keys) {
                $params->{$_} = $params->{$_}->[0]
                  if ref $params->{$_} eq 'ARRAY';
            }

            # Callback
            return 1 if $callback->(@$params{@param_keys});

            # Failed
            $self->res->code(401);

            return;
        }
    );
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::ParamsAuth - URL Parameters Auth Helper

=head1 DESCRIPTION

L<Mojolicous::Plugin::ParamsAuth> is a helper for authenticating using url parameters

=head1 USAGE

    # Request:
    GET /?userinput=username&passinput=password


    use Mojolicious::Lite;

    plugin 'params_auth';

    get '/' => sub {
        my $self = shift;

        return $self->render_text('ok')
          if $self->params_auth(userinput => passinput =>
              sub { return 1 if "@_" eq 'username password' });
    };

    app->start;

Any number of parameters can be specified:

    $self->params_auth( one => two => three => four => sub { } )

The subroutine callback receives form values as the parameter list.

=head1 METHODS

L<Mojolicious::Plugin::ParamsAuth> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

Register condition in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>

=head1 DEVELOPMENT

L<http://github.com/tempire/mojolicious-plugin-paramsauth>

=head1 VERSION

0.03

=head1 AUTHOR

Glen Hinkle tempire@cpan.org

=cut
