#!/usr/bin/perl -T

use Test::More tests => 138;
use Paranoid;
use Paranoid::IO::FileMultiplexer;
use Paranoid::Debug;
use Paranoid::IO qw(:all);
use Paranoid::Process qw(:pfork);
use Paranoid::Module;
use Fcntl qw(:DEFAULT :flock :mode :seek);

use constant DOUBLEMAX => 1019;

psecureEnv();

use strict;
use warnings;

my ( $obj, $block, $bat, $stream, $data, %stats, %streams, @addr, $content );
my $tfile = 't/piofm-test1';

unlink $tfile if -f $tfile;

#PDEBUG = 20;

# Test for invalid sizes
unlink $tfile if -t $tfile;
ok( !defined(
        $obj = Paranoid::IO::FileMultiplexer->new(
            file      => undef,
            blockSize => 512,
            )
        ),
    'piofm file name undefined 1'
    );
ok( !defined(
        $obj = Paranoid::IO::FileMultiplexer->new(
            file      => '',
            blockSize => 512,
            )
        ),
    'piofm file name ZLS 1'
    );
ok( !defined(
        $obj = Paranoid::IO::FileMultiplexer->new(
            file      => $tfile,
            blockSize => 512,
            )
        ),
    'piofm blockSize too small 1'
    );
ok( !defined(
        $obj = Paranoid::IO::FileMultiplexer->new(
            file      => $tfile,
            blockSize => 4194304,
            )
        ),
    'piofm blockSize too big 1',
    );
ok( !defined(
        $obj = Paranoid::IO::FileMultiplexer->new(
            file      => $tfile,
            blockSize => 8190,
            )
        ),
    'piofm blockSize not divisible 1',
    );

# Def block size init
ok( $obj = Paranoid::IO::FileMultiplexer->new( file => $tfile ),
    'piofm blockSize default 1' );
is( ( stat $tfile )[7], 4096, 'piofm default file size 1' );
$obj = undef;
unlink $tfile;

# Custom block size init
ok( $obj = Paranoid::IO::FileMultiplexer->new(
        file      => $tfile,
        blockSize => 8192
        ),
    'piofm blockSize custom 1'
    );
is( ( stat $tfile )[7], 8192, 'piofm custom file size 1' );

# Test block methods
ok( !defined( $block = Paranoid::IO::FileMultiplexer::Block->new($tfile) ),
    'piofm block invalid args 1' );
ok( !defined(
        $block = Paranoid::IO::FileMultiplexer::Block->new( $tfile, 2 )
        ),
    'piofm block invalid args 2'
    );
ok( $block = Paranoid::IO::FileMultiplexer::Block->new( $tfile, 0, 4096 ),
    'piofm block new 1' );
ok( !$block->allocate, "piofm block already allocated 1" );
ok( $block = Paranoid::IO::FileMultiplexer::Block->new( $tfile, 3, 4096 ),
    'piofm block new 2' );
ok( !$block->allocate, "piofm block already allocated 2" );
ok( $block = Paranoid::IO::FileMultiplexer::Block->new( $tfile, 2, 4096 ),
    'piofm block new 2' );
ok( $block->allocate, "piofm block allocate 1" );
ok( $block = Paranoid::IO::FileMultiplexer::Block->new( $tfile, 0, 4096 ),
    'piofm block new 3' );
is( $block->bwrite( "hello",   4 ),    5, "piofm bwrite 1" );
is( $block->bwrite( "goodbye", 4091 ), 5, "piofm bwrite 2" );
is( $block->bread( \$data, 4, 5 ), 5, "piofm bread 1" );
is( $data, "hello", "piofm bread validate 1" );
is( $block->bread( \$data, 4091, 15 ), 5, "piofm bread 2" );
is( $data,                   "goodb", "piofm bread validate 2" );
is( $block->bwrite("hello"), 5,       "piofm bwrite 3" );
is( $block->bread( \$data, undef, 9 ), 9, "piofm bread 3" );
is( $data,                   "helloello", "piofm bread validate 3" );
is( $block->bread( \$data ), 4096,        "piofm bread 4" );
is( $block->bread( \$data, 2048 ), 2048, "piofm bread 5" );
is( $block->bread( \$data ), 4096, "piofm bread full block 1" );

