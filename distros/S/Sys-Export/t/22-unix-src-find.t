use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Test2AndUtils;
use experimental qw( signatures );
use Sys::Export::Unix;
use File::stat;
use Socket;
use Fcntl qw( S_IFDIR S_IFREG S_IFLNK S_ISLNK S_IFCHR S_IFSOCK );
use autodie;

my $tmp= File::Temp->newdir;

my $exporter= Sys::Export::Unix->new(src => $tmp, dst => File::Temp->newdir);
note "exporter src: '".$exporter->src."' dst: '".$exporter->dst."'";

mkdir "$tmp/usr";
mkdir "$tmp/usr/local";
mkfile "$tmp/usr/local/datafile",  "Just some data\n";
mkfile "$tmp/usr/local/datafile2", "Just more data\n";
mkfile "$tmp/usr/local/datafile3", "Even more data\n";

my %found= map +($_->{src_path} => $_), $exporter->src_find('/');
is( \%found, {
   'usr'                     => hash { field src_path => 'usr'; etc; },
   'usr/local'               => hash { field src_path => 'usr/local'; etc; },
   'usr/local/datafile'      => hash { field src_path => 'usr/local/datafile'; etc; },
   'usr/local/datafile2'     => hash { field src_path => 'usr/local/datafile2'; etc; },
   'usr/local/datafile3'     => hash { field src_path => 'usr/local/datafile3'; etc; },
}, 'found all files and directories' );

%found= map +($_->{src_path} => $_), $exporter->src_find('usr', sub { -f && /3$/ });
is( \%found, {
   'usr/local/datafile3'     => hash { field src_path => 'usr/local/datafile3'; etc; },
}, 'found files matching /3$/' );

%found= map +($_->{src_path} => $_), $exporter->src_find('usr', sub { -d });
is( \%found, {
   'usr'                     => hash { field src_path => 'usr'; etc; },
   'usr/local'               => hash { field src_path => 'usr/local'; etc; },
}, 'found directories under usr/' );

%found= map +($_->{src_path} => $_), $exporter->src_find('/', qr/data/);
is( \%found, {
   'usr/local/datafile'      => hash { field src_path => 'usr/local/datafile'; etc; },
   'usr/local/datafile2'     => hash { field src_path => 'usr/local/datafile2'; etc; },
   'usr/local/datafile3'     => hash { field src_path => 'usr/local/datafile3'; etc; },
}, 'found all paths matching qr/data/' );

done_testing;
