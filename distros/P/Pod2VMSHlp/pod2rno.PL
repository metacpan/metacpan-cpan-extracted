#!/usr/local/bin/perl

use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
$origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PL');
$file .= '.com' if $^O eq 'VMS';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
$Config{startperl}
!GROK!THIS!
#    eval 'exec $Config{perlpath} -S \$0 \${1+"\$@"}'
#        if \$running_under_some_shell;
#!GROK!THIS!

# The #!/perl is to ensure that perl -x pod2rno.com works ok on VMS,
# without interfering with other platforms $Config{startperl} #! paths.
if ($^O eq 'VMS') {
print OUT <<'!NO!SUBS!';
#!/perl
!NO!SUBS!
}

# In the following, perl variables are not expanded during extraction.
print OUT <<'!NO!SUBS!';

# pod2rno -- Convert POD data to formatted DSR input.
#
# Copyright 2001 by Peter Prymmer <pvhp@best.com>
# based upon pod2man.PL,v 1.4 by Russ Allbery
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

require 5.004;

use Getopt::Long qw(GetOptions);
use Pod::Dsr ();
use Pod::Usage qw(pod2usage);

use strict;

# Insert -- into @ARGV before any single dash argument to hide it from
# Getopt::Long; we want to interpret it as meaning stdin (which Pod::Parser
# does correctly).
my $stdin;
@ARGV = map { $_ eq '-' && !$stdin++ ? ('--', $_) : $_ } @ARGV;

# Parse our options, trying to retain backwards compatibility with pod2man
# but allowing short forms as well.  --lax is currently ignored.
my %options;
Getopt::Long::config ('bundling_override');
GetOptions (\%options, 'section|s=s', 'release|r=s', 'chapter|c=i',
            'center=s', 'date|d=s', 'official|o', 'quotes|q=s', 
            'layout|l=s', 'lax',
            'help|h') or exit 1;
pod2usage (0) if $options{help};

# Official sets --center, but don't override things explicitly set.
if ($options{official} && !defined $options{center}) {
    $options{center} = 'Perl Programmers Reference Guide';
}

# Initialize and run the formatter, pulling a pair of input and output off
# at a time.
my $parser = Pod::Dsr->new (%options);
my @files;
do {
    @files = splice (@ARGV, 0, 2);
    $parser->parse_from_file (@files);
} while (@ARGV);
  
__END__

=head1 NAME

pod2rno - Convert POD data to formatted DSR input

=head1 SYNOPSIS

pod2rno [B<--layout>=I<string>] [B<--chapter>=I<number>]
[B<--section>=I<manext>] [B<--release>=I<version>]
[B<--center>=I<string>] [B<--date>=I<string>] 
[B<--official>] [B<--lax>]
[B<--quotes>=I<quotes>] [I<input> [I<output>] ...]

pod2rno B<--help>

=head1 DESCRIPTION

B<pod2rno> is a front-end for Pod::Dsr, using it to generate DSR .RNO input
from POD source.  The resulting DSR code is suitable for use with the 
RUNOFF command.

I<input> is the file to read for POD source (the POD can be embedded in
code).  If I<input> isn't given, it defaults to STDIN.  I<output>, if given,
is the file to which to write the formatted output.  If I<output> isn't
given, the formatted output is written to STDOUT.  Several POD files can be
processed in the same B<pod2rno> invocation (saving module load and compile
times) by providing multiple pairs of I<input> and I<output> files on the
command line.

B<--section>, B<--release>, B<--center>, B<--date>, B<--layout>, and 
B<--official> can be used to set the headers and footers to use; if not 
given, Pod::Dsr will assume various defaults.  See below or L<Pod::Dsr> 
for details.

Besides the obvious pod conversions, Pod::Dsr, and therefore pod2rno also
takes care of formatting func(), func(n), and simple variable references
like $foo or @bar so you don't have to use code escapes for them; complex
expressions like C<$fred{'stuff'}> will still need to be escaped, though.
It takes care of several other runoff-specific tweaks.  See L<Pod::Dsr> 
for complete information.

=head1 OPTIONS

=over 4

=item B<-l> I<string>, B<--layout>=I<string>

Inserts the given I<string> at the head of the dsr document, typically used
to set the .LAYOUT style.  The default is C<.LAYOUT 0>, but could be
given as C<.LAYOUT >I<n1[,n2]>, where I<n1> can be any of qw(0 1 2 3),
if I<n1> E<gt> 0 then I<n2> can specify the number of lines below
the last line of text on a page where the page number will appear.
I<E.g.> C<-l ".LAYOUT 1,2"> or C<--layout=".LAYOUT 2,2">.
 
