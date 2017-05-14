use strict;
use Test::More;
use POSIX qw(dup2);
use IO::Handle;
use FileHandle;

# Skip all tests if Archive::Zip, Compress::Zlib doesn't exist, or if
# 'unzip' executable is not in the path.
eval "use Archive::Zip";
eval "use Compress::Zlib";
unless (exists $INC{"Archive/Zip.pm"} && exists $INC{"Compress/Zlib.pm"} &&
	on_path ("unzip"))
  {
    plan skip_all => "missing support for ZIP files";
    exit 0;
  }

plan tests => 75;

use Net::FTPServer::InMem::Server;

pipe INFD0, OUTFD0 or die "pipe: $!";
pipe INFD1, OUTFD1 or die "pipe: $!";
my $pid = fork ();
die unless defined $pid;
unless ($pid) {			# Child process (the server).
  POSIX::dup2 (fileno INFD0, 0);
  POSIX::dup2 (fileno OUTFD1, 1);
  close INFD0;
  close OUTFD0;
  close INFD1;
  close OUTFD1;
  my $ftps = Net::FTPServer::InMem::Server->run
    (['--test', '-d', '-C', '/dev/null',
      '-o', 'limit memory=-1',
      '-o', 'limit nr processes=-1',
      '-o', 'limit nr files=-1']);
  exit;
}

# Parent process (the test script).
close INFD0;
close OUTFD1;
OUTFD0->autoflush (1);

$_ = <INFD1>;
print OUTFD0 "USER rich\r\n";
$_ = <INFD1>;
ok (/^331/);

print OUTFD0 "PASS 123456\r\n";
$_ = <INFD1>;
ok (/^230 Welcome rich\./);

# Use binary mode.
print OUTFD0 "TYPE I\r\n";
$_ = <INFD1>;
ok (/^200/);

# Enter passive mode and get a port number.
print OUTFD0 "PASV\r\n";
$_ = <INFD1>;
ok (/^227 Entering Passive Mode \(127,0,0,1,(.*),(.*)\)/);

my $port = $1 * 256 + $2;

# Create a directory containing some files.
# dir/
#   sub1/
#     subfile.txt
#   file1.txt
#   file2.txt
#      ...
#   file20.txt
print OUTFD0 "MKD dir\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "CWD dir\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "MKD sub1\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "CWD sub1\r\n";
$_ = <INFD1>;
ok (/^250/);

ok (upload_file ("subfile.txt", 10000));

print OUTFD0 "CDUP\r\n";
$_ = <INFD1>;
ok (/^250/);

ok (upload_file ("file1.txt", 50000));
ok (upload_file ("file2.txt", 500));
ok (upload_file ("file3.txt", 500));
ok (upload_file ("file4.txt", 500));
ok (upload_file ("file5.txt", 500));

ok (upload_file ("file6.txt", 20000));
ok (upload_file ("file7.txt", 200));
ok (upload_file ("file8.txt", 200));
ok (upload_file ("file9.txt", 200));
ok (upload_file ("file10.txt", 200));

ok (upload_file ("file11.txt", 40000));
ok (upload_file ("file12.txt", 400));
ok (upload_file ("file13.txt", 400));
ok (upload_file ("file14.txt", 400));
ok (upload_file ("file15.txt", 400));

ok (upload_file ("file16.txt", 10000));
ok (upload_file ("file17.txt", 100));
ok (upload_file ("file18.txt", 100));
ok (upload_file ("file19.txt", 100));
ok (upload_file ("file20.txt", 100));

print OUTFD0 "CWD /\r\n";
$_ = <INFD1>;
ok (/^250/);

# Download ZIP file.
my $tmpfile = ".350generatorzip.t.$$";
ok (download_file ("dir.zip", $tmpfile));

open LIST, "unzip -v $tmpfile |" or die "$tmpfile: $!";
my $buffer;
{
  local $/ = undef;
  $buffer = <LIST>;
}
close LIST;

# Sort and check the output.

my @results = split /\r?\n/, $buffer;

# 5 lines of overhead, 21 files.
ok (@results == 5 + 21);

