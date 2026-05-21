package Nobody::JSON;
our @EXPORT    = qw( json );
our @EXPORT_OK = qw( encode_json decode_json );
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );
BEGIN {
  *import=\&Exporter::import;
}
use Exporter;
use FindBin qw($RealBin);
use Nobody::Util;
use Carp::Always;
use JSON::XS;
use common::sense;
our $VERSION = '0.01';

# Lazy-initialised encoder configured for maximum readability:
# - ascii: escape non-ASCII so output is safe in any context
# - pretty: human-readable indented output
# - allow_nonref: encode bare scalars, not just objects/arrays
INIT {
  sub new {
    my($class)=class(shift);
    my($json)=JSON::XS->new;
    $json->ascii;
    $json->encode(1);
    $json->canonical(1);
    $json->pretty;
    $json->allow_nonref;
    $json->allow_blessed;
    $json->convert_blessed;
    my($self)=bless([$json],$class);
    $self;
  }; 
};
sub json {
  local(@_)=@_;
  state($json);
  unless(defined($json)){
    $json=Nobody::JSON->new;
  };
  $json;
};
sub load {
  die "you can't do that!" unless safe_can($_[0],"load");
  die "usage: json->load( path(x) )" unless (
    @_==2 and ref($_[1])
  );
  local(@_)=@_;
  my($self)=shift;
  my($src)=shift;
  my $txt=$src->slurp;
  my $obj=$self->decode($txt);
  $obj;
};
sub save {
  die "you can't do that!" unless safe_can($_[0],"save");
  my($self)=shift;
  die "too many args" if @_>2;
  my($dst)=shift;
  local($_)=$self->encode($_[0]);
  $dst->spew($_);
};
sub json_encode {
  local(@_)=@_;
  json->encode(@_);
};
sub json_decode {
  local(@_)=@_;
  json->decode(@_);
};
sub encode_json($) { json->encode(shift) }
sub decode_json($) {  json->decode(shift) }
sub encode {
  local(@_)=@_;
  die "you can't do that!" unless safe_can($_[0],"encode");
  my($self)=shift;
  $self->[0]->encode(@_);
};
sub decode {
  die "you can't do that!" unless safe_can($_[0],"decode");
  local(@_)=@_;
  my($self)=shift;
  $self->[0]->decode("@_");
}
1;

=head1 NAME

Nobody::JSON - JSON encoding with the prettiest possible output

=head1 SYNOPSIS

  use Nobody::JSON;

  my $json = encode_json({ key => "value", list => [1, 2, 3] });
  my $data = decode_json($json);

=head1 DESCRIPTION

C<Nobody::JSON> is a thin wrapper around C<JSON::XS> that configures the
encoder for maximum human readability: ASCII-safe output, pretty-printed
with indentation, and support for non-reference scalars.

The interface is intentionally compatible with C<JSON::XS>, C<JSON::PP>,
C<Cpanel::JSON::XS>, and any other JSON module that exports C<encode_json>
and C<decode_json> with the same prototypes.

=head1 EXPORTS

C<encode_json> and C<decode_json> are exported by default.
C<json_encode> and C<json_decode> are available as aliases via C<:all>
or explicit import.

=head1 FUNCTIONS

=head2 encode_json( $data )

Encodes C<$data> to a pretty-printed, ASCII-safe JSON string.

=head2 decode_json( $json )

Decodes a JSON string to a Perl data structure.  Thin pass-through to
C<JSON::XS::decode_json>.

=head1 AUTHOR

Rich Paul, C<< <nobody at cpan.org> >>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
