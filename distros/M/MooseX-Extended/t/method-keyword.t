#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests
  name    => 'method',
  version => v5.26.0,
  module  => ['Function::Parameters'];

package My::Names {
    use MooseX::Extended types => [qw(compile Num NonEmptyStr Str PositiveInt ArrayRef)],
      includes                 => ['method'];
    use List::Util 'sum';

    param _name => ( isa => NonEmptyStr, init_arg => 'name' );
    param title => ( isa => Str, required => 0, predicate => 1 );
    param extra => ( is  => 'rw', isa => Str, required => 0 );

    field created => ( isa => PositiveInt, default => sub {time} );
    field updated => ( is => 'rw', isa => PositiveInt, writer => 1, builder => sub {time} );

    method name() {
        my $title = $self->title;
        my $name  = $self->_name;
        return $title ? "$title $name" : $name;
    }

    method add($args) {
        state $check = compile( ArrayRef [ Num, 1 ] );
        ($args) = $check->($args);
        return sum( $args->@* );
    }
}

subtest 'miscellaneous features' => sub {
    SKIP: {
        skip "Classes cannot be immutable while running under the debugger", 1 if $^P;
        ok +My::Names->meta->is_immutable,
          'We should be able to define an immutable class';
    }
    is mro::get_mro('My::Names'), 'c3', "Our class's mro should be c3";
};

subtest 'no title' => sub {
    my $person = My::Names->new( name => 'Ovid', );
    is $person->name, 'Ovid', 'name should be correct';
    ok !defined $person->title, '... and no title';
    cmp_ok $person->created, '>', 0, '... and a sane default for created';
    ok !$person->can('sum'), 'subroutines have been removed from the namespace';
    is $person->add( [qw/1 3 5 6/] ), 15, 'Our add() method should work';
    ok !$person->has_title, 'Our predicate shortcut should work';

    ok !defined $person->extra, 'optional params start our as default';
    $person->extra('foo');
    is $person->extra, 'foo', 'We can declare is => "rw" for params';

    my $updated = $person->updated;
    $person->set_updated( $updated + 1 );
    is $person->updated, $updated + 1, 'We should be able to update is => "rw" fields';
    ok $person->can('_build_updated'), 'Coderef builder was installed as method';
};

subtest 'has title' => sub {
    my $person = My::Names->new( name => 'Ovid', );
    my $doctor = My::Names->new( name => 'Smith', title => 'Dr.' );
    is $doctor->name, 'Dr. Smith', 'Titles should show up correctly';
    cmp_ok $doctor->created, '>=', $person->created,
      '... and their created date should be correct';
    ok $doctor->has_title, 'Our predicate shortcut should work';
};

done_testing;
