use Test2::V0;

skip_all "FIXME: not yet written";

use String::Copyright;

done_testing;

__END__

FIXME:
  * raw strings should succeed on both latin1 and utf8 ©
  * utf8 strings should fail on latin1 © and succeed on utf8 ©
  * utf8 strings should succeed on double-byte names
  * utf8 strings should correctly normalize double-byte merged lines
  * utf8 strings should cleanup double-byte whitespace and exotic markers
