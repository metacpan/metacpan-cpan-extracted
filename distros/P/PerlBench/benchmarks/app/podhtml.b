# Name: Run pod2html on perlfunc

use lib "benchmarks/app";
use MyPodHtml qw(pod2html);
use File::Spec;
my $DEVNULL = File::Spec->devnull;

### TEST

pod2html("--infile" => "benchmarks/app/perlfunc.pod", "--outfile" => $DEVNULL);
