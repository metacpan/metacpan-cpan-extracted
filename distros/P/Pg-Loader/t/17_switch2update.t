use Pg::Loader::Misc_2;
use Test::More qw( no_plan );
use Test::Exception;

*switch_2_update = \&Pg::Loader::Misc_2::_switch_2_update ;

my $s;

$s  = { copy=>'*' };
is switch_2_update( $s ),  'copy' ;
$s  = { copy_columns=>'' };
is switch_2_update( $s ),  'copy' ;
$s  = { copy_only=>'' };
is switch_2_update( $s ),  'copy' ;

$s  = { update=>'*' };
is switch_2_update( $s ),  'update' ;
$s  = { update_columns=>'' };
is switch_2_update( $s ),  'update' ;


$s = { copy=>1, update=>1 }        ; dies_ok { switch_2_update( $s ) };
$s = { copy_columns=>1, update=>1 }; dies_ok { switch_2_update( $s ) };
$s = { copy_only=>1, update=>1 }   ; dies_ok { switch_2_update( $s ) };

$s = { copy=>1, update_columns=>1 }        ; dies_ok { switch_2_update( $s ) };
$s = { copy_columns=>1, update_columns=>1 }; dies_ok { switch_2_update( $s ) };
$s = { copy_only=>1, update_columns=>1 }   ; dies_ok { switch_2_update( $s ) };

$s = { copy=>1, update_only=>1 }        ; dies_ok { switch_2_update( $s ) };
$s = { copy_columns=>1, update_only=>1 }; dies_ok { switch_2_update( $s ) };
$s = { copy_only=>1, update_only=>1 }   ; dies_ok { switch_2_update( $s ) };
$s = { update=>1, update_columns=>1 }   ; lives_ok { switch_2_update( $s ) };

## check if data are tranfered
$s = { update_columns=> 'fa' }   ; 
switch_2_update( $s ) ;
is $s->{copy_columns} , $s->{update_columns} ; 
$s = { update=> 'fa' }   ; switch_2_update( $s ) ;
is $s->{copy} , $s->{update} ; 

exit;
TODO: {
        local $TODO = 'not implemented'    ;
	$s  = { update_only=>'a' }         ;
	#lives_ok { switch_2_update( $s ) };
        $s = { update=>1, update_only=>1 }   ; 
        #lives_ok { switch_2_update( $s ) };

}



