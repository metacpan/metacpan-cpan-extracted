package Neo4p::Test;
use REST::Neo4p;
use Scalar::Util qw/looks_like_number/;
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
  bless {
    uuid => $uuid
   }, $class;
}
sub uuid {shift->{uuid}}
sub lbl {"N".shift->{uuid}}
sub agent {REST::Neo4p->agent}

sub create_sample {
  my $self = shift;
  die "No connection"  unless REST::Neo4p->connected;
  my @node_objs;
  foreach (@nodes) {
    $_->{uuid} = $self->uuid;
    push @node_objs, REST::Neo4p::Node->new($_);
    $node_objs[-1]->set_labels($self->lbl);
  }
  foreach (@relns) {
    my ($n1, $n2, $type) = @$_;
    my $r = $node_objs[$n1]->relate_to( $node_objs[$n2],
					$type, {
					  uuid => $self->uuid,
					  hash => "$n1$n2$type"
					 }); 
  }
  return 1;
}

sub find_sample {
  my $self = shift;
  my ($k,$v) = @_;
  $v+=0 if looks_like_number $v;
  my $lbl = $self->lbl;
  my $q = REST::Neo4p::Query->new("MATCH (n:$lbl) where n.$k = \$value return n");
  $q->execute({value => $v});
  my @ret;
  while (my $r = $q->fetch) {
    push @ret, $r->[0];
  }
  return @ret;
}

sub delete_sample {
  my $self = shift;
  die "No connection"  unless REST::Neo4p->connected;
  my $lbl = $self->lbl;
  my $q = REST::Neo4p::Query->new("match (n:$lbl) where n.uuid = \$uuid detach delete n",{uuid => $self->uuid});
  $q->execute();
  return 1;
}

sub DESTROY {
  my $self = shift;
  eval {
    $self->delete_sample;
  };
}
1;
