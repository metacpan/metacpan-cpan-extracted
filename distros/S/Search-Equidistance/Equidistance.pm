package Search::Equidistance;

use 5.008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Search::Equidistance ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(decode);
	
our $VERSION = '0.01';

# Preloaded methods go here.

sub decode {
croak("Usage: decode(string, max-skip, file) ") unless(@_ == 3);

my ($find, $MAXSKIP, $file) = @_;
my $rfind = reverse($find);
open F, $file or die "No such file $file: $!\n";

my $line = join "", <F>;
$line =~ s/(\W|\n)//g;

my ($sum_count, $n, $found, $sm, $i, $end, $match, $len, $pos, $count);

$sum_count = 0;
for $n (1..$MAXSKIP) {
	$found = 0;
	$sm = $n - 1;
	for $i (0..$sm) {
		$end = $sm - $i;
		$match = "\.\{0,$i\}\(\.{0,1}\)\.\{0\,$end\}";
		($_ = $line) =~ s/$match/$1/g;
		$len = length;
		$pos = 0;
		$count = 0;
		while (/$find|$rfind/i) {
			$found++;
			print "[Skip=$n]\n" if ($found == 1);
			$count++;
			print "<$i:$len>" if ($count == 1);
			$pos += length($`);
			print "$&($pos)";
			$pos += length($&);
			s/$`$&//;
		}
		print "\n" if ($count > 0);
		$sum_count += $count;
	}
}
print "\n=== String $find are found $sum_count times (forward & reverse) ===\n";

}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Search::Equidistance - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Search::Equidistance;
  decode ($search_string, $MAXSKIP, $file);

=head1 ABSTRACT

  This should be the abstract for Search::Equidistance.
  The abstract is used when making PPD (Perl Package Description) files.
  If you don't want an ABSTRACT you should also edit Makefile.PL to
  remove the ABSTRACT_FROM option.

=head1 DESCRIPTION

  First converts file to contiguous_single_line text composed of
  alphabets and digits only. Then for skip 1(normal text) thru MAXSKIP,
  generates partial texts, searches the string (case-insensitive, forward,
  and reverse) and lists the find as follows. 

  Example output:

  $ run_decode.pl ABC 5 code.10000
  [Skip=3]
  <0:3334>CBA(405)ABC(811)
  <1:3333>CBA(1249)
  [Skip=4]
  <2:2500>CBA(900)
  [Skip=5]
  <0:2000>CBA(1115)
  <4:2000>ABC(406)CBA(1827)

  "=== String ABC are found 7 times (forward & reverse) ==="

  where
  [Skip=3] has 3 partial texts (text-0, text-1, text-2)
  <0:3334> means text-0 (of length 3334),
           code.10000 being length 10000
  CBA(405)ABC(811) => string CBA found in position 405, and
                      ABC in position 811 (starting position 0)
  
=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Hack Sung Lee, E<lt>hslee@xylan.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Hack Sung Lee

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
