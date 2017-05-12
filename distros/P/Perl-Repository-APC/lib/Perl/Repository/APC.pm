package Perl::Repository::APC;

use strict;
use warnings;
use version;
use Cwd;
use File::Spec;
use Module::CoreList 2.14;

my $Id = q$Id: APC.pm 317 2011-03-26 16:59:05Z k $;
# our $VERSION = sprintf "2.000_%03d", substr(q$Rev: 317 $,4);
our $VERSION = "2.002001";
$VERSION =~ s/_//;

our %tarballs = (
                 "5.8.1" => {
                             tarfile => "perl-5.8.1.tar.gz",
                            },
                 "5.8.2" => {
                             tarfile => "perl-5.8.2.tar.gz",
                            },
                 "5.8.3" => {
                             tarfile => "perl-5.8.3.tar.gz",
                            },
                 "5.8.4" => {
                             tarfile => "perl-5.8.4.tar.gz",
                            },
                 "5.8.5" => {
                             tarfile => "perl-5.8.5.tar.gz",
                            },
                 "5.8.6" => {
                             tarfile => "perl-5.8.6.tar.gz",
                            },
                 "5.8.7" => {
                             tarfile => "perl-5.8.7.tar.gz",
                            },
                 "5.8.8" => {
                             tarfile => "perl-5.8.8.tar.gz",
                            },
                 "5.9.0" => {
                             tarfile => "perl-5.9.0.tar.gz",
                            },
                 "5.9.1" => {
                             tarfile => "perl-5.9.1.tar.gz",
                            },
                 "5.9.2" => {
                             tarfile => "perl-5.9.2.tar.gz",
                            },
                 "5.9.3" => {
                             tarfile => "perl-5.9.3.tar.gz",
                            },
                 "5.9.4" => {
                             tarfile => "perl-5.9.4.tar.gz",
                            },
                 "5.9.5" => {
                             tarfile => "perl-5.9.5.tar.gz",
                            },
                 "5.10.0" => {
                              tarfile => "perl-5.10.0.tar.gz",
                             },
                );

sub new {
  unless (@_ == 2){
    require Carp;
    Carp::croak(sprintf "Not enough arguments for %s -> new ()\n", __PACKAGE__);
  }
  my $proto   =  shift;
  my $class   =  ref $proto || $proto;

  my $dir =  shift;
  my $self;

  $self->{DIR} = $dir;
  $self->{APC} = [_apc_struct($dir)];

  bless $self => $class;
}

sub apcdirs {
  my($self) = @_;
  @{$self->{APC}};
}

sub tarball {
  unless (@_ == 2){
    require Carp;
    Carp::croak(sprintf "Not enough arguments for %s -> tarball ()\n", __PACKAGE__);
  }
  my($self,$pver) = @_;
  unless ($pver){
    require Carp;
    Carp::croak(sprintf "No version argument for %s -> tarball ()\n", __PACKAGE__);
  }

  my $DIR = File::Spec->catdir($self->{DIR},$pver);
  my $dir;
  unless (opendir $dir, $DIR) {
    return $self->_from_additional_tarballs($pver);
  }
  my(@dirent) = grep !/RC|TRIAL/, grep /^perl.*\.tar\.gz$/, readdir $dir;
  closedir $dir;
  if (@dirent>1){
      die "\aALERT: (\@dirent > 1: @dirent) in $pver" ;
  } elsif (@dirent==0) {
      return $self->_from_additional_tarballs($pver);
  }
  $dirent[0];
}

sub _from_additional_tarballs {
  my($self,$pver) = @_;
  die "unsupported perl version '$pver'", unless exists $tarballs{$pver};
  my $tarball = $tarballs{$pver}{tarfile};
  my $cwd = Cwd::cwd();
  my $addltar = File::Spec->catfile
      (
       $self->{DIR},
       "additional_tarballs",
       $tarball,
      );
  if (-f $addltar){
    return $addltar;
  } else {
    die "tarball '$tarball' not found. Have you mirrored the additional_tarballs directory?\n";
  }
}

