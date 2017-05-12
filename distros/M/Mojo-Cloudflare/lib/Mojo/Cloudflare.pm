package Mojo::Cloudflare;

=head1 NAME

Mojo::Cloudflare - Talk with the Cloudflare API using Mojo::UserAgent

=head1 VERSION

0.04

=head1 DESCRIPTION

L<Mojo::Cloudflare> is an (async) client for the
L<CloudFlare API|http://www.cloudflare.com/docs/client-api.html>.

=head1 SYNOPSIS

  use Mojo::Cloudflare;
  my $cf = Mojo::Cloudflare->new(
             email => 'sample@example.com',
             key => '8afbe6dea02407989af4dd4c97bb6e25',
             zone => 'example.com',
           );

  # add a record
  $cf->record({
    content => 'mojolicio.us',
    name => 'direct.example.pm',
    type => 'CNAME',
  })->save;

  # retrieve and update records
  for my $record ($cf->records->all) {
    warn $record->name;
    $record->ttl(1)->save; # update a record
  }

  # update a record
  $cf->record({
    content => 'mojolicio.us',
    id => 'some_id_fom_cloudflare', # <-- cause update instead of insert
    name => 'direct.example.pm',
    type => 'CNAME',
  })->save;

=cut

use Mojo::Base -base;
use Mojo::JSON::Pointer;
use Mojo::UserAgent;
use Mojo::Cloudflare::Record;
use Mojo::Cloudflare::RecordSet;

our $VERSION = '0.04';

=head1 ATTRIBUTES

=head2 api_url

Holds the endpoint where we communicate. Default is
L<https://www.cloudflare.com/api_json.html>.

=head2 email

  $str = $self->email;
  $self = $self->email($str);

The e-mail address associated with the API key.

=head2 key

  $str = $self->key;
  $self = $self->key($str);

This is the API key made available on your Account page.

=head2 zone

  $str = $self->zone;
  $self = $self->zone($str);

The zone (domain) to act on.

=cut

has api_url => 'https://www.cloudflare.com/api_json.html';
has email   => '';
has key     => '';
has zone    => '';
has _ua     => sub { Mojo::UserAgent->new };

=head1 METHODS

=head2 add_record

Will be deprecated. Use L<Mojo::Cloudflare::Record/save> instead.

=cut

sub add_record {
  my ($self, $args, $cb) = @_;
  my %args;

  %args = map { ($_, $args->{$_}); } grep { defined $args->{$_}; } qw( type name content ttl );

  $args{_class} = 'Mojo::Cloudflare::Record';
  $args{a}      = 'rec_new';
  $args{prio}   = $args->{priority} if defined $args->{priority};
  $args{ttl} ||= 1;

  return $self->_post(\%args, $cb);
}

=head2 delete_record

Will be deprecated. Use L<Mojo::Cloudflare::Record/delete> instead.

=cut

sub delete_record {
  my ($self, $id, $cb) = @_;

  $self->_post({a => 'rec_delete', id => $id, _class => 'Mojo::Cloudflare::Record'}, $cb,);
}

=head2 edit_record

Will be deprecated. Use L<Mojo::Cloudflare::Record/save> instead.

=cut

sub edit_record {
  my ($self, $args, $cb) = @_;
  my %args;

  %args = map { ($_, $args->{$_}); } grep { defined $args->{$_}; } qw( id type name content ttl );

  $args{_class}       = 'Mojo::Cloudflare::Record';
  $args{a}            = 'rec_edit';
  $args{prio}         = $args->{priority} if defined $args->{priority};
  $args{service_mode} = $args->{service_mode} ? 1 : 0 if defined $args->{service_mode};

  return $self->_post(\%args, $cb);
}

=head2 record

  $record_obj = $self->record(\%record_construction_args);

Returns a L<Mojo::Cloudflare::Record> object.

=cut

sub record {
  my $self = shift;
  my $args = @_ ? @_ > 1 ? {@_} : $_[0] : {};
  my $obj  = Mojo::Cloudflare::Record->new({});
  $obj->$_($args->{$_}) for grep { $obj->can($_) } keys %$args;
  Scalar::Util::weaken($obj->_cf($self)->{_cf});
  $obj;
}

=head2 records

  $records_obj = $self->records($offset);
  $self = $self->records($offset, sub {
            my($self, $err, $records_obj) = @_;
          });

Used to retrieve L<Mojo::Cloudflare::Record> objects. The return value will
be a L<Mojo::Cloudflare::RecordSet> object.

C<$offset> is optional and defaults to "all", which will retrieve all the DNS
records instead of the limit of 180 set by CloudFlare.

=cut

sub records {
  my ($self, $offset, $cb) = @_;

  if (ref $offset eq 'CODE') {
    $cb     = $offset;
    $offset = 'all';
  }

  if (!defined $offset or $offset eq 'all') {
    my $record_set = Mojo::Cloudflare::RecordSet->new({count => 0, has_more => undef, objs => []});
    Scalar::Util::weaken($record_set->_cf($self)->{_cf});
    return $cb ? $self->_all_records_nb($record_set, $cb) : $self->_all_records($record_set);
  }
  else {
    return $self->_post({a => 'rec_load_all', o => $offset, _class => 'Mojo::Cloudflare::RecordSet'}, $cb);
  }
}

sub _all_records {
  my ($self, $record_set) = @_;
  my $has_more = 1;
  my $offset   = 0;

  while ($has_more) {
    my $json = $self->_post({a => 'rec_load_all', o => $offset, _class => 'Mojo::Cloudflare::RecordSet'});

    $record_set->data->{count} += $json->get('/count');
    push @{$record_set->data->{objs}}, @{$json->get('/objs') || []};
    $has_more = $json->get('/has_more');
    $offset += $has_more ? $json->get('/count') : 0;
  }

  return $record_set;
}

sub _all_records_nb {
  my ($self, $record_set, $cb) = @_;
  my $offset = 0;
  my $retriever;

  $retriever = sub {
    my ($self, $err, $json) = @_;
    my $offset;

    return $self->$cb($err, $record_set) if $err;

    $offset += $json->get('/count');
    $record_set->data->{count} = $offset;
    push @{$record_set->data->{objs}}, @{$json->get('/objs') || []};

    return $self->$cb('', $record_set) unless $json->get('/has_more');
    return $self->_post({a => 'rec_load_all', o => $offset, _class => 'Mojo::Cloudflare::RecordSet'}, $retriever);
  };

  $self->_post({a => 'rec_load_all', _class => 'Mojo::Cloudflare::RecordSet'}, $retriever);
}

sub _post {
  my ($self, $data, $cb) = @_;
  my $class = delete $data->{_class};

  $data->{a} or die "Internal error: Unknown action";
  $data->{email} ||= $self->email;
  $data->{tkn}   ||= $self->key;
  $data->{z} = $self->zone if $data->{a} =~ /^rec/;

  unless ($cb) {
    my $tx = $self->_ua->post($self->api_url, form => $data);
    my ($err, $obj) = $class->_new_from_tx($tx);

    die $err if $err;
    Scalar::Util::weaken($obj->_cf($self)->{_cf});
    return $obj;
  }

  Scalar::Util::weaken($self);
  $self->_ua->post(
    $self->api_url,
    form => $data,
    sub {
      my ($err, $obj) = $class->_new_from_tx($_[1]);

      Scalar::Util::weaken($obj->_cf($self)->{_cf});
      $self->$cb($err, $obj);
    },
  );

  return $self;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
