package Parse::Distname;

use strict;
use warnings;
use Carp;
use Exporter 5.57 'import';

our $VERSION = '0.04';
our @EXPORT_OK = qw/parse_distname/;

our $SUFFRE = qr/\.(?:tgz|tbz|tar[\._-]gz|tar\.bz2|tar\.Z|zip)$/;

sub parse_distname {
  my $distname = shift;

  my %res;

  # Stringify first, in case $distname is some kind of an object
  my $path = "$distname";
  $res{arg} = $path;

  # Small path normalization
  $path =~ s!\\!/!g;
  $path =~ s!//+!/!g;
  $path =~ s!/\./!/!g;

  $path =~ s!^(.*?/)?(?:authors/)?id/!!;

  # Get pause_id
  my ($pause_id, $author_dir);

  # A/AU/AUTHOR/Dist-Version.ext
  if ($path =~ s!^(([A-Z])/(\2[A-Z0-9])/(\3[A-Z0-9-]{0,7})/)!!) {
    $author_dir = $1;
    $pause_id   = $4;
  }
  # AUTHOR/Dist-Version.ext as a handy shortcut (esp. for testing)
  elsif ($path =~ s!^([A-Z][A-Z0-9][A-Z0-9-]{0,7})/!!) {
    $pause_id = $1;
    $author_dir = join '/',
      substr($pause_id, 0, 1),
      substr($pause_id, 0, 2),
      $pause_id,
      "";
  }
  # A little backward incompatibility here (id/A/AU/AUTHOR etc)
  # but I believe nobody cares.
  else {
    $pause_id = "";

    # Assume it's a local distribution
    $author_dir = "L/LO/LOCAL/";
  }
  $res{pause_id}  = $pause_id;
  $res{cpan_path} = "$author_dir$path";

  # Now the path should be (subdir/)dist-version
  if ($path =~ s!^(.+/)!!) {
    $res{subdir} = $1;

    # Typical Perl6 distributions are located under Perl6/ directory
    $res{perl6} = 1 if $res{subdir} =~ m!^Perl6/!;
  }

  # PAUSE allows only a few extensions ($PAUSE::dist::SUFFQR + zip)
  $path =~ s/($SUFFRE)//i or return;
  $res{extension} = $1;

  $res{name_and_version} = $path;

  # Parse dist-version
  my $info = _parse_distv($path);
  $res{$_} = $info->{$_} for keys %$info;

  return \%res;
}

