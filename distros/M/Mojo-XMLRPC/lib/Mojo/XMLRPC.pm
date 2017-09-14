package Mojo::XMLRPC;

use Mojo::Base -strict;

use B ();
use Mojo::ByteStream;
use Mojo::Date;
use Mojo::DOM;
use Mojo::JSON;
use Mojo::Template;
use Scalar::Util ();

use Mojo::XMLRPC::Base64;
use Mojo::XMLRPC::Message::Call;
use Mojo::XMLRPC::Message::Response;

use Exporter 'import';

our @EXPORT_OK = (qw[decode_xmlrpc encode_xmlrpc from_xmlrpc to_xmlrpc]);

our $VERSION = '0.02';
$VERSION = eval $VERSION;

my $message = Mojo::Template->new(
  auto_escape => 1,
  name => 'message',
  namespace => __PACKAGE__,
)->parse(<<'TEMPLATE');
  % my ($tag, $method, @args) = @_;
<?xml version="1.0" encoding="UTF-8"?>
<<%= $tag %>>
% if (defined $method) {
  <methodName><%= $method %></methodName>
% }
% for my $arg (@args) {
  %= $arg
% }
</<%= $tag %>>
TEMPLATE

my $fault = Mojo::Template->new(
  auto_escape => 1,
  name => 'fault',
  namespace => __PACKAGE__,
)->parse(<<'TEMPLATE');
  % my ($code, $string) = @_;
  <fault>
    <value><struct>
      <member>
        <name>faultCode</name>
        <value><int><%= $code // '' %></int></value>
      </member>
      <member>
        <name>faultString</name>
        <value><string><%= $string // '' %></string></value>
      </member>
    </struct></value>
  </fault>
TEMPLATE

my $params = Mojo::Template->new(
  auto_escape => 1,
  name => 'params',
  namespace => __PACKAGE__,
)->parse(<<'TEMPLATE');
  % my (@params) = @_;
  <params>
  % for my $param (@params) {
    <param><value><%= $param %></value></param>
  % }
  </params>
TEMPLATE

sub decode_xmlrpc { from_xmlrpc(Mojo::Util::decode 'UTF-8', $_[0]) }

sub encode_xmlrpc { Mojo::Util::encode 'UTF-8', to_xmlrpc(@_) }

sub from_xmlrpc {
  my ($xml) = shift;

  # parse the XML document
  my $dom = Mojo::DOM->new($xml);
  my $msg;

  # detect the message type
  my $top  = $dom->children->first;
  my $type = $top->tag;
  if ($type eq 'methodCall') {
    $msg = Mojo::XMLRPC::Message::Call->new;
    if (defined(my $method = $top->children('methodName')->first)) {
      $msg->method_name($method->text);
    }

  } elsif ($type eq 'methodResponse') {
    $msg = Mojo::XMLRPC::Message::Response->new;
    if (defined(my $fault = $top->children('fault')->first)) {
      return $msg->fault(_decode_element($fault));
    }

  } else {
    die 'unknown type of message';
  }

  if (defined(my $params = $top->children('params')->first)) {
    $msg->parameters([ map { _decode_element($_) } @{ $params->children('param') } ]);
  }

  return $msg;
}

sub to_xmlrpc {
  my ($type, @args) = @_;

  if (Scalar::Util::blessed($type) && $type->isa('Mojo::XMLRPC::Message')) {
    my $obj = $type;
    if ($obj->isa('Mojo::XMLRPC::Message::Call')) {
      $type = 'call';
      @args = ($obj->method_name, @{ $obj->parameters });
    } elsif ($obj->isa('Mojo::XMLRPC::Message::Response')) {
      $type = $obj->is_fault ? 'fault' : 'response';
      @args = $obj->is_fault ? @{ $obj->fault }{qw/faultCode faultString/} : @{ $obj->parameters };
    } else {
      die 'Message type not understood';
    }
  }

  my $tag    = $type eq 'call' ? 'methodCall' : 'methodResponse';
  my $method = $type eq 'call' ? shift @args  : undef;

  my $xml =
    $type eq 'fault' ? $fault->process(@args) :
    @args ? $params->process(map { _encode_item($_) } @args) :
    undef;

  return $message->process($tag, $method, defined($xml) ? Mojo::ByteStream->new($xml) : ());
}

