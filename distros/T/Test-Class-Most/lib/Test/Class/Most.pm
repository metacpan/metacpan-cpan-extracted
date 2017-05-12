package Test::Class::Most;

use warnings;
use strict;
use Test::Class;
use Carp 'croak';

=head1 NAME

Test::Class::Most - Test Classes the easy way

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

Instead of this:

    use strict;
    use warnings;
    use Test::Exception 0.88;
    use Test::Differences 0.500;
    use Test::Deep 0.106;
    use Test::Warn 0.11;
    use Test::More 0.88;

    use parent 'My::Test::Class';

    sub some_test : Tests { ... }

You type this:

    use Test::Class::Most parent => 'My::Test::Class';

    sub some_test : Tests { ... }

=head1 DESCRIPTION

When people write test classes with the excellent C<Test::Class>, you often
see the following at the top of the code:

  package Some::Test::Class;

  use strict;
  use warnings;
  use base 'My::Test::Class';
  use Test::More;
  use Test::Exception;

  # and then the tests ...

That's a lot of boilerplate and I don't like boilerplate.  So now you can do
this:

  use Test::Class::Most parent => 'My::Test::Class';

That automatically imports L<strict> and L<warnings> for you.  It also gives
you all of the testing goodness from L<Test::Most>.

=head1 CREATING YOUR OWN BASE CLASS

You probably want to create your own base class for testing.  To do this,
simply specify no import list:

  package My::Test::Class;
  use Test::Class::Most; # we now inherit from Test::Class

  INIT { Test::Class->runtests }

  1;

And then your other classes inherit as normal (well, the way we do it):

  package Tests::For::Foo;
  use Test::Class::Most parent => 'My::Test::Class';

And you can inherit from those other classes, too:

  package Tests::For::Foo::Child;
  use Test::Class::Most parent => 'Tests::For::Foo';

