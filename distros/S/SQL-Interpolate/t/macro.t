use strict;
BEGIN {require 't/lib.pl';}
use Test::More 'no_plan';
use Data::Dumper;
use SQL::Interpolate qw(:all);
use SQL::Interpolate::Macro qw(:all); #FIX--OK interface?

my $interp = new SQL::Interpolate(sql_rel_filter({
    messageset => {name => qr/^([A-Z])$/, key => ['msid']},
    message    => {name => qr/^([m-p])$/, key => ['mid']},
    messageset_message => {
        name => qr/^([A-Z])([m-p])$/, key => ['msid', 'mid']},
    messageset_messageset => {
        name => qr/^([A-Z])([A-Z])$/, key => ['msid_1', 'msid_2']}
}));

# paren()
&flatten_test(
    ['WHERE', sql_paren(sql_paren('x = ', \5))],
    ['WHERE', '(', '(', 'x = ', \5, ')', ')'],
    'paren'
);

# and()
&flatten_test(
    [sql_and 'x=y', \5, sql('z=', \2)],
    ['(', '(', 'x=y', ')', 'AND', '(', \5, ')', 'AND', '(', 'z=', \2, ')', ')'],
    'and size > 0'
);
&flatten_test(
    [sql_and],
    ['1=1'],
    'and size = 0'
);
&flatten_test(  # fails in 0.31
    [sql_and sql],
    ['1=1'],
    'and sql() size = 0'
);

# or()
&flatten_test(
    [sql_or 'x=y', \5, sql('z=', \2)],
    ['(', '(', 'x=y', ')', 'OR', '(', \5, ')', 'OR', '(', 'z=', \2, ')', ')'],
    'or size > 0'
);
&flatten_test(
    [sql_or],
    ['1=0'],
    'or size = 0'
);
&flatten_test(  # fails in 0.31
    [sql_or sql],
    ['1=0'],
    'or sql() size = 0'
);

# or/and()
&flatten_test(
    [sql_or sql_and('x=y', \5), sql_and()],
    ['(', '(', '(', '(', 'x=y', ')', 'AND', '(', \5, ')', ')', ')', 'OR', '(', '1=1', ')', ')'],
    'or/and'
);


# rel() and link()
# AB and BC
&rel_test(
    ['SELECT * FROM REL(AB), REL(BC) WHERE LINK(AB,BC) A B C'],
    'SELECT * FROM messageset_messageset as AB , messageset_messageset as BC WHERE AB.msid_2 = BC.msid_1 AB.msid_1 BC.msid_1 BC.msid_2', 'AB,BC');
&rel_test(
    ['SELECT * FROM REL(BA), REL(BC) WHERE LINK(BA,BC) A B C'],
    'SELECT * FROM messageset_messageset as BA , messageset_messageset as BC WHERE BA.msid_1 = BC.msid_1 BA.msid_2 BC.msid_1 BC.msid_2', 'BA,BC');
&rel_test(
    ['SELECT * FROM REL(AB), REL(CB) WHERE LINK(AB,CB) A B C'],
    'SELECT * FROM messageset_messageset as AB , messageset_messageset as CB WHERE AB.msid_2 = CB.msid_2 AB.msid_1 CB.msid_2 CB.msid_1', 'AB,CB');
&rel_test(
    ['SELECT * FROM REL(AB), REL(BC) WHERE LINK(BC,AB) A B C'],
    'SELECT * FROM messageset_messageset as AB , messageset_messageset as BC WHERE BC.msid_1 = AB.msid_2 AB.msid_1 BC.msid_1 BC.msid_2', 'AB,BC 2');

# AB and Bm
&rel_test(
    ['SELECT * FROM REL(AB), REL(Bm) WHERE LINK(AB,Bm) A B m'],
    'SELECT * FROM messageset_messageset as AB , messageset_message as Bm WHERE AB.msid_2 = Bm.msid AB.msid_1 Bm.msid Bm.mid', 'AB,Bm');
&rel_test(
    ['SELECT * FROM REL(BA), REL(Bm) WHERE LINK(BA,Bm) A B m'],
    'SELECT * FROM messageset_messageset as BA , messageset_message as Bm WHERE BA.msid_1 = Bm.msid BA.msid_2 Bm.msid Bm.mid', 'BA,Bm');

# AB and A
&rel_test(
    ['SELECT * FROM REL(AB), REL(A) WHERE LINK(AB,A) A B'],
    'SELECT * FROM messageset_messageset as AB , messageset as A WHERE AB.msid_1 = A.msid A.msid AB.msid_2', 'AB,A');
&rel_test(
    ['SELECT * FROM REL(BA), REL(A) WHERE LINK(BA,A) A B'],
    'SELECT * FROM messageset_messageset as BA , messageset as A WHERE BA.msid_2 = A.msid A.msid BA.msid_1', 'BA,A');
