#!/usr/bin/perl
#
# search the lib tree for pm/pod files containing pod comments and convert them to html
#

use Pod::Simple::HTML;
use File::Find;
use IO::File;
use File::Basename;

my $outdir = $ARGV[0] || "html";
my @files = ();

sub wanted {
    my $f = $File::Find::name;
    return if $f =~ /CVS/;
    return if $f =~ /pfe_bak/;
    return unless $f =~ /\.p(m|od)$/;

    my $fh = new IO::File "<$f";
    return unless ref($fh);
    local $_;
    while(<$fh>) {
        if(/^=head1/) {
            push(@files,$f);
            return;
        }
    }
    $fh = undef;
}
find({ no_chdir => 1, wanted => \&wanted } ,"lib");

for my $f (@files) {
    my $bn = basename($f);
    my $out = $bn;
    $out =~ s/\.p(m|od)$/.html/;

    print "Writing $outdir/$out\n";
    Pod::Simple::HTML->parse_from_file($f,"$outdir/$out");
}
