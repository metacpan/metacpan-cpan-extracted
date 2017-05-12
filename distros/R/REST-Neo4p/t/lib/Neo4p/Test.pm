package Neo4p::Test;
use REST::Neo4p;
use strict;
use warnings;

my $uuid = '925bd263_e369_4fc0_8e33_ea50d616358b';
my @nodes = (
  { name => 'I' },
  { name => 'you' },
  { name => 'he' }, 
  { name => 'she'},
  { name => 'it'}
);

my @relns = (
  [qw/0 1 bosom/],
  [qw/0 1 best/],
  [qw/1 0 best/],
  [qw/2 3 umm/],
  [qw/3 4 fairweather/],
  [qw/3 0 good/]
);


sub new {
  my $class = shift;
  my ($db,$user,$pass) = @_;
  unless (REST::Neo4p->connected) {
    eval {
      REST::Neo4p->agent->credentials($db,'',$user,$pass) if defined $user;
      REST::Neo4p->connect($db);
    };
    if (my $e = Exception::Class->caught) {
      warn (ref $e ? ref($e).":".$e->message : $@);
      return;
    }
  }
  my $nix = REST::Neo4p->get_index_by_name("N$uuid", 'node') ||
    REST::Neo4p::Index->new( node => "N$uuid" );
  my $rix = REST::Neo4p->get_index_by_name("R$uuid", 'node') ||
    REST::Neo4p::Index->new( relationship => "R$uuid" );
  bless {
    nix => $nix,
    rix => $rix,
    uuid => $uuid
   }, $class;
}
sub nix {shift->{nix}}
sub rix {shift->{rix}}
sub uuid {shift->{uuid}}
sub agent {REST::Neo4p->agent}

sub create_sample {
  my $self = shift;
  die "No connection"  unless REST::Neo4p->connected;
  my @node_objs;
  foreach (@nodes) {
    $_->{uuid} = $uuid; # add uniquifier
    push @node_objs, 
      my $n = $self->nix->create_unique( name => $_->{name}, $_);
  }
  foreach (@relns) {
    my ($n1, $n2, $type) = @$_;
#    my $r = $node_objs[$n1]->relate_to( $node_objs[$n2], $type, {hash => "$n1$n2$type"});
#    $self->rix->add_entry($r, hash => "$n1$n2$type");
    $self->rix->create_unique( hash => "$n1$n2$type",
			       $node_objs[$n1] => $node_objs[$n2], $type);
  }
  return 1;
}

sub delete_sample {
  my $self = shift;
  die "No connection"  unless REST::Neo4p->connected;
  my @r = $self->rix->find_entries("hash:*");
  my @n = $self->nix->find_entries("name:*");
  $_->remove for @r, @n;
  $self->nix->remove;
  $self->rix->remove;
  return 1;
}

sub DESTROY {
  my $self = shift;
  eval {
    $self->delete_sample;
  };
}
1;
