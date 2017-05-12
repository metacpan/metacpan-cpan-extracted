package SolarBeam::Response;
use Mojo::Base -base;

use Data::Page;
use Mojo::JSON 'decode_json';
use Mojo::JSON::MaybeXS;
use Mojo::Util 'decamelize';

use constant DEBUG => $ENV{SOLARBEAM_DEBUG} || 0;

has docs => sub { +[] };
has error         => undef;
has facet_dates   => sub { +{} };
has facet_fields  => sub { +{} };
has facet_queries => sub { +{} };
has facet_ranges  => sub { +{} };
has num_found     => 0;
has pager         => sub { Data::Page->new };
has params        => sub { +{} };
has query_time    => 0;
has start         => 0;
has terms         => sub { +{} };

sub facet_fields_as_hashes {
  my $self = shift;

  return $self->{facet_fields_as_hashes} ||= do {
    my $facet_fields = $self->facet_fields;
    my %res;
    for my $k (keys %$facet_fields) {
      $res{$k} = {map { @$_{qw(value count)} } @{$facet_fields->{$k} || []}};
    }
    return \%res;
  };
}

sub parse {
  my ($self, $tx) = @_;
  my $res      = $tx->res;
  my $data     = $res->json || {};
  my $header   = $data->{responseHeader};
  my $response = $data->{response};
  my $facets   = $data->{facet_counts};
  my $terms    = $data->{terms};
  my $field;

  if ($data->{error}) {
    $self->error({code => $data->{error}{code} || $tx->res->code, message => $data->{error}{msg}});
    return $self;
  }

  if ($res->code and !$header) {
    my $dom = $res->dom;

    if ($dom and $dom->at('title')) {
      $self->error({code => $res->code, message => $dom->at('title')->text});
    }
    else {
      $self->error({code => $res->code, message => $res->body || 'Missing response headers.'});
    }
    return $self;
  }

  if ($tx->error) {
    $tx->error->{message} ||= 'Unknown error';
    $self->error($tx->error);
    return $self;
  }

  for $field (keys %$header) {
    my $method = decamelize ucfirst $field;
    $self->$method($header->{$field}) if $self->can($method);
  }

  for $field (keys %$response) {
    my $method = decamelize ucfirst $field;
    $self->$method($response->{$field}) if $self->can($method);
  }

  for $field (keys %$facets) {
    $self->$field($facets->{$field}) if $self->can($field);
  }

  my $ff = $self->facet_fields;
  if ($ff) {
    for $field (keys %$ff) {
      $ff->{$field} = $self->_build_count_list($ff->{$field});
    }
  }

  if ($self->facet_ranges) {
    for $field (keys %{$self->facet_ranges}) {
      my $range = $self->facet_ranges->{$field};
      $range->{counts} = $self->_build_count_list($range->{counts});
    }
  }

  if ($terms) {
    my $sane_terms = {};
    for $field (keys %$terms) {
      $sane_terms->{$field} = $self->_build_count_list($terms->{$field});
    }
    $self->terms($sane_terms);
  }

  if (!$self->error && $response) {
    $self->pager->total_entries($self->num_found);
  }

  $self;
}

sub _build_count_list {
  my ($self, $list) = @_;
  my @result = ();
  for (my $i = 1; $i < @$list; $i += 2) {
    push @result, {value => $list->[$i - 1], count => $list->[$i]};
  }
  return \@result;
}

1;

=encoding utf8

=head1 NAME

SolarBeam::Response - Represents a Solr search response

=head1 SYNOPSIS

 use SolarBeam::Response;
 my $tx = Mojo::UserAgent->new->post($solr_url, form => \%query);
 my $res = SolarBeam::Response->new->parse($tx);

 if ($res->error) {
    die sprintf "%s: %s", $res->error->{code} || 0, $res->error->{message};
 }

 for my $doc (@{$res->docs}) {
    say $doc->{surname};
 }

=head1 DESCRIPTION

L<SolarBeam::Response> holds the response from L<SolarBeam/autocomplete> or
L<SolarBeam/search>.

=head1 ATTRIBUTES

=head2 docs

  $array_ref = $self->docs;
  $self = $self->docs([{}, ...]);

Holds a list of the documents retrieved from Solr.

=head2 error

  $hash_ref = $self->error;
  $self = $self->error({message => "Error message", code => 500});

Holds either a hash-ref with error details or C<undef()> if no error is
detected. This attribute is modeled the same way as L<Mojo::Transaction/error>,
but can also contain detailed error messages from the Solr server.

=head2 facet_dates

  $hash_ref = $self->facet_dates;

TODO.

=head2 facet_fields

  $hash_ref = $self->facet_fields;

TODO.

=head2 facet_queries

  $hash_ref = $self->facet_queries;

TODO.

=head2 facet_ranges

  $hash_ref = $self->facet_ranges;

TODO.

=head2 num_found

  $int = $self->num_found;

Holds the number of matching documents. This number can be higher than the
number of elements in L</docs>.

=head2 pager

  $pager = $self->pager;
  $self = $self->pager(Data::Page->new);

Holds a L<Data::Page> object.

=head2 params

  $hash_ref = $self->params;

Holds the search params sent to Solr.

=head2 query_time

  $int = $self->query_time;

The time the search took.

=head2 start

  $int = $self->start;

Offset of the search result.

=head2 terms

    $hash_ref = $self->terms;

TODO

=head1 METHODS

=head2 facet_fields_as_hashes

    $hash_ref = $self->facet_fields_as_hashes;

Turns the arrays in L</facet_fields> into hashes instead. Example:

    $self->facet_fields = {colors => [{value => "red", count => 42}]};
    $self->facet_fields_as_hashes = {colors => {red => 42}}

=head2 parse

    $self = $self->parse(Mojo::Transaction->new);

Used to parse the result from a query. Will populate the different
L</ATTRIBUTES>.

=head1 SEE ALSO

L<SolarBeam>.

=cut
