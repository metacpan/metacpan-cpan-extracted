# Copyright 2012, 2013, 2014, 2015 Kevin Ryde

# This file is part of Regexp-Common-Other.
#
# Regexp-Common-Other is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Regexp-Common-Other is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Regexp-Common-Other.  If not, see <http://www.gnu.org/licenses/>.


package Regexp::Common::Emacs;
use 5.005;
use strict;
use Carp;

# no import(), don't want %RE or builtins, and will call pattern() by full name
use Regexp::Common ();

use vars '$VERSION';
$VERSION = 14;

## no critic (RequireInterpolationOfMetachars)

# uncomment this to run the ### lines
# use Smart::Comments;


# "[:digit:]" in perl 5.6 where available
# "0-9"       in perl 5.005 and earlier
use constant DIGIT => do {
  local $^W = 0;
  eval q{'0' =~ /[[:digit:]]/ ? '[:digit:]' : '0-9'}
    || die "Oops, eval for [:digit:] error: ",$@;
};
### DIGIT: DIGIT()


# Ending with "~", per Emacs manual info "(emacs)Backup Names" and function
# backup-file-name-p
# Eg. "foo.c~" or "foo.c.~123~"
#
Regexp::Common::pattern
  (name   => ['Emacs','backup'],
   create => sub {
     my ($self, $flags) = @_;
     ### $flags

     if (exists $flags->{'-single'}) {
       # presumed from single only
       # $1=whole
       # $2=basename
       if (exists $flags->{'-keep'}) {
         return '(?k:(?k:.+)~$)';
       } else {
         return '.~$';
       }
     }

     if (exists $flags->{'-numbered'}) {
       if (! exists $flags->{'-notnumbered'}) {
         # numbered only
         # $1=whole
         # $2=basename
         # $3=number
         if (exists $flags->{'-keep'}) {
           return '(?k:(?k:.+)\.~(?k:\d+)~$)';
         } else {
           return '.\.~\d+~$';
         }
       }
     } else {
       if (exists $flags->{'-notnumbered'}) {
         # not numbered only
         # $1=whole
         # $2=basename
         #
         # .* \D~         z~       non-digit
         # .* [^~]\d+~    z123~    non-~
         # .* [^.]~\d+~   z~123~   non-.
         # ^  \.~\d+~     .~123~   basename empty
         #
         return '(?k:(?k:.*(?:\D|(?:[^~'.DIGIT().']|(?:[^.]|^\.)~)\d+))~$)';
       }
     }

     # numbered or not numbered
     if (exists $flags->{'-keep'}) {
       # $1=whole
       # $2=basename
       # $3=number or undef
       return '(?k:(?k:.+?)(?:\.~(?k:\d+))?~$)';
     } else {
       return '.~$';
     }

   });

# begin and end with "#", per Emacs function auto-save-file-name-p
Regexp::Common::pattern
  (name   => ['Emacs','autosave'],
   create => '^(?k:#(?k:.+)#$)');

# file-locked-p and C source MAKE_LOCK_NAME()
Regexp::Common::pattern
  (name   => ['Emacs','lockfile'],
   create => sub {
     my ($self, $flags) = @_;
     if (exists $flags->{'-keep'}) {
       return '^(?k:\.\#(?k:.+))$';
     } else {
       return '^\.\#.';
     }
   });

# any of backup,autosave,lockfile
#      (.+) ~$    backup
# ^#   (.+) #$    autosave
# ^\.# (.+)     lockfile
Regexp::Common::pattern
  (name   => ['Emacs','skipfile'],
   create => sub {
     my ($self, $flags) = @_;
     if (exists $flags->{'-keep'}) {
       return '^(?k:\.\#.+|\#.+\#|.+~)$';
     } else {
       return '^(?:\.\#.|\#.+\#$)|.~$';
     }
   });

1;
__END__

=for stopwords Ryde filename filenames basename Basename-only lockfile lockfiles symlink symlinks PID autosave builtin builtins non-builtin

=head1 NAME

Regexp::Common::Emacs -- regexps for some Emacs filenames

=for test_synopsis my ($str)

=head1 SYNOPSIS

 use Regexp::Common 'Emacs', 'no_defaults';
 if ($str =~ /$RE{Emacs}{backup}/) {
    # ...
 }

 # regexp
 my $re1 = $RE{Emacs}{lockfile};

 # subroutine style to get regexp
 use Regexp::Common 'RE_Emacs_autosave';
 my $re2 = RE_Emacs_autosave();

=head1 DESCRIPTION

This module is regexps matching filenames used by Emacs.  They're designed
to operate only on the filename without a directory part, so

    foo.txt            good
    /dir/foo.txt       bad

Basename-only is because the directory and/or volume part is system
dependent and best left to something like C<splitpath()> from L<File::Spec>.
The basename is as per C<readdir()> if scanning a directory.