Of course, it's quite possible that you're a fan of multiple inheritance, so
you can do that, too (I was I<soooooo> tempted to not allow this, but I
figured I shouldn't force too many of my personal beliefs on you):

 package Tests::For::ISuckAtOO;
 use Test::Class::Most parent => [qw/
    Tests::For::Foo
    Tests::For::Bar
    Some::Other::Class::For::Increased::Stupidity
 /];

As a side note, it's recommended that even if you don't need test control
methods in your base class, put stubs in there:

  package My::Test::Class;
  use Test::Class::Most; # we now inherit from Test::Class

  INIT { Test::Class->runtests }

  sub startup  : Tests(startup)  {}
  sub setup    : Tests(setup)    {}
  sub teardown : Tests(teardown) {}
  sub shutdown : Tests(shutdown) {}

  1;

This allows developers to I<always> be able to safely call parent test control
methods rather than wonder if they are there:

  package Tests::For::Customer;
  use Test::Class::Most parent => 'My::Test::Class';

  sub setup : Tests(setup) {
    my $test = shift;
    $test->next::method; # safe due to stub in base class
    ...
  }

=head1 ATTRIBUTES

You can also specify "attributes" which are merely very simple getter/setters.

  use Test::Class::Most 
    parent      => 'My::Test::Class',
    attributes  => [qw/customer items/],
    is_abstract => 1;

  sub setup : Tests(setup) {
    my $test = shift;
    $test->SUPER::setup;
    $test->customer( ... );
    $test->items( ... );
  }

  sub some_tests : Tests {
    my $test     = shift;
    my $customer = $test->customer;
    ...
  }

If called with no arguments, returns the current value.  If called with one
argument, sets that argument as the current value.  If called with more than
one argument, it croaks.

=head1 ABSTRACT CLASSES

You may pass an optional C<is_abstract> parameter in the import list. It takes
a boolean value. This value is advisory only and is not inherited. It defaults
to false if not provided.

Sometimes you want to identify a test class as "abstract". It may have a bunch
of tests, but those should only run for its subclasses. You can pass
C<<is_abstract => 1>> in the import list. Then, to test if a given class or
instance of that class is "abstract":

 sub dont_run_in_abstract_base_class : Tests {
     my $test = shift;
     return if Test::Class::Most->is_abstract($test);
     ...
 }

Note that C<is_abstract> is strictly B<advisory only>. You are expected
(required) to check the value yourself and take appropriate action.

We recommend adding the following method to your base class:

 sub is_abstract {
     my $test = shift;
     return Test::Class::Most->is_abstract($test);
 }

And later in a subclass:

 if ( $test->is_abstract ) { ... }

=head1 EXPORT

All functions from L<Test::Most> are automatically exported into your
namespace.

=cut

{
    my %IS_ABSTRACT;

    sub is_abstract {
        my ( undef, $proto ) = @_;
        my $test_class = ref $proto || $proto;
        return $IS_ABSTRACT{$test_class};
    }

    sub import {
        my ( $class, %args ) = @_;
        my $caller = caller;
        eval "package $caller; use Test::Most;";
        croak($@) if $@;
        warnings->import;
        strict->import;
        if ( my $parent = delete $args{parent} ) {
            if ( ref $parent && 'ARRAY' ne ref $parent ) {
                croak(
    "Argument to 'parent' must be a classname or array of classnames, not ($parent)"
                );
            }
            $parent = [$parent] unless ref $parent;
            foreach my $p (@$parent) {
                eval "use $p";
                croak($@) if $@;
            }
            no strict 'refs';
            push @{"${caller}::ISA"} => @$parent;
        }
        else {
            no strict 'refs';
            push @{"${caller}::ISA"} => 'Test::Class';
        }
        if ( my $attributes = delete $args{attributes} ) {
            if ( ref $attributes && 'ARRAY' ne ref $attributes ) {
                croak(
    "Argument to 'attributes' must be a classname or array of classnames, not ($attributes)"
                );
            }
            $attributes = [$attributes] unless ref $attributes;
            foreach my $attr (@$attributes) {
                my $method = "$caller\::$attr";
                no strict 'refs';
                *$method = sub {
                    my $test = shift;
                    return $test->{$method} unless @_;
                    if ( @_ > 1 ) {
                        croak("You may not pass more than one argument to '$method'");
                    }
                    $test->{$method} = shift;
                    return $test;
                };
            }
        }
        if ( my $is_abstract = delete $args{is_abstract} ) {
            $IS_ABSTRACT{$caller} = $is_abstract;
        }
        else {
            $IS_ABSTRACT{$caller} = 0;
        }
    }
}

=head1 TUTORIAL

If you're not familiar with using L<Test::Class>, please see my tutorial at:

=over 4

=item * L<http://www.modernperlbooks.com/mt/2009/03/organizing-test-suites-with-testclass.html>

=item * L<http://www.modernperlbooks.com/mt/2009/03/reusing-test-code-with-testclass.html>

=item * L<http://www.modernperlbooks.com/mt/2009/03/making-your-testing-life-easier.html>

=item * L<http://www.modernperlbooks.com/mt/2009/03/using-test-control-methods-with-testclass.html>

=item * L<http://www.modernperlbooks.com/mt/2009/03/working-with-testclass-test-suites.html>

=back


=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-class-most at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-Most>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Class::Most

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Class-Most>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Class-Most>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Class-Most>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Class-Most/>

=back

=head1 SEE ALSO

=over 4

=item * L<Test::Class>

xUnit-style testing in Perl

=item * L<Test::Most>

The most popular CPAN test modules bundled into one module.

=item * L<Modern::Perl>

I stole this code.  Thanks C<chromatic>!

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Adrian Howard for L<Test::Class>, Adam Kennedy for maintaining it
and C<chromatic> for L<Modern::Perl>.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no warnings 'void';
"Boilerplate is bad, m'kay";
