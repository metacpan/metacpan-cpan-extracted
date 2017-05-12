package SVL::Share;
use strict;
use warnings;
use Text::Tags::Parser;
use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_accessors(qw(host depot path port tags uuid));

sub url {
  my $self = shift;
  return 'svn://' . $self->host . ":" . $self->port . "/" . $self->depot . $self->path;
}

sub tags_as_string {
  my $self = shift;
  return Text::Tags::Parser->new->join_tags(@{ $self->tags });
}

sub dump {
  my $self = shift;
  return join ':', $self->uuid, $self->host, $self->port, $self->depot,
    $self->path, $self->tags_as_string;
}

sub parse {
  my($class, $text) = @_;
  my($uuid, $host, $port, $depot, $path, $tags) = split ':', $text, 6;
  return SVL::Share->new({
    uuid => $uuid,
    host => $host,
    port => $port,
    depot => $depot,
    path => $path,
    tags => [Text::Tags::Parser->new->parse_tags($tags)],
  })
}

1;
