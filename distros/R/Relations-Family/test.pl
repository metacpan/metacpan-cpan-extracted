#!perl

use DBI;
use Relations;
use Relations::Query;
use Relations::Abstract;
use lib '.';
use Relations::Family;
use Relations::Family::Member;
use Relations::Family::Lineage;
use Relations::Family::Rivalry;
use Relations::Family::Value;

use finder;

configure_settings('fam_test','root','','localhost','3306') unless -e "Settings.pm";

eval "use Settings";

$dsn = "DBI:mysql:mysql:$host:$port";

$dbh = DBI->connect($dsn,$username,$password,{PrintError => 1, RaiseError => 0});

$abs = new Relations::Abstract($dbh);

create_finder($abs,$database);
$fam = relate_finder($abs,$database);

$val = new Relations::Family::Value(-name    => 'sweet',
                                    -sql     => 'jesus',
                                    -members => 'choir');

die "Value create failed" unless (($val->{name} eq 'sweet') and 
                                  ($val->{sql} eq 'jesus') and 
                                  ($val->{members} eq 'choir'));

$lin = new Relations::Family::Lineage(-parent_member => 'dude',
                                      -parent_field  => 'dude_id',
                                      -child_member  => 'sweet',
                                      -child_field   => 'sweet_id');

die "Lineage create failed" unless (($lin->{parent_member} eq 'dude') and 
                                    ($lin->{parent_field} eq 'dude_id') and 
                                    ($lin->{child_member} eq 'sweet') and 
                                    ($lin->{child_field} eq 'sweet_id'));

$riv = new Relations::Family::Rivalry(-brother_member => 'yang',
                                      -brother_field  => 'yang_id',
                                      -sister_member  => 'yin',
                                      -sister_field   => 'yin_id');

die "Rivalry create failed" unless (($riv->{brother_member} eq 'yang') and 
                                    ($riv->{brother_field} eq 'yang_id') and 
                                    ($riv->{sister_member} eq 'yin') and 
                                    ($riv->{sister_field} eq 'yin_id'));

$query_one = "select barney as fife " . 
             "from moogoo as green_teeth ".
             "where flotsam>jetsam " .
             "group by denali " .
             "having fortune=cookie " .
             "order by was,is,will ".
             "limit 1";
    
$qry = new Relations::Query(-select   => {'fife' => 'barney'},
                            -from     => {'green_teeth' => 'moogoo'},
                            -where    => "flotsam>jetsam",
                            -group_by => "denali",
                            -having   => {'fortune' => 'cookie'},
                            -order_by => ['was','is','will'],
                            -limit    => '1');

$mem = new Relations::Family::Member(-name     => 'rand',
                                     -label    => 'Random Thoughts',
                                     -database => 'mindtrip',
                                     -table    => 'rand_thoughts',
                                     -id_field => 'rd_id',
                                     -query    => $qry,
                                     -alias    => 'mooky');

die "Member create failed alias" unless (($mem->{name} eq 'rand')  and 
                                         ($mem->{label} eq 'Random Thoughts') and 
                                         ($mem->{database} eq 'mindtrip') and 
                                         ($mem->{table} eq 'rand_thoughts') and 
                                         ($mem->{id_field} eq 'rd_id')  and 
                                         ($mem->{query}->get() eq $query_one) and 
                                         ($mem->{alias} eq 'mooky'));

$qry = new Relations::Query(-select   => {'fife' => 'barney'},
                            -from     => {'green_teeth' => 'moogoo'},
                            -where    => "flotsam>jetsam",
                            -group_by => "denali",
                            -having   => {'fortune' => 'cookie'},
                            -order_by => ['was','is','will'],
                            -limit    => '1');

$mem = new Relations::Family::Member(-name     => 'rand',
                                     -label    => 'Random Thoughts',
                                     -database => 'mindtrip',
                                     -table    => 'rand_thoughts',
                                     -id_field => 'rd_id',
                                     -query    => $qry);

die "Member create failed basic" unless (($mem->{name} eq 'rand')  and 
                                         ($mem->{label} eq 'Random Thoughts') and 
                                         ($mem->{database} eq 'mindtrip') and 
                                         ($mem->{table} eq 'rand_thoughts') and 
                                         ($mem->{id_field} eq 'rd_id')  and 
                                         ($mem->{query}->get() eq $query_one) and 
                                         ($mem->{alias} eq 'rand_thoughts'));

die "Member create failed chosen" unless (($mem->{chosen_ids_count} == 0)  and 
                                          ($mem->{chosen_ids_string} eq '')  and 
                                          (scalar @{$mem->{chosen_ids_array}} == 0) and
                                          (scalar @{$mem->{chosen_ids_select}} == 0) and
                                          ($mem->{chosen_labels_string} eq '')  and 
                                          (scalar @{$mem->{chosen_labels_array}} == 0) and 
                                          (scalar keys %{$mem->{chosen_labels_hash}} == 0) and 
                                          (scalar keys %{$mem->{chosen_labels_select}} == 0));

