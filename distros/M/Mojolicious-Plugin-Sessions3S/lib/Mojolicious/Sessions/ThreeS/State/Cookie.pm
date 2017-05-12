package Mojolicious::Sessions::ThreeS::State::Cookie;
$Mojolicious::Sessions::ThreeS::State::Cookie::VERSION = '0.004';
use Mojo::Base qw/Mojolicious::Sessions::ThreeS::State/;

=head1 NAME

Mojolicious::Sessions::ThreeS::State::Cookie - A cookie based session ID manager

=cut

has 'cookie_domain';
has 'cookie_name' => 'sessions3sid';
has 'cookie_path' => '/';

has 'http_only' => 1;
has 'secure';

=head2 cookie_domain

=head2 cookie_name

Defaults to C<sessions3sid>

=head2 cookie_path

Defaults to C<cookie_path>

=head2 http_only

Defautls to C<1>

=head2 secure

Defaults to C<undef>

=head2 get_session_id

See L<Mojolicious::Sessions::ThreeS::State>

=cut

sub get_session_id{
    my ($self, $controller) = @_;
    return $controller->signed_cookie( $self->cookie_name() );
}

=head2 set_session_id

See L<Mojolicious::Sessions::ThreeS::State>

=cut

sub set_session_id{
    my ( $self, $controller, $session_id , $opts ) = @_;
    $opts //= {};
    $controller->signed_cookie(
        $self->cookie_name,
        $session_id,
        {
            domain => scalar( $self->cookie_domain ),
            ( $opts->{expires} ? ( expires => $opts->{expires} ) : () ),
            httponly => $self->http_only,
            path => $self->cookie_path(),
            secure => $self->secure()
        }
    );
}


1;
