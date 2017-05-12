package T1;
use base 'Object::Simple';

use strict;
use warnings;

__PACKAGE__->attr('m1');
__PACKAGE__->attr([qw/m4_1 m4_2/]);
__PACKAGE__->attr('m11' => 1);
__PACKAGE__->attr('m12' => sub { 9 });
__PACKAGE__->attr([qw/m18 m19/] => 5);
__PACKAGE__->attr(
    [qw/m33 m34/],
    m35 => 1,
    m36 => sub { 5 }
);

__PACKAGE__->attr(
    m37 => 1,
    m38 => sub { 5 }
);

package T1_2;
use base 'T1';

package T1_3;
use base 'T1_2';

1;
