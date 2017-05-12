package SolarBeam;
use Mojo::Base -base;

use Mojo::UserAgent;
use Mojo::Parameters;
use Mojo::URL;
use SolarBeam::Query;
use SolarBeam::Response;
use SolarBeam::Util 'escape';

our $VERSION = '0.04';

has ua            => sub { Mojo::UserAgent->new };
has default_query => sub { {} };

sub autocomplete {
  my $cb = pop;
  my ($self, $prefix, %options) = @_;
  my $postfix = delete $options{'-postfix'} || '\w+';

  $options{'regex.flag'} = 'case_insensitive';
  $options{'regex'}      = quotemeta($prefix) . $postfix;
  my $options = {terms => \%options, -endpoint => 'terms'};
  my $url = $self->_build_url($options);

  Mojo::IOLoop->delay(
    sub { $self->ua->get($url, shift->begin) },
    sub {
      my ($delay, $tx) = @_;
      $self->$cb(SolarBeam::Response->new->parse($tx));
    }
  );

  return $self;
}

sub new {
  my $self = shift->SUPER::new(@_);
  $self->url($self->{url}) if $self->{url};
  $self;
}

sub search {
  my $cb = pop;
  my ($self, $query, %options) = @_;
  my $options = \%options;
  my $page    = $options->{page};

  $options->{-query} = $query;
  my $url = $self->_build_url($options);
  my $q   = $url->query;
  $url->query(Mojo::Parameters->new);

  Mojo::IOLoop->delay(
    sub { $self->ua->post($url, form => $q->to_hash, shift->begin) },
    sub {
      my ($delay, $tx) = @_;
      my $res = SolarBeam::Response->new->parse($tx);

      if ($page && !$res->error) {
        $res->pager->current_page($page);
        $res->pager->entries_per_page($options->{rows});
      }

      $self->$cb($res);
    }
  );

  return $self;
}

sub url {
  my $self = shift;
  return $self->{url} ||= Mojo::URL->new('http://localhost:8983/solr') unless @_;
  $self->{url} = Mojo::URL->new(shift);
  return $self;
}

sub _build_hash {
  my ($self, %fields) = @_;
  my @query;

  for my $field (keys %fields) {
    my $val = $fields{$field};
    my @vals = ref($val) eq 'ARRAY' ? @{$val} : $val;
    push @query, join(' OR ', map { $field . ':(' . escape($_) . ')' } @vals);
  }

  return '(' . join(' AND ', @query) . ')';
}

sub _build_query {
  my ($self, $query) = @_;

  my $type = ref($query);
  if ($type eq 'HASH') {
    $self->_build_hash(%{$query});
  }
  elsif ($type eq 'ARRAY') {
    my ($raw, @params) = @$query;
    $raw =~ s|%@|escape(shift @params)|ge;
    my %params = @params;
    $raw =~ s|%([a-z]+)|escape($params{$1})|ge;
    $raw;
  }
  else {
    $query;
  }
}

sub _build_url {
  my ($self, $options) = @_;
  my $endpoint = delete $options->{-endpoint};
  my $query    = delete $options->{-query};
  my $url      = $self->url->clone;

  $url->path($endpoint || 'select');
  $url->query(q => $self->_build_query($query)) if $query;
  $url->query($self->default_query);
  $url->query({wt => 'json'});

  if ($options->{page}) {
    $self->_handle_page($options->{page}, $options);
  }

  if ($options->{fq}) {
    $self->_handle_fq($options->{fq}, $options);
  }

  if ($options->{facet}) {
    $self->_handle_facet($options->{facet}, $options);
  }

  if ($options->{terms}) {
    $self->_handle_nested_hash('terms', $options->{terms}, $options);
  }

  $url->query($options);

  return $url;
}

sub _handle_fq {
  my ($self, $fq, $options) = @_;

  if (ref($fq) eq 'ARRAY') {
    my @queries = map { $self->_build_query($_) } @{$fq};
    $options->{fq} = \@queries;
  }
  else {
    $options->{fq} = $self->_build_query($fq);
  }
  return;
}

sub _handle_facet {
  my ($self, $facet, $options) = @_;
  $self->_handle_nested_hash('facet', $facet, $options);
}

sub _handle_nested_hash {
  my ($self, $prefix, $content, $options) = @_;
  my $type = ref $content;

  if ($type eq 'HASH') {
    $content->{-value} or $content->{-value} = 'true';

    for my $key (keys %{$content}) {
      my $name = $prefix;
      $name .= '.' . $key if $key ne '-value';
      $self->_handle_nested_hash($name, $content->{$key}, $options);
    }
  }
  else {
    $options->{$prefix} = $content;
  }
}

sub _handle_page {
  my ($self, $page, $options) = @_;
  die "You must provide both page and rows" unless $options->{rows};
  $options->{start} = ($page - 1) * $options->{rows};
  return delete $options->{page};
}

1;

=encoding utf8

=head1 NAME

SolarBeam - Async Solr search driver

=head1 VERSION

0.04

=head1 SYNOPSIS

    use SolarBeam;
    my $solr = SolarBeam->new;
    $solr->search(...);

=head1 DESCRIPTION

Interface to acquire Solr index engine connections.

L<SolarBeam> is currently EXPERIMENTAL.

=head1 ATTRIBUTES

L<SolarBeam> implements the the following attributes.

=head2 ua 

    $ua = $self->ua
    $self = $self->ua(Mojo::UserAgent->new);

A L<Mojo::UserAgent> compatible object.

=head2 url

  $url = $self->url;

Solr endpoint as a L<Mojo::URL> object. Note that passing in L</url> as a
string to L</new> also works.

=head2 default_query

A hashref with default parameters used for every query.

=head1 METHODS

=head2 new

  $self = SolarBeam->new(%attributes);

Object constructor.

=head2 search

  $self = $self->search($query, [%options], sub { my ($self, $res) = @_; });

Used to search for data in Solr. C<$res> is a L<SolarBeam::Response> object.

Example C<$query>:

=over 2

=item * Hash

  $self->search({surname => q("Thorsen"), age => [33, 34]});

The query above will result in this Solr query:

  (surname:("Thorsen") AND age:(33) OR age:(34))

=item * String

  $self->search("active:1");

The query above will result in this Solr query:

  active:1

=back

C<%options> can hold Solr query parameters and some special instuctions
to this module, such a "page" and "rows".

=over 2

=item * page

Used to calculate the offset together with L</rows>. Will also be used to set
L<Data::Page> attributes in L<SolarBeam::Response/pager>:

  $res->pager->current_page($page);

=item * rows

Used to calculate the offset together with L</page>. Will also be used to set
L<Data::Page> attributes in L<SolarBeam::Response/pager>:

  $res->pager->entries_per_page($rows);

=back

=head2 autocomplete

    $self = $self->autocomplete($prefix, [%options], sub { my ($self, $res) = @_; });

TODO.

C<$res> is a L<SolarBeam::Response> object.

C<%options> can be:

=over 2

=item * -postfix   - defaults to \w+

=item * regex.flag -

=item * regex      -

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016, Magnus Holm

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Magnus Holm - C<judofyr@gmail.com>

Jan Henning Thorsen - C<jhthorsen@cpan.org>

Nicolas Mendoza - C<mendoza@pvv.ntnu.no>

=cut
