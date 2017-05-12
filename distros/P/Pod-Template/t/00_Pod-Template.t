BEGIN { chdir 't' if -d 't' };
use lib '../lib';
use Test::More tests => 9;
use File::Spec;
use strict;

my $keep = shift || 0;

use_ok('Pod::Template') or die diag qq[Can not load 'Pod::Template'];

my @root = qw[.. samples];
my $dh;
opendir $dh, File::Spec->catdir( @root )
        or die qq[Could not open samples dir\n];
        
for my $dir ( grep /\w/, readdir($dh) ) {
    
    my $path = File::Spec->catdir(  @root, $dir );
    next unless -d $path;

    my $prog = File::Spec->catfile( @root,'parse_sample.pl');
    my $file = File::Spec->catfile( $dir . '.pod' );
    my $exp  = File::Spec->catfile( 'expect', $dir . '.expect' );
    my $cmd  = "$^X $prog -o $file -P $path";
 
    ok(!system($cmd),                   "Ran parse_sample.pl OK");
    ok( -s $file,                       "   Resulting pod file has size");
    cmp_ok( -s $file, '==', -s $exp,    "   Expected file size found");   

    my @list;
    for my $item ($file,$exp) {
        my $fh = FileHandle->new($file)
                    or die qq[Could not open file '$file': $!\n];
        push @list, do { local $/; <$fh> };
    }

    is( shift @list, shift @list, "Files are the same" );                    

    unlink $file unless $keep;
}                 
    
