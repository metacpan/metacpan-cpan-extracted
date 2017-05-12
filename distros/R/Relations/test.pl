use lib '.';
use Relations;

$first = '1st';
$second = '2nd';
$third = '3rd';

@args_ordered = ($first,$second,$third);

($first_ordered,$second_ordered,$third_ordered) = rearrange(['FIRST','SECOND','THIRD'],@args_ordered);

die "ordered rearrange failed" unless (($first_ordered eq $first) and 
                                       ($second_ordered eq $second) and 
                                       ($third_ordered eq $third));

@args_named = (-first  => $first,
               -second => $second,
               -third  => $third);

($first_named,$second_named,$third_named) = rearrange(['FIRST','SECOND','THIRD'],@args_named);

die "named rearrange failed" unless (($first_named eq $first) and 
                                     ($second_named eq $second) and 
                                     ($third_named eq $third));

%args_hashed = (first  => $first,
                second => $second,
                third  => $third);

($first_hashed,$second_hashed,$third_hashed) = rearrange(['FIRST','SECOND','THIRD'],\%args_hashed);

die "hashed plain rearrange failed" unless (($first_hashed eq $first) and 
                                      ($second_hashed eq $second) and 
                                      ($third_hashed eq $third));

%args_hashed = (-first  => $first,
                -second => $second,
                -third  => $third);

($first_hashed,$second_hashed,$third_hashed) = rearrange(['FIRST','SECOND','THIRD'],\%args_hashed);

die "hashed minus rearrange failed" unless (($first_hashed eq $first) and 
                                      ($second_hashed eq $second) and 
                                      ($third_hashed eq $third));

$bit_byte = "salad bit Garden byte dressing bit Blue Cheese";
$bit_byte_switch = "dressing bit Blue Cheese byte salad bit Garden";

$where_hash = {salad    => 'Garden',
               dressing => 'Blue Cheese'};

$bit_byte_hash = delimit_clause(' bit ',' byte ',0,$where_hash);

die "hash delimit_clause failed" unless ($bit_byte_hash eq $bit_byte) ||
                                        ($bit_byte_hash eq $bit_byte_switch);

$where_reverse = {'Garden'      => salad,
                  'Blue Cheese' => dressing};

$bit_byte_reverse = delimit_clause(' bit ',' byte ',1,$where_reverse);

die "reverse delimit_clause failed" unless ($bit_byte_hash eq $bit_byte) ||
                                           ($bit_byte_hash eq $bit_byte_switch);

$where_array = ["salad bit Garden",
                "dressing bit Blue Cheese"];

$bit_byte_array = delimit_clause(' bit ',' byte ',0,$where_array);

die "array delimit_clause failed" unless ($bit_byte_hash eq $bit_byte) ||
                                         ($bit_byte_hash eq $bit_byte_switch);

$where_string = "salad bit Garden byte dressing bit Blue Cheese";

$bit_byte_string = delimit_clause(' bit ',' byte ',0,$where_string);

die "string delimit_clause failed" unless ($bit_byte_hash eq $bit_byte) ||
                                          ($bit_byte_hash eq $bit_byte_switch);

$hand = {'me' => 'free', 'I'  => 'sky'};

$as_hand = as_clause($hand);
$as_one_hand = "free as me,sky as I";
$as_other_hand = "sky as I,free as me";

die "as_clause failed" unless ($as_hand eq $as_one_hand) ||
                              ($as_hand eq $as_other_hand);

$equals_hand = equals_clause($hand);
$equals_one_hand = "me=free and I=sky";
$equals_other_hand = "I=sky and me=free";

die "equals_clause failed" unless ($equals_hand eq $equals_one_hand) ||
                                  ($equals_hand eq $equals_other_hand);
 
$comma_hand = comma_clause($hand);
$comma_one_hand = "me,free,I,sky";
$comma_other_hand = "I,sky,me,free";

die "comma_clause failed" unless ($comma_hand eq $comma_one_hand) ||
                                 ($comma_hand eq $comma_other_hand);
 
$assign_hand = assign_clause($hand);
$assign_one_hand = "me=free,I=sky";
$assign_other_hand = "I=sky,me=free";