sub patches {
  my($self,$ver) = @_;
  unless ($ver) {
    require Carp;
    Carp::confess("patches called without ver[$ver]");
  }
  my @res;
  for my $apcdir (@{$self->{APC}}) {
    my $pver = $apcdir->{perl};
    next unless $pver eq $ver;
    @res = @{$apcdir->{patches}};
    last;
  }
  \@res;
}

sub first_in_branch {
  my($self,$branch) = @_;
  unless (exists $self->{FIRST_IN_BRANCH}) {
    $self->next_in_branch; # initialize
  }
  my $ret = $self->{FIRST_IN_BRANCH}{$branch};
  die "Unknown branch" unless $ret;
  $ret;
}

sub next_in_branch {
  my($self,$ver) = @_;
  if (not exists $self->{NEXT_IN_BRANCH}) {
    my %L = ();
    for my $apcdir (@{$self->{APC}}) {
      my $pbranch = $apcdir->{branch};
      my $pver = $apcdir->{perl};
      $self->{NEXT_IN_BRANCH}{$pver} = [$pbranch]; # only for the last
      if ($L{$pbranch}){
        $self->{NEXT_IN_BRANCH}{$L{$pbranch}} = [$pbranch,$pver];
      } else {
        $self->{FIRST_IN_BRANCH}{$pbranch} = $pver;
      }
      $L{$pbranch} = $pver;
    }
  }
  return unless $ver;
  my $ref = $self->{NEXT_IN_BRANCH}{$ver};
  die "Unknown perl version $ver\n" unless $ref;
  my($rbranch,$rver) = @$ref;
  # warn "rver[$rver] rbranch[$rbranch]";
  $rver;
}

sub get_to_version {
  die "Usage: ->get_to_version(\$branch,\$patch)" unless @_ == 3;
  my($self,$branch,$patch) = @_;
  unless ($patch) {
    require Carp;
    Carp::confess("get_to_version called without patch[$patch]");
  }
  my $bp2v = $self->_bp2v;
  my $ret = $bp2v->{$branch,$patch};
  unless ($ret){
    require Carp;
    Carp::confess("patch[$patch] not part of branch[$branch]");
  }
  $ret;
}

sub get_diff_dir {
  die "Usage: ->get_diff_dir(\$branch,\$patch)" unless @_ == 3;
  my($self,$branch,$patch) = @_;
  my $perl = $self->get_to_version($branch,$patch);
  my $dir = $self->{PERL2DIR}{$perl};
  return $dir if $dir;
  my @apc = @{$self->{APC}};
  for my $apcdir (@apc) {
    my($dir) = $apcdir->{dir};
    my $abs = File::Spec->catdir($self->{DIR},$dir);
    unless (-d $abs) {
      $dir = $apcdir->{diffdir};
      $abs = File::Spec->catdir($self->{DIR},$dir);
      unless (-d $abs) {
        warn "WARNING: directory '$abs' not found";
      }
    }
    my($perl) = $apcdir->{perl};
    $self->{PERL2DIR}{$perl} = $dir;
  }
  die "could not find dir for perl '$self->{PERL2DIR}{$perl}'" unless $self->{PERL2DIR}{$perl};
  return $self->{PERL2DIR}{$perl};
}

sub _bp2v {
  my $self = shift;
  unless ($self->{BP2V}) { # branch/patch to version mapping
    my @apc = @{$self->{APC}};
    for my $apcdir (@apc) {
      my($apc_branch) = $apcdir->{branch};
      my($pver)       = $apcdir->{perl};
      my($patches)    = $apcdir->{patches};
      for my $p (@$patches) {
        $self->{BP2V}{$apc_branch,$p} = $pver;
      }
    }
  }
  $self->{BP2V};
}

