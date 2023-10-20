#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2023-08-20
# @package Process::SubProcess
# @subpackage bin/run_subprocess.pl

# This Module spawns a sub process from the commandline options and prints the results
# to the STDOUT in a structured parseable output.
#

use strict;
use warnings;

use Getopt::Long::Descriptive;
use Path::Tiny qw(path);
use JSON qw(encode_json);
use YAML qw(Dump);
use Data::Dump qw(dump);

BEGIN {
    use lib "lib";
    use lib "../lib";
}    #BEGIN

use Process::SubProcess;

# ==============================================================================
# Executing Section

=head1 NAME

run_subprocess.pl - Script to run sub processes in an easy post-processable way

=head1 DESCRIPTION

C<run_subprocess.pl> captures the  C<STDOUT>, C<STDERR>, the C<EXIT CODE> from a
sub process and parses it into I<JSON>, I<YAML> or I<Plain Text> formats.

=head1 OVERVIEW

    run_subprocess.pl [-bcdfhnrtx] [long options...]
      -c STR --command STR      the COMMAND to be run
      -n STR --name STR         the NAME for the COMMAND
      -r INT --readtimeout INT  the TIMEOUT for reading of the output from
    			                            COMMAND
      -t INT --timeout INT      the TIMEOUT for execution the COMMAND
      -x --exit                 execution returns exit code
      -f STR --format STR       the format for the output
      -b STR --boundary STR     boundary string for the plain text output
      -d --debug                execution debug output
      -h --help                 print usage message and exit

See L<Method C<Process::SubProcess::setArrProcess()>|Process::SubProcess/"setArrProcess ( CONFIGURATIONS )">

=head1 EXAMPLES

=over 4

=item Plain Test Format with Boundary

    $ bin/run_subprocess.pl -n "test-script fails" -c "t/test_script.pl 3 6" -b ':====' -t 2

    script 'run_subprocess.pl' - Command Result:
    :====SUMMARY:
    command: t/test_script.pl 3 6
    name: test-script fails
    pid: 7387
    exit code: -1
    error code: 4
    :====STDOUT:
    :====STDERR:
    script 'test_script.pl' START 0 ERROR
    Sub Process (7387) 'test-script fails': Execution timed out!
    Execution Time '2 / 2'
    Process will be terminated.
    Sub Process (7387) 'test-script fails': Process terminating ...
    :====END:====

=item JSON Format

    $ bin/run_subprocess.pl -n "test-script" -c "t/test_script.pl 2 0" -f json | jq '.'

    {
      "exit_code": 0,
      "error_code": 0,
      "name": "test-script",
      "command": "t/test_script.pl 2 0",
      "stdout": "Start - Time Now: '1688649512.50548' s\nscript 'test_script.pl' START 0\nscript 'test_script.pl' PAUSE '2' ...\nscript 'test_script.pl' END 1\nEnd - Time Now: '1688649514.50564' s\nscript 'test_script.pl' done in '2000.16093254089' ms\nscript 'test_script.pl' EXIT '0'\n",
      "pid": "14911",
      "stderr": "script 'test_script.pl' START 0 ERROR\nscript 'test_script.pl' END 1 ERROR\n"
    }

=item YAML Format

    $ bin/run_subprocess.pl -n "test-script" -c "t/test_script.pl 2 0" -f yaml

    ---
    command: t/test_script.pl 2 0
    error_code: 0
    exit_code: 0
    name: test-script
    pid: 14928
    stderr: |
      script 'test_script.pl' START 0 ERROR
      script 'test_script.pl' END 1 ERROR
    stdout: |
      Start - Time Now: '1688649560.87845' s
      script 'test_script.pl' START 0
      script 'test_script.pl' PAUSE '2' ...
      script 'test_script.pl' END 1
      End - Time Now: '1688649562.8786' s
      script 'test_script.pl' done in '2000.1528263092' ms
      script 'test_script.pl' EXIT '0'

