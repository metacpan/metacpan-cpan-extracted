#!perl -T

use warnings;
use strict;

use File::Spec::Functions;
use Test::More;
use Test::Exception;
use lib qw( lib );

BEGIN {
    eval "use XML::Writer";
    if ($@) {
	plan skip_all => "XML::Writer required for testing xml" if $@;
    } else {
	plan tests => 6;
    }
}

my $datadir      = q{data};  # test files

BEGIN { use_ok('Parse::Flash::Cookie') }
use Parse::Flash::Cookie;
ok(1);


my %file2content = (
    'WellGames_Glassez.sol' => qr|<sol name="WellGames_Glassez" created_by="Parse::Flash::Cookie" version="\d+\.\d+">.*</sol>\s*|s,
    'jellyblocks.sol'       => qr|<sol name="jellyblocks" created_by="Parse::Flash::Cookie" version="\d+\.\d+">.*</sol>\s*|s,
    );

foreach my $file (sort keys %file2content) {

    $file =~ qr|^([-+@\w./]+)$|;
    $file = $1;

    # locate test file
    my $file_with_path = catfile(q{data}, $file);
    ok(-f $file_with_path, qq{Expect '$file' to be a file on local filesystem});

 TODO: {
     local $TODO = q{Version 3 support not yet implemented};
     
     lives_ok( sub { Parse::Flash::Cookie::to_xml($file_with_path); },
	       q{Not implemented support for sol file v3 yet.});
    }
}

__END__
