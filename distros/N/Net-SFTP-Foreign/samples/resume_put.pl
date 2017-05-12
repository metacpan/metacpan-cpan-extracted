#!/usr/bin/perl

#
# this script is used to test the resume feature of the put method
#

use strict;
use warnings;

@ARGV == 2 or die "Usage:\n  resume_put.pl file_len gpg_id\n\n";
my ($len, $id) = @ARGV;

use Net::SFTP::Foreign;

my $base;

our ($a, $b);

use File::Slurp;

sub reset_local {
    create_file(@_);
}

sub create_file {
    my ($len) = @_;
    $base = join '', map { chr rand 256 } 0..100000;
    open my $fh, '>', "local.txt";
    binmode $fh;
    while ($len > 0) {
	print $fh substr $base, 0, $len;
	$len -= length $base
    }
    close $fh;
    unlink 'local.txt.gpg';
    system 'gpg', '--encrypt', '--recipient', $id, 'local.txt';
    read_file("local.txt.gpg", binmode => ':raw');
}

open STDERR, ">", "Net-SFTP-Foreign.debug";
$Net::SFTP::Foreign::debug = 3+32+128+4096+16384;

$| = 1;
my $pwd = `pwd`;
chomp $pwd;
my $i = 1;
eval {
    while (1) {
        my $s;
        my $content = create_file(1 + int rand $len);
        my $gpg_len = length $content;
        for (1..100) {
            my $remote = 1 + int rand length $content;
            print STDERR "\n\n############################## ${i}:$remote/$gpg_len ################################\n\n";
            print " ${i}:$remote/$gpg_len";
	    $i++;
            $s //= Net::SFTP::Foreign->new('localhost');
            $s->setcwd($pwd);

            write_file("remote.txt.gpg", {binmode => ':raw'}, substr($content, 0, $remote));
            $s->put("local.txt.gpg", "remote.txt.gpg", resume => 1);
            if ($s->error) {
                print $s->error . "!";
                undef $s;
                next;
            }
            my $rcontent = read_file("remote.txt.gpg", binary => ':raw');
            unless ($content eq $rcontent and
                    (stat "remote.txt.gpg")[7] == (stat "local.txt.gpg")[7]) {
                die "\ndifferent contents\n";
            }
        }
    }
};
if ($@) {
    print $@;
    die $@;
}
