# -*- perl -*-
#$Id: 001_roundtrip.t 517 2009-10-23 15:52:21Z maj $
use lib '../lib';
use Test::More tests => 10;

BEGIN { use_ok( 'PerlIO::via::gzip' ); }
use_ok('File::Temp');
use_ok('IO::Compress::Gzip');
use_ok('IO::Uncompress::Gunzip');
use File::Temp qw(tempfile);
use IO::Uncompress::Gunzip qw(gunzip);
use IO::Compress::Gzip qw(gzip);

my ($tmph, $tmpf) = tempfile;
ok open( $tmph, ">:via(gzip)", $tmpf), "open tempfile for compressed writing";
my ($first,$last) = (rand(), rand());
print $tmph $first,"\n";
for (0..1000) {
    print $tmph rand(),"\n";
}
print $tmph $last, "\n";
ok $tmph->close, "flush and put the lid down";
my $data;
gunzip $tmpf => \$data;
is( (split m{$/},$data)[0], $first, "first entry roundtrip" );
is( (split m{$/},$data)[-1], $last, "last entry roundtrip");
my $works = "It works!";
gzip \$works => $tmpf;
undef $tmph;
ok open($tmph, "<:via(gzip)", $tmpf), "open tempfile for decompressed reading";
is( my $a = <$tmph>, "It works!", "reading roundtrip" );

1;




