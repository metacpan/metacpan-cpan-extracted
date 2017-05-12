package Test::Class::Sugar;

use Devel::Declare ();
use Devel::Declare::Context::Simple;
use B::Hooks::EndOfScope;
use Test::Class::Sugar::Context;
use Test::Class::Sugar::CodeGenerator;
use Carp qw/croak/;

use namespace::clean;

our $VERSION = '0.0400';

my %PARSER_FOR = (
    testclass => '_parse_testclass',
    startup   => '_parse_inner_keyword',
    setup     => '_parse_inner_keyword',
    test      => '_parse_inner_keyword',
    teardown  => '_parse_inner_keyword',
    shutdown  => '_parse_inner_keyword',
);

use Sub::Exporter -setup => {
    exports => [qw/testclass startup setup test teardown shutdown/],
    groups => {default => [qw/testclass/],
               inner   => [qw/startup setup test teardown shutdown/]},
    installer => sub {
        my ($args, $to_export) = @_;
        my $pack = $args->{into};
        unless (@$to_export) {
            unshift @$to_export, 'testclass', \&testclass;
        }
        foreach my $name (@$to_export) {
            my $parser_called = defined $PARSER_FOR{$name} ? $PARSER_FOR{$name} : '-NOTHING-';
            if (my $parser = __PACKAGE__->can($parser_called)) {
                Devel::Declare->setup_for(
                    $pack,
                    { $name => { const => sub { $parser->($pack, $args->{col}{defaults}, @_) } } },
                );
            }
        }
        Sub::Exporter::default_installer(@_);
    },
    collectors => [qw/defaults/],
};

sub _test_generator {
    my($ctx, $name, $plan) = @_;
    Test::Class::Sugar::CodeGenerator->new(
        context => $ctx,
        name    => $name,
        plan    => $plan,
    );
}

sub _testclass_generator {
    my($ctx, $classname, $defaults, $options) = @_;

    foreach my $key (keys %$defaults) {
        defined $options->{$key} ? () : ($options->{$key} = $defaults->{$key});
    }

    my $ret = Test::Class::Sugar::CodeGenerator->new(
        context   => $ctx,
        options   => $options,
    );
    $ret->classname($classname) if $classname;
    return $ret;
}


sub _parse_inner_keyword {
    my $pack = shift;
    my $defaults = shift;

    local $Carp::Internal{'Devel::Declare'} = 1;

    my $ctx = Test::Class::Sugar::Context->new->init(@_);
    my $preamble = '';

    $ctx->skip_declarator;

    my $name = $ctx->strip_test_name
        || croak "Can't make a test without a name";
    my $plan = $ctx->strip_plan;

    _test_generator($ctx, $name, $plan)->install_test();

    return;
}

sub _parse_testclass {
    my $pack = shift;
    my $defaults = shift;

    local $Carp::Internal{'Devel::Declare'} = 1;

    my $ctx = Test::Class::Sugar::Context->new->init(@_);

    $ctx->skip_declarator;
    my $classname = $ctx->strip_testclass_name;
    _testclass_generator($ctx, $classname, $defaults, $ctx->strip_options)
        ->install_testclass;
}

sub testclass (&) {}

sub startup (&) {}
sub setup (&) {}
sub test (&) { croak "Should not be called" }
sub teardown (&) {}
sub shutdown (&) {}

1;
__END__

=head1 NAME

Test::Class::Sugar - Helper syntax for writing Test::Class tests

=head1 SYNOPSIS

    use Test::Class::Sugar;

    testclass exercises Person {
        # Test::Most has been magically included
        # 'warnings' and 'strict' are turned on

        startup >> 1 {
            use_ok $test->subject;
        }

        test autonaming {
            is ref($test), 'Test::Person';
        }

        test the naming of parts {
            is $test->current_method, 'test_the_naming_of_parts';
        }

        test multiple assertions >> 2 {
            is ref($test), 'Test::Person';
            is $test->current_method, 'test_multiple_assertions';
        }
    }

    Test::Class->runtests;

=head1 DESCRIPTION

Test::Class::Sugar provides a new syntax for setting up your Test::Class based
tests. The idea is that we bundle up all the tedious boilerplate involved in
writing a class in favour of getting to the meat of what you're testing. We
made warranted assumptions about what you want to do, and we do them for
you. So, when you write

    testclass exercises Person {
        ...
    }

