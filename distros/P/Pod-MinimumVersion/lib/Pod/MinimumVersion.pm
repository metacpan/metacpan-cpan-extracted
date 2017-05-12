# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Pod-MinimumVersion.

# Pod-MinimumVersion is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Pod-MinimumVersion is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Pod-MinimumVersion.  If not, see <http://www.gnu.org/licenses/>.


package Pod::MinimumVersion;
use 5.004;
use strict;
use List::Util;
use version;
use vars qw($VERSION @CHECKS);

# uncomment this to run the ### lines
#use Smart::Comments;

$VERSION = 50;

sub new {
  my ($class, %self) = @_;
  $self{'want_reports'} ||= 'one_per_version';
  return bless \%self, $class;
}

sub minimum_version {
  my ($self) = @_;
  my $report = $self->minimum_report || return undef;
  return $report->{'version'};
}
sub minimum_report {
  my ($self) = @_;
  if (! exists $self->{'minimum_report'}) {
    $self->{'minimum_report'}
      = List::Util::reduce {$a->{'version'} > $b->{'version'} ? $a : $b}
        $self->reports;
  }
  return $self->{'minimum_report'};
}
sub reports {
  my ($self) = @_;
  $self->analyze;
  return @{$self->{'reports'} || []};
}

sub analyze {
  my ($self) = @_;
  return if $self->{'analyzed'};
  $self->{'analyzed'} = 1;

  ### Pod-MinVer analyze()

  my %checks;
  foreach my $elem (@CHECKS) {
    my ($func, $command, $version) = @$elem;
    next if ($self->{'above_version'} && $version <= $self->{'above_version'});
    push @{$checks{$command}}, $func;
  }
  return if (! %checks);

  require Pod::MinimumVersion::Parser;
  my $parser = Pod::MinimumVersion::Parser->new (pmv    => $self,
                                                 checks => \%checks);
  if (exists $self->{'string'}) {
    $parser->parse_from_string ("$self->{'string'}");
  } elsif (exists $self->{'filehandle'}) {
    $parser->parse_from_filehandle ($self->{'filehandle'});
  } elsif (exists $self->{'filename'}) {
    # stringize to parse_from_file() taking an overloaded object to be a handle
    # ENHANCE-ME: perhaps opening here and parse_from_filehandle() would be
    # a better way to avoid 
    $parser->parse_from_file ("$self->{'filename'}");
  }
}

#------------------------------------------------------------------------------
# 5.004
#
# E<> newly documented in 5.004, but is in pod2man right back to 5.002, so
# don't report that

{
  my $v5004 = version->new('5.004');

  # =for, =begin, =end new in 5.004
  #
  push @CHECKS, [ \&_check_for_begin_end, 'command', $v5004 ];
  my %for_begin_end = (for => 1, begin => 1, end => 1);
  sub _check_for_begin_end {
    my ($self, $command, $text, $para_obj) = @_;
    if ($for_begin_end{$command}) {
      $self->report ('for_begin_end', $v5004, $para_obj, "=$command command");
    }
  }
}

#------------------------------------------------------------------------------
# 5.005

{
  my $v5005 = version->new('5.005');

  # L<display|target> display alternative new in 5.005
  #
  push @CHECKS, [ \&_check_link_display_text, 'interior_sequence', $v5005 ];
  sub _check_link_display_text {
    my ($self, $command, $arg, $seq_obj) = @_;
    if ($command eq 'L' && $arg =~ /\|/) {
      $self->report ('link_display_text', $v5005, $seq_obj,
                     'Display text L<display|target> link');
    }
  }
}

#------------------------------------------------------------------------------
# 5.006

{
  my $v5006 = version->new('5.006');

  push @CHECKS, [ \&_check_double_angles, 'interior_sequence', $v5006 ];
  sub _check_double_angles {
    my ($self, $command, $arg, $seq_obj) = @_;

    if ($seq_obj->left_delimiter =~ /^<</) {
      $self->report ('double_angles', $v5006, $seq_obj,
                     'Double angle brackets C<< foo >>');
    }
  }
}

#------------------------------------------------------------------------------
# 5.008

