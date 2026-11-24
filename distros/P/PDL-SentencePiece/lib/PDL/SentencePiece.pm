package PDL::SentencePiece;

use 5.010;
use strict;
use warnings;
use Carp qw(croak);
use XSLoader;
use PDL::Core ();
use PDL::Lite ();

our $VERSION = '0.01';

XSLoader::load('PDL::SentencePiece', $VERSION);

sub new {
    my ($class, %args) = @_;
    my $self = $class->_new();
    if (defined $args{model}) {
        $self->load($args{model});
    }
    return $self;
}

sub load {
    my ($self, $file) = @_;
    croak 'Model filename required' unless defined $file;
    $self->_load($file) or croak "Failed to load SentencePiece model '$file'";
    return $self;
}

sub encode {
    my ($self, $text) = @_;
    my $ids = $self->_encode_as_ids($text // '');
    return PDL::Core::pdl(PDL::long(), $ids);
}

sub decode {
    my ($self, $ids_pdl) = @_;
    my @ids = ref($ids_pdl) && eval { $ids_pdl->isa('PDL') }
        ? $ids_pdl->list
        : (ref($ids_pdl) eq 'ARRAY' ? @{$ids_pdl} : ());
    return $self->_decode_ids(\@ids);
}

1;

__END__

=head1 NAME

PDL::SentencePiece - SentencePiece C++17/XS tokenizer bindings for PDL ndarrays

=head1 SYNOPSIS

    use PDL::SentencePiece;

    my $sp  = PDL::SentencePiece->new(model => 'tokenizer.model');
    my $ids = $sp->encode('Hello, world!');  # PDL long ndarray
    my $txt = $sp->decode($ids);

=head1 DESCRIPTION

C<PDL::SentencePiece> provides C++17/XS bindings to Google's
C<libsentencepiece> library, encoding text directly into L<PDL> C<long>
token-ID ndarrays and decoding token ndarrays back to text.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Google LLC. Apache License, Version 2.0.

=cut
