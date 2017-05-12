#########
# Author:        rmp
# Maintainer:    $Author: rmp $
# Created:       2008-08-13
# Last Modified: $Date$
# Id:            $Id$
# $HeadURL$
#
package Net::Plazes::Base;
use strict;
use warnings;
use base qw(Class::Accessor);
use Carp;
use English qw(-no_match_vars);
use HTTP::Request;
use LWP::UserAgent;
use XML::LibXML;
use Lingua::EN::Inflect qw(PL);

our $VERSION = '0.03';

__PACKAGE__->mk_accessors(fields());

sub new {
  my ($class, $ref) = @_;
  $ref ||= {};
  bless $ref, $class;
  return $ref;
}

sub service {
  return q[];
}

sub doc_element {
  my $self  = shift;
  my ($ref) = (ref $self || $self) =~ /([^:]+)$/mx;
  my $el    = lc $ref;

  return $el;
}

sub fields {
  return ();
}

sub useragent {
  my $self = shift;

  if(!$self->{useragent}) {
    $self->{useragent} = LWP::UserAgent->new();
    $self->{useragent}->env_proxy();
    $self->{useragent}->agent(qq[Net::Plazes v$VERSION]);
  }

  return $self->{useragent};
}

sub parser {
  my $self = shift;

  if(!$self->{parser}) {
    $self->{parser} = XML::LibXML->new();
  }

  return $self->{parser};
}

sub process_dom {
  my ($self, $obj, $dom) = @_;

  for my $field ($self->fields()) {
    my $els = [$dom->getElementsByTagName($field)];
    if($els->[0]) {
      my $fc = $els->[0]->getFirstChild();
      if($fc) {
	$obj->{$field} = $fc->getData();
      } else {
	$obj->{$field} = q[];
      }
    }
  }

  return $obj;
}

sub has_many {
  my $class  = shift;
  my $plural = PL($class->doc_element());
  my $ns     = "${class}::$plural";

  no strict 'refs'; ## no critic

  *{$ns} = sub {
    my $self = shift;

    if(!$self->{$plural}) {
      $self->list();
    }

    return $self->{$plural};
  };

  use strict;
  return 1;
}

sub get {
  my ($self, $field) = @_;
  if(defined $self->{$field}) {
    return $self->{$field};
  }

  if($self->{id}) {
    $self->read();

  } else {
    $self->list();
  }

  return $self->{$field};
}

sub read { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
  my $self     = shift;
  my $obj_uri  = sprintf q[%s/%s], $self->service(), $self->id();
  if($obj_uri !~ /\.xml$/mx) {
    $obj_uri .= q[.xml];
  }
  my $req      = HTTP::Request->new('GET', $obj_uri, ['Accept' => 'text/xml']);
  my $response = $self->useragent->request($req);

  if(!$response->is_success()) {
    croak $response->status_line() . " fetching $obj_uri";
  }

  my $dom;
  eval {
    $dom = $self->parser->parse_string($response->content());

  } or do {
    croak q[Error parsing response] . $response->content(). qq[\nRequest was: $obj_uri];
  };

  $self->process_dom($self, $dom);

  return $dom;
}

sub list {
  my ($self, $obj_uri) = @_;
  $obj_uri   ||= $self->service();

  if($obj_uri !~ /\.xml$/mx) {
    $obj_uri .= q[.xml];
  }

  my $req      = HTTP::Request->new('GET', $obj_uri, ['Accept' => 'text/xml']);
  my $response = $self->useragent->request($req);

  my $dom;
  eval {
    $dom = $self->parser->parse_string($response->content());
    1;
  } or do {
    croak q[Error parsing response: ] . $response->content(). qq[\nRequest was: $obj_uri];
  };

  my $objs = [];
  my $els  = [$dom->getElementsByTagName($self->doc_element())];

  for my $el (@{$els||[]}) {
    my $pkg = ref $self;
    push @{$objs}, $self->process_dom($pkg->new(), $el);
  }

  $self->{PL($self->doc_element())} = $objs;
  return $dom;
}

1;
__END__

=head1 NAME

Net::Plazes::Base - base/super- class for Net::Plazes::*

=head1 VERSION

$Revision$

=head1 SYNOPSIS

 use base qw(Net::Plazes::Base);

 sub fields {
  return qw(id field_one field_two);
 }

=head1 DESCRIPTION

Net::Plazes::Base shouldn't be used directly. It's designed to be
inherited from to represent various concrete resources, see
Net::Plazes::Plaze, Net::Plazes::User, Net::Plazes::Presence

=head1 SUBROUTINES/METHODS

=head2 new - constructor

=head2 service - service url for entities of this type

=head2 doc_element - name of top-level dom element this resource represents

=head2 fields - list of accessors for resources of this type

 my @aFields = $oObj->fields();

=head2 useragent - (cached) LWP::Useragent object

=head2 parser - (cached) XML::LibXML object

=head2 get - Class::Accessor override for triggering web fetches

=head2 process_dom - process accessors data from dom

=head2 has_many - compile-time accessor setup for list() fetching

=head2 read - fetch and process element with this id

=head2 list - fetch and process all available elements

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Carp

=item English -no_match_vars

=item HTTP::Request

=item LWP::UserAgent

=item XML::LibXML

=item Class::Accessor

=item Lingua::EN::Inflect

=item base

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
