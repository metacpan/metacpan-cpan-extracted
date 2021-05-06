use strict;
use warnings;
use Test::More;

use_ok q{Sub::Genius};

my $sq = Sub::Genius->new( preplan => q{A&B&C} );
is $sq->preplan, q{[A]&[B]&[C]}, q{PRE retained and preprocessed successfully};

$sq = Sub::Genius->new( preplan => q{A*&B&C} );
is $sq->preplan, q{[A]*&[B]&[C]}, q{PRE retained and preprocessed successfully};

$sq = Sub::Genius->new( preplan => q{begin&middle*&end} );
is $sq->preplan, q{[begin]&[middle]*&[end]}, q{PRE retained and preprocessed successfully};

$sq = Sub::Genius->new( preplan => q{begin*&middle*&end*} );
is $sq->preplan, q{[begin]*&[middle]*&[end]*}, q{PRE retained and preprocessed successfully};

$sq = Sub::Genius->new( preplan => q{begin*|middle*&end*} );
is $sq->preplan, q{[begin]*|[middle]*&[end]*}, q{PRE retained and preprocessed successfully};

$sq = Sub::Genius->new( preplan => q{A & B & C}, preprocess => 0 );
is $sq->preplan, q{A & B & C}, q{PRE retained and preprocessed successfully};

$sq = Sub::Genius->new( preplan => q{A & B & C}, preprocess => undef );
is $sq->preplan, q{A & B & C}, q{PRE retained and preprocessed successfully};

$sq = Sub::Genius->new( preplan => q{begin & middle & end}, preprocess => undef );
is $sq->preplan, q{begin & middle & end}, q{PRE retained and preprocessed successfully};

done_testing();

exit;

__END__
