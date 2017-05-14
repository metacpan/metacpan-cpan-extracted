package T1;
use base 'Object::Simple';

use strict;
use warnings;

__PACKAGE__->attr('m1');
__PACKAGE__->class_attr('m2');
__PACKAGE__->dual_attr('m3');

__PACKAGE__->attr([qw/m4_1 m4_2/]);
__PACKAGE__->class_attr([qw/m5_1 m5_2/]);
__PACKAGE__->dual_attr([qw/m6_1 m6_2/]);

__PACKAGE__->class_attr('m9', default => 9);
__PACKAGE__->dual_attr('m10', default => 10);

__PACKAGE__->attr('m11' => 1);
__PACKAGE__->attr('m12' => sub { 9 });

__PACKAGE__->class_attr('m13' => 'm13');
__PACKAGE__->class_attr('m14' => sub { 'm14' });

__PACKAGE__->dual_attr('m15' => 'm15');
__PACKAGE__->dual_attr('m16' => sub { 'm16' });

__PACKAGE__->attr([qw/m18 m19/] => 5);
__PACKAGE__->class_attr([qw/m20 m21/] => 6);
__PACKAGE__->dual_attr([qw/m22 m23/] => 7);


__PACKAGE__->dual_attr('m24', default => sub { {a => 1} },
                              inherit => 'hash_copy');

__PACKAGE__->dual_attr('m25', default => sub { [1, 2] },
                              inherit => 'array_copy');

__PACKAGE__->dual_attr('m26', default => 1,
                              inherit => 'scalar_copy');

__PACKAGE__->class_attr('m27', default => sub { {} }, inherit => 'hash_copy');
__PACKAGE__->m27->{a1} = 1;

__PACKAGE__->class_attr('m28', default => sub { [] }, inherit => 'array_copy');
__PACKAGE__->m28->[0] = 1;

__PACKAGE__->class_attr('m29', default => sub { shift->m30 }, inherit => 'scalar_copy');
__PACKAGE__->dual_attr('m30', default => 5);

__PACKAGE__->attr(m31 => sub { shift->m30 });
__PACKAGE__->class_attr(m32 => sub { shift->m30 });

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

__PACKAGE__->m27->{a2} = 2;
__PACKAGE__->m28->[1] = 2;

package T1_3;
use base 'T1_2';

1;
