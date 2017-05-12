use strict;
use warnings;
use Test::More;
use Net::Gnats::Response;

isa_ok ( my $parent_ok = Net::Gnats::Response->new(type => 1),
         'Net::Gnats::Response' );
isa_ok my $child1_ok = Net::Gnats::Response->new(raw => ['001-one',
                                                         '002-two',
                                                         '003 three']),
  'Net::Gnats::Response';
isa_ok my $child2_ok = Net::Gnats::Response->new(raw => ['004-four',
                                                         '005-five',
                                                         '006 six']),
  'Net::Gnats::Response';

is_deeply $parent_ok->raw, [], 'parent_ok: raw is empty';
is_deeply $parent_ok->as_list, [], 'parent_ok: no data from children';
is        $parent_ok->code, 1, 'parent_ok: self and children OK';
is        $parent_ok->as_string, '', 'parent_ok: no children, empty string';

is_deeply $child1_ok->raw, ['001-one', '002-two', '003 three'], 'child1_ok: has list of three items';
is_deeply $child1_ok->as_list, [qw(one two three)], 'child1_ok: get raw children';
is        $child1_ok->code, '003', 'child1_ok: self and children OK';
is        $child1_ok->as_string, 'one two three', 'child1_ok: concatenated list';

is_deeply $child2_ok->raw, ['004-four', '005-five', '006 six'], 'child2_ok: has list of three items';
is_deeply $child2_ok->as_list, [qw(four five six)], 'child2_ok: get raw children';
is        $child2_ok->code, '006', 'child2_ok: self and children OK';
is        $child2_ok->as_string, 'four five six', 'child2_ok: concatenated list';

# add responses to parent and check
isa_ok $parent_ok->add($child1_ok), 'Net::Gnats::Response';
is_deeply $parent_ok->raw, [], 'parent_ok_c1: after child1 raw is empty';
is_deeply $parent_ok->as_list, [qw(one two three)], 'parent_ok_c1: after child1 data from children';
is        $parent_ok->code, 1, 'parent_ok_c1: self and children OK';
is        $parent_ok->as_string, 'one two three', 'parent_ok_c1: children, concatenated string';

isa_ok $parent_ok->add($child2_ok), 'Net::Gnats::Response';
is_deeply $parent_ok->raw, [], 'parent_ok_c2: after child1 raw is empty';
is_deeply $parent_ok->as_list, [qw(one two three),
                                qw(four five six)], 'parent_ok_c2: after child2 data from children';
is        $parent_ok->code, 1, 'parent_ok_c2: self and children OK';
is        $parent_ok->as_string, 'one two three, four five six', 'parent_ok_c2: children, string w children';


# add a bad code Result to a parent.  understand that one or more
# things went wrong.
# delay ... until really necessary.

done_testing;
