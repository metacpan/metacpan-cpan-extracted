#
# Test cases for pathetic abnormities
#
use Test::More;
use Net::SSH::AuthorizedKeysFile;
use File::Temp qw(tempfile);

my $tdir = "t";
$tdir = "../t" unless -d $tdir;
my $cdir = "$tdir/canned";

plan tests => 3;

my $keyfile = Net::SSH::AuthorizedKeysFile->new(
    file => "$cdir/ak-comments.txt",
);

is $keyfile->sanity_check(), 1, "sanity of regular file succeeds";

my($fh, $tmpfile) = tempfile( UNLINK => 1 );
my $string = ("a" x ($keyfile->{ridiculous_line_len} + 1));
print $fh "$string\n";
close $fh;

is $keyfile->sanity_check($tmpfile), undef, "check sanity of insane file";

($fh, $tmpfile) = tempfile( UNLINK => 1 );
$string = ("a" x ($keyfile->{ridiculous_line_len} / 2) . 
              "\n" .
              "a" x ($keyfile->{ridiculous_line_len} / 2)
             );
print $fh "$string\n";
close $fh;

is $keyfile->sanity_check($tmpfile), 1, "sanity of regular file succeeds";