# Test file header block methods
$obj = $block = undef;
unlink $tfile;
$obj = Paranoid::IO::FileMultiplexer->new( file => $tfile );
ok( !defined(
        $block = Paranoid::IO::FileMultiplexer::Block::FileHeader->new(
            $tfile, 8155
            )
        ),
    'piofm fheader invalid args 1'
    );
ok( $block =
        Paranoid::IO::FileMultiplexer::Block::FileHeader->new( $tfile, 4096 ),
    'piofm fheader new 1'
    );
is( $block->writeSig, 28, 'piofm fheader write 1' );
is( $block->blocks,   1,  'piofm fheader get blocks 1' );
ok( $block->writeBlocks(6), 'piofm fheader write blocks 1' );
is( $block->readBlocks, 6, 'piofm fheader read blocks 1' );
is( $block->blocks,     6, 'piofm fheader get blocks 2' );
$block->writeBlocks(1);
ok( $block->readSig, 'piofm fheader readSig 1' );

%stats = $block->model;
warn "Int Size: $stats{intSize}\n";
warn "Cur File Size: $stats{curFileSize} ($stats{curFSHuman})\n";
warn "Max File Size: $stats{maxFileSize} ($stats{maxFSHuman})\n";
warn "Cur Streams: $stats{curStreams}\n";
warn "Max Streams: $stats{maxStreams}\n";
warn "Max Stream Size: $stats{maxStreamSize} ($stats{maxSSHuman})\n";

# Redo in 8K blocks
$obj = $block = undef;
unlink $tfile;
$obj =
    Paranoid::IO::FileMultiplexer->new( file => $tfile, blockSize => 8192 );
ok( defined( $block = $obj->header ), 'piofm fheader 1' );
is( $block->writeSig, 28, 'piofm fheader write 2' );
ok( $block->readSig, 'piofm fheader readSig 2' );
is( $block->blocks,    1,    'piofm fheader get blocks 3' );
is( $block->blockSize, 8192, 'piofm fheader blockSize 1' );

%stats = $block->model;
warn "Int Size: $stats{intSize}\n";
warn "Cur File Size: $stats{curFileSize} ($stats{curFSHuman})\n";
warn "Max File Size: $stats{maxFileSize} ($stats{maxFSHuman})\n";
warn "Cur Streams: $stats{curStreams}\n";
warn "Max Streams: $stats{maxStreams}\n";
warn "Max Stream Size: $stats{maxStreamSize} ($stats{maxSSHuman})\n";

# Delete references and reopen the file w/defaults
$obj = $block = undef;
ok( defined( $obj = Paranoid::IO::FileMultiplexer->new( file => $tfile ) ),
    'piofm open existing file 1' );
is( $obj->header->blockSize, 8192, 'piofm open existing block size match 1' );

# Write bad block size
pseek( $tfile, 10, SEEK_SET ) and pwrite( $tfile, pack 'Nx', 8155 );
ok( !$obj->header->readSig, 'piofm bad block size in file 1' );

# Test w/new object
$obj = $block = undef;
ok( !defined( $obj = Paranoid::IO::FileMultiplexer->new( file => $tfile ) ),
    'piofm open existing file with bad block size 1' );

# Write bad block count
$obj = $block = undef;
unlink $tfile;
$obj =
    Paranoid::IO::FileMultiplexer->new( file => $tfile, blockSize => 8192 );
pseek( $tfile, 19, SEEK_SET ) and pwrite( $tfile, pack 'NNx', 4, 0 );
ok( !$obj->header->validateBlocks, 'piofm block count mismatch 1' );
ok( !$obj->header->readSig,        'piofm block count mismatch 2' );

