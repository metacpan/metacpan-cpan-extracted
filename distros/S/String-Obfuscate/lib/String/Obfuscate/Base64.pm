use v5.20;
use warnings;
use experimental 'signatures';

package String::Obfuscate::Base64 {
  use parent 'String::Obfuscate';
  use constant B64_CHARS => ['a'..'z', 'A'..'Z', 0..9, '+', '/'];
  use MIME::Base64 qw(encode_base64 decode_base64);

  sub new ($class, %params) {
    die 'Cannot use custom chars in Base64 mode' if exists $params{'chars'};
    $class->SUPER::new(chars => B64_CHARS, %params);
  }

  sub obfuscate   ($self, $str) { $self->SUPER::obfuscate(encode_base64($str)) }
  sub deobfuscate ($self, $str) { decode_base64($self->SUPER::deobfuscate($str)) }
}

1;