die "Member create failed available" unless (($mem->{available_ids_count} == 0)  and 
                                             (scalar @{$mem->{available_ids_array}} == 0) and
                                             (scalar @{$mem->{available_ids_select}} == 0) and
                                             (scalar @{$mem->{available_labels_array}} == 0) and 
                                             (scalar keys %{$mem->{available_labels_hash}} == 0) and 
                                             (scalar keys %{$mem->{available_labels_select}} == 0));

die "Member create failed select" unless (($mem->{filter} eq '') and 
                                          ($mem->{match} == 0) and 
                                          ($mem->{group} == 0) and 
                                          ($mem->{limit} eq '') and 
                                          ($mem->{ignore} == 0));

$fam = new Relations::Family('data stuff');

die "Family create failed" unless (($fam->{abstract} eq 'data stuff')  and 
                                   (scalar @{$fam->{members}} == 0) and 
                                   (scalar keys %{$fam->{names}} == 0) and 
                                   (scalar keys %{$fam->{labels}} == 0));

$fam->add_member(-member => $mem);

die "Basic add member failed" unless (($fam->{members}->[0] == $mem) and
                                      ($fam->{names}->{'rand'} == $mem) and
                                      ($fam->{labels}->{'Random Thoughts'} == $mem));

$fam->add_member(-name     => 'donkey',
                 -label    => 'Donkey Biter',
                 -database => 'dweebas',
                 -table    => 'donkeys_damnit',
                 -id_field => 'freak_id',
                 -query    => $qry);

$query_dis = "select distinct barney as fife " . 
             "from moogoo as green_teeth ".
             "where flotsam>jetsam " .
             "group by denali " .
             "having fortune=cookie " .
             "order by was,is,will ".
             "limit 1";
    
die "Regular add member failed" unless (($fam->{members}->[1]->{name} eq 'donkey') and
                                        ($fam->{members}->[1]->{label} eq 'Donkey Biter') and
                                        ($fam->{members}->[1]->{database} eq 'dweebas') and
                                        ($fam->{members}->[1]->{table} eq 'donkeys_damnit') and
                                        ($fam->{members}->[1]->{id_field} eq 'freak_id') and
                                        ($fam->{members}->[1]->{query}->get() eq $query_dis) and
                                        ($fam->{names}->{'donkey'} == $fam->{members}->[1]) and
                                        ($fam->{labels}->{'Donkey Biter'} == $fam->{members}->[1]) and
                                        ($fam->{members}->[1]->{alias} eq 'donkeys_damnit'));

$qry->add(-select => 'yayaya');

die "Copied add member failed" unless (($fam->{members}->[1]->{name} eq 'donkey') and
                                        ($fam->{members}->[1]->{label} eq 'Donkey Biter') and
                                        ($fam->{members}->[1]->{database} eq 'dweebas') and
                                        ($fam->{members}->[1]->{table} eq 'donkeys_damnit') and
                                        ($fam->{members}->[1]->{id_field} eq 'freak_id') and
                                        ($fam->{members}->[1]->{query}->get() eq $query_dis) and
                                        ($fam->{names}->{'donkey'} == $fam->{members}->[1]) and
                                        ($fam->{labels}->{'Donkey Biter'} == $fam->{members}->[1]) and
                                        ($fam->{members}->[1]->{alias} eq 'donkeys_damnit'));

$qry = new Relations::Query(-select   => {'fife' => 'barney'},
                            -from     => {'green_teeth' => 'moogoo'},
                            -where    => "flotsam>jetsam",
                            -group_by => "denali",
                            -having   => {'fortune' => 'cookie'},
                            -order_by => ['was','is','will'],
                            -limit    => '1');

$fam->add_member(-name     => 'vb',
                 -label    => 'Venga Boyz',
                 -database => 'songs',
                 -table    => 'we_like',
                 -id_field => 'to_party',
                 -query    => {-select   => {'hey' => 'now'},
                               -from     => {'nappy' => 'winamp'},
                               -where    => {'happines' => 'justaroundthecorner'},
                               -group_by => "nikki",
                               -having   => {'smile' => 'look'},
                               -order_by => ['before','during','after'],
                               -limit    => '500'},
                 -alias    => 'muck_stank');

$query_two = "select now as hey " . 
             "from winamp as nappy ".
             "where happines=justaroundthecorner " .
             "group by nikki " .
             "having smile=look " .
             "order by before,during,after ".
             "limit 500";
    
die "Full add member failed" unless (($fam->{members}->[2]->{name} eq 'vb') and
                                      ($fam->{members}->[2]->{label} eq 'Venga Boyz') and
                                      ($fam->{members}->[2]->{database} eq 'songs') and
                                      ($fam->{members}->[2]->{table} eq 'we_like') and
                                      ($fam->{members}->[2]->{id_field} eq 'to_party') and
                                      ($fam->{members}->[2]->{query}->get() == $query_two) and
                                      ($fam->{names}->{'vb'} == $fam->{members}->[2]) and
                                      ($fam->{labels}->{'Venga Boyz'} == $fam->{members}->[2]) and
                                      ($fam->{members}->[2]->{alias} eq 'muck_stank'));

$fam->add_lineage(-parent_name  => 'vb',
                  -parent_field => 'wakko',
                  -child_name   => 'donkey',
                  -child_field  => 'jakko');

