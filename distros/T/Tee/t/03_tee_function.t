# Tee tests
use strict;
use File::Spec;
use File::Temp;
use IO::CaptureOutput qw/ capture qxx /;
use IO::File;
use Probe::Perl;
use Test::More;
use t::Expected;

#--------------------------------------------------------------------------#
# autoflush to keep output in order
#--------------------------------------------------------------------------#

my $stdout = select(STDERR);
$|=1;
select($stdout);
$|=1;

#--------------------------------------------------------------------------#
# Declarations
#--------------------------------------------------------------------------#

my $pp = Probe::Perl->new;
my $perl = $pp->find_perl_interpreter;
my $hello = File::Spec->catfile(qw/t helloworld.pl/);
my $fatality = File::Spec->catfile(qw/t fatality.pl/);
my $tee = File::Spec->catfile(qw/scripts ptee/);
my $tempfh = File::Temp->new;
my $tempfh2 = File::Temp->new;
my $tempname = $tempfh->filename;
my $tempname2 = $tempfh2->filename;
my ($got_stdout, $got_stderr, $teed_stdout, $rc, $status);

my $stdout_regex = quotemeta(expected("STDOUT"));
my $stderr_regex = quotemeta(expected("STDERR"));

sub _slurp {
  my $fh = IO::File->new(shift, "r");
  local $/;
  return scalar <$fh>;
}

#--------------------------------------------------------------------------#
# Begin test plan
#--------------------------------------------------------------------------#

plan tests =>  14 ;

require_ok( "Tee" );
Tee->import;

can_ok( "main", "tee" );

ok( -r $hello, 
    "hello script readable" 
);

# check direct output of helloworld

($got_stdout, $got_stderr) = qxx("$perl $hello");

is( $got_stdout, expected("STDOUT"), 
    "system(CMD) script STDOUT"
);
is( $got_stderr, expected("STDERR"), 
    "system(CMD) script STDERR"
);

# check tee of STDOUT
truncate $tempfh, 0;

capture { 
  $rc = tee("$perl $hello", $tempname) 
} \$got_stdout, \$got_stderr;

is( $got_stdout, expected("STDOUT"), 
    "tee(CMD,FILE) script STDOUT"
);
is( $got_stderr, expected("STDERR"), 
    "tee(CMD,FILE) script STDERR"
);

$teed_stdout = _slurp($tempname);
is( $teed_stdout, expected("STDOUT"), 
    "tee(CMD,FILE) script tee file"
);

# check tee of STDOUT to multiple files
truncate $tempfh, 0;
capture { 
  tee("$perl $hello", $tempname, $tempname2);
} \$got_stdout, \$got_stderr;


$teed_stdout = _slurp($tempname);
is( $teed_stdout, expected("STDOUT"), 
    "tee(CMD,FILE1,FILE2) script tee file (1)"
);

$teed_stdout = _slurp($tempname2);
is( $teed_stdout, expected("STDOUT"), 
    "tee(CMD,FILE1,FILE2) script tee file (2)"
);

## check tee of both STDOUT and STDERR
truncate $tempfh, 0;
capture { 
  tee("$perl $hello", { stderr => 1 }, $tempname);
} \$got_stdout, \$got_stderr;

$teed_stdout = _slurp($tempname);

like( $teed_stdout, "/$stdout_regex/", 
    "tee(CMD,FILE) w/stderr script tee file (STDOUT)"
);
like( $teed_stdout, "/$stderr_regex/",
    "tee(CMD,FILE) w/stderr script tee file (STDERR)"
);


## check tee of both with append
capture { 
  tee("$perl $hello", { stderr => 1, append => 1 }, $tempname);
} \$got_stdout, \$got_stderr;

$teed_stdout = _slurp($tempname);

my $saw_stdout = () = ( $teed_stdout =~ /($stdout_regex)/gms );
my $saw_stderr = () = ( $teed_stdout =~ /($stderr_regex)/gms );

is( $saw_stdout, 2, 
    "tee(CMD,FILE) w/stderr+append script tee file (STDOUT)"
);
is( $saw_stderr, 2, 
    "tee(CMD,FILE) w/stderr+append script tee file (STDERR)"
);

