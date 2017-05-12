use Test::More qw(no_plan);
use PerlIO::via::Skip;

my $Data = do { local $/=undef ; <DATA> };
my $Result;

sub work ($;$) {
        my ($pat, $count) = @_ ;
	no warnings;
	$ENV{ viaSKIP } = { skippatterns=> $pat } ;
        open \*DATA , '<', \$Data  or die $!;
	open my $o ,  '>:via(Skip)', \$Result or die $!;
	print $o  scalar <DATA>    for 1..($count||1);
	$Result;
}

is work ( 'oo' => 2)                , "apple\norange\n"         ;
is work ( 'oo' => 1)                , "apple\n"                 ;
is work ( 'pp' => 1)                ,  ''                       ;
is work ( 'pp' => 2)                , "orange\n"                ;
is work ( 'pp' => 3)                , "orange\nmelon\n"         ;
is work ( ''   => 1)                , "apple\n"                 ;

is work ( [qw( pp )]     => 2)      , "orange\n"                ;
is work ( [qw( pp ora) ] => 3)      , "melon\n"                 ;
is work ( [qw( pp ora) ] => 3)      , "melon\n"                 ;
is work ( [qw( a    )  ] => 3)      , "melon\n"                 ;
is work ( [qw( pp o  ) ] => 8)      , "grapes\n"                ;
is work ( [qw( a o  )  ] => 8)      ,  ''                       ;
is work ( [qw( a o  )  ] => 8)      ,  ''                       ;

__END__
apple
orange
melon
grapes