die "Name add lineage failed" unless (($fam->{names}->{'vb'}->{children}->[0]->{parent_member} == $fam->{names}->{'vb'})  and 
                                      ($fam->{names}->{'vb'}->{children}->[0]->{parent_field} eq 'wakko')  and 
                                      ($fam->{names}->{'vb'}->{children}->[0]->{child_member} == $fam->{names}->{'donkey'})  and 
                                      ($fam->{names}->{'vb'}->{children}->[0]->{child_field} eq 'jakko')  and 
                                      ($fam->{names}->{'donkey'}->{parents}->[0]->{parent_member} == $fam->{names}->{'vb'})  and 
                                      ($fam->{names}->{'donkey'}->{parents}->[0]->{parent_field} eq 'wakko')  and 
                                      ($fam->{names}->{'donkey'}->{parents}->[0]->{child_member} == $fam->{names}->{'donkey'})  and 
                                      ($fam->{names}->{'donkey'}->{parents}->[0]->{child_field} eq 'jakko'));

$fam->add_lineage(-parent_label => 'Random Thoughts',
                  -parent_field => 'sally',
                  -child_label   => 'Venga Boyz',
                  -child_field  => 'wally');

die "Label add lineage failed" unless (($fam->{names}->{'rand'}->{children}->[0]->{parent_member} == $fam->{names}->{'rand'})  and 
                                       ($fam->{names}->{'rand'}->{children}->[0]->{parent_field} eq 'sally')  and 
                                       ($fam->{names}->{'rand'}->{children}->[0]->{child_member} == $fam->{names}->{'vb'})  and 
                                       ($fam->{names}->{'rand'}->{children}->[0]->{child_field} eq 'wally')  and 
                                       ($fam->{names}->{'vb'}->{parents}->[0]->{parent_member} == $fam->{names}->{'rand'})  and 
                                       ($fam->{names}->{'vb'}->{parents}->[0]->{parent_field} eq 'sally')  and 
                                       ($fam->{names}->{'vb'}->{parents}->[0]->{child_member} == $fam->{names}->{'vb'})  and 
                                       ($fam->{names}->{'vb'}->{parents}->[0]->{child_field} eq 'wally'));

$fam->add_lineage(-parent_member => $fam->{names}->{'donkey'},
                  -parent_field  => 'murtle',
                  -child_member  => $fam->{names}->{'rand'},
                  -child_field   => 'turtle');

die "Member add lineage failed" unless (($fam->{names}->{'donkey'}->{children}->[0]->{parent_member} == $fam->{names}->{'donkey'})  and 
                                        ($fam->{names}->{'donkey'}->{children}->[0]->{parent_field} eq 'murtle')  and 
                                        ($fam->{names}->{'donkey'}->{children}->[0]->{child_member} == $fam->{names}->{'rand'})  and 
                                        ($fam->{names}->{'donkey'}->{children}->[0]->{child_field} eq 'turtle')  and 
                                        ($fam->{names}->{'rand'}->{parents}->[0]->{parent_member} == $fam->{names}->{'donkey'})  and 
                                        ($fam->{names}->{'rand'}->{parents}->[0]->{parent_field} eq 'murtle')  and 
                                        ($fam->{names}->{'rand'}->{parents}->[0]->{child_member} == $fam->{names}->{'rand'})  and 
                                        ($fam->{names}->{'rand'}->{parents}->[0]->{child_field} eq 'turtle'));

$new_lin = new Relations::Family::Lineage(-parent_member => $fam->{names}->{'vb'},
                                          -parent_field  => 'heehee',
                                          -child_member  => $fam->{names}->{'rand'},
                                          -child_field   => 'haahaa');

$fam->add_lineage(-lineage => $new_lin);

die "Direct add lineage failed" unless (($fam->{names}->{'vb'}->{children}->[1]->{parent_member} == $fam->{names}->{'vb'})  and 
                                        ($fam->{names}->{'vb'}->{children}->[1]->{parent_field} eq 'heehee')  and 
                                        ($fam->{names}->{'vb'}->{children}->[1]->{child_member} == $fam->{names}->{'rand'})  and 
                                        ($fam->{names}->{'vb'}->{children}->[1]->{child_field} eq 'haahaa')  and 
                                        ($fam->{names}->{'rand'}->{parents}->[1]->{parent_member} == $fam->{names}->{'vb'})  and 
                                        ($fam->{names}->{'rand'}->{parents}->[1]->{parent_field} eq 'heehee')  and 
                                        ($fam->{names}->{'rand'}->{parents}->[1]->{child_member} == $fam->{names}->{'rand'})  and 
                                        ($fam->{names}->{'rand'}->{parents}->[1]->{child_field} eq 'haahaa'));

$fam->add_rivalry(-brother_name  => 'vb',
                  -brother_field => 'wakko',
                  -sister_name   => 'donkey',
                  -sister_field  => 'jakko');