=item B<-c> I<chapter_number>, B<--chapter>=I<chapeter_number>

Inserts a C<.CHAPTER >I<chapter number> command into the document after 
the .TITLE.

=item B<--center>=I<string>

Sets the centered page header to I<string>.  The default is "User
Contributed Perl Documentation", but also see B<--official> below.

=item B<-d> I<string>, B<--date>=I<string>

Set the left-hand footer string to this value.  By default, the modification
date of the input file will be used, or the current date if input comes from
STDIN.

=item B<-h>, B<--help>

Print out usage information.

=item B<--lax>

Don't complain when required sections are missing.  Not currently used, as
POD checking functionality is not yet implemented in Pod::Dsr 
(See L<podchecker>).

=item B<-o>, B<--official>

Set the default header to indicate that this page is part of the standard
Perl release, if B<--center> is not also given.

=item B<-q> I<quotes>, B<--quotes>=I<quotes>

Sets the quote marks used to surround C<E<lt>> text to I<quotes>.  If
I<quotes> is a single character, it is used as both the left and right
quote; if I<quotes> is two characters, the first character is used as the
left quote and the second as the right quoted; and if I<quotes> is four
characters, the first two are used as the left quote and the second two as
the right quote.  I<quotes> may also be set to the special value C<none>, in 
which case no quote marks are added around C<E<lt>> text.

=item B<-r>, B<--release>

Set the centered footer.  By default, this is the version of Perl you run
B<pod2rno> under.

=item B<-s>, B<--section>

Set the section for the C<.HEADER_LEVEL> command.  The standard section 
numbering convention is to use 1 for user commands, 2 for system calls, 3 for
functions, 4 for devices, 5 for file formats, 6 for games, 7 for
miscellaneous information, and 8 for administrator commands.  There is a lot
of variation here, however; some systems (like Solaris) use 4 for file
formats, 5 for miscellaneous information, and 7 for devices.  Still others
use 1m instead of 8, or some mix of both.  About the only section numbers
that are reliably consistent are 1, 2, and 3.  By default, section 1 will 
be used unless the file ends in .pm in which case section 3 will be selected.

=back

=head1 DIAGNOSTICS

If B<pod2rno> fails with errors, see L<Pod::Dsr> and L<Pod::Parser> for
information about what those errors might mean.

=head1 EXAMPLES

    pod2rno program > program.rno
    runoff program

    pod2rno SomeModule.pm > PERL_ROOT:[LIB.POD]SomeModule.rno
    runoff PERL_ROOT:[LIB.POD]SomeModule.rno

You may then TYPE or PRINT out the resulting .MEM file.

If you would like to print out a lot of pod pages continuously, you probably
want to use the pod2mem utility instead of pod2rno (pod2mem has yet to be
written though :-).

Index entries are inserted for every =head\d directive as well as for 
each list element.  To obtain a PRINT able or TYPE able index file
run B<runoff> with the /INTERMEDIATE qualifier then the /INDEX 
qualifier, as in:

    runoff /intermediate program.rno
    runoff /index program.brn
    runoff program.rnx

after which you may TYPE or PRINT both the program.mem file as well as the 
program.mex file which holds the formatted index.

A table of contents may also be generated with the /CONTENTS qualifier 
to RUNOFF like so:

    runoff /intermediate program.rno
    runoff /contents program.brn
    runoff program.rnt
    
after which you may TYPE or PRINT both the program.mem file as well as the 
program.mec file which holds the formatted table of contents.

=head1 BUGS

Lots of this documentation is duplicated from L<Pod::Dsr>.

POD checking and the corresponding B<--lax> option don't work yet.

=head1 SEE ALSO

L<Pod::Dsr|Pod::Dsr>, L<Pod::Man|Pod::Man>, L<Pod::Parser|Pod::Parser>, 
HELP RUNOFF.  HELP DSR.

For additional information that may be more accurate for your specific
system, see either HELP RUNOFF or HELP DSR.  See also the F<README.runoff>
file that comes with the Pod2VMSHlp distribution.

The pod markup for Pod::Man and pod2man have information on typical
sections to include in manual page documents.

=head1 AUTHOR

Peter Prymmer pvhp@best.com, based on B<pod2man> by Russ Allbery 
which was in turn based on the original B<pod2man> by Larry Wall 
and Tom Christiansen.  Large portions of this documentation, 
particularly the sections on the anatomy of a proper man
page, are taken from the B<pod2man> documentation by Tom.

=cut
!NO!SUBS!
#'# (cperl-mode)

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;

