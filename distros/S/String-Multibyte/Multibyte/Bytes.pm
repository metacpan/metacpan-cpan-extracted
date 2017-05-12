package String::Multibyte::Bytes;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'bytes',
    regexp   => '[\x00-\xFF]',
    nextchar =>
	sub {
	    my $c = unpack('C', shift);
	    $c == 0xFF ? undef : pack('C', 1+$c);
	},
    cmpchar => sub { $_[0] cmp $_[1] },
};

__END__

=head1 NAME

String::Multibyte::Bytes - internally used by String::Multibyte for bytes encoding scheme

=head1 SYNOPSIS

    use String::Multibyte;

    $bytes = String::Multibyte->new('Bytes');
    $byte_length = $bytes->length($string);

=head1 DESCRIPTION

C<String::Multibyte::Bytes> is used for string manipulation in bytes.

Character order: C<0x00..0xff>

=head1 SEE ALSO

L<String::Multibyte>

=cut
