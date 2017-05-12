#!perl -T

# Hash Orignal Test
use Test::More tests => 23;
use Data::Dumper;
diag('Test for leaks between packages and validation!');

 {
     #test load scalars
     package fee;
     use base qw(Orignal);
     
     fee->attributes({SCALARS =>[qw(s1 s2 s3 s4)],
                      HASHES  =>[qw(h1 h2 h3 h4)],
                      ORDERED_HASHES  =>[qw(oh1 oh2 oh3 oh4)],
                      ARRAYS=>[qw(a1 a2 a3 a4)]});

 }
 
 {
     #test load hahses
     package fi;
     use base qw(Orignal);
     
     fi->attributes({SCALARS =>[qw(s1 s2 s3 s4)],
                     HASHES  =>[qw(h1 h2 h3 h4)],
                     ORDERED_HASHES  =>[qw(oh1 oh2 oh3 oh4)],
                     ARRAYS=>[qw(a1 a2 a3 a4)]});

 }
 
 {
     #test load ordered_hahses
     package fo;
     use base qw(Orignal);
     
     fo->attributes({SCALARS =>[qw(s1 s2 s3 s4)],
                      HASHES  =>[qw(h1 h2 h3 h4)],
                      ORDERED_HASHES  =>[qw(oh1 oh2 oh3 oh4)],
                      ARRAYS=>[qw(a1 a2 a3 a4)]});

 }
 
 {
     #test load arrays
     package fum;
     use base qw(Orignal);
     
     fum->attributes({SCALARS =>[qw(s1 s2 s3 s4)],
                      HASHES  =>[qw(h1 h2 h3 h4)],
                      ORDERED_HASHES  =>[qw(oh1 oh2 oh3 oh4)],
                      ARRAYS=>[qw(a1 a2 a3 a4)]});
                    
     sub validate_s1 {
          my $self = shift;
          my ($in) = @_;
          die 
            if ($in eq 'NO');   
     }

     sub validate_h4 {
         my $self = shift;
         my ($in) = @_;
         ref($in) eq 'Some::Big::Ass::Class' || die;
  
     }
 }
 
                
 my @scalars = (qw(fe fi fo fum));
 my @ints    = (1,2.22,100000,-11);
 my @mixed   = ([1,2,4],{test=>1,test=>2},12,'sss');
 my @attrs   = (qw(s1 s2 s3 s4));
 my %value   = (h1=>{keyh1_1=>'f1_1',keyh1_2=>'f1_2',keyh1_3=>'f1_3'},
                h2=>{keyh2_1=>'f2_1',keyh2_2=>'f2_2',keyh2_3=>'f2_3',},
                h3=>{keyh3_1=>'f3_1',keyh3_2=>'f3_2',keyh3_3=>'f3_3'},
                a1=>[qw(1-1 1-2 1-3)],
                a2=>[qw(2-1 2-2 2-3)],
                a3=>[qw(3-1 3-2 3-3)],);
 my $scalar_test;
 my $all_test;
 ok ($fee = fee->new({s1=>'fe_new fee',
                              s2=>'fi_new fee',
                              s3=>'fo_new fee',
                              s4=>'fum_new fee',
                              h1=>$value{h1},
                              h2=>$value{h2},
                              h3=>$value{h3},
                              oh1=>$value{h1},
                              oh2=>$value{h2},
                              oh3=>$value{h3},
                              a1=>$value{a1},
                              a2=>$value{a2},
                              a3=>$value{a3}}),"create a new fee");  

 ok ($fi = fi->new({s1=>'fe_new fi',
                              s2=>'fi_new fi',
                              s3=>'fo_new fi',
                              s4=>'fum_new fi',
                              h1=>$value{h3},
                              h2=>$value{h2},
                              h3=>$value{h1},
                              oh1=>$value{h3},
                              oh2=>$value{h2},
                              oh3=>$value{h1},
                              a1=>$value{a3},
                              a2=>$value{a2},
                              a3=>$value{a1}}),"create a new fi");  


 ok ($fo = fo->new({s1=>'fe_new fo',
                              s2=>'fi_new fo',
                              s3=>'fo_new fo',
                              s4=>'fum_new fo',
                              h1=>$value{h3},
                              h2=>$value{h1},
                              h3=>$value{h2},
                              oh1=>$value{h3},
                              oh2=>$value{h1},
                              oh3=>$value{h2},
                              a1=>$value{a1},
                              a2=>$value{a1},
                              a3=>$value{a1}}),"create a new fo");  

 ok ($fum = fum->new({s1=>'fe_new fum',
                              s2=>'fi_new fum',
                              s3=>'fo_new fum',
                              s4=>'fum_new fum',
                              h1=>$value{h2},
                              h2=>$value{h1},
                              h3=>$value{h3},
                              oh1=>$value{h1},
                              oh2=>$value{h2},
                              oh3=>$value{h3},
                              a1=>$value{a3},
                              a2=>$value{a1},
                              a3=>$value{a2}}),"create a new fum");  


#lets test for leaks

cmp_ok($fee->s1(),'eq','fe_new fee','fee scalar correct');
cmp_ok($fi->s1(),'eq','fe_new fi','fi scalar correct');
cmp_ok($fo->s1(),'eq','fe_new fo','fo scalar correct');
cmp_ok($fum->s1(),'eq','fe_new fum','fum scalar correct');
my %ahash = $fee->oh2();


foreach my $key ($fee->keys_oh2()){
   cmp_ok($value{h2}->{$key},'eq',$ahash{$key},$key.' has correct value');
}
 
%ahash = $fi->h3();


foreach my $key ($fi->keys_h3()){
   cmp_ok($value{h1}->{$key},'eq',$ahash{$key},$key.' has correct value');
}

my @array = $fo->a2();


foreach my $index (0..2){
   cmp_ok($value{a1}->[$index],'eq',$array[$index],$array[$index].' has correct value');
}

%ahash = $fum->h2();


foreach my $key ($fum->keys_h2()){
   cmp_ok($value{h1}->{$key},'eq',$ahash{$key},$key.' has correct value');
}

$fum->s1("");
cmp_ok($fum->s1,'eq',"",'s1 has correct value of nothing');
eval {
  $fum->s1("NO");
};
ok($@, 'Set s1 to NO. Should Die');

eval {
    $fum->h4({X=>"cc"});
};
ok($@, 'Set h4 to hash. Should Die');