See L<Regexp::Common> for basic operation of C<Regexp::Common>.

=head2 Patterns

=over

=item C<$RE{Emacs}{backup}>

Match an Emacs backup filename, with no directory part.  This is filenames
like

    foo.txt~          single
    foo.txt.~123~     numbered

The C<-keep> option captures are

    $1    whole string
    $2    originating filename "foo.txt"
    $3    backup number "123", or undef if single

Options can restrict to numbered or single backups.

=over

=item C<$RE{Emacs}{backup}{-numbered}>

Match only numbered backup files, not single ones.

    foo.txt.~123~     matched
    foo.txt~          not matched

=item C<$RE{Emacs}{backup}{-notnumbered}>

Match only single backup files, not numbered ones.

    foo.txt~          matched
    foo.txt.~123~     not matched

C<-numbered> and C<-notnumbered> are mutually exclusive.  A given backup
file matches just one of the two.

A file such as F<foo.txt.~123~> is presumed to be a numbered backup.  It
could be a single backup from F<foo.txt.~123>, but files named that way
ought to be unusual.

=item C<$RE{Emacs}{backup}{-single}>

Match backup files and assume that they are always single backups.  This
pattern is anything ending F<~>.

    foo.txt~          matched
    foo.txt.~123~     matched, $2 = foo.txt.~123

This is the same as the default C<$RE{Emacs}{backup>>, but the C<-keep>
originating name in C<$2> becomes everything before the ending F<~>, with no
number part distinguished.

=back

Emacs makes a backup file when first changing a file.  The default is a
single backup F<foo.txt~>.  The C<version-control> variable can be set for
rolling numbered backups F<foo.txt.~1~>, F<foo.txt.~2~>, F<foo.txt.~3~> etc.

See the I<GNU Emacs Manual> section "Single or Numbered Backups" (node
"Backup Names") and function C<backup-file-name-p> for the name pattern.

For reference, the C<mount> program (see L<mount(8)>) uses F</etc/mtab~> as
a lockfile.  F<mtab~> would be reckoned an Emacs backup file by the patterns
here.

=item C<$RE{Emacs}{lockfile}>

Match an Emacs lockfile filename, with no directory part.  This is a
filename like

    .#foo.txt

The C<-keep> option captures are

    $1       whole string
    $2       originating filename "foo.txt"

Emacs creates a lockfile to prevent two users or two running copies of Emacs
from editing the same file simultaneously.  On a Unix-like system a lockfile
is normally a symlink to a non-existent target with user and PID.  That
means ignoring dangling symlinks will also ignore Emacs lockfiles -- if
that's easier than checking filenames.

See the I<GNU Emacs Manual> section "Protection against Simultaneous
Editing" (node "Interlocking") and C source code C<fill_in_lock_file_name()>
for the name construction.

=item C<$RE{Emacs}{autosave}>

Match an Emacs autosave filename, with no directory part.  This is a
filename like

    #foo.txt#

The C<-keep> option captures are

    $1       whole string
    $2       originating filename "foo.txt"

Emacs creates an autosave file with the content of a file buffer which has
been edited and not yet saved.  The autosave file can be used to recover
those edits in the event of a system crash (C<M-x recover-session> or
individual C<M-x recover-file> or C<M-x recover-this-file>).

See the I<GNU Emacs Manual> section "Auto-Save Files" (node "Auto-Saving")
and function C<auto-save-file-name-p> for the pattern.

=item C<$RE{Emacs}{skipfile}>

Match Emacs-related filenames which can generally be skipped.  This means a
backup, lockfile or autosave as above.

    foo.txt~             backup
    foo.txt.~123~        backup
    .#foo.txt            lockfile
    #foo.txt#            autosave

With the C<-keep> option the only capture is

    $1       whole string

For example to exclude Emacs bits when reading a directory,

    opendir DH, '/some/dir' or die $!;
    while (my $filename = readdir DH) {
      next if $filename =~ $RE{Emacs}{skipfile};
      print "$filename\n";
    }
    closedir DH;

=back

=head1 IMPORTS

This module should be loaded through the C<Regexp::Common> mechanism, see
L<Regexp::Common/Loading specific sets of patterns.>.  Remember that loading
an add-on pattern like this module also loads all the builtin patterns by
default.

    # Emacs plus all builtins
    use Regexp::Common 'Emacs';

If you want only C<$RE{Emacs}> then add C<no_defaults> (or list specific
desired builtins).

    # Emacs alone
    use Regexp::Common 'Emacs', 'no_defaults';

=head1 SEE ALSO

L<Regexp::Common>

=head1 HOME PAGE

http://user42.tuxfamily.org/regexp-common-other/index.html

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015 Kevin Ryde

Regexp-Common-Other is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Regexp-Common-Other is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Regexp-Common-Other.  If not, see <http://www.gnu.org/licenses/>.

=cut
