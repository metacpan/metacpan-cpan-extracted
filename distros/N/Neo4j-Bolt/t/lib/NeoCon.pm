package NeoCon;
use v5.12;
use warnings;

use IPC::Run qw/run/;
use Carp qw/croak/;
use File::Spec;
use Cwd;

my $VERBOSE = $ENV{NEOCON_VERBOSE} // 0;
my $REUSE = $ENV{NEOCON_REUSE} // 1;
my $RETRIES = $ENV{NEOCON_RETRIES} // 3;

my ($in,$out,$err);
my $TAG = 'neo4j:3.5';
unless (eval 'require IO::Pty;1') {
  croak __PACKAGE__." requires IO::Pty - please install it"
}
unless (run ['docker'],\$in,\$out,\$err) {
  croak __PACKAGE__." requires docker - please install it"
}
# tag => <docker tag>
# name => <container name>
# ports => <hash of port mappings container => host>

sub new {
  my $class = shift;
  my %args = @_;
  my $self = bless \%args, $class;
  $self->{tag} //= $TAG;
  $self->{name} //= "test$$";
  $self->{ports} //= {7687 => undef, 7474 => undef, 7473 => undef};
  $self->{delay} //= 10;
  $self->{reuse} //= 1;
  $self->{load} //= undef;
  return $self;
}

sub error { shift->{_error} }
sub port { shift->{ports}{shift()} }
sub ports { shift->{ports} }
sub delay { shift->{delay} }
sub name { shift->{name} }
sub reuse { shift->{reuse} }
sub load { shift->{load} }
sub id { shift->{id} }

sub start {
  my $self = shift;
  my $pwd = getcwd();
  my @startcmd = split / /, "docker run -d -P --env NEO4J_AUTH=none -v $pwd:/import --name $$self{name} $$self{tag}";
  unless ($self->is_running && $self->reuse) {
    print STDERR "Starting docker $$self{tag} as $$self{name}" if $VERBOSE;
    unless (run \@startcmd, \$in, \$out, \$err) {
      $self->{_error} = $err;
      return;
    }
    print STDERR '*';
    sleep $self->delay;
    my $success;
    for (my $i=0;$i<$RETRIES;$i++) {
      if ( $success = run(['docker','exec', $self->name, '/bin/bash', '-c', 'cypher-shell'],\$in,\$out,\$err) ) {
	last;
      }
      else {
	print STDERR "*";
	sleep $self->delay;
      }
    }
    if (!$success) {
      $self->{_error} = "Failed to ping container after $RETRIES attempts\n";
      return;
    }
    print STDERR "\n";
  }
  if ($self->load) {
    run ['docker', 'exec', $self->name, '/bin/bash', '-c', "cypher-shell < ".File::Spec->catfile('/import',$self->load)], \$in, \$out,\$err;
    if ($err) {
      $self->{_error} = $err;
      return;
    }
    else {
      sleep $self->delay;
    }
  }
  $self->_get_ports;
  return 1;
}

sub stop {
  my $self = shift;
  print STDERR "Stopping docker container $$self{name}" if $VERBOSE;
  unless (run [split / /,"docker kill $$self{name}"], \$in,\$out,\$err) {
    $self->{_error} = $err;
    return;
  }
  return 1;
}

sub rm {
  my $self = shift;
  print STDERR "Removing docker container $$self{name}" if $VERBOSE;
  unless ( run [split / /, "docker rm $$self{name}"],\$in,\$out,\$err ) {
    $self->{_error} = $err;
    return;
  }
  return 1;
}

sub _get_ports {
  my $self = shift;
  return unless $self->name;
  run [split / /, "docker container port $$self{name}"], \$in, \$out, \$err;
  for my $port (keys %{$self->{ports}}) {
    my ($p) = grep /${port}.tcp/, split /\n/,$out;
    ($p) = $p =~ m/([0-9]+)$/;
    $self->{ports}{$port} = $p;
  }
  return 1;
}

sub is_running {
  my $self = shift;
  return unless $self->name;
  my %h;
  run [split / /, 'docker ps --format {{.ID}}\t{{.Names}}'], \$in, \$out, \$err;
  for (split /\n/,$out) {
    my @a = split /\t/;
    $h{$a[1]} = $a[0];
  }
  if ($h{$self->name}) {
   return $self->{id} = $h{$self->name};
  }
  else {
    return;
  }
}

sub DESTROY {
  my $self = shift;
  unless ($self->reuse) {
    $self->stop;
    $self->rm;
  }
  undef $self;
}
1;
