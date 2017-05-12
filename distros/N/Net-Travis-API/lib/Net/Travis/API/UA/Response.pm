use 5.010;    # _Pulp__5010_qr_m_propagate_properly
use strict;
use warnings;

package Net::Travis::API::UA::Response;

our $VERSION = '0.002001';

# ABSTRACT: Subclass of HTTP::Tiny::UA::Response for utility methods

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













use Moo qw( extends has );




























use Encode qw( FB_CROAK );

extends 'HTTP::Tiny::UA::Response';









has 'json' => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require JSON::MaybeXS;
    return JSON::MaybeXS->new();
  },
);













sub content_type {
  my ($self) = @_;
  return unless exists $self->headers->{'content-type'};
  return
    unless my ($type) = $self->headers->{'content-type'} =~ qr{ \A ( [^/]+ / [^;]+ ) }msx;
  return $type;
}
















sub content_type_params {
  my ($self) = @_;
  return [] unless exists $self->headers->{'content-type'};
  return []
    unless my (@params) = $self->headers->{'content-type'} =~ qr{ (?:;([^;]+))+ }msx;
  return [@params];
}

















sub decoded_content {
  my ( $self, $force_encoding ) = @_;
  if ( not $force_encoding ) {
    return $self->content if not my $type = $self->content_type;
    return $self->content unless $type =~ qr{ \Atext/ }msx;
    for my $param ( @{ $self->content_type_params } ) {
      if ( $param =~ qr{ \Acharset=(.+)\z }msx ) {
        $force_encoding = $param;
      }
    }
    return $self->content if not $force_encoding;
  }
  return Encode::decode( $force_encoding, $self->content, Encode::FB_CROAK );
}


















sub content_json {
  my ( $self, $force ) = @_;
  my ($has_force) = ( @_ > 1 );

  my %whitelist = ( 'application/json' => 1 );
  return unless $has_force or exists $whitelist{ $self->content_type };
  my $charset = 'utf-8';
  if ( $has_force and defined $force ) {
    $charset = $force;
  }
  else {
    for my $param ( @{ $self->content_type_params } ) {
      next unless $param =~ /\Acharset=(.+)\z/msx;
      $charset = $1;
    }
  }
  return $self->json->utf8(0)->decode( $self->decoded_content($charset) );
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Travis::API::UA::Response - Subclass of HTTP::Tiny::UA::Response for utility methods

=head1 VERSION

version 0.002001

=head1 DESCRIPTION

This class warps extends C<HTTP::Tiny::UA::Response> and adds a few utility methods
and features that either

=over 4

=item 1. Have not yet been approved for merge

=over 2

=item * L<< github-pull:HTTP-Tiny-UA#3|https://github.com/dagolden/HTTP-Tiny-UA/pull/3 >>

=back

=item 2. Don't make sense to propagate to a general purpose HTTP User Agent.

=over 2

=item * L<< C<content_json>|/content_json >>

=back

=back

=head1 METHODS

=head2 content_type

Returns the L<< C<type/subtype>|http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.7 >> portion of the C<content-type> header.

Returns C<undef> if there was no C<content-type> header.

    if ( $result->content_type eq 'application/json' ) {
        ...
    }

=head2 content_type_params

Returns all L<< C<parameter>|http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.7 >> parts of the C<content-type> header
as an C<ArrayRef>.

Returns an empty C<ArrayRef> if no such parameters were sent in the C<content-type> header, or there was no C<content-type> header.

    for my $header ( @{ $result->content_type_params } ) {
        if ( $header =~ /^charset=(.+)/ ) {
            print "A charset of $1 was specified! :D";
        }
    }

=head2 decoded_content

Returns L<< C<< ->content >>|/content >> after applying type specific decoding.

At present, this means everything that is not C<text/*> will simply yield C<< ->content >>

And everything that is C<text/*> without a C<text/*;charset=someencoding> will simply yield C<< ->content >>

    my $foo = $result->decoded_content(); # text/* with a specified encoding interpreted properly.

Optionally, you can pass a forced encoding to apply and override smart detection.

    my $foo = $result->decoded_content('utf-8'); # type specific encodings ignored, utf-8 forced.

=head2 C<content_json>

Returns a the data decoded from JSON.

Returns C<undef> if the data

    ->content_json() # decodes automatically as per applicable encoding
                   # or returns undef if its not application/json

    ->content_json(undef) # Forces decoding as json, but defers the text encoding
                        # method to use either utf-8 or an encoding specified
                        # by a ;charset= parameter.

    ->content_json('utf-8') # Forces decoding as json, and forces the text decoding to utf-

=head1 ATTRIBUTES

=head2 C<json>

I<Optional.>

A JSON Object for decoding JSON

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::Travis::API::UA::Response",
    "interface":"class",
    "inherits":"HTTP::Tiny::UA::Response"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
