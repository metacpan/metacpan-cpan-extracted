package SkilletorTest;
# ABSTRACT: Shared helpers of the Skilletor tests

use strict;
use warnings;

use Exporter qw( import );
use IO::Compress::Gzip ();
use IO::Socket::INET ();
use POSIX ();
use Path::Tiny qw( path tempdir );
use Test::More ();
use Skilletor::FSUtil qw( encode_text );
use Skilletor::JSON qw( js_stringify );
use SkilletorTest::Server;

our @EXPORT_OK = qw( error_of write_json home_with git_ok git_out make_repo commit_files clean_git_env bare_remote make_tar gzip_bytes pax_path serve_http );

# Test output is UTF-8: names and messages carry non-ASCII.
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

# A test never runs git against a repository an exported variable names, and never asks for
# credentials; it has its own identity.
sub clean_git_env {
  delete @ENV{qw(
    GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
    GIT_COMMON_DIR GIT_PREFIX GIT_CONFIG GIT_CEILING_DIRECTORIES HERMES_HOME CODEX_HOME CLAUDE_PLUGIN_ROOT
  )};
  $ENV{GIT_TERMINAL_PROMPT} = '0';
  $ENV{GIT_AUTHOR_NAME}     = $ENV{GIT_COMMITTER_NAME}  = 'Skilletor Test';
  $ENV{GIT_AUTHOR_EMAIL}    = $ENV{GIT_COMMITTER_EMAIL} = 'test@example.invalid';
  $ENV{GIT_CONFIG_NOSYSTEM} = '1';
  $ENV{GIT_CONFIG_GLOBAL}   = '/dev/null';
}
clean_git_env();

# The message of the error a code ref throws; undef when it does not.
sub error_of {
  my ( $code ) = @_;
  local $@;
  return undef if eval { $code->(); 1 };
  my $err = $@;
  return ref $err && $err->can('message') ? $err->message : "$err";
}

# Write a value as JSON (a string as is) to a file, making its directory.
sub write_json {
  my ( $file, $value ) = @_;
  my $f = path($file);
  $f->parent->mkpath;
  $f->spew_raw( encode_text( ref $value ? js_stringify( $value, 2 )."\n" : $value ) );
  return $f;
}

# A temp home (and project) with config files: home_with( user => {...}, project => {...}, local => {...} ).
sub home_with {
  my ( %files ) = @_;
  my $root    = tempdir;
  my $home    = $root->child('home');
  my $project = $root->child('project');
  $home->child('.claude')->mkpath;
  $project->child('.claude')->mkpath;
  write_json( $home->child( '.claude', 'skilletor.json' ), $files{user} ) if exists $files{user};
  write_json( $project->child( '.claude', 'skilletor.json' ), $files{project} ) if exists $files{project};
  write_json( $project->child( '.claude', 'skilletor.local.json' ), $files{local} ) if exists $files{local};
  return { root => $root, home => "$home", project => "$project" };
}

