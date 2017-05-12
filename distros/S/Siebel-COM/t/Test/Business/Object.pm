package Test::Business::Object;
use base 'Test::Class';
use Test::Most;
use Test::Moose;
use Siebel::COM::Business::Object;

sub class { 'Siebel::COM::Business::Object' }
sub role { 'Siebel::COM' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class();
}

sub roles : Test(1) {

    my $self = shift;

    does_ok( $self->class(), $self->role() );

}

sub can_methods : Test(1) {

    my $self = shift;

    can_ok( $self->class(),
        qw(get_bus_comp)
    );

}

1;
