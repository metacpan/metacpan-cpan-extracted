package TAP::Formatter::JUnit;

use Moose;
use MooseX::NonMoose;
extends qw(
    TAP::Formatter::Console
);

use XML::Generator;
use TAP::Formatter::JUnit::Session;
use namespace::clean;

our $VERSION = '0.16';

has 'testsuites' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => [qw( Array )],
    handles => {
        add_testsuite => 'push',
    },
);

has 'xml' => (
    is         => 'rw',
    isa        => 'XML::Generator',
    lazy_build => 1,
);
sub _build_xml {
    return XML::Generator->new(
        ':pretty',
        ':std',
        'escape'   => 'always,high-bit,even-entities',
        'encoding' => 'UTF-8',
    );
}

###############################################################################
# Subroutine:   open_test($test, $parser)
###############################################################################
# Over-ridden 'open_test()' method.
#
# Creates a 'TAP::Formatter::JUnit::Session' session, instead of a console
# formatter session.
sub open_test {
    my ($self, $test, $parser) = @_;
    my $session = TAP::Formatter::JUnit::Session->new( {
        name            => $test,
        formatter       => $self,
        parser          => $parser,
        passing_todo_ok => $ENV{ALLOW_PASSING_TODOS} ? 1 : 0,
    } );
    return $session;
}

###############################################################################
# Subroutine:   summary()
###############################################################################
# Prints the summary report (in JUnit) after all tests are run.
sub summary {
    my $self = shift;
    return if $self->silent();

    my @suites = @{$self->testsuites};
    print { $self->stdout } $self->xml->testsuites( @suites );
}

1;

=for stopwords xml testsuites TODO parseable JUnitXSchema.xsd

=head1 NAME

TAP::Formatter::JUnit - Harness output delegate for JUnit output

=head1 SYNOPSIS

On the command line, with F<prove>:

=for test_synopsis BEGIN { die "SKIP: This isn't Perl, but shell" }

  $ prove --formatter TAP::Formatter::JUnit ...

Or, in your own scripts:

  use TAP::Harness;

  # What TAP output did we save from a previous run, with
  # PERL_TEST_HARNESS_DUMP_TAP=tap/
  my @tests = glob("tap/*.t");

  # Convert the TAP to JUnit
  my $harness = TAP::Harness->new( {
      formatter_class => 'TAP::Formatter::JUnit',
      merge => 1,
  } );
  $harness->runtests(@tests);

=head1 DESCRIPTION

B<This code is currently in alpha state and is subject to change.>

C<TAP::Formatter::JUnit> provides JUnit output formatting for C<TAP::Harness>.

By default (e.g. when run with F<prove>), the I<entire> test suite is gathered
together into a single JUnit XML document, which is then displayed on C<STDOUT>.
You can, however, have individual JUnit XML files dumped for each individual
test, by setting C<PERL_TEST_HARNESS_DUMP_TAP> to a directory that you would
like the JUnit XML dumped to.  Note, that this will B<also> cause
C<TAP::Harness> to dump the original TAP output into that directory as well (but
IMHO that's ok as you've now got the data in two parseable formats).

Timing information is included in the JUnit XML, I<if> you specified C<--timer>
when you ran F<prove>.

In standard use, a "passing TODO" is treated as failure conditions (and is
reported as such in the generated JUnit).  If you wish to treat these as a
"pass" and not a "fail" condition, setting C<ALLOW_PASSING_TODOS> in your
environment will turn these into pass conditions.

The JUnit output generated is partial to being grokked by Hudson
(L<http://hudson.dev.java.net/>).  That's the build tool I'm using at the
moment and needed to be able to generate JUnit output for.

=head1 ATTRIBUTES

=over

=item testsuites

List-ref of test suites that have been executed.

=item xml

An C<XML::Generator> instance, to be used to generate XML output.

=back

=head1 METHODS

=over

=item open_test($test, $parser)

Over-ridden C<open_test()> method.

Creates a C<TAP::Formatter::JUnit::Session> session, instead of a console
formatter session.

=item summary()

Prints the summary report (in JUnit) after all tests are run.

=item add_testsuite($suite)

Adds the given XML test C<$suite> to the list of test suites that we've
executed and need to summarize.

=back

=head1 AUTHOR

Graham TerMarsch <cpan@howlingfrog.com>

Many thanks to Andy Armstrong and all those involved for the B<fabulous> set of
tests in C<Test::Harness>; they became the basis for the unit tests here.

Other thanks go out to those that have provided feedback, comments, or patches:

  Mark Aufflick
  Joe McMahon
  Michael Nachbaur
  Marc Abramowitz
  Colin Robertson
  Phillip Kimmey
  Dave Lambley

=head1 COPYRIGHT

Copyright 2008-2010, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

=over

=item L<TAP::Formatter::Console>

=item L<TAP::Formatter::JUnit::Session>

=item L<Hudson home page|http://hudson.dev.java.net/>

=item L<JUnitXSchema.xsd|http://jra1mw.cvs.cern.ch:8180/cgi-bin/jra1mw.cgi/org.glite.testing.unit/config/JUnitXSchema.xsd?view=markup&content-type=text%2Fvnd.viewcvs-markup&revision=HEAD>

=item L<JUnit parsing in Bamboo|http://confluence.atlassian.com/display/BAMBOO/JUnit+parsing+in+Bamboo>.

=back

=cut
