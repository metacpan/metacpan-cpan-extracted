package Term::ReadLine::Perl5::Dumb;
use strict; use warnings;
=head1 NAME

Term::ReadLine::Perl5::Dumb

=head1 DESCRIPTION

A non-OO package for dumb terminals similar to GNU's readline. The
preferred OO Package is L<Term::ReadLine::Perl5>.

Since L<Term::ReadLine::Perl5::readline> currently has global state,
when more than one interface is created, we fallback to this code.

=cut

eval "use rlib '.' ";  # rlib is now optional
use Term::ReadLine::Perl5::History;

sub get_line($) {
    my $term_IN = shift;
    scalar <$term_IN>;
}

=head1 SUBROUTINES

=head2 readline

B<readline>(I<$prompt>, [I<$in>, [I<$out>]])

A version readline for a dumb terminal, that is one that doesn't have
many terminal editing capabilities. I<$prompt> is the prompt to
display; optional arguments I<$in> and I<$out> specify input and
output file handles. I<STDIN> and I<STDOUT> are used when the
corresponding file handles are not given.

=cut

sub readline($;$$)
{
    my ($prompt,  $term_IN, $term_OUT) = @_;
    $term_IN  = \*STDIN  unless defined $term_IN;
    $term_OUT = \*STDOUT unless defined $term_OUT;
    my $old = select $term_OUT;
    local $\ = '';
    local $| = 1;
    print $term_OUT $prompt;
    local $/ = "\n";
    my $line;
    if (!defined($line = get_line($term_IN))) {
	select $old;
	return undef;
    }
    select $old;
    chomp($line);
    return $line;
}

=head1 SEE ALSO

L<Term::ReadLine::Perl5>
=cut

1;
