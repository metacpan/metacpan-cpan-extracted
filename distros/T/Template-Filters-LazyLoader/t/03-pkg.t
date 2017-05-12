use strict;
use FindBin;
use File::Spec;
use lib ( 
    File::Spec->catfile( $FindBin::Bin , 'lib' ) ,
    File::Spec->catfile( $FindBin::Bin , '../lib' ),  
);
use Template;
use Test::More qw/no_plan/;
use Test::Exception;
use_ok( 'Template::Filters::LazyLoader' );


# no pkg or base_pkg or no pkgs test
{
    my $lazy = Template::Filters::LazyLoader->new();
   throws_ok { $lazy->load() }  qr/You must set base_pkg or pkg or pkgs\./ , 'please die' ;
}

# set not exsisting package.
{
   my $lazy = Template::Filters::LazyLoader->new();
   $lazy->pkg('xxx');
   dies_ok { $lazy->load() } 'please dieeeee' ;
}

# finally
{
    my $lazy = Template::Filters::LazyLoader->new();
    $lazy->pkg('CustomFilters::Seattle');
    
    my $tt = Template->new({
        FILTERS         => $lazy->load() , 
    });
    my $output = '';
    $tt->process(\*DATA , {} , \$output ) or die $@;
    like( $output , qr/seattle/ , 'seattle' );

}

__END__
[% 'never' | seattle %]
