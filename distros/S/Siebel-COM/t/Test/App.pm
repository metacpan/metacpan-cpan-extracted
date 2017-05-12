package Test::App;
use base qw(Test::Class);
use Test::Most;
use Test::Moose;
use Siebel::COM::App;

sub class { 'Siebel::COM::App' }
sub role  { 'Siebel::COM' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class();
}

sub attributes : Test(4) {

    my $self = shift;

    has_attribute_ok( $self->class(), 'user' );
    has_attribute_ok( $self->class(), 'password' );
    has_attribute_ok( $self->class(), 'ole_class' );
    has_attribute_ok( $self->class(), '_ole' );

}

sub roles : Test(1) {

    my $self = shift;

    does_ok( $self->class(), $self->role() );

}

sub can_methods : Test(1) {

    my $self = shift;

    can_ok( $self->class(), qw(login get_bus_object get_last_error) );

}

1;
