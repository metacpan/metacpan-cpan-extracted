package SIL::Encode_all;

=head1 TITLE

SIL::Encode_all - pulls in all Encode modules into packaged programs

=head1 DESCRIPTION

Lists all the Encode modules that will facilitate lots of encodings.

=cut

use Encode::Byte;
use Encode::Unicode;
use Encode::Symbol;
use Encode::CN;
use Encode::JP;
use Encode::KR;
use Encode::TW;

1;
