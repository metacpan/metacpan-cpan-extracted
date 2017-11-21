use ExtUtils::MakeMaker;
use strict;
use warnings;
my $CC = 'c++';
`protoc --cpp_out=. nats_streaming.proto`;
die "need google protobuf compiler installed" if $!;
my $cflags = `pkg-config --cflags protobuf`;
die "need protobuf installed" if $cflags =~ /not found/;
my $libs   = `pkg-config --libs protobuf`;
$libs ||= "-lprotobuf";

my $LD_EXT = '';
if($libs =~ /-pthread/)
{
    $LD_EXT = ' -pthread';
    $libs =~ s/-pthread//;
}
WriteMakefile(
    'NAME' => 'Net::NATS::Streaming::PB',
    'VERSION'  => '0.06',
    'OPTIMIZE'      => '-O2 -Wall',
    'CC'            => $CC,
    'LD'            => '$(CC)'.$LD_EXT,
    'CCFLAGS'       => $cflags,
    'OBJECT'        => 'nats_streaming.pb.o PB.o',
    'LIBS'          => [$libs],
    'XSOPT'         => '-C++',
    clean           => { FILES => "nats_streaming.pb.cc nats_streaming.pb.h" }
);

