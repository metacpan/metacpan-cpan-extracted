package Mock::MonkeyPatch;

use strict;
use warnings;

our $VERSION = '1.03';
$VERSION = eval $VERSION;

use Carp ();
use Scalar::Util ();
use Sub::Util 1.40 ();

sub ORIGINAL;

{
  no strict 'refs';

  sub _defined { defined &{$_[0]} }
  sub _patch {
    no warnings 'redefine';
    my $p = prototype \&{$_[0]};
    if (defined $p) {
      Sub::Util::set_prototype($p, $_[1]);
    }
    *{$_[0]} = $_[1];
  }
}

sub arguments {
  my ($self, $occurance) = @_;
  $occurance = 0 unless defined $occurance;
  return $self->{arguments}[$occurance];
}

sub called { scalar @{$_[0]{arguments}} }

sub method_arguments {
  my ($self, $occurance, $type) = @_;
  return undef
    unless my $args = $self->arguments($occurance);
  my @args = @$args; # copy
  my $inst = shift @args;
  if ($type) {
    return undef
      unless $inst->isa($type);
  }
  return \@args;
}

sub patch {
  my ($class, $symbol, $sub, $opts) = @_;
  $opts ||= {};

  $symbol =~ s/^&//;

  Carp::croak "Symbol &$symbol is not already defined"
    unless _defined $symbol;

  my $self = bless {
    arguments => [],
    original => \&{$symbol},
    store => exists $opts->{store_arguments} ? $opts->{store_arguments} : 1,
    sub => $sub,
    symbol => $symbol,
  }, $class;

  Scalar::Util::weaken(my $weak = $self);
  _patch $symbol => sub {
    no warnings 'redefine';
    local *ORIGINAL = $weak->{original};
    push @{ $weak->{arguments} }, [ $weak->{store} ? @_ : () ];
    $sub->(@_);
  };

  return $self;
}

sub reset { $_[0]{arguments} = []; $_[0] }

sub restore {
  my $self = shift;
  if (my $orig = delete $self->{original}) {
    _patch $self->{symbol}, $orig;
  }
  return $self;
}

sub store_arguments { @_ == 1 ? $_[0]{store} : do { $_[0]{store} = $_[1]; $_[0] } }

sub DESTROY {
  my $self = shift;
  return if defined ${^GLOBAL_PHASE} && ${^GLOBAL_PHASE} eq 'DESTRUCT';
  $self->restore;
}

1;

=head1 NAME

Mock::MonkeyPatch - Monkey patching with test mocking in mind

=head1 SYNOPSIS

  {
    package MyApp;

    sub gen_item_id {
      my $type = shift;
      # calls external service and gets id for $type
    }

    sub build_item {
      my $type = shift;
      my $item = Item->new(type => $type);
      $item->id(gen_item_id($type));
      return $item;
    }
  }

  use Test::More;
  use MyApp;
  use Mock::MonkeyPatch;

  my $mock = Mock::MonkeyPatch->patch(
    'MyApp::gen_item_id' => sub { 'abcd' }
  );

  my $item = MyApp::build_item('rubber_chicken');
  is $item->id, 'abcd', 'building item calls MyApp::gen_random_id';
  ok $mock->called, 'the mock was indeed called';
  is_deeply $mock->arguments, ['rubber_chicken'], 'the mock was called with expected arguments';

=head1 DESCRIPTION

Mocking is a common tool, especially for testing.
By strategically replacing a subroutine, one can isolate segments (units) of code to test individually.
When this is done it is important to know that the mocked sub was actually called and with what arguments it was called.

L<Mock::MonkeyPatch> injects a subroutine in the place of an existing one.
It returns an object by which you can revisit the manner in which the mocked subroutine was called.
Further when the object goes out of scope (or when the L</restore> method is called) the original subroutine is replaced.

=head1 CONSTRUCTOR

=head2 patch

  my $mock = Mock::MonkeyPatch->patch('MyPackage::foo' => sub { ... });
  my $mock = Mock::MonkeyPatch->patch('MyPackage::foo' => sub { ... }, \%options);

Mock a subroutine and return a object to represent it.
Takes a fully qualifed subroutine name, a subroutine reference to call in its place, and optionally a hash reference of additional constructor arguments.

The replacement subroutine will be wrapped in a one that will store calling data, then injected in place of the original.
Within the replacement subroutine the original is available as the fully qualified subroutine C<Mock::MonkeyPatch::ORIGINAL>.
This can be used to inject behavior before, after, or even around the original.
This includes munging the arguments passed to the origial (though the actual arguments are what are stored).
For example usage, see L</COOKBOOK>.

