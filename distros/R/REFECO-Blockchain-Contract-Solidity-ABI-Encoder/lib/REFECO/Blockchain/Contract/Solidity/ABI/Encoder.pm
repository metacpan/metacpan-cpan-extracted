package REFECO::Blockchain::Contract::Solidity::ABI::Encoder;

use strict;
use warnings;
no indirect;

=head1 NAME

REFECO::Blockchain::Contract::Solidity::ABI::Encoder - Contract Application Binary Interface argument encoder

=head1 VERSION

Version 0.001

=cut

our $VERSION = '0.001';

=head1 SYNOPSIS

The Contract Application Binary Interface (ABI) is the standard way to interact
with contracts (Ethereum), this module aims to be an utility to encode the given
data according ABI type specification.

    my $encoder = REFECO::Blockchain::Contract::Solidity::ABI::Encoder->new();
    $encoder->function('test')
        # string
        ->append(string => 'Hello, World!')
        # bytes
        ->append(bytes => unpack("H*", 'Hello, World!'))
        # tuple
        ->append('(uint256,address)' => [75000000000000, '0x0000000000000000000000000000000000000000'])
        # arrays
        ->append('bool[]', [1, 0, 1, 0])
        # multidimensional arrays
        ->append('uint256[][][2]', [[[1]], [[2]]])
        # tuples arrays and tuples inside tuples
        ->append('((int256)[2])' => [[[1], [2]]])->encode();
    ...

=head1 AUTHOR

Reginaldo Costa, C<< <refeco at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-refeco-blockchain-smartcontracts-solidity-abi-encoder at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=REFECO-Blockchain-Contract-Solidity-ABI-Encoder>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc REFECO::Blockchain::Contract::Solidity::ABI::Encoder


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=REFECO-Blockchain-Contract-Solidity-ABI-Encoder>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/REFECO-Blockchain-Contract-Solidity-ABI-Encoder>

=item * Search CPAN

L<https://metacpan.org/release/REFECO-Blockchain-Contract-Solidity-ABI-Encoder>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Reginaldo Costa.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

use Carp;
use Digest::Keccak qw(keccak_256_hex);
use REFECO::Blockchain::Contract::Solidity::ABI::Type;
use REFECO::Blockchain::Contract::Solidity::ABI::Type::Tuple;

sub new {
    my ($class, %params) = @_;

    my $self = {};
    bless $self, $class;
    return $self;
}

sub instances {
    my $self = shift;
    return $self->{instances} //= [];
}

sub function_name {
    my $self = shift;
    return $self->{function_name};
}

=head2 append

Appends type signature and the respective values to the encoder

=over 4

=item * C<%param> key is the respective type signature followed by the value e.g. uint256 => 10

=back

return same L<REFECO::Blockchain::Contract::Solidity::ABI::Encoder> instance

=cut

sub append {
    my ($self, %param) = @_;

    for my $type_signature (keys %param) {
        push(
            $self->instances->@*,
            REFECO::Blockchain::Contract::Solidity::ABI::Type::new_type(
                signature => $type_signature,
                data      => $param{$type_signature}));
    }

    return $self;
}

=head2 function

Appends the function name to the encoder, this is optional for when you want the
function signature added to the converted string or only the name converted

=over 4

=item * C<function_name> solidity function name e.g. for `transfer(address,uint256)` will be `transfer`

=back

return same L<REFECO::Blockchain::Contract::Solidity::ABI::Encoder> instance

=cut

sub function {
    my ($self, $function_name) = @_;
    $self->{function_name} = $function_name;
    return $self;
}

=head2 generate_function_signature

Based on the given function name and type signatures create the full function
signature

=over 4

=back

string function signature

=cut

sub generate_function_signature {
    my $self = shift;
    croak "Missing function name e.g. ->function('name')" unless $self->function_name;
    my $signature = $self->function_name . '(';
    $signature .= sprintf("%s,", $_->signature) for $self->instances->@*;
    chop $signature;
    return $signature . ')';
}

=head2 encode_function_signature

Encode function signature, this function can be called directly but in most of
cases you just want to let the module take care of it for you calling `function`
instead

=over 4

=item C<signature> function signature, if not give method will try to use the one given by `function`

=back

encoded function signature string prefixed with 0x

=cut

sub encode_function_signature {
    my ($self, $signature) = @_;
    return sprintf("0x%.8s", keccak_256_hex($signature // $self->generate_function_signature));
}

=head2 encode

Encodes all appended type signatures and the function name (if given)

=over 4

=back

Encoded string, if function name given will be 0x prefixed

=cut

sub encode {
    my $self = shift;

    my $tuple = REFECO::Blockchain::Contract::Solidity::ABI::Type::Tuple->new;
    $tuple->{instances} = $self->instances;
    my @data = $tuple->encode->@*;
    unshift @data, $self->encode_function_signature if $self->function_name;

    return join('', @data);
}

=head2 clean

Clean all the appended type signatures and the function name

=over 4

=back

undef

=cut

sub clean {
    my $self = shift;
    delete $self->{instances};
    undef $self->{function_name};
}

1;

