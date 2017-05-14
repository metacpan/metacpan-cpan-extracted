package Term::ReadLine::Tiny::readline;
=head1 NAME

Term::ReadLine::Tiny::readline - A non-OO package of Term::ReadLine::Tiny

=head1 VERSION

version 1.08

=head1 SYNOPSIS

	use Term::ReadLine::Tiny::readline;
	
	while ( defined($_ = readline("Prompt: ")) )
	{
		print "$_\n";
	}
	print "\n";
	
	$s = "";
	while ( defined($_ = readkey(1)) )
	{
		$s .= $_;
	}
	print "\n$s\n";

=cut
use strict;
use warnings;
use v5.10.1;
use Term::ReadLine::Tiny;


BEGIN
{
	require Exporter;
	our $VERSION     = '1.08';
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw(readline readkey);
	our @EXPORT_OK   = qw();
}


=head1 Functions

=cut
=head2 readline([$prompt[, $default[, IN[, OUT]]]])

interactively gets an input line. Trailing newline is removed.

Returns C<undef> on C<EOF>.

=cut
sub readline
{
	my ($prompt, $default, $IN, $OUT) = @_;
	my $term = Term::ReadLine::Tiny->new(undef, $IN, $OUT);
	return $term->readline($prompt, $default);
}

=head2 readkey([$echo[, IN[, OUT]]])

reads a key from input and echoes if I<echo> argument is C<TRUE>.

Returns C<undef> on C<EOF>.

=cut
sub readkey
{
	my ($echo, $IN, $OUT) = @_;
	my $term = Term::ReadLine::Tiny->new(undef, $IN, $OUT);
	return $term->readkey($echo);
}


1;
__END__
=head1 SEE ALSO

=over

=item *

L<Term::ReadLine::Tiny|https://metacpan.org/pod/Term::ReadLine::Tiny> - Tiny implementation of ReadLine

=back

=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/p5-Term-ReadLine-Tiny>

B<CPAN> L<https://metacpan.org/release/Term-ReadLine-Tiny>

=head1 AUTHOR

Orkun Karaduman <orkunkaraduman@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman <orkunkaraduman@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