shift @results;
shift @results;
shift @results;
pop @results;
pop @results;

foreach (@results)
  {
    s/^\s+//;
    s/\s+$//;
    my ($length, $method, $size, $ratio, $date, $time, $crc32, $name)
      = split /\s+/, $_;
    $_ = { length => $length, name => $name };
  }

@results = sort { $a->{name} cmp $b->{name} } @results;

ok ($results[0]->{name} eq "file1.txt");
ok ($results[0]->{length} == 50000);
ok ($results[1]->{name} eq "file10.txt");
ok ($results[1]->{length} == 200);
ok ($results[2]->{name} eq "file11.txt");
ok ($results[2]->{length} == 40000);
ok ($results[3]->{name} eq "file12.txt");
ok ($results[3]->{length} == 400);
ok ($results[4]->{name} eq "file13.txt");
ok ($results[4]->{length} == 400);
ok ($results[5]->{name} eq "file14.txt");
ok ($results[5]->{length} == 400);
ok ($results[6]->{name} eq "file15.txt");
ok ($results[6]->{length} == 400);
ok ($results[7]->{name} eq "file16.txt");
ok ($results[7]->{length} == 10000);
ok ($results[8]->{name} eq "file17.txt");
ok ($results[8]->{length} == 100);
ok ($results[9]->{name} eq "file18.txt");
ok ($results[9]->{length} == 100);
ok ($results[10]->{name} eq "file19.txt");
ok ($results[10]->{length} == 100);
ok ($results[11]->{name} eq "file2.txt");
ok ($results[11]->{length} == 500);
ok ($results[12]->{name} eq "file20.txt");
ok ($results[12]->{length} == 100);
ok ($results[13]->{name} eq "file3.txt");
ok ($results[13]->{length} == 500);
ok ($results[14]->{name} eq "file4.txt");
ok ($results[14]->{length} == 500);
ok ($results[15]->{name} eq "file5.txt");
ok ($results[15]->{length} == 500);
ok ($results[16]->{name} eq "file6.txt");
ok ($results[16]->{length} == 20000);
ok ($results[17]->{name} eq "file7.txt");
ok ($results[17]->{length} == 200);
ok ($results[18]->{name} eq "file8.txt");
ok ($results[18]->{length} == 200);
ok ($results[19]->{name} eq "file9.txt");
ok ($results[19]->{length} == 200);
ok ($results[20]->{name} eq "subfile.txt");
ok ($results[20]->{length} == 10000);

unlink $tmpfile;

print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;

exit;

# This function uploads a file to the server.

sub upload_file
  {
    my $filename = shift;
    my $size = shift;

    # Generate $size bytes of data.
    my $buffer = "";
    for (my $i = 0; $i < $size; ++$i)
      {
	$buffer .= chr (($i % 95) + 32);
      }

    # Send the STOR command.
    print OUTFD0 "STOR $filename\r\n";
    $_ = <INFD1>;
    return 0 unless /^150/;

    # Connect to the passive mode port.
    my $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    # Write to socket.
    $sock->print ($buffer);
    $sock->close;

    # Check return code.
    $_ = <INFD1>;
    return /^226/;
  }

# Download a file from the server into a local file.

sub download_file
  {
    my $remote_filename = shift;
    my $local_filename = shift;

    # Send the RETR command.
    print OUTFD0 "RETR $remote_filename\r\n";
    $_ = <INFD1>;
    return 0 unless /^150/;

    # Connect to the passive mode port.
    my $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    # Read all the data into a buffer.
    my $buffer = "";
    my $posn = 0;
    my $r;
    while (($r = $sock->read ($buffer, 65536, $posn)) > 0) {
      $posn += $r;
    }
    $sock->close;

    # Check return code.
    $_ = <INFD1>;
    return 0 unless /^226/;

    # Save to load file.
    open DOWNLOAD, ">$local_filename" or die "$local_filename: $!";
    print DOWNLOAD $buffer;
    close DOWNLOAD;

    # OK!
    return 1;
  }

sub on_path
  {
    foreach (split /:/, $ENV{PATH})
      {
	return 1 if -x "$_/$_[0]";
      }
    0;
  }

__END__
