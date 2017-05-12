# -*- perl -*-

use strict;
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
my $origdir = cwd;
chdir dirname($0);
my $script = basename($0, '.PL');
$script .= '.com' if $^O eq 'VMS';

unlink($script);
open OUT, ">$script" or die "open for writing $script: $!";

print OUT <<"!GROK!THIS!";
$Config{startperl}
    eval 'exec $Config{perlpath} -S \$0 \${1+"\$@"}'
	if \$running_under_some_shell;
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

##############################################################################
# podlint - beautify a POD document
#
# (C) 2001 Marek Rouchal <marekr@cpan.org>
# This is free software and can be used under the same conditions as Perl
# itself.
##############################################################################

use strict;

use Getopt::Long qw(GetOptions);
use Pod::Usage;
use Pod::Compiler qw(pod_compile);

# Option defaults
my %opt = (
  quiet => 0,
  warnings => 1,
  errors => 1,
  linelength => 0,
  unwrap => '',
  unnest => 'BCFS',
  perlcode => 1,
  i => undef
);

GetOptions(\%opt,
  qw(warnings! errors! linelength=i unwrap=s unnest=s i:s perlcode! help man))
    || pod2usage(2);

pod2usage(1) if $opt{help};
pod2usage(-exitstatus => 0, -verbose => 2) if $opt{man};

if($opt{quiet}) {
  $opt{errors} = $opt{warnings} = 0;
}

my $errors = 0;
unless(@ARGV) {
  # filter mode
  unless(&_convert_and_save(\*STDIN, undef)) {
    $errors++;
  }
}
elsif(defined $opt{i}) {
  # backup file mode
  foreach my $in (@ARGV) {
    my $inname = $in;
    unless(-s $in) {
      warn "Error: '$in' does not exist or is empty.\n";
      $errors++;
      next;
    }
    my $bak = $opt{i};
    my $out = $in;
    if(length $bak) {
      unless($bak =~ s/\*/$in/g) {
        # simply append
        $bak = $in.$bak;
      }
      $in = $bak;
    }
    if($out ne $in && !rename($out, $in)) {
      warn "Error: cannot create backup file '$in': $!\n";
    } else {
      warn "Linting $inname\n" unless($opt{quiet});
      unless(&_convert_and_save($in, $out, $inname)) {
        rename($in,$out) unless($in eq $out); # try to go back
        $errors++;
      }
    }
  }
}
else {
  # two-arg mode
  my ($in,$out) = @ARGV;
  unless(-s $in) {
    warn "Error: '$in' does not exist or is empty.\n";
    $errors++;
  } else {
    unless(&_convert_and_save($in, $out)) {
      $errors++;
    }
  }
}
warn "podlint finished with $errors error(s).\n" unless($opt{quiet});

exit $errors? 1 : 0;

sub _convert_and_save
{
  my ($in,$out,$name) = @_;
  $name = $in unless(defined $name);
  my $root = pod_compile(+{
    -ignore => $opt{unnest},
    -unwrap => $opt{unwrap},
    -perlcode => $opt{perlcode},
    -linelength => $opt{linelength},
    -errors => $opt{errors},
    -warnings => $opt{warnings}
   }, $in);

  unless($root) {
    warn "Error: Could not parse file '$name'.\n";
    return 0;
  }

  if($out) {
    unless(open(OUT, ">$out")) {
      warn "Error: Cannot write output to '$out': $!\n";
      return 0;
    }
    print OUT $root->as_pod;
    close(OUT);
  } else {
    print $root->as_pod;
  }
  1;
}

##############################################################################

=head1 NAME

podlint - beautify the POD within a file

=head1 SYNOPSIS

B<podlint> B<-help> | B<-man>

or

B<podlint>
S<[ B<-warnings> | B<-nowarnings> ]> 
S<[ B<-errors> | B<-noerrors> ]> 
S<[ B<-perlcode> | B<-noperlcode> ]> 
S<[ B<-linelength> I<num> ]> 
S<[ B<-unwrap> I<string> ]> 
S<[ B<-unnest> I<string> ]> 
S<[ I<inputfile> ]> S<[ I<outputfile> ]>

or

