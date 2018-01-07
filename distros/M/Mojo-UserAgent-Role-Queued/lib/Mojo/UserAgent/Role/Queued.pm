package Mojo::UserAgent::Role::Queued;
use Mojo::Base '-role';
use Scalar::Util 'weaken';

our $VERSION = "0.04";

has max_active => sub { shift->max_connections };

around start => sub {
  my ($orig, $self, $tx, $cb) = @_;
  if ($cb) {
    $self->_enqueue($orig, {tx => $tx, cb => $cb});
  }
  else {
    return $orig->($self, $tx); # Blocking calls skip the queue
  }
};

sub _enqueue {
  my ($self, $original_start, $job) = @_;
  $self->{'jobs'} ||= [];
  push @{$self->{'jobs'}}, $job;
  $self->_process($original_start);
}

sub _process {
  my ($self, $original_start) = @_;
  state $start //= $original_start;
  state $active //= 0;
  # we have jobs and can run them:
  while ($active < $self->max_active
    and my $job = shift @{$self->{'jobs'}})
  {
    my ($tx, $cb) = ($job->{tx}, $job->{cb});
    $active++;
    weaken $self;
    $tx->on(finish => sub { $active--; $self->_process() });
    $start->( $self, $tx, $cb );
  }
  if (scalar @{$self->{'jobs'}} == 0 && $active == 0) {
    $self->emit('stop_queue');
  }
}


1;
__END__

=encoding utf-8

=head1 NAME

Mojo::UserAgent::Role::Queued - A role to process non-blocking requests in a rate-limiting queue.

=head1 SYNOPSIS

    use Mojo::UserAgent;

    my $ua = Mojo::UserAgent->new->with_role('+Queued');
    $ua->max_redirects(3);
    $ua->max_active(5); # process up to 5 requests at a time
    for my $url (@big_list_of_urls) {
    $ua->get($url, sub {
            my ($ua, $tx) = @_;
            if ($tx->success) {
                say "Page at $url is titled: ",
                  $tx->res->dom->at('title')->text;
            }
           });
   };
   # works with promises, too:
  my @p = map {
    $ua->get_p($_)->then(sub { pop->res->dom->at('title')->text })
      ->catch(sub { say "Error: ", @_ })
  } @big_list_of_urls;
   Mojo::Promise->all(@p)->wait;
 

=head1 DESCRIPTION

Mojo::UserAgent::Role::Queued manages all non-blocking requests made through L<Mojo::UserAgent> in a queue to limit the number of simultaneous requests.

B<THIS IS AN INITIAL RELEASE>.

L<Mojo::UserAgent> can make multiple concurrent non-blocking HTTP requests using Mojo's event loop, but because there is only a single process handling all of them, you must take care to limit the number of simultaneous requests you make.

Some discussion of this issue is available here
L<http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html>
and in Joel Berger's answer here:
L<http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests>.

L<Mojo::UserAgent::Role::Queued> tries to generalize the practice of managing a large number of requests using a queue, by embedding the queue inside L<Mojo::UserAgent> itself.

=head1 EVENTS

L<Mojo::UserAgent::Role::Queued> adds the following event to those emitted by L<Mojo::UserAgent>:

=head2 stop_queue

  $ua->on(stop_queue => sub { my ($ua) = @_; .... })

Emitted when the queue has been emptied of all pending jobs.

=head1 ATTRIBUTES

L<Mojo::UserAgent::Role::Queued> has the following attributes:

=head2 max_active

    $ua->max_active(5);  # execute no more than 5 transactions at a time.
    print "Execute no more than ", $ua->max_active, " concurrent transactions"

Parameter controlling the maximum number of transactions that can be active at the same time.

=head2 

=head1 LICENSE

Copyright (C) Dotan Dimet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Dotan Dimet E<lt>dotan@corky.netE<gt>

=cut

