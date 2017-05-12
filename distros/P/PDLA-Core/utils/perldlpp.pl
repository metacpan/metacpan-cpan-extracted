#!/usr/bin/perl
#
use PDLA::NiceSlice;

my $prefile = "";

{
   local $/;
   $prefile = <>;
}

my ($postfile) = &PDLA::NiceSlice::perldlpp("PDLA::NiceSlice", $prefile);

print $postfile;

__END__

=head2 perldlpp.pl

=for ref

Script to filter PDLA::NiceSlice constructs from argument file to STDOUT

=for usage

  perldlpp.pl file-w-niceslice.pm > file-no-niceslice.pm       ( unix systems)
  perl perldlpp.pl file-w-niceslice.pm > file-no-niceslice.pm  (win32 systems)

C<perldlpp.pl> is a preprocessor script for perl module files
to filter and translate the PDLA::NiceSlice constructs.  The name of
the file(s) to be filtered is given as argument to the command and the
result of the source filtering is output to STDOUT.

One use for this script is to preprocess the .pm files installed for
PDLA to remove the requirement for PDLA::NiceSlice filtering in the
core PDLA modules.  This allows PDLA to be used with environments such
as C<perlapp> that are not compatible with source code filters.

It is planned to add C<Makefile> support for this filter to the PDLA
configure, build, and install process.

=for example

  # For example (using the unix shell):
  mkdir fixed

  # filter all pm files in this directory into fixed/
  for pm in *.pm ; do perldlpp.pl $pm > fixed/$pm ; done

  Now the fixed/*.pm files have been PDLA::NiceSlice processed
  and could be used to replace the original input files as
  "clean" (no source filter) versions.

=cut

1;
