package Path::ExpandTilde;

use strict;
use warnings;
use Carp 'croak';
use Exporter;
use File::Glob ':glob';
use File::Spec;

our $VERSION = '0.003';

our @ISA = 'Exporter';
our @EXPORT = 'expand_tilde';

use constant BSD_GLOB_FLAGS => GLOB_NOCHECK | GLOB_QUOTE | GLOB_TILDE | GLOB_ERR
  # add GLOB_NOCASE as in File::Glob
  | ($^O =~ m/\A(?:MSWin32|VMS|os2|dos|riscos)\z/ ? GLOB_NOCASE : 0);

# File::Glob did not try %USERPROFILE% (set in Windows NT derivatives) for ~ before 5.16
use constant WINDOWS_USERPROFILE => $^O eq 'MSWin32' && $] < 5.016;

# File::Glob does not have bsd_glob on 5.6.0, but its glob was the same then
BEGIN { *bsd_glob = \&File::Glob::glob if $] == 5.006 }

sub expand_tilde {
  my ($dir) = @_;
  return undef unless defined $dir;
  return File::Spec->canonpath($dir) unless $dir =~ m/^~/;
  # parse path into segments
  my ($volume, $directories, $file) = File::Spec->splitpath($dir, 1);
  my @parts = File::Spec->splitdir($directories);
  my $first = shift @parts;
  return File::Spec->canonpath($dir) unless defined $first;
  # expand first segment
  my $expanded;
  if (WINDOWS_USERPROFILE and $first eq '~') {
    $expanded = $ENV{HOME} || $ENV{USERPROFILE};
  } else {
    (my $pattern = $first) =~ s/([\\*?{[])/\\$1/g;
    ($expanded) = bsd_glob($pattern, BSD_GLOB_FLAGS);
    croak "Failed to expand $first: $!" if GLOB_ERROR;
  }
  return File::Spec->canonpath($dir) if !defined $expanded or $expanded eq $first;
  # replace first segment with new path
  ($volume, $directories) = File::Spec->splitpath($expanded, 1);
  $directories = File::Spec->catdir($directories, @parts);
  return File::Spec->catpath($volume, $directories, $file);
}

1;

=head1 NAME

Path::ExpandTilde - Expand tilde (~) to homedir in file paths

=head1 SYNOPSIS

  use Path::ExpandTilde;
  my $homedir = expand_tilde('~');
  my $bashrc = expand_tilde('~/.bashrc');
  my $pg_home = expand_tilde('~postgres');

=head1 DESCRIPTION

This module uses C<bsd_glob> from L<File::Glob> to portably expand a leading
tilde (C<~>) in a file path into the current or specified user's home
directory. No other L<glob metacharacters|File::Glob/"META CHARACTERS"> are
expanded.

=head1 FUNCTIONS

=head2 expand_tilde

  my $new_path = expand_tilde($path);

Exported by default. If the path starts with C<~>, expands that to the current
user's home directory. If the path starts with C<< ~I<username> >>, expands
that to the specified user's home directory. If the user doesn't exist, no
expansion is done. The returned path is canonicalized as by
L<File::Spec/"canonpath"> either way.

=head1 NOTES

The algorithm should be portable to most operating systems supported by Perl,
though the home directory may not be found by C<bsd_glob> on some.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<File::Path::Expand>, L<File::HomeDir>, L<File::HomeDir::Tiny>
