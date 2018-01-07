[![Build Status](https://travis-ci.org/dotandimet/Mojo-UserAgent-Role-Queued.svg?branch=master)](https://travis-ci.org/dotandimet/Mojo-UserAgent-Role-Queued) [![MetaCPAN Release](https://badge.fury.io/pl/Mojo-UserAgent-Role-Queued.svg)](https://metacpan.org/release/Mojo-UserAgent-Role-Queued)
# NAME

Mojo::UserAgent::Role::Queued - A role to process non-blocking requests in a rate-limiting queue.

# SYNOPSIS

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
    

# DESCRIPTION

Mojo::UserAgent::Role::Queued manages all non-blocking requests made through [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent) in a queue to limit the number of simultaneous requests.

**THIS IS AN INITIAL RELEASE**.

[Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent) can make multiple concurrent non-blocking HTTP requests using Mojo's event loop, but because there is only a single process handling all of them, you must take care to limit the number of simultaneous requests you make.

Some discussion of this issue is available here
[http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html](http://blogs.perl.org/users/stas/2013/01/web-scraping-with-modern-perl-part-1.html)
and in Joel Berger's answer here:
[http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests](http://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests).

[Mojo::UserAgent::Role::Queued](https://metacpan.org/pod/Mojo::UserAgent::Role::Queued) tries to generalize the practice of managing a large number of requests using a queue, by embedding the queue inside [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent) itself.

# EVENTS

[Mojo::UserAgent::Role::Queued](https://metacpan.org/pod/Mojo::UserAgent::Role::Queued) adds the following event to those emitted by [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent):

## stop\_queue

    $ua->on(stop_queue => sub { my ($ua) = @_; .... })

Emitted when the queue has been emptied of all pending jobs.

# ATTRIBUTES

[Mojo::UserAgent::Role::Queued](https://metacpan.org/pod/Mojo::UserAgent::Role::Queued) has the following attributes:

## max\_active

    $ua->max_active(5);  # execute no more than 5 transactions at a time.
    print "Execute no more than ", $ua->max_active, " concurrent transactions"

Parameter controlling the maximum number of transactions that can be active at the same time.

## 

# LICENSE

Copyright (C) Dotan Dimet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Dotan Dimet <dotan@corky.net>
