#!/usr/bin/perl

=head1 usage

  $0 $keyfile $blocknum

=cut

use strict;
use Data::Dumper;
use RFID::Libnfc::Reader;
use RFID::Libnfc::Constants;
use RFID::Libnfc qw(print_hex);

my $outfile = "./dump.out";
my $keyfile = "/Users/xant/mykeys";

sub usage {
    printf("%s block_num\nWill fetch 16 bytes from stdin", $0);
    exit -1;
}

if( @ARGV ){
    $keyfile = shift;
}

my $r = RFID::Libnfc::Reader->new(debug => 1);
if ($r->init()) {
    printf ("Reader: %s\n", $r->name);
    my $tag = $r->connect(IM_ISO14443A_106);

    if ($tag) {
        $tag->dump_info;
    } else {
        warn "No TAG";
        exit -1;
    }

    my $input;
    read(STDIN, $input, 16);
    printf("INPUT: ") and print_hex($input, 16);

    # TODO - allow to specify the keyfile through a cmdline argument
    $tag->load_keys($keyfile) if (-f $keyfile); 
    # or use :
    # my @keys = (
    # # default keys
    # pack("C6", 0x00,0x00,0x00,0x00,0x00,0x00),
    # pack("C6", 0xb5,0xff,0x67,0xcb,0xa9,0x51),

    # #   ... add your keys here in the format [ keya, keyb ] ...
    # #   for instance : 
    # #   [ pack("C6", 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF),
    # #     pack("C6", 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA) ],
    # #   one couple for each sector. The index inside this array must
    # #   coincide with the sector number they open.
    # #
    # );
    # $tag->set_keys(@keys);

    $tag->select if $tag->can('select');

    my $block = $ARGV[0];
    die "bad block num $block. Must be between 0 and ". $tag->blocks
        unless ($block =~ /^\d+$/ and $block < $tag->blocks);
    my $sector = $tag->block2sector($block);
    my $acl = $tag->acl($sector);
    # warn Data::Dumper->Dump([$acl], ["ACL"]);
    my $data = $tag->read_block($block);
    # print "Old data: " and print_hex($data, length($data));
    $tag->write_block($block, $input));
    # my $data = $tag->read_block($block);
    # print "New data: " and print_hex($data, length($data));

}

