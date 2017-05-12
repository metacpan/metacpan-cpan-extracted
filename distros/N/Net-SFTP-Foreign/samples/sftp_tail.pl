#!/usr/bin/perl

use strict;
use warnings;

use Net::SFTP::Foreign;
use Fcntl qw(SEEK_END);

@ARGV == 1
    or usage();

my ($host, $file) = $ARGV[0] =~ /([^:]+):(.+)/ or usage();

my $sftp = Net::SFTP::Foreign->new($host);
$sftp->error and die "Unable to connect to remote host: ".$sftp->error."\n";

my $fh = $sftp->open($file)
    or die "Unable to open file $file: ".$sftp->error."\n";

# goto end of file
seek($fh, 0, SEEK_END);

my $sleep = 1;
while (1) {
    while (<$fh>) {
        print;
        $sleep = 1;
    }
    print "### sleeping $sleep\n";
    sleep $sleep;
    $sleep++ unless $sleep > 5;
}

sub usage {
    warn <<EOW;
Usage:
  $0 [user@]host:/path/to/file
EOW
    exit 0;

}
