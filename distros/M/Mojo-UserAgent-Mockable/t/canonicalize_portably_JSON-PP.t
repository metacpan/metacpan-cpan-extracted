# Force JSON::MaybeXS to only use this one particular JSON-ish module.
use Devel::Hide qw(Cpanel::JSON::XS JSON::XS);
use Test::More;

eval 'use JSON::PP';
plan skip_all => 'JSON::PP required for this test' if($@);

require './t/record_playback.t';

