package Net::Statsd::Client::Telegraf;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.1';
use Moo;

extends 'Net::Statsd::Client';

has tags => ( is => 'ro', default => sub { {} }, isa => sub { die 'tags is expecting a hashref' unless ref $_[0] and ref $_[0] eq 'HASH'; } );

around increment => sub {
    my ( $orig, $self, $metric, %opt ) = @_;

    return $self->$orig( $self->add_tags($metric, $opt{tags}), $opt{sample_rate});
};

around decrement => sub {
    my ( $orig, $self, $metric, %opt ) = @_;

    return $self->$orig( $self->add_tags($metric, $opt{tags}), $opt{sample_rate});
};

around update => sub {
    my ( $orig, $self, $metric, $count, %opt ) = @_;

    return $self->$orig( $self->add_tags($metric, $opt{tags}), $count, $opt{sample_rate});
};

around timing_ms => sub {
    my ( $orig, $self, $metric, $time, @others ) = @_;

    #ugly layer to handle timer method,
    #Timer method return a timer method which call timing_ms, with the
    #protocal of Net::Statsd::Client, hence, with a scalar after $time
    #use Data::Dumper; warn Dumper( \@others );
    if( scalar( @others ) == 1 ) {
        my $sample_rate = $others[0];

        return $self->$orig( $metric, $time, $sample_rate);
    } else {
        my %opt = @others;
        return $self->$orig( $self->add_tags($metric, $opt{tags}), $time, $opt{sample_rate});
    }
};

around gauge => sub {
    my ( $orig, $self, $metric, $value, %opt ) = @_;

    return $self->$orig( $self->add_tags($metric, $opt{tags}), $value, $opt{sample_rate});
};

around set_add => sub {
    my ( $orig, $self, $metric, $value, %opt ) = @_;

    return $self->$orig( $self->add_tags($metric, $opt{tags}), $value, $opt{sample_rate});
};

around timer => sub {
    my ( $orig, $self, $metric, %opt ) = @_;

    return $self->$orig( $self->add_tags($metric, $opt{tags}), $opt{sample_rate});
};

sub add_tags {
    my ($self, $what, $tags) = @_;

    my $t = '';
    if( defined $tags ) {
        die 'tags is expecting a hashref'
            unless ref $tags and ref $tags eq 'HASH';
        while( my ($name, $value) = each %$tags ) {
            $name =~ s/\s/_/g;
            $value =~ s/\s/_/g;
            $t .= ",$name=$value";
        }
    }
    while( my ($name, $value) = each %{$self->tags} ) {
        $name =~ s/\s/_/g;
        $value =~ s/\s/_/g;
        $t .= ",$name=$value";
    }

    return $what.$t;
}

1;
__END__

=encoding utf-8

=head1 NAME

Net::StatsD::Client::Telegraf - Send data to the statsd plugin of telegraf, with support for influxDB's tagging system

=head1 SYNOPSIS

  use Net::Statsd::Client::Telegraf;
  my $stats = Net::Statsd::Client->new(prefix => "service.frobnitzer.", tags => { job => "my_program" } );
  $stats->increment("requests", tags => { foo => "bar" }, sample_rate => 0.2 );
  my $timer = $stats->timer("request_duration");
  # ... do something expensive ...
  my $elapsed_ms = $timer->finish;

=head1 DESCRIPTION

Net::StatsD::Client::Telegraf is a tiny layer on top of L<Net::StatsD::Client> to add support for
tags as implemented by the statsd collector of telegraf.
Defaults tags can be passed as a hashref in the tags attributes, each methods also accept a tags
arguments to add tags for the current statsd call

=head1 ATTRIBUTES

Net::Statsd::Client::Telegraf takes the exact same parameters as L<Net::StatsD::Client>, plus an additionnal tags,
for the documentation of the other attribute of the constructor, please refer to
L<Net::StatsD::Client>

=head2 tags

B<Optional:> A hashref containing key values to be used as tags in the metrics name, as accepted by influxDB and telegraf

=head1 METHODS

Being a layer on top of L<Net::Statsd::Client>, Net::Statsd::Client::Telegraf exposes the exact same methods,
the only difference begin in the parameters, for all of its methods, L<Net::Statsd::Client> accepts an optional
parameter C<sample_rate>, instead Net::Statsd::Client::Telegraf accept a lsit of options in key value format
The key being C<sample_rate> and C<tags>.

  $stats->increment(
    "metric_name",
    tags => {
      name1 => "value1",
      name2 => "value2",
    },
    sample_rate => 0.2
 );

=head2 $stats->increment($metric, [%options] )

Increment the named counter metric.

=head2 $stats->decrement($metric, [%options] )

Decrement the named counter metric.

=head2 $stats->update($metric, $count, [%options] )

Add C<$count> to the value of the named counter metric.

=head2 $stats->timing_ms($metric, $time, [%options] )

Record an event of duration C<$time> milliseconds for the named timing metric.

=head2 $stats->timer($metric, [%options] )

Returns a L<Net::Statsd::Client::Timer> object for the named timing metric.
The timer begins when you call this method, and ends when you call C<finish>
on the timer.  Calling C<finish> on the timer returns the elapsed time in
milliseconds.

=head2 $stats->gauge($metric, $value, [%options] )

Send a value for the named gauge metric. Instead of adding up like counters
or producing a large number of quantiles like timings, gauges simply take
the last value sent in any time period, and don't require scaling.

=head2 $statsd->set_add($metric, $value, [%options] )

Add a value to the named set metric. Sets count the number of *unique*
values they see in each time period, letting you estimate, for example, the
number of users using a site at a time by adding their userids to a set each
time they load a page.

=head1 SEE ALSO

This module is a tiny layer on top of L<Net::Stats::Client>, to add the tags functionality

=head1 AUTHOR

Pierre VIGIER E<lt>pierre.vigier@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2018- Pierre VIGIER

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
