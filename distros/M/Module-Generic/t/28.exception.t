BEGIN
{
    use strict;
    use warnings;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    # use open ':std' => ':utf8';
    use Test::More;
    use Config;
    use_ok( 'Module::Generic::Exception' ) || BAIL_OUT( "Unable to load Module::Generic::Exception" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

subtest 'basic exception creation' => sub
{
    my $e = Module::Generic::Exception->new( 'Something bad happened' );
    isa_ok( $e, 'Module::Generic::Exception' );
    is( $e->message, 'Something bad happened', 'Message stored correctly' );
    like( "$e", qr/Something bad happened/, 'Stringification returns message' );
};

subtest 'exception without message' => sub
{
    my $e = Module::Generic::Exception->new;
    isa_ok( $e, 'Module::Generic::Exception' );
    is( $e->message, '', 'Empty message' );
};

subtest 'threaded usage' => sub
{
    SKIP:
    {
        if( !$Config{useithreads} )
        {
            skip( 'Threads are not available on this system', 1 );
        }
        require threads;
        threads->import;

        my $thr = threads->create(sub
        {
            my $e = Module::Generic::Exception->new( "Threaded error" );
            my $msg = $e->message;
            return( $msg );
        });

        my $result = $thr->join;
        like( $result, qr/Threaded error/, 'Exception created and passed correctly in thread' );
    }
};

subtest 'exception as object and string' => sub
{
    my $e = Module::Generic::Exception->new( 'Mixed usage' );
    my $str = "$e";
    like( $str, qr/Mixed usage/, 'Stringified exception matches expected output' );
    is( $e->message, 'Mixed usage', 'Object still holds correct message' );
};

done_testing();

__END__