die "Name add rivalry failed" unless (($fam->{names}->{'vb'}->{sisters}->[0]->{brother_member} == $fam->{names}->{'vb'})  and 
                                      ($fam->{names}->{'vb'}->{sisters}->[0]->{brother_field} eq 'wakko')  and 
                                      ($fam->{names}->{'vb'}->{sisters}->[0]->{sister_member} == $fam->{names}->{'donkey'})  and 
                                      ($fam->{names}->{'vb'}->{sisters}->[0]->{sister_field} eq 'jakko')  and 
                                      ($fam->{names}->{'donkey'}->{brothers}->[0]->{brother_member} == $fam->{names}->{'vb'})  and 
                                      ($fam->{names}->{'donkey'}->{brothers}->[0]->{brother_field} eq 'wakko')  and 
                                      ($fam->{names}->{'donkey'}->{brothers}->[0]->{sister_member} == $fam->{names}->{'donkey'})  and 
                                      ($fam->{names}->{'donkey'}->{brothers}->[0]->{sister_field} eq 'jakko'));

$fam->add_rivalry(-brother_label => 'Random Thoughts',
                  -brother_field => 'sally',
                  -sister_label   => 'Venga Boyz',
                  -sister_field  => 'wally');

die "Label add rivalry failed" unless (($fam->{names}->{'rand'}->{sisters}->[0]->{brother_member} == $fam->{names}->{'rand'})  and 
                                       ($fam->{names}->{'rand'}->{sisters}->[0]->{brother_field} eq 'sally')  and 
                                       ($fam->{names}->{'rand'}->{sisters}->[0]->{sister_member} == $fam->{names}->{'vb'})  and 
                                       ($fam->{names}->{'rand'}->{sisters}->[0]->{sister_field} eq 'wally')  and 
                                       ($fam->{names}->{'vb'}->{brothers}->[0]->{brother_member} == $fam->{names}->{'rand'})  and 
                                       ($fam->{names}->{'vb'}->{brothers}->[0]->{brother_field} eq 'sally')  and 
                                       ($fam->{names}->{'vb'}->{brothers}->[0]->{sister_member} == $fam->{names}->{'vb'})  and 
                                       ($fam->{names}->{'vb'}->{brothers}->[0]->{sister_field} eq 'wally'));

$fam->add_rivalry(-brother_member => $fam->{names}->{'donkey'},
                  -brother_field  => 'murtle',
                  -sister_member  => $fam->{names}->{'rand'},
                  -sister_field   => 'turtle');

die "Member add rivalry failed" unless (($fam->{names}->{'donkey'}->{sisters}->[0]->{brother_member} == $fam->{names}->{'donkey'})  and 
                                        ($fam->{names}->{'donkey'}->{sisters}->[0]->{brother_field} eq 'murtle')  and 
                                        ($fam->{names}->{'donkey'}->{sisters}->[0]->{sister_member} == $fam->{names}->{'rand'})  and 
                                        ($fam->{names}->{'donkey'}->{sisters}->[0]->{sister_field} eq 'turtle')  and 
                                        ($fam->{names}->{'rand'}->{brothers}->[0]->{brother_member} == $fam->{names}->{'donkey'})  and 
                                        ($fam->{names}->{'rand'}->{brothers}->[0]->{brother_field} eq 'murtle')  and 
                                        ($fam->{names}->{'rand'}->{brothers}->[0]->{sister_member} == $fam->{names}->{'rand'})  and 
                                        ($fam->{names}->{'rand'}->{brothers}->[0]->{sister_field} eq 'turtle'));

$new_riv = new Relations::Family::Rivalry(-brother_member => $fam->{names}->{'vb'},
                                          -brother_field  => 'heehee',
                                          -sister_member  => $fam->{names}->{'rand'},
                                          -sister_field   => 'haahaa');

$fam->add_rivalry(-rivalry => $new_riv);

die "Direct add rivalry failed" unless (($fam->{names}->{'vb'}->{sisters}->[1]->{brother_member} == $fam->{names}->{'vb'})  and 
                                        ($fam->{names}->{'vb'}->{sisters}->[1]->{brother_field} eq 'heehee')  and 
                                        ($fam->{names}->{'vb'}->{sisters}->[1]->{sister_member} == $fam->{names}->{'rand'})  and 
                                        ($fam->{names}->{'vb'}->{sisters}->[1]->{sister_field} eq 'haahaa')  and 
                                        ($fam->{names}->{'rand'}->{brothers}->[1]->{brother_member} == $fam->{names}->{'vb'})  and 
                                        ($fam->{names}->{'rand'}->{brothers}->[1]->{brother_field} eq 'heehee')  and 
                                        ($fam->{names}->{'rand'}->{brothers}->[1]->{sister_member} == $fam->{names}->{'rand'})  and 
                                        ($fam->{names}->{'rand'}->{brothers}->[1]->{sister_field} eq 'haahaa'));

$fam->add_value(-name  => 'dandy',
                -sql => 'cambells elvis',
                -member_names => 'rand,vb');

die "Name add value failed" unless (($fam->{'values'}->{dandy}->{name} eq 'dandy')  and 
                                    ($fam->{'values'}->{dandy}->{sql} eq 'cambells elvis')  and 
                                    ($fam->{'values'}->{dandy}->{members}->[0]  == $fam->{names}->{'rand'})  and 
                                    ($fam->{'values'}->{dandy}->{members}->[1]  == $fam->{names}->{'vb'}));

$fam->add_value(-name  => 'dip',
                -sql => 'freak_nasty',
                -member_labels => 'Venga Boyz,Donkey Biter,Random Thoughts');

