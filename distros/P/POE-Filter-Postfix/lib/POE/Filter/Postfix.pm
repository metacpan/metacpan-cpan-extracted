use strict;
use warnings;

package POE::Filter::Postfix;
our $VERSION = '0.003';


# ABSTRACT: Postfix (MTA) text attribute communication
use base qw(POE::Filter);

sub _abstract {
  my $name = shift;
  eval sprintf <<'', ($name) x 2;
sub %s { 
  my $class = ref($_[0]) || $_[0];
  require Carp;
  Carp::croak("$class must override %s()");
}

}

BEGIN {
  _abstract($_) for qw(
    attribute_separator
    attribute_terminator
    request_terminator
  )
}


sub new {
  my $class = shift;
  bless {
    @_,
    buffer => '',
  } => $class;
}


sub clone {
  my $self = shift;
  $self->new(%$self);
}


sub get_one_start {
  my ($self, $buf) = @_;
  $self->{buffer} .= $_ for @$buf;
}


sub get_one {
  my ($self) = @_;
  my %attr;
  my $buf = $self->{buffer};
  my ($a_s, $a_t, $r_t) = (
    $self->attribute_separator,
    $self->attribute_terminator,
    $self->request_terminator,
  );
  while ($buf =~ s/^([^$r_t]+?)\Q$a_s\E//) {
    my $key = $self->decode_key("$1");
    $buf =~ s/^([^$r_t]*)?\Q$a_t\E// or return [];
    $attr{$key} = $self->decode_value("$1");
  }
  return [] unless $buf =~ s/^\Q$r_t\E//;
  $self->{buffer} = $buf;
  return [ \%attr ];
}


sub get_pending {
  my ($self) = @_;
  return [ $self->{buffer} ] if length $self->{buffer};
  return undef;
}


sub decode_key   { $_[1] }
sub decode_value { $_[1] }


sub put {
  my ($self, $chunks) = @_;

  return [ map { $self->_encode($_) } @$chunks ];
}

sub _encode {
  my ($self, $attr) = @_;
  return join $self->attribute_terminator,
    (map {
      join $self->attribute_separator,
        $self->encode_key($_),
        $self->encode_value($attr->{$_})
    } keys %$attr),
    $self->request_terminator;
}


sub encode_key   { $_[1] }
sub encode_value { $_[1] }


1;


__END__
=head1 NAME

POE::Filter::Postfix - Postfix (MTA) text attribute communication

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This filter translates between hashrefs and the key-value attribute protocols
that the Postfix MTA uses for its internal communications.

Unless you're doing something complicated, you can probably use
L<POE::Component::Server::Postfix> instead of this module.

Don't use this module directly.  See L<POE::Filter::Postfix::Null>,
L<POE::Filter::Postfix::Base64>, and L<POE::Filter::Postfix::Plain> instead.

=head1 METHODS

=head2 new

Return a new POE::Filter::Postfix.

Call this on a subclass, not on POE::Filter::Postfix directly.

=head2 clone

See L<POE::Filter/clone>.

=head2 get_one_start

See L<POE::Filter/get_one_start>.

=head2 get_one

See L<POE::Filter/get_one>.

=head2 get_pending

See L<POE::Filter/get_pending>.

=head2 decode_key

=head2 decode_value

After parsing keys and values, these methods are called to decode them.  See
L<POE::Filter::Postfix::Base64> for an example.

The default is to pass keys and values through unchanged.

You do not need to call these methods by hand; C<get_one> calls them
automatically.

=head2 put

See L<POE::Filter/put>.

=head2 encode_key

=head2 encode_value

Before packing keys and values into a string, these methods are called to
encode them.  See L<POE::Filter::Postfix::Base64> for an example.

The default is to pass keys and values through unchanged.

You do not need to call these methods by hand; C<put> calls them automatically.

=head2 attribute_separator

=head2 attribute_terminator

=head2 request_terminator

These methods must be overridden by subclasses.

Each returns a string that will be used to parse and construct requests.

See existing subclasses for examples.

=head1 AUTHOR

  Hans Dieter Pearcey <hdp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

