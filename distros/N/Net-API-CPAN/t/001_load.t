# -*- perl -*-
BEGIN
{
    use strict;
    use lib './lib';
    use vars qw( $DEBUG @modules );
    use Test::More qw( no_plan );
    use Module::Generic::File qw( file );
    our @modules;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

# To build the list of modules:
# find ./lib -type f -name "*.pm" -print | xargs perl -lE 'my @f=sort(@ARGV); for(@f) { s,./lib/,,; s,\.pm$,,; s,/,::,g; substr( $_, 0, 0, q{use_ok( ''} ); $_ .= q{'' );}; say $_; }'
BEGIN
{
    use strict;
    use warnings;
    my $lib = file(__FILE__)->parent->parent->child( 'lib' );
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