# Fix header
pseek( $tfile, 19, SEEK_SET ) and pwrite( $tfile, pack 'NNx', 1, 0 );
ok( $obj->header->readSig, 'piofm file header fixed 1' );

# Write extra data and test readSig again
pseek( $tfile, 0, SEEK_END ) and pwrite( $tfile, pack 'xxxx' );
ok( !$obj->header->readSig, 'piofm bad file size 1' );

# Create new file for further tests
$obj = $block = undef;
unlink $tfile;
$obj =
    Paranoid::IO::FileMultiplexer->new( file => $tfile, blockSize => 8192 );
ok( $obj->header->readSig, 'piofm fheader readSig 3' );

# Test stream records in the file header
ok( $obj->header->readStreams, 'piofm fheader readStreams 1' );
%streams = $obj->header->streams;
is( scalar keys %streams, 0, 'piofm fheader streams 1' );
ok( !$obj->header->addStream,      'piofm fheader addStream no args 1' );
ok( !$obj->header->addStream('a'), 'piofm fheader addStream no block n 1' );
ok( !$obj->header->addStream( 'a', -1 ),
    'piofm fheader addStream bad block n 1'
    );
%streams = $obj->header->streams;
is( scalar keys %streams, 0, 'piofm fheader streams 2' );
ok( $obj->header->addStream( 'a', 1 ), 'piofm fheader addStream 1' );
%streams = $obj->header->streams;
is( scalar keys %streams, 1, 'piofm fheader streams 3' );
is( $streams{a},          1, 'piofm fheader streams bn check 1' );
ok( $obj->header->addStream( 'foo', 4 ), 'piofm fheader addStream 2' );
%streams = $obj->header->streams;
is( scalar keys %streams, 2, 'piofm fheader streams 4' );
is( $streams{foo},        4, 'piofm fheader streams bn check 2' );

# Test Stream header blocks
$stream =
    Paranoid::IO::FileMultiplexer::Block::StreamHeader->new( $tfile, 1, 8192,
    'a' );
ok( defined $stream,     'piofm sheader new 1' );
ok( !$stream->readSig,   'piofm sheader readSig before allocate 1' );
ok( $stream->allocate,   'piofm sheader allocate 1' );
ok( $stream->writeSig,   'piofm sheader writeSig 1' );
ok( !$stream->addBAT(1), 'piofm sheader addBAT invalid bn 1' );
ok( !$stream->addBAT(),  'piofm sheader addBAT invalid bn 2' );
ok( $stream->addBAT(2),  'piofm sheader addBAT 1' );
is( $stream->eos, 0, 'piofm sheader eos is zero 1' );
ok( $stream->writeEOS(127), 'piofm sheader eos set 1' );
is( $stream->eos, 127, 'piofm sheader eos is zero 1' );
ok( $stream->validateEOS,         'piofm sheader eos validate 1' );
ok( $obj->header->writeBlocks(2), 'piofm fheader writeBlocks 1' );

# Test BAT header blocks
$bat = Paranoid::IO::FileMultiplexer::Block::BATHeader->new( $tfile, 2, 8192,
    'a', 0 );
ok( defined $bat,                 'piofm bheader new 1' );
ok( !$bat->readSig,               'piofm bheader readSig before allocate 1' );
ok( $bat->allocate,               'piofm bheader allocate 1' );
ok( $bat->writeSig,               'piofm bheader writeSig 1' );
ok( !$bat->addData(1),            'piofm bheader addData invalid bn 1' );
ok( !$bat->addData(),             'piofm bheader addData invalid bn 2' );
ok( $bat->addData(3),             'piofm bheader addData 1' );
ok( $obj->header->writeBlocks(3), 'piofm fheader writeBlocks 2' );

# Clean up first missing data block
$block = Paranoid::IO::FileMultiplexer::Block->new( $tfile, 3, 8192 );
ok( defined $block,               'piofm data block new 1' );
ok( $block->allocate,             'piofm data block allocate 1' );
ok( $obj->header->writeBlocks(4), 'piofm fheader writeBlocks 3' );

