package Test::App::DataControl;
use base qw(Test::App);
use Test::Most;
use Test::Moose;
use Siebel::COM::App::DataControl;

sub class { 'Siebel::COM::App::DataControl' }
sub role  { 'Siebel::COM' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class();
}

sub attributes : Test(9) {

    my $self = shift;

    has_attribute_ok( $self->class(), 'host' );
    has_attribute_ok( $self->class(), 'enterprise' );
    has_attribute_ok( $self->class(), 'lang' );
    has_attribute_ok( $self->class(), 'aom' );
    has_attribute_ok( $self->class(), 'transport' );
    has_attribute_ok( $self->class(), 'encryption' );
    has_attribute_ok( $self->class(), 'compression' );
    has_attribute_ok( $self->class(), 'connected' );
    has_attribute_ok( $self->class(), 'ole_class' );

}

sub can_methods : Test(1) {

	my $self = shift;

	can_ok($self->class(), qw(_error get_conn_str logoff));

}

1;
