use lib '../lib';
use Pod::Template;
use File::Spec;
use Getopt::Std;

my $opts = {};
getopts('Po:', $opts);

### get the directory and open it ###
my $dir = shift or die usage();
my $dh;
opendir($dh, "$dir") or die qq[Could not open dir '$dir': $!\n];

### find the template file ###
### add any subdirs as libs too the parser ###
my @libs;
my $re      = qr/\.ptmpl$/;
my ($tmpl)  =   grep /$re/, 
                map {
                    my $path = File::Spec->catdir($dir,$_);    
                    push @libs, $path if -d $path;
                    $_; 
                } readdir($dh) 
                    or die qq[No Pod::Template template found in dir '$dir'\n];

### parse the template ###
my $parser = Pod::Template->new( lib => [$dir, @libs] );
$parser->parse( template => File::Spec->catfile($dir,$tmpl) );

### construct the output file name ###
$tmpl   =~ s/$re//;
my $out = exists $opts->{'o'}
            ? $opts->{'o'}
            : File::Spec->catfile( $dir, $tmpl . '.pod' );

### write the pod to the file ###
my $fh;
open($fh, ">$out") or die qq[Could not open '$out' for writing: $!\n];
print $fh $parser->as_string;                
close $fh;

### display it via perldoc ###
system("perldoc $out") unless $opts->{'P'};

print "Saved the documentation as:\n\t$out\n";

### some usage info ###
sub usage {
    return qq[
Usage:
    $0 [-o FILE] [-P] DIRECTORY
    
Joins Pod::Template templates and sources into valid pod;
displays the pod using your perldoc program

Options:
    -o  print the result to named file.
    -P  do not display the result using 'perldoc'

    \n]
}            
