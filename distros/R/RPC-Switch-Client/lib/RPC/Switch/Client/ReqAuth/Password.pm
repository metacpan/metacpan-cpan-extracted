package RPC::Switch::Client::ReqAuth::Password;

use Mojo::Base 'RPC::Switch::Client::ReqAuth';

use Carp qw(croak);

has [qw(user password)];

sub new {
    my $self = shift->SUPER::new(@_);
    croak('missing argument user') unless $self->user;
    croak('missing argument password') unless $self->password;
    return $self;
}

=pod

Simplistic example of adding a username/password combo as request
authentication

=cut

1;
