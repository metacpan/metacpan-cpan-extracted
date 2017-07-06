use Test::More ;

BEGIN{
use_ok("Template::Reverse");
};

sub do_diff{
    my ($a,$b) = @_;
    my $ret = Template::Reverse::_diff($a,$b);
#    dd $ret;
    return $ret;
}
my $W = Template::Reverse::WILDCARD;
my (@seq1,@seq2,@exp,$diff);
@seq1 = qw( A B C D E F );
@seq2 = qw( A B C D E F );
@exp  = qw( A B C D E F );
$diff = do_diff(\@seq1,\@seq2);

is_deeply($diff, \@exp, 'sdiff test1');
$diff = do_diff(\@seq2,\@seq1);
is_deeply($diff, \@exp, 'sdiff test2');


@seq1 = qw( A B C D E F );
@seq2 = qw( A B C   E F );
@exp  = (qw( A B C ),$W,qw( E F ));
$diff = do_diff(\@seq1,\@seq2);
is_deeply($diff, \@exp, 'sdiff test3');
$diff = do_diff(\@seq2,\@seq1);
is_deeply($diff, \@exp, 'sdiff test4');

@seq1 = qw( A B C D E F );
@seq2 = qw( A B     E F );
@exp  = (qw( A B ),$W,qw( E F ));
$diff = do_diff(\@seq1,\@seq2);
is_deeply($diff, \@exp, 'sdiff test5');
$diff = do_diff(\@seq2,\@seq1);
is_deeply($diff, \@exp, 'sdiff test6');

@seq1 = qw( A B C D E F );
@seq2 = qw( B     E F );
@exp  = (qw( ),$W,qw( B ),$W,qw( E F ));
$diff = do_diff(\@seq1,\@seq2);
is_deeply($diff, \@exp, 'sdiff test7');
$diff = do_diff(\@seq2,\@seq1);
is_deeply($diff, \@exp, 'sdiff test8');

@seq1 = qw( A B C D E F );
@seq2 = qw(   B C D E );
@exp  = (qw( ),$W,qw( B C D E ),$W,qw( ));
$diff = do_diff(\@seq1,\@seq2);
is_deeply($diff, \@exp, 'sdiff test9');
$diff = do_diff(\@seq2,\@seq1);
is_deeply($diff, \@exp, 'sdiff test10');

@seq1 = qw( A B C D E F );
@seq2 = qw(   B C   E );
@exp  = (qw( ),$W,qw( B C ),$W,qw( E ),$W,qw( ));
$diff = do_diff(\@seq1,\@seq2);
is_deeply($diff, \@exp, 'sdiff test11');
$diff = do_diff(\@seq2,\@seq1);
is_deeply($diff, \@exp, 'sdiff test12');

done_testing();
