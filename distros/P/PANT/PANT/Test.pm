# PANT::Test - Test modules from PANT

package PANT::Test;

use 5.008;
use strict;
use warnings;
use Carp;
use Cwd;
use XML::Writer;
use Test::Harness::Straps;
use Benchmark;
use Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PANT ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.15';


sub new {
    my($clsname, $writer, @args) =@_;
    my $self = { 
	writer=>$writer,
	@args
    };
    bless $self, $clsname;
    return $self;
}

sub RunTests {
    my($self, %args) = @_;
    my $writer = $self->{writer};
    my $dir = $args{directory};
    my $pushstreams = 1;
    my $cdir;
    if ($dir) {
	$cdir = getcwd;
	chdir($dir) || Abort("Can't change to directory $dir");
    }
    my $retval = 1;
    $writer->dataElement('h2', "Run the following tests");
    $writer->startTag('ul');
    $writer->startTag('table', border=>1);
    $writer->startTag('tr');
    foreach my $h (("Test",  "No.", "Passed", "Failed", "Skipped", "Pass rate", "Failure reason")) {
      $writer->dataElement('th', $h);
    }
    $writer->endTag('tr');
    my $stderrfile = "xxxxstderr$$.txt";
    my($OLDERR, $stderr);
    if ($pushstreams) {
      # push the output state
      open $OLDERR,     ">&", \*STDERR or die "Can't dup STDERR: $!";
      $stderr = "";
      close(STDERR);
      open(STDERR, ">$stderrfile")      or die "Can't open STDERR: $!";
    }
    my $totaltests = 0;
    my $totalpass = 0;
    my $tfiles = 0;
    my $tfailures = 0;
    my $strap = new Test::Harness::Straps;
    my $t_start = new Benchmark;

    foreach my $tfile (@{$args{tests}}) {
      $writer->startTag('tr');
      $writer->dataElement('td', $tfile);
      $tfiles ++;

      my %results;
      if (!$self->{dryrun}) {
	%results = $strap->analyze_file($tfile);
      }

      if (!%results) {
	$writer->dataElement('td', $self->{dryrun} ? "Test not run -dryrun" : $strap->{error});
	$writer->endTag('tr');
	$totaltests ++;
	next;
      };
      $tfailures ++ if (!$results{passing});
      $totalpass +=  $results{ok};
      $totaltests += $results{max};
      my %attr = (id=> ($results{passing} ? "pass" : "fail"));
      $writer->dataElement('td',  $results{max}, %attr);
      $writer->dataElement('td', $results{ok}, %attr);
      $writer->dataElement('td',  $results{max} - $results{ok}, %attr);
      $writer->dataElement('td', $results{skip}, %attr);
      $writer->dataElement('td', sprintf("%.2f", $results{ok} / $results{max} * 100), %attr);
      $writer->startTag('td', %attr);
      foreach my $err (MakeFailureReport(\%results)) {
	$writer->characters($err);
	$writer->emptyTag('br');
      }
      $writer->endTag('td');
      $writer->endTag('tr');
    }
    my $timed = timediff(new Benchmark, $t_start);
    if ($pushstreams) {
      open STDERR, ">&", $OLDERR    or die "Can't dup OLDERR: $!";
      if (open JUNK, "$stderrfile") {
	  local($/);
	  $stderr = <JUNK>;
	  close(JUNK);
      }
      unlink($stderrfile);
    }
    $writer->endTag("table");
    $writer->dataElement('li',
			 sprintf("Summary: Test Files $tfiles, Failed Test files $tfailures, %.2f%%",
				 ($tfiles-$tfailures) / $tfiles * 100));
    $writer->dataElement('li',
			 sprintf("Summary: Total Tests $totaltests, Failed Tests %d, Pass rate %.2f%%",
				 $totaltests - $totalpass,
				 $totalpass / $totaltests * 100));
    $writer->dataElement('li', "Took " . timestr($timed));

    if($stderr) {
      $writer->dataElement('li', "Error output"); 
      $writer->dataElement('pre', $stderr);
    }
    chdir ($cdir) if ($cdir);
    $writer->endTag('ul');
    return $retval;
}

sub MakeFailureReport {
  my $report = shift;
  return ("All Passed") if ($report->{passing});
  my @results = ();
  my $tnum = 0;
  foreach my $test (@{$report->{details}}) {
    $tnum ++;
    next if ($test->{ok});
    push(@results, "$tnum $test->{name}");
  }
  return @results;
}
1;
__END__


=head1 NAME

PANT::Test - PANT support for running tests

=head1 SYNOPSIS

  use PANT::Test;

  $tester = new PANT::Test($xmlwriter);
  $tester->runtests(tests=>[@testlist], directory=>"test");

=head1 ABSTRACT

  This is part of a module to help construct automated build environments.
  This part is for running tests.

=head1 DESCRIPTION

This module is part of a set to help run automated
builds of a project and to produce a build log. This part
is designed to incorporate runs of the perl test suite.

=head1 EXPORTS

None

=head1 METHODS

=head2 new

Constructor for a test object. Requires an XML::Writer object as a parameter, which it
will use for subsequent log construction.

=head2 runtests

This takes a list of files with tests in to run. The output is 
trapped and diverted to the logging stream. It appears as an html table.
Table cells that refer to a failed test will have the html ID of "fail", and those
that pass will be tagged with the ID "pass".
This allows for appropriate syle sheet controls to highlight cells.

C<td#fail { background:red }>

C<td#pass { background:green }>

It takes the following options

=over 4

=item tests=>[list of tests]

The list of tests to run (.t files).

=item directory=>somewhere

An optional directory to change to for the duration of the test

=back


=head1 SEE ALSO

Makes use of XML::Writer to construct the build log.


=head1 AUTHOR

Julian Onions, E<lt>julianonions@yahoo.nospam-co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Julian Onions

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 


=cut

