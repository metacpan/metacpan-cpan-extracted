use Pg::Loader::Misc;
use Test::More qw( no_plan );
use Test::Exception;

*error_check  = \& Pg::Loader::Misc::error_check;

my $h = { pgsql => { base => undef, host => 'localhost' },
          cvs1  => { null => 'na' , filename=>'a', table=>'a', format=>'csv'}    
};
my $a1 = { pgsql => { base => undef, host => 'localhost' },
           cvs1  => { copy_columns => 'na', , filename=>'a', table=>'a', 
                      format=>'csv'}  
};
my $a2 = { pgsql => { base => undef, host => 'localhost' },
           cvs1  => { only_cols => '1-3', , filename=>'a', table=>'a', 
                      format=>'csv'}
};
my $d1 = { pgsql => { base => undef, host => 'localhost' },
           cvs1  => { copy_columns => 'age', only_cols=>'1-3', filename=>'a',
                      table=>'a', format=>'csv'} 
};
lives_ok  {  error_check( $h,  'cvs1')   };
lives_ok  {  error_check( $h,  'cvs1')   };
lives_ok  {  error_check( $a1, 'cvs1')   };
lives_ok  {  error_check( $a2, 'cvs1')   };

exit;
dies_ok   { error_check( $h,  'a'   ) }  ;
dies_ok   { error_check( $d1, 'cvs1') }  ;

dies_ok   { error_check( $h, '' )     }  ;
dies_ok   { error_check( $h, undef)   }  ;
dies_ok   { error_check( '', 'cvs1')  }  ;
dies_ok   { error_check( undef,'cvs1')}  ;

__END__
