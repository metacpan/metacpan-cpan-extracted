# $Source: /Users/clajac/cvsroot//Scripting/Scripting/Loader.pm,v $
# $Author: clajac $
# $Date: 2003/07/21 07:33:21 $
# $Revision: 1.5 $

package Scripting::Loader;
use Carp qw(croak carp);
use IO::Dir;
use IO::File;
use File::Spec;
use Digest::SHA1 qw(sha1);
use File::Find::Rule qw(find);
use Scripting::Event qw(:constants);

use strict;

my %Engine;
my %Engine_Loaded;
my @Allow;

# Find available engines
BEGIN {
  my ($path) = __FILE__ =~ /^(.*)Loader\.pm$/;
  
  %Engine = map { 
    (/(\w+)\.pm/)[0] => $_ 
  } find(file => name => "*.pm", in => File::Spec->catfile($path, "Engine"));
}

sub allow {
  my ($pkg, $allow) = @_;

  die "Argument must be string or ARRAY reference\n" if(ref $allow && ref $allow ne 'ARRAY');
  unless(ref $allow) {
    my @allow = split/\s+/,$allow;
    $allow = \@allow;
  }

  for (@$allow) {
    die "Type '$_' not supported\n" unless(exists $Engine{$_});
  }

  @Allow = @$allow;
}

sub load {
  my ($pkg, $paths) = @_;

  die "Argument must be a string or ARRAY reference\n" if(ref $paths && ref $paths ne 'ARRAY');
  $paths = [$paths] unless(ref $paths);

  my @files = find(file => name => [map { "*.$_" } @Allow], in => $paths);
  foreach (@files) {
    Scripting::Loader->load_file($_);
  }
}

sub load_file {
  my ($pkg, $path) = @_;

  $path = File::Spec->rel2abs($path);

  my @parts = File::Spec->splitdir($path);

  my $file = pop @parts;
  my $ns = pop @parts;

  $ns = "_Global" unless(Scripting::Expose->has_namespace($ns));
  my ($event, $engine) = $file =~ /^(.*)\.(\w+)$/;

  _load_engine($engine);

  my $file = IO::File->new($path, "r") || die $!;
  my $source = join "", $file->getlines;
  $file->close();
  
  my $digest = sha1($source);
  warn "Script '$path' doesn't match signed signature'\n" unless(Scripting::Security->match($path, $digest));

  my $cb = "Scripting::Engine::$engine"->load($path, $ns, $source);

  if(Scripting::Event->has_event($ns, $event)) {
    Scripting::Event->remove_event($ns, $event);
  }

  Scripting::Event->add_event($ns, $event, $cb);
}

sub _load_engine {
  my ($engine) = @_;

  if(exists $Engine{$engine}) {
    unless(exists $Engine_Loaded{$engine}) {
      require $Engine{$engine};
      $Engine_Loaded{$engine} = 1;
    }
  }
}

1;
