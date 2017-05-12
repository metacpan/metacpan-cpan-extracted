
use Scriptalicious
     -progname => "pu";

our $VERSION = "1.00";

my $url = ".";
getopt("u|url" => \$url);

run("echo", "doing something with $url");

my ($rv, $output) = capture_err("cat", $url);

say "the rc from the `cat $url' command was $?";

__END__

=head1 NAME

pu - an uncarved block of wood

=head1 SYNOPSIS

pu [options] arguments

=head1 DESCRIPTION

This script's function is to be a blank example that many
great and simple scripts may be built upon.

Remember, you cannot carve rotten wood.

=head1 COMMAND LINE OPTIONS

=over

=item B<-h, --help>

Display a program usage screen and exit.

=item B<-V, --version>

Display program version and exit.

=item B<-v, --verbose>

Verbose command execution, displaying things like the
commands run, their output, etc.

=item B<-q, --quiet>

Suppress all normal program output; only display errors and
warnings.

=item B<-d, --debug>

Display output to help someone debug this script, not the
process going on.

=back
