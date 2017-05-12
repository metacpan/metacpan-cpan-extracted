#! /usr/bin/perl
#---------------------------------------------------------------------
# calendar.pl
# Copyright 2007 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Generate a PostScript calendar
#---------------------------------------------------------------------

use strict;
use Getopt::Long 2.17 ();
use PostScript::Calendar;

#---------------------------------------------------------------------
# Parse arguments:
#---------------------------------------------------------------------
Getopt::Long::Configure(qw(bundling no_getopt_compat));

my ($output, $year);

Getopt::Long::GetOptions(
    'output|o=s'   => \$output,
    'year|y=s'     => \$year,
    'help|?'       => \&usage,
    'version'      => \&usage
) or usage();

usage() if not $year and @ARGV < 2;

sub usage
{
    print "calendar.pl $PostScript::Calendar::VERSION\n", ;
    exit if $_[0] and $_[0] eq 'version';
    print "\n" . <<'';
Usage:  calendar.pl [options] YEAR MONTH [PARAMETER VALUE ...]
        calendar.pl --year=YEAR [PARAMETER VALUE ...]
  -o, --output=NAME  Save calendar to NAME.ps (default YEAR-MONTH)
  -y, --year=YEAR    Make a calendar for each month of YEAR
  -?, --help         Display this usage information and exit
      --version      Display version number and exit

    exit;
} # end sub usage

#---------------------------------------------------------------------
# Values surrounded by curly braces are Perl code to be eval'd:

foreach (@ARGV) {
  if (/^\{(.+)\}\z/) {
    $_ = eval $1;
  }
} # end foreach @ARGV

#---------------------------------------------------------------------
my $obj;

if ($year) {
  # Create one page for each month in a full year:
  $output = sprintf "%04d", $year unless defined $output;

  my $ps;
  for my $month (1 .. 12) {
    $ps->newpage if $ps;
    my $cal = PostScript::Calendar->new($year, $month, @ARGV, ps_file => $ps);
    $cal->generate;
    # We get the PostScript::File from the first calendar,
    # and pass that to the remaining calendars:
    $ps ||= $cal->ps_file;
  } # end for $month 1 to 12

  $obj = $ps;
} else {
  # Make a calendar for just one month:
  $output = sprintf "%04d-%02d", @ARGV unless defined $output;

  my $cal = PostScript::Calendar->new(@ARGV);

  $obj = $cal;
}

# Save the calendar:
if ($output =~ /\.(?:pdf|png)\z/i) {
  # If PDF or PNG output is requested, use PostScript::Convert:
  print "Saving $output...\n";
  require PostScript::Convert;
  PostScript::Convert::psconvert($obj, $output);
} else {
  # Otherwise, just save the PostScript code:
  print "Saving $output.ps...\n";
  $obj->output($output);
}

__END__

=head1 NAME

calendar.pl - Generate a monthly calendar in PostScript

=head1 SYNOPSIS

 Usage:  calendar.pl [options] YEAR MONTH [PARAMETER VALUE ...]
         calendar.pl --year=YEAR [PARAMETER VALUE ...]
   -o, --output=NAME  Save calendar to NAME.ps (default YEAR-MONTH)
   -y, --year=YEAR    Make a calendar for each month of YEAR
   -?, --help         Display this usage information and exit
       --version      Display version number and exit

=head1 DESCRIPTION

calendar.pl generates generates printable calendars using
L<PostScript::Calendar>.

The command line arguments are simply passed to PostScript::Calendar's
C<new> method.  Any arguments that are surrounded by curly braces are
evaluated as Perl code (after the braces are removed).  This is
necessary for passing in array references.  Don't forget to quote the
braces from the shell.

Years must be fully specified (e.g., use 1990, not 90).  Months range
from 1 to 12.  Days of the week can be specified as 0 to 7 (where
Sunday is either 0 or 7, Monday is 1, etc.).

All dimensions are specified in PostScript points (72 per inch).

If the output filename (specified with C<--output>) ends in C<.pdf> or
C<.png>, it uses PostScript::Convert to generate the requested format.

=head1 AUTHOR

Christopher J. Madsen  C<< <perl AT cjmweb.net> >>

Please report any bugs or feature requests to
C<< <bug-PostScript-Calendar AT rt.cpan.org> >>, or through the web interface
at L<http://rt.cpan.org/Public/Bug/Report.html?Queue=PostScript-Calendar>


=head1 LICENSE AND COPYRIGHT

Copyright 2007 Christopher J. Madsen. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
