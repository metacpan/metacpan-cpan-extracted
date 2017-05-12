use strict;
use warnings;
use Config;
use File::Path;
use Test::More tests => 8;

my $dir = "t/pods2html.d";
Simple($dir);
Empty($dir);
Subdir($dir);
Recurse($dir);

sub Simple {
	my $d = shift;

	my $pods2html = "blib/script/pods2html";
	my $template  = "$d/template.txt";
	my $values    = "$d/values.pl";

	rmtree("$d/html_act");
	system "$Config{perlpath} $pods2html $d/pod $d/html_act";
	ok !RDiff( "$d/html_exp", "$d/html_act" );

	rmtree("$d/html_act_t");
	system "$Config{perlpath} $pods2html --variables $values $d/pod $d/html_act_t $template";
	ok !RDiff( "$d/html_exp_t", "$d/html_act_t" );

	rmtree("$d/html_act_tv");
	system "$Config{perlpath} $pods2html --variables $values $d/pod $d/html_act_tv $template color=red";
	ok !RDiff( "$d/html_exp_tv", "$d/html_act_tv" );
}

sub Empty {
	my $d = shift;

	rmtree("$d/html_act");
	system "$Config{perlpath} blib/script/pods2html $d/pod $d/html_act";
	ok !RDiff( "$d/html_exp", "$d/html_act" );

	rmtree("$d/html_act");
	system "$Config{perlpath} blib/script/pods2html --empty $d/pod $d/html_act";
	ok !RDiff( "$d/empty_exp", "$d/html_act" );
}

sub Subdir {
	my $d = shift;

	rmtree("$d/A");
	system "$Config{perlpath} blib/script/pods2html $d/pod $d/A/B/C";
	ok !RDiff( "$d/html_exp", "$d/A/B/C" );
}

sub Recurse {
	my $d = shift;

	my $pods2html = "blib/script/pods2html";

	rmtree("$d/podR/HTML");
	system "$Config{perlpath} blib/script/pods2html $d/podR $d/podR/HTML";
	ok !RDiff( "$d/podR_exp", "$d/podR" );
	system "$Config{perlpath} blib/script/pods2html $d/podR $d/podR/HTML";
	ok !RDiff( "$d/podR_exp", "$d/podR" );
}

sub RDiff    # Recursive subdirectory comparison
{
	my ( $a, $b ) = @_;

	eval { DirCmp( $a, $b ) };

	print STDERR $@;
	$@;
}

sub DirCmp {
	my ( $a, $b ) = @_;

	my @a = Names($a);
	my @b = Names($b);

	ListCmp( \@a, \@b ) and die "Different names: $a $b\n";

	@a = map {"$a/$_"} @a;
	@b = map {"$b/$_"} @b;

	for ( @a, @b ) { -f or -d or die "bad type: $_\n" }

	while ( @a and @b ) {
		$a = shift @a;
		$b = shift @b;

		-f $a and -f $b and FileCmp( $a, $b ) and return "$a ne $b";
		-d $a and -d $b and DirCmp( $a, $b );
		-f $a and -d $b or -d $a and -f $b and return "type mismatch: $a $b";
	}

	'';
}

sub Names {
	my $dir = shift;

	opendir DIR, $dir or die "Can't opendir $dir: $!\n";
	my @names = grep { not m(^\.) and $_ ne 'CVS' } readdir(DIR);
	closedir DIR;

	sort @names;
}

sub ListCmp {
	my ( $a, $b ) = @_;

	@$a == @$b or return 1;

	for ( my $i = 0; $i < @$a; $i++ ) {
		$a->[$i] eq $b->[$i]
			or return 1;
	}

	0;
}

sub FileCmp {
	my ( $x, $y ) = @_;

	local $/ = undef;

	open my $fx, '<', $x or die "Can't open $x: $!\n";
	open my $fy, '<', $y or die "Can't open $y: $!\n";

	return <$fx> ne <$fy>;
}
