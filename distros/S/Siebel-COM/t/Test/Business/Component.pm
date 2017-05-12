package Test::Business::Component;
use base 'Test::Class';
use Test::Most;
use Test::Moose;
use Siebel::COM::Business::Component;

sub class { 'Siebel::COM::Business::Component' }
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
        qw(activate_field get_field_value clear_query set_search_expr set_search_spec query first_record next_record set_field_value write_record set_view_mode)
    );

}

1;
