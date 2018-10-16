package Net::Async::Consul;
$Net::Async::Consul::VERSION = '0.002';
# ABSTRACT: Make async calls to Consul via IO::Async

use warnings;
use strict;

use Consul 0.016;
use Net::Async::HTTP;
use HTTP::Request;
use HTTP::Headers;
use Hash::MultiValue;
use List::Util 1.29 qw(pairmap);
use Carp qw(croak);

sub new {
  my ($class, %args) = @_;

  my $loop = delete $args{loop};
  croak "missing required param: loop" unless $loop;
  my $http = Net::Async::HTTP->new(
    max_connections_per_host => 4,
    max_in_flight => 4,
  );
  $loop->add($http);

  Consul->new(%args,
    request_cb => sub {
      my ($self, $req) = @_;
      $http->do_request(
        request => HTTP::Request->new(
          $req->method,
          $req->url,
          HTTP::Headers->new(%{$req->headers->as_hashref}),
          $req->content,
        ),
        timeout => $self->timeout,
        on_response => sub {
          my ($r) = @_;
          $req->callback->(Consul::Response->new(
            status  => $r->code,
            reason  => $r->message,,
            headers => Hash::MultiValue->new(pairmap { (lc($a) => $b) } $r->headers->flatten),
            content => $r->content,
            request => $req,
          ));
        },
        on_error => sub {
          $req->callback->(Consul::Response->new(
            status => 599,
            reason => "internal error: @_",
            request => $req,
          ));
        }
      );
      return;
    },
  );
}

sub acl     { shift->new(@_)->acl     }
sub agent   { shift->new(@_)->agent   }
sub catalog { shift->new(@_)->catalog }
sub event   { shift->new(@_)->event   }
sub health  { shift->new(@_)->health  }
sub kv      { shift->new(@_)->kv      }
sub session { shift->new(@_)->session }
sub status  { shift->new(@_)->status  }

1;

=pod

=encoding UTF-8

=for markdown [![Build Status](https://secure.travis-ci.org/robn/Net-Async-Consul.png)](http://travis-ci.org/robn/Net-Async-Consul)

=head1 NAME

Net::Async::Consul - Make async calls to Consul via IO::Async

=head1 SYNOPSIS

  use IO::Async::Loop;
  use Net::Async::Consul;

  my $loop = IO::Async::Loop->new;
  
  my $kv = Net::Async::Consul->kv(loop => $loop);

  # do some blocking op to discover the current index
  $kv->get("mykey", cb => sub { 
    my ($v, $meta) = @_;
  
    # now set up a long-poll to watch a key we're interested in
    $kv->get("mykey", index => $meta->index, cb => sub {
      my ($v, $meta) = @_;
      say "mykey changed to ".$v->value;
      $loop->stop;
    });
  });
  
  # make the change
  $kv->put("mykey" => "newval");
  
  $loop->run;

=head1 DESCRIPTION

Net::Async::Consul is a thin wrapper around L<Consul> to connect it to
L<Net::Async::HTTP> for asynchronous operation.

It takes the same arguments and methods as L<Consul> itself, so see the
documentation for that module for details. The important difference is that you
must pass the C<loop> option with the loop object to API methods, the C<cb>
option to the endpoint methods to enable their asynchronous mode.

There's also a C<on_error> argument. If you pass in a coderef for this
argument, it will be called with a single string arg whenever something goes
wrong internally (usually a HTTP failure). Use it to safely log or cleanup
after the error.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/Net-Async-Consul/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/Net-Async-Consul>

  git clone https://github.com/robn/Net-Async-Consul.git

=head1 AUTHORS

=over 4

=item *

Rob N ★ <robn@robn.io>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Rob N ★.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
