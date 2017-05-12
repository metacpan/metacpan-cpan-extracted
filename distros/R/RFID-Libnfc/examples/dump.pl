#!/usr/bin/perl

use Data::Dumper;
use RFID::Libnfc::Reader;
use RFID::Libnfc::Constants;

my $outfile = "./dump.out";
my $keyfile = "/Users/xant/mykeys";

sub usage {
    printf("%s [ -o dump_filename ]\n", $0);
    exit -1;
}

sub parse_cmdline {
    for (my $i = 0; $i < scalar(@ARGV); $i++) {
        my $opt = $ARGV[$i];
        if ($opt eq "-h") {
            usage();
        } elsif ($opt eq "-k") {
            $keyfile = $ARGV[++$i];
        } elsif ($opt eq "-o") {
            $outfile = $ARGV[++$i];
            usage() unless($outfile);
        }
    }
}

parse_cmdline();
my $r = RFID::Libnfc::Reader->new(debug => 0);
if ($r->init()) {
    printf ("Reader: %s\n", $r->name);
    my $tag = $r->connect(IM_ISO14443A_106);

    if ($tag) {
        $tag->dump_info;
    } else {
        warn "No TAG";
        exit -1;
    }

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

    $tag->select if ($tag->can("select")); 

    open(DUMP, ">$outfile") or die "Can't open dump file: $!";
    print "Dumping tag to $outfile\n";
    for (my $i = 0; $i < $tag->blocks; $i++) {
        if (my $data = $tag->read_block($i)) {
            # if we are dumping an ultralight token, 
            # we receive 16 bytes (while a block is 4bytes long)
            # so we can skip next 3 blocks
            $i += 3 if ($tag->type eq "ULTRA");
            print DUMP $data;
            my @databytes = split(//, $data);
            my $len = scalar(@databytes);
            # let's format the output.
            # unprintable chars will be outputted as a '.' (like any other hexdumper)
            my @chars = map { (ord($_) > 31 and ord($_) < 127) ? $_ : '.' } @databytes; 
            my @bytes = map { ord($_) } @databytes; 
            printf ("%03d: [" . "%02x" x $len . "]\t" . "%s" x $len . "\n", $i, @bytes, @chars);
        } else {
            warn $tag->error."\n";
            if ($tag->type eq "4K") {
                print DUMP pack("a16", "");

            }
        }
    }
    close(DUMP);
}

