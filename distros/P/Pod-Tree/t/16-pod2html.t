use 5.006;
use strict;
use warnings;
use Config;
use Test::More;

my @Files  = qw(cut for link list paragraph sequence);
my $NFiles = @Files;

plan tests => 3 * $NFiles;

my $Dir = "t/pod2html.d";

for my $file (@Files) {
	my $pod  = "$Dir/$file.pod";
	my $html = "$Dir/$file.html";
	my $exp  = "$Dir/$file.exp";

	unlink $html;
	system "$Config{perlpath} blib/script/podtree2html --notoc $pod $html";
	ok !FileCmp( $html, $exp );
}

for my $file (@Files) {
	my $pod      = "$Dir/$file.pod";
	my $html     = "$Dir/$file.html_t";
	my $exp      = "$Dir/$file.exp_t";
	my $template = "$Dir/template.txt";
	my $values   = "$Dir/values.pl";

	unlink $html;
	system "$Config{perlpath} blib/script/podtree2html --notoc -variables $values $pod $html $template";
	ok !FileCmp( $html, $exp );
}

for my $file (@Files) {
	my $pod      = "$Dir/$file.pod";
	my $html     = "$Dir/$file.html_tv";
	my $exp      = "$Dir/$file.exp_tv";
	my $template = "$Dir/template.txt";
	my $values   = "$Dir/values.pl";

	unlink $html;
	system "$Config{perlpath} blib/script/podtree2html --notoc -variables $values $pod $html $template color=red";
	ok !FileCmp( $html, $exp );
}

sub FileCmp {
	my ( $x, $y ) = @_;

	local $/ = undef;

	open my $fx, '<', $x or die "Can't open $x: $!\n";
	open my $fy, '<', $y or die "Can't open $y: $!\n";

	return <$fx> ne <$fy>;
}
