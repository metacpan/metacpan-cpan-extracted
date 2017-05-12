package Test::Business::Object::DataServer;
use base 'Test::Business::Object';
use Test::Moose;
use Siebel::COM::Business::Object::DataServer;

sub class { 'Siebel::COM::Business::Object::DataServer' }
sub role2 { 'Siebel::COM::Exception::DataServer' }

sub roles : Test(2) {

    my $self = shift;

    does_ok( $self->class(), $self->role() );
    does_ok( $self->class(), $self->role2() );

}

1;