&rel_test(
    ['SELECT * FROM REL(AB), REL(A) WHERE LINK(A,AB) A B'],
    'SELECT * FROM messageset_messageset as AB , messageset as A WHERE A.msid = AB.msid_1 A.msid AB.msid_2', 'AB,A 2');

# Am and m
&rel_test(
    ['SELECT * FROM REL(Am), REL(m) WHERE LINK(Am,m)'],
    'SELECT * FROM messageset_message as Am , message as m WHERE Am.mid = m.mid', 'Am,m');
&rel_test(
    ['SELECT * FROM REL(Am), REL(m) WHERE LINK(m,Am)'],
    'SELECT * FROM messageset_message as Am , message as m WHERE m.mid = Am.mid', 'Am,m 2');

# Am and A
&rel_test(
    ['SELECT * FROM REL(Am), REL(A) WHERE LINK(Am,A)'],
    'SELECT * FROM messageset_message as Am , messageset as A WHERE Am.msid = A.msid', 'Am,A');
&rel_test(
    ['SELECT * FROM REL(Am), REL(A) WHERE LINK(A,Am)'],
    'SELECT * FROM messageset_message as Am , messageset as A WHERE A.msid = Am.msid', 'Am,A 2');

# AB and BC and CA
&rel_test(
    ['SELECT * FROM REL(AB), REL(BC), REL(CA) WHERE LINK(AB,BC,CA)'],
    'SELECT * FROM messageset_messageset as AB , messageset_messageset as BC , messageset_messageset as CA WHERE (AB.msid_2 = BC.msid_1 AND BC.msid_2 = CA.msid_1 AND AB.msid_1 = CA.msid_2)', 'AB,BC,CA');

# AB and BC and Cm and m
&rel_test(
    ['SELECT * FROM REL(AB), REL(BC), REL(Cm), REL(m) WHERE LINK(AB,BC,Cm,m)'],
    'SELECT * FROM messageset_messageset as AB , messageset_messageset as BC , messageset_message as Cm , message as m WHERE (AB.msid_2 = BC.msid_1 AND BC.msid_2 = Cm.msid AND Cm.mid = m.mid)', 'AB,BC,Cm,m');

# Am and Bm and Cm
&rel_test(
    ['SELECT * FROM REL(Am), REL(Bm), REL(Cm) WHERE LINK(Am,Bm,Cm) AND A B C m'],
    'SELECT * FROM messageset_message as Am , messageset_message as Bm , messageset_message as Cm WHERE (Am.mid = Bm.mid AND Bm.mid = Cm.mid) AND Am.msid Bm.msid Cm.msid Cm.mid', 'Am,Bm,Cm');


sub flatten_test
{
    my($snips, $expect, $name) = @_;

    my_deeply([sql_flatten @$snips], $expect, $name);
}



#FIX--broken test
#$interp = new SQL::Interpolate();
#$interp->sql_rel_filter({
#    sales_order => {name => qr/([S-T])/, key => ['so_nbr']},
#    part => {name => qr/([p-r])/, key => ['part_nbr']},
#    sales_order_line => {
#        name => qr/([S-T])([p-r])/, key => ['so_nbr', 'part_nbr']}
#});
#
#&filter_sql_test($interp,
#    "SELECT * FROM REL(S), REL(Sp), REL(p) WHERE LINK(S,Sp,p) AND S = 123",
#    "SELECT * FROM sales_order as S, sales_order_line as Sp, part as p WHERE (S.so_nbr = Sp.so_nbr AND Sp.part_nbr = p.part_nbr) AND Sp.so_nbr = 123", 't');


sub filter_sql_test
{
    my($interp, $input, $expect, $name) = @_;
    my_deeply($interp->filter_sql($input), $expect, $name);
}



#IMPROVE
sub rel_test
{
    my($snips, $expect, $name) = @_;

    my_deeply($interp->sql_interp(@$snips), $expect, $name);
}


#IMPROVE--handle this (auto-LINK AB and BC)
# SELECT * FROM REL(AB,BC)
# SELECT * FROM REL(AB LEFT JOIN BC)


# IMPROVE--handle cases like this
#$interp->sql_rel_filter({
#    messageset => {name => qr/([A-Z])/, key => [msid => undef]},
#    message    => {name => qr/([m-p])/, key => [mid  => undef]},
#    user       => {name => qr/([u-z])/, key => [uid  => undef]},
#    messageset_message => {name => qr/([A-Z])([m-p])([u-z])/, key => [
#        msid   => 'messageset',
#        mid    => 'message',
#        uid    => 'user'
#    ]},
#    messageset_messageset => {name => qr/([A-Z])([A-Z])/, key => [
#        msid_1 => 'messageset',
#        msid_2 => 'messageset'
#    ]},
#});
# SELECT * FROM REL(Amu), REL(m), REL(u) WHERE LINK(Amu,m,u)


