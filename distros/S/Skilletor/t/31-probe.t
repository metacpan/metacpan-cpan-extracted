#!/usr/bin/env perl
# Skilletor::Probe, the probe `add` asks a generic host with (the reference's probe.ts), and add's
# use of a probe – what conformance/ cannot pin: its cases have no TLS server, so the HEAD on
# the tarball never answers there. Here it runs against a local HTTP server (the probe sends a
# HEAD to whatever URL it is given; the spec always gives https://), git against file:// repos.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of git_ok home_with make_repo serve_http );

use Cwd ();
use IO::Socket::INET;
use Path::Tiny qw( path tempdir );
use Time::HiRes ();
use Skilletor::Commands;
use Skilletor::Engine;
use Skilletor::FSUtil qw( read_text );
use Skilletor::JSON qw( js_parse js_stringify );
use Skilletor::Probe qw( make_probe );

my $srv = serve_http();
my $tmp = tempdir;
my $repo = make_repo( "$tmp/repo", 'skills/foo/SKILL.md' => "---\nname: foo\n---\n" );
my $repo_url = 'file://'.Cwd::realpath($repo);
my $probe = make_probe();

# What git and HEAD requests the server saw for a path prefix.
sub heads_of {
  my ( $prefix ) = @_;
  return [ grep { $_->{method} eq 'HEAD' && index( $_->{path}, $prefix ) == 0 } @{ $srv->requests } ];
}

subtest 'git answers: a git source, no HEAD asked' => sub {
  is_deeply( $probe->($repo_url), { git => 1 }, 'a repository' );
  my $missing = 'file://'.Cwd::realpath("$tmp").'/missing';
  is_deeply( $probe->($missing), {}, 'no repository and no http(s) tarball: neither' );
};

subtest 'git does not answer: a HEAD on <url>.tar.gz, as fetch sends it' => sub {
  $srv->route( '/team.tar.gz', { status => 200 } );
  is_deeply( $probe->( $srv->url('/team') ), { tarball => 1 }, '200: a tarball' );
  my $heads = heads_of('/team.tar.gz');
  is( scalar @$heads, 1, 'one HEAD' );
  my %h = %{ $heads->[0]{headers} };
  is_deeply(
    { map { ( $_ => $h{$_} ) } qw( user-agent accept accept-language sec-fetch-mode accept-encoding ) },
    { 'user-agent' => 'node', accept => '*/*', 'accept-language' => '*', 'sec-fetch-mode' => 'cors', 'accept-encoding' => 'gzip, deflate' },
    "fetch's headers"
  );

  $srv->route( '/moved.tar.gz', { status => 302, headers => { Location => $srv->url('/there.tar.gz') } } );
  $srv->route( '/there.tar.gz', { status => 204 } );
  is_deeply( $probe->( $srv->url('/moved') ), { tarball => 1 }, 'a redirect followed to a 2xx: a tarball' );
  is( scalar @{ heads_of('/there.tar.gz') }, 1, 'the redirect asked with HEAD again' );

  $srv->route( '/gone.tar.gz', { status => 404 } );
  $srv->route( '/broken.tar.gz', { status => 500 } );
  is_deeply( $probe->( $srv->url('/gone') ),   {}, '404: neither' );
  is_deeply( $probe->( $srv->url('/broken') ), {}, '500: neither' );
};

