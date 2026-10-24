#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of write_json );

use JSON::MaybeXS ();
use Path::Tiny qw( path tempdir );
use Scalar::Util qw( blessed reftype );
use Skilletor::Config;
use Skilletor::JSON qw( js_parse );

# t/data/config-oracle.json: what the reference's loadConfig made of each scenario
# (maint/oracle-config.mjs) – the files byte for byte, and the loaded config or the error.
my $oracle = js_parse( path( $FindBin::Bin, 'data', 'config-oracle.json' )->slurp_utf8 );

# Plain data: booleans as strings, tied hashes as plain ones – what is_deeply can compare.
sub plain {
  my ( $v ) = @_;
  return $v unless ref $v;
  return $v ? 'JSON::true' : 'JSON::false' if JSON::MaybeXS::is_bool($v);
  return [ map { plain($_) } @$v ] if reftype $v eq 'ARRAY';
  return { map { $_ => plain( $v->{$_} ) } keys %$v } if reftype $v eq 'HASH';
  die 'unexpected '.ref $v;
}

sub placeholders {
  my ( $v, $home, $project ) = @_;
  return $v unless defined $v;
  if ( !ref $v ) {
    ( my $s = $v ) =~ s/<HOME>/$home/g;
    $s =~ s/<PROJECT>/$project/g;
    return $s;
  }
  return $v if JSON::MaybeXS::is_bool($v);
  return [ map { placeholders( $_, $home, $project ) } @$v ] if reftype $v eq 'ARRAY';
  return { map { $_ => placeholders( $v->{$_}, $home, $project ) } keys %$v };
}

for my $case ( @{ $oracle } ) {
  subtest $case->{name} => sub {
    my $root    = tempdir;
    my $home    = $root->child('home');
    my $project = $root->child('project');
    my %file = (
      user    => $home->child( '.claude', 'skilletor.json' ),
      project => $project->child( '.claude', 'skilletor.json' ),
      local   => $project->child( '.claude', 'skilletor.local.json' ),
    );
    $_->parent->mkpath for values %file;
    for my $k ( keys %file ) {
      next unless defined $case->{files}{$k};
      $file{$k}->spew_utf8( $case->{files}{$k} );
    }
    my %args = ( home => "$home" );
    $args{project_dir} = "$project" unless $case->{noProject};
    if ( my $u = $case->{unchecked} ) {
      $args{unchecked} = { path => "$file{ $u->{file} }", name => $u->{name} };
    }

    my $config;
    my $err = error_of( sub { $config = Skilletor::Config->new(%args) } );
    if ( exists $case->{error} ) {
      is( $err, placeholders( $case->{error}, "$home", "$project" ), 'same error' );
      return;
    }
    is( $err, undef, 'loads' ) or return;
    is_deeply(
      plain( $config->to_data ),
      plain( placeholders( $case->{loaded}, "$home", "$project" ) ),
      'same config',
    );
  };
}

subtest 'accessors' => sub {
  my $t = SkilletorTest::home_with(
    user    => { sources => { u => { git => 'https://u' }, s => { local => '~/dev/s' } }, install => { skills => ['a@u'] } },
    project => { sources => { s => { git => 'https://p', ref => 'v1' } }, install => { skills => ['b@s'], agents => ['*@u'] } },
  );
  my $c = Skilletor::Config->load( home => $t->{home}, project_dir => $t->{project} );
  ok( $c->has_project, 'has a project' );
  is_deeply( [ $c->source_names ], [qw( s u )], 'merged names in Map order: project first' );
  is_deeply( [ $c->user_source_names ], [qw( s u )], 'user names in file order (written sorted)' );
  is( $c->source('s')->{git}, 'https://p', 'project git' );
  is( $c->source('s')->{local}, '~/dev/s', 'user local beside it (author mode)' );
  is_deeply( $c->source('s')->{origins}, { git => 'project', local => 'user' }, 'origins per field' );
  ok( !exists $c->user_source('s')->{git}, 'the user scope never sees the project git' );
  is( $c->source_of( user => 's' )->{local}, '~/dev/s', 'source_of' );
  is( scalar @{ $c->sources_of('project') }, 2, 'sources_of' );
  is( $c->scope('project')->{wildcards}[0]{pattern}, '*', 'scope' );
  is( $c->check_interval, 1800, 'default interval' );
  is( $c->user_path, $t->{home}.'/.claude/skilletor.json', 'user path' );
  my $u = Skilletor::Config->load( home => $t->{home} );
  ok( !$u->has_project && !defined $u->project && !defined $u->project_path, 'user scope only' );
};

subtest 'unreadable file' => sub {
  plan skip_all => 'root reads everything' if $> == 0;
  my $t = SkilletorTest::home_with( user => {} );
  my $f = path( $t->{home}, '.claude', 'skilletor.json' );
  chmod 0000, "$f";
  is( error_of( sub { Skilletor::Config->load( home => $t->{home} ) } ),
    "$f: cannot read config (EACCES: permission denied, open '$f')", 'EACCES as Node words it' );
  chmod 0644, "$f";
  $f->remove;
  $f->mkpath;
  is( error_of( sub { Skilletor::Config->load( home => $t->{home} ) } ),
    "$f: cannot read config (EISDIR: illegal operation on a directory, read)", 'EISDIR' );
};

done_testing;