sub _parse_distv {
  my $distv = shift;

  my %res;

  # Remove potential -withoutworldwriteables suffix
  $distv =~ s/-withoutworldwriteables$//;

  my $trial;
  # Remove TRIAL (PAUSE::dist::isa_dev_version seems to be
  # a little too strict)
  if ($distv =~ s/([_\-])(TRIAL(?:[0-9]*|[_.\-].+))$//) {
    $trial = [$1, $2];
  }

  # Remove RC for perl as well
  my $rc;
  if ($distv =~ /^perl/ and $distv =~ s/\-(RC[0-9]*)$//) {
    $rc = $1;
  }

  my $version;
  # Usually a version, which starts with a number (or a 'v'-number),
  # is the last part of the name.
  if ($distv =~ s/\-((?:[vV][0-9]|[0-9.])[^-]*)$//) {
    $version = $1;
  }
  # However, there may be a trailing part.
  elsif ($distv =~ s/\-((?:[vV][0-9]|[0-9.])(?![A-Z]).*?)$//) {
    $version = $1;

    # Special case
    if ($distv eq 'perl' and $version !~ /\./) {
      $distv = "$distv-$version";
      $version = undef;
    }
  }

  # If the name still contains a dot between numbers,
  # it's probably a part of the version.
  if ($distv =~ s/([_\.-]?)([vV]?[0-9]*\.[0-9]+.*)$//) {
    my $separator = $1 || '';
    $version = defined $version ? "$2-$version" : $2;
    $version =~ s/^\.//;

    # Special case
    if ($distv =~ s/_v$//) {
      $version = "v$separator$version";
    }
  }

  # If we still don't have a version and the name has a tailing number
  # with a small-letter prefix (other than 'v')
  if (!defined $version and $distv =~ s/\-([a-z]+[0-9][0-9_]*)$//) {
    $version = $1;
  }

  # If we still don't have a version, and the name doesn't have a hyphen,
  # and it has a tailing number... (and an occasional alpha/beta marker)
  # (and the number is not a part of a few proper names)
  if (!defined $version and $distv !~ /\-(?:S3|MSWin32|OS2|(?:[A-Za-z][A-Za-z0-9_]*)?SSL3)$/i and $distv =~ s/([_\.]?)([vV]?[0-9_]+[ab]?)$//) {
    my $separator = $1;
    $version = $2;

    # Special case
    if (!$separator and $distv =~ s/_([a-z])$//) {
      $version = "$1$version";
    }
  }

  # Special case that should be put at the end
  if (!defined $version and $distv =~ s/\-undef$//) {
    $version = undef;
  }

  my $dist = $distv;

  my $dev;
  if ($dist eq 'perl') {
    if ($version =~ /\d\.(\d+)(?:\D(\d+))?/) {
      $dev = 1 if ($1 > 6 and $1 & 1) or ($2 and $2 >= 50);
    }
    if ($rc) {
      $version = "$version-$rc";
      $dev = 1;
    }
  }
  elsif (($version and $version =~ /\d\.\d+_\d/) or $trial) {
    $dev = 1;
  }

  if ($trial) {
    $version = defined $version ? "$version$trial->[0]$trial->[1]" : $trial->[1];
    $dev = 1;
  }

  # Normalize the Dist.pm-1.23 convention which CGI.pm and
  # a few others use.
  $dist =~ s/\.pm$//;

  # Remove apparent remnants that can't be a part of a package name
  $dist =~ s/[\-\.]+$//;

  my $version_number;
  if (defined $version) {
    if ($version =~ /^([vV]?[0-9._]+)(?:\-|$)/) {
      $version_number = $1;
      $version_number =~ s/[\._]+$//;
    }
  }

  return {
    name => $dist,
    version => $version,
    version_number => $version_number,
    is_dev => $dev,
  };
}

# for compatibility with CPAN::DistnameInfo

sub new {
  my ($class, $distname) = @_;
  my $info = parse_distname($distname) || {};
  bless $info, $class;
}

sub distname_info {
  my $distname = shift;
  my $info = parse_distname($distname);
  @$info{qw/name version is_dev/};
}

sub dist      { shift->{name} }
sub version   { shift->{version} }
sub maturity  { shift->{is_dev} ? 'developer' : 'released' }
sub filename  {
  my $self = shift;
  join "", grep defined $_, @$self{qw/subdir name_and_version extension/};
}
sub cpanid    { shift->{pause_id} }
sub distvname { shift->{name_and_version} }
sub extension { substr(shift->{extension}, 1) }
sub pathname  { shift->{arg} }

sub properties {
  my $self = shift;
  my @methods = qw/
    dist version maturity filename
    cpanid distvname extension pathname
  /;
  my %properties;
  for my $method (@methods) {
    $properties{$method} = $self->$method;
  }
  %properties;
}

# extra accessors

sub is_perl6       { shift->{is_perl6} }
sub version_number { shift->{version_number} }

1;

__END__

=encoding utf-8

=head1 NAME

Parse::Distname - parse a distribution name

=head1 SYNOPSIS

    use Parse::Distname 'parse_distname';
    my $info = parse_distname('ISHIGAKI/Parse-Distname-0.01.tar.gz');
    
    # for compatibility with CPAN::DistnameInfo
    my $info_obj = Parse::Distname->new('ISHIGAKI/Parse-Distname-0.01.tar.gz');
    say $info_obj->dist; # Parse-Distname

=head1 DESCRIPTION

