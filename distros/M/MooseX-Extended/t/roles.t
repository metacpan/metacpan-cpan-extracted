#!/usr/bin/env perl

use lib 'lib', 't/lib';
use Test::Most;

pass 'this';
use Not::Corinna;
pass 'that';
subtest 'miscellaneous features' => sub {
    SKIP: {
        skip "Classes cannot be immutable while running under the debugger", 1 if $^P;
        ok +Not::Corinna->meta->is_immutable,
          'We should be able to define an immutable class';
    }
    is mro::get_mro('Not::Corinna'), 'c3', "Our class's mro should be c3";
};

subtest 'no title' => sub {
    my $person = Not::Corinna->new( name => 'Ovid', );
    is $person->name, 'Ovid', 'name should be correct';
    ok !defined $person->title, '... and no title';
    cmp_ok $person->created, '>', 0, '... and a sane default for created';
    ok !$person->can('sum'), 'subroutines have been removed from the namespace';
    is $person->add( [qw/1 3 5 6/] ), 15, 'Our add() method should work';
};

subtest 'has title' => sub {
    my $person = Not::Corinna->new( name => 'Ovid', );
    my $doctor = Not::Corinna->new( name => 'Smith', title => 'Dr.' );
    is $doctor->name, 'Dr. Smith', 'Titles should show up correctly';
    cmp_ok $doctor->created, '>=', $person->created,
      '... and their created date should be correct';
};

subtest 'exceptions' => sub {
    my $person = Not::Corinna->new( name => 'Ovid', );

    throws_ok { $person->title('Mr.') }
    'Moose::Exception::CannotAssignValueToReadOnlyAccessor',
      'param() is read-only by default';

    throws_ok { $person->created(11111) }
    'Moose::Exception::CannotAssignValueToReadOnlyAccessor',
      'field() is read-only by default';

    throws_ok { $person->add( [] ) }
    'Error::TypeTiny::Assertion',
      'passing an empty array reference should be fatal';

    throws_ok { Not::Corinna->new( name => 'Ovid', created => 1 ) }
    'Moose::Exception',
      'Attributes not defined as `param` are illegal in the constructor';
};

done_testing;
