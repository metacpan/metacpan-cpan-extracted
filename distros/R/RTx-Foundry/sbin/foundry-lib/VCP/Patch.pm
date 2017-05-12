package VCP::Patch ;

=head1 NAME

VCP::Patch - Apply the (almost) unified diffs used in RevML

=head1 SYNOPSIS

    use VCP::Patch ;

    vcp_patch( $source_file_name, $result_file_name, $patch_file_name ) ;

=head1 DESCRIPTION

Creates the result file by applying the patch to the source file.  Obliterates
the result file even if the patch fails.

The patches are in a "unified diff" format, but without the filename headers
(these are passed as other data fields in VCP and the actual filenames are just
working files and are not important).  Some example patches:

=item *

For a one line file:

   @@ -1 +1 @@
   -a/deeply/buried/file, revision 1, char 0x01="<char code="0x01" />"
   +a/deeply/buried/file, revision 2, char 0x09="  "

=item *

For a several line file with multiple changes:

Here are the source and result files side-by-side:

   Source	Result
   ======	======

   1            1
   2		2
   3		3
   4		4
   5d		5a
   6		6
   7		7
   8		8
   9		9
   10		9a
   11		10
   11d		11
   12		12
   13		13

The "patch" to transform the source in to the result can be expressed in
several ways, depending on the amount of context.  VCP requires no context
since the result is checked with an MD5 checksum.  Context is, however,
sometimes used to make the RevML a bit more human readable, though this can
vary.

=over

=item 0 context (C<diff -U 0>):

   @@ -5 +5 @@
   -5d
   +5a
   @@ -9,0 +10 @@
   +9a
   @@ -12 +12,0 @@
   -11d

=item 1 line of context (C<diff -U 1>):

   --- A   Sat Aug 25 00:05:26 2001
   +++ B   Sat Aug 25 00:05:26 2001
   @@ -4,3 +4,3 @@
    4
   -5d
   +5a
    6
   @@ -9,5 +9,5 @@
    9
   +9a
    10
    11
   -11d
    12

=item 3 lines of context (C<diff -U 3 ...> or C<diff -u ...>)

   --- A   Sat Aug 25 00:05:26 2001
   +++ B   Sat Aug 25 00:05:26 2001
   @@ -2,13 +2,13 @@
    2
    3
    4
   -5d
   +5a
    6
    7
    8
    9
   +9a
    10
    11
   -11d
    12
    13

=back

=head1 Functions

=over

=cut

@ISA    = qw( Exporter ) ;
@EXPORT = qw( vcp_patch ) ;

use strict ;
use Carp ;
use VCP::Debug ':debug' ;
use Exporter ;

=item vcp_patch

Takes a patch file name, a source file name, and a result file name and
performs the patch.  Called from VCP::Source::revml to reconstitute revisions
given by delta records.

Will die on error, always returns true.

=cut

sub vcp_patch {
   my ( $source_fn, $result_fn, $patch_fn ) = @_ ;

   Carp::confess "undefined source_fn" unless defined $source_fn;
   Carp::confess "undefined result_fn" unless defined $result_fn;
   Carp::confess "undefined patch_fn"  unless defined $patch_fn;

   debug "vcp: patching $source_fn -> $result_fn using $patch_fn" if debugging ;

   open PATCH,  "<$patch_fn"     or croak "$!: $source_fn" ;
   open SOURCE, "<$source_fn"    or croak "$!: $source_fn" ;
   open RESULT, ">$result_fn"    or croak "$!: $result_fn" ;

   ## We'll need to make sure the diff's line endings match up with the
   ## source files' somehow.
   binmode PATCH;
   binmode SOURCE;
   binmode RESULT;

   my $source_pos = 1;

   while ( <PATCH> =~ /(.)(.*?\n)/ ) {
      my ( $fchar, $patch_line ) = ( $1, $2 );
      if ( $fchar eq '@' ) {
         $patch_line =~ /^\@ -(\d+)(?:,\d+)? [+-]\d+(,\d+)? \@\@/
             or croak "Can't parse diff line: '$fchar$patch_line'.";
         my $first_source_line = $1;
         while ( $source_pos < $first_source_line ) {
            my $source_line = <SOURCE>;
            croak "Ran off end of source file $source_fn at line $source_pos"
               unless defined $source_line;
            print RESULT $source_line;
            ++$source_pos;
         }
      }
      elsif ( $fchar eq '-' ) {
         my $source_line = <SOURCE>;
         croak "Ran off end of source $source_fn at line $source_pos"
            unless defined $source_line;
         $source_line =~ s/[\r\n]+\z//;
         $patch_line =~ s/[\r\n]+\z//;
         unless ( $source_line eq $patch_line ) {
            $source_line =~ s/([\000-\037])/sprintf "\\x%02x", ord $1/ge;
            $patch_line  =~ s/([\000-\037])/sprintf "\\x%02x", ord $1/ge;
            croak "Patch line disagrees with source line $source_pos:\n",
               "   source file: '$source_fn'\n",
               "   patch file : '$patch_fn'\n",
               "   result file: '$result_fn'\n",
               "   source line: \"$source_line\"\n",
               "   patch  line: \"$patch_line\"\n";
         }
         ++$source_pos;
      }
      elsif ( $fchar eq ' ' ) {
         my $source_line = <SOURCE>;
         croak "Ran off end of source file $source_fn at line $source_pos"
            unless defined $source_line;
         print RESULT $source_line;
         ++$source_pos;
      }
      elsif ( $fchar eq '+' ) {
         print RESULT $patch_line;
         ++$source_pos;
      }
      else {
          croak "Unknown line type '$fchar' in diff line '$fchar$patch_line'";
      }
   }

   print RESULT <SOURCE> ;

   close SOURCE or croak "$!: $source_fn" ;
   close RESULT or croak "$!: $result_fn" ;
   close PATCH  or croak "$!: $patch_fn" ;
   return 1 ;
}

=head1 COPYRIGHT

Copyright 2000, Perforce Software, Inc.  All Rights Reserved.

This module and the VCP package are licensed according to the terms given in
the file LICENSE accompanying this distribution, a copy of which is included in
L<vcp>.

=head1 AUTHOR

Sean McCune <sean@sean-mccune.com>

=cut

1 ;