Currently the optional hashref only accepts one option, an initial value for L</store_arguments> which is true if not given.

The wrapper will have the same prototype as the mocked function if one exists.
The replacement need not have any prototype, the arguments received by the wrapper will be passed to the given sub as they were received.
(If this doesn't make any sense to you, don't worry about it.)

=head1 METHODS

=head2 arguments

  my $args = $mock->arguments;
  my $args_second_time = $mock->arguments(1);

Returns an array reference containing the arguments that were passed to the mocked subroutine (but see also L</store_arguments>).
Optionally an integer may be passed which designates the call number to fetch arguments in the same manner of indexing an array (zero indexed).
If not given, C<0> is assumed, representing the first time the mock was called.
Returns C<undef> if the mocked subroutine was not called (or was not called enough times).

  use Test::More;
  is_deeply $mock->arguments, [1, 2, 3], 'called with the right arguments';

=head2 called

  my $time_called = $mock->called;

Returns the number of times the mocked subroutine was called.
This means that that there should be values available from L</arguments> up to the value of C<< $mock->called - 1 >>.

  use Test::More;
  ok $mock->called, 'mock was called';
  is $mock->called, 3, 'mock was called three times';

=head2 method_arguments

  my $args = $mock->method_arguments;
  my $args_third_time = $mock->method_arguments(2, 'MyClass');

A wrapper around L</arguments> convenient for when the mocked subroutine is called as a method.
Like L</arguments> it returns a subroutine reference, though it removes the first arguments which is the invocant.
It also can take a call number designation.

Additionally it takes a class name to test against the invocant as C<< $invocant->isa('Class::Name') >>.
If the invocant is not an instance of the class or a subclass thereof it returns C<undef>.

  use Test::More;
  is_deeply $mock->method_arguments(0, 'FrobberCo::Employee'),
    ['some', 'arguments'], 'mock method called with known arguments on a FrobberCo::Employee instance';

=head2 reset

  $mock = $mock->reset;

Reset the historical information stored in the mock, including L</arguments> and L</called>.
Returns the mock instance for chaining if desired.

Note that this does not restore the original method. for that, see L</restore>.

  use Test::More;
  is $mock->called, 3, 'called 3 times';
  is $mock->reset->called, 0, 'called zero times after reset';

=head2 restore

  $mock = $mock->restore;

Restore the original method to its original place in the symbol table.
This method is also called automatically when the object goes out of scope and is garbage collected.
Returns the mock instance for chaining if desired.
This method can only be called once!

Note that this does not reset historical information stored in the mock, for that, see L</reset>.

=head2 store_arguments

  $mock = $mock->store_arguments(0);

When true, the default if not passed to the constructor, arguments passed to the mocked subroutine are stored and accessible later via L</arguments> and L</method_arguments>.
However sometimes this isn't desirable, especially in cases where the reference count of items in the arguments matter; notably when an object should be destroyed and the destructor's behavior is important.
When this is true set C<store_arguments> to a false value and only an empty array reference will be stored.

When used as a setter, it returns the mock instance for chaining if desired.

=head1 COOKBOOK

=head2 Run code before the original

The original version of the mocked function (read: the code that was available via the symbol B<at the time the mock was initiated>)
is available via the fully qualified symbol C<Mock::MonkeyPatch::ORIGINAL>.
You can call this in your mock if for example you want to do some setup before calling the function.

  my $mock = $self->patch($symbol, sub {
    # do some stuff before the original
    do_mocked_stuff(@_);
    # then call the original function/method
    Mock::MonkeyPatch::ORIGINAL(@_);
  });

=head2 Using ORIGINAL in a nonblocking environment

Since the C<ORIGINAL> symbol is implemented via C<local> if you want to call it after leaving the scope you need to store a reference to the function in a lexical.

  my $mock = $self->patch($symbol, sub {
    my @args = @_;
    my $orig = \&Mock::MonkeyPatch::ORIGINAL;
    Mojo::IOLoop->timer(1 => sub { $orig->(@args) });
  });

=head1 SEE ALSO

=over

=item *

L<Test::MockObject>

=item *

L<Mock::Quick>

=item *

L<Mock::Sub>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mock-MonkeyPatch>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 CONTRIBUTORS

=over

=item *

Doug Bell (preaction)

=item *

Brian Medley (bpmedley)

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Joel Berger and L</CONTRIBUTORS>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
