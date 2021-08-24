package Test::Pod::Coverage::TrustMe;
use strict;
use warnings;

our $VERSION = '0.002000';
$VERSION =~ tr/_//d;

use File::Spec ();
use Cwd ();
use Test::Builder ();

use Exporter ();
*import = \&Exporter::import;

our @EXPORT = qw(
  all_modules
  pod_coverage_ok
  all_pod_coverage_ok
);

sub _blib {
  my $dir = File::Spec->curdir;
  my $try = 5;
  while ($try--) {
    my $blib = File::Spec->catdir($dir, 'blib');
    if (
      -d $blib
      && -d File::Spec->catdir($blib, 'arch')
      && -d File::Spec->catdir($blib, 'lib')
    ) {
      return $blib;
    }

    $dir = File::Spec->catdir($dir, File::Spec->updir);
  }
  return undef;
}

sub _lib {
  my $dir = File::Spec->curdir;
  my $try = 5;
  while ($try--) {
    my $lib = File::Spec->catdir($dir, 'lib');
    if (-d $lib) {
      my @parts = File::Spec->splitdir(Cwd::realpath($lib));
      if (
        @parts >= 2
        && $parts[-1] eq 'lib'
        && ($parts[-2] eq 't' || $parts[-2] eq 'xt')
      ) {
        next;
      }

      return $lib;
    }

    $dir = File::Spec->catdir($dir, File::Spec->updir);
  }
  return undef;
}

sub _base_dirs {
  my %find;
  if (my $lib = _lib()) {
    $find{Cwd::realpath($lib)}++;
  }
  if (my $blib = _blib()) {
    $find{Cwd::realpath(File::Spec->catdir($blib, 'arch'))}++;
    $find{Cwd::realpath(File::Spec->catdir($blib, 'lib'))}++;
  }

  my @dirs = grep $find{Cwd::realpath($_)}, @INC;
  return @dirs;
}

sub all_modules {
  my @dirs = @_;
  @dirs = _base_dirs
    if !@dirs;

  my %searched;
  my @modules;
  my %modules;

  my @search = map [$_], @dirs;
  while (my $search = shift @search) {
    my ($dir, @pre) = @$search;
    next
      if $searched{Cwd::realpath($dir)}++;
    opendir my $dh, $dir or die;
    my @found = File::Spec->no_upwards(readdir $dh);
    closedir $dh;

    my @mods = grep /\.pm\z/ && -f File::Spec->catfile($dir, $_), @found;
    s/\.pm\z// for @mods;
    push @modules,
      grep !$modules{$_}++,
      map join('::', @pre, $_),
      grep !/\W/,
      @mods;

    unshift @search,
      map [ $_->[0], @pre, $_->[1] ],
      grep -d $_->[0],
      map [ File::Spec->catdir($dir, $_) => $_ ],
      grep !/\W/,
      @found;
  }

  return @modules;
}

sub pod_coverage_ok {
  my $module = shift;
  my %opts = ref $_[0] eq 'HASH' ? %{ +shift } : ();
  my $msg = shift || "Pod coverage on $module";

  $opts{package} = $module;

  my $class = delete $opts{coverage_class} || 'Pod::Coverage::TrustMe';
  (my $mod = "$class.pm") =~ s{::}{/}g;
  require $mod;

  my $cover = $class->new(%opts);

  our $Test ||= Test::Builder->new;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $ok;
  my $rating = $cover->coverage;
  if (!defined $rating) {
    my $why = $cover->why_unrated;
    $ok = $Test->ok( defined $cover->symbols, $msg );
    $Test->diag( "$module: ". $cover->why_unrated );
  }
  else {
    $ok = $Test->is_eq((map sprintf('%3.0f%%', $_ * 100), $rating, 1), $msg);
    if (!$ok) {
      $Test->diag(join('',
        "Naked subroutines:\n",
        map "    $_\n", $cover->uncovered,
      ));
    }
  }
  return $ok;
}

sub all_pod_coverage_ok {
  my %opts = ref $_[0] eq 'HASH' ? %{ +shift } : ();
  my $dirs = delete $opts{dirs};
  my @modules = all_modules(@{ $dirs || [] });

  our $Test ||= Test::Builder->new;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my $ok = 1;

  if ( @modules ) {
    $Test->plan( tests => scalar @modules );

    for my $module ( @modules ) {
      pod_coverage_ok( $module, @_ ) or $ok = 0;
    }
  }
  else {
    $Test->plan( tests => 1 );
    $Test->ok( 1, "No modules found." );
  }

  return $ok;
}

1;
__END__

=head1 NAME

Test::Pod::Coverage::TrustMe - Test Pod coverage

=head1 SYNOPSIS

  use Test::Pod::Coverage::TrustMe;

  all_pod_coverage_ok();

=head1 DESCRIPTION

Tests that all of the functions or methods provided by a package have
documentation. Drop in replacement for L<Test::Pod::Coverage>, but with
additional features. Uses L<Pod::Coverage::TrustMe> to check coverage by
default.

=head1 FUNCTIONS

=head2 pod_coverage_ok ( $module[, $options][, $message] )

Tests the coverage of the C<$module> given. Options specified will be passed
along to the constructor of L<Pod::Coverage::TrustMe>. A default test message
will be used if not provided.

A special options of C<coverage_class> can be used to specify an alternative
class to use for calculating coverage. This option will not be passed along
to the class constructor.

=head2 all_pod_coverage_ok ( [ $options ] [, $message ] )

Tests coverage for all modules found. This will set a test plan, so it should
not be used in scripts doing other tests. Alternatively, it can be run in its
own subtest.

Accepts the same options as L</pod_coverage_ok>, in addition to a C<dirs>
option to specify an array reference of directories to search for modules. The
L</all_modules> function will be used to search these directories. Note that
the modules must still be loadable using a L<require|perlfunc/require>. This
module will not automatically add the specified directories to
L<@INC|perlvar/@INC>.

=head2 all_modules ( @dirs )

Finds all modules in the given directories.  If no directories are provided,
the C<lib>, C<blib/arch>, and C<blib/lib> directories will be searched, but only
if they are found in L<@INC|perlvar/@INC>.

=head1 AUTHORS

See L<Pod::Coverage::TrustMe> for authors.

=head1 COPYRIGHT AND LICENSE

See L<Pod::Coverage::TrustMe> for the copyright and license.

=cut
