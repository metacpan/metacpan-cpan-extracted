package SVL::OpenDHT;
use strict;
use warnings;
use base qw(Class::Accessor::Chained::Fast);
use Digest::MD5 qw(md5_base64);
use Net::OpenDHT;
__PACKAGE__->mk_accessors(qw(opendht));

sub new {
  my $class   = shift;
  my $self    = $class->SUPER::new();
  my $opendht = Net::OpenDHT->new();
  $opendht->application("svl");
  $self->opendht($opendht);
  return $self;
}

sub show {
  my ($self, $target) = @_;
  my $munged_target = $self->_munge($target);
  my @shares;
  foreach my $value ($self->opendht->fetch($munged_target)) {
    push @shares, SVL::Share->parse($value);
  }
  return @shares;
}

sub publish {
  my ($self, $shares) = @_;
  my $opendht = $self->opendht;
  foreach my $share (@$shares) {
    my $uuid = $share->uuid;
    my $dump = $share->dump;
    my @tags = @{ $share->tags };
    warn "opendht: $uuid or @tags\n";
    $opendht->put($self->_munge($uuid), $dump, 60);
    foreach my $tag (@tags) {
      $opendht->put($self->_munge($tag), $dump, 60);
    }
  }
}

# keys can only be 20 chars long, so we hash and substr and
# deal with collisions later
sub _munge {
  my ($self, $id) = @_;
  return 'svl:' . substr(md5_base64($id), 0, 16);
}

1;
