#!/usr/bin/perl
use Test;
BEGIN { plan tests => 6 };
use PostScript::File 0.10 qw(check_file);
ok(1); # module found
use PostScript::Graph::Paper 0.08;
ok(1); # module found

my $gp = new PostScript::Graph::Paper(
	file => {
	    landscape => 1,
	    left => 40,
	    right => 40,
	    top => 30,
	    bottom => 30,
	    clipping => 1,
	    clipcmd => "stroke",
	    debug => 2,
	    errors => 1,
	    errx => 36,
	    erry => 300,
	},
	layout => {
	    key_width => 100,
	},
	x_axis => {
	    labels => [qw(aaa bbb ccc ddd eee fff ggg hhh iii jjj)],
	    show_lines => 1,
	    center => 1,
	    offset => 0,
	},
	y_axis => {
	    labels => [qw(aaa bbb ccc ddd eee fff ggg hhh iii jjj)],
	},
    );
ok($gp);

my $name = "t/04pa-twobars";
$gp->output( $name );
ok(1); # survived so far
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
