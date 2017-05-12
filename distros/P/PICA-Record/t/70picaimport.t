#!perl

##!perl -Tw

use strict;

use Test::More qw(no_plan);
use File::Temp qw(tempdir);
use Cwd qw(abs_path cwd);
use PICA::Store;
use PICA::Record;
use Data::Dumper;

if (not $ENV{PICASQL_TEST} ) {
    diag("Set PICASQL_TEST to enable additional tests of PICA::SQLiteStore!");
    ok(1);
    exit;
}

my $tempdir = tempdir( UNLINK => 1 );
my $verbose = 0;

writefile("store.conf","SQLite=$tempdir/picastore.db\n");
writefile("test.pica", slurp("t/files/minimal.pica"));

my @files = (
  abs_path("t/files/cjk.pica"),
  "$tempdir/test.pica"
);

writefile("files", join("\n", @files)."\n");

#my $record = readpicarecord("t/files/minimal.pica");
#$record->delete_field('


my $store = PICA::Store->new( conf => "$tempdir/store.conf" );
isa_ok( $store, 'PICA::Store', 'created a new store via config file' );

my %result = $store->create( PICA::Record->new('021A $aShort Title') );
my $id = $result{id};
ok ( $result{id}, 'created a record' );

# $store->size

# chdir $dir;
#t/files/graveyard.pica

my ($stdout, $stderr) = picaimport();
ok( $stderr, "needs parameters" );

($stdout, $stderr) = picaimport( "-conf $tempdir/store.conf -from $tempdir/files" );
ok( !$stderr, "import looks fine" );

my @lines = $stdout ? split("\n", $stdout) : ('');
my $msg = "^Reading from $tempdir/files";
ok( shift(@lines) =~ /$msg/, "read from file" );
my %records = map { $_ =~ /^([0-9]*[0-9Xx]) (.+)/; ($1=>$2); } @lines;

is( (keys %records), 2, 'imported 2 records' );
is( scalar @{$store->recentchanges}, 2+1, 'imported into store' );

# TODO: check if records are the same
# TODO: move files

# ($stdout, $stderr) = picaimport( "-conf $tempdir/store.conf -delete -force " . join(" ", keys %records) );
# ok( !$stderr, "delete looks fine" );
# is( scalar @{$store->recentchanges}, 2+2+1, 'deleted from store' );

#print "$stderr\n";
# print "$stdout\n";

#print Dumper(\%records) . "\n"; 
#2 /home/voj/svn/picapm/trunk/t/files/cjk.pica
#3 /tmp/9NjveobGae/test.pica

# TODO: use Test::...something for testing scripts
sub picaimport {
    my $args = shift || '';
    my ($stdout, $stderr) = ("$tempdir/stdout", "$tempdir/stderr");
    my $cmd = "perl -Iblib/lib script/picaimport $args";
    $cmd .= " 1>$stdout 2>$stderr";
    print "$cmd\n" if $verbose;
    system($cmd);
    return ( slurp($stdout), slurp($stderr) );
}


# write a file in the temporary directory
sub writefile {
    my ($file, $data) = @_;
    $file = "$tempdir/$file";
    my $fh;
    open $fh, ">$file" or die("failed to open $file");
    print $fh $data;
    close $fh;
}

# read a file into a string
sub slurp {
    my $filename = shift;
    my ($fh, $buffer, $data);
    open( $fh, "<", $filename ) or return "Failed to read file '$filename'";
    binmode($fh);
    while (read ($fh, $buffer, 65536) ) { $data .= $buffer; }
    close $fh;
    return $data;
}