use Pg::Loader::Misc_2 qw/ add_defaults /;
use Pg::Loader::Misc qw/ subset  /;
use Test::More qw( no_plan );
use Test::Exception;


*add_defaults = \& Pg::Loader::Misc_2::add_defaults ;
*subset       = \& Pg::Loader::Misc::subset       ;

my $m = { apple  => {  } };
my $s = { apple  => { null => 'na', use_template=>undef } ,
          fruit  => { }, };
my $a = { apple  => { use_template=>'fruit' } ,
          fruit  => { template=>1, format=>'csv', null=>'aa'}, };
my $b = { apple  => { use_template=>'fruit' } ,
          fruit  => { template=>undef, only_cols=>1, 
                      format=>'csv', null=>'bb'}, };

add_defaults( $m, 'apple');  my $mm = $m->{apple};
add_defaults( $s, 'apple');  my $ss = $s->{apple};
add_defaults( $a, 'apple');  my $aa = $a->{apple};
add_defaults( $b, 'apple');  my $bb = $b->{apple};

is_deeply [ @{$aa}{qw( format copy copy_columns)}], [ qw( csv * *) ];
is_deeply [ @{$aa}{qw( copy_every filename     )}], [ qw( 10000 STDIN )];
is_deeply [ @{$aa}{qw( field_sep)}], [ ',' ];


is   $aa->{ null   }   ,  '$$aa$$' ;
is   $aa->{ format }   ,  'csv'            ;

is_deeply [ @{$bb}{qw( table format only_cols )}], 
          [        qw( apple csv 1)       ];

my $mandatory = [qw( copy     copy_every    null       copy_columns
		     format   quotechar     table      field_sep
		     mode     reject_data   filename   client_encoding
                     lc_time  datestyle     lc_monetary  
                     lc_type  lc_numeric    lc_messages 
             )];

ok subset  [keys %$aa], $mandatory  ;

is_deeply [ @{$mm}{qw( copy copy_every filename      format table)}],
	  [        qw( *    10000      STDIN         text    apple)];

is   $bb->{ null }  ,  '$$bb$$' ;
is   $mm->{ null }  ,  '$$\NA$$' ;
is   $ss->{ null }  ,  '$$na$$'  ;


# the following fail because they exit(1) instead of die()
#dies_ok { add_defaults ( $s, 'appl') };
#dies_ok { add_defaults ( $s, '') };
#dies_ok { add_defaults ( $s, undef) };
