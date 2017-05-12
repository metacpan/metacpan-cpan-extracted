package t::Util;
use strict;
use warnings;
use utf8;

use parent qw/Test::Builder::Module/;
our @EXPORT = qw/has_gearmand setup_gearmand/;

use File::Which qw/which/;
use Test::TCP;

my $gearmand = which('gearmand');

sub has_gearmand { !!$gearmand }

sub setup_gearmand {
    return Test::TCP->new(
        code => sub {
            my $port = shift;
            exec $gearmand, -p => $port;
            die "cannot execute $gearmand: $!";
        },
    );
}

1;
