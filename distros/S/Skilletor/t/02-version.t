#!/usr/bin/env perl
# One version line (k242): the dist's $VERSION (0.008000) is the plugin's version (package.json,
# 0.8.0) in the other spelling, version->normal without its "v". The dist keeps both sub-levels
# (k269): x.yyyzzz is the plugin's x.y.z. Every module carries it, and the CLI reports it.
#
# The tie to package.json holds in a checkout (the tarball has no package.json) in one of two
# states:
# - released, or about to be: package.json is normal($VERSION);
# - after a release: @Git::VersionManager's BumpVersionAfterRelease has moved lib/ on to the next
#   version (Version::Next: 0.008000 -> 0.008001) while package.json still names the release
#   (0.8.0): normal($VERSION - 0.000001). package.json follows with the next release's preparation.
# The release gate, maint/version-tie.pl (dist.ini: run_before_release), takes the first state
# only, for the version dzil releases.
use strict;
use warnings;
use Test::More;
use FindBin;
use Path::Tiny qw( path tempdir );
use version ();
use Skilletor ();
use Skilletor::Process qw( run_command );

my $DIST = path( $FindBin::Bin, '..' );
my $VERSION = $Skilletor::VERSION;

sub normal { version->parse( $_[0] )->normal =~ s/\Av//r }

# The plugin version released when lib/ holds the bump after it.
sub released_before { normal( sprintf '%.6f', $_[0] - 0.000001 ) }

like( $VERSION, qr/\A\d+\.\d{6}\z/, "the dist version ($VERSION) has six decimals: x.yyyzzz is the plugin's x.y.z" );

subtest 'x.yyyzzz is the plugin\'s x.y.z' => sub {
  is( normal('0.008000'), '0.8.0',  '0.008000' );
  is( normal('0.008001'), '0.8.1',  '0.008001' );
  is( normal('1.012003'), '1.12.3', '1.012003' );
};

subtest 'the bump after a release names the release before it' => sub {
  is( released_before('0.008001'), '0.8.0',   '0.008001, the bump after 0.008000' );
  is( released_before('0.009000'), '0.8.999', '0.009000, the bump after 0.008999' );
};

subtest 'every module of lib/ carries the dist version' => sub {
  my @pm;
  $DIST->child('lib')->visit( sub { push @pm, $_[0] if $_[0] =~ /\.pm\z/ }, { recurse => 1 } );
  cmp_ok( scalar @pm, '>', 50, 'the modules of lib/' );
  for my $pm ( sort { "$a" cmp "$b" } @pm ) {
    my @v = $pm->slurp_raw =~ /^our \$VERSION = '([^']*)';$/mg;
    is_deeply( \@v, [$VERSION], $pm->relative($DIST).": our \$VERSION = '$VERSION'" );
  }
};

subtest 'the CLI reports the dist version' => sub {
  my @cli = ( $^X, '-I'.$DIST->child('lib'), $DIST->child( 'script', 'skilletor' )."" );
  my $v = run_command( cmd => [ @cli, '--version' ], env => {%ENV} );
  is( $v->{stdout} =~ s/\r?\n\z//r, $VERSION, '--version' );
  my $h = run_command( cmd => [ @cli, '--help' ], env => {%ENV} );
  like( $h->{stdout}, qr/\Askilletor \Q$VERSION\E\r?\n/, '--help starts with it' );
};

subtest 'package.json names the same version, or the release before it' => sub {
  my $pkg = $DIST->child('package.json');
  plan skip_all => 'no package.json (the CPAN tarball): the plugin is a checkout\'s' unless $pkg->is_file;
  my ($plugin) = $pkg->slurp_raw =~ /^  "version": "([^"]+)",$/m;
  ok( defined $plugin, 'package.json has a version' ) or return;
  my $released = normal($VERSION);
  my $before   = released_before($VERSION);
  ok( $plugin eq $released || $plugin eq $before,
    "package.json $plugin is $released (dist $VERSION) or, lib/ one bump past the release, $before" );
};

subtest 'maint/version-tie.pl releases only the version package.json names' => sub {
  my $tie = $DIST->child( 'maint', 'version-tie.pl' );
  plan skip_all => 'no maint/ (the CPAN tarball)' unless $tie->is_file;
  my $dir = tempdir;
  $dir->child('package.json')
    ->spew_raw(qq({\n  "name": "skilletor",\n  "version": "0.8.0",\n  "type": "module"\n}\n));
  my $run = sub { run_command( cmd => [ $^X, "$tie", @_ ], cwd => "$dir", env => {%ENV} ) };
  my $ok = $run->('0.008000');
  is( $ok->{code}, 0, '0.008000 against 0.8.0' ) or diag $ok->{stderr};
  like( $ok->{stdout}, qr/\Aversion-tie: dist 0\.008000 = plugin 0\.8\.0\r?\n\z/, 'it names both' );
  my $behind = $run->('0.008001');
  is( $behind->{code}, 1, '0.008001 against 0.8.0: package.json not prepared' );
  like( $behind->{stderr}, qr/package\.json must say 0\.8\.1, not 0\.8\.0/, 'it names the version wanted' );
  for my $bad ( '0.008', '0.0080', '0.008000_01', '0.8.0', 'v0.8.0' ) {
    my $r = $run->($bad);
    isnt( $r->{code}, 0, "$bad is refused" );
    like( $r->{stderr}, qr/\Ausage: .*x\.yyyzzz/, "$bad: the usage names the spelling" );
  }
};

done_testing;
