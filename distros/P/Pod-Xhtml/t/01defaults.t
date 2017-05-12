#!/usr/local/bin/perl -w
#$Id: 01defaults.t,v 1.24 2007/07/16 11:09:29 andreww Exp $

use strict;
use lib qw(./lib ../lib);
use Test::More;
use Getopt::Std;
use File::Basename;

getopts('tTs', \my %opt);
if ($opt{t} || $opt{T}) {
	require Log::Trace;
	import Log::Trace print => {Deep => $opt{T}};
}

chdir ( dirname ( $0 ) );

require Test_LinkParser;

my $pod_links = Test_LinkParser->new();

plan tests => 21;

eval { require Pod::Xhtml };
ok( $Pod::Xhtml::VERSION, "Pod::Xhtml compiled" );

for my $tdata (['a'],
			   ['b'],
			   ['c', MakeIndex => 2],
			   ['e'],
			   ['FH'], # parsing from filehandle
			  ) {
	my($tname, %options) = @$tdata;
	my $podi = "$tname.pod";
	my $podo = "$tname.pod.xhtml";
	my $podg = "$tname.xhtml";
	my $parser = Pod::Xhtml->new(LinkParser => $pod_links, %options);

	unlink $podo if -e $podo;

	ok( ! -f $podo, "output file ($podo) doesn't exist");
	if($tname eq 'FH') {
		# test parsing from filehandles
		open(OUT, '>'.$podo) or die("Can't open out $podo: $!");
		$parser->parse_from_filehandle( \*DATA, \*OUT );
		close OUT;
	} else {
		# try parsing from file
		$parser->parse_from_file( $podi, $podo );
	}
	ok( -f $podo, "output file ($podo) created" );

	my $filecont = readfile( $podo );
	my $goodcont = readfile( $podg );
	DUMP("filecont ($podo)", \$filecont);
	DUMP("goodcont ($podg)", \$goodcont);
	ok( $filecont, "output file contains content $tname" );
	ok( $filecont =~ /\Q$goodcont\E/, "content $tname matches expected data" );
	undef $filecont;
	unlink $podo unless $opt{'s'};
}

sub readfile {
	my $filename = shift;
	local *IN;
	open(IN, '< ' . $filename) or die("Can't open $filename: $!");
	local $/ = undef;
	my $x = <IN>;
	close IN;
	return $x;
}

# Log::Trace stubs
sub TRACE {}
sub DUMP  {}

# this pod is for testing only!
__DATA__
=head1 NAME

A - Some demo POD

=head1 SYNOPSIS

	use Pod::Xhtml;
	my $px = new Pod::Xhtml;

=head1 DESCRIPTION

This is a module to translate POD to Xhtml. Lorem ipsum L<Dolor/Dolor> sit amet consectueur adipscing elit. Sed diam nomumny.
This is a module to translate POD to Xhtml. L<The Lorem entry|/Lorem> ipsum dolor sit amet
consectueur adipscing elit. Sed diam nomumny.
This is a module to translate F<POD> to Xhtml. B<Lorem> ipsum I<dolor> sit amet
C<consectueur adipscing> elit. X<Sed diam nomumny>.
This is a module to translate POD to Xhtml. See L</Lorem> ipsum dolor sit amet
consectueur adipscing elit. Sed diam L<nomumny>. L<http://foo.bar/baz/>

=head1 METHODS

=over 4

=item Nested blocks

Pod::Xhtml now supports nested over/item/back blocks:

=over 4

=item *

Point 1

=item *

Point Number 2

=item *

Item three

=item *

Point four

Still point four

  This is verbatim text in a bulleted list

=back

  This is verbatim test in a regular list

=back

=head2 TOP

This should NOT reference #TOP, unless the top of the page has had its id
changed, somehow, for some reason.

=head2 EXAMPLE

This is the first example block.

=head1 ATTRIBUTES

=over 4

=item Lorem

Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.

=item Ipsum

Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.

=item Dolor( $foo )

Lorem ipsum dolor sit amet consectueur ..Z<>.. elit. Sed diam nomumny.

=back

=head2 EXAMPLE

This is the second example block.

=head1 ISSUES

=head2 KNOWN ISSUES

There are some issues known about. Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.
Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny. S<SPACES   ARE  IMPORTANT>

=head2 UNKNOWN ISSUES

There are also some issues not known about. Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.
Lorem ipsum dolor sit amet consectueur adipscing elit. Sed diam nomumny.

=head3 EXAMPLE

This is the third example block.

=cut