What Perl sees, after Test::Class::Sugar has done its work, is roughly:

    {
        package Test::Person;
        use base qw/Test::Class/;
        use strict; use warnings;
        require Person;

        sub subject { 'Person' };

        ...
    }

Some of the assumptions we made are overrideable, others aren't. Yet. Most of
them will be though. See L</Changing Assumptions> for details

=head2 Why you shouldn't use Test::Class::Sugar

Test::Class::Sugar is very new, mostly untested and is inadvertently hostile
to you if you confuse its parser. Don't use it if you want to live.

=head2 Why you should use Test::Class::Sugar

It's so shiny! Test::Class::Sugar was written to scratch an itch I had
when writing some tests for a L<MooseX::Declare> based module. Switching from
the implementation code to the test code was like shifting from fifth to first
gear in one fell swoop. Not fun. This is my attempt to sprinkle some
C<Devel::Declare> magic dust over the testing experience.

=head2 Bear this in mind:

B<Test::Class::Sugar is not a source filter>

I know it looks like a source filter in the right light, but it isn't. Source
filters fall down because only perl can parse Perl, so it's easy to confuse
them. Devel::Declare based modules work by letting perl parse Perl until it
comes across a new keyword, at which point it temporarily hands parsing duty
over to a new parser which has the job of parsing the little language
introduced by the keyword, turning it into real Perl, and handing the
responsibility for parsing that back to Perl. Obviously, it's still possible
for that to screw things up royally, but there are fewer opportunities to fuck
up.

We now return you to your regularly scheduled documentation.

=head1 SYNTAX

Essentially, Test::Class::Sugar adds some new keywords to perl. Here's what
they do, and what they expect.

(Syntax is described in the semi-standard half-arsed Backus-Naur Form
beloved of crappy language documentation efforts everywhere. If you can't read
it by now, find someone who can and blackmail them into writing a BNF free
tutorial and I for one will thank you for it.)

=over

=item B<testclass>

    testclass NAME?
      ( exercises CLASS
      | extends CLASS (, CLASS)*
      | uses HELPER (, HELPER)*
      )*

Where B<NAME> is is an optional test class name - the sort of thing you're
used to writing after C<package>. You don't have to name your C<testclass>,
but if you don't supply a name, you MUST supply an exercises clause.

=over

=item exercises CLASS

You can supply at most one C<exercises> clause. This specifies the class under
test. We use it to autoname the class if you haven't provided a NAME of your
own (the default name of the class would be C<< Test::<CLASS> >>). Also, if
you supply an exercises clause, the class will be autorequired and your test
class will have a C<subject> helper method, which will return the name of the
class under test.

=item extends CLASS (, CLASS)*

Sometimes, you don't want to inherit directly from B<Test::Class>. If that's
the case, add an C<extends> clause, and your worries will be over. The extends
clause supports, but emphatically does not encourage, multiple
inheritance. Friends don't let friends do multiple inheritance, but
Test::Class::Sugar's not a friend, it's a robot servant which knows nothing of
Asimov's Laws. If you insist on asking it for a length of rope with a loop at
the end and a rickety stepladder on which to stand, it will be all too happy to
assist.

=item uses HELPER (, HELPER)*

Ah, the glory that is the C<uses> clause. If you don't provide a uses clause,
Test::Class::Sugar will assume that you want to use L<Test::Most> as your
testing only testing helper library. If you would rather use, say,
L<Test::More> then you can do:

    testclass ExampleTest uses -More {...}

Hang on, C<-More>, what's that about? It's a simple shortcut. Instead of
making you write C<uses Test::This, Test::That, Test::TheOther>, you can write
C<uses -This, -That, -TheOther> and we'll expand the C<-> into C<Test::> and
do the right thing.

Note that, if you need to do anything special in the way of import arguments,
you should do the C<use> yourself. We're all about the 80:20 rule here.

=back

=item B<test>

    test WORD ( WORD )* (>> PLAN)? { ... }

I may be fooling myself, but I hope its mostly obvious what this does. Here's a few
examples to show you what's happening:

    test with multiple subtests >> 3 {...}
    test with no_plan >> no_plan {...}
    test 'a complicated description with "symbols" in it' {...}

