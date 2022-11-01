#!perl
# t/001_load.t - check module loading and create testing directory
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG @modules );
    use Test::More qw( no_plan );
    our @modules;
    use Module::Generic::File qw( file );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use strict;
    use warnings;
    my $lib = file( './lib' );
    $lib->find(sub
    {
        return(1) unless( $_->extension eq 'pm' );
        diag( "Checking file '$_'" ) if( $DEBUG );
        my $base = $_->relative( $lib );
        $base =~ s,\.pm$,,;
        $base =~ s,/,::,g;
        push( @modules, $base );
    });
    use_ok( $_ ) for( sort( @modules ) );
};

done_testing();

__END__

r