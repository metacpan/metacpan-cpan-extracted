#!/usr/bin/perl 
use warnings;
use strict;
use File::Find;
use Getopt::Long qw{HelpMessage};

my %duplicated;
my $relative = ''; #quotemeta('/home/casiano/public_html/cpan');
my $log = '';
my $output = '';
my $pod = 0;

my $result = GetOptions(
  "relative=s" => \$relative,  
  "log=s"      => \$log,
  "output=s"   => \$output,
  "pod!"       => \$pod,
  "help"       => sub { HelpMessage( -msg => <<'EOH', -exitval => 0) },

In the server:

  perlmodule.server$ pminstalled.pl [options] [searchpathlist] -o .ppmdf.descriptor

or in the client (assuming automatic SSH authentication):

    client$ ssh remote.machine perl pminstalled.pl [options] [searchpathlist]  .ppmdf.descriptor

If "searchpathlist" is empty "@INC" will be used instead.

Options:

  * --relative path, -r path

  The consequence of using -r path is that path will be removed from the dir entries in the PPMDF file

  * --log file, -l file

  Specifies the log file where warnings will be saved.  For example:

    pp2@nereida:$ ssh orion perl pminstalled.pl -log /tmp/dups  /tmp/perl5lib/.orion.installed.modules

  * --output file, -o log

    Must be followed by the name of the output file.

  * --pod, --nopod

    The POD files (extension .pod) associated with the module will be added
    to the files entry for that module

  * --help
     This help. See also "perldoc Remote::Use::Tutorial" and "perldoc pminstalled.pl"


EOH
);

my $fw;
sub log_warn {
  print $fw "@_";
}

$SIG{__WARN__} = \&log_warn if ($log && open $fw, "> $log");

my $fo;
$fo = \*STDOUT unless ($output && open $fo, "> $output");
 
$relative = quotemeta($relative);

my @SEARCH;
if (@ARGV) {
  @SEARCH = @ARGV;
}
else {
  @SEARCH = @INC;
}

sub duplicated {

  if (exists($duplicated{$_})) {
    warn <<"EOW";
Duplicated module $_:
Is in: 
       $duplicated{$_}
and in: 
       $File::Find::name
only the first will be considered.

EOW
    return 1;
  }
  return 0;
}

# Avoid File::Find warnings 
@SEARCH = grep { -d } @SEARCH;

our $startdir;
print $fo "(\n";
for $startdir (@SEARCH) { 
    eval { find(\&wanted, $startdir) };
    warn "Error $!" if $@;
}
print $fo ");\n";

sub wanted {
    if (-d && /^[a-z]/) { 
        # this is so we don't go down site_perl etc too early
        $File::Find::prune = 1;
        return;
    }
    return unless /\.pm$/;
    local $_ = $File::Find::name;

    my $startrelativedir = $startdir;         # /usr/local/share/perl/5.8.8/

    # If option "relative" is used we eliminate the 
    # "relative" prefix from the path
    $startrelativedir =~ s/^$relative// if $relative;

    $startdir =~ s{/\s*$}{}; # Supress final /
    # Get the file name associated with the module
    s{^(\Q$startdir\E)/(.*)}{'$2'}; 
    my $filename = $2 || '';                        # Parse/Eyapp.pm
    # Now $_ = '$filename'

    return if duplicated();

    $duplicated{$_} = $File::Find::name;

    # Get the directory part
    my $dir = $filename;                  
    $dir =~ s/\.pm//;                         # Parse/Eyapp

    print $fo "$_ => { dir => '$startrelativedir', files => [";

    # Print pods if option is activated
    if ($pod) {
      my $podname = $File::Find::name;
      $podname =~ s/\.pm$/.pod/;
      print $fo "\n\t'$podname'," if -f $podname;
    }

    my $auxdir = "$startdir/auto/$dir";       # /usr/local/share/perl/5.8.8/auto//IO/Tty
    if (-d $auxdir) {                         
      eval { find(\&auxiliaryfiles, $auxdir) }; 
      warn "Error $!" if $@;
    }

    my $resultname = $File::Find::name;
    $resultname =~ s/^$relative// if $relative;
    print $fo "\n\t'$resultname' ] },\n";
} 

sub auxiliaryfiles {
  my $resultname = $File::Find::name;

  # Skip .packlist files
  return if $resultname =~ /\.packlist/;

  $resultname =~ s/^$relative// if $relative;
  print $fo "\n\t'$resultname'," if -f $File::Find::name;
}

__END__

