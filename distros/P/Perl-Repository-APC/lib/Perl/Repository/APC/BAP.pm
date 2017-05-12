package Perl::Repository::APC::BAP;
use Perl::Repository::APC;

use strict;
use warnings;

my $Id = q$Id: BAP.pm 294 2008-02-22 10:42:30Z k $;
our $VERSION = sprintf "%.3f", 1 + substr(q$Rev: 294 $,4)/1000;

sub new {
  unless (@_ == 2){
    require Carp;
    Carp::croak(sprintf "Not enough arguments for %s -> new ()\n", __PACKAGE__);
  }
  my $proto   =  shift;
  my $class   =  ref $proto || $proto;

  my $apc =  shift;
  my $self;

  $self->{APC} = $apc;

  bless $self => $class;
}

sub translate {
  my($self,$branch,$baseperl,$patchlevel) = @_;
  die sprintf "%s -> translate called without a branch argument", __PACKAGE__
      unless $branch;
  my($prev, $nextperl, @patches, @ver);
  my $apc = $self->{APC};
  if ($branch eq "perl") {
    $prev = "0";
  } elsif (my($bv) = $branch =~ /^maint-(.*)/) {
    # maintainance nightmare: we currently (rev 123) have no access to
    # any metadata that tell us the perl we need
    if ($bv eq "5.004") {
      $prev = "0";
    } elsif ($branch =~ /\//) { # currently only "maint-5.6/perl-5.6.2"
      if ($branch eq "maint-5.6/perl-5.6.2") {
        $prev = "5.6.1";
      } else {
        die "Illegal value for branch[$branch]"; # carp doesn't make it better
      }
    } else {
      $prev = "$bv.0"; # 5.6 -> 5.6.0 etc.
    }
  }
  @ver = $prev;
  for (
       my $next = $apc->first_in_branch($branch);
       $next;
       $next = $apc->next_in_branch($next)
      ) {
    $nextperl = $next;
    @patches = @{$apc->patches($next)};
    push @ver, $next;
    if ($patchlevel && $patchlevel >= $patches[0] && $patchlevel <= $patches[-1]){
      if (defined $baseperl && length $baseperl &&
          grep { $_ eq $baseperl } @ver) {
        unless ($prev eq $baseperl){
          die "Fatal error: patch $patchlevel is outside the patchset based on $baseperl\n";
        }
      }
      last;
    } elsif (defined $baseperl && length($baseperl)) {
      if ($baseperl eq "0") {
        if ($ver[0] eq "0") {
          last;
        } else {
          die "Fatal error: 0 is not starting point for branch $branch\n";
        }
      } else {
        last if $prev && $baseperl eq $prev || @ver>1 && $baseperl eq $ver[-2];
      }
    }
    $prev = $next;
  }
  if (defined $baseperl && length $baseperl) {
    if ($baseperl eq "0") {
      # always OK?
    } else {
      unless (grep { $_ eq $baseperl } @ver){
        die "Fatal error: $baseperl is not part of branch $branch";
      }
    }
  } else {
    if (@ver > 1) {
      $baseperl = $ver[-2];
    } elsif (@ver == 1) {
      $baseperl = $ver[0];
      $baseperl =~ s/1$/0/;
    } else {
      die "Could not determine base perl version";
    }
  }
  if ($patchlevel) {
    unless (grep { $_ eq $patchlevel } @patches){
      my @neighbors = $self->neighbors($patchlevel,\@patches);
      my $tellmore;
      if (@neighbors) {
        if (@neighbors == 1) {
          $tellmore = "$neighbors[0] would be";
        } else {
          $tellmore = "$neighbors[0] or $neighbors[1] would be";
        }
      } else {
        $tellmore = "Range is from $patches[0] to $patches[-1]";
      }
      die "Fatal error: patch $patchlevel is not part of the patchset for $baseperl
    ($tellmore)\n";
    }
  } else {
    $patchlevel = $patches[-1];
  }
  my $firstpatch = $patches[0];
  my $dir = $apc->get_diff_dir($branch,$patchlevel);
  return ($baseperl, $nextperl, $firstpatch, $patchlevel, $dir);
}

sub neighbors {
  my($self,$x,$arr) = @_;
  return if $x < $arr->[0];
  return if $x > $arr->[-1];
  my @res;
  for my $i (0..$#$arr) {
    if ($arr->[$i] < $x) {
      $res[0] = $arr->[$i];
    } elsif ($arr->[$i] > $x) {
      $res[1] ||= $arr->[$i];
      last;
    } else {
      # must not happen
      die "Panic: neighbors called with matching element";
    }
  }
  @res;
}

1;

__END__

=head1 NAME

Perl::Repository::APC::BAP - Transform the argument to buildaperl

=head1 SYNOPSIS

  use Perl::Repository::APC::BAP;
  my $apc = Perl::Repository::APC->new("/path/to/APC");
  my $bap = Perl::Repository::APC::BAP->new($apc);
  my($baseperl,$nextperl,$firstpatch,$lastpatch,$dir) = $bap->translate("perl",...);

=head1 DESCRIPTION

The constructor new() takes a single argument, a Perl::Repository::APC
object. The resulting object has the following methods:

=over

=item * translate($branch,$baseperl,$patchlevel)

=item * translate($branch,$baseperl)

$branch is one of C<perl>, C<maint-5.004>, C<maint-5.005>,
C<maint-5.6>, C<maint-5.8>. $baseperl is the perl version we want as a
base. $patchlevel is a patch number that B<must> also be available in
the local copy of APC.

$branch is a mandatory argument. $baseperl may be undef and
$patchlevel can be omitted. If $baseperl is undef and $patchlevel is
given, translate() finds the proper version. If patch is omitted and
$baseperl is given, translate() finds the most recent patch for that
base. If both are omitted, translate() finds the newest values
available for both version and patch for that branch. If both are
given, translate() checks if the values are legal and dies if they
aren't.

Five values are returned: the perl version we can use as a base, the
"next" perl version that this patchset is running to, the first and
the last patch number we want, and finally the directory where we find
the patches. The directory was the same as the target perl version up
to 5.8.0 but started to diverge from 5.8.1 and later. Please see bap.t
for examples. Starting from 5.10.1. the directory may be one of these
C<living> directories that match C<^perl-.*-diffs$>. These directories
do not contain a subdirectory C<diffs>. Instead they contain the
patches directly.

=back

=head1 AUTHOR

Andreas Koenig C<< <ANDK> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 SEE ALSO

Perl::Repository::APC, patchaperlup, buildaperl, binsearchaperl

=cut