sub _decode_element {
  my $elem = shift;
  my $tag = $elem->tag;

  if ($tag eq 'param' || $tag eq 'value' || $tag eq 'fault') {
    return _decode_element($elem->children->first);

  } elsif ($tag eq 'array') {
    my $data = $elem->children('data')->first;
    return [ map { _decode_element($_) } @{ $data->children('value') } ];

  } elsif ($tag eq 'struct') {
    return +{
      map {;
        $_->children('name')->first->text,              # key
        _decode_element($_->children('value')->first)   # value
      }
      @{ $elem->children('member') }  # pairs
    };

  } elsif ($tag eq 'int' || $tag eq 'i4') {
    return $elem->text + 0;

  } elsif ($tag eq 'string' || $tag eq 'name') {
    return $elem->text;

  } elsif ($tag eq 'double') {
    return $elem->text / 1.0;

  } elsif ($tag eq 'boolean') {
    return $elem->text ? Mojo::JSON::true : Mojo::JSON::false;

  } elsif ($tag eq 'nil') {
    return undef;

  } elsif ($tag eq 'dateTime.iso8601') {
    my $date = Mojo::Date->new($elem->text);
    unless ($date->epoch) {
      require Time::Piece;
      $date->epoch(Time::Piece->strptime($elem->text, '%Y%m%dT%H:%M:%S')->epoch);
    }
    return $date;
  } elsif ($tag eq 'base64') {
    return Mojo::XMLRPC::Base64->new(encoded => $elem->text);
  }

  die "unknown tag: $tag";
}

sub _encode_item {
  my $item = shift;
  my $ret;

  if (ref $item) {
    if (Scalar::Util::blessed $item) {
      if ($item->can('TO_XMLRPC')) {
        return _encode_item($item->TO_XMLRPC);

      } elsif ($item->isa('JSON::PP::Boolean')) {
        my $val = $item ? 1 : 0;
        $ret = "<boolean>$val</boolean>";

      } elsif ($item->isa('Mojo::Date')) {
        my $date = $item->to_datetime;
        $ret = "<dateTime.iso8601>$date</dateTime.iso8601>";

      } elsif ($item->isa('Mojo::XMLRPC::Base64')) {
        $ret = "<base64>$item</base64>";

      } elsif ($item->can('TO_JSON')) {
        return _encode_item($item->TO_JSON);

      } else {
        return _encode_item("$item");
      }
    } elsif (ref $item eq 'ARRAY') {
      $ret = join '', map { '<value>' . _encode_item($_) . '</value>' } @$item;
      $ret = "<array><data>$ret</data></array>";

    } elsif (ref $item eq 'HASH') {
      $ret = join '', map {
        my $name = Mojo::Util::xml_escape($_);
        "<member><name>$name</name><value>" . _encode_item($item->{$_}) . '</value></member>';
      } keys %$item;
      $ret = "<struct>$ret</struct>";

    } elsif (ref $item eq 'SCALAR') {
      my $val = $$item ? 1 : 0;
      $ret = "<boolean>$val</boolean>";
    }
  }
  else {
    my $sv = B::svref_2object(\$item);

    $ret =
      !defined $item ? '<nil/>' :
      $sv->FLAGS & B::SVf_NOK ? "<double>$item</double>" :
      $sv->FLAGS & B::SVf_IOK ? "<int>$item</int>" :
      '<string>' . Mojo::Util::xml_escape($item) . '</string>';
  }

  return Mojo::ByteStream->new($ret);
}

1;

=encoding utf8

=head1 NAME

Mojo::XMLRPC - An XMLRPC message parser/encoder using the Mojo stack

=head1 SYNOPSIS

  use Mojo::UserAgent;
  use Mojo::XMLRPC qw[to_xmlrpc from_xmlrpc];

  my $ua = Mojo::UserAgent->new;
  my $url = ...;
  my $tx = $ua->post($url, encode_xmlrpc(request => 'mymethod', 'myarg'));
  my $res = decode_xmlrpc($tx->res->body)

=head1 DESCRIPTION

