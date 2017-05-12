#!perl -T

# Base Orignal Test
use Test::More tests => 18;

diag('Loading Orignal and version');

 {
     #test load scalars
     package fee;
     use base qw(Orignal);
     
     fee->attributes({SCALARS =>[qw(s1 s2 s3 s4)],
                      ORDERED_HASHES  =>[qw(oh1 oh2 oh3 oh4)],
                      HASHES =>[qw(h1 h2 h3 h4)],
                      ARRAYS=>[qw(a1 a2 a3 a4)]});

 }
 
                 
my %attrs = (SCALARS  =>[qw(s1 s2 s3 s4)],
             HASHES  =>[qw(h1 h2 h3 h4)],
             ORDERED_HASHES =>[qw(oh1 oh2 oh3 oh4)],
             ARRAYS  =>[qw(a1 a2 a3 a4)]);
 
 
my $base_test;
ok ($base_test = fee->new(),"create a new one");
my $meta =  $base_test->my_attributes();
ok($base_test->my_attributes(),"got attributes");

foreach my $key (keys(%attrs)){
    foreach my $index (0..3) {
        cmp_ok($meta->{$key}->[$index], "eq" ,$attrs{$key}->[$index]," I have a ".$attrs{$key}->[$index]);
    }
}





