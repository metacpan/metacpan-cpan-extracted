use lib '.';
use Relations::Query;

$query_one = "select barney as fife " . 
             "from moogoo as green_teeth ".
             "where flotsam>jetsam " .
             "group by denali " .
             "having fortune=cookie " .
             "order by was,is,will ".
             "limit 1";
    
$query = new Relations::Query(-select   => {'fife' => 'barney'},
                              -from     => {'green_teeth' => 'moogoo'},
                              -where    => "flotsam>jetsam",
                              -group_by => "denali",
                              -having   => {'fortune' => 'cookie'},
                              -order_by => ['was','is','will'],
                              -limit    => '1');

$get_query = $query->get();

die "Query new or get failed" unless ($get_query eq $query_one);
 
$clone = $query->clone();

$clone_query = $clone->get();

die "Query clone failed" unless ($get_query eq $clone_query);
 
$query_two = "select barney as fife,aunt as bee " . 
             "from moogoo as green_teeth,fish as sea ".
             "where flotsam>jetsam and lighter=dark " .
             "group by denali,sally,merman " .
             "having fortune=cookie and sushi<wasabe " .
             "order by was,is,will,n,cheese ".
             "limit 1,2";
    
$query->add(-select   => {'bee' => 'aunt'},
            -from     => {'sea' => 'fish'},
            -where    => {'lighter' => 'dark'},
            -group_by => ['sally','merman'],
            -having   => "sushi<wasabe",
            -order_by => {'n' => 'cheese'},
            -limit    => '2');

$add_query = $query->get();

die "Query add failed" unless ($query_two eq $add_query);
 
$query_thr = "select sparkle as clean " . 
             "from book as lean ".
             "where fighting is between courage and chaos " .
             "group by a,raging,fire " .
             "having fishes in (the sea) " .
             "order by sense,faith,passion ".
             "limit 123";
    
$query->set(-select   => {'clean' => 'sparkle'},
            -from     => {'lean' => 'book'},
            -where    => "fighting is between courage and chaos",
            -group_by => ['a','raging','fire'],
            -having   => "fishes in (the sea)",
            -order_by => ['sense','faith','passion'],
            -limit    => '123');

$set_query = $query->get();

die "Query set failed" unless ($query_thr eq $set_query);
 
$query_num_for = "select sparkle as clean,dog as mean " . 
                 "from book as lean,stern as obscene ".
                 "where fighting is between courage and chaos and running is null " .
                 "group by a,raging,fire,water " .
                 "having fishes in (the sea) and kitties=on_tv " .
                 "order by sense,faith,passion,for,lust,is,nowhere,bound ".
                 "limit 123,9678";
    
$get_add_query = $query->get_add(-select   => {'mean' => 'dog'},
                                 -from     => {'obscene' => 'stern'},
                                 -where    => "running is null",
                                 -order_by => ['for','lust','is','nowhere','bound'],
                                 -having   => {'kitties'=> 'on_tv'},
                                 -group_by => 'water',
                                 -limit    => ['9678']);

die "Query get_add failed" unless ($query_num_for eq $get_add_query);
 
$query_num_fiv = "select sparkle as clean " . 
                 "from shoes as clean ".
                 "where fighting is between courage and chaos " .
                 "group by nothing,much " .
                 "having fishes in (the sea) " .
                 "order by logic,reason,might ".
                 "limit 123";
    
$get_set_query = $query->get_set(-from     => {'clean' => 'shoes'},
                                 -order_by => ['logic','reason','might'],
                                 -group_by => ['nothing' => 'much']);

die "Query get_set failed" unless ($query_num_fiv eq $get_set_query);

$query_num_six = "select nothing";
    
$query->set(-select   => 'nothing',
            -from     => '',
            -where    => '',
            -group_by => '',
            -having   => '',
            -order_by => '',
            -limit    => '');

$get_not_query = $query->get();

die "Destructive query failed" unless ($query_num_six eq $get_not_query);
 
$string = to_string('select this from that');

die "to_string string failed" unless ($string eq 'select this from that');

$minus = to_string({-select => 'this',
                    -from   => 'that'});

die "to_string minus failed" unless ($minus eq 'select this from that');

$hash = to_string({'select' => 'this',
                   'from'   => 'that'});

die "to_string hash failed" unless ($hash eq 'select this from that');

$query = to_string(Relations::Query->new(-select => 'this',-from   => 'that'));

die "to_string query failed" unless ($query eq 'select this from that');

print "\nEverything seems fine\n";