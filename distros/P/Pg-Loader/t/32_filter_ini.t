BEGIN { push @ARGV, "--dbitest=42"; }
use Pg::Loader::Query;
use Test::More qw( no_plan );
use Test::MockDBI;
use Pg::Loader::Misc;
use Test::Exception;

*get_columns_names = \& Pg::Loader::Query::get_columns_names;
*filter_ini        = \& Pg::Loader::Misc::filter_ini ;

my $dh = DBI->connect( '$dsn', '','');
ok $dh;

my $mock = get_instance Test::MockDBI;
my $fake = [ [ 'classid', '1'    ], [ 'objid','2'   ], ['objsubid','3'],
             [ 'refclassid', '4' ], [ 'refobjid','5'], 
             [ 'refobjsubid', '6'], [ 'deptype','7' ]
];
my $s  = { copy_columns => [qw( objid refobjid )],
	   format       => q('text') , 
	   copy         => '*' , 
	   field_sep    => '\,' , 
	   table        => 'a' , 
};
my @fake = qw( classid objid objsubid refclassid refobjid refobjsubid deptype);

$mock->set_retval_scalar( 42, '.*select column_name, ordi.*', $fake);

my $k = { copy=>'classid', format=>'text', table=>'a' ,
	  reformat => ['objid:John::Misc::upper'] ,
};
my $m = { copy=>['classid', 'objid'], format=>'text', table=>'a' ,
	  reformat => 'objid:John::Misc::upper' ,
};
my $ans = { col=>'objid', pack=>'John::Misc', fun=>'upper'};

#TODO
exit;
filter_ini ( $k, $dh );
filter_ini ( $m, $dh );

is_deeply $k->{rfm}{objid}, $ans;
is_deeply $m->{rfm}{objid}, $ans;

is $k->{format}, 'text';

$s  = { copy_columns => [qw( objid refobjid )],
	   format       => q('text') , 
	   copy         => '*' , 
	   field_sep    => '\,' , 
	   table        => 'a' , 
};
filter_ini( $s, $dh ) ;
is_deeply  $s->{copy}, [@fake] ;

is_deeply [ @{$s}{qw( field_sep format )}],   [',', 'text'];


my $ns = { copy_columns => [qw( objid re )],
 	   format       => q('text') , 
	   copy         => '*' , 
	   field_sep    => '\,' , 
	   table        => 'a' , 
};
dies_ok {filter_ini ( $ns, $dh ) };

$ns = { copy_columns => [qw(  )],
 	   format       => q('text') , 
	   copy         => '*' , 
	   field_sep    => '\,' , 
	   table        => 'a' , 
};

lives_ok {filter_ini ( $ns, $dh ) };
__END__

$aann = {  reformat  => [ 'objid:John::Misc::upper' ],
           copy      => [ 'classid' ],
           format    => 'text',
           rfm       => { objid=>{col=>'objid',pack=>'John::Misc',fun=>'upper'}
                        },
           table     => 'a'
        };