sub _run_git {
  my ( $dir, @args ) = @_;
  my $pid = open( my $fh, '-|' ) // die 'fork: '.$!;
  if ( !$pid ) {
    open STDERR, '>&', \*STDOUT;
    chdir $dir or die 'chdir '.$dir.': '.$!;
    exec { 'git' } 'git', @args;
    die 'exec git: '.$!;
  }
  local $/;
  my $out = <$fh>;
  close $fh;
  return ( $? >> 8, $out // '' );
}

sub git_ok {
  my ( $dir, @args ) = @_;
  my ( $code, $out ) = _run_git( $dir, @args );
  die 'git '.join( ' ', @args ).' failed in '.$dir.': '.$out if $code;
  return $out;
}

sub git_out {
  my ( $dir, @args ) = @_;
  ( my $out = git_ok( $dir, @args ) ) =~ s/\s+\z//;
  return $out;
}

# A fresh repo (branch main) at $dir with one commit of %files.
sub make_repo {
  my ( $dir, %files ) = @_;
  path($dir)->mkpath;
  git_ok( $dir, 'init', '-q', '-b', 'main' );
  commit_files( $dir, 'initial', %files );
  return $dir;
}

# A bare remote at file:// plus a work tree pushing to it: { url, bare, work, commit, tag, branch }.
sub bare_remote {
  my ( $root ) = @_;
  my $bare = path($root)->child('bare.git');
  my $work = path($root)->child('work');
  git_ok( "$root", 'init', '-q', '-b', 'main', '--bare', "$bare" );
  $work->mkpath;
  git_ok( "$work", 'init', '-q', '-b', 'main' );
  my $url = 'file://'.$bare->realpath;
  my %r = ( url => $url, bare => "$bare", work => "$work" );
  $r{commit} = sub {
    my ( $files, $msg ) = @_;
    $files = { 'file.txt' => $files } unless ref $files;
    my $sha = commit_files( "$work", $msg // 'commit', %$files );
    git_ok( "$work", 'push', '-q', $url, 'main' );
    return $sha;
  };
  $r{tag} = sub {
    my ( $name, $annotated ) = @_;
    git_ok( "$work", 'tag', ( $annotated ? ( '-a', '-m', $name ) : () ), $name );
    git_ok( "$work", 'push', '-q', $url, $name );
  };
  # The remote goes away (renamed: a detached git maintenance may still be writing in it).
  $r{gone} = sub { rename "$bare", "$bare.gone" or die 'rename '.$bare.': '.$! };
  $r{branch} = sub {
    my ( $name ) = @_;
    git_ok( "$work", 'branch', $name );
    git_ok( "$work", 'push', '-q', $url, $name );
  };
  return \%r;
}

# A tar of entries { name, data?, type? ('0' file, '5' dir, '2' symlink, '1' hardlink, 'L', 'x'),
# mode?, prefix?, size? (raw field text) }, ended by two zero blocks.
sub make_tar {
  my ( @entries ) = @_;
  my $out = '';
  for my $e (@entries) {
    my $data = $e->{data} // '';
    my $type = $e->{type} // '0';
    my $h = pack( 'a100', $e->{name} )
      .pack( 'a8', $e->{mode_field} // sprintf( '%07o', $e->{mode} // ( $type eq '5' ? 0755 : 0644 ) ) )
      .pack( 'a8', '0000000' ).pack( 'a8', '0000000' )
      .pack( 'a12', $e->{size} // sprintf( '%011o', length $data ) )
      .pack( 'a12', '00000000000' )
      .'        '
      .$type
      .pack( 'a100', $e->{linkname} // '' )
      ."ustar\0".'00'
      .pack( 'a32', 'u' ).pack( 'a32', 'g' )
      .pack( 'a8', '' ).pack( 'a8', '' )
      .pack( 'a155', $e->{prefix} // '' );
    $h .= "\0" x ( 512 - length $h );
    my $sum = 0;
    $sum += $_ for unpack 'C*', $h;
    substr( $h, 148, 8 ) = sprintf( "%06o\0 ", $sum );
    $out .= $h.$data.( "\0" x ( ( 512 - length($data) % 512 ) % 512 ) );
  }
  return $out.( "\0" x 1024 );
}

sub gzip_bytes {
  my ( $bytes ) = @_;
  my $out;
  IO::Compress::Gzip::gzip( \$bytes => \$out, Minimal => 1 ) or die $IO::Compress::Gzip::GzipError;
  return $out;
}

# A pax extended header entry setting `path`.
sub pax_path {
  my ( $p ) = @_;
  my $rec = ' path='.$p."\n";
  my $len = length($rec) + 1;
  $len++ while length( $len.$rec ) != $len;
  return { name => 'PaxHeader', type => 'x', data => $len.$rec };
}

# An HTTP server on 127.0.0.1 in a child process, answering from route files:
# $srv->route( '/a.tgz', { status => 200, headers => { etag => '"1"' }, body => $bytes } ).
# Every request is logged; $srv->requests returns [ { method, path, headers } ].
sub serve_http {
  my $dir = tempdir;
  my $listen = IO::Socket::INET->new( LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 16, ReuseAddr => 1 )
    or die 'listen: '.$!;
  my $port = $listen->sockport;
  my $pid = fork // die 'fork: '.$!;
  if ( !$pid ) {
    while ( my $c = $listen->accept ) {
      local $/ = "\r\n";
      my $line = <$c> // next;
      my ( $method, $target ) = $line =~ /\A(\S+) (\S+)/;
      my %h;
      while ( my $l = <$c> ) {
        last if $l eq "\r\n";
        $h{ lc $1 } = $2 if $l =~ /\A([^:]+):\s*(.*?)\r\n\z/;
      }
      path( $dir, 'log' )->append_raw( js_stringify( { method => $method, path => $target, headers => \%h } )."\n" );
      ( my $key = $target ) =~ s/[^A-Za-z0-9]/_/g;
      my $route = path( $dir, 'route'.$key );
      my $r = $route->exists ? Skilletor::JSON::js_parse( $route->slurp_utf8 ) : { status => 404, headers => {}, body_hex => '' };
      my $body = pack 'H*', $r->{body_hex};
      my $status = ( ref $r->{status_for} && $h{'if-none-match'} && exists $r->{status_for}{ $h{'if-none-match'} } )
        ? $r->{status_for}{ $h{'if-none-match'} } : $r->{status};
      $body = '' if $status == 304;
      my $head = 'HTTP/1.1 '.$status." X\r\n";
      $head .= $_.': '.$r->{headers}{$_}."\r\n" for sort keys %{ $r->{headers} };
      $head .= 'Content-Length: '.length($body)."\r\nConnection: close\r\n\r\n";
      print {$c} $head.( $method eq 'HEAD' ? '' : $body );
      close $c;
    }
    POSIX::_exit(0);
  }
  close $listen;
  return SkilletorTest::Server->new( dir => $dir, port => $port, pid => $pid );
}

sub commit_files {
  my ( $dir, $message, %files ) = @_;
  for my $name ( sort keys %files ) {
    my $f = path($dir)->child($name);
    $f->parent->mkpath;
    $f->spew_raw( $files{$name} );
  }
  git_ok( $dir, 'add', '-A' );
  git_ok( $dir, 'commit', '-q', '--allow-empty', '-m', $message );
  return git_out( $dir, 'rev-parse', 'HEAD' );
}

1;
