use strict;
use warnings;
package Net::Disqus::Exception;
BEGIN {
  $Net::Disqus::Exception::VERSION = '1.19';
}
use base 'Class::Accessor';
use overload '""' => \&overload_text;
__PACKAGE__->mk_accessors(qw(code text));

sub overload_text { return shift->text }
1;
