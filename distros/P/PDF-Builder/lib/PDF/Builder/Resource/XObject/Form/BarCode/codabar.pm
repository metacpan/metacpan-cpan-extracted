package PDF::Builder::Resource::XObject::Form::BarCode::codabar;

use base 'PDF::Builder::Resource::XObject::Form::BarCode';

use strict;
use warnings;

our $VERSION = '3.012'; # VERSION
my $LAST_UPDATE = '2.029'; # manually update whenever code is changed

=head1 NAME

PDF::Builder::Resource::XObject::Form::BarCode::codabar - specific information for CodaBar bar codes. Inherits from L<PDF::Builder::Resource::XObject::Form::BarCode>

=cut

sub new {
    my ($class, $pdf, %options) = @_;

    my $self = $class->SUPER::new($pdf, %options);

    my @bars = $self->encode($options{'-code'});

    $self->drawbar([@bars], $options{'caption'});

    return $self;
}

# allowed alphabet and translation to bar widths
my $codabar = q|0123456789-$:/.+ABCD|;

my @barcodabar = qw(
    11111221 11112211 11121121 22111111 11211211
    21111211 12111121 12112111 12211111 21121111
    11122111 11221111 21112121 21211121 21212111
    11212121 aabbabaa ababaaba ababaaba aaabbbaa
);

sub encode_char {
    my $self = shift;
    my $char = uc(shift());

    return $barcodabar[index($codabar, $char)];
}

1;