# Test verification
ok( !$obj->chkConsistency, 'piofm chkConsistency missing stream header 1' );

# Test corrupt flag
ok( !$obj->addStream('bar'), 'piofm corrupt flag 1' );

# Fix stream foo
$stream =
    Paranoid::IO::FileMultiplexer::Block::StreamHeader->new( $tfile, 4, 8192,
    'foo' );
ok( defined $stream,              'piofm sheader new 1' );
ok( $stream->allocate,            'piofm sheader allocate 1' );
ok( $stream->writeSig,            'piofm sheader writeSig 1' );
ok( $obj->header->writeBlocks(5), 'piofm fheader writeBlocks 4' );

# Test verification
ok( $obj->chkConsistency, 'piofm chkConsistency stream header fixed 1' );

# Test corrupt flag again
ok( $obj->addStream('bar'), 'piofm addStream bar 1' );
is( $obj->header->blocks, 8, 'piofm blocks after bar 1' );

# Test _getStream
$stream = $obj->_getStream('foo');
ok( defined $stream, 'piofm _getStream 1' );
is( $stream->streamName, 'foo', 'piofm check stream name 1' );

# Test _calcAddr
@addr = $obj->_calcAddr(0);
is( $addr[0], 0, 'piofm calcAddr start of stream 1' );
is( $addr[1], 0, 'piofm calcAddr start of stream 2' );
is( $addr[2], 0, 'piofm calcAddr start of stream 3' );
@addr = $obj->_calcAddr( $obj->header->blockSize / 2 );
is( $addr[0], 0,                           'piofm calcAddr mid-block 1' );
is( $addr[1], 0,                           'piofm calcAddr mid-block 2' );
is( $addr[2], $obj->header->blockSize / 2, 'piofm calcAddr mid-block 3' );
@addr = $obj->_calcAddr( $obj->header->blockSize );
is( $addr[0], 0, 'piofm calcAddr next block 1' );
is( $addr[1], 1, 'piofm calcAddr next block 2' );
is( $addr[2], 0, 'piofm calcAddr next block 3' );
@addr =
    $obj->_calcAddr(
    $obj->header->blockSize + ( $obj->header->blockSize / 2 ) );
is( $addr[0], 0,                           'piofm calcAddr next block 4' );
is( $addr[1], 1,                           'piofm calcAddr next block 5' );
is( $addr[2], $obj->header->blockSize / 2, 'piofm calcAddr next block 6' );
@addr = $obj->_calcAddr(
    DOUBLEMAX * 4 * $obj->header->blockSize + 7 + $obj->header->blockSize );
is( $addr[0], 4, 'piofm calcAddr far block 1' );
is( $addr[1], 1, 'piofm calcAddr far block 2' );
is( $addr[2], 7, 'piofm calcAddr far block 3' );

# Test _growStream
my $blocks = $obj->header->blocks;
is( $obj->_growStream( "a", $obj->_calcAddr(0) ), 1, 'piofm growStream 1' );
is( $obj->_growStream( "a", $obj->_calcAddr( $obj->header->blockSize * 4 ) ),
    $blocks + 3,
    'piofm growStream 2'
    );

# Test strmWrite
my $msga = 'This is stream "a". ' x 100;
is( $obj->strmWrite( 'a', $msga ), length $msga, 'piofm strmWrite to a 1' );
is( $obj->strmTell('a'), length $msga, 'piofm strmTell stream a 1' );
my $msgb = 'This write 2 to stream "a". ' x 600;
is( $obj->strmWrite( 'a', $msgb ), length $msgb, 'piofm strmWrite to a 2' );
is( $obj->strmTell('a'), length $msga . $msgb, 'piofm strmTell stream a 2' );
ok( $obj->strmSeek( 'a', 0, SEEK_SET ), 'piofm strmSeek 1' );
is( $obj->strmRead( 'a', \$content, length $msga ),
    length $msga, 'piofm strmRead a 1' );
