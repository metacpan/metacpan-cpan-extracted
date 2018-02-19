use strict;
use warnings;
use Test::More;

use Test::CPAN::Meta::JSON;
use SVG;

my $meta    = meta_spec_ok('MYMETA.json');
my $version = $SVG::VERSION;

is( $meta->{version}, $version, 'MYMETA.json distribution version matches' );

if ( $meta->{provides} ) {
    foreach my $mod ( keys %{ $meta->{provides} } ) {
        eval("use $mod;");
        my $mod_version = eval( sprintf( "\$%s::VERSION", $mod ) );
        is( $meta->{provides}{$mod}{version},
            $version, "MYMETA.json entry [$mod] version matches" );
        is( $mod_version, $version, "Package $mod doesn't match version." );
    }
}

done_testing();