subtest 'what fetch refuses to send is no answer, and never asked' => sub {
  $srv->route( '/cred.tar.gz', { status => 200 } );
  my $with = $srv->url('/cred') =~ s{\Ahttp://}{http://user:secret@}r;
  is_deeply( $probe->($with), {}, 'credentials in the URL: neither' );
  is( scalar @{ heads_of('/cred.tar.gz') }, 0, 'no HEAD sent' );
  is_deeply( $probe->('not a url'), {}, 'no URL at all: neither' );
};

subtest 'no git on the machine: the HEAD still answers' => sub {
  $srv->route( '/nogit.tar.gz', { status => 200 } );
  local $ENV{PATH} = "$tmp/no-such-bin";
  is_deeply( $probe->( $srv->url('/nogit') ), { tarball => 1 }, 'a tarball' );
};

subtest 'a host that never answers: neither, within the timeout' => sub {
  # Listening, never accepting: git and the HEAD connect and wait for an answer that never comes.
  my $mute = IO::Socket::INET->new( LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 16 ) or die "listen: $!";
  my $url = 'http://127.0.0.1:'.$mute->sockport.'/x';
  my $t0 = Time::HiRes::time();
  is_deeply( make_probe( timeout_ms => 300 )->($url), {}, 'neither' );
  my $took = Time::HiRes::time() - $t0;
  cmp_ok( $took, '<', 6, "ended by the timeouts (took ${took}s)" );
};

subtest 'an exported GIT_DIR does not steer the probe (k91)' => sub {
  my $victim = make_repo( "$tmp/victim", 'file.txt' => "v\n" );
  my $missing = 'file://'.Cwd::realpath("$tmp").'/elsewhere.git';
  git_ok( $victim, 'config', "url.$repo_url.insteadOf", $missing );
  local $ENV{GIT_DIR} = "$victim/.git";
  is_deeply( $probe->($missing), {}, "the victim's insteadOf is not read" );
  is_deeply( $probe->($repo_url), { git => 1 }, 'a real repository still answers' );
};

subtest 'add probes a generic host with the probe it is given' => sub {
  my $m = home_with();
  path( $m->{home}, '.claude.json' )->spew_raw("{}\n");
  my $engine = Skilletor::Engine->new( home => $m->{home}, project_dir => $m->{project}, codex_home => "$m->{home}/.codex",
    is_git_work_tree => sub { 0 }, git_tracked => sub { [] } );
  my $cfg = path( $m->{home}, '.claude', 'skilletor.json' );
  my @asked;
  my $answer = sub { my ( $a ) = @_; sub { push @asked, $_[0]; $a } };

  my $r = Skilletor::Commands::add( $engine, spec => 'skills.example.org/team', probe => $answer->( { tarball => 1 } ) );
  is_deeply( \@asked, ['https://skills.example.org/team'], 'the base URL asked' );
  is( js_stringify( $r->{def} ), '{"url":"https://skills.example.org/team.tar.gz"}', 'a tarball: a url source' );
  is( $r->{name}, 'skills-example-org', 'named after the host' );
  ok( !$r->{kept}, 'added' );

  $r = Skilletor::Commands::add( $engine, name => 'repo', spec => 'skills.example.org', probe => $answer->( { git => 1 } ) );
  is( js_stringify( $r->{def} ), '{"git":"https://skills.example.org/skills"}', 'git: a git source at the default repo' );
  is(
    read_text("$cfg"),
    qq({\n  "sources": {\n    "skills-example-org": {\n      "url": "https://skills.example.org/team.tar.gz"\n    },\n)
      .qq(    "repo": {\n      "git": "https://skills.example.org/skills"\n    }\n  }\n}\n),
    'both written'
  );
  my $trust = js_parse( read_text( path( $m->{home}, '.claude', 'skilletor', 'trust.json' ) ) );
  is_deeply(
    $trust,
    { 'skills-example-org' => { kind => 'url', address => 'https://skills.example.org/team.tar.gz' },
      repo => { kind => 'git', address => 'https://skills.example.org/skills' } },
    'both trusted'
  );

  my $before = read_text("$cfg");
  is(
    error_of( sub { Skilletor::Commands::add( $engine, name => 'none', spec => 'skills.example.org/x', probe => $answer->( {} ) ) } ),
    'cannot resolve "skills.example.org/x": neither https://skills.example.org/x (git) nor https://skills.example.org/x.tar.gz (tarball) responded',
    'neither: the spec refused'
  );
  is( read_text("$cfg"), $before, 'nothing written' );

  @asked = ();
  Skilletor::Commands::add( $engine, name => 'gh', spec => 'Getty/skills', probe => $answer->( {} ) );
  is_deeply( \@asked, [], 'a known forge is never probed' );
};

$srv->stop;
done_testing;
