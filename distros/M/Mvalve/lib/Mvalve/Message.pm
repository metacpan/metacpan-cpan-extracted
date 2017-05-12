# $Id$

package Mvalve::Message;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::ClassAttribute;
use Data::Serializer;
use Digest::SHA1 ();
use HTTP::Headers;
use POSIX();
use Sys::Hostname();
use Time::HiRes();

class_type 'HTTP::Headers';

coerce 'HTTP::Headers'
    => from 'HashRef',
        => via { HTTP::Headers->new(%$_) }
;

has 'id' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    default => sub {
        # XXX - hints as to about when this message was generated
        my ($int_part, $float_part) = split(/\./, Time::HiRes::time());
        my $prefix = join('.', POSIX::strftime('%Y%m%d%H%M%S', localtime($int_part)), $float_part);
        
        return join('-', $prefix, Digest::SHA1::sha1_hex({}, $$, Time::HiRes::time(), rand(), Sys::Hostname::hostname()))
    }
);

has 'headers' => (
    is => 'rw',
    isa => 'HTTP::Headers',
    coerce => 1,
    default => sub { HTTP::Headers->new },
    handles => {
        header => 'header',
        header_add => 'push_header',
        header_remove => 'remove_header'
    },
);

has 'content' => (
    is => 'rw',
);

class_has 'SERIALIZER' => (
    is => 'rw',
    isa => 'Data::Serializer',
    lazy => 1,
    default => sub {
        Data::Serializer->new(
            serializer => 'Storable',
            compress   => 1,
        )
    },
);

__PACKAGE__->meta->make_immutable;

no Moose;
no MooseX::ClassAttribute;

sub serialize { 
    my $rv = eval { $_[0]->SERIALIZER->serialize($_[0]) };
    Carp::confess("Failed to serialize @_: $@") if $@;
    return $rv;
}
    
sub deserialize { 
    my $rv = eval { shift->SERIALIZER->deserialize(@_) };
    Carp::confess("Failed to deserialize @_: $@") if $@;
    return $rv;
}


1;

__END__

=head1 NAME

Mvalve::Message - A Message Object

=head1 SYNOPSIS

  use Mvalve::Message;

  my $message = Mvalve::Message->new(
    headers => {
      from => 'me',
      to   => 'you',
    },
    content => {
      random => 'content',
    }
  );

  my $serialized   = $message->serialize;
  my $materialized = Mvalve::Message->deserialize($serialized);

=head1 METHODS

=head2 BUILD

Custom BUILD() for Moose

=head2 SERIALIZER

Returns the serializer object to use 

=head2 serialize

Serializes the message

=head2 deserialize

Deserializes a packed structure to a message

=cut
