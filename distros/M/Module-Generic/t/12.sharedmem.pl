#!perl
BEGIN
{
    use strict;
    use lib './lib';
    use Module::Generic::SharedMem;
    # our $DEBUG = 0;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

{
    # We open it in write mode, but not create, because 80.notes.t will have created for us already
    my $shem = Module::Generic::SharedMem->new(
        debug => $DEBUG,
        create => 0,
        key => 'test_key',
        size => 2048,
        destroy => 0,
        mode => 0666,
    );
    # For debugging only
    # $shem->create(1);
    # $shem->destroy(1);
    my $s = $shem->open || do
    {
        print( STDOUT $shem->error, "\n" );
        die( $shem->error );
    };
    my $ref = $s->read;
    defined( $ref ) || do
    {
        print( STDOUT $s->error, "\n" );
        die( $s->error );
    };
    ref( $ref ) eq 'HASH' || do
    {
        print( STDOUT "Shared memory data ($ref) is not an hash reference.\n" );
        die( "Shared memory data ($ref) is not an hash reference." );
    };
    # $ref = {};
    $ref->{year} = 2021;
    defined( $s->write( $ref ) ) || do
    {
        print( STDOUT "Unable to write to shared memory: $!\n" );
        die( "Unable to write to shared memory: $!" );
    };
    # $ref = $s->read;
    # ref( $ref ) eq 'HASH' || die( "Shared memory data is not an hash reference." );
    print( STDOUT "ok\n" );
    # $s->remove;
    exit( 0 );
}

__END__

