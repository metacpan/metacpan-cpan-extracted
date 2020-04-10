use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Test::Ability

=cut

=abstract

Property-Based Testing for Perl 5

=cut

=includes

method: array
method: array_object
method: choose
method: code
method: code_object
method: date
method: datetime
method: hash
method: hash_object
method: maybe
method: number
method: number_object
method: object
method: regexp
method: regexp_object
method: scalar
method: scalar_object
method: string
method: string_object
method: test
method: time
method: undef
method: undef_object
method: word
method: words

=cut

=synopsis

  package main;

  use Test::Ability;

  my $t = Test::Ability->new;

=cut

=libraries

Types::Standard

=cut

=integrates

Data::Object::Role::Buildable
Data::Object::Role::Stashable

=cut

=attributes

arguments: ro, opt, ArrayRef
invocant: ro, opt, Object

=cut

=description

This package provides methods for generating values and test-cases, providing a
framework for performing property-based testing.

=cut

=scenario stash

The package provides a stash object for default and user-defined value
generators. You can easily extend the default generators by adding your own.
Once defined, custom generators can be specified in the I<gen-spec> (generator
specification) arrayref provided to the C<test> method (and others).

=example stash

  # given: synopsis

  $t->stash(direction => sub {
    my ($self) = @_;

    {
      move => ('forward', 'reverse')[rand(1)],
      time => time
    }
  });

=cut

=method array

The array method returns a random array reference.

=signature array

array(Maybe[Int] $min, Maybe[Int] $max) : ArrayRef

=example-1 array

  # given: synopsis

  $t->array;

=cut

=method array_object

The array_object method returns a random array object.

=signature array_object

array_object(Maybe[Int] $min, Maybe[Int] $max) : Object

=example-1 array_object

  # given: synopsis

  $t->array_object;

=cut

=method choose

The choose method returns a random value from the set of specified generators.

=signature choose

choose(ArrayRef[ArrayRef] $args) : Any

=example-1 choose

  # given: synopsis

  $t->choose([['datetime'], ['words', [2,3]]]);

=cut

=method code

The code method returns a random code reference.

=signature code

code(Maybe[Int] $min, Maybe[Int] $max) : CodeRef

=example-1 code

  # given: synopsis

  $t->code;

=cut

=method code_object

The code_object method returns a random code object.

=signature code_object

code_object(Maybe[Int] $min, Maybe[Int] $max) : Object

=example-1 code_object

  # given: synopsis

  $t->code_object;

=cut

=method date

The date method returns a random date.

=signature date

date(Maybe[Str] $min, Maybe[Str] $max) : Str

=example-1 date

  # given: synopsis

  $t->date;

=cut

=method datetime

The datetime method returns a random date and time.

=signature datetime

datetime(Maybe[Str] $min, Maybe[Str] $max) : Str

=example-1 datetime

  # given: synopsis

  $t->datetime;

=cut

=method hash

The hash method returns a random hash reference.

=signature hash

hash(Maybe[Int] $min, Maybe[Int] $max) : HashRef

=example-1 hash

  # given: synopsis

  $t->hash;

=cut

=method hash_object

The hash_object method returns a random hash object.

=signature hash_object

hash_object(Maybe[Int] $min, Maybe[Int] $max) : Object

=example-1 hash_object

  # given: synopsis

  $t->hash_object;

=cut

=method maybe

The maybe method returns a random choice using the choose method, or the
undefined value.

=signature maybe

maybe(ArrayRef[ArrayRef] $args) : Any

=example-1 maybe

  # given: synopsis

  $t->maybe([['date'], ['time']]);

=cut

=method number

The number method returns a random number.

=signature number

number(Maybe[Int] $min, Maybe[Int] $max) : Int

=example-1 number

  # given: synopsis

  $t->number;

=cut

=method number_object

The number_object method returns a random number object.

=signature number_object

number_object(Maybe[Int] $min, Maybe[Int] $max) : Object

=example-1 number_object

  # given: synopsis

  $t->number_object;

=cut

=method object

The object method returns a random object.

=signature object

object() : Object

=example-1 object

  # given: synopsis

  $t->object;

=cut

