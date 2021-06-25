use strict;
use warnings;
use Test::More;
use Test::Exception;
use Digest::MD5 ();
use Storable    ();
use File::Temp  ();

use_ok q{Sub::Genius};

# default caching behavior

my $sq = Sub::Genius->new( preplan => q{A&B&C} );
unlink $sq->cachefile;

isa_ok $sq, q{Sub::Genius};
can_ok( $sq, qw/cachedir checksum cachefile/ );
is $sq->preplan, q{[A]&[B]&[C]}, q{PRE retained and preprocessed successfully};
is Digest::MD5::md5_hex(q{[A]&[B]&[C]}), $sq->checksum, q{PRE checksum as expected};

# cache file doesn't exist yet
ok !-e $sq->cachefile, q{Default cached PRE file doesn't exists};
$sq->init_plan;    # caching is triggered
ok -e $sq->cachefile, q{Default cached PRE file exists};
is_deeply Storable::retrieve( $sq->cachefile ), $sq->dfa, q{Cached DFA from PRE as expected};
is( ref $sq->dfa, q{FLAT::DFA::Minimal}, q{DFA confirmed} );

$sq = Sub::Genius->new( preplan => q{A&B&C} );
ok -e $sq->cachefile, q{Default cached PRE file exists};
$sq->init_plan;    # caching is triggered
is_deeply Storable::retrieve( $sq->cachefile ), $sq->dfa, q{Cached DFA from PRE as expected};
is( ref $sq->dfa, q{FLAT::DFA::Minimal}, q{DFA confirmed} );

# clean for next test
unlink $sq->cachefile;

# caching with custom director

my $dir = File::Temp::tempdir( CLEANUP => 1 );
$sq = Sub::Genius->new( preplan => q{A&B&C}, cachedir => $dir );
unlink $sq->cachefile;

isa_ok $sq, q{Sub::Genius};
can_ok( $sq, qw/cachedir checksum cachefile/ );
is $sq->preplan, q{[A]&[B]&[C]}, q{PRE retained and preprocessed successfully};
is Digest::MD5::md5_hex(q{[A]&[B]&[C]}), $sq->checksum, q{PRE checksum as expected};

# cache file doesn't exist yet
ok !-e $sq->cachefile, q{Default cached PRE file doesn't exists};
$sq->init_plan;    # caching is triggered
ok -e $sq->cachefile, q{Default cached PRE file exists};
is_deeply Storable::retrieve( $sq->cachefile ), $sq->dfa, q{Cached DFA from PRE as expected};
is( ref $sq->dfa, q{FLAT::DFA::Minimal}, q{DFA confirmed} );

$sq = Sub::Genius->new( preplan => q{A&B&C}, cachedir => $dir );
ok -e $sq->cachefile, q{Default cached PRE file exists};
$sq->init_plan;    # caching is triggered
is_deeply Storable::retrieve( $sq->cachefile ), $sq->dfa, q{Cached DFA from PRE as expected};
is( ref $sq->dfa, q{FLAT::DFA::Minimal}, q{DFA confirmed} );

# clean for next test
unlink $sq->cachefile;

# caching off altogether

$sq = Sub::Genius->new( preplan => q{A&B&C}, cachedir => undef );

is Digest::MD5::md5_hex(q{[A]&[B]&[C]}), $sq->checksum, q{PRE checksum as expected};
is undef, $sq->cachedir,  q{cachedir not defined};
is undef, $sq->cachefile, q{cachefile not defined};
$sq->init_plan;    # caching is triggered

done_testing();

exit;

__END__
