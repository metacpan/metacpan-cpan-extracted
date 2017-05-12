# -*- Perl -*-
#
# Solicits data from an external editor as determined by the EDITOR
# environment variable. Run perldoc(1) on this module for additional
# documentation.
#
# Copyright 2004-2005,2009-2010,2012 Jeremy Mates
#
# This module is free software; you can redistribute it and/or modify it
# under the Artistic license.

package Term::CallEditor;

use strict;
use warnings;

require 5.006;

use vars qw(@EXPORT @ISA $VERSION $errstr);
@EXPORT = qw(solicit);
@ISA    = qw(Exporter);
use Exporter;

use Fcntl qw(:DEFAULT :flock);
use File::Temp qw(tempfile);
use IO::Handle;

use POSIX qw(getpgrp tcgetpgrp);

$VERSION = '0.66';

sub solicit {
  my $message = shift;
  my $params = shift || {};

  unless ( exists $params->{skip_interative} and $params->{skip_interative} ) {
    return unless _is_interactive();
  }

  File::Temp->safe_level( $params->{safe_level} ) if exists $params->{safe_level};
  my ( $tfh, $filename ) = tempfile( UNLINK => 1 );

  unless ( $tfh and $filename ) {
    $errstr = 'no temporary file';
    return;
  }

  if ( exists $params->{binmode_layer}
    and defined $params->{binmode_layer} ) {
    binmode( $tfh, $params->{binmode_layer} );
  } elsif ( exists $params->{BINMODE} and $params->{BINMODE} ) {
    binmode($tfh);
  }

  select( ( select($tfh), $|++ )[0] );

  if ( defined $message ) {
    my $ref = ref $message;
    if ( not $ref ) {
      print $tfh $message;
    } elsif ( $ref eq 'SCALAR' ) {
      print $tfh $$message;
    } elsif ( $ref eq 'ARRAY' ) {
      print $tfh "@$message";
    } elsif ( $ref eq 'GLOB' ) {
      while ( my $line = <$message> ) {
        print $tfh $line;
      }
    } elsif ( UNIVERSAL::can( $message, 'getlines' ) ) {
      print $tfh $message->getlines;
    }
    # Help the bits reach the disk
    $tfh->flush();
    # TODO may need eval or exclude on other platforms
    if ( $^O !~ m/Win32/ ) {
      $tfh->sync();
    }
  }

  my $editor = $ENV{EDITOR} || 'vi';

  # need to unlock for external editor
  flock $tfh, LOCK_UN;

  my $status = system $editor, $filename;
  if ( $status != 0 ) {
    $errstr =
      ( $status != -1 )
      ? "external editor failed: editor=$editor, errstr=$?"
      : "could not launch program: editor=$editor, errstr=$!";
    return;
  }

  # Must reopen filename, as editor could have done a rename() on us, in
  # which case the $tfh is then invalid.
  my $outfh;
  unless ( open( $outfh, '<', $filename ) ) {
    $errstr = "could not reopen tmp file: errstr=$!";
    return;
  }

  return wantarray ? ( $outfh, $filename ) : $outfh;
}

# Perl CookBook code to check whether terminal is interactive
sub _is_interactive {
  my $tty;
  unless ( open $tty, '<', '/dev/tty' ) {
    $errstr = "cannot open /dev/tty: errno=$!";
    return;
  }
  my $tpgrp = tcgetpgrp fileno $tty;
  my $pgrp  = getpgrp();
  close $tty;
  unless ( $tpgrp == $pgrp ) {
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

  print while <$fh>;

=head1 DESCRIPTION

This module calls an external editor with an optional text message via
the C<solicit()> function, then returns any data from this editor as a
file handle. By default, the EDITOR environment variable will be used,
otherwise C<vi>.

C<solicit()> returns a temporary file handle pointing to what was
written in the editor (or also the filename in list context).

=head1 SOLICIT

C<solicit()> as a second argument accepts a number of optional
parameters as a hash reference.

  solicit(
    "\x{8ACB}",
    { skip_interactive => 1,
      binmode_layer => ':utf8'
    }
  );

=over 4

=item B<BINMODE> => I<BOOLEAN>

If true, enables C<binmode> on the filehandle prior to writing the
message to it.

=item B<binmode_layer> => I<binmode layer>

If set, enables C<binmode> on the filehandle prior to writing the
message to it. Useful if one needs to write UTF-8 or some other encoded
data as a message to the EDITOR.

=item B<safe_level> => I<NUMBER>

Set a custom C<safe_level> value for the L<File::Temp> method of that
name. The default C<safe_level> is number 2. Be seeing you.

=item B<skip_interactive> => I<BOOLEAN>

If true, C<solicit> skips making a test to see whether the terminal is
interactive.

=back

On error, C<solicit()> returns C<undef>. Consult
C<$Term::CallEditor::errstr> for details. Note that L<File::Temp> may
throw a fatal error if the C<safe_level> checks fail, so paranoid coders
should wrap the C<solicit> call in an C<eval> block.

=head1 EXAMPLES

See also the C<eg/solicit> script under the module distribution.

=over 4

=item B<Pass in a block of text to the editor>

Use a here doc:

  my $fh = solicit(<< "END_BLARB");

  FOO: This is an example designed to span multiple lines for
  FOO: the sake of an example that span multiple lines.
  END_BLARB

=item B<Support bbedit(1) on Mac OS X>

To use BBEdit as the external editor, create a shell script wrapper to
call bbedit(1), then set this wrapper as the EDITOR environment
variable. The C<-t> option to bbedit(1) can be used to set a custom
title, if desired.

  #!/bin/sh
  exec bbedit -w "$@"

Any editor that requires arguments will require a wrapper like this.

=back

=head1 BUGS

No known bugs.

=head2 Reporting Bugs

Newer versions of this module may be available from CPAN.

If the bug is in the latest version, send a report to the author.
Patches that fix problems or add new features are welcome.

L<http://github.com/thrig/Term-CallEditor>

=head2 Known Issues

This module relies heavily on the Unix terminal, permissions on the
temporary directory (for the L<File::Temp> module C<safe_level> call),
whether C<system()> can actually run the C<EDITOR> environment variable,
and so forth.

=head1 SEE ALSO

vipe(1) of moreutils to use vi(1) in pipes.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT

Copyright 2004-2005,2009-2010,2012 Jeremy Mates

This module is free software; you can redistribute it and/or modify it
under the Artistic License (2.0).

=head1 HISTORY

Inspired from the CVS prompt-user-for-commit-message functionality.

=cut