=method regexp

The regexp method returns a random regexp.

=signature regexp

regexp(Maybe[Str] $exp) : RegexpRef

=example-1 regexp

  # given: synopsis

  $t->regexp;

=cut

=method regexp_object

The regexp_object method returns a random regexp object.

=signature regexp_object

regexp_object(Maybe[Str] $exp) : Object

=example-1 regexp_object

  # given: synopsis

  $t->regexp_object;

=cut

=method scalar

The scalar method returns a random scalar reference.

=signature scalar

scalar(Maybe[Int] $min, Maybe[Int] $max) : Ref

=example-1 scalar

  # given: synopsis

  $t->scalar;

=cut

=method scalar_object

The scalar_object method returns a random scalar object.

=signature scalar_object

scalar_object(Maybe[Int] $min, Maybe[Int] $max) : Object

=example-1 scalar_object

  # given: synopsis

  $t->scalar_object;

=cut

=method string

The string method returns a random string.

=signature string

string(Maybe[Int] $min, Maybe[Int] $max) : Str

=example-1 string

  # given: synopsis

  $t->string;

=cut

=method string_object

The string_object method returns a random string object.

=signature string_object

string_object(Maybe[Int] $min, Maybe[Int] $max) : Object

=example-1 string_object

  # given: synopsis

  $t->string_object;

=cut

=method test

The test method generates subtests using L<Test::More/subtest>, optionally
generating and passing random values to each iteration as well as a
L<Data::Object::Try> object for easy execution of callbacks and interception of
exceptions. This callback expected should have the signature C<($tryable,
@arguments)> where C<@arguments> gets assigned the generated values in the order
specified. The callback must return the C<$tryable> object, which is called for
you automatically, executing the subtest logic you've implemented.

=signature test

test(Str $name, Int $cycles, ArrayRef[ArrayRef] $spec, CodeRef $callback) : Undef

=example-1 test

  # given: synopsis

  # use Test::More;

  sub is_an_adult {
    my ($age) = @_;

    $age >= 18;
  }

  $t->test('is_an_adult', 100, [['number', [10, 30]]], sub {
    my ($tryable, $age) = @_;

    $tryable->call(sub {
      if ($age >= 18) {
        ok is_an_adult($age),
          "age is $age, is an adult";
      }
      else {
        ok !is_an_adult($age),
          "age is $age, is not an adult";
      }
    });

    $tryable
  });

=cut

=method time

The time method returns a random time.

=signature time

time(Maybe[Str] $min, Maybe[Str] $max) : Str

=example-1 time

  # given: synopsis

  $t->time;

=cut

=method undef

The undef method returns the undefined value.

=signature undef

undef() : Undef

=example-1 undef

  # given: synopsis

  $t->undef;

=cut

=method undef_object

The undef_object method returns the undefined value as an object.

=signature undef_object

undef_object() : Object

=example-1 undef_object

  # given: synopsis

  $t->undef_object;

=cut

=method word

The word method returns a random word.

=signature word

word() : Str

=example-1 word

  # given: synopsis

  $t->word;

=cut

=method words

The words method returns random words.

=signature words

words(Maybe[Int] $min, Maybe[Int] $max) : Str

=example-1 words

  # given: synopsis

  $t->words;

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'array', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'array_object', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'choose', 'method', fun($tryable) {
  my $result;

  my $words = 0;
  my $dates = 0;

  for (1..100) {
    ok $result = $tryable->result, 'got choice';

    $dates++ if $result =~ /\d/;
    $words++ if $result !~ /\d/;
  }

  ok $words, 'choice produces words';
  ok $dates, 'choice produces dates';

  $result
});

$subs->example(-1, 'code', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'code_object', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'date', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'datetime', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'hash', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'hash_object', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'maybe', 'method', fun($tryable) {
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'number', 'method', fun($tryable) {
  my $result = $tryable->result;

  $result
});

$subs->example(-1, 'number_object', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'object', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'regexp', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'regexp_object', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'scalar', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'scalar_object', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'string', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'string_object', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'test', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'time', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'undef', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'undef_object', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'word', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'words', 'method', fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

ok 1 and done_testing;
