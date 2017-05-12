package Net::OATH::Server::Lite::DataHandler;

use strict;
use warnings;

=head1 NAME

Net::OATH::Server::Lite::DataHandler - Base class that specifies interface for data handler for your server.

=head1 DESCRIPTION

This connects Net::OATH::Server::Lite library to your service.
This specifies an interface to handle data stored in your application. 
You must inherit this and implement the subroutines according to the interface contract.

=head1 SYNOPSIS

    package YourDataHandler;
    use strict;
    use warnings;

    use parent 'Net::OATH::Server::Lite::DataHandler';

=cut

sub new {
    my ($class, %args) = @_;
    my $self = bless { request => undef, %args }, $class;
    $self->init;
    $self;
}

=head1 METHODS

=head2 init

This method can be implemented to initialize your subclass.

=cut

sub init {
    my $self = shift;
    # template method
}

=head1 INTERFACES

=head2 request

Returns <Plack::Request> object.

=cut

sub request {
    my $self = shift;
    return $self->{request};
}

=head2 create_id

Returns identifier of new user object.

=cut

sub create_id {
    my ($self) = @_;
    die "abstract method";
}

=head2 create_secret

Returns raw secret of new user object.

=cut

sub create_secret {
    my ($self) = @_;
    die "abstract method";
}

# For Register

=head2 insert_user( $user )

Inserts new user object to your datastore and returnes result as a boolean.

=cut

sub insert_user {
    my ($self, $user) = @_;
    die "abstract method";
}

# For Login and User Object

=head2 select_user( $id )

Return user object which is found by $id.

=cut

sub select_user {
    my ($self, $id) = @_;
    die "abstract method";
}

# For User Object

=head2 update_user( $user )

Updates user object on your datastore and returnes result as a boolean.

=cut

sub update_user {
    my ($self, $user) = @_;
    die "abstract method";
}

=head2 delete_user( $id )

Deletes user object which is found by $id on your datastore and returnes result as a boolean.

=cut

sub delete_user {
    my ($self, $id) = @_;
    die "abstract method";
}

1;
