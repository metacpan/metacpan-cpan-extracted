# Tests for PerlIO::via::xz

use 5.12.0;
use warnings;

use Test::More;

use File::Copy;

eval {
    require IO::Compress::Xz;
    require IO::Uncompress::UnXz;
    1;
    } or do { ok (1, "Prereqs not met"); done_testing; exit 0; };

use_ok ("PerlIO::via::xz");

my $txz = "test.xz";	END { $txz and unlink $txz }

my %txt;
my %xz;
for my $type (qw( plain banner )) {
    local $/;
    open my $fh, "<", "files/$type.txt" or die "$type.txt: $!\n";
    $txt{$type} = <$fh>;
    close $fh;

    open    $fh, "<", "files/$type.xz"  or die "$type.xz:  $!\n";
    $xz{$type}  = <$fh>;
    close $fh;
    }

# Check defaults
#cmp_ok(PerlIO::via::xz->level, "==", 1, "default worklevel");

my $fh;

# Opening/closing
ok ( open  ($fh, "<:via(xz)",  "files/plain.xz"),	"open for reading");
ok ( close ($fh),					"close file");

ok (!open  ($fh, "+<:via(xz)", "files/plain.xz"),	"read+write is impossible");

ok ( open  ($fh, ">:via(xz)",  $txz),			"open for write");
ok ( close ($fh),					"close file");

ok (!open  ($fh, "+>:via(xz)", $txz),			"write+read is impossible");
ok (!open  ($fh, ">>:via(xz)", $txz),			"append is not supported");

for ([ MORMAL => "\xff\xfe\xff\xfe" x 16	],
     [ EMPTY  => ""				],
     [ UNDEF  => undef				],
     [ REF_X  => \0x1ffffff			],
     [ REF    => \40				],) {

    my ($rst, $rs) = @$_;
    local $/ = $rs;
    $rst eq "REF" and $txt{$_} = substr $txt{$_}, 0, 40 for qw( plain banner );

    # Decompression
    for my $type (qw( plain banner )) {

	ok (open (my $fz, "<:via(xz)", "files/$type.xz"), "$rst:Open $type");
	my $data = <$fz>;
	if (defined $rs) {
	    is ($data, $txt{$type}, "$rst:$type decompression");
	    }
	else {
	    # Shorten the error message
	    is (substr ($data, 0, 40), substr ($txt{$type}, 0, 40),
		"$rst:$type decompression");
	    }
	}

    # Compression
    for my $type (qw( plain banner )) {
	my $fh;
	ok (open ($fh, ">:via(xz)", $txz), "$rst:Open $type compress");

	ok ((print { $fh } $txt{$type}), "$rst:Write");
	ok (close ($fh), "$rst:Close");
	}

    # Roundtrip
    for my $type (qw( plain banner )) {
	my $fh;
	ok (open ($fh, ">:via(xz)", $txz), "$rst:Open $type compress");

	ok ((print { $fh } $txt{$type}), "$rst:Write");
	ok (close ($fh), "$rst:Close");

	ok (open ($fh, "<:via(xz)", $txz), "$rst:Open $type uncompress");
	my $data = <$fh>;
	if (defined $rs) {
	    is ($data, $txt{$type}, "$rst:$type compare");
	    }
	else {
	    # Shorten the error message
	    is (substr ($data, 0, 40), substr ($txt{$type}, 0, 40),
		"$rst:$type compare");
	    }
	}
    }

done_testing;
