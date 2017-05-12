#!perl -T

# Hash Ordered  Test
use Test::More tests =>82;
use Data::Dumper;

diag('Ordered Hash testing');


 {
     #test load ordered_hahses
     package fo;
     use base qw(Orignal);
     
     fo->attributes({ORDERED_HASHES  =>[qw(oh1 oh2 oh3 oh4)]});


 }
 
 
                
 my @scalars = (qw(f1_1 f1_2 f1_3));
 
 my %value   = (h1=>{keyh1_1=>'f1_1',keyh1_2=>'f1_2',keyh1_3=>'f1_3'},
                h2=>{keyh2_1=>'f2_1',keyh2_2=>'f2_2',keyh2_3=>'f2_3',},
                h3=>{keyh3_1=>'f3_1',keyh3_2=>'f3_2',keyh3_3=>'f3_3'});
                
 my $hash_test;
 ok ($hash_test = fo->new({oh1=>{keyh1_1=>'f1_1',keyh1_2=>'f1_2',keyh1_3=>'f1_3'},
                           oh2=>{keyh2_1=>'f2_1',keyh2_2=>'f2_2',keyh2_3=>'f2_3'},
                           oh3=>{keyh3_1=>'f3_1',keyh3_2=>'f3_2',keyh3_3=>'f3_3'}}),"create a new one");  



#test the set/get code

#simple get hash();
my %new_hash;
ok(%new_hash = $hash_test->oh1(),'simple get x->hash()');
cmp_ok(keys(%new_hash),'==',3,"correct number of keys!");
cmp_ok(values(%new_hash),'==',3,"correct number of values! ");

foreach my $key (keys(%{$value{h1}})){
  is($value{h1}->{$key},$new_hash{$key}," correct value in hash $new_hash{$key}");       
}


#get by key ('xx,'xx'...)
ok(%new_hash = $hash_test->oh2(qw(keyh2_1 keyh2_3)),"get by key x->hash('xx','xx'...)");
cmp_ok(keys(%new_hash),'==',2,"correct # of keys!");
cmp_ok(values(%new_hash),'==',2,"correct  of values! ");

is($value{h2}->{keyh2_1},$new_hash{keyh2_1}," correct value in hash $new_hash{keyh2_1}"); 
is($value{h2}->{keyh2_3},$new_hash{keyh2_3}," correct value in hash $new_hash{keyh2_3}"); 
my $key_count = 0;
ok($key_count = $hash_test->oh1($value{h3}),"Ok set by hash x->hash({'xx','xx'...}) in scalar");
ok($key_count," Not Empty");
ok(%new_hash = $hash_test->oh1(),'Ok got 1h');

ok(%new_hash = $hash_test->oh1(),'Ok got 1h');
cmp_ok(keys(%new_hash),'==',6,"correct number of keys =6!");
cmp_ok(values(%new_hash),'==',6,"correct number of values=6! ");

foreach my $key (keys(%{$value{h1}})){
  is($value{h1}->{$key},$new_hash{$key}," correct value in hash $new_hash{$key}");       
}
foreach my $key (keys(%{$value{h3}})){
  is($value{h3}->{$key},$new_hash{$key}," correct value in hash $new_hash{$key}");       
}

ok(%new_hash = $hash_test->oh1($value{h2}),"Ok set by hash ref x->hash({'xx','xx'...}) in list (hash)");

cmp_ok(keys(%new_hash),'==',9,"correct number of keys!");
cmp_ok(values(%new_hash),'==',9,"correct number of values! ");
my %big_hash;
ok(%big_hash = $hash_test->oh1($value{h1}),"Ok same again but should not add any as the keys are the same");

cmp_ok(keys(%big_hash),'==',9,"correct number of keys!");
cmp_ok(values(%big_hash),'==',9,"correct number of values! ");

#now for exists
foreach my $key (keys(%{$value{h1}})){
  is($hash_test->exists_oh1($key),1," checking for x->exits_hash('$key')");       
}

$key_count=$hash_test->exists_oh2(qw(keyh2_1 keyh2_3));
cmp_ok($key_count,'==',2,"correct number of keys $key_count! for x->exits_hash('xx','xx')");

ok($key_count = $hash_test->keys_oh2(),"checking for x->keys_hash() in scalar ");
cmp_ok($key_count,'==',3,"correct number of keys $key_count!");

my @keys = ();
ok(@keys = $hash_test->keys_oh2(),"checking for x->keys_hash() in list (array) ");
cmp_ok(scalar(@keys),'==',3,"correct index retruned!");
foreach my $key (@keys){
  ok(exists($value{h2}->{$key}),"Key $key in array and hash");
}

ok($key_count = $hash_test->values_oh3(),"checking for x->values_hash() in scalar ");
cmp_ok($key_count,'==',3,"correct number of values $key_count!");

ok(@keys = $hash_test->values_oh3(),"checking for x->values_hash() in list (array) ");
cmp_ok(scalar(@keys),'==',3,"correct index retruned!");
my %check;
foreach my $key (@keys){
  
  $check{$key}=1;
}
my @h3_values = values(%{$value{h3}});
foreach my $key (@h3_values){
  cmp_ok($check{$key},'==',1,"value $key present");
}

#now for deletes

ok($key_count = $hash_test->delete_oh3('keyh3_2'),"Delete x->values_hash(key)  in scalar ");
cmp_ok($key_count,'eq','f3_2',"value $key_count is returned");
is($hash_test->exists_oh3('keyh3_2'),0,"key not present");

ok($key_count = $hash_test->delete_oh3('keyh3_1','keyh3_3'),"Delete x->values_hash(key,key)  in scalar ");
cmp_ok($key_count,'eq','f3_3',"value $key_count is returned");
is($hash_test->exists_oh3('keyh3_3','keyh3_1'),0,"keys not present");

ok(@keys = $hash_test->delete_oh2('keyh2_2'),"Delete x->values_hash(key)  in list ");
cmp_ok($keys[0],'eq','f2_2',"value $key_count is returned");
is($hash_test->exists_oh2('keyh2_2'),0,"key not present");

ok(@keys = $hash_test->delete_oh2('keyh2_1','keyh2_3'),"Delete x->values_hash(key,key)  in list ");
cmp_ok($keys[0],'eq','f2_1',"value $keys[0] is returned");
cmp_ok($keys[1],'eq','f2_3',"value $keys[1] is returned");
is($hash_test->exists_oh2('keyh2_3','keyh2_1'),0,"keys not present");

#now to clean it up
%new_hash = $hash_test->oh1({});

ok(!%new_hash,"value undef is retuned");
my @ordered;
@ordered = sort({$a cmp  $b} keys(%big_hash));

foreach my $key (@ordered){
   $hash_test->oh1({$key=>$big_hash{$key}});
}
%new_hash = $hash_test->oh1();

cmp_ok(keys(%new_hash),'==',9,"correct number of keys!");
cmp_ok(values(%new_hash),'==',9,"correct number of values! ");



@keys = $hash_test->keys_oh1();
foreach my $index (0...8){
  cmp_ok($ordered[$index],'eq',$keys[$index],'correct order');  
}

@keys = $hash_test->values_oh1();

@ordered = sort({$a cmp  $b} values(%big_hash));

foreach my $index (0...8){
  cmp_ok($ordered[$index],'eq',$keys[$index],'correct order');  
}