{
  my $v5008 = version->new('5.008');

  # =head3 and =head4 new in 5.8.0
  push @CHECKS, [ \&_check_head34, 'command', $v5008 ];
  my %head34 = (head3 => 1, head4 => 1);
  sub _check_head34 {
    my ($self, $command, $text, $para_obj) = @_;
    if ($head34{$command}) {
      $self->report ('head34', $v5008, $para_obj, "=$command command");
    }
  }

  # E<sol> and E<verbar> documented in 5.6.0, but Pod::Man only has them in
  # 5.8.0, so rate them as a 5008 feature
  #
  # E<apos> is in Pod::Man of 5.8.0, though not documented explicitly
  #
  push @CHECKS, [ \&_check_E_5008, 'interior_sequence', $v5008 ];
  my %E_5008 = (apos => 1, sol => 1, verbar => 1);
  sub _check_E_5008 {
    my ($self, $command, $arg, $seq_obj) = @_;

    if ($command eq 'E' && $E_5008{$arg}) {
      $self->report ('E_5008', $v5008, $seq_obj, "E<$arg> escape");
    }
  }

  # L<http://...> urls new in 5.8.0
  #
  # In 5.6 and earlier the "/" is interpreted as a section, so from
  # L<http://foo.com/index.html> you get something bad like
  #
  #    the section on "/foo.com/index.html" in the http: manpage
  #
  # Crib note: a "|" display text part is not allowed with a url, according
  # to perlpodspec of perl 5.10.0 under the "Authors wanting to link to a
  # particular (absolute) URL" bullet point.  So no need to watch for that
  # in applying this test.
  #
  push @CHECKS, [ \&_check_link_url, 'interior_sequence', $v5008 ];
  sub _check_link_url {
    my ($self, $command, $arg, $seq_obj) = @_;
    # this regexp as recommended by perlpodspec of perl 5.10.0
    if ($command eq 'L' && $arg =~ m/\A\w+:[^:\s]\S*\z/) {
      $self->report ('link_url', $v5008, $seq_obj,
                     'L<> link to URL');
    }
  }
}

#------------------------------------------------------------------------------
# 5.010

{
  my $v5010 = version->new('5.010');

  # =encoding documented in 5.8.0, but Pod::Man doesn't recognise it until
  # 5.10.0, so rate it as a 5010 feature
  #
  push @CHECKS, [ \&_check_encoding, 'command', $v5010 ];
  sub _check_encoding {
    my ($self, $command, $text, $para_obj) = @_;
    if ($command eq 'encoding') {
      $self->report ('encoding', $v5010, $para_obj, '=encoding command');
    }
  }
}

#------------------------------------------------------------------------------
# 5.012

{
  my $v5012 = version->new('5.012');

  # L<text|url> documented in 5.12.0 where previously explicitly prohibited,
  # rate it as a 5012 feature
  #
  push @CHECKS, [ \&_check_link_url_with_text, 'interior_sequence', $v5012 ];
  sub _check_link_url_with_text {
    my ($self, $command, $arg, $seq_obj) = @_;
    # this regexp adapted from recommendation of perlpodspec from perl 5.10.0
    if ($command eq 'L' && $arg =~ m/\A.*\|\w+:[^:\s]\S*\z/) {
      $self->report ('link_url_with_text', $v5012, $seq_obj,
                     'L<> link with URL and text');
    }
  }
}

#------------------------------------------------------------------------------

sub report {
  my ($self, $name, $version, $pod_obj, $why) = @_;

  if ($self->{'want_reports'} eq 'one_per_check') {
    return if ($self->{'seen'}->{$name}++);
  }
  if ($self->{'want_reports'} eq 'one_per_version') {
    return if ($self->{'seen'}->{$version}++);
  }

  my ($filename, $linenum) = $pod_obj->file_line;
  if (defined $self->{'filename'}) {
    $filename = $self->{'filename'};
  }
  require Pod::MinimumVersion::Report;
  push @{$self->{'reports'}},
    Pod::MinimumVersion::Report->new (filename => $filename,
                                      name     => $name,
                                      linenum  => $linenum,
                                      version  => $version,
                                      why      => $why);
}

1;
__END__

=for stopwords Ryde Pod-MinimumVersion

=head1 NAME

Pod::MinimumVersion - Perl version for POD directives used

=head1 SYNOPSIS

 use Pod::MinimumVersion;
 my $pmv = Pod::MinimumVersion->new (filename => '/some/foo.pl');
 print $pmv->minimum_version,"\n";
 print $pmv->reports;

