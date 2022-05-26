#!/usr/bin/env perl

use lib 'lib';
use Test::Most;

package My::Names {
    use MooseX::Extended excludes => [qw/ StrictConstructor c3 /],
      types                       => [qw(compile Num NonEmptyStr Str PositiveInt ArrayRef)];
    use List::Util 'sum';

    param _name => ( isa => NonEmptyStr, init_arg => 'name' );
    param title => ( isa => Str, required => 0, predicate => 1 );
    field created => ( isa => PositiveInt, default => sub {time} );

    sub name ($self) {
        my $title = $self->title;
        my $name  = $self->_name;
        return $title ? "$title $name" : $name;
    }

    sub add ( $self, $args ) {
        state $check = compile( ArrayRef [ Num, 1 ] );
        ($args) = $check->($args);
        return sum( $args->@* );
    }

    sub warnit ($self) {
        carp("this is a warning");
    }
}

subtest 'miscellaneous features' => sub {
    ok +My::Names->meta->is_immutable,
      'We should be able to define an immutable class';
    isnt mro::get_mro('My::Names'), 'c3', "... but we can exclude the C3 mro if we want";

    ok my $instance = My::Names->new(
        name              => 'Bob',
        unknown_attribute => 'foo',
      ),
      '... and our class does not use MooseX::StrictConstructor';
    ok !$instance->can('unknown_attribute'),   '... and those arguments get ignored';
    ok !exists $instance->{unknown_attribute}, '... and are not stored internally';
};

subtest 'no title' => sub {
    my $person = My::Names->new( name => 'Ovid', );
    is $person->name, 'Ovid', 'name should be correct';
    ok !defined $person->title, '... and no title';
    cmp_ok $person->created, '>', 0, '... and a sane default for created';
    ok !$person->can('sum'), 'subroutines have been removed from the namespace';
    is $person->add( [qw/1 3 5 6/] ), 15, 'Our add() method should work';
    ok !$person->has_title, 'Our predicate shortcut should work';
};

subtest 'has title' => sub {
    my $person = My::Names->new( name => 'Ovid', );
    my $doctor = My::Names->new( name => 'Smith', title => 'Dr.' );
    is $doctor->name, 'Dr. Smith', 'Titles should show up correctly';
    cmp_ok $doctor->created, '>=', $person->created,
      '... and their created date should be correct';
    ok $doctor->has_title, 'Our predicate shortcut should work';
};

subtest 'exceptions' => sub {
    my $person = My::Names->new( name => 'Ovid', );

    throws_ok { $person->title('Mr.') }
    'Moose::Exception::CannotAssignValueToReadOnlyAccessor',
      'param() is read-only by default';

    throws_ok { $person->created(11111) }
    'Moose::Exception::CannotAssignValueToReadOnlyAccessor',
      'field() is read-only by default';

    throws_ok { $person->add( [] ) }
    'Error::TypeTiny::Assertion',
      'passing an empty array reference should be fatal';
};

done_testing;
