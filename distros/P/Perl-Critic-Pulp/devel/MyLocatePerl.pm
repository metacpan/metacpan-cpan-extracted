# Copyright 2009, 2010, 2011, 2012, 2013 Kevin Ryde.

# MyLocatePerl.pm is shared by various distributions.
#
# MyLocatePerl.pm is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# MyLocatePerl.pm is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.

package MyLocatePerl;
use 5.006;
use strict;
use warnings;
use base 'File::Locate::Iterator';
use FindBin;
use File::Slurp 'slurp';
use IO::File;
use IO::Uncompress::AnyInflate;
use MyUniqByInode;
use MyUniqByMD5;

# uncomment this to run the ### lines
# use Smart::Comments;


# glob => '/usr/share/perl5/Debconf/FrontEnd/*'

my $compressed_re = qr/\.gz$/;

sub new {
  my ($class, %options) = @_;

  my @suffixes = ('t','pm','pl','PL');
  if (delete $options{'include_pod'}) {
    push @suffixes, 'pod';
  }
  if (delete $options{'exclude_t'}) {
    @suffixes = grep {$_ ne 't'} @suffixes;
  }
  if (delete $options{'only_t'}) {
    @suffixes = ('t');
  }
  my $suffixes = join('|',@suffixes);
  my $suffixes_re = qr/\.($suffixes)($compressed_re)?$/;
  ### $suffixes
  ### $suffixes_re

  my $locate_regexp = $suffixes_re;
  if (defined (my $under_directory = $options{'under_directory'})) {
    unless ($under_directory =~ m{/$}) {
      $under_directory .= '/';
    }
    $locate_regexp = qr/^\Q$under_directory\E.*$suffixes_re/;
  }
  ### $locate_regexp

  my $self = $class->SUPER::new (
                                 # globs => ['/bin/*',
                                 #           '/usr/bin/*',
                                 #           '/usr/local/bin/*',
                                 #           '/usr/local/bin2/*'],
                                 regexp => $locate_regexp,
                                 %options);
  $self->{'uniq_ino'} = MyUniqByInode->new;
  $self->{'uniq_md5'} = MyUniqByMD5->new;
  $self->{'my_suffixes_re'} = $suffixes_re;
  return $self;
}

sub next {
  my ($self) = @_;
  unless ($self->{'done_script'}) {
    $self->{'done_script'} = 1;
    my $filename = File::Spec->catfile ($FindBin::Bin, $FindBin::Script);
    ### $filename
    my $content = slurp($filename);
    return ($filename, $content);
  }
  for (;;) {
    defined(my $filename = $self->SUPER::next) or return;
    ### consider: $filename

    next if $filename =~ m{/blib/};
    next if $filename =~ m{/DateTime/TimeZone/};  # data .pm's
    next if $filename =~ m{/Date/Manip/TZ/};      # data .pm's
    next if $filename =~ m{/Date/Manip/Offset/};  # data .pm's
    next if $filename =~ m{/Text/Unidecode/};     # data .pm's
    next if $filename =~ m{/junk.pl};

    my $io;
    if ($filename =~ $compressed_re) {
      $io = IO::Uncompress::AnyInflate->new ($filename);
    } else {
      $io = IO::File->new ($filename, 'r');
    }
    $io or next;
    $self->{'uniq_ino'}->uniq($filename) or next;  # or $io ???

    my $content = _slurp_if_perl ($self, $filename, $io);
    ### content: $content && "ok"
    next if ! defined $content;

    $self->{'uniq_md5'}->uniq_str($content) or next;

    ### return: $filename
    return ($filename, $content);
  }
}

sub _slurp_if_perl {
  my ($self, $filename, $io) = @_;
  ### slurp: "$io"

  my $first = '';
  if ($filename !~ $self->{'my_suffixes_re'}) {
    # file in /bin etc must have #!.../perl
    $io->read($first, 128) or return;
    ### first part: $first

    if ($first !~ m{^#!([^\r\n]*/|[ \t]*)perl[ \t\r\n]}) {
      ### no #!perl
      return;
    }
  }

  my $rest = do { local $/; $io->getline }; # slurp
  if (! defined $rest) {
    ### read error: $!
    return;
  }
  return $first . $rest;
}
1;
__END__
