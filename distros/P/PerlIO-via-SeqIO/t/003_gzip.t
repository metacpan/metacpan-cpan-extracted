#-*-perl-*-
# $Id$
use strict;
use warnings;
use lib '../lib';
use Test::More tests => 4;
use File::Temp qw(tempfile);
use_ok('PerlIO::via::SeqIO');
use PerlIO::via::SeqIO;

my $HAVE_VIA_GZIP = eval "require PerlIO::via::gzip; 1";
SKIP : {
    skip "PerlIO::via::gzip unavailable", 3 unless $HAVE_VIA_GZIP;
    my $tpref = File::Spec->catfile('t', 'test');
    ok open(my $fh, "<:via(gzip):via(SeqIO::fasta)", "$tpref.fas.gz"), 'open test.fas.gz for reading via SeqIO';
    my ($tmph, $tmpf) = tempfile(UNLINK=>1);
    close($tmph);
    ok open(my $zfh, '>:via(gzip):via(SeqIO::embl)', $tmpf), 'open conversion target via gzip';
    {
	local $/;
	my $slurp = <$fh>;
	print $zfh $slurp;
	close($zfh);
    }
    open(my $targh, "<:via(gzip)", $tmpf);
    open(my $testh, "<$tpref.embl");
    my @targ = <$targh>;
    my @test = <$testh>;
    is_deeply(\@targ, \@test, "embl conversion via gzip correct");
    close($targh)
}