B<podlint> S<B<-i> I<string>> 
S<[ B<-warnings> | B<-nowarnings> ]> 
S<[ B<-errors> | B<-noerrors> ]> 
S<[ B<-perlcode> | B<-noperlcode> ]> 
S<[ B<-linelength> I<num> ]> 
S<[ B<-unwrap> I<string> ]> 
S<[ B<-unnest> I<string> ]>
I<inputfile1> S<[ I<inputfile2> ... ]>

=head1 DESCRIPTION

B<podlint> uses L<Pod::Compiler|Pod::Compiler> to compile the POD within
a file. The output contains a "beautified" POD, i.e. B<podlint> fixes
all errors and warnings with respect to proper POD syntax.

Nothing changes if the input already was perfect. If there were errors,
you should check the result whether it reflects what you intended.

This script works either in filter mode (if you omit the arguments),
i.e. it reads from STDIN and writes to STDOUT, diagnostic messages
always go to STDERR. If you specify the input file name and omit the
output file name, the result is printed to STDOUT. See L</-i string> for
an alternative way of processing arguments.

=head1 OPTIONS

=over 4

=item B<-help>

Print the usage and options.

=item B<-man>

Show the complete manual.

=item B<-warnings> | B<-nowarnings>

Enable or suppress the printing of warnings. Default is
enabled.

=item B<-errors> | B<-noerrors>

Enable or suppress the printing of errors. Default is
enabled.

=item B<-quiet>

Same as B<-nowarnings> B<-noerrors>, and suppress any progress/status
output.

=item B<-linelength> I<num>

Wrap all POD text to the given line length. Forced line breaks
(i.e. a newline followed by whitespace) is not modified. Default is
to leave paragraphs untouched.

=item B<-unwrap> I<string>

Unwrap all sequences indicated by the given string (e.g. C<I> or C<BI>),
i.e. convert C<IE<lt>abcIE<lt>defE<gt>ghiE<gt>> to 
C<IE<lt>abcE<gt>defIE<lt>ghiE<gt>>. Default is no unwraps.

=item B<-unnest> I<string>

Unnest all sequences indicated by the given string (e.g. C<B> or C<BCS>),
i.e. drop all occurrences of an interior sequence contained in one of
the same type. Default is C<BCFS>.

=item B<-perlcode> | B<-noperlcode>

Include or exclude non-POD (i.e. executable Perl code) in the output.
Default is to include Perl code.

=item B<-i> I<string>

Similar to the Perl B<-i> option, see L<perlrun>: Create a backup file of the
given input file. If I<string> is empty, the input file will be overwritten
without creating a backup. All command line arguments are treated as input
files.

=back

=head1 RETURN VALUE

0 in case of success, a non-zero value in case of fatal errors.

=head1 EXAMPLES

  cat mail_containing_perl | podlint -noperlcode | less

Get all the POD out of the given file.

  podlint abc.pod abc1.pod

Lint F<abc.pod> and write the result to F<abc1.pod>.

  podlint -linelength  -i .bak abc.pod def.pod ghi.pod

Beautify the files F<abc.pod>, F<def.pod>, F<ghi.pod>, keeping
the original contents in F<abc.pod.bak>, F<def.pod.bak>,
F<ghi.pod.bak>, respectively.

=head1 CAVEATS

This tool depends on the capabilities of B<Pod::Parser>. This means that
if you have e.g. POD code in a here document, it is subject to processing
by B<podlint> as well.

=head1 ERRORS

Errors occur if the input file(s) cannot be read, the output file(s) cannot
be written, backup file(s) cannot be created etc.

Errors in the POD syntax are printed, and B<podlint> tries to resolve them
as far as possible. The result may not be what you expected it to be, so
please crosscheck the result.

If you run B<podlint> on the result again, only those errors should re-occur
that could not be fixed (e.g. internal hyperlinks without a destination).

=head1 WARNINGS

POD syntax warnings are printed and fixed as far as possible.

=head1 BUGS

Please report bugs to <marekr@cpan.org>.

=head1 AUTHOR

Marek Rouchal <marekr@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2001 by Marek Rouchal. All rights reserved.

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Pod::Compiler>, L<podchecker>, L<Pod::Parser>

=cut

!NO!SUBS!

close OUT or die "Can't close $script: $!";
chmod 0755, $script or die "Can't reset permissions for $script: $!\n";
exec("$Config{'eunicefix'} $script") if $Config{'eunicefix'} ne ':';
chdir $origdir;
