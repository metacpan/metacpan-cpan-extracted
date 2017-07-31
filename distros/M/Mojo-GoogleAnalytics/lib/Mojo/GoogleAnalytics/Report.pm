package Mojo::GoogleAnalytics::Report;
use Mojo::Base -base;

sub count      { shift->{data}{rowCount} || 0 }
sub error      { shift->{error} }
sub page_token { shift->{nextPageToken}  || '' }
sub query      { shift->{query}          || {} }
sub rows       { shift->{data}{rows}     || [] }
sub tx         { shift->{tx} }

has maximums => sub { shift->_stats('maximums') };
has minimums => sub { shift->_stats('minimums') };
has totals   => sub { shift->_stats('totals') };

sub rows_to_hash {
  my $self    = shift;
  my $headers = $self->{columnHeader}{metricHeader}{metricHeaderEntries};
  my $reduced = {};

  for my $row (@{$self->rows}) {
    my $level   = $reduced;
    my $metrics = $row->{metrics}[0]{values};
    my $prev;

    for my $dimension (@{$row->{dimensions}}) {
      $prev = $level;
      $level = $level->{$dimension} ||= {};
    }

    if (@$metrics == 1) {
      $prev->{$row->{dimensions}[-1]} = $metrics->[0];
    }
    else {
      for my $i (0 .. @$headers - 1) {
        $level->{$headers->[$i]{name}} = $metrics->[$i];
      }
    }
  }

  return $reduced;
}

sub rows_to_table {
  my ($self, %args) = @_;
  my $headers = $self->{columnHeader};
  my @rows;

  unless ($args{no_headers}) {
    push @rows, [@{$headers->{dimensions}}, map { $_->{name} } @{$headers->{metricHeader}{metricHeaderEntries}}];
  }

  for my $row (@{$self->rows}) {
    push @rows, [@{$row->{dimensions}}, @{$row->{metrics}[0]{values}}];
  }

  if (($args{as} || '') eq 'text') {
    return Mojo::Util::tablify(\@rows);
  }

  return \@rows;
}

sub _stats {
  my ($self, $attr) = @_;
  my $headers = $self->{columnHeader}{metricHeader}{metricHeaderEntries};
  my $metrics = delete $self->{data}{$attr};
  my %data;

  $metrics = $metrics->[0]{values};

  for my $i (0 .. @$headers - 1) {
    $data{$headers->[$i]{name}} = $metrics->[$i];
  }

  return \%data;
}

1;

=encoding utf8

=head1 NAME

Mojo::GoogleAnalytics::Report - Represents a Google Analytics report

=head1 SYNOPSIS

See L<Mojo::GoogleAnalytics>.

=head1 DESCRIPTION

L<Mojo::GoogleAnalytics::Report> represents a result from
L<Mojo::GoogleAnalytics/batch_get>.

=head1 ATTRIBUTES

=head2 count

  $int = $self->count;

Returns the total count of rows that can be returned by Google Analytics.

=head2 error

  $hash_ref = $self->error;

Holds a hash ref if an error occurred and undef if not. Example data structure:

  {
    code    => 403,
    message => "Something went wrong",
  }

=head2 maximums

  $hash_ref = $self->maximums;

Holds a hash ref with the maximum metrics. Example:

  {
    "ga:pageviews" => 349,
    "ga:sessions"  => 40,
  }

=head2 minimums

  $hash_ref = $self->minimums;

See L</maximums>.

=head2 page_token

  $str = $self->page_token;

Holds a token that can be used to query Google Analytics for more data.

=head2 query

  $hash_ref = $self->query;

Holds the query passed on to L<Mojo::GoogleAnalytics/batch_get>.

=head2 rows

  $array_ref = $self->rows;

Holds the row data returned from Google Analytics. Example:

  [
    {
      dimensions => ["Norway", "Chrome"],
      metrics    => [{values => [349, 40]}],
    },
    ...
  ]

=head2 totals

  $hash_ref = $self->totals;

See L</maximums>.

=head2 tx

  $tx = $self->tx;

Holds the raw L<Mojo::Transaction> object used in the request. Useful if you
need to extract raw data:

  my $raw_data = $tx->res->json;

=head1 METHODS

=head2 rows_to_hash

  $hash_ref = $self->rows_to_hash;

Creates a multi dimensional hash, from the "dimensions" in the rows. Example
result:

  # Query dimensions: [{name => 'ga:country'}, {name => 'ga:browser'}]
  # Result:
  {
    Norway => {
      Chrome => {
        "ga:pageviews" => 349,
        "ga:sessions"  => 40,
      },
      ...
    },
    ...
  }

=head2 rows_to_table

  $array_ref = $self->rows_to_table(no_headers => 1);
  $str = $self->rows_to_table(as => "text", no_headers => 1);

Converts L</rows> into tabular data. C<as> can be used to return the table as
either "text" or "hash" (default). Set C<no_headers> to a true value to avoid
getting the first item in the C<$array_ref> as header names. Example "text" output:

  ga:country  ga:browser  ga:pageviews  ga:sessions
  Sweden      Chrome      472493        43340
  Sweden      Safari      413833        43242
  Denmark     Safari      127321        13975
  Denmark     Chrome      124904        12077
  Norway      Chrome      105998        10066

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

L<Mojo::GoogleAnalytics>.

=head1 SEE ALSO

L<Mojo::GoogleAnalytics>.

=cut