die "Label add value failed" unless (($fam->{'values'}->{dip}->{name} eq 'dip')  and 
                                     ($fam->{'values'}->{dip}->{sql} eq 'freak_nasty')  and 
                                     ($fam->{'values'}->{dip}->{members}->[0]  == $fam->{names}->{'vb'})  and 
                                     ($fam->{'values'}->{dip}->{members}->[1]  == $fam->{names}->{'donkey'})  and 
                                     ($fam->{'values'}->{dip}->{members}->[2]  == $fam->{names}->{'rand'}));

$fam->add_value(-name  => 'poe',
                -sql => 'pretty',
                -members => [$fam->{names}->{'rand'},$fam->{names}->{'donkey'}]);

die "Member add value failed" unless (($fam->{'values'}->{poe}->{name} eq 'poe')  and 
                                      ($fam->{'values'}->{poe}->{sql} eq 'pretty')  and 
                                      ($fam->{'values'}->{poe}->{members}->[0]  == $fam->{names}->{'rand'})  and 
                                      ($fam->{'values'}->{poe}->{members}->[1]  == $fam->{names}->{'donkey'}));

$new_val = new Relations::Family::Value(-name    => 'lucinda',
                                        -sql     => 'essence',
                                        -members => [$fam->{names}->{'donkey'},$fam->{names}->{'vb'}]);

$fam->add_value(-value => $new_val);

die "Direct add value failed" unless (($fam->{'values'}->{lucinda}->{name} eq 'lucinda')  and 
                                      ($fam->{'values'}->{lucinda}->{sql} eq 'essence')  and 
                                      ($fam->{'values'}->{lucinda}->{members}->[0]  == $fam->{names}->{'donkey'})  and 
                                      ($fam->{'values'}->{lucinda}->{members}->[1]  == $fam->{names}->{'vb'}));

$chosen = $fam->set_chosen(-name   => 'vb',
                           -selects => ["5\tblee",
                                        "8\tblah"],
                           -filter => 'thing',
                           -match  => 1,
                           -group  => 4,
                           -limit  => "2,3",
                           -ignore => 7);

die "Select set chosen failed" unless (($chosen->{count} == 2) and
                                        ($chosen->{ids_string} eq '5,8') and
                                        ($chosen->{ids_array}->[0] == 5) and
                                        ($chosen->{ids_array}->[1] == 8) and
                                        ($chosen->{ids_select}->[0] eq "5\tblee") and
                                        ($chosen->{ids_select}->[1] eq "8\tblah") and
                                        ($chosen->{labels_string} eq "blee\tblah") and
                                        ($chosen->{labels_array}->[0] eq 'blee') and
                                        ($chosen->{labels_array}->[1] eq 'blah') and
                                        ($chosen->{labels_hash}->{'5'} eq 'blee') and
                                        ($chosen->{labels_hash}->{'8'} eq 'blah') and
                                        ($chosen->{labels_select}->{"5\tblee"} eq 'blee') and
                                        ($chosen->{labels_select}->{"8\tblah"} eq 'blah') and
                                        ($chosen->{filter} eq 'thing') and
                                        ($chosen->{match} == 1) and
                                        ($chosen->{group} == 4) and
                                        ($chosen->{limit} eq '2,3') and
                                        ($chosen->{ignore} == 7));

$chosen = $fam->set_chosen(-label   => 'Random Thoughts',
                           -ids     => [23,12],
                           -labels => {23 => "foo",
                                       12 => "bar"},
                           -filter => 'thang',
                           -match  => 3,
                           -group  => 2,
                           -limit  => "235454",
                           -ignore => 6);

die "Hash set chosen failed" unless (($chosen->{count} == 2) and
                                      ($chosen->{ids_string} eq '23,12') and
                                      ($chosen->{ids_array}->[0] == 23) and
                                      ($chosen->{ids_array}->[1] == 12) and
                                      ($chosen->{ids_select}->[0] eq "23\tfoo") and
                                      ($chosen->{ids_select}->[1] eq "12\tbar") and
                                      ($chosen->{labels_string} eq "foo\tbar") and
                                      ($chosen->{labels_array}->[0] eq 'foo') and
                                      ($chosen->{labels_array}->[1] eq 'bar') and
                                      ($chosen->{labels_hash}->{'23'} eq 'foo') and
                                      ($chosen->{labels_hash}->{'12'} eq 'bar') and
                                      ($chosen->{labels_select}->{"23\tfoo"} eq 'foo') and
                                      ($chosen->{labels_select}->{"12\tbar"} eq 'bar') and
                                      ($chosen->{filter} eq 'thang') and
                                      ($chosen->{match} == 3) and
                                      ($chosen->{group} == 2) and
                                      ($chosen->{limit} eq '235454') and
                                      ($chosen->{ignore} == 6));

$fam->set_chosen(-member  => $mem,
                 -ids     => [47,51],
                 -labels  => ["shoe","saloon"],
                 -filter => 'g-money',
                 -match  => 5,
                 -group  => 1,
                 -limit  => "5471",
                 -ignore => 1);

$chosen = $fam->get_chosen(-name => 'rand');

