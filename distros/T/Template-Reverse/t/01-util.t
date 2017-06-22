use Test::More ;
use Data::Dump;

BEGIN{
use_ok("Template::Reverse::Util");
};

# sub do_diff{
#     my ($a,$b) = @_;
#     my $ret = Template::Reverse::_diff($a,$b);
# #    dd $ret;
#     return $ret;
# }
# my $W = Template::Reverse::WILDCARD;
# my (@seq1,@seq2,@exp,$diff);
# @seq1 = qw( A B C D E F );
# @seq2 = qw( A B C D E F );
# @exp  = qw( A B C D E F );
# $diff = do_diff(\@seq1,\@seq2);

# is_deeply($diff, \@exp, 'sdiff test1');
# $diff = do_diff(\@seq2,\@seq1);
# is_deeply($diff, \@exp, 'sdiff test2');
my @got;
my @exp;
@exp = (["A", "B", "C"], ["C", "D", "E"]);
@got = partition(3,2, ('A','B','C','D','E'));
is_deeply(\@got, \@exp, 'partition 1');

@exp = (["A", "B", "C"], ["B", "C", "D"], ["C", "D", "E"]);
@got = partition(3, 1, ('A','B','C','D','E'));
is_deeply(\@got, \@exp, 'partition 2');

use constant::Atom qw(WILDCARD);

@exp = (["A","B"], [WILDCARD], ["C","B"]);
@got = partition_by(sub{$_[0] eq WILDCARD}, ('A','B',WILDCARD,'C','B'));
is_deeply(\@got, \@exp, 'partition_by 1');

@exp = ([1], [2], [3], [4], [5], [6]);
@got = partition_by(sub{(shift() % 2)==0}, (1,2,3,4,5,6));
is_deeply(\@got, \@exp, 'partition_by 2');


done_testing();
