#!perl

package Schema::RDBMS::AUS::Crypt::SHA1;

use strict;
use warnings;
use Digest::SHA1 qw(sha1_hex);

return 1;

sub crypt {
    return sha1_hex($_[1]);
}
