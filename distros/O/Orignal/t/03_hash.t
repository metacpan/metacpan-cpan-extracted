#!perl -T

# Hash Orignal Test
use Test::More tests =>62;
use Data::Dumper;
diag('Hash testing');


 {
     #test load hahses
     package fi;
     use base qw(Orignal);
     
     fi->attributes({HASHES =>[qw(h1 h2 h3)]});

 }
 
 
                
 my @scalars = (qw(fe fi fo fum));

 my %value   = (h1=>{keyh1_1=>'f1_1',keyh1_2=>'f1_2',keyh1_3=>'f1_3'},
                h2=>{keyh2_1=>'f2_1',keyh2_2=>'f2_2',keyh2_3=>'f2_3',},
                h3=>{keyh3_1=>'f3_1',keyh3_2=>'f3_2',keyh3_3=>'f3_3'});
                
 my $hash_test;
 ok ($hash_test = fi->new({h1=>{keyh1_1=>'f1_1',keyh1_2=>'f1_2',keyh1_3=>'f1_3'},
                           h2=>{keyh2_1=>'f2_1',keyh2_2=>'f2_2',keyh2_3=>'f2_3'},
                           h3=>{keyh3_1=>'f3_1',keyh3_2=>'f3_2',keyh3_3=>'f3_3'}}),"create a new one");  

#test the set/get code

#simple get hash();
my %new_hash;
ok(%new_hash = $hash_test->h1(),'simple get x->hash()');
cmp_ok(keys(%new_hash),'==',3,"correct number of keys!");
cmp_ok(values(%new_hash),'==',3,"correct number of values! ");


foreach my $key (keys(%{$value{h1}})){
  is($value{h1}->{$key},$new_hash{$key}," correct value in hash $new_hash{$key}");       
}

#get by key ('xx,'xx'...)
ok(%new_hash = $hash_test->h2(qw(keyh2_1 keyh2_3)),"get by key x->hash('xx','xx')");
cmp_ok(keys(%new_hash),'==',2,"correct # of keys!");
cmp_ok(values(%new_hash),'==',2,"correct  of values! ");

is($value{h2}->{keyh2_1},$new_hash{keyh2_1}," correct value in hash $new_hash{keyh2_1}"); 
is($value{h2}->{keyh2_3},$new_hash{keyh2_3}," correct value in hash $new_hash{keyh2_3}"); 
my $key_count = 0;
ok($key_count = $hash_test->h1($value{h3}),"Ok set by hash x->hash({'xx','xx'}) in scalar");
ok($key_count," Not Empty'!");
ok(%new_hash = $hash_test->h1(),'Ok got 1h');

ok(%new_hash = $hash_test->h1(),'Ok got 1h');
cmp_ok(keys(%new_hash),'==',6,"correct number of keys =6!");
cmp_ok(values(%new_hash),'==',6,"correct number of values=6! ");

foreach my $key (keys(%{$value{h1}})){
  is($value{h1}->{$key},$new_hash{$key}," correct value in hash $new_hash{$key}");       
}
foreach my $key (keys(%{$value{h3}})){
  is($value{h3}->{$key},$new_hash{$key}," correct value in hash $new_hash{$key}");       
}

ok(%new_hash = $hash_test->h1($value{h2}),"Ok set by hash ref x->hash({'xx','xx'...}) in list (hash)");

cmp_ok(keys(%new_hash),'==',9,"correct number of keys!");
cmp_ok(values(%new_hash),'==',9,"correct number of values! ");

ok(%new_hash = $hash_test->h1($value{h1}),"Ok same again but should not add any as the keys are the same");

cmp_ok(keys(%new_hash),'==',9,"correct number of keys!");
cmp_ok(values(%new_hash),'==',9,"correct number of values! ");

#now for exists
foreach my $key (keys(%{$value{h1}})){
  is($hash_test->exists_h1($key),1," checking for x->exits_hash('$key')");       
}

$key_count=$hash_test->exists_h2(qw(keyh2_1 keyh2_3));

cmp_ok($key_count,'==',2,"correct number of keys $key_count! for x->exits_hash('xx','xx')");

ok($key_count = $hash_test->keys_h2(),"checking for x->keys_hash() in scalar ");
cmp_ok($key_count,'==',3,"correct number of keys $key_count!");

my @keys = ();
ok(@keys = $hash_test->keys_h2(),"checking for x->keys_hash() in list (array) ");
cmp_ok(scalar(@keys),'==',3,"correct index retruned!");
foreach my $key (@keys){
  ok(exists($value{h2}->{$key}),"Key $key in array and hash");
}

ok($key_count = $hash_test->values_h3(),"checking for x->values_hash() in scalar ");
cmp_ok($key_count,'==',3,"correct number of values $key_count!");

ok(@keys = $hash_test->values_h3(),"checking for x->values_hash() in list (array) ");
cmp_ok(scalar(@keys),'==',3,"correct index retruned!");
my %check;
foreach my $key (@keys){
  
  $check{$key}=1;
}
my @h3_values = values(%{$value{h3}});
foreach my $key (@h3_values){
  cmp_ok($check{$key},'==',1,"value $key present");
}

ok($key_count = $hash_test->delete_h3('keyh3_2'),"Delete x->values_hash(key)  in scalar ");
cmp_ok($key_count,'eq','f3_2',"value $key_count is retuned");
is($hash_test->exists_h3('keyh3_2'),0,"key not present");

ok($key_count = $hash_test->delete_h3('keyh3_1','keyh3_3'),"Delete x->values_hash(key,key)  in scalar ");
cmp_ok($key_count,'eq','f3_3',"value $key_count is retuned");
is($hash_test->exists_h3('keyh3_3','keyh3_1'),0,"keys not present");

ok(@keys = $hash_test->delete_h2('keyh2_2'),"Delete x->values_hash(key)  in list ");
cmp_ok($keys[0],'eq','f2_2',"value $key_count is retuned");
is($hash_test->exists_h2('keyh2_2'),0,"key not present");

ok(@keys = $hash_test->delete_h2('keyh2_1','keyh2_3'),"Delete x->values_hash(key,key)  in list ");
cmp_ok($keys[0],'eq','f2_1',"value $keys[0] is retuned");
cmp_ok($keys[1],'eq','f2_3',"value $keys[1] is retuned");
is($hash_test->exists_h2('keyh2_3','keyh2_1'),0,"keys not present");

#now to clean it up
%new_hash = $hash_test->h1({});

ok(!%new_hash,"value undef is retuned");

#now for deletes





