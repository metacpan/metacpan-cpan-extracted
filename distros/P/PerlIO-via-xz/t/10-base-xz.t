#!/pro/bin/perl

use 5.12.0;
use warnings;

use Test::More;

eval {
    require IO::Compress::Xz;
    require IO::Uncompress::UnXz;
    $IO::Compress::Xz::XzError = 0;
    1;
    } or do { ok (1, "Prereqs not met"); done_testing; exit 0; };

ok (my $txt = "Lorem ipsum dolor sit amet\n", "Set text");
my $xz;

for ([ MORMAL => "\xff\xfe\xff\xfe" x 16	],
     [ EMPTY  => ""				],
     [ UNDEF  => undef				],
     [ REF    => \40				],) {

    my ($rst, $rs) = @$_;
    local $/ = $rs;

    ok (1, "Testing for RS $rst");

    {   my $z = IO::Compress::Xz->new (\$xz)     or die $IO::Compress::Xz::XzError;
	ok ($z->print ($txt), "print");
	ok ($z->close, "close");
	}

    {   my $z = IO::Uncompress::UnXz->new (\$xz) or die $IO::Uncompress::UnXz::UnXzError;
	ok (my $data = $z->getline, "getline");
	is ($data, $txt, "Roundtrip");
	}

    {   local $/ = undef;
	my $z = IO::Uncompress::UnXz->new (\$xz) or die $IO::Uncompress::UnXz::UnXzError;
	ok (my $data = $z->getline, "getline \$/ = undef");
	is ($data, $txt, "Roundtrip");
	}

    {   my $z = IO::Uncompress::UnXz->new (\$xz) or die $IO::Uncompress::UnXz::UnXzError;
	local $/ = undef;
	ok (my $data = $z->getline, "getline \$/ = undef");
	is ($data, $txt, "Roundtrip");
	}
    }

done_testing;