die "Array set chosen failed" unless (($chosen->{count} == 2) and
                                      ($chosen->{ids_string} eq '47,51') and
                                      ($chosen->{ids_array}->[0] == 47) and
                                      ($chosen->{ids_array}->[1] == 51) and
                                      ($chosen->{ids_select}->[0] eq "47\tshoe") and
                                      ($chosen->{ids_select}->[1] eq "51\tsaloon") and
                                      ($chosen->{labels_string} eq "shoe\tsaloon") and
                                      ($chosen->{labels_array}->[0] eq 'shoe') and
                                      ($chosen->{labels_array}->[1] eq 'saloon') and
                                      ($chosen->{labels_hash}->{'47'} eq 'shoe') and
                                      ($chosen->{labels_hash}->{'51'} eq 'saloon') and
                                      ($chosen->{labels_select}->{"47\tshoe"} eq 'shoe') and
                                      ($chosen->{labels_select}->{"51\tsaloon"} eq 'saloon') and
                                      ($chosen->{filter} eq 'g-money') and
                                      ($chosen->{match} == 5) and
                                      ($chosen->{group} == 1) and
                                      ($chosen->{limit} eq '5471') and
                                      ($chosen->{ignore} == 1));

$fam->set_chosen(-label  => 'Donkey Biter',
                 -ids     => "21,36",
                 -labels  => "flew\tkoo koo",
                 -filter => 'special-sauce',
                 -match  => 6,
                 -group  => 1,
                 -limit  => "6211",
                 -ignore => 1);

$chosen = $fam->get_chosen(-name => 'donkey');

die "String set chosen failed" unless (($chosen->{count} == 2) and
                                      ($chosen->{ids_string} eq '21,36') and
                                      ($chosen->{ids_array}->[0] == 21) and
                                      ($chosen->{ids_array}->[1] == 36) and
                                      ($chosen->{ids_select}->[0] eq "21\tflew") and
                                      ($chosen->{ids_select}->[1] eq "36\tkoo koo") and
                                      ($chosen->{labels_string} eq "flew\tkoo koo") and
                                      ($chosen->{labels_array}->[0] eq 'flew') and
                                      ($chosen->{labels_array}->[1] eq 'koo koo') and
                                      ($chosen->{labels_hash}->{'21'} eq 'flew') and
                                      ($chosen->{labels_hash}->{'36'} eq 'koo koo') and
                                      ($chosen->{labels_select}->{"21\tflew"} eq 'flew') and
                                      ($chosen->{labels_select}->{"36\tkoo koo"} eq 'koo koo') and
                                      ($chosen->{filter} eq 'special-sauce') and
                                      ($chosen->{match} == 6) and
                                      ($chosen->{group} == 1) and
                                      ($chosen->{limit} eq '6211') and
                                      ($chosen->{ignore} == 1));

$finder = relate_finder($abs,$database);

$finder->set_chosen(-name   => 'account',
                    -ids    => "21,36");

%needs = ();
%needed = ();

$needs = \%needs;
$needed = \%needed;

$need = $finder->get_needs($finder->{names}->{'account'},$needs,$needed,1);

die "Get self needs failed" unless ((not $need) and
                                    (not $needs->{'account'}));

%needs = ();
%needed = ();

$needs = \%needs;
$needed = \%needed;

$need = $finder->get_needs($finder->{names}->{'item'},$needs,$needed,1);

die "Get other needs failed" unless (($need) and
                                     ($needs->{'item'}));

$finder->set_chosen(-name   => 'customer',
                    -ids    => "4,20");

%row = ();
@ids = ();
push @ids, \%row;
$ids = \@ids;

%ided = ();
$ided = \%ided;

$ids = $finder->get_ids($finder->{names}->{'type'},$ids,$ided,1,1);

die "Get basic values failed" unless (($ids->[0]->{'account'} eq "21,36") and
                                      ($ids->[0]->{'customer'} eq "4,20"));

$finder->set_chosen(-name   => 'product',
                    -ids    => "3,3445,10000",
                    -match  => 1);

%row = ();
@ids = ();
push @ids, \%row;
$ids = \@ids;

%ided = ();
$ided = \%ided;

$ids = $finder->get_ids($finder->{names}->{'item'},$ids,$ided,1,1);

die "Get all values failed" unless (($ids->[0]->{'product'} eq "3") and
                                    ($ids->[0]->{'account'} eq "21,36") and
                                    ($ids->[0]->{'customer'} eq "4,20") and
                                    ($ids->[1]->{'product'} eq "3445") and
                                    ($ids->[1]->{'account'} eq "21,36") and
                                    ($ids->[1]->{'customer'} eq "4,20") and
                                    ($ids->[2]->{'product'} eq "10000") and
                                    ($ids->[2]->{'account'} eq "21,36") and
                                    ($ids->[2]->{'customer'} eq "4,20"));

%row = ();
@ids = ();
push @ids, \%row;
$ids = \@ids;

%ided = ();
$ided = \%ided;

$ids = $finder->get_ids($finder->{names}->{'type'},$ids,$ided,1,1);

die "Get all -> any values failed" unless (($ids->[0]->{'product'} eq "3,3445,10000") and
                                           ($ids->[0]->{'account'} eq "21,36") and
                                           ($ids->[0]->{'customer'} eq "4,20"));

