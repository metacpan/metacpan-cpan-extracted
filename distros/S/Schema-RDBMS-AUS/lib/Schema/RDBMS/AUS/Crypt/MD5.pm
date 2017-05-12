#!perl

package Schema::RDBMS::AUS::Crypt::MD5;

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

return 1;

sub crypt {
    return md5_hex($_[1]);
}
