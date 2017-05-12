use Pg::Loader::Columns;
use Test::More qw( no_plan );
use Test::Exception;

*field_nums_reqe = \&Pg::Loader::Columns::field_nums_reqe;

my @all_cols = qw( one two three four );
my $h       = { only_cols => undef };
my $s       = { only_cols => '1-2'    };
my $s1      = { only_cols => ['1-2']  };
my $a       = { only_cols => ['0-1',3]  };

is_deeply  [field_nums_reqe( { only_cols=>undef    } , $#all_cols)], [0..3];
is_deeply  [field_nums_reqe( { only_cols=>'1-2'    } , $#all_cols)], [0..1];
is_deeply  [field_nums_reqe( { only_cols=>['1-2',3]} , $#all_cols)], [0..1,2];
is_deeply  [field_nums_reqe( { only_cols=>['1-2']  } , $#all_cols)], [0..1];
is_deeply  [field_nums_reqe( { only_cols=>undef    } , $#all_cols)], [0..3];
is_deeply  [field_nums_reqe( {} , $#all_cols)], [0..3];

is_deeply  [field_nums_reqe( { only_cols=>'2-3,3'} , $#all_cols)], [1..2];
is_deeply  [field_nums_reqe( { only_cols=>'1,2-3,3'} , $#all_cols)], [0,1..2];

is_deeply  [field_nums_reqe( { only_cols=>[1,'2-3',3]},$#all_cols)], [0,1..2];
is_deeply  [field_nums_reqe( { only_cols=>['1']},$#all_cols)], [0];
is_deeply  [field_nums_reqe( { only_cols=>[1]},$#all_cols)], [0];
dies_ok { field_nums_reqe( { only_cols=>[0-1]}, 3) };
#dies_ok { field_nums_reqe( { only_cols=>0}, 3 )};


