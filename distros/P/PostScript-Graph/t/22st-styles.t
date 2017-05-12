#!/usr/bin/perl
use strict;
use warnings;

use Test;
BEGIN { plan tests => 23 };
use PostScript::File 0.12 qw(check_file);
ok(1);
use PostScript::Graph::Style 0.07;
ok(1);

my $s1 = new PostScript::Graph::Sequence;
ok($s1);
$s1->setup( "color",
    [ [ 1, 1, 0 ],    # yellow
      [ 0, 1, 0 ],    # green
      [ 0, 1, 1 ], ]  # cyan
    );
ok(1);

my $opts = {
	    sequence => $s1,
	    auto  => [qw(color dashes)],
	    color => 0,
	    line  => {
		width  => 2,
	    },
};

my $gf = new PostScript::File();
ok($gf);

my ($oldsid, $old);
for (my $c = 0; $c < 4; $c++) {
    my $s = new PostScript::Graph::Style($opts);
    $s->write($gf);
    my $id = $s->id();
    $id =~ /(\d+)\.(\d+)/;
    ok($1);
    ok($2);
    ok($oldsid, $1) if (defined $oldsid);
    $oldsid = $1;
    ok($old+1, $2) if (defined $old);
    $old = $2;
    $gf->add_to_page("% use style $id\n");
}
ok(1);

my $name = "t/22st-styles";
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
