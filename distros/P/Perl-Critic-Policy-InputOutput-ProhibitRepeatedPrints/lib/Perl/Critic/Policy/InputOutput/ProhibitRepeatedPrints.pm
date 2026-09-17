package Perl::Critic::Policy::InputOutput::ProhibitRepeatedPrints;
$Perl::Critic::Policy::InputOutput::ProhibitRepeatedPrints::VERSION = '0.001';
# ABSTRACT: Build the string, then print it once.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use Readonly;

use Perl::Critic::Utils qw{ :severities };
use parent              qw{Perl::Critic::Policy};



Readonly::Scalar my $DESC => 'Consecutive prints to the same filehandle';
Readonly::Scalar my $EXPL => 'Build the string, then print it once';

Readonly::Scalar my $DEFAULT_MINIMUM => 2;

# The three that write to a handle and take one as their first argument.
Readonly::Hash my %PRINTS => map { $_ => 1 } qw{print printf say};

# STDOUT, as the handle of a print that names none.  Not a legal handle name, so
# it cannot collide with one somebody wrote.
Readonly::Scalar my $IMPLICIT => q{ implicit };

sub supported_parameters {
    return (
        {
            name            => 'minimum_violations',
            description     => 'How many consecutive prints to one handle are too many.',
            default_string  => $DEFAULT_MINIMUM,
            behavior        => 'integer',
            integer_minimum => 2,
        },
        {
            name           => 'allow',
            description    => 'Handles never reported, as the source spells them.',
            default_string => q{},
            behavior       => 'string list',
        },
    );
}

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw{troglodyne maintenance} }

# Statements rather than tokens: a run is consecutive statements, and asking for
# them one block at a time is what makes "consecutive" mean anything.  Asking
# for PPI::Statement alone would also hand back every compound statement and
# every statement nested inside one, and the run would then span a block
# boundary it never crossed in the source.
sub applies_to { return 'PPI::Structure::Block', 'PPI::Document' }

sub violates {
    my ( $self, $elem, undef ) = @_;

    my @runs = $self->_runs_in($elem);
    return map { $self->violation( $DESC, $EXPL, $_ ) } @runs;
}

# The first print of every run in this block long enough to report.  Only the
# first: a run of twelve is one message written twelve ways, not twelve
# findings, and a violation per line is a wall nobody reads.
sub _runs_in {
    my ( $self, $elem ) = @_;

    my ( @found, @run );
    my $handle = q{};

    foreach my $statement ( $elem->schildren ) {
        my $printed = _printed_handle($statement);

        if ( !defined $printed || $printed ne $handle ) {
            push( @found, $run[0] ) if $self->_long_enough( \@run, $handle );
            @run    = defined $printed ? ($statement) : ();
            $handle = defined $printed ? $printed     : q{};
            next;
        }

        push( @run, $statement );
    }

    push( @found, $run[0] ) if $self->_long_enough( \@run, $handle );
    return @found;
}

sub _long_enough {
    my ( $self, $run, $handle ) = @_;

    return 0 if scalar @{$run} < $self->{_minimum_violations};
    return 0 if $self->{_allow}{$handle};
    return 1;
}

# The handle a statement prints to, or undef when it is not a print at all.
# STDOUT is $IMPLICIT rather than the empty string so that "not a print" and
# "print naming no handle" cannot be confused for one another.
sub _printed_handle {
    my ($statement) = @_;

    return undef unless $statement->isa('PPI::Statement');
    return undef if $statement->isa('PPI::Statement::Compound');

    my @significant = grep { $_->significant } $statement->schildren;
    my $first       = shift @significant or return undef;

    return undef unless $first->isa('PPI::Token::Word');
    return undef unless $PRINTS{ $first->content };

    my $second = shift @significant;
    return $IMPLICIT unless defined $second;

    # print {*STDERR} "..." and print $fh "...".  Anything else -- a string, a
    # variable being printed rather than printed to -- is STDOUT.
    return $second->content if $second->isa('PPI::Structure::Block');
    return $second->content if $second->isa('PPI::Token::Symbol') && _is_handle( $second, \@significant );

    return $IMPLICIT;
}

