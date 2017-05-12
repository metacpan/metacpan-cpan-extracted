package Test::App::DataServer;
use base qw(Test::App);
use Test::Most;
use Test::Moose;
use Siebel::COM::App::DataServer;

sub class { 'Siebel::COM::App::DataServer' }
sub role  { 'Siebel::COM' }

sub startup : Tests(startup => 1) {

    my $test = shift;
    use_ok $test->class();
}

sub attributes : Test(3) {

    my $self = shift;

    has_attribute_ok( $self->class(), 'ole_class' );
    has_attribute_ok( $self->class(), 'data_source' );
    has_attribute_ok( $self->class(), 'cfg' );

}

sub roles : Test(1) {

    my $self = shift;

    does_ok( $self->class(), $self->role() );

}

sub can_methods : Test(1) {

	my $self = shift;

	can_ok($self->class(), qw(_error get_return_code get_app_def load_objects));

}

1;
