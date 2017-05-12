package Net::Groonga::HTTP::Response;
use strict;
use warnings;
use utf8;
use JSON::XS qw(decode_json);
use Data::Page;
use Net::Groonga::Pager;

use Mouse;

has function => (
    is => 'rw',
    required => 1,
);

has args => (
    is => 'rw',
    required => 1,
);

has http_response => (
    is => 'rw',
    required => 1,
);

has data => (
    is => 'rw',
    builder => '_build_data',
);

no Mouse;

sub is_success {
    my $self = shift;
    return $self->http_response->code eq 200 && $self->return_code == 0;
}

sub _build_data {
    my $self = shift;
    return undef if $self->http_response->code ne 200;
    return $self->http_response->content if $self->function eq 'dump';
    decode_json($self->http_response->content);
}

sub return_code {
    my $self = shift;
    Carp::croak(sprintf("%s:%s", $self->function, $self->http_response->status_line)) unless $self->data;
    return 0 if $self->function eq 'dump';
    $self->data->[0]->[0];
}

sub start_time {
    my $self = shift;
    Carp::croak(sprintf("%s:%s", $self->function, $self->http_response->status_line)) unless $self->data;
    return undef if $self->function eq 'dump';
    $self->data->[0]->[1];
}

sub elapsed_time {
    my $self = shift;
    Carp::croak(sprintf("%s:%s", $self->function, $self->http_response->status_line)) unless $self->data;
    return undef if $self->function eq 'dump';
    $self->data->[0]->[2];
}

sub result {
    my $self = shift;
    Carp::croak(sprintf("%s:%s:%s", $self->function, $self->http_response->status_line, substr($self->http_response->content, 0, 256))) unless $self->data;
    return $self->data if $self->function eq 'dump';
    $self->data->[1];
}

sub pager {
    my $self = shift;
    return unless $self->data;
    return unless $self->return_code == 0;
    return unless ref $self->data eq 'ARRAY';
    return unless ref $self->data->[1] eq 'ARRAY';
    return unless ref $self->data->[1]->[0] eq 'ARRAY';
    return unless ref $self->data->[1]->[0]->[0] eq 'ARRAY';

    my $total_entries = $self->data->[1]->[0]->[0]->[0];
    my $limit  = $self->args->{limit}  || 10;
    my $offset = $self->args->{offset} || 0;

    Net::Groonga::Pager->new(
        limit  => $limit,
        offset => $offset,
        total_entries => $total_entries,
    );
}

sub rows {
    my $self = shift;
    return unless $self->data;

    my @rows = @{$self->data->[1]->[0]};
    my $cnt    = shift @rows;
    my $header = shift @rows;
    my @results;
    for my $row (@rows) {
        my %args;
        for (my $i=0; $i<@$header; ++$i) {
            my $key = $header->[$i]->[0];
            my $val = $row->[$i];
            $args{$key} = $val;
        }
        push @results, \%args;
    }
    return @results;
}

1;
__END__

=head1 NAME

Net::Groonga::HTTP::Response - Response object for Net::Groonga::HTTP

=head1 DESCRIPTION

This class is a response class for L<Net::Groonga::HTTP>.

=head1 BASIC METHODS

=over 4

=item $res->function() :Str

The name of executed function.

=item $res->args() : HashRef

The arguments for executed function.

=item $res->http_response() :Object

Executed HTTP response object from L<Furl>.

=back

=head1 METHODS FOR ANALYZING CONTENT-BODY

Following methods return method dies if the response is not I<200 OK>.

=over 4

=item $res->data() :Object

JSON decoded content body.

=item $res->return_code() :Int

Shorthand for C<< $res->data->[0]->[0] >>.

Groonga's return code. It's not HTTP status code.

=item $res->starttime() :Int

Shorthand for C<< $res->data->[0]->[2] >>.

=item $res->elapsed_time() :Int

Shorthand for C<< $res->data->[0]->[2] >>.

Elapsed time.

=item $res->result() :Int

Shorthand for C<< $res->data->[1] >>.

=item $res->pager() :Net::Groonga::Pager

Create pager object if it's available.

It's only useful if the function is B<select>.

The object instance of L<Net::Groonga::Pager>.

=item @rows = $res->rows()

Create list of hashrefs from JSON content.

It's only useful if the function si B<select>.

=back