sub get_from_version {
  my($self) = shift;
  my($branch,$patch) = @_;
  unless ($patch) {
    require Carp;
    $patch = "[undef]" unless defined $patch;
    Carp::confess("get_from_version called without patch[$patch]");
  }
  my $perl = $self->get_to_version(@_);
  my @apc = @{$self->{APC}};
  my %Ldir = ( "perl" => 0, "maint-5.004" => 0 );
  for my $apc (@apc) {
    my($apc_branch) = $apc->{branch};
    next unless $apc_branch eq $branch;
    my($pver) = $apc->{perl};
    if ($pver eq $perl) {
      if (exists $Ldir{$apc_branch}){
        return $Ldir{$apc_branch};
      } else {
        $perl =~ s/1$/0/;
        return $perl;
      }
    }
    $Ldir{$apc_branch} = $pver;
  }
}

{
  my %ignore = map { ($_ => undef) } qw(4475 32694);
  sub _ignore_patch_number ($) {
    my($patch_number) = @_;
    return exists $ignore{$patch_number};
  }
}

sub _apc_struct ($) {
  my $APC = shift;
  opendir my $APCDH, $APC or die "Could not open APC[$APC]: $!";
  my @apcdir;
  my %dseen;
  my %living_dirs = (
                     # all the "old" symlinks

## % ls -ld APC/*/diffs(@)
## lrwxrwxrwx 1 sand sand 21 2005-06-09 06:34:12 APC/5.005_04/diffs -> ../perl-5.005xx-diffs/
## lrwxrwxrwx 1 sand sand 19 2008-01-19 15:48:04 APC/5.6.2/diffs -> ../perl-5.6.2-diffs/
## lrwxrwxrwx 1 sand sand 19 2008-01-19 15:48:04 APC/5.6.3/diffs -> ../perl-5.6.x-diffs/
## lrwxrwxrwx 1 sand sand 19 2008-01-19 15:48:04 APC/5.8.1/diffs -> ../perl-5.8.x-diffs/
## lrwxrwxrwx 1 sand sand 21 2008-01-19 15:48:04 APC/5.9.0/diffs -> ../perl-current-diffs/

                     "5.005_04" => "perl-5.005xx-diffs",
                     "5.6.2"    => "perl-5.6.2-diffs",
                     "5.6.3"    => "perl-5.6.x-diffs",
                     "5.8.1"    => "perl-5.8.x-diffs",
                     "5.9.0"    => "perl-current-diffs",
                     
                     # plus the not symlinked ones
                     "5.10.1"   => "perl-5.10.x-diffs",
                    );
  my %have_visited;
 DIRENT: for my $dirent (readdir $APCDH, keys %living_dirs) {
    next DIRENT unless $dirent =~ /^5/;
    my $diffdir;
    if (my $living_dir = $living_dirs{$dirent}) {
      $diffdir =  File::Spec->catdir($APC,$living_dir);
      unless (-e $diffdir) {
        my $fallback =  File::Spec->catdir($APC,$dirent,"diffs");
        warn "Warning: expected to find '$diffdir', trying '$fallback'";
        $diffdir = $fallback;
      }
    } else {
      $diffdir =  File::Spec->catdir($APC,$dirent,"diffs");
    }
    if ($have_visited{$dirent,$diffdir}++){
      # again is OK if for a different thing
      # warn "DEBUG: skipping '$diffdir' due to '$dirent'";
      next DIRENT;
    }
    opendir my $DIFFDIR, $diffdir or die "Could not open $diffdir: $!";
    my %patches;
    # read them and give them a value
  PFILE: for my $dirent2 (readdir $DIFFDIR) {
      next PFILE unless $dirent2 =~ /^(\d+)\.gz/;
      my $candnu = $1;
      next PFILE if _ignore_patch_number($candnu);
      $patches{$dirent2} = $candnu;
      if ($dseen{$dirent2}) {
        # warn "Duplicate $dirent2 in $diffdir (also in $dseen{$dirent2})\n";
      } else {
        $dseen{$dirent2} = $diffdir;
      }
    }
    closedir $DIFFDIR;
    unless (%patches){ # in case they did not mirror something we try to drop it silently
      # warn "DEBUG: skipping '$dirent' because no entry";
      next DIRENT;
    }
    my @patches = sort { $patches{$a} <=> $patches{$b} || $a cmp $b } keys %patches;
    my $branch;
    my $sortdummy;
  PATCH: for my $n (0..$#patches) {
      my $diff;
      die unless -e ($diff = File::Spec->catfile($diffdir,$patches[$n]));
      ($sortdummy) = $patches[$n] =~ /(\d+)/ unless $sortdummy;
      open my $fh, "zcat $diff |" or die;
      local($/) = "\n";
    LINE: while (<$fh>) {
        next LINE unless m|^==== //depot/([^/]+)/([^/]+)|;
        $branch = $1;
        my $subbranch = $2; # this limits us to one level. Unlucky.
        next LINE unless $branch =~ /maint/;
        $branch .= "/$subbranch" unless $subbranch eq "perl";
        last LINE;
        # print "$dirent|$patches[0]: $_";
      }
      close $fh;
      if ($branch) {
        last PATCH;
      }
    }
    my $reldiffdir = File::Spec->abs2rel($diffdir, $APC);
    unless ($reldiffdir) {
      warn "DEBUG: no reldiffdir??? dirent[$dirent]diffdir[$diffdir]";
    }
    push @apcdir, {branch  => $branch,
                   dir     => $dirent,
                   diffdir => $reldiffdir,
                   perl    => $dirent,
                   patches => [map {$patches{$patches[$_]}} 0..$#patches],
                  };
  }
  closedir $APCDH;
  _splice_additional_tarballs(\@apcdir);
  sort { $a->{patches}[-1] <=> $b->{patches}[-1] } @apcdir;
}

sub _splice_additional_tarballs ($) {
  my($apcdir) = @_;
  my @splicers;
  while (my($k,$v) = each %tarballs) {
    my $version = version->new($k)->numify + 0;
    my $x = $Module::CoreList::patchlevel{$version}
        or die "could not access corelist for '$version' from '$INC{'Module/CoreList.pm'}'";
    push @splicers, {
                     branch     => $x->[0],
                     patchlevel => $x->[1],
                     perl       => $k,
                    };
  }
  my $success = 0;
  for my $splicer (sort {$a->{branch} cmp $b->{branch}
                             ||
                                 $a->{patchlevel} <=> $b->{patchlevel}
                               } @splicers) {
  APCDIR: for my $i (0..$#$apcdir) {
      my $beq = $apcdir->[$i]{branch} eq $splicer->{branch};
      my $peq = version->new($splicer->{perl}) >= version->new($apcdir->[$i]{perl});
      my $lok = $splicer->{patchlevel} > $apcdir->[$i]{patches}[0];
      my $rok = $splicer->{patchlevel} <= $apcdir->[$i]{patches}[-1];
      if ($beq && $peq && $lok && $rok) {
        my $adir = splice @$apcdir, $i, 1;
        # the left range is leading to $version_popular
        # the right range is leading to what it already states
        my(%left, %right);
        for ("branch","dir","diffdir") {
          $left{$_} = $right{$_} = $adir->{$_};
        }
        if ($splicer->{perl} eq $adir->{perl}){
          # we cannot have two perls with the same name.
          $adir->{perl} .= ".1"; # ouch
        }
        $left{perl}     = $splicer->{perl};
        $right{perl}    = $adir->{perl};
        $left{patches}  = [];
        $right{patches} = [];
        push @{$left{patches}}, shift @{$adir->{patches}} while $adir->{patches}[0] <= $splicer->{patchlevel};
        $right{patches} = $adir->{patches};
        push @$apcdir, \%left, \%right;
        last APCDIR;
      }
    }
  }
  my %rename = (
                "5.8.1.1" => "5.8.9",
                "5.9.0.1" => "5.11.0",
               );
 APCDIR: for my $i (0..$#$apcdir) {
    my $perl = $apcdir->[$i]{perl};
    if (my $rename = $rename{$perl}) {
      $apcdir->[$i]{perl} = $rename;
    }
  }
}

sub version_range {
  my($self,$branch,$lo,$hi) = @_;
  $lo = $self->closest($branch,">",$lo);
  $hi = $self->closest($branch,"<",$hi);
  my @range;
  my @apc = @{$self->{APC}};
  for my $apcdir (@apc) {
    my($apc_branch) = $apcdir->{branch};
    my($pver) = $apcdir->{perl};
    my($patches) = $apcdir->{patches};
    next unless $apc_branch eq $branch;
    next unless $lo <= $patches->[-1];
    last if $hi < $patches->[0];
    push @range, $pver;
  }
  \@range;
}

sub patch_range {
  my($self,$branch,$lo,$hi) = @_;
  my($vrange,%vrange);
  $vrange = $self->version_range($branch,$lo,$hi);
  @vrange{@$vrange} = ();
  my @range;
  my @apc = @{$self->{APC}};
  for my $apcdir (@apc) {
    next unless exists $vrange{$apcdir->{perl}};
    my($patches) = $apcdir->{patches};
    for my $p (@$patches) {
      if ($p >= $lo && $p <= $hi) {
        push @range, $p;
      }
    }
  }
  \@range;
}

sub closest {
  my($self,$branch,$alt,$wanted) = @_;
  my $closest;
  if ($alt eq "<") {
    $closest = 0;
  } else {
    $closest = 999999999;
  }
  my @apc = @{$self->{APC}};
  for my $i (0..$#apc) {
    my $apcdir = $apc[$i];
    my($apc_branch) = $apcdir->{branch};
    my($pver) = $apcdir->{perl};
    my $patches = $apcdir->{patches};
    next unless $apc_branch eq $branch;
    next if $alt eq ">" && $patches->[-1] < $wanted;
    next if $alt eq "<" && $patches->[0] > $wanted;
    if ($alt eq ">" && $patches->[0] > $wanted){
      $closest = $patches->[0] if $closest > $patches->[0];
      last;
    } elsif ($alt eq "<" && $patches->[-1] < $wanted) {
      $closest = $patches->[-1];
      next;
    }
    for my $p (@$patches) {
      if ($alt eq "<") {
        last if $p > $wanted;
        $closest = $p;
      } else {
        $closest = $p, last if $p >= $wanted;
      }
    }
  }
  if ($alt eq "<") {
    if ($closest == 0) {
      die "Could not find a patch > 0 and < $wanted";
    }
  } else {
    if ($closest == 999999999) {
      die "Could not find a patch < 999999999 and > $wanted";
    }
  }
  $closest;
}

1;

__END__

=head1 NAME

Perl::Repository::APC - Class modelling "All Perl Changes" repository

=head1 SYNOPSIS

  use Perl::Repository::APC;
  my $apc = Perl::Repository::APC->new("/path/to/APC");

=head1 WARNING

Note (2011-03-26 andk): This package once implemented sort of a
poor man's git in the times when perl sources were kept in a Perforce
repository. Since the perl repo itself switched to git in 2008 this
package is outdated and hardly of use for anybody. It will probably be
removed from CPAN soon.

=head1 DESCRIPTION

=over

=item * new

The constructor new() takes a single argument, the path to the APC.
The resulting object has the following methods:

=item * get_to_version($branch,$patch)

$branch is one of C<perl>, C<maint-5.004>, C<maint-5.005>,
C<maint-5.6>, C<maint-5.8>, C<maint-5.10>. $patch is a patch number that B<must> also
be available in the local copy of APC. The return value is the perl
version that this patch was/is leading to. If the branch is still
active in that area, that version may be arbitrary, just enough to get
a unique identifier.

    $apc->get_to_version("perl",7100);         # returns "5.7.1"
    $apc->get_to_version("maint-5.005",1656);  # returns "5.005_01"
    $apc->get_to_version("perl", 30000);       # returns "5.9.5"

Dies if $patch is not part of $branch.

=item * get_diff_dir($branch,$patch)

$branch is one of C<perl>, C<maint-5.004>, C<maint-5.005>,
C<maint-5.6>, C<maint-5.8>, C<maint-5.10>. $patch is a patch number
that B<must> also be available in the local copy of APC. The return
value is the APC directory that holds the patches for this patch.

    $apc->get_to_version("perl",7100);         # returns "5.7.1"
    $apc->get_to_version("maint-5.005",1656);  # returns "5.005_01"
    $apc->get_diff_dir("perl", 30000);         # returns "5.9.0"

Dies if $patch is not part of $branch.

=item * get_from_version($branch,$patch)

Like above, but returns the perl version this patch is building upon.
E.g.

    $apc->get_to_version("perl",7100);         # "5.7.0"
    $apc->get_to_version("maint-5.005",1656);  # "5.005_00"
    $apc->get_from_version("perl",12823);      # "5.7.2"
    $apc->get_from_version("maint-5.6",12823); # "5.6.1"

=item * patch_range($branch,$lower,$upper)

$lower and $upper are two patch numbers, $branch is a perforce branch
name (see get_to_version() for a description). This method returns an
reference to an array containing all patchnumbers on $branch starting
with the lower boundary (or above, if the lower boundary does not
exist) and ending with the upper boundary (or below, if the upper
boundary does not exist). E.g.

    $apc->patch_range("perl",0,999999999); # returns all patches on the trunk
    $apc->patch_range("perl",17600,17700); # 

=item * version_range($branch,$lower,$upper)

As above but instead of returning an array of patches, it returns the
accordant array of perl versions (i.e. directories below APC). E.g.

    $apc->version_range("perl",17600,17700); # returns ["5.8.0","5.9.0"]

=item * tarball($version)

$version is a perl version as labeled in the APC, e.g. "5.005_00".
The return value is the name of the perl tarball containing that
version. E.g.

    $apc->tarball("5.005_00"); # "perl5.005.tar.gz"
    $apc->tarball("5.6.0");    # "perl-5.6.0.tar.gz"
    $apc->tarball("5.004_75"); # "perl5.005-beta1.tar.gz"

Dies if the argument cannot be resolved to existing tarball.

Versions of Perl::Repository::APC up to 1.276 returned a relative
path. Since then it may return an absolute path or a relative one in
order to be able to support the additional_tarballs/ directory which
was added to APC in 2008-01.

=item * first_in_branch($branch)

=item * next_in_branch($version)

$branch is a perforce branch (see get_to_version() for a description).
$version is a perl version as labeled in the APC, e.g. "5.005_00".

    $apc->first_in_branch("maint-5.004"); # returns "5.004_00"
    $apc->first_in_branch("perl");        # returns "5.004_50"
    $apc->next_in_branch("5.6.0");        # returns "5.7.0"

Next_in_branch returns undef for the last version of a branch. Both
methods die if the argument is not a valid branch or version name.

=item * patches($version)

Returns an arrayref to the numerically sorted list of all available
patches to build this target perl version.

    $apc->patches("5.7.1"); # returns an arrayref to an array with
                            # 1820 numbers

=item * apcdirs()

Returns a list of hashrefs. Each hashref has the keys C<branch> for
the branch name, C<perl> for the perl version name. C<patches> for an
arrayref which contains the numerically sorted patch numbers that were
leading to that perl version. See the script C<apc-overview> for a
simple example of using this.

=item * closest($branch,$alt,$wanted)

If the patch is in the $branch branch this returns the patch number
$wanted itself. Otherwise returns the closest to the $wanted
patchnumber in a given branch. The $alt argument specifies from which
side the closest should be determined: if $alt is C<< < >> we search
from the left, otherwise we search from the right.

=back

=head1 AUTHOR

Andreas Koenig C<< <ANDK> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 SEE ALSO

patchaperlup, buildaperl, binsearchaperl

=cut
