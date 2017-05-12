package Net::Google::DataAPI::Auth::AuthSub;
use Any::Moose;
with 'Net::Google::DataAPI::Role::Auth';
use Net::Google::AuthSub;
use URI;
our $VERSION = '0.03';

has authsub => (
    is => 'ro',
    isa => 'Net::Google::AuthSub',
    required => 1,
);

sub sign_request {
    my ($self, $req) = @_;
    $self->authsub->{_compat}->{uncuddled_auth} = 1;
    $req->header($self->authsub->auth_params);
    return $req;
}

__PACKAGE__->meta->make_immutable;

no Any::Moose;

1;