$finder->set_chosen(-name   => 'product',
                    -ids    => $finder->{names}->{'product'}->{chosen_ids_string},
                    -match  => 0);

$finder->set_chosen(-name   => 'account',
                    -ids    => $finder->{names}->{'account'}->{chosen_ids_string},
                    -match  => 1);

$finder->set_chosen(-name   => 'customer',
                    -ids    => $finder->{names}->{'customer'}->{chosen_ids_string},
                    -match  => 1);

%row = ();
@ids = ();
push @ids, \%row;
$ids = \@ids;

%ided = ();
$ided = \%ided;

$ids = $finder->get_ids($finder->{names}->{'account'},$ids,$ided,1,1);

die "Get account values failed" unless (($ids->[0]->{'product'} eq "3,3445,10000") and
                                        ($ids->[0]->{'customer'} eq "4,20"));

%row = ();
@ids = ();
push @ids, \%row;
$ids = \@ids;

%ided = ();
$ided = \%ided;

$ids = $finder->get_ids($finder->{names}->{'customer'},$ids,$ided,1,1);

die "Get customer values failed" unless (($ids->[0]->{'product'} eq "3,3445,10000") and
                                         ($ids->[0]->{'account'} eq "21,36"));

%row = ();
@ids = ();
push @ids, \%row;
$ids = \@ids;

%ided = ();
$ided = \%ided;

$ids = $finder->get_ids($finder->{names}->{'item'},$ids,$ided,1,1);

die "Get cross values failed" unless (($ids->[0]->{'product'} eq "3,3445,10000") and
                                      ($ids->[0]->{'account'} eq "21") and
                                      ($ids->[0]->{'customer'} eq "4") and
                                      ($ids->[1]->{'product'} eq "3,3445,10000") and
                                      ($ids->[1]->{'account'} eq "36") and
                                      ($ids->[1]->{'customer'} eq "4") and
                                      ($ids->[2]->{'product'} eq "3,3445,10000") and
                                      ($ids->[2]->{'account'} eq "21") and
                                      ($ids->[2]->{'customer'} eq "20") and
                                      ($ids->[3]->{'product'} eq "3,3445,10000") and
                                      ($ids->[3]->{'account'} eq "36") and
                                      ($ids->[3]->{'customer'} eq "20"));

%needs = ();
%needed = ();

$needs = \%needs;
$needed = \%needed;

$need = $finder->get_needs($finder->{names}->{'item'},$needs,$needed,1);

%row = ();
@ids = ();
push @ids, \%row;
$ids = \@ids;

%ided = ();
$ided = \%ided;

$ids = $finder->get_ids($finder->{names}->{'item'},$ids,$ided,1,1);

%queried = ();
$queried = \%queried;

$qry = new Relations::Query(-select => 'item_id');

$finder->get_query($finder->{names}->{'item'},$qry,$ids->[2],$needs,$queried);

$query = "select item_id " . 
           "from $database.item as item," .
                "$database.purchase as purchase," . 
                "$database.customer as customer," . 
                "$database.account as account," . 
                "$database.product as product " . 
           "where item.pur_id=purchase.pur_id and " .
                 "purchase.cust_id=customer.cust_id and " .
                 "customer.cust_id in (20) and " .
                 "customer.cust_id=account.cust_id and " .
                 "account.acc_id in (21) and " .
                 "item.prod_id=product.prod_id and " .
                 "product.prod_id in (3,3445,10000)";

die "Get query failed" unless (($qry->get() eq $query));

$finder = relate_finder($abs,$database);

$finder->set_chosen(-name   => 'customer',
                    -ids    => '2,4');

$available = $finder->get_available(-name => 'purchase');

die "Get available failed" unless (($available->{count} == 3) and
                                    ($available->{ids_array}->[0] == 6) and
                                    ($available->{ids_array}->[1] == 8) and
                                    ($available->{ids_array}->[2] == 5) and
                                    ($available->{ids_select}->[0] eq "6\tLast Night Diner - May 9th, 2001") and
                                    ($available->{ids_select}->[1] eq "8\tVarney Solutions - January 4th, 2001") and
                                    ($available->{ids_select}->[2] eq "5\tLast Night Diner - November 3rd, 2000") and
                                    ($available->{labels_array}->[0] eq "Last Night Diner - May 9th, 2001") and
                                    ($available->{labels_array}->[1] eq "Varney Solutions - January 4th, 2001") and
                                    ($available->{labels_array}->[2] eq "Last Night Diner - November 3rd, 2000") and
                                    ($available->{labels_hash}->{'6'} eq "Last Night Diner - May 9th, 2001") and
                                    ($available->{labels_hash}->{'8'} eq "Varney Solutions - January 4th, 2001") and
                                    ($available->{labels_hash}->{'5'} eq "Last Night Diner - November 3rd, 2000") and
                                    ($available->{labels_select}->{"6\tLast Night Diner - May 9th, 2001"} eq "Last Night Diner - May 9th, 2001") and
                                    ($available->{labels_select}->{"8\tVarney Solutions - January 4th, 2001"} eq "Varney Solutions - January 4th, 2001") and
                                    ($available->{labels_select}->{"5\tLast Night Diner - November 3rd, 2000"} eq "Last Night Diner - November 3rd, 2000"));

