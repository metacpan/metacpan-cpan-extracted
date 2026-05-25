package Protocol::Tus::AbstractModel;
{ our $VERSION = '0.001' }
use Moo;
use v5.24;
use warnings;
use experimental qw< signatures >;
use List::Util qw< any >;
use namespace::clean;

has max_size => (is => 'ro', default => undef);

sub cleanup ($self, $id)                     { ... }
sub create_upload($self, $length, $metadata) { ... }
sub extensions ($self)                       { ... }
sub finalize ($self, $id)                    { ... }
sub get_info ($self, $id)                    { ... }
sub save_chunk ($self, $offset, $dref)       { ... }
sub set_length ($self, $id, $length)         { ... }

sub extensions_as_string ($self) {
   return join(',', $self->extensions);
}

sub get_offset ($self, $id) {
   return $self->get_info($id)->{offset} // undef;
}

sub is_complete ($self, $id) {
   return $self->get_info($id)->{complete} // undef;
}

sub supports_extension ($self, $extension) {
   return any { $_ eq $extension } $self->extensions;
}

1;
