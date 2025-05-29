#!perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More qw( no_plan );
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    use Module::Generic::File qw( tempfile );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Module::Generic::File::IO' );
};

use strict;
use warnings;
my $class= 'Module::Generic::File::IO';

subtest 'file io' => sub
{
    my $all_chars   = join( '', "\r\n", map( chr( $_ ), 1..255 ), "zzz\n\r" );
    my $file        = tempfile( auto_remove => 1 );
    my $expect      = quotemeta( $all_chars );
    use_ok( $class );

    use_ok( $class );
    can_ok( $class, 'binmode' );

    # file the file with binary data;
    # use standard open to make sure we can compare binmodes
    # on both.
    {
        my $tmp;
        diag( "Writing data to temporary file \"$file\"." ) if( $DEBUG );
        open( $tmp, '>', $file ) or BAIL_OUT( "Could not open '$file': $!" );
        binmode( $tmp );
        print( $tmp $all_chars );
        close( $tmp );
    }

    # now read in the file, once without binmode, once with.
    # without binmode should fail at least on win32...
    if( $^O =~ /MSWin32/i )
    {
        my $fh = $class->new;
        isa_ok( $fh, $class );
        ok( $fh->open( $file ), "Opened '$file'" );
    
        my $cont = do { local $/; <$fh> };
        unlike( $cont, qr/$expect/, "Content match fails without binmode" );
    }    

    # now with binmode, it must pass 
    {
        my $fh = $class->new;
        diag( "Error instantiating a $class object: ", $class->error ) if( $DEBUG && !defined( $fh ) );

        isa_ok( $fh, $class );
        ok( $fh->open( $file ), "Opened '$file' $!" );
        ok( $fh->binmode, "binmode enabled" );
        my $cont = do{ local $/; <$fh> };
        like( $cont, qr/$expect/, "Content match passes with binmode" );
    }
};

subtest 'getline' => sub
{
    my $file = __FILE__;
    my $io = Module::Generic::File::IO->new( $file );
    isa_ok( $io, 'Module::Generic::File::IO', "Opening $file" );

    my $line = $io->getline;
    like( $line, qr/^\#\!perl/, 'Read first line' );

    my( $list, $context ) = $io->getline;
    is( $list, "BEGIN\n", 'Read second line' );
    is( $context, undef, 'Did not read third line with getline() in list context' );

    $line = $io->getline;
    $line = $io->getline;
    like( $line, qr/^[[:blank:]]+use strict/, 'Read fourth line' );

    my @lines = $io->getlines;
    cmp_ok( @lines, '>', 3, 'getlines reads lots of lines' );
    like( $lines[-1], qr/^__END__/, 'last line' );

    $line = $io->getline;
    is( $line, undef, 'geline reads no more at EOF' );

    @lines = $io->getlines;
    is( @lines, 0, 'gelines reads no more at EOF' );

    # And again
    $io = Module::Generic::File::IO->new( $file );
    isa_ok( $io, 'Module::Generic::File::IO', "Opening $file" );

    $line = $io->getline;
    like( $line, qr/^\#\!perl/, 'Read first line again' );

    {
        no warnings 'Module::Generic::File::IO';
        is( ( $line = $io->getline( 'Boom' ) ), undef, 'caught an exception' );
    }
    like( $io->error->message, qr/usage.*getline\(\) at .* line /, 'getline usage' );
    is( $line, undef, 'return value is undef upon exception' );
    
    {
        no warnings 'Module::Generic::File::IO';
        ( $list, $context ) = $io->getlines( 'Boom' );
    }
    is( $list, undef, 'caught another exception' );
    like( $io->error->message, qr/usage.*getlines\(\) at .* line /, 'getlines usage' );
    is( $list, undef, 'empty return list in list context upon exception' );
    
    {
        no warnings 'Module::Generic::File::IO';
        is( ( $line = $io->getlines ), undef, 'caught another exception' );
    }
    like( $io->error->message, qr/Can't call .*getlines in a scalar context.* at .* line /, 'getlines in scalar context returns an exception' );
    is( $line, undef, 'return value is undef upon exception' );

    {
        no warnings 'Module::Generic::File::IO';
        is( $io->getlines, undef, 'caught another exception' );
    }
    like( $io->error->message, qr/Can't call .*getlines in a scalar context.* at .* line /, 'getlines in void context returns an exception' );
    is( $line, undef, 'return value is undef upon exception' );

    ( $list, $context ) = $io->getlines;
    is( $list, "BEGIN\n", 'Read third line' );
    like( $context, qr/^\{\n/, 'Read third line' );
};

done_testing();

__END__
