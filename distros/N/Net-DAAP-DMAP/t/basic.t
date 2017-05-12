#!perl
use strict;
use warnings;
my @dmap_files;
BEGIN { @dmap_files = <t/*.dmap> }
use Test::More tests => scalar @dmap_files;
use Net::DAAP::DMAP qw( dmap_unpack dmap_pack );

sub is_binary ($$;$) {
    $_[0] =~ s{([^[:print:]])}{sprintf "<%02x>", ord $1}ge;
    $_[1] =~ s{([^[:print:]])}{sprintf "<%02x>", ord $1}ge;
    goto &is;
}
if ( eval "use Data::HexDump; use Test::Differences; 1" ) {
    no warnings 'redefine';
    *is_binary = sub ($$;$) {
        my ( $value, $expected, $reason ) = @_;
        eq_or_diff( HexDump($value), HexDump($expected), $reason );
    };
}

for my $file (@dmap_files) {
    local $TODO = "Fix Net::DAAP::DMAP to understand the new content codes"
        if $file =~ /server-info/;
    my $data = do { open my $fh, '<', $file; binmode $fh; local $/; <$fh> };
    my $unpacked = dmap_unpack($data);
    my $repacked = dmap_pack($unpacked);
    #use YAML;
    #print Dump $unpacked;
    is_binary( $repacked, $data, "$file round trips" );
}