Parse::Distname is yet another distribution name parser. It works
almost the same as L<CPAN::DistnameInfo>, but Parse::Distname takes
a different approach. It tries to extract a version part of a
distribution and treat the rest as a distribution name, contrary to
CPAN::DistnameInfo which tries to define a name part and treat
the rest as a version.

Because of this difference, when Parse::Distname parses a weird
distribution name such as "AUTHOR/v1.0.tar.gz", it says the name
is empty and the version is "v1.0", while CPAN::DistnameInfo
says the name is "v" and the version is "1.0". See test files
in this distribution if you need more details. As of this writing,
Parse::Distname returns a different result for about 200+
distributions among about 320000 BackPan distributions.

=head1 FUNCTION

Parse::Distname exports one function C<parse_distname> if requested.
It returns a hash reference, with the following keys as of this
writing:

=over 4

=item arg

The path you passed to the function. If what you passed is some kind
of an object (of Path::Tiny, for example), it's stringified.

=item cpan_path

A relative path to the distribution, whose base directory is
assumed CPAN/authors/id/. If org_path doesn't contain a pause_id,
the distribution is assumed to belong to LOCAL user. For example,

  say parse_distname('Dist-0.01.tar.gz')->{cpan_path};
  # L/LO/LOCAL/Dist-0.01.tar.gz

If you only gives a pause_id, parent directories are supplemented.

  say parse_distname('ISHIGAKI/Dist-0.01.tar.gz')->{cpan_path};
  # I/IS/ISHIGAKI/Dist-0.01.tar.gz

=item pause_id

The pause_id of the distribution. Contrary to the above, this is
empty if you don't give a pause_id.

  say parse_distname('Dist-0.01.tar.gz')->{pause_id};
  # (undef, not LOCAL)

=item subdir

A PAUSE distribution may be put into a subdirectory under the author
directory. If the name contains such a subdirectory, it's kept here.

  say parse_distname('AUTHOR/sub/Dist-0.01.tar.gz')->{subdir};
  # sub

Perl 6 distributions are (almost) always put under Perl6/
subdirectory under each author's directory (with a few exceptions).

=item name_and_version

The name and version of the distribution, without an extension and
directory parts, which should not be empty as long as the
distribution has an extension that PAUSE accepts.

  say parse_distname('AUTHOR/sub/Dist-0.01.tar.gz')->{name_and_version};
  # Dist-0.01

=item name

The name part of the distribution. This may be empty if no valid
name is found

  say parse_distname('AUTHOR/sub/Dist-0.01.tar.gz')->{name};
  # Dist
  
  say parse_distname('AUTHOR/v0.1.tar.gz')->{name};
  # (empty)

=item version

The version part of the distribution. This also may be empty, and
this may not always be a valid version, and may have a following
part such as C<-TRIAL>.

  say parse_distname('AUTHOR/Dist.tar.gz')->{version};
  # (undef)
  
  say parse_distname('AUTHOR/Dist-0.01-TRIAL.tar.gz')->{version};
  # 0.01-TRIAL

=item version_number

The first numerical part of the version. This also may be empty, and
this may not always be a valid version.

  say parse_distname('AUTHOR/Dist-0.01-TRIAL.tar.gz')->{version_number};
  # 0.01
  
  say parse_distname('AUTHOR/Dist-0_0_1.tar.gz')->{version_number};
  # 0_0_1

=item extension

The extension of the distribution. If no valid extension is found,
parse_distname returns false (undef).

=item is_perl6

For convenience, if subdir exists and it starts with Perl6/,
this becomes true.

=item is_dev

If the version looks like C<\d+.\d+_\d+>, or contains C<-TRIAL>,
this becomes true. PAUSE treats such a distribution as a developer's
release and doesn't list it in its indices.

=back

=head1 METHODS

For compatibility with CPAN::DistnameInfo, Parse::Distname has the
same methods/accessors, so you can use it as a drop-in replacement.

In addition, C<is_perl6> and C<version_number> are available.

=head1 SEE ALSO

L<CPAN::DistnameInfo>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
