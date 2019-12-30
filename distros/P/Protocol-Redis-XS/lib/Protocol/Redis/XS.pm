package Protocol::Redis::XS;
use strict;
use warnings;
use parent "Protocol::Redis";

use XS::Object::Magic;
use XSLoader;

our $VERSION = '0.07';

XSLoader::load "Protocol::Redis::XS", $VERSION;

sub new {
  my($class, %args) = @_;

  my $on_message = delete $args{on_message};

  my $self = bless \%args, $class;
  return unless $self->api == 1;
  $self->on_message($on_message) if defined $on_message;

  $self->_create;

  return $self;
}

# See Protocol::Redis for description of the API versioning
sub api {
  my($self) = @_;

  $self->{api};
}

sub on_message {
  my($self, $cb) = @_;
  $self->{_on_message_cb} = $cb;
}

1;

__END__

=head1 NAME

Protocol::Redis::XS - hiredis based parser compatible with Protocol::Redis

=head1 SYNOPSIS

  use Protocol::Redis::XS;
  my $redis = Protocol::Redis::XS->new(api => 1);
  $redis->parse("+OK\r\n");
  $redis->get_message;

=head1 DESCRIPTION

This provides a fast parser for the Redis protocol using the code from
L<hiredis|https://github.com/redis/hiredis> and with API compatibility with
L<Protocol::Redis>.

(If you've found yourself here just looking to use Redis in Perl: This is a low
level parsing module, you probably want to look at the modules mentioned in
L</SEE ALSO> first.)

=head1 METHODS

As per L<Protocol::Redis>, API version 1.

=head2 parse

Parse a chunk of data (calls L</on_message> callback if defined and a complete
message is received).

=head2 get_message

Return a message. This is a potentially nested data structure, for example as
follows:

  {
    type => '*',
    data => [
      {
        type => '$',
        data => 'hello'
      }
    ]
  }

=head2 on_message

Set callback for L</parse>.

=head1 THREADS

This module will work on a threaded perl and will work with threads, however
instances of Protocol::Redis should not be shared between threads.

=head1 SUPPORT

=head2 IRC

L<#redis on irc.perl.org|irc://irc.perl.org/redis>

=head1 DEVELOPMENT

See github: L<https://github.com/dgl/protocol-redis-xs>.

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

With thanks to Sergey Zasenko <undef@cpan.org> for the original
L<Protocol::Redis> and defining the API.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 David Leadbeater.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Redis>, L<Redis::hiredis>, L<Mojo::Redis>, L<AnyEvent::Redis>,
L<Protocol::Redis>.

=cut

# ex:sw=2 et:
