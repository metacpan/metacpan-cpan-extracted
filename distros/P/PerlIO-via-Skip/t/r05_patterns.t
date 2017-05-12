use Test::More qw(no_plan);
use PerlIO::via::Skip;

my $data = do { local $/=undef ; <DATA> };


sub work ($;$) {
        my ($pat, $count) = @_ ;
	no warnings;
	$ENV{ viaSKIP } = { skippatterns=> $pat } ;
	open my $i , "<:via(Skip)",  \$data      ;
        my $a;
        $a .= <$i>    for 1..($count||1) ;
        $a;
}

is work ( 'oo' => 2)      , "apple\norange\n"                ;
is work ( 'oo' => 1)      , "apple\n"                        ;
is work ( 'pp' => 1)      , "orange\n"                       ;
is work ( 'pp' => 2)      , "orange\nmelon\n"                ;
is work ( ''   => 1)      , "apple\n"                        ;

is work ( [qw( pp )]     => 1)      , "orange\n"             ;
is work ( [qw( pp ora) ] => 1)      , "melon\n"              ;
is work ( [qw( pp ora) ] => 1)      , "melon\n"              ;
is work ( [qw( a    )  ] => 1)      , "melon\n"              ;
is work ( [qw( pp o  ) ] => 1)      , "grapes\n"             ;
is work ( [qw( a o  )  ] => 1)      ,  ''                    ;
is work ( [qw( a o  )  ] => 2)      ,  ''                    ;

__END__
apple
orange
melon
grapes