L<Mojo::XMLRPC> is a pure-perl XML-RPC message parser and encoder.
It uses tools from the L<Mojo> toolkit to do all of the work.

This does not mean that it must only be used in conjunction with a L<Mojolicious> app, far from it.
Feel free to use it in any circumstance that needs XML-RPC messages.

=head1 MAPPING

The mapping between Perl types and XMLRPC types is not perfectly one-to-one, especially given Perl's scalar types.
The following is a description of the procedure used to encode and decode XMLRPC message from/to Perl.

=head2 Perl to XMLRPC

If the item is a blessed reference:

=over

=item *

If the item/object implements a C<TO_XMLRPC> method, it is called and the result is encoded.

=item *

If the item is a L<JSON::PP::Boolean>, as the L<Mojo::JSON> booleans are, it is encoded as a C<boolean>.

=item *

If the item is a L<Mojo::Date> then it is encoded as a C<dateTime.iso8601>.

=item *

If the item is a L<Mojo::XMLRPC::Base64> then it is encode as a C<base64>.
This wrapper class is used to distinguish a string from a base64 and aid in encoding/decoding.

=item

If the item/object implements a C<TO_JSON> method, it is called and the result is encoded.

=item

If none of the above cases are true, the item is stringified and encoded as a C<string>.

=back

If the item is an unblessed reference:

=over

=item *

An array reference is encoded as an C<array>.

=item *

A hash reference is encoded as a C<struct>.

=item *

A scalar reference is encoded as a C<boolean> depending on the truthiness of the referenced value.
This is the standard shortcut seen in JSON modules allowing C<\1> for true and C<\0> for false.

=back

If the item is a non-reference scalar:

=over

=item *

If the item is undefined it is encoded as C<< <nil/> >>.

=item *

If the item has C<NOK> (it has been used as a floating point number) it is encoded as C<double>.

=item *

If the item has C<IOK> (it has been used as an integer (and not a float)) it is encoded as a C<double>.

=item *

All other values are encoded as C<string>.

=back

=head2 XMLRPC to Perl

Most values decode back into Perl in a manner that would survive a round trip.
The exceptions are blessed objects that implement C<TO_XMLRPC> or C<TO_JSON> or are stringified.
The shortcuts for booleans will round-trip to being L<Mojo::JSON> booleans objects.

Values encoded as integers will not be truncated via C<int> however no attempt is made to upgrade them to C<IOK> or C<NOK>.
Values encoded as floating point C<double> will be forcably upgraded to C<NOK> (by dividing by 1.0).
This is so that an integer value encoded as a floating point will round trip, the reverse case isn't as useful and thus isn't handled.

=head1 FUNCTIONS

=head2 decode_xmlrpc

Like L</from_xmlrpc> but first decodes from UTF-8 encoded bytes.

=head2 encode_xmlrpc

Like L</to_xmlrpc> but encodes the result to UTF-8 encoded bytes.

=head2 from_xmlrpc

Takes a character string, interprets it, and returns a L<Mojo::XMLRPC::Message> containing the result.
If the input is UTF-8 encoded bytes, you can use L</decode_xmlrpc> instead.

=head2 to_xmlrpc

Generates an XMLRPC message from data passed to the function.
The input may be a L<Mojo::XMLRPC::Message> or it could be of the following form.

=over

=item *

A message type, one of C<call>, C<response>, C<fault>.

=item *

If the message type is C<call>, then the method name.

=item *

If the message is not a C<fault>, then all remaining arguments are parameters.
If the message is a C<fault>, then the fault code followed by the fault string, all remaining arguments are ignored.

=back

The return value is a character string.
To generate UTF-8 encoded bytes, you can use L</encode_xmlrpc> instead.

=head1 THANKS

This module was inspired by L<XMLRPC::Fast> written by Sébastien Aperghis-Tramoni.

L<Mojo::XMLRPC> was a port of that module initially to use the L<Mojo::DOM> module rather than L<XML::Parser>.
By the time port to the Mojo stack was complete, the module was entirely rewritten.
That said, the algorithm still owes a debt of gratitude to that one.

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Mojo-XMLRPC>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Joel Berger
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
