package Perl::Critic::Policy::ControlStructures::ProhibitEmptyConditionalBlocks 0.001;

# ABSTRACT: Write no if, elsif, else or unless with nothing in its block.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use Readonly;

use Perl::Critic::Utils qw{ :severities };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $EXPL => q{Invert the condition, or return early};


sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_MEDIUM }
sub default_themes       { return qw{ maintenance } }
sub applies_to           { return 'PPI::Statement::Compound' }


sub violates {
    my ( $self, $elem, undef ) = @_;

    # PPI types an unless chain as 'if' too.
    return unless $elem->type eq 'if';

    my ( @violations, $keyword );
    foreach my $child ( $elem->schildren ) {
        if ( $child->isa('PPI::Token::Word') ) {
            $keyword = $child;
            next;
        }
        next unless $child->isa('PPI::Structure::Block');
        next if $child->schildren;
        push( @violations, $self->violation( 'Empty ' . $keyword->content . ' block', $EXPL, $keyword ) );
    }
    return @violations;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitEmptyConditionalBlocks - Write no if, elsif, else or unless with nothing in its block.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::ControlStructures::ProhibitEmptyConditionalBlocks

A branch with nothing in it is a branch that does nothing, written out so the
reader has to work that out.  Say what does happen instead: invert the
condition, or return early.

    if ( $query->{raw} ) {          # reported
        # raw skips the filters.
    }
    elsif ( @acls ) {
        ...
    }

    # raw skips the filters.
    return if $query->{raw};
    ...

A comment does not make a block less empty.  Put it beside the code that the
condition guards, where it explains something.

=head2 PROHIBITED

    if ($x) {}                      # each of these blocks
    if ($x) { # nothing to do       # holds no statement
    }
    unless ($x) {}
    if ($x) { f() } elsif ($y) {}
    if ($x) { f() } else {}
    if ($x) { ; }                   # a null statement is none

=head2 ALLOWED

    if ($x) { f() }
    f() if $x;                      # no block
    while ( waitpid( -1, WNOHANG ) > 0 ) {}    # a loop, not a conditional
    sub noop {}                     # a sub, not a conditional

=head2 CAVEATS

Only C<if>, C<elsif>, C<else> and C<unless> are read.  An empty loop body can
be the point of the loop, when its condition does the work, so loops are left
alone.

Each empty block is a violation of its own, reported at the keyword that opens
it.

=head2 METHODS

=head3 supported_parameters

=head3 default_severity

=head3 default_themes

=head3 applies_to

=head3 violates

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitemptyconditionalblocks/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 CONTRIBUTOR

=for stopwords troglodyne-bot

troglodyne-bot <morpheus@troglodyne.net>

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
