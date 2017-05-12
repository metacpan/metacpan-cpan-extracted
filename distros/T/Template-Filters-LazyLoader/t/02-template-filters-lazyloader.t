use strict;
use FindBin;
use File::Spec;
use Data::Dumper;
use lib ( 
    File::Spec->catfile( $FindBin::Bin , 'lib' ) ,
    File::Spec->catfile( $FindBin::Bin , '../lib' ),  
);
use Template;
use Test::More qw/no_plan/;
use Test::Differences;

my $HASH = {
    seattle_cool    => [ sub { "DUMMY" }, 1 ],
    okurahoma       => sub { "DUMMY" },
    osaka           => sub { "DUMMY" },
    seattle         => sub { "DUMMY" },
    tulsa           => [ sub { "DUMMY" } , 1 ],
    sukiyanen_osaka => sub { "DUMMY" },
    dynamic_osaka   => [ sub { "DUMMY" } , 1 ],
};

use_ok( 'Template::Filters::LazyLoader' );

my $lazy = Template::Filters::LazyLoader->new();
$lazy->base_pkg('CustomFilters');


my $tt = Template->new({
    FILTERS         => $lazy->load() , 
});

eq_or_diff( $HASH , $lazy->filters() );
 my $output = '';
 $tt->process(\*DATA , {} , \$output ) or die $@;

like( $output , qr/osaka/, 'osaka');
like( $output , qr/sukiyanen_osaka/ , 'sukiyanen_osaka' );
like( $output , qr/dynamic_osaka/ , 'dynamic_osaka' );
like( $output , qr/seattle/ , 'seattle' );
like( $output , qr/seattle_cool/ , 'seattle_cool' );
like( $output , qr/okurahoma/ , 'okurahoma' );
like( $output , qr/OKURAHOMA_TULSA_OK/ , 'tulsa' );
__END__
[% 'never' | seattle_cool %]
[% 'never' | okurahoma %]
[% 'never' | osaka %]
[% 'never' | seattle %]
[% 'never' | dynamic_osaka %]
[% 'never' | sukiyanen_osaka %]
[% FILTER tulsa('OKURAHOMA_' , 'TULSA_') %]OK[% END %]