die "assign_clause failed" unless ($assign_hand eq $assign_one_hand) ||
                                  ($assign_hand eq $assign_other_hand);
 
$add_hand = {'car' => 'far'};

$add_as_hand = add_as_clause($as_hand,$add_hand);
$add_as_one_hand = "free as me,sky as I,far as car";
$add_as_other_hand = "sky as I,free as me,far as car";

die "add_as_clause failed" unless ($add_as_hand eq $add_as_one_hand) ||
                                  ($add_as_hand eq $add_as_other_hand);
  
$add_equals_hand = add_equals_clause($equals_hand,$add_hand);
$add_equals_one_hand = "me=free and I=sky and car=far";
$add_equals_other_hand = "I=sky and me=free and car=far";

die "add_equals_clause failed" unless ($add_equals_hand eq $add_equals_one_hand) ||
                                      ($add_equals_hand eq $add_equals_other_hand);
 
$add_comma_hand = add_comma_clause($comma_hand,$add_hand);
$add_comma_one_hand = "me,free,I,sky,car,far";
$add_comma_other_hand = "I,sky,me,free,car,far";

die "add_comma_clause failed" unless ($add_comma_hand eq $add_comma_one_hand) ||
                                     ($add_comma_hand eq $add_comma_other_hand);
 
$add_assign_hand = add_assign_clause($assign_hand,$add_hand);
$add_assign_one_hand = "me=free,I=sky,car=far";
$add_assign_other_hand = "I=sky,me=free,car=far";

die "add_assign_clause failed" unless ($add_assign_hand eq $add_assign_one_hand) ||
                                      ($add_assign_hand eq $add_assign_other_hand);
 
$set_hand = {'link' => 'think'};

$set_as_hand = set_as_clause($as_hand,$set_hand);
$set_as_one_hand = "think as link";

die "set_as_clause failed" unless ($set_as_hand eq $set_as_one_hand);
  
$set_equals_hand = set_equals_clause($equals_hand,$set_hand);
$set_equals_one_hand = "link=think";

die "set_equals_clause failed" unless ($set_equals_hand eq $set_equals_one_hand);
 
$set_comma_hand = set_comma_clause($comma_hand,$set_hand);
$set_comma_one_hand = "link,think";

die "set_comma_clause failed" unless ($set_comma_hand eq $set_comma_one_hand);
 
$set_assign_hand = set_assign_clause($assign_hand,$set_hand);
$set_assign_one_hand = "link=think";

die "set_assign_clause failed" unless ($set_assign_hand eq $set_assign_one_hand);
 
$thing = to_array('fee,fie,foe');

die "to_array failed string" unless (($thing->[0] eq 'fee') and 
                                     ($thing->[1] eq 'fie') and 
                                     ($thing->[2] eq 'foe'));

$thong = to_array("lee\tlie\tlow","\t");

die "to_array failed split" unless (($thong->[0] eq 'lee') and 
                                    ($thong->[1] eq 'lie') and 
                                    ($thong->[2] eq 'low'));

$thang = to_array(['me','my','moe']);

die "to_array failed array" unless (($thang->[0] eq 'me') and 
                                    ($thang->[1] eq 'my') and 
                                    ($thang->[2] eq 'moe'));

@noop = (1,2,3);

$noop = to_array(\@noop);

$noop->[0] = 4;
$noop->[1] = 5;
$noop->[2] = 6;

die "to_array failed copy" unless (($noop[0] == 1) and 
                                   ($noop[1] == 2) and 
                                   ($noop[2] == 3) and 
                                   ($noop->[0] == 4) and 
                                   ($noop->[1] == 5) and 
                                   ($noop->[2] == 6));

$bing = to_hash('fee,fie,foe');

die "to_hash failed string" unless ($bing->{'fee'} and 
                                    $bing->{'fie'} and 
                                    $bing->{'foe'});

$bung = to_hash("lee\tlie\tlow","\t");

die "to_hash failed split" unless ($bung->{'lee'} and 
                                   $bung->{'lie'} and 
                                   $bung->{'low'});

$bang = to_hash(['me','my','moe']);

