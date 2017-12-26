package Mock::Sub;
use 5.006;
use strict;
use warnings;

use Carp qw(confess);
use Mock::Sub::Child;
use Scalar::Util qw(weaken);

our $VERSION = '1.08';

my %opts;

sub import {
    my ($class, %args) = @_;
    %opts = %args;
}
sub new {
    my $self = bless {}, shift;
    %{ $self } = @_;

    for (keys %opts){
        $self->{$_} = $opts{$_};
    }
    return $self;
}
sub mock {
    my $self = shift;
    my $sub = shift;

    if (ref($self) ne 'Mock::Sub'){
        confess
            "calling mock() on the Mock::Sub class is no longer permitted. " .
            "create a new mock object with Mock::Sub->new;, then call mock " .
            "with my \$sub_object = \$mock->mock('sub_name'); ";
    }
    my %p = @_;
    for (keys %p){
        $self->{$_} = $p{$_};
    }

    if (! defined wantarray){
        confess "\n\ncalling mock() in void context isn't allowed. ";
    }

    my $child = Mock::Sub::Child->new(no_warnings => $self->{no_warnings});

    $child->side_effect($self->{side_effect});
    $child->return_value($self->{return_value});

    $self->{objects}{$sub}{obj} = $child;
    $child->_mock($sub);

    # remove the REFCNT to the child, or else DESTROY won't be called
    weaken $self->{objects}{$sub}{obj};

    return $child;
}
sub mocked_subs {
    my $self = shift;

    my @names;

    for (keys %{ $self->{objects} }) {
        if ($self->mocked_state($_)){
            push @names, $_;
        }
    }
    return @names;
}
sub mocked_objects {
    my $self = shift;

    my @mocked;
    for (keys %{ $self->{objects} }){
        push @mocked, $self->{objects}{$_}{obj};
    }
    return @mocked;
}
sub mocked_state {
    my ($self, $sub) = @_;

    if (! $sub){
        confess "calling mocked_state() on a Mock::Sub object requires a sub " .
              "name to be passed in as its only parameter. ";
    }

    eval {
        my $test = $self->{objects}{$sub}{obj}->mocked_state();
    };
    if ($@){
        confess "can't call mocked_state() on the class if the sub hasn't yet " .
              "been mocked. ";
    }
    return $self->{objects}{$sub}{obj}->mocked_state;
}
sub DESTROY {
}
sub __end {}; # vim fold placeholder

1;
=head1 NAME

Mock::Sub - Mock package, object and standard subroutines, with unit testing in mind.

=for html
<a href="http://travis-ci.org/stevieb9/mock-sub"><img src="https://secure.travis-ci.org/stevieb9/mock-sub.png"/>
<a href='https://coveralls.io/github/stevieb9/mock-sub?branch=master'><img src='https://coveralls.io/repos/stevieb9/mock-sub/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    # see EXAMPLES for a full use case and caveats

    use Mock::Sub;

    # disable warnings about mocking non-existent subs

    use Mock::Sub no_warnings => 1

    # create the parent mock object

    my $mock = Mock::Sub->new;

    # mock some subs...

    my $foo = $mock->mock('Package::foo');
    my $bar = $mock->mock('Package::bar');

    # wait until a mocked sub is called

    Package::foo();

    # then...

    $foo->name;         # name of sub that's mocked
    $foo->called;       # was the sub called?
    $foo->called_count; # how many times was it called?
    $foo->called_with;  # array of params sent to sub

    # have the mocked sub return something when it's called (list or scalar).

    $foo->return_value(1, 2, {a => 1});
    my @return = Package::foo;

    # have the mocked sub perform an action

    $foo->side_effect( sub { die "eval catch" if @_; } );

    eval { Package::foo(1); };
    like ($@, qr/eval catch/, "side_effect worked with params");

    # extract the parameters the sub was called with (if return_value or
    # side_effect is not used, we will return the parameters that were sent into
    # the mocked sub (list or scalar context)

    my @args = $foo->called_with;

    # reset the mock object for re-use within the same scope

    $foo->reset;

    # restore original functionality to the sub

    $foo->unmock;

    # re-mock a previously unmock()ed sub

    $foo->remock;

    # check if a sub is mocked

    my $state = $foo->mocked_state;

    # mock out a CORE:: function. Be warned that this *must* be done within
    # compile stage (BEGIN), and the function can NOT be unmocked prior
    # to the completion of program execution

    my ($mock, $caller);

    BEGIN {
        $mock = Mock::Sub->new;
        $caller = $mock->mock('caller');
    };

    $caller->return_value(55);
    caller(); # mocked caller() called

=head1 DESCRIPTION

Easy to use and very lightweight module for mocking out sub calls.
Very useful for testing areas of your own modules where getting coverage may
be difficult due to nothing to test against, and/or to reduce test run time by
eliminating the need to call subs that you really don't want or need to test.

=head1 EXAMPLE

Here's a full example to get further coverage where it's difficult if not
impossible to test certain areas of your code (eg: you have if/else statements,
but they don't do anything but call other subs. You don't want to test the
subs that are called, nor do you want to add statements to your code).