=item JSON Format extracting C<STDOUT> and C<EXIT CODE>

    $ bin/run_subprocess.pl -n "test-script" -c "t/test_script.pl 2 0" -f json | jq '.stdout,.exit_code'

    "Start - Time Now: '1688649702.23336' s\nscript 'test_script.pl' START 0\nscript 'test_script.pl' PAUSE '2' ...\nscript 'test_script.pl' END 1\nEnd - Time Now: '1688649704.23352' s\nscript 'test_script.pl' done in '2000.15997886658' ms\nscript 'test_script.pl' EXIT '0'\n"
    0

=back

=cut

# ------------------------
# Script Environment

my $module_file = path($0)->basename;
my $path        = Path::Tiny->cwd;
my $maindir     = $path;

# ------------------------
# Script Parameter

my ( $opt, $usage ) = describe_options(
    '%c %o',
    [ 'command|c=s', 'the COMMAND to be run',    { 'required' => 1 } ],
    [ 'name|n=s',    'the NAME for the COMMAND', { 'default'  => '' } ],
    [
        'readtimeout|r=i',
        'the TIMEOUT for reading of the output from COMMAND',
        { 'default' => -1 }
    ],
    [
        'timeout|t=i',
        'the TIMEOUT for execution the COMMAND',
        { 'default' => -1 }
    ],
    [ 'exit|x',     'execution returns exit code', { 'default' => 0 } ],
    [ 'format|f=s', 'the format for the output',   { 'default' => 'plain' } ],
    [
        'boundary|b=s',
        'boundary string for the plain text output',
        { 'default' => '>>>>' }
    ],
    [ 'debug|d', 'execution debug output' ],
    [ 'help|h',  "print usage message and exit", { 'shortcircuit' => 1 } ],
);

if ( $opt->help ) {
    print( $usage->text );

    exit;
}

my %command_res = (
    'command'    => $opt->command,
    'pid'        => -1,
    'name'       => $opt->name,
    'stdout'     => '',
    'stderr'     => '',
    'exit_code'  => -1,
    'error_code' => 0
);

if ( $opt->command ne '' ) {
    my $process =
      Process::SubProcess->new( 'command' => $command_res{'command'} );

    $process->setName( $command_res{'name'} ) if ( $command_res{'name'} ne '' );

    $process->setReadTimeout( $opt->readtimeout )
      if ( $opt->readtimeout != -1 );
    $process->setTimeout( $opt->timeout ) if ( $opt->timeout != -1 );

    $process->Run();

    if ( $opt->debug ) {
        print "proc dmp:\n", dump($process), "\n";
    }

    $command_res{'pid'}        = $process->getProcessID;
    $command_res{'exit_code'}  = $process->getProcessStatus;
    $command_res{'error_code'} = $process->getErrorCode;

    $command_res{'stdout'} = ${ $process->getReportString };
    $command_res{'stderr'} = ${ $process->getErrorString };
}
else {
    $command_res{'error_code'} = 3;
    $command_res{'stderr'} =
      "script '$module_file' - Command Error: Command is missing!";
}

# ------------------------
# Print the Command Result

if ( $opt->format eq 'plain' ) {
    print "script '$module_file' - Command Result:\n";

    printf "%sSUMMARY:\n", $opt->boundary;
    printf "command: %s\nname: %s\npid: %d\nexit code: %d\nerror code: %d\n",
      $command_res{'command'}, $command_res{'name'}, $command_res{'pid'},
      $command_res{'exit_code'}, $command_res{'error_code'};

    printf "%sSTDOUT:\n", $opt->boundary;
    print $command_res{'stdout'};

    printf "%sSTDERR:\n", $opt->boundary;
    print $command_res{'stderr'};

    printf "%sEND%s\n", $opt->boundary, $opt->boundary;
}
elsif ( $opt->format eq 'json' ) {
    print encode_json( \%command_res );
}
elsif ( $opt->format eq 'yaml' ) {
    print Dump( \%command_res );
}
else {
    print "script '$module_file' - Command Result:\n", dump( \%command_res ),
      "\n";
}

if ( $opt->exit ) {
  	if ( $command_res{'exit_code'} > -1 ) {
  		  exit $command_res{'exit_code'};
  	}
  	else {
  		  exit $command_res{'error_code'};
  	}
}