die "to_hash failed array" unless ($bang->{'me'} and 
                                   $bang->{'my'} and 
                                   $bang->{'moe'});

$bong = to_hash({'see'  => 1,
                 'sigh' => 1,
                 'so'   => 1});

die "to_hash failed hash" unless ($bong->{'see'} and 
                                  $bong->{'sigh'} and 
                                  $bong->{'so'});

%noop = ('a' => 1,
         'b' => 2,
         'c' => 3);

$noop = to_hash(\%noop);

$noop->{'a'} = 4;
$noop->{'b'} = 5;
$noop->{'c'} = 6;

die "to_hash failed copy" unless (($noop{'a'} == 1) and 
                                  ($noop{'b'} == 2) and 
                                  ($noop{'c'} == 3) and 
                                  ($noop->{'a'} == 4) and 
                                  ($noop->{'b'} == 5) and 
                                  ($noop->{'c'} == 6));

$sing = add_array(['earth','air'],['fire','water']);

die "add_array failed" unless (($sing->[0] eq 'earth') and 
                               ($sing->[1] eq 'air') and 
                               ($sing->[2] eq 'fire') and 
                               ($sing->[3] eq 'water'));

$song = add_hash({'yin' => 1},{'yang' => 1});

die "add_hash failed" unless ($song->{'yin'} and 
                              $song->{'yang'});

open NONE, ">none.txt";

print NONE "\n";

close NONE;

open SOME, ">some.txt";

print SOME "that\n";

close SOME;

open GET, ">get.pl";

print GET "use lib '.';\n";
print GET "use Relations;\n";
print GET "\$ans = get_input(\"heyo\",'this');\n";
print GET "print \"\n\$ans\n\";";

close GET;

open GETTER, "perl get.pl < none.txt |";

$qst = <GETTER>;
chomp $qst;
$ans = <GETTER>;
chomp $ans;

close GETTER;

die "get_input none failed" unless ($qst eq 'heyo [this]:') and ($ans eq 'this');
                               
open GETTER, "perl get.pl < some.txt |";

$qst = <GETTER>;
chomp $qst;
$ans = <GETTER>;
chomp $ans;

close GETTER;

die "get_input some failed" unless ($qst eq 'heyo [this]:') and ($ans eq 'that');
                                        
unlink 'get.pl';
unlink 'none.txt';
unlink 'some.txt';

open SET, ">set.pl";

print SET "use lib '.';\n";
print SET "use Relations;\n";
print SET "configure_settings('test','me','hide','here','2525')";

close SET;

open SETTER, "| perl set.pl";

print SETTER "\n";
print SETTER "\n";
print SETTER "\n";
print SETTER "\n";
print SETTER "\n";
print SETTER "\n";

close SETTER;

die "configure deny failed" if (-e 'Settings.pm');
                               
open SETTER, "| perl set.pl";

print SETTER "\n";
print SETTER "\n";
print SETTER "\n";
print SETTER "\n";
print SETTER "\n";
print SETTER "y\n";

close SETTER;

$i = 0;

open SETTINGS, "<Settings.pm";

while ($set_line = <SETTINGS>) {

  eval $set_line;

}

close SETTINGS;

die "default configure_settings failed" unless (($database eq 'test') and 
                                                ($username eq 'me') and 
                                                ($password eq 'hide') and 
                                                ($host eq 'here') and 
                                                ($port eq '2525'));
                               
open SETTER, "| perl set.pl";

print SETTER "pass\n";
print SETTER "you\n";
print SETTER "find\n";
print SETTER "there\n";
print SETTER "5252\n";
print SETTER "Y\n";

close SETTER;

open SETTINGS, "<Settings.pm";

while ($set_line = <SETTINGS>) {

  eval $set_line;

}

close SETTINGS;

die "entered configure_settings failed" unless (($database eq 'pass') and 
                                                ($username eq 'you') and 
                                                ($password eq 'find') and 
                                                ($host eq 'there') and 
                                                ($port eq '5252'));

print "\n\n";

unlink 'set.pl';
unlink 'Settings.pm';

print "\nEverything seems fine.\n";