Gets translated to:

    sub test_with_multiple_subtests : Test(3) {...}
    sub test_with_no_plan : Test(no_plan) {...}
    sub a_complicated_description_with_symbols_in_it : Test {...}

C<< >> PLAN >> is used to declare the number of subtests run by a given
message. It's not the most obvious choice I know, but I gave up on trying to
use C<:> after losing a few rounds with Perl over loop labels.

See L<Test::Class|Test::Class/Test> for details of C<PLAN>'s semantics.

=head2 Lifecycle Methods

=item B<startup>

=item B<setup>

=item B<teardown>

=item B<shutdown>

    (startup|setup|teardown|shutdown) ( WORD )* (>> PLAN)? { ... }

These lifecycle helpers work in pretty much the same way as L</test>, but with
the added wrinkle that, if you don't supply a name, they generate method names
derived from the name of the test class and the name of the helper, so, for
instance:

    testclass Test::Lifecycle::Autonaming {
        setup { ... }
    }

is equivalent to writing:

    testclass Test::Lifecycle::Autonaming {
        setup 'setup_Test_Lifecycle_Autonaming' {...}
    }

Other than that, the lifecycle helpers behave as described in
L<Test::Class|Test::Class/Test>. In particular, you can still give them names,
so

    testclass {
        setup with a name {...}
    }

works just fine.

=back

=head2 Changing Assumptions

There are several aspects of Test::Class::Sugar's policy that you may disagree
with. If you do, you can adjust them by passing a 'defaults' hash at use
time. For example:

    use Test::Class::Sugar defaults => { prefix => TestSuite };

Here's a list of the possible default settings and what they affect.

=over

=item prefix

Changes the prefix used for autogenerating test class names from C<Test::> to whatever you specify, so:

    use Test::Class::Sugar defaults => { prefix => TestSuite };

    testclass exercises Something {
        ...
    }

will build a test class called C<TestSuite::Something>

=item test_instance

B<COMING SOON>

Prefer C<$self> to C<$test> in your test methods? Then the C<test_instance> default is your friend. Just do

    use Test::Class::Sugar defaults => { test_instance => '$self' }

and all manner of things shall be well.



=item uses

B<< COMING SOON, BUT PROBABLY LATER THAN C<test_instance> >>

Bored of adding the same old C<uses> clause to your every testclass? Fix it at use time like so:

    use Test::Class::Sugar
        defaults => {
            uses => [qw/Test::More Moose/]
        };

=back

=head1 DIAGNOSTICS

Right now, Test::Class::Sugar's diagnostics range from the confusing to the
downright misleading. Expect progress on this in the future, tuit supply
permitting. 

Patches welcome.

=head1 BUGS AND LIMITATIONS

=head2 Known bugs

=over

=item Screwy line numbers

Test::Class::Sugar can screw up the accord between the line perl thinks some
code is on and the line the code is I<actually> on. This makes debugging test
classes harder than it should be. Our error reporting is bad enough already
without making things worse.

=back

=head2 Unknown bugs

There's bound to be some.

=head2 We still don't play well with MooseX::Declare

It would be useful to pinch some of L<MooseX::Declare>'s magic for writing
helper methods. Something like:

    helper whatever ($arg) {
        lives_ok { $test->subject->new($arg) }
    }

could be rather handy.


=head2 Patches welcome.

Please report any bugs or feature requests to me. It's unlikely you'll get any
response if you use L<http://rt.cpan.org> though. Your best course of action
is to fork the project L<http://www.github.com/pdcawley/test-class-sugar>,
write at least one failing test (Write something in C<testclass> form that
should work, but doesn't. If you can arrange for it to fail gracefully, then
please do, but if all you do is write something that blows up spectacularly,
that's good too. Failing/exploding tests are like manna to a maintenance
programmer.

=head1 AUTHOR

Piers Cawley C<< <pdcawley@bofh.org.uk> >>

=head1 ACKNOWLEDGEMENTS

Thanks to Adrian Howard for the original Test::Class, and to Adam Kennedy for
taking on the maintenance of it.

Thanks to my contributors:

Hans Dieter Pearcey for documentation fixes and Joel Bernstein for doing the
boring work of making this all work with Perl 5.8 (which means I can start
using this at work!)

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Piers Cawley C<< <pdcawley@bofh.org.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
