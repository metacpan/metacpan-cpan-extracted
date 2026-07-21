#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/92.manifest.t
##----------------------------------------------------------------------------
BEGIN
{
    use strict;
    use warnings FATAL => 'all';
    use Test::More;
    unless( $ENV{AUTHOR_TESTING} )
    {
        plan( skip_all => "Author tests not required for installation" );
    }
};

my $min_tcm = 0.9;

eval "use Test::CheckManifest $min_tcm";
plan skip_all => "Test::CheckManifest $min_tcm required" if( $@ );

ok_manifest( { filter => [qr/Format\.bs/, qr/PersonName-Format\.c/, qr/PersonName-Format\.o/] } );

done_testing;
