#!/usr/bin/perl
use Test;
BEGIN { plan tests => 12 };
use PostScript::File 0.12 qw(check_file);
ok(1);
use PostScript::Graph::Paper 0.10;
ok(1);
use PostScript::Graph::Key 0.10;
ok(1);

my $gf = new PostScript::File();
ok($gf);
my $gk = new PostScript::Graph::Key(
	max_height => 300,
	num_items => 5,
    );
ok($gk);
my $keyw = $gk->width();
ok($keyw);

my $gp = new PostScript::Graph::Paper(
	file => $gf,
	layout => {
	    key_width => $keyw,
	},
    );
ok($gp);

my $layout_keyw = $gp->layout_key_width();
ok($layout_keyw, $keyw);

$gk->build_key( $gp );
ok(1);

my $name = "t/10ke-simple";
$gf->output( $name );
ok(1);
my $psfile = check_file( "$name.ps" );
ok($psfile);
ok( check_filesize($psfile, -s $psfile) );	# the chart looks different?
warn "Use ghostview or similar to inspect results file:\n$psfile\n";

sub check_filesize {
    my ($psfile, $pssize) = @_;
    my %fs;
    my $filesizes = 't/filesizes';
    
    if (open(IN, '<', $filesizes)) {
	while (<IN>) {
	    chomp;
	    my ($size, $file) = m/^(\d+)\t(.+)$/;
	    $fs{$file} = $size;
	}
	close IN;
    }
    
    my $exists = $fs{$psfile};
    my $res = ($fs{$psfile} == $pssize);
    $fs{$psfile} = $pssize;

    open(OUT, '>', $filesizes) or die "Unable to write to $filesizes : $!\n";
    while( my ($file, $size) = each %fs ) {
	print OUT "$size\t$file\n" if defined $file and defined $size;
    }
    close OUT;

    return 1 unless $exists;
    return $res;
}
