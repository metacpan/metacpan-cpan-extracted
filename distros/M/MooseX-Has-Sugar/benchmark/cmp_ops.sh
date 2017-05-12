##
# cmp_ops.sh $PERL  $CODEA $CODEB
# cmp_ops.sh 5.10.1 'sub baz { code here }' 'sub baz { slightly different code here }'
#
# where  5.10.1 would respond to 'perlbrew use 5.10.1'
# and $CODEA and $CODEB both have a sub 'baz' in them.
#
# eg: bash benchmark/cmp_ops.sh  5.10.1 'sub baz { return q[a] }' 'sub baz { q[a] }'
#
perlbrew_ver=$1
shift

diff -Naur <(
    perlbrew exec --with=${perlbrew_ver} perl -MO=-qq,Concise,-exec,baz -e "$1"
) <(
    perlbrew exec --with=${perlbrew_ver} perl -MO=-qq,Concise,-exec,baz -e "$2"
)
