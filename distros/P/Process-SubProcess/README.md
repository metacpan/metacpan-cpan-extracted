[![Automated Tests](https://github.com/bodo-hugo-barwich/Process/actions/workflows/automated_testing.yml/badge.svg)](https://github.com/bodo-hugo-barwich/Process/actions/workflows/automated_testing.yml)
[![Publish new Release](https://github.com/bodo-hugo-barwich/Process/actions/workflows/publish_release.yml/badge.svg)](https://github.com/bodo-hugo-barwich/Process/actions/workflows/publish_release.yml)

# Process
Process::SubProcess - Perl Module for Multiprocessing

Running Sub Processes in an easy way while reading STDOUT, STDERR, Exit Code and possible System Errors. \
It also implements running multiple Sub Processes simultaneously while keeping all Report and Error Messages and Exit Codes
seperate.

# Features
Some important Features are:
* Asynchronous Launch
* Reads Big Outputs
* Execution Timeout
* Configurable Read Interval
* Captures possible System Errors at Launch Time like "file not found" Errors

# Motivation
This Module was conceived out of the need to launch multiple Tasks simultaneously
while still keeping each Log and Error Messages and Exit Codes separately.\
As I developed it as Prototype at:\
[Multi Process Manager](https://stackoverflow.com/questions/50177534/why-do-pipes-from-child-processes-break-sometimes-and-sometimes-not)\
The **Object Oriented Design** permits the implementation of the **[Command Pattern / Manager-Worker Pattern](https://en.wikipedia.org/wiki/Command_pattern)** with the `Process::SubProcess::Group` and `Process::SubProcess::Pool` Packages.\
Having a similar implementation as the [`Capture::Tiny` Package](https://metacpan.org/pod/Capture::Tiny)
it eventually evolved as a Procedural Replacement for the `Capture::Tiny::capture()` Function
which is demonstrated under [Usage > runSubProcess\(\) Function](#runsubprocess-function).\
This capability also enabled its usage as Command Line Helper Tool with the `run_subprocess.pl` script
as seen under [Usage > Runner Script](#runner-script).

## Example Use Case
The Usefulness of this Library is best shown by an Example Use Case as seen in the `Process::SubProcess::Group::Run` Test Sequence:\
Having 3 Jobs at hand of 2 seconds, 3 seconds and 1 second running them sequencially would take aproximately **6 seconds**.\
But using the `Process::SubProcess::Group` it takes effectively only **3 seconds** to complete.\
And still each Job can be evaluated separately by their own Results keeping Log Message separate from Error Messages and
viewing them in their context.
```
# Subtest: Process::SubProcess::Group::Run
    ok 1 - scripts (count: '3'): added correctly
Process Group Execution Start - Time Now: '1688542787.31262' s
    ok 2 - Process Group Execution: Execution correct
Process Group Execution End - Time Now: '1688542790.33528' s
Process Group Execution finished in '3022.66407012939' ms
    ok 3 - Process No. '0': Listed correctly
Process (8608) 'test-script:2s':
ERROR CODE: '0'
EXIT CODE: '0'
STDOUT: 'Start - Time Now: '1688542787.33535' s
script 'test_script.pl' START 0
script 'test_script.pl' PAUSE '2' ...
script 'test_script.pl' END 1
End - Time Now: '1688542789.33552' s
script 'test_script.pl' done in '2000.16403198242' ms
script 'test_script.pl' EXIT '0'
'
STDERR: 'script 'test_script.pl' START 0 ERROR
script 'test_script.pl' END 1 ERROR
'
    ok 4 - Process No. '1': Listed correctly
Process (8609) 'test-script:3s':
ERROR CODE: '0'
EXIT CODE: '0'
STDOUT: 'Start - Time Now: '1688542787.3336' s
script 'test_script.pl' START 0
script 'test_script.pl' PAUSE '3' ...
script 'test_script.pl' END 1
End - Time Now: '1688542790.3338' s
script 'test_script.pl' done in '3000.19979476929' ms
script 'test_script.pl' EXIT '0'
'
STDERR: 'script 'test_script.pl' START 0 ERROR
script 'test_script.pl' END 1 ERROR
'
    ok 5 - Process No. '2': Listed correctly
Process (8610) 'test-script:1s':
ERROR CODE: '0'
EXIT CODE: '0'
STDOUT: 'Start - Time Now: '1688542787.34636' s
script 'test_script.pl' START 0
script 'test_script.pl' PAUSE '1' ...
script 'test_script.pl' END 1
End - Time Now: '1688542788.34656' s
script 'test_script.pl' done in '1000.20098686218' ms
script 'test_script.pl' EXIT '0'
'
STDERR: 'script 'test_script.pl' START 0 ERROR
script 'test_script.pl' END 1 ERROR
'
    1..5
ok 3 - Process::SubProcess::Group::Run
```

# Usage
## Runner Script
The new **Runner Script** `run_subprocess.pl` lets process the output of different commandline tools
in a organised manner and parse it correctly into _JSON_, _YAML_ or _Plain Text_ formats:
```plain
$ bin/run_subprocess.pl -n "test-script fails" -c "t/test_script.pl 2 6" -f json | jq '.'
{
  "stdout": "Start - Time Now: '1688630328.73393' s\nscript 'test_script.pl' START 0\nscript 'test_script.pl' PAUSE '2' ...\nscript 'test_script.pl' END 1\nEnd - Time Now: '1688630330.73409' s\nscript 'test_script.pl' done in '2000.15306472778' ms\nscript 'test_script.pl' EXIT '6'\n",
  "name": "test-script fails",
  "error_code": 1,
  "stderr": "script 'test_script.pl' START 0 ERROR\nscript 'test_script.pl' END 1 ERROR\n",
  "exit_code": 6,
  "command": "t/test_script.pl 2 6",
  "pid": "7273"
}
```
```plain
$ bin/run_subprocess.pl -n "test-script fails" -c "t/test_script.pl 2 6" -f json | jq '.error_code,.exit_code'
1
6
```
```plain
$ bin/run_subprocess.pl -n "test-script fails" -c "t/test_script.pl 2 6" -f json | jq '.stderr,.exit_code,.error_code'
"script 'test_script.pl' START 0 ERROR\nscript 'test_script.pl' END 1 ERROR\n"
6
1
```

## runSubProcess() Function
Demonstrating the `runSubProcess()` Function Use Case:
```perl
use Process::SubProcess qw(runSubProcess);

use Test::More;


my $spath = '/path/to/test/script/';
my $stestscript = 'test_script.pl';
my $itestpause = 3;
my $iteststatus = 4;

my $rscriptlog = undef;
my $rscripterror = undef;
my $iscriptstatus = -1;
my $irunok = -1;


subtest 'runSubProcess() Function' => sub {

  #Execute the Command
  ($rscriptlog, $rscripterror, $iscriptstatus)
    = runSubProcess("${spath}${stestscript} $itestpause $iteststatus");

  #Evaluate the Results

  isnt($rscriptlog, undef, "STDOUT Ref is returned");
  isnt($rscripterror, undef, "STDERR Ref is returned");
  isnt($iscriptstatus, undef, "EXIT CODE is returned");
  ok($iscriptstatus =~ qr/^-?\d$/, "EXIT CODE is numeric");
  is($iscriptstatus, $iteststatus, 'EXIT CODE is correct');

  print("EXIT CODE: '$iscriptstatus'\n");

  if(defined $rscriptlog)
  {
    isnt($$rscriptlog, '', "STDOUT was captured");

    print("STDOUT: '$$rscriptlog'\n");
  } #if(defined $rscriptlog)

  if(defined $rscripterror)
  {
    isnt($$rscripterror, '', "STDERR was captured");

    print("STDERR: '$$rscripterror'\n");
  } #if(defined $rscripterror)
};

done_testing();
```

# Documentation
The Class Diagramm kann be found at:\
[Class Diagram for the Package 'Process'](docs/Process.jpg)\
![Class Diagram for the Package 'Process'](docs/Process.jpg)