# print $fh "..." names a handle; print $x, $y prints two things to STDOUT.  The
# difference is the comma: a handle is not separated from what follows it.
sub _is_handle {
    my ( $symbol, $rest ) = @_;

    my $next = $rest->[0] or return 0;
    return 0 if $next->isa('PPI::Token::Operator');
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitRepeatedPrints - Build the string, then print it once.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::InputOutput::ProhibitRepeatedPrints

Consecutive prints to the same filehandle should be one print with the string built
first:

    print {*STDERR} "Configuration in $dir\n";      # reported
    print {*STDERR} "  copied: $what\n";
    print {*STDERR} "  built here: $other\n";

    my $said = "Configuration in $dir\n";           # what it means
    $said .= "  copied: $what\n";
    $said .= "  built here: $other\n";
    print {*STDERR} $said;

A heredoc usually reads better still, and is what this most often wants to
become:

    print {*STDERR} <<"SAID";
    Configuration in $dir
      copied: $what
      built here: $other
    SAID

The point is not the number of system calls, though this can matter in a tight loop.
We write code to be read by other people, and reducing the amount of information
per-line respects the reader's time.

=head2 What counts as the same handle

Three forms, and they are only a run when the handle matches:

    print "a\n";               # STDOUT, implicitly
    print {*STDERR} "b\n";     # a block
    print $fh "c\n";           # a lexical handle

So a print to STDOUT directly after one to STDERR is two messages rather than a
run, and is not reported.  C<printf> and C<say> count alongside C<print>: they
write to the same handle and the string can be built ahead of them just the
same.

=head2 PROHIBITED

    print "one\n";
    print "two\n";

    printf "%s\n", $a;
    print "and\n";

    print {*STDERR} "one\n";
    print {*STDERR} "two\n" if $why;

=head2 ALLOWED

    print "one\n";
    print {*STDERR} "two\n";        # a different handle

    print "one\n";
    $thing->do_something;
    print "two\n";                  # not consecutive

    print "$_\n" for @lines;        # one statement, however many lines

A statement modifier does not split a run -- the second print above is still
part of one -- but a C<for> modifier makes a single statement that prints many
times, which is already the thing this policy asks for and cannot be built into
a string without a C<join>.

=head1 CONFIGURATION

=head2 minimum_violations

How many consecutive prints to the same handle are too many.  Two by default;
raise it where a short run is house style.

    [InputOutput::ProhibitRepeatedPrints]
    minimum_violations = 3

=head2 allow

Handles never reported however many times they are printed to in a row, spelled
the way the source spells them: C<{*STDERR}> with its braces, C<$fh> with its
sigil.  Empty by default.

    [InputOutput::ProhibitRepeatedPrints]
    allow = {*STDERR}

=head1 CAVEATS

Two consecutive prints are not always one message.  Example:

    my $file = write_thing()
    print "Wrote $file\n";

    print "Defining and starting $domain...\n";
    ...

The first concludes one step and the second announces the next.  Joining them
would say something the code does not mean, and a blank line between two prints
is not something the policy can read an intention from -- a run of lines that
really is one message often has one too.

There is no rule here that would tell those apart, so where this happens the
answer is C<## no critic (InputOutput::ProhibitRepeatedPrints)> with a reason,
or the handle in C<allow>, rather than a rewrite that makes the code worse to
satisfy a policy.

=head2 METHODS

What L<Perl::Critic::Policy> asks of a policy, answered here rather than called
from anywhere.

=head3 supported_parameters

C<minimum_violations>, how many consecutive prints to one handle are too many,
and C<allow>, the handles never reported however many times they are printed to
in a row.  Both are described under L</CONFIGURATION>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitrepeatedprints/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
