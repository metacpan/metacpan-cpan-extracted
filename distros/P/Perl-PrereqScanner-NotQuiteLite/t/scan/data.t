use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::scan::Util;

test(<<'TEST'); # PHILCROW/Bigtop-0.38/lib/Bigtop/Parser.pm
sub build_lookup_hash {
    my $self = shift;

    return [
        {
            __TYPE__ => 'schema',
            __DATA__ => [ $self->{__NAME__} => $self->{__IDENT__} ],
        }
    ];
}
TEST

done_testing;