=head1 DESCRIPTION

C<Pod::MinimumVersion> parses the POD in a Perl script, module, or document,
and reports what version of Perl is required to process the directives in
it with C<pod2man> etc.

=head1 CHECKS

The following POD features are identified.

=over 4

=item *

5.004: new C<=for>, C<=begin> and C<=end>

=item *

5.005: new LE<lt>display text|targetE<gt> style display part

=item *

5.6.0: new CE<lt>E<lt> foo E<gt>E<gt> etc double-angles

=item *

5.8.0: new C<=head3> and C<=head4>

=item *

5.8.0: new LE<lt>http://some.where.comE<gt> URLs.  (Before 5.8 the "/" is a
"section" separator, giving very poor output.)

=item *

5.8.0: new EE<lt>aposE<gt>, EE<lt>solE<gt>, EE<lt>verbarE<gt> chars.
(Documented in 5.6.0, but pod2man doesn't recognise them until 5.8.)

=item *

5.10.0: new C<=encoding> command.  (Documented in 5.8.0, but C<pod2man>
doesn't recognise it until 5.10.)

=item *

5.12.0: new LE<lt>display text|http://some.where.comE<gt> URL with text.
(Before 5.12 the combination of display part and URL was explicitly
disallowed by L<perlpodspec>.)

=back

POD syntax errors are quietly ignored currently.  The intention is only to
check what C<pod2man> would act on but it's probably a good idea to use
C<Pod::Checker> first.

S<C<JE<lt>E<lt> E<gt>E<gt>>> for C<Pod::MultiLang> is recognised and is
allowed for any Perl, including with double-angles.  The assumption is that
if you're writing that then you'll first crunch with the C<Pod::MultiLang>
tools, so it's not important what C<pod2man> thinks of it.

=head1 FUNCTIONS

=over 4

=item C<$pmv = Pod::MinimumVersion-E<gt>new (key =E<gt> value, ...)>

Create and return a new C<Pod::MinimumVersion> object which will analyze a
document.  The document is supplied as one of

    filehandle => $fh,
    string     => 'something',
    filename   => '/my/dir/foo.pod',

For C<filehandle> and C<string>, a C<filename> can be supplied too to give a
name in the reports.  The handle or string is what's actually read.

The C<above_version> option lets you set a Perl version of you have or are
targeting, so reports are only about features above that level.

    above_version => '5.006',

=item C<$version = $pmv-E<gt>minimum_version ()>

=item C<$report = $pmv-E<gt>minimum_report ()>

Return the minimum Perl required for the document in C<$pmv>.

C<minimum_version> returns a C<version> number object (see L<version>).
C<minimum_report> returns a C<Pod::MinimumVersion::Report> object (see
L</REPORT OBJECTS> below).

=item C<@reports = $pmv-E<gt>reports ()>

Return a list of C<Pod::MinimumVersion::Report> objects concerning the
document in C<$pmv>.

These multiple reports let you identify multiple places that a particular
Perl is required.  With the C<above_version> option the reports are only
about things higher than that.

C<minimum_version> and C<minimum_report> are simply the highest Perl among
these multiple reports.

=back

=head1 REPORT OBJECTS

A C<Pod::MinimumVersion::Report> object holds a location within a document
and a reason that a particular Perl is needed at that point.  The hash
fields are

    filename   string
    linenum    integer, with 1 for the first line
    version    version.pm object
    why        string

=over 4

=item C<$str = $report-E<gt>as_string>

Return a formatted string for the report.  Currently this is in GNU
file:line style, simply

    <filename>:<linenum>: <version> due to <why>

=back

=head1 SEE ALSO

L<version>,
L<Pod::MultiLang>,
L<Perl::Critic::Policy::Compatibility::PodMinimumVersion>

L<Perl::MinimumVersion>,
L<Perl::Critic::Policy::Modules::PerlMinimumVersion>,
L<Perl::Critic::Policy::Compatibility::PerlMinimumVersionAndWhy>

=head1 HOME PAGE

http://user42.tuxfamily.org/pod-minimumversion/index.html

=head1 COPYRIGHT

Copyright 2009, 2010, 2011 Kevin Ryde

Pod-MinimumVersion is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Pod-MinimumVersion is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Pod-MinimumVersion.  If not, see <http://www.gnu.org/licenses/>.

=cut
