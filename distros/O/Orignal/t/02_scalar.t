#!perl -T

# Scalars Orignal Test
use Test::More tests => 29;

diag('Scalar Testing');

 {
     #test load scalars
     package fee;
     use base qw(Orignal);
     fee->attributes({SCALARS =>[qw(s1 s2 s3 s4)]});

 }
 
               
my @scalars = (qw(fe fi fo fum));
my @ints    = (1,2.22,100000,-11);
my @mixed   = ([1,2,4],{test=>1,test=>2},12,'sss');
my @attrs   = (qw(s1 s2 s3 s4));
 
my $scalar_test;
ok ($scalar_test = fee->new({s1=>'fe_new',
                             s2=>'fi_new',
                             s3=>'fo_new',
                             s4=>'fum_new'}),"create a new one");  


is($scalar_test->s1(), 'fe_new',  's1 is eq to correct default value fe_new');              
is($scalar_test->s2(), 'fi_new',  's2 is eq to correct default value fe_new');   
is($scalar_test->s3(), 'fo_new',  's3 is eq to new value');   
is($scalar_test->s4(), 'fum_new', 's4 is eq to new value'); 


#test set~get works for one works for all strings
foreach my $new_value (@scalars){
   ok($scalar_test->s1($new_value),"set to $new_value");
   is($scalar_test->s1(), $new_value,  "got $new_value");
            
}

#test set~get works for one works for all ints
foreach my $new_value (@ints){
   ok($scalar_test->s1($new_value),"set to $new_value");
   is($scalar_test->s1(), $new_value,  "got $new_value");              
}

#test set~get works for one works for all sorts
foreach my $new_value (@mixed){
   ok($scalar_test->s1($new_value),"set to $new_value");
   is($scalar_test->s1(), $new_value,  "got $new_value");              
}








