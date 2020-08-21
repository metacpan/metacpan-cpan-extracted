# -*- Perl -*-
#
# Solicits data from an external editor. Run perldoc(1) on this module
# for additional documentation.

package Term::CallEditor;

use strict;
use warnings;

require 5.008;

use vars qw(@EXPORT @ISA $VERSION $errstr);
@EXPORT = qw(solicit);
@ISA    = qw(Exporter);
use Exporter;

use File::Temp qw(tempfile);
use IO::Handle;    # for way olden versions of Perl
use POSIX qw(getpgrp tcgetpgrp);
use Text::ParseWords qw(shellwords);

$VERSION = '1.00';

sub solicit {
    my $message = shift;
    my $params  = shift || {};
    $errstr = '';

    unless (exists $params->{skip_interative} and $params->{skip_interative}) {
        return unless _is_interactive();
    }

    File::Temp->safe_level($params->{safe_level}) if exists $params->{safe_level};
    my ($tfh, $filename) = tempfile(UNLINK => 1);

    unless ($tfh and $filename) {
        $errstr = 'no temporary file';
        return;
    }

    if (exists $params->{binmode_layer}
        and defined $params->{binmode_layer}) {
        binmode($tfh, $params->{binmode_layer});
    } elsif ($params->{BINMODE}) {
        binmode($tfh);
    }

    select((select($tfh), $|++)[0]);

    if (defined $message) {
        my $ref = ref $message;
        if (not $ref) {
            print $tfh $message;
        } elsif ($ref eq 'SCALAR') {
            print $tfh $$message;
        } elsif ($ref eq 'ARRAY') {
            print $tfh "@$message";
        } elsif ($ref eq 'GLOB') {
            while (my $line = readline $message) {
                print $tfh $line;
            }
        } elsif (UNIVERSAL::can($message, 'getlines')) {
            print $tfh $message->getlines;
        }
        # Help the bits reach the disk
        $tfh->flush();
        $params->{NOSYNC} = 1 if $^O =~ m/Win32/;
        if (!$params->{NOSYNC}) {
            $tfh->sync();
        }
    }

    my $ed = defined $params->{DEFAULT_EDITOR} ? $params->{DEFAULT_EDITOR} : 'vi';
    my $status;
    my @errs;
    # new in 2020, support for VISUAL !!
    for my $editor ($ENV{VISUAL}, $ENV{EDITOR}, $ed) {
        next unless length $editor;
        my @cmd = (shellwords($editor), $filename);
        $status = system { $cmd[0] } @cmd;
        if ($status != 0) {
            push @errs,
              ($status != -1)
              ? "external editor failed: editor=$editor, errstr=$?"
              : "could not launch program: editor=$editor, errstr=$!";
        } else {
            last;
        }
    }
    if ($status != 0) {
        $errstr = join ' ', @errs;
        return;
    }

    # Must reopen filename; the editor could pull a rename(2) on us, in
    # which case $tfh is now invalid.
    my $outfh;
    unless (open($outfh, '<', $filename)) {
        $errstr = "could not reopen tmp file: errstr=$!";
        return;
    }

    return wantarray ? ($outfh, $filename) : $outfh;
}

# Perl CookBook code to check whether terminal is interactive
sub _is_interactive {
    my $tty;
    unless (open $tty, '<', '/dev/tty') {
        $errstr = "cannot open /dev/tty: errno=$!";
        return;
    }
    my $tpgrp = tcgetpgrp fileno $tty;
    my $pgrp  = getpgrp();
    close $tty;
    unless ($tpgrp == $pgrp) {
        $errstr = "no exclusive control of tty: pgrp=$pgrp, tpgrp=$tpgrp";
        return;
    }
    return 1;
}

1;
__END__

=head1 NAME

Term::CallEditor - solicit data from an external editor

=head1 SYNOPSIS

  use Term::CallEditor qw/solicit/;

  my $fh = solicit('FOO: please replace this text');
  die "$Term::CallEditor::errstr\n" unless $fh;

  print while readline $fh;

=head1 DESCRIPTION

This module calls an external editor via the C<solicit()> function, then
returns any data from this editor as a file handle. The environment
variables C<VISUAL> and then C<EDITOR> are consulted for a program name
to run, otherwise falling back to L<vi(1)>. The L<Text::ParseWords>
C<shellwords()> function is used to expand the environment variables.

C<solicit()> returns a temporary file handle pointing to what was
written in the editor (and also the filename in list context).

=head1 FUNCTION

=over 4

=item B<solicit>

C<solicit()> as a second argument accepts a number of optional
parameters as a hash reference.

  solicit(
      "\x{8ACB}",
      {   skip_interactive => 1,
          binmode_layer    => ':utf8'
      }
  );

=over 4

=item B<BINMODE> => I<BOOLEAN>

If true, enables C<binmode> on the filehandle prior to writing the
message to it.

=item B<DEFAULT_EDITOR> => I<string>

What to use as the default editor instead of L<vi(1)>.

=item B<NOSYNC> => I<BOOLEAN>

If true, C<sync()> from L<IO::Handle> will not be called. C<sync()> is
not called when on Win32, but otherwise is called by default.

=item B<binmode_layer> => I<binmode layer>

If set, enables C<binmode> on the filehandle prior to writing the
message to it.

=item B<safe_level> => I<NUMBER>

Set a custom C<safe_level> value for the L<File::Temp> method of
that name.

=item B<skip_interactive> => I<BOOLEAN>

If true, C<solicit> skips making a test to see whether the terminal is
interactive.

=back

On error, C<solicit()> returns C<undef>. Consult
C<$Term::CallEditor::errstr> for details. Note that L<File::Temp> may
throw a fatal error if the C<safe_level> checks fail, so paranoid coders
should wrap the C<solicit> call in an C<eval> block (or instead use
something like L<Syntax::Keyword::Try>).

=back

=head1 EXAMPLES

See also the C<eg/solicit> script under the module distribution.

=over 4

=item B<Pass in a block of text to the editor>

Use a here doc:

  my $fh = solicit(<< "END_BLARB");

  FOO: This is an example designed to span multiple lines for
  FOO: the sake of an example that span multiple lines.
  END_BLARB

=item B<Shell Exec Wrapper>

A shell exec wrapper may be necessary as a target for EDITOR (or VISUAL)
as not all programs that support EDITOR (or VISUAL) perform shell word
splitting on the input, and the C<shellword> splitting (now) done by
this module may not suffice for complicated shell commands:

  #!/bin/sh
  exec youreditor --some-arg "$@"

=back

=head1 BUGS

No known bugs.

=head2 Reporting Bugs

Newer versions of this module may be available from CPAN.

If the bug is in the latest version, send a report to the author.
Patches that fix problems or add new features are welcome.

L<https://github.com/thrig/Term-CallEditor>

=head2 Known Issues

This module relies heavily on the Unix terminal, permissions on the
temporary directory (for the L<File::Temp> module C<safe_level> call),
whether C<system()> can actually run the C<EDITOR> environment variable,
and so forth.

=head1 SEE ALSO

L<vipe(1)> of moreutils to use L<vi(1)> in pipes.

https://unix.stackexchange.com/questions/4859/visual-vs-editor-what-s-the-difference

  "Most applications treat $VISUAL as a shell snippet that they append
  the (shell-quoted) file name to, but some treat it as the name of an
  executable which they may or may not search in $PATH. So it's best to
  set VISUAL (and EDITOR) to the full path to an executable (which could
  be a wrapper script if you want e.g. options)." -- Gilles

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT

Copyright 2004 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=head1 HISTORY

Inspired from the CVS prompt-user-for-commit-message functionality.

=cut
