package Test::Business::Component::DataServer;
use base 'Test::Business::Component';
use Siebel::COM::Business::Component::DataServer;
use Test::Moose;

sub class { 'Siebel::COM::Business::Component::DataServer' }
sub role2 { 'Siebel::COM::Exception::DataServer' }

sub roles : Test(2) {

    my $self = shift;

    does_ok( $self->class(), $self->role() );
    does_ok( $self->class(), $self->role2() );

}

1;
