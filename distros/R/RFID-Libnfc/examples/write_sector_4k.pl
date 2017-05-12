#!/usr/bin/perl

use Data::Dumper;
use RFID::Libnfc::Reader;
use RFID::Libnfc::Constants;
use RFID::Libnfc qw(print_hex);

my $infile = undef;
my $keyfile = "/Users/xant/mykeys";

sub usage {
    printf("%s sector_number [ -i input_datafile ]\n", $0);
    exit -1;
}

my $sector = shift;
usage unless($sector =~ /^\d+$/);

sub parse_cmdline {
    for (my $i = 0; $i < scalar(@ARGV); $i++) {
        my $opt = $ARGV[$i];
        if ($opt eq "-h") {
            usage();
        } elsif ($opt eq "-k") {
            $keyfile = $ARGV[++$i];
        } elsif ($opt eq "-i") {
            $infile = $ARGV[++$i];
            usage() unless($infile);
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

    $tag->load_keys($keyfile) if (-f $keyfile); 

    $tag->select if ($tag->can("select")); 

    die "bad sector num $sector. Must be between 0 and ". $tag->sectors
        unless ($sector =~ /^\d+$/ and $sector < $tag->sectors);
    my $acl = $tag->acl($sector);
    warn Data::Dumper->Dump([$acl], ["ACL"]);
    my $data = $tag->read_sector($sector);
    my $len = length($data);
    my @databytes = unpack("C".$len, $data);
    # let's format the output.
    # unprintable chars will be outputted as a '.' (like any other hexdumper)
    my @chars = map { ($_ > 31 and $_ < 127) ? $_ : ord('.') } @databytes; 
    printf "Old Data: \n";
    while (my @blockbytes = splice(@databytes, 0, 16)) {
        my @chars = map { ($_ > 31 and $_ < 127) ? $_ : ord('.') } @blockbytes; 
        printf ("%03d: " . "%02x " x 16 . "\t|" . "%c" x 16 . "|\n", $i, @blockbytes, @chars);
    }

    if ($infile and -f $infile) {
        open (IN, $infile) or die "Can't open file $infile: $!";
        my $indata;
        die "Can't read enough data " unless (read(IN, $indata, 16*15) == 16*15);
        $tag->write_sector($sector, $indata);
        $data = $tag->read_sector($sector);
        my $len = length($data);
        my @databytes = unpack("C".$len, $data);
        # let's format the output.
        # unprintable chars will be outputted as a '.' (like any other hexdumper)
        my @chars = map { ($_ > 31 and $_ < 127) ? $_ : ord('.') } @databytes; 
        printf "New Data: \n";
        while (my @blockbytes = splice(@databytes, 0, 16)) {
            my @chars = map { ($_ > 31 and $_ < 127) ? $_ : ord('.') } @blockbytes; 
            printf ("%03d: " . "%02x " x 16 . "\t|" . "%c" x 16 . "|\n", $i, @blockbytes, @chars);
        }
    }

}

