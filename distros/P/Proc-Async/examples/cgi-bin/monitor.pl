#!/usr/bin/env perl
#
use warnings;
use strict;

use FindBin qw($Bin);
use lib "$Bin/lib";

use CGI;
use CGI::Carp qw( fatalsToBrowser );
use Proc::Async;

$| = 1;

my $cgi = CGI->new();
print $cgi->header('text/html');

my %params = $cgi->Vars;
my $jobid   = $params{'jobid'};
my $status  = "";
my $wdir    = "";
my $stdout  = "";
my $stderr  = "";
my $results = "";
my $msg     = "";

my $action = $params{'action'};
if ($action eq 'start') {

    # start an external process
    my @args = ("$Bin/bin/extester");
    push (@args, '-sleep', $params{'sleep'}) if $params{'sleep'};
    push (@args, '-stdout', $params{'stdout'}) if $params{'stdout'};
    push (@args, '-stderr', $params{'stderr'}) if $params{'stderr'};
    push (@args, '-create', $params{'file1'} . '=' . ($params{'count1'} ? $params{'count1'} : 1))
        if $params{'file1'};
    push (@args, '-create', $params{'file2'} . '=' . ($params{'count2'} ? $params{'count2'} : 1))
        if $params{'file2'};
    $jobid = Proc::Async->start (\@args);
    $msg = "Command line: " . join (" ", map {"'$_'"} @args);

} elsif ($action eq 'kill') {

    # kill an external process
    $msg = "Killing job: " . (Proc::Async->signal ($jobid, 9) ? "success\n" : "failure\n");

} elsif ($action eq 'clean') {

    # remove all results
    my $file_count = Proc::Async->clean ($jobid);
    $msg = "$file_count files for have been deleted"

}

# if there was an action changing process status it is better to wait
# a bit to display the new status rather still the old one
unless ($action eq 'status') {
    sleep (1);
}

# check the status of the started process
my @status = Proc::Async->status ($jobid);
$status = join (", ", @status) . "\n";

# show working directory and the results
$wdir = Proc::Async->working_dir ($jobid) || "";
$stdout = Proc::Async->stdout ($jobid);
$stderr = Proc::Async->stderr ($jobid);
my @files = Proc::Async->result_list ($jobid);
if (@files) {
    $results = "<table cellpadding=\"5\" border=\"0\">\n";
    foreach my $file (@files) {
        $results .= "<tr valign='top'><td>$file</td><td><pre>";
        $results .= Proc::Async->result ($jobid, $file);
        $results .= "</pre></td></tr>\n";
    }
    $results .= "</table>\n";
}

print <<"END_OF_DOC";
  <div>
      <input type="hidden" name="jobid" id="jobid" value="$jobid"/>
      <table border="0">
        <tr valign="top">
          <td>Status:</td><td>$status</td>
        </tr>
        <tr valign="top">
          <td>Job ID:</td><td>$jobid</td>
        </tr>
        <tr valign="top">
          <td>Working directory:</td><td>$wdir</td>
        </tr>
        <tr valign="top">
          <td>STDOUT:</td><td>$stdout</td>
        </tr>
        <tr valign="top">
          <td>STDERR:</td><td>$stderr</td>
        </tr>
        <tr valign="top">
          <td>Other results:</td><td>$results</td>
        </tr>
      </table>
      $msg
  </div>
END_OF_DOC
