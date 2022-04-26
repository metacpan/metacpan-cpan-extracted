# Force JSON::MaybeXS to only use this one particular JSON-ish module.
# We don't hide JSON::PP because Mojo::JSON loads it explicitly, but
# JSON::MaybeXS (used by Mojo::UserAgent::Mockable) should pick one of
# the XS options first.
use Devel::Hide qw(Cpanel::JSON::XS);
use Test::More;

eval 'use JSON::XS';
plan skip_all => 'JSON::XS required for this test' if($@);

require './t/record_playback.t';