is( $msga, $content, 'piofm stream a content match 1 ' );
is( $obj->strmRead( 'a', \$content, length $msgb ),
    length $msgb, 'piofm strmRead a 2' );
is( $msgb, $content, 'piofm stream a content match 2 ' );
ok( $obj->strmSeek( 'a', length($msga) - 100, SEEK_SET ),
    'piofm strmSeek 2' );
is( $obj->strmRead( 'a', \$content, 200 ), 200, 'piofm strmRead a 3' );
is( $content,
    substr( $msga, -100 ) . substr( $msgb, 0, 100 ),
    'piofm stream a content match 3'
    );

# Misc testing
$msga = 'This is stream "foo" . ' x 1000;
is( $obj->strmWrite( 'foo', $msga ), length $msga, 'piofm strmWrite to a 3' );
ok( $obj->strmAppend( 'foo', 'This is the end.' ), 'piofm strmAppend foo 1' );
ok( $obj->strmSeek( 'foo', -100, SEEK_END ), 'piofm strmSeek foo 1' );
is( $obj->strmRead( 'foo', \$content, 150 ),
    100, 'piofm strmRead foo past EOS 1' );
ok( $content =~ /This is the end.$/s, 'piofm stream foo content match 1' );
ok( $obj->strmTruncate( 'foo', 20 ), 'piofm stream foo truncate 1' );
is( $obj->strmRead( 'foo', \$content, 100 ),
    0, 'piofm strmRead foo past EOS 2' );
ok( $obj->strmSeek( 'foo', 0, SEEK_SET ), 'piofm strmSeek foo 2' );
is( $obj->strmRead( 'foo', \$content, 100 ), 20, 'piofm strmRead foo 1' );

# Fork-testing
$SIG{CHLD} = \&sigchld;
my ( $child, $pid );

SKIP: {
    skip( 'No Time::HiRes -- skipping permissions test', 1 )
        unless loadModule( 'Time::HiRes', qw(usleep) );

    $obj = $stream = $bat = $block = undef;
    unlink $tfile;

    $obj = Paranoid::IO::FileMultiplexer->new( file => $tfile, );
    $obj->addStream('odds');
    $obj->addStream('evens');

    # Fork some children and have them all write messages to various streams
    foreach $child ( 1 .. 10 ) {
        unless ( $pid = pfork() ) {
            for ( 1 .. 50 ) {
                my $intvl = int rand 500;
                usleep($intvl);
                $obj->strmAppend( ( $child % 2 ? 'odds' : 'evens' ),
                    "child $child: pid $$ test #$_ (slept $intvl usec)\n" );
            }
            exit 0;
        }
    }
    while ( childrenCount() ) { sleep 1 }
    sleep 5;

    # Count the number of lines in each stream
    $obj->strmSeek( 'odds', 0, SEEK_SET );
    $obj->strmRead( 'odds', \$content, 16384 );
    is( scalar split( /\n/s, $content ), 250, 'piofm fork line count 1' );

#     {
#         my @lines = split /\n/s, $content;
#         foreach $child ( 1, 3, 5, 7, 9 ) {
#             my @c1 = grep /child $child:/, @lines;
#             warn "\nChild $child count: @{[ scalar @c1 ]}\n";
#             foreach ( @c1 ) { warn "LINE: $_\n" }
#         }
#     }

    $obj->strmSeek( 'evens', 0, SEEK_SET );
    $obj->strmRead( 'evens', \$content, 16384 );
    is( scalar split( /\n/s, $content ), 250, 'piofm fork line count 2' );

#     {
#         my @lines = split /\n/s, $content;
#         foreach $child ( 2, 4, 6, 8, 10 ) {
#             my @c1 = grep /child $child:/, @lines;
#             warn "\nChild $child count: @{[ scalar @c1 ]}\n";
#             foreach ( @c1 ) { warn "LINE: $_\n" }
#         }
#     }

}

# Cleanup
#
# TODO:  Disable copy before shipping
#system("cp -av $tfile $tfile-bak");
unlink $tfile;

