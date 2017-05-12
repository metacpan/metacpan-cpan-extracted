package String::Multibyte::UTF8;

use vars qw($VERSION);
$VERSION = '1.12';

+{
    charset  => 'UTF-8',

    regexp   => '(?:[\x00-\x7F]|[\xC2-\xDF][\x80-\xBF]|' .
	'\xE0[\xA0-\xBF][\x80-\xBF]|\xED[\x80-\x9F][\x80-\xBF]|' .
	'[\xE1-\xEC\xEE\xEF][\x80-\xBF][\x80-\xBF]|' .
	'\xF0[\x90-\xBF][\x80-\xBF][\x80-\xBF]|' .
	'[\xF1-\xF3][\x80-\xBF][\x80-\xBF][\x80-\xBF]|' .
	'\xF4[\x80-\x8F][\x80-\xBF][\x80-\xBF])',

    cmpchar => sub { $_[0] cmp $_[1] },

    nextchar => sub {
	my $ch = shift;
	my $len = length $ch;
	if ($len < 1 || 4 < $len) {
	    return undef;
	}
	elsif ($len == 1) {
	    return $ch eq "\x7F"
		? "\xC2\x80"
		: chr(ord($ch)+1);
	}
	elsif ($len == 2) {
	    my($c,$d) = unpack('CC',$ch);
	    return $ch eq "\xDF\xBF"
		? "\xE0\xA0\x80"
		: $d == 0xBF
		    ? chr($c+1)."\x80"
		    : pack('CC', $c, $d+1);
	}
	elsif ($len == 3) {
	    my($c,$d,$e) = unpack('CCC',$ch);
	    return $ch eq "\xEF\xBF\xBF"
		? "\xF0\x90\x80\x80"
		: $ch eq "\xED\x9F\xBF"
		    ? "\xEE\x80\x80"
		    : $e == 0xBF
			? $d == 0xBF
			    ? chr($c+1)."\x80\x80"
			    : pack('CCC', $c, $d+1, 0x80)
			: pack('CCC', $c, $d, $e+1);
	}
	else {
	    my($c,$d,$e,$f) = unpack('CCCC',$ch);
	    return $ch ge "\xF4\x8F\xBF\xBF"
		? undef
		    : $f == 0xBF
			? $e == 0xBF
			    ? $d == 0xBF
				? chr($c+1)."\x80\x80\x80"
				: pack('CCCC', $c, $d+1, 0x80, 0x80)
			    : pack('CCCC', $c, $d, $e+1, 0x80)
			: pack('CCCC', $c, $d, $e, $f+1);
	}
    },
};

__END__

=head1 NAME

String::Multibyte::UTF8 - internally used
by String::Multibyte for UTF-8

=head1 SYNOPSIS

    use String::Multibyte;

    $utf8 = String::Multibyte->new('UTF8');
    $utf8_length = $utf8->length($utf8_string);

=head1 DESCRIPTION

C<String::Multibyte::UTF8> is used for manipulation of strings in UTF-8.

Character order: C<U+00..U+D7FF>, C<U+E000..U+10FFFF>.

=head1 CAVEAT

Surrogate characters C<U+D800..U+DFFF> are excluded.

=head1 SEE ALSO

L<String::Multibyte>

=cut