$finder->set_chosen(-name  => 'customer',
                    -ids   => '2,4',
                    -group => 1);

$available = $finder->get_available(-name => 'purchase');

die "Get available group failed" unless (($available->{count} == 5) and
                                          ($available->{ids_array}->[0] == 3) and
                                          ($available->{ids_array}->[1] == 7) and
                                          ($available->{ids_array}->[2] == 4) and
                                          ($available->{ids_array}->[3] == 2) and
                                          ($available->{ids_array}->[4] == 1));

$finder->set_chosen(-name   => 'customer');

$finder->set_chosen(-name  => 'purchase',
                    -ids   => '1,2,3',
                    -match => 1);

$available = $finder->get_available(-name => 'product');

die "Get available match failed" unless (($available->{count} == 3) and
                                          ($available->{ids_array}->[0] == 4) and
                                          ($available->{ids_array}->[1] == 5) and
                                          ($available->{ids_array}->[2] == 2));

$finder->set_chosen(-name  => 'product',
                    -limit => 2);

$available = $finder->get_available(-name => 'product');

die "Get available limit failed" unless (($available->{count} == 2) and
                                          ($available->{ids_array}->[0] == 4) and
                                          ($available->{ids_array}->[1] == 5));

$finder->set_chosen(-name  => 'product',
                    -filter => 'To');

$available = $finder->get_available(-name => 'product');

die "Get available limit failed" unless (($available->{count} == 2) and
                                          ($available->{ids_array}->[0] == 5) and
                                          ($available->{ids_array}->[1] == 2));

$finder->set_chosen(-name  => 'purchase',
                    -ids   => '5,6',
                    -ignore => 1);

$finder->set_chosen(-name  => 'customer',
                    -ids   => '1');

$finder->set_chosen(-name  => 'product');

$available = $finder->get_available(-name => 'product');

die "Get available ignroe failed" unless (($available->{count} == 6) and
                                          ($available->{ids_array}->[0] == 9) and
                                          ($available->{ids_array}->[1] == 4) and
                                          ($available->{ids_array}->[2] == 3) and
                                          ($available->{ids_array}->[3] == 5) and
                                          ($available->{ids_array}->[4] == 1) and
                                          ($available->{ids_array}->[5] == 2));

$chosen = $finder->choose_available(-name => 'product');

die "choose_available failed" unless (($chosen->{count} == 6) and
                                      ($chosen->{ids_array}->[0] == 9) and
                                      ($chosen->{ids_array}->[1] == 4) and
                                      ($chosen->{ids_array}->[2] == 3) and
                                      ($chosen->{ids_array}->[3] == 5) and
                                      ($chosen->{ids_array}->[4] == 1) and
                                      ($chosen->{ids_array}->[5] == 2));

%ids = ();
$ids = \%ids;

$ids->{'account'} = 3;

$valued = to_hash('customer,item');

$visits = to_hash();
$visited = to_hash();

$finder->get_visits($finder->{names}->{'item'},$visits,$visited,$ids,$valued);

die "Get visits failed" unless (($visits->{'customer'}) and
                                ($visits->{'purchase'}) and
                                ($visits->{'item'}) and
                                ($visits->{'account'}) and
                               !($visits->{'product'}) and
                               !($visits->{'pur_sp'}) and
                               !($visits->{'region'}) and
                               !($visits->{'type'}) and
                               !($visits->{'sales_person'}));

$finder = relate_finder($abs,$database);

$finder->set_chosen(-label  => 'Customer',
                    -ids    => '2,4,5');

$finder->add_value(-name  => 'Stuff',
                   -sql   => 'sum(item.qty)',
                   -member_names => 'item');

$reunion = $finder->get_reunion(-data        => 'Customer,Stuff',
                                -use_labels  => 'Customer',
                                -group_by    => 'Customer',
                                -order_by    => 'Stuff desc');

$matrix = $abs->select_matrix(-query => $reunion);

die "Get reunion native failed" unless ((scalar @$matrix == 3) and
                                        ($matrix->[0]->{Stuff} == 238) and
                                        ($matrix->[1]->{Stuff} == 12) and
                                        ($matrix->[2]->{Stuff} == 9) and
                                        ($matrix->[0]->{Customer} eq "Last Night Diner") and
                                        ($matrix->[1]->{Customer} eq "Teskaday Print Shop") and
                                        ($matrix->[2]->{Customer} eq "Varney Solutions"));

$reunion = $finder->get_reunion(-data           => 'Customer,Stuff',
                                -use_label_ids  => {'Customer' => "1,3"},
                                -group_by       => 'Customer',
                                -order_by       => 'Stuff desc');

$matrix = $abs->select_matrix(-query => $reunion);

die "Get reunion forced failed" unless ((scalar @$matrix == 2) and
                                        ($matrix->[0]->{Stuff} == 104) and
                                        ($matrix->[1]->{Stuff} == 4) and
                                        ($matrix->[0]->{Customer} eq "Harry's Garage") and
                                        ($matrix->[1]->{Customer} eq "Simply Flowers"));


$abs->run_query("DROP DATABASE IF EXISTS $database") or die "Couldn't drop database: $database";

print "\nEverything seems fine\n";