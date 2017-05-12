package TAP::Formatter::Jenkins;

use Moose;
use MooseX::NonMoose;
extends qw(
    TAP::Formatter::Console
);

use TAP::Formatter::Jenkins::Session;
use Data::Dumper;

our $VERSION = '0.02';

has 'test_suites' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'passing_todo_ok' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

###############################################################################
# Subroutine:   open_test($test, $parser)
###############################################################################
# Over-ridden 'open_test()' method.
#
# Creates a 'TAP::Formatter::Jenkins::Session' session, instead of a console
# formatter session.
sub open_test {
    my ( $self, $test, $parser ) = @_;

    $self->passing_todo_ok( $ENV{ALLOW_PASSING_TODOS} ? 1 : 0 );

    my $session = TAP::Formatter::Jenkins::Session->new( {
        name            => $test,
        formatter       => $self,
        parser          => $parser,
        passing_todo_ok => $self->passing_todo_ok,
    } );
    return $session;
}

###############################################################################
# Subroutine:   summary($aggregate)
###############################################################################
# Prints the summary report (in Jenkins TAP Plugin formatting) after all tests are run.
sub summary {
    my ( $self, $aggregate ) = @_;

    $self->_save_tap_files;

    return if $self->silent();

    print { $self->stdout } "ALL DONE\n";
}

###############################################################################
# Save tests result to tap files
sub _save_tap_files {
    my $self = shift;

    while ( my ( $test_name, $output ) = each %{ $self->test_suites } ) {
        my $tap_name = $test_name;
        $tap_name =~ s/^\///;
        $tap_name =~ s/\//-/g;
        $tap_name =~ s/\.t/.tap/;

        open my $tap_file, ">", $tap_name or die "Can not open file: $_";
        print { $tap_file } $output;
        close $tap_file;
    }
}

1;

=head1 NAME

TAP::Formatter::Jenkins - Harness output delegate for Jenkins TAP Plugin
output

=head1 SYNOPSIS

On the command line, with F<prove>:

  prove --formatter TAP::Formatter::Jenkins ...

Or, in your own scripts:

  use TAP::Harness;
  my $harness = TAP::Harness->new( {
      formatter_class => 'TAP::Formatter::Jenkins',
      merge => 1,
  } );
  $harness->runtests(@tests);

=head1 DESCRIPTION

B<This code is currently in alpha state and is subject to change.>

C<TAP::Formatter::Jenkins> provides TAP output formatting for C<TAP::Harness>,
which can be used in Jenkins CI server.

This module is based on TAP::Formatter::JUnit by Graham TerMarsch
<cpan@howlingfrog.com>, main differences are:

In standard use, "passing TODOs" are treated as failure conditions (and are
reported as such in the generated TAP).  If you wish to treat these as a
"pass" and not a "fail" condition, setting C<ALLOW_PASSING_TODOS> in your
environment will turn these into pass conditions.

=over

=item * resulting TAP is saved in %test_suite_name%.tap instead of putting it to the stdout

=item * converts information about failing tests to YAMLish

=back

=head1 ATTRIBUTES

=over

=item test_suites

List-ref of test suites that have been executed.

=back

=head1 METHODS

=over

=item B<open_test($test, $parser)>

Over-ridden C<open_test()> method.

Creates a C<TAP::Formatter::Jenkins::Session> session, instead of a console
formatter session.

=item B<summary($aggregate)>

Prints the summary report (in Jenkins TAP Plugin formatting) after all tests are run.

=item B<add_testsuite($suite)>

Adds the given test C<$suite> to the list of test suites that we've
executed and need to summarize.

=back

=head1 COPYRIGHT

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<TAP::Formatter::Jenkins::Session>,
L<TAP::Formatter::Jenkins::MyParser>,

=cut
