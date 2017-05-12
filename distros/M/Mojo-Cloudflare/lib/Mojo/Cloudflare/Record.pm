package Mojo::Cloudflare::Record;

=head1 NAME

Mojo::Cloudflare::Record - Represent a Cloudflare DNS record

=head1 DESCRIPTION

L<Mojo::Cloudflare::Record> represents a DNS record in the
L<Mojo::Cloudflare> module.

This module inherit from L<Mojo::JSON::Pointer>.

=cut

use Mojo::Base 'Mojo::JSON::Pointer';
use Mojo::JSON::Pointer;
use Mojo::UserAgent;

require Mojo::Cloudflare;

=head1 ATTRIBUTES

=head2 content

  $str = $self->content;
  $self = $self->content($str);

The content of the DNS record, will depend on the the type of record being
added.

This attribute is required to do anything useful with this object.

=head2 id

  $str = $self->id;

The identifier from Cloudflare. Can only be set in constructor.

=head2 name

  $str = $self->name;
  $self = $self->name($str);

Name of the DNS record.

This attribute is required to do anything useful with this object.

=head2 priority

  $int = $self->priority;
  $self = $self->priority($int);

MX record priority.

=head2 ttl

  $int = $self->ttl;
  $self = $self->ttl($int);

TTL of record in seconds. 1 (default) = Automatic, otherwise, value must in
between 120 and 86400 seconds.

=head2 service_mode

  $int = $self->service_mode;
  $self = $self->service_mode($int);

Status of CloudFlare Proxy:
1 = orange cloud (active),
0 = grey cloud (deactive).

=head2 type

  $str = $self->type;
  $self = $self->type($str);

Type of the DNS record: A, CNAME, MX, TXT, SPF, AAAA, NS, SRV, or LOC.

This attribute is required to do anything useful with this object.

=cut

for my $attr (qw( content name priority type )) {
  has $attr => sub { $_[0]->get("/$attr") || $_[0]->get("/obj/$attr") || "" };
}

sub id {
  $_[0]->{id} ||= $_[0]->get("/rec_id") || $_[0]->get("/obj/rec_id") || "";
}

has service_mode => '';
has ttl => sub { shift->data->{ttl} || 1 };

# Will be public once I know what to call the attribute
has _cf => sub { Mojo::Cloudflare->new };

=head1 METHODS

=head2 delete

  $self = $self->delete(sub { my($self, $err) = @_; ... });
  $self = $self->delete; # die $err on failure

Used to save delete record from Cloudflare.

=cut

sub delete {
  my ($self, $cb) = @_;

  $self->_cf->_post({a => 'rec_delete', id => $self->id, _class => $self}, $cb);
}

=head2 save

  $self = $self->save(sub { my($self, $err) = @_; ... });
  $self = $self->save; # die $err on failure

Used to save record to Cloudflare.

=cut

sub save {
  my $self = shift;
  return $self->id ? $self->_rec_edit(@_) : $self->_rec_new(@_);
}

sub _new_from_tx {
  my ($class, $tx) = @_;
  my $err = $tx->error;
  my $json = $tx->res->json || {};

  $json->{result} //= '';
  $err ||= $json->{msg} || $json->{result} || 'Unknown error.' if $json->{result} ne 'success';

  if (ref $class) {    # object instead of class
    my $obj = $json->{response}{rec}{obj} || {};
    for my $k (keys %$obj) {
      $class->data->{obj}{$k} = $obj->{$k};
      $class->$k($obj->{$k}) if $class->can($k);
    }
    return $err, $class;
  }
  else {
    return $err, $class->new($json->{response}{rec} || {});
  }
}

sub _rec_new {
  my ($self, $cb) = @_;
  my %args = map { ($_, $self->$_) } qw( content name ttl type );

  $args{_class} = $self;
  $args{a}      = 'rec_new';
  $args{prio}   = $self->priority if length $self->priority;

  return $self->_cf->_post(\%args, $cb);
}

sub _rec_edit {
  my ($self, $cb) = @_;
  my %args = map { ($_, $self->$_) } qw( content name ttl type );

  $args{_class}       = $self;
  $args{a}            = 'rec_edit';
  $args{id}           = $self->id or die "Cannot update record ($self->{name}) without 'id'";
  $args{prio}         = $self->priority if length $self->priority;
  $args{service_mode} = $self->service_mode ? 1 : 0 if length $self->service_mode;

  return $self->_cf->_post(\%args, $cb);
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
