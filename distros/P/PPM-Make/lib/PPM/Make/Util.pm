package PPM::Make::Util;
use strict;
use warnings;
use base qw(Exporter);
use File::Basename;
use Safe;
use XML::Parser;
use Digest::MD5;
use Config;
use CPAN::DistnameInfo;
use File::Spec;
use PPM::Make::Config qw(WIN32 HAS_CPAN ACTIVEPERL);
use HTTP::Tiny;
use HTML::Entities;

=head1 NAME

  PPM::Make::Util - Utility functions for PPM::Make

=head1 SYNOPSIS

  use PPM::Make::Util qw(:all);

=head1 DESCRIPTION

This module contains a number of utility functions used by PPM::Make.

=over 2

=cut

our $VERSION = '0.9904';

our (@EXPORT_OK, %EXPORT_TAGS, $protocol, $ext, $src_dir, $build_dir,
     @url_list, $ERROR);
$protocol = qr{^(http|ftp)://};
$ext = qr{\.(tar\.gz|tar\.bz2|tgz|tar\.Z|zip)};
@url_list = url_list();

my @exports = qw(load_cs verifyMD5 verifySHA256 parse_version $ERROR
                 is_core is_ap_core url_list
                 parse_ppd parse_abstract
                 ppd2cpan_version cpan2ppd_version
                 file_to_dist cpan_file fix_path
                 mirror encode_non_ascii_chars
                 $src_dir $build_dir @url_list);

%EXPORT_TAGS = (all => [@exports]);
@EXPORT_OK = (@exports);

my %ap_core = map {$_ => 1} qw(
                               Archive-Tar
                               Archive-Zip
                               Compress-Zlib
                               Data-Dump
                               Digest-HMAC
                               Digest-MD2
                               Digest-MD4
                               Digest-SHA1
                               File-CounterFile
                               Font-AFM
                               HTML-Parser
                               HTML-Tagset
                               HTML-Tree
                               IO-String
                               IO-Zlib
                               libwin32
                               libwww-perl
                               MD5
                               MIME-Base64-Scripts
                               SOAP-Lite
                               Term-ReadLine-Perl
                               TermReadKey
                               Text-Autoformat
                               Text-Reform
                               Tk
                               Unicode-String
                               URI
                               XML-Parser
                               XML-Simple  );

if (WIN32 and ACTIVEPERL and eval { Win32::BuildNumber() > 818 }) {
  $ap_core{'DBI'}++; $ap_core{'DBD-SQLite'}++;
}
src_and_build();

my %dists;

=item fix_path

Ensures a path is a Unix-type path, with no spaces.

  my $path = 'C:\Program Files\';
  my $unix_version = fix_path($path);

=cut

sub fix_path {
  my $path = shift;
  $path = Win32::GetShortPathName($path);
  $path =~ s!\\!/!g;
  $path =~ s!/$!!;
  return $path;
}

=item load_cs

Loads a CHECKSUMS file into $cksum
(adapted from the MD5 check of CPAN.pm)

  my $cksum = load_cs('CHECKSUMS');

=cut

sub load_cs {
  my $cs = shift;
  open(my $fh, '<', $cs);
  unless ($fh) {
    $ERROR = qq{Could not open "$cs": $!};
    return;
  }
  local($/);
  my $eval = <$fh>;
  close $fh;
  $eval =~ s/\015?\012/\n/g;
  my $comp = Safe->new();
  my $cksum = $comp->reval($eval);
  if ($@) {
    $ERROR = qq{eval of "$cs" failed: $@};
    return;
  }
  return $cksum;
}

=item verifyMD5

Verify a CHECKSUM for a $file

   my $ok = verifyMD5($cksum, $file);
   print "$file checked out OK" if $ok;

=cut

sub verifyMD5 {
  my ($cksum, $file) = @_;
  my ($is, $should);
  open (my $fh, '<', $file);
  unless ($fh) {
    $ERROR = qq{Cannot open "$file": $!};
    return;
  }
  binmode($fh);
  unless ($is = Digest::MD5->new->addfile($fh)->hexdigest) {
    $ERROR = qq{Could not compute checksum for "$file": $!};
    close $fh;
    return;
  }
  close $fh;
  if ($should = $cksum->{$file}->{md5}) {
    my $test = ($is eq $should);
    if (!$test && ($should = $cksum->{$file}->{'md5-ungz'})) {
      $test = ($is eq $should);
    }
    printf qq{  Checksum for "$file" is %s\n}, 
      ($test) ? 'OK.' : 'NOT OK.';
    return $test;
  }
  else {
    $ERROR = qq{Checksum data for "$file" not present.};
    return;
  }
}

=item verifySHA256

Verify a CHECKSUM for a $file

   my $ok = verifySHA256($cksum, $file);
   print "$file checked out OK" if $ok;

=cut

sub verifySHA256 {
  my ($cksum, $file) = @_;
  my ($is, $should);
  open (my $fh, '<', $file);
  unless ($fh) {
    $ERROR = qq{Cannot open "$file": $!};
    return;
  }
  require Digest::SHA;
  binmode($fh);
  unless ($is = Digest::SHA->new(256)->addfile($fh)->hexdigest) {
    $ERROR = qq{Could not compute checksum for "$file": $!};
    close $fh;
    return;
  }
  close $fh;
  if ($should = $cksum->{$file}->{sha256}) {
    my $test = ($is eq $should);
    if (!$test && ($should = $cksum->{$file}->{'sha256-ungz'})) {
      $test = ($is eq $should);
    }
    printf qq{  SHA256-Checksum for "$file" is %s\n},
      ($test) ? 'OK.' : 'NOT OK.';
    return $test;
  }
  else {
    $ERROR = qq{Checksum data for "$file" not present.};
    return;
  }
}

=item is_core

Tests to see if a module is part of the core, based on
whether or not the file is found within a I<site> type
of directory.

  my $is_core = is_core('Net::FTP');
  print "Net::FTP is a core module" if $is_core;

=cut

sub is_core {
  my $m = shift;
  return unless $m;
  $m =~ s!::|-!/!g;
  $m .= '.pm';
  my $is_core = (-e File::Spec->catfile($Config{privlibexp}, $m)) ? 1 : 0;
  return $is_core;
}

=item is_ap_core

Tests to see if a package is part of the ActivePerl core (at
least for recent ActivePerl versions).

  my $is_ap_core = is_ap_core('libwin32');
  print "libwin32 is a core package" if $is_ap_core;

=cut

sub is_ap_core {
  my $p = shift;
  return unless defined $p;
  return defined $ap_core{$p} ? 1 : 0;
}

=item file_to_dist

In scalar context, returns a CPAN distribution name I<filename> based
on an input file I<A/AB/ABC/filename-1.23.tar.gz>:

  my $file = 'A/AB/ABC/defg-1.23.tar.gz';
  my $dist = file_to_dist($file);

In a list context, returns both the distribution name I<filename>
and the version number I<1.23>:

  my $file = 'A/AB/ABC/defg-1.23.tar.gz';
  my ($dist, $version) = file_to_dist($cpan_file);


=cut

sub file_to_dist {
  my $cpan_file = shift;
  return unless $cpan_file;
  my $d = CPAN::DistnameInfo->new($cpan_file);
  my ($dist, $version) = ($d->dist, $d->version);
  unless ($dist and $version) {
      $ERROR = qq{Could not find distribution name from $cpan_file.};
      return;
  }
  return wantarray? ($dist, $version) : $dist;
}

=item ppd2cpan_version

Converts a ppd-type of version string (eg, I<1,23,0,0>) into a ppd one
of the form I<1.23>:

  my $s = "1,23,0,0";
  my $v = ppd2cpan_version($v);

=cut

sub ppd2cpan_version {
  local $_ = shift;
  s/(,0)*$//;
  tr/,/./;
  return $_;
}

=item cpan2ppd_version

Converts a cpan-type of version string (eg, I<1.23>) into a ppd one
of the form I<1,23,0,0>:

  my $v = 1.23;
  my $s = cpan2ppd_version($v);

=cut

sub cpan2ppd_version {
  local $_ = shift;
  return join ',', (split (/\./, $_), (0)x4)[0..3];
}


=item parse_ppd

Parse a I<ppd> file or a string.

  my $ppd = 'package.ppd';
  my $d = parse_ppd($ppd);
  print $d->{ABSTRACT};
  print $d->{OS}->{NAME};

  my $e = parse_ppd($ppd, 'MSWin32-x86-multi-thread');
  print $e->{ABSTRACT};

This routine takes a required argument of a I<ppd> file containing
a I<.ppd> extension or a string and,
optionally, an ARCHITECTURE name to restrict the results to.
It returns a data structure containing the information of 
the ppd file or string:

    $d->{SOFTPKG}->{NAME}
    $d->{SOFTPKG}->{VERSION}
    $d->{TITLE}
    $d->{AUTHOR}
    $d->{ABSTRACT}
    $d->{PROVIDE}
    $d->{DEPENDENCY}
    $d->{REQUIRE}
    $d->{OS}->{NAME}
    $d->{ARCHITECTURE}->{NAME}
    $d->{CODEBASE}->{HREF}
    $d->{INSTALL}->{EXEC}
    $d->{INSTALL}->{SCRIPT}
    $d->{INSTALL}->{HREF}

The I<PROVIDE>, I<REQUIRE> and I<DEPENDENDENCY> tags are array references
containing lists of, respectively, the prerequisites required and 
the modules supplied by the package, with keys of I<NAME> and
I<VERSION>.

If there is more than one I<IMPLEMENTATION> section in the
ppd file, all the results except for the I<SOFTPKG> elements and
I<TITLE>, I<AUTHOR>, and I<ABSTRACT> will be placed in 
a I<$d-E<gt>{IMPLENTATION}> array
reference. If an optional second argument is passed to 
I<parse_ppd($file, $arch)>, this will filter out all implementation
sections except for the specified I<ARCHITECTURE> given by I<$arch>.

=cut

my $i;

sub parse_ppd {
  my $file = shift;
  my $arch = shift;
  my $is_a_file = ($file =~ /\.ppd/);
  if ($is_a_file) {
    unless (-e $file) {
      $ERROR = qq{$file not found.};
      return;
    }
  }
  my $p = XML::Parser->new(Style => 'Subs',
                           Handlers => {Char => \&ppd_char,
                                        Start => \&ppd_start,
                                        End => \&ppd_end,
                                        Init => \&ppd_init,
                                        Final => \&ppd_final,
                                       },
                          );
  my $d = $is_a_file ? $p->parsefile($file) : $p->parse($file);
  my $implem = $d->{IMPLEMENTATION};
  my $size = scalar @$implem;
  if ($size == 1) {
    $d->{PROVIDE} = $implem->[0]->{PROVIDE} || [];
    $d->{DEPENDENCY} = $implem->[0]->{DEPENDENCY} || [];
    $d->{REQUIRE} = $implem->[0]->{DEPENDENCY} || [];
    $d->{OS}->{NAME} = $implem->[0]->{OS}->{NAME} || '';
    $d->{ARCHITECTURE}->{NAME} = $implem->[0]->{ARCHITECTURE}->{NAME} || '';
    $d->{CODEBASE}->{HREF} = $implem->[0]->{CODEBASE}->{HREF};
    $d->{INSTALL}->{EXEC} = $implem->[0]->{INSTALL}->{EXEC};
    $d->{INSTALL}->{SCRIPT} = $implem->[0]->{INSTALL}->{SCRIPT};
    $d->{INSTALL}->{HREF} = $implem->[0]->{INSTALL}->{HREF};
  }
  elsif (defined $arch) {
    my $flag = 0;
    my $i;
    for ($i=0; $i<$size; $i++) {
      if ($implem->[$i]->{ARCHITECTURE}->{NAME} eq $arch) {
        $flag++;
        last;
      }
    }
    return unless $flag;
    $d->{PROVIDE} = $implem->[$i]->{PROVIDE} || [];
    $d->{DEPENDENCY} = $implem->[$i]->{DEPENDENCY} || [];
    $d->{REQUIRE} = $implem->[$i]->{DEPENDENCY} || [];
    $d->{OS}->{NAME} = $implem->[$i]->{OS}->{NAME} || '';
    $d->{ARCHITECTURE}->{NAME} = $implem->[$i]->{ARCHITECTURE}->{NAME} || '';
    $d->{CODEBASE}->{HREF} = $implem->[$i]->{CODEBASE}->{HREF};
    $d->{INSTALL}->{EXEC} = $implem->[$i]->{INSTALL}->{EXEC};
    $d->{INSTALL}->{SCRIPT} = $implem->[$i]->{INSTALL}->{SCRIPT};
    $d->{INSTALL}->{HREF} = $implem->[$i]->{INSTALL}->{HREF};
  }
  return $d;
}

sub ppd_init {
  my $self = shift;
  $i = 0;
  $self->{_mydata} = {
                      SOFTPKG => {NAME => '', VERSION => ''},
                      TITLE => '',
                      AUTHOR => '',
                      ABSTRACT => '',
                      PROVIDE => [],
                      IMPLEMENTATION => [],
                      OS => {NAME => ''},
                      ARCHITECTURE => {NAME => ''},
                      CODEBASE => {HREF => ''},
                      DEPENDENCY => [],
                      REQUIRE => [],
                      INSTALL => {EXEC => '', SCRIPT => '', HREF => ''},
                      wanted => {TITLE => 1, ABSTRACT => 1, AUTHOR => 1},
                      _current => '',
                     };
}

sub ppd_start {
  my ($self, $tag, %attrs) = @_;
  my $internal = $self->{_mydata};
  $internal->{_current} = $tag;
 SWITCH: {
    ($tag eq 'SOFTPKG') and do {
      $internal->{SOFTPKG}->{NAME} = $attrs{NAME};
      $internal->{SOFTPKG}->{VERSION} = $attrs{VERSION};
      last SWITCH;
    };
    ($tag eq 'PROVIDE') and do {
      my $name = $attrs{NAME};
      my $version = $attrs{VERSION};
      if ($version) {
        push @{$internal->{IMPLEMENTATION}->[$i]->{PROVIDE}},
          {NAME => $name, VERSION => $version};
      }
      else {
        push @{$internal->{IMPLEMENTATION}->[$i]->{PROVIDE}},
          {NAME => $name};        
      }
      last SWITCH;
    };
    ($tag eq 'CODEBASE') and do {
      $internal->{IMPLEMENTATION}->[$i]->{CODEBASE}->{HREF} =
        $attrs{HREF};
      last SWITCH;
    };
    ($tag eq 'OS') and do {
      $internal->{IMPLEMENTATION}->[$i]->{OS}->{NAME} =
        $attrs{NAME};
      last SWITCH;
    };
    ($tag eq 'ARCHITECTURE') and do {
      $internal->{IMPLEMENTATION}->[$i]->{ARCHITECTURE}->{NAME} =
        $attrs{NAME};
      last SWITCH;
    };
    ($tag eq 'INSTALL') and do {
      $internal->{IMPLEMENTATION}->[$i]->{INSTALL}->{EXEC} =
        $attrs{EXEC};
      $internal->{IMPLEMENTATION}->[$i]->{INSTALL}->{HREF} =
        $attrs{HREF};
      last SWITCH;
    };
    ($tag eq 'DEPENDENCY') and do {
      push @{$internal->{IMPLEMENTATION}->[$i]->{DEPENDENCY}},
        {NAME => $attrs{NAME}, VERSION => $attrs{VERSION}};
      last SWITCH;
    };
    ($tag eq 'REQUIRE') and do {
      push @{$internal->{IMPLEMENTATION}->[$i]->{REQUIRE}},
        {NAME => $attrs{NAME}, VERSION => $attrs{VERSION}};
      last SWITCH;
    };
  }
}

sub ppd_char {
  my ($self, $string) = @_;
  my $internal = $self->{_mydata};
  my $tag = $internal->{_current};
  if ($tag and $internal->{wanted}->{$tag}) {
    $internal->{$tag} .= $string;
  }
  elsif ($tag and $tag eq 'INSTALL') {
    $internal->{IMPLEMENTATION}->[$i]->{INSTALL}->{SCRIPT} .= $string;
  }
  else {
  }
}

sub ppd_end {
  my ($self, $tag) = @_;
  $i++ if ($tag eq 'IMPLEMENTATION');
  delete $self->{_mydata}->{_current};
}

sub ppd_final {
  my $self = shift;
  return $self->{_mydata};
}

=item src_and_build

Returns the source and build directories used with
CPAN.pm, if present. If not, returns those used with PPM,
if those are present. If neither of these are available,
returns the system temp directory.

  my ($src_dir, $build_dir)= src_and_build;

=cut

sub src_and_build {
  return if ($src_dir and $build_dir);
 SWITCH: {
    HAS_CPAN and do {
      $src_dir = $CPAN::Config->{keep_source_where};
      $build_dir = $CPAN::Config->{build_dir};
      last SWITCH if ($src_dir and $build_dir);
    };
    $src_dir = File::Spec->tmpdir() || '.';
    $build_dir = $src_dir;
  }
}

=item parse_version

Extracts a version string from a module file.

  my $version = parse_version('C:/Perl/lib/CPAN.pm');

=cut

# from ExtUtils::MM_Unix
sub parse_version {
  my $parsefile = shift;
  return unless -e $parsefile;
  my $version;
  local $/ = "\n";
  my $fh;
  unless (open($fh, '<', $parsefile)) {
    $ERROR = "Could not open '$parsefile': $!";
    return;
  }
  my $inpod = 0;
  while (<$fh>) {
    $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
    next if $inpod || /^\s*\#/;
    chop;
    # next unless /\$(([\w\:\']*)\bVERSION)\b.*\=/;
    next unless /([\$*])(([\w\:\']*)\bVERSION)\b.*\=/;
    my $eval = qq{
                  package # hide from PAUSE
                    ExtUtils::MakeMaker::_version;
                  no strict;
                  
                  local $1$2;
                  \$$2=undef; do {
                    $_;
                    return \$$2;
                  };
                 };
    local $^W = 0;
    $version = eval($eval);
    warn "Could not eval '$eval' in $parsefile: $@" if $@;
    last;
  }
  close $fh;
  return $version;
}

=item parse_abstract

Attempt to obtain an abstract from a module file.

  my $package = 'CPAN';
  my $file = 'C:/Perl/lib/CPAN.pm';
  my $abstract = parse_abstract($package, $file);

=cut

sub parse_abstract {
  my ($package, $file) = @_;
  my $basename = basename($file, qr/\.\w+$/);
  (my $stripped = $basename) =~ s!\.\w+$!!;
  (my $trans = $package) =~ s!-!::!g;
  my $result;
  my $inpod = 0;
  open(my $fh, '<', $file) or die "Couldn't open $file: $!";
  while (<$fh>) {
    $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
    next if !$inpod;
    chop;
    next unless /^\s*($package|$basename|$stripped|$trans)\s+--*\s+(.*)/;
    $result = $2;
    last;
  }
  close($fh);
  return unless $result;
  chomp($result);
  return $result;
}

=item cpan_file {

Given a file of the form C<file.tar.gz> and a CPAN id
of the form <ABCDEFG>, will return the CPAN file
C<A/AB/ABCDEFG/file.tar.gz>.

  my $cpanid = 'GBARR';
  my $file = 'libnet-1.23.tar.gz';
  my $cpan_file = cpan_file($cpanid, $file);

=cut

sub cpan_file {
  my ($cpanid, $file) = @_;
  return $file if $file =~ m!/!;
  (my $cpan_loc = $cpanid) =~ s{^(\w)(\w)(.*)}{$1/$1$2/$1$2$3};
  return qq{$cpan_loc/$file};
}

=item url_list

Gets a list of CPAN mirrors, incorporating any from CPAN.pm.

  my @list = url_list();

=cut

sub url_list {
  my @urls;
  if (HAS_CPAN and defined $CPAN::Config->{urllist} and
      ref($CPAN::Config->{urllist}) eq 'ARRAY') {
    push @urls, @{$CPAN::Config->{urllist}};
  }
  push @urls, 'ftp://ftp.cpan.org', 'http://www.cpan.org';
  return @urls;
}

=item mirror

Gets a file from a remote source and store it to a local file.

  my $success = getstore($url, $file);

=cut

sub mirror {
  my ($url, $file) = @_;
  my $ua = HTTP::Tiny->new(agent => "PPM-Make/$VERSION");
  my $res = $ua->mirror($url, $file);
  $res->{success} ? 1 : 0;
}

=item encode_non_ascii_chars

Encodes non-ascii characters.

  my $encoded = encode_non_ascii_chars($non_ascii_string);

=cut

sub encode_non_ascii_chars {
  my $string = shift;
  HTML::Entities::encode_entities_numeric($string, '^\n\x20-\x25\x26-\x7e');
}

1;

__END__

=back

=head1 COPYRIGHT

This program is copyright, 2003, 2006 by 
Randy Kobes <r.kobes@uwinnipeg.ca>.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<PPM>.

=cut

