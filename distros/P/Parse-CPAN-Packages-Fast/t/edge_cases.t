use strict;
use warnings 'FATAL', 'all';
BEGIN {
    if (!eval { require Compress::Zlib; 1 }) {
	print "1..0 # skip No Compress::Zlib installed\n";
	exit 0;
    }
}
use File::Temp qw(tempfile);
use Test::More 'no_plan';

use Parse::CPAN::Packages::Fast;

{
    my $p = create_test_object(<<EOF);
Kwalify                            1.20something  S/SR/SREZIC/Kwalify-1.20something.tar.gz
Kwalify                            1.21  S/SR/SREZIC/Kwalify-1.21.tar.gz
EOF
    is $p->latest_distribution('Kwalify')->version, '1.21', 'Can deal with non-numeric versions';
}

sub create_test_object {
    my($data) = @_;
    my($tmpfh,$tmpfile) = tempfile(SUFFIX => '.txt.gz', UNLINK => 1)
	or die $!;
    print $tmpfh Compress::Zlib::memGzip("Some header line\n\n$data");
    close $tmpfh
	or die $!;

    my $p = Parse::CPAN::Packages::Fast->new($tmpfile);
    isa_ok $p, 'Parse::CPAN::Packages::Fast';
    $p;
}