Note that if the end subroutine you're testing is NOT Object Oriented (and
you're importing them into your module that you're testing), you have to mock
them as part of your own namespace (ie. instead of Other::first, you'd mock
MyModule::first).

   # module you're testing:

    package MyPackage;
    
    use Other;
    use Exporter qw(import);
    @EXPORT_OK = qw(test);
   
    my $other = Other->new;

    sub test {
        my $arg = shift;
        
        if ($arg == 1){
            # how do you test this?... there's no return etc.
            $other->first();        
        }
        if ($arg == 2){
            $other->second();
        }
    }

    # your test file

    use MyPackage qw(test);
    use Mock::Sub;
    use Test::More tests => 2;

    my $mock = Mock::Sub->new;

    my $first = $mock->mock('Other::first');
    my $second = $mock->mock('Other::second');

    # coverage for first if() in MyPackage::test
    test(1);
    is ($first->called, 1, "1st if() statement covered");

    # coverage for second if()
    test(2);
    is ($second->called, 1, "2nd if() statement covered");

=head1 MOCK OBJECT METHODS

=head2 C<new(%opts)>

Instantiates and returns a new C<Mock::Sub> object, ready to be used to start
creating mocked sub objects.

Optional options:

=over 4

=item C<return_value =E<gt> $scalar>

Set this to have all mocked subs created with this mock object return anything
you wish (accepts a single scalar only. See C<return_value()> method to return
a list and for further information). You can also set it in individual mocks
only (see C<return_value()> method).

=item C<side_effect =E<gt> $cref>

Set this in C<new()> to have the side effect passed into all child mocks
created with this object. See C<side_effect()> method.

=back

=head2 C<mock('sub', %opts)>

Instantiates and returns a new mock object on each call. 'sub' is the name of
the subroutine to mock (requires full package name if the sub isn't in
C<main::>).

The mocked sub will return the parameters sent into the mocked sub if a return
value isn't set, or a side effect doesn't return anything, if available. If
in scalar context but a list was sent in, we'll return the first parameter in
the list. In list context, we simply receive the parameters as they were sent
in.

Optional parameters:

See C<new()> for a description of the parameters. Both the C<return_value> and
C<side_effect> parameters can be set in this method to individualize each mock
object, and will override the global configuration if set in C<new()>.

There's also C<return_value()> and C<side_effect()> methods if you want to
set, change or remove these values after instantiation of a child sub object.

=head2 mocked_subs

Returns a list of all the names of the subs that are currently mocked under
the parent mock object.

=head2 mocked_objects

Returns a list of all sub objects underneath the parent mock object, regardless
if its sub is currently mocked or not.

=head2 mocked_state('Sub::Name')

Returns 1 if the sub currently under the parent mock object is mocked or not,
and 0 if not. Croaks if there hasn't been a child sub object created with this
sub name.

=head1 SUB OBJECT METHODS

These methods are for the children mocked sub objects returned from the
parent mock object. See L<MOCK OBJECT METHODS> for methods related
to the parent mock object.

=head2 C<unmock>

Restores the original functionality back to the sub, and runs C<reset()> on
the object.

=head2 C<remock>

Re-mocks the sub within the object after calling C<unmock> on it (accepts the
side_effect and return_value parameters).

=head2 C<called>

Returns true (1) if the sub being mocked has been called, and false (0) if not.

=head2 C<called_count>

Returns the number of times the mocked sub has been called.

=head2 C<called_with>

Returns an array of the parameters sent to the subroutine. C<confess()s> if
we're called before the mocked sub has been called.

=head2 C<mocked_state>

Returns true (1) if the sub the object refers to is currently mocked, and
false (0) if not.

=head2 C<name>

Returns the name of the sub being mocked.

=head2 C<side_effect($cref)>

Add (or change/delete) a side effect after instantiation.

Send in a code reference containing an action you'd like the
mocked sub to perform.

The side effect function will receive all parameters sent into the mocked sub.

You can use both C<side_effect()> and C<return_value()> params at the same
time. C<side_effect> will be run first, and then C<return_value>. Note that if
C<side_effect>'s last expression evaluates to any value whatsoever
(even false), it will return that and C<return_value> will be skipped.

To work around this and have the side_effect run but still get the
return_value thereafter, write your cref to evaluate undef as the last thing
it does: C<sub { ...; undef; }>.

=head2 C<return_value>

Add (or change/delete) the mocked sub's return value after instantiation.
Can be a scalar or list. Send in C<undef> to remove previously set values.

=head2 C<reset>

Resets the functional parameters (C<return_value>, C<side_effect>), along
with C<called()> and C<called_count()> back to undef/false. Does not restore
the sub back to its original state.

=head1 NOTES

This module has a backwards parent-child relationship. To use, you create a
mock object using L</MOCK OBJECT METHODS> C<new> and C<mock> methods,
thereafter, you use the returned mocked sub object L</SUB OBJECT METHODS> to
perform the work.

The parent mock object retains certain information and statistics of the child
mocked objects (and the subs themselves).

To mock CORE::GLOBAL functions, you *must* initiate within a C<BEGIN> block
(see C<SYNOPSIS> for details). It is important that if you mock a CORE sub,
it can't and won't be returned to its original state until after the entire
program process tree exists. Period.

I didn't make this a C<Test::> module (although it started that way) because
I can see more uses than placing it into that category.

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 BUGS

Please report any bugs or requests at
L<https://github.com/stevieb9/mock-sub/issues>

=head1 REPOSITORY

L<https://github.com/stevieb9/mock-sub>

=head1 BUILD RESULTS

CPAN Testers: L<http://matrix.cpantesters.org/?dist=Mock-Sub>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mock::Sub

=head1 ACKNOWLEDGEMENTS

Python's MagicMock module.

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Mock::Sub

