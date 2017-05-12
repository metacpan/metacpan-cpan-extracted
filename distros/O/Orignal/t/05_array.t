#!perl -T

# Hash Orignal Test
use Test::More tests => 37;
use Data::Dumper;
diag('Array Testing');

 
 {
     #test load arrays
     package fum;
     use base qw(Orignal);
     
     fum->attributes({ARRAYS=>[qw(a1 a2 a3 a4)]});

 }
 
 my %value   = (a1=>[qw(1-1 1-2 1-3)],
                a2=>[qw(2-1 2-2 2-3)],
                a3=>[qw(3-1 3-2 3-3)],);
                
 my $array_test;
 ok ($array_test = fum->new({a1=>[qw(1-1 1-2 1-3)],
                            a2=>[qw(2-1 2-2 2-3)],
                            a3=>[qw(3-1 3-2 3-3)]}),"create a new one");  


my @new_array; 
ok(@new_array = $array_test->a1(),'simple get x->array()');
cmp_ok(scalar(@new_array),'==',3,"correct number of indexs!");

foreach my $index (0..2){
    
  is($value{a1}->[$index],$new_array[$index],"$index correct value in array $new_array[$index]");       

}


#get by index ('xx,'xx'...)
ok(@new_array = $array_test->a2(2,0),"get by index x->array(1,2)");
cmp_ok(scalar(@new_array),'==',2,"correct # of indexes!");

is($value{a2}->[2],$new_array[0]," correct value in array $new_array[0]"); 
is($value{a2}->[0],$new_array[1]," correct value in array $new_array[1]"); 
my $key_count = 0;
ok($key_count = $array_test->a1($value{a3}),"Ok set by array x->array(['xx','xx'...]) in scalar");
cmp_ok($key_count,'==','6',"correct value of '6'!");
ok(@new_array = $array_test->a1(),"get the whole lot");
for (my $index=0;$index<3;$index++){ 
   is($value{a1}->[$index],$new_array[$index],"$index $value{a1}->[$index] correct value in array $new_array[$index]");       
   
}
 for (my $index=0;$index<3;$index++){ 
   is($value{a3}->[$index],$new_array[$index+3],"$index $value{a3}->[$index] correct value in array $new_array[$index]");       
}

ok(@new_array = $array_test->a1($value{a2}),"Ok set by array x->array(['xx','xx'...]) in list ");

cmp_ok(scalar(@new_array),'==','9',"correct value of '9'!".scalar(@new_array));

for (my $index=0;$index<3;$index++){ 
   is($value{a2}->[$index],$new_array[$index+6],"$index $value{a2}->[$index] correct value in array $new_array[$index]");       
}

#lets test the rest

ok($key_count=$array_test->pop_a2(),'pop one off for Aunt Peg');
cmp_ok($key_count,'eq',$value{a2}->[2],'correct value popped');

ok($key_count=$array_test->push_a2($value{a2}->[2]),'push one for Seka');
cmp_ok($key_count,'eq',3,'correct value pushed');

ok($key_count=$array_test->push_a2($value{a1}),'push three for Venessa');
cmp_ok($key_count,'eq',6,"$key_count correct value pushed");

ok($key_count=$array_test->shift_a3(),'shift one off for Kay Parker');
cmp_ok($key_count,'eq',$value{a3}->[0],'correct value shifeded');

ok($key_count=$array_test->unshift_a3($value{a3}->[0]),'unshift one for Patricia Rhomberg');
cmp_ok($key_count,'eq',3,'correct value unshifted');

ok($key_count=$array_test->push_a3($value{a2}),'unshift three for Cicciolina');
cmp_ok($key_count,'eq',6,"$key_count correct value unshifted");
 
#now to clean it out

@new_array = $array_test->a1([]);
ok(!@new_array,"value undef is retuned so it is empty");


 # 