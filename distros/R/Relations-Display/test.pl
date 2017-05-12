#!/usr/bin/perl
use DBI;
use Relations;
use Relations::Query;
use Relations::Abstract;
use lib '.';
use Relations::Display;
use Relations::Display::Table;

configure_settings('dsp_test','root','','localhost','3306') unless -e "Settings.pm";

eval "use Settings";

$dsn = "DBI:mysql:mysql:$host:$port";

$dbh = DBI->connect($dsn,$username,$password,{PrintError => 1, RaiseError => 0});

$abs = new Relations::Abstract($dbh);

create_watcher($abs,$database);

$x_axis_values->[0] = 0;
$x_axis_values->[1] = 1;
$x_axis_values->[2] = 2;

$legend_values->[0] = 'a';
$legend_values->[1] = 'b';
$legend_values->[2] = 'c';

$x_axis_titles->{'0'} = 'One';
$x_axis_titles->{'1'} = 'Two';
$x_axis_titles->{'2'} = 'Three';

$legend_titles->{'a'} = 'Ay';
$legend_titles->{'b'} = 'Bee';
$legend_titles->{'c'} = 'Cie';

$y_axis_values->{'0'}{'a'} = 'Mercury';
$y_axis_values->{'0'}{'b'} = 'Venus';
$y_axis_values->{'0'}{'c'} = 'Earth';
$y_axis_values->{'1'}{'a'} = 'Mars';
$y_axis_values->{'1'}{'b'} = 'Jupiter';
$y_axis_values->{'1'}{'c'} = 'Uranus';
$y_axis_values->{'2'}{'a'} = 'Saturn';
$y_axis_values->{'2'}{'b'} = 'Neptune';
$y_axis_values->{'2'}{'c'} = 'Pluto';

$tbl = new Relations::Display::Table(-title          => 'The Main Event',
                                     -x_label        => 'Axis Spin X',
                                     -y_label        => 'Axis Spin Y',
                                     -legend_label   => 'Legend in Mind',
                                     -x_axis_values  => $x_axis_values,
                                     -legend_values  => $legend_values,
                                     -x_axis_titles  => $x_axis_titles,
                                     -legend_titles  => $legend_titles,
                                     -y_axis_values  => $y_axis_values);
                                      
die "Create Table failed" unless (('The Main Event' eq $tbl->{title}) and
                                  ('Axis Spin X' eq $tbl->{x_label}) and
                                  ('Axis Spin Y' eq $tbl->{y_label}) and
                                  ('Legend in Mind' eq $tbl->{legend_label}) and
                                  ('0 1 2' eq join ' ', @{$tbl->{x_axis_values}}) and 
                                  ('a b c' eq join ' ', @{$tbl->{legend_values}}) and
                                  ('One' eq $tbl->{x_axis_titles}->{'0'}) and
                                  ('Two' eq $tbl->{x_axis_titles}->{'1'}) and
                                  ('Three' eq $tbl->{x_axis_titles}->{'2'}) and
                                  ('Ay' eq $tbl->{legend_titles}->{'a'}) and
                                  ('Bee' eq $tbl->{legend_titles}->{'b'}) and
                                  ('Cie' eq $tbl->{legend_titles}->{'c'}) and
                                  ('Mercury' eq $tbl->{y_axis_values}->{'0'}{'a'}) and
                                  ('Venus' eq $tbl->{y_axis_values}->{'0'}{'b'}) and
                                  ('Earth' eq $tbl->{y_axis_values}->{'0'}{'c'}) and
                                  ('Mars' eq $tbl->{y_axis_values}->{'1'}{'a'}) and
                                  ('Jupiter' eq $tbl->{y_axis_values}->{'1'}{'b'}) and
                                  ('Uranus' eq $tbl->{y_axis_values}->{'1'}{'c'}) and
                                  ('Saturn' eq $tbl->{y_axis_values}->{'2'}{'a'}) and
                                  ('Neptune' eq $tbl->{y_axis_values}->{'2'}{'b'}) and
                                  ('Pluto' eq $tbl->{y_axis_values}->{'2'}{'c'}));

$x_axis_values->[0] = 4;
$legend_values->[0] = 'd';
$x_axis_titles->{'0'} = 'Four';
$legend_titles->{'a'} = 'Dee';
$y_axis_values->{'0'}{'a'} = 'Moon';

die "Copy Table failed" unless (('The Main Event' eq $tbl->{title}) and
                                  ('Axis Spin X' eq $tbl->{x_label}) and
                                  ('Axis Spin Y' eq $tbl->{y_label}) and
                                  ('Legend in Mind' eq $tbl->{legend_label}) and
                                  ('0 1 2' eq join ' ', @{$tbl->{x_axis_values}}) and 
                                  ('a b c' eq join ' ', @{$tbl->{legend_values}}) and
                                  ('One' eq $tbl->{x_axis_titles}->{'0'}) and
                                  ('Two' eq $tbl->{x_axis_titles}->{'1'}) and
                                  ('Three' eq $tbl->{x_axis_titles}->{'2'}) and
                                  ('Ay' eq $tbl->{legend_titles}->{'a'}) and
                                  ('Bee' eq $tbl->{legend_titles}->{'b'}) and
                                  ('Cie' eq $tbl->{legend_titles}->{'c'}) and
                                  ('Mercury' eq $tbl->{y_axis_values}->{'0'}{'a'}) and
                                  ('Venus' eq $tbl->{y_axis_values}->{'0'}{'b'}) and
                                  ('Earth' eq $tbl->{y_axis_values}->{'0'}{'c'}) and
                                  ('Mars' eq $tbl->{y_axis_values}->{'1'}{'a'}) and
                                  ('Jupiter' eq $tbl->{y_axis_values}->{'1'}{'b'}) and
                                  ('Uranus' eq $tbl->{y_axis_values}->{'1'}{'c'}) and
                                  ('Saturn' eq $tbl->{y_axis_values}->{'2'}{'a'}) and
                                  ('Neptune' eq $tbl->{y_axis_values}->{'2'}{'b'}) and
                                  ('Pluto' eq $tbl->{y_axis_values}->{'2'}{'c'}));

$cln = $tbl->clone();

die "Clone Table failed" unless (('The Main Event' eq $cln->{title}) and
                                  ('Axis Spin Y' eq $cln->{y_label}) and
                                  ('Axis Spin X' eq $cln->{x_label}) and
                                  ('Legend in Mind' eq $cln->{legend_label}) and
                                  ('0 1 2' eq join ' ', @{$cln->{x_axis_values}}) and 
                                  ('a b c' eq join ' ', @{$cln->{legend_values}}) and
                                  ('One' eq $cln->{x_axis_titles}->{'0'}) and
                                  ('Two' eq $cln->{x_axis_titles}->{'1'}) and
                                  ('Three' eq $cln->{x_axis_titles}->{'2'}) and
                                  ('Ay' eq $cln->{legend_titles}->{'a'}) and
                                  ('Bee' eq $cln->{legend_titles}->{'b'}) and
                                  ('Cie' eq $cln->{legend_titles}->{'c'}) and
                                  ('Mercury' eq $cln->{y_axis_values}->{'0'}{'a'}) and
                                  ('Venus' eq $cln->{y_axis_values}->{'0'}{'b'}) and
                                  ('Earth' eq $cln->{y_axis_values}->{'0'}{'c'}) and
                                  ('Mars' eq $cln->{y_axis_values}->{'1'}{'a'}) and
                                  ('Jupiter' eq $cln->{y_axis_values}->{'1'}{'b'}) and
                                  ('Uranus' eq $cln->{y_axis_values}->{'1'}{'c'}) and
                                  ('Saturn' eq $cln->{y_axis_values}->{'2'}{'a'}) and
                                  ('Neptune' eq $cln->{y_axis_values}->{'2'}{'b'}) and
                                  ('Pluto' eq $cln->{y_axis_values}->{'2'}{'c'}));

$row[0] = {toot => 'beer'};
$qry = new Relations::Query('hi');

$x_axis->[0] = 'Atlas';
$x_axis->[1] = 'Shrug';

$legend->[0] = 'Mind';
$legend->[1] = 'Spring';

$settings->{'fee'} = 7;
$settings->{'fie'} = 'blue';

$hide->{'Donkey'} = 1;
$hide->{'Falafel'} = 1;

$vertical->[0] = 'Ding';
$vertical->[1] = 'Dong';

$horizontal->[0] = 'Mine';
$horizontal->[1] = 'Mom';

$dsp = new Relations::Display(-query      => $qry,
                              -chart      => 'Pretty',
                              -width      => 'wicked wide',
                              -height     => 'really tall',
                              -prefix     => 'Prefixing',
                              -x_axis     => $x_axis,
                              -legend     => $legend,
                              -y_axis     => 'Hanky',
                              -aggregate  => 0,
                              -settings   => $settings,
                              -abstract   => 'Monkey',
                              -hide       => 'Donkey,Falafel',
                              -vertical   => ['Ding','Dong'],
                              -horizontal => ['Mine','Mom'],
                              -matrix     => \@row,
                              -table      => $tbl);

die "Display new failed" unless (($dsp->{query}->{'select'} eq 'hi') and
                                 ($dsp->{chart} eq 'Pretty') and
                                 ($dsp->{width} eq 'wicked wide') and
                                 ($dsp->{height} eq 'really tall') and
                                 ($dsp->{prefix} eq 'Prefixing') and
                                 ($dsp->{x_axis}->[0] eq 'Atlas') and
                                 ($dsp->{x_axis}->[1] eq 'Shrug') and
                                 ($dsp->{legend}->[0] eq 'Mind') and
                                 ($dsp->{legend}->[1] eq 'Spring') and
                                 ($dsp->{aggregate} == 0) and
                                 ($dsp->{settings}->{fee} == 7) and
                                 ($dsp->{settings}->{fie} eq 'blue') and
                                 ($dsp->{abstract} eq 'Monkey') and
                                 ($dsp->{hide}->{Donkey}) and
                                 ($dsp->{hide}->{Falafel}) and
                                 ($dsp->{vertical}->[0] eq 'Ding') and
                                 ($dsp->{vertical}->[1] eq 'Dong') and
                                 ($dsp->{horizontal}->[0] eq 'Mine') and
                                 ($dsp->{horizontal}->[1] eq 'Mom') and
                                 ($dsp->{matrix}->[0]->{toot} eq 'beer') and
                                 ($dsp->{table}->{title} eq 'The Main Event'));

$qry->add(-select => 'ya');
$x_axis->[0] = 'Rand';
$legend->[0] = 'Visor';
$settings->{'fee'} = 67;
$hide->{'Donkey'} = 0;
$vertical->[0] = 'Dang';
$horizontal->[0] = 'Dad';
$row[0] = {toot => 'fruit'};
$tbl->{title} = 'The Fake Event';

die "Display copy failed" unless (($dsp->{query}->{'select'} eq 'hi') and
                                   ($dsp->{chart} eq 'Pretty') and
                                   ($dsp->{width} eq 'wicked wide') and
                                   ($dsp->{height} eq 'really tall') and
                                   ($dsp->{prefix} eq 'Prefixing') and
                                   ($dsp->{x_axis}->[0] eq 'Atlas') and
                                   ($dsp->{x_axis}->[1] eq 'Shrug') and
                                   ($dsp->{legend}->[0] eq 'Mind') and
                                   ($dsp->{legend}->[1] eq 'Spring') and
                                   ($dsp->{settings}->{fee} == 7) and
                                   ($dsp->{settings}->{fie} eq 'blue') and
                                   ($dsp->{abstract} eq 'Monkey') and
                                   ($dsp->{hide}->{Donkey}) and
                                   ($dsp->{hide}->{Falafel}) and
                                   ($dsp->{vertical}->[0] eq 'Ding') and
                                   ($dsp->{vertical}->[1] eq 'Dong') and
                                   ($dsp->{horizontal}->[0] eq 'Mine') and
                                   ($dsp->{horizontal}->[1] eq 'Mom') and
                                   ($dsp->{matrix}->[0]->{toot} eq 'beer') and
                                   ($dsp->{table}->{title} eq 'The Main Event'));

$qry = new Relations::Query('hi');

$cln = $dsp->clone();

die "Display clone failed" unless (($cln->{query}->{'select'} eq 'hi') and
                                   ($cln->{chart} eq 'Pretty') and
                                   ($cln->{width} eq 'wicked wide') and
                                   ($cln->{height} eq 'really tall') and
                                   ($cln->{prefix} eq 'Prefixing') and
                                   ($cln->{x_axis}->[0] eq 'Atlas') and
                                   ($cln->{x_axis}->[1] eq 'Shrug') and
                                   ($cln->{legend}->[0] eq 'Mind') and
                                   ($cln->{legend}->[1] eq 'Spring') and
                                   ($cln->{settings}->{fee} == 7) and
                                   ($cln->{settings}->{fie} eq 'blue') and
                                   ($cln->{abstract} eq 'Monkey') and
                                   ($cln->{hide}->{Donkey}) and
                                   ($cln->{hide}->{Falafel}) and
                                   ($cln->{vertical}->[0] eq 'Ding') and
                                   ($cln->{vertical}->[1] eq 'Dong') and
                                   ($cln->{horizontal}->[0] eq 'Mine') and
                                   ($cln->{horizontal}->[1] eq 'Mom') and
                                   ($cln->{matrix}->[0]->{toot} eq 'beer') and
                                   ($cln->{table}->{title} eq 'The Main Event'));

$dsp->add(-x_axis     => 'Ayn,Rand',
          -legend     => ['Hand','Thing'],
          -settings   => {'foe' => 11,
                          'fum' => 'moon'},
          -hide       => ['Eating','Waffle'],
          -vertical   => 'Candy,Gram',
          -horizontal => 'Dad,Home');

die "Display add failed" unless (($dsp->{query}->{'select'} eq 'hi') and
                                 ($dsp->{chart} eq 'Pretty') and
                                 ($dsp->{width} eq 'wicked wide') and
                                 ($dsp->{height} eq 'really tall') and
                                 ($dsp->{prefix} eq 'Prefixing') and
                                 ($dsp->{x_axis}->[0] eq 'Atlas') and
                                 ($dsp->{x_axis}->[1] eq 'Shrug') and
                                 ($dsp->{x_axis}->[2] eq 'Ayn') and
                                 ($dsp->{x_axis}->[3] eq 'Rand') and
                                 ($dsp->{legend}->[0] eq 'Mind') and
                                 ($dsp->{legend}->[1] eq 'Spring') and
                                 ($dsp->{legend}->[2] eq 'Hand') and
                                 ($dsp->{legend}->[3] eq 'Thing') and
                                 ($dsp->{settings}->{fee} == 7) and
                                 ($dsp->{settings}->{fie} eq 'blue') and
                                 ($dsp->{settings}->{foe} == 11) and
                                 ($dsp->{settings}->{fum} eq 'moon') and
                                 ($dsp->{abstract} eq 'Monkey') and
                                 ($dsp->{hide}->{Donkey}) and
                                 ($dsp->{hide}->{Falafel}) and
                                 ($dsp->{hide}->{Eating}) and
                                 ($dsp->{hide}->{Waffle}) and
                                 ($dsp->{vertical}->[0] eq 'Ding') and
                                 ($dsp->{vertical}->[1] eq 'Dong') and
                                 ($dsp->{vertical}->[2] eq 'Candy') and
                                 ($dsp->{vertical}->[3] eq 'Gram') and
                                 ($dsp->{horizontal}->[0] eq 'Mine') and
                                 ($dsp->{horizontal}->[1] eq 'Mom') and
                                 ($dsp->{horizontal}->[2] eq 'Dad') and
                                 ($dsp->{horizontal}->[3] eq 'Home') and
                                 ($dsp->{matrix}->[0]->{toot} eq 'beer') and
                                 ($dsp->{table}->{title} eq 'The Main Event'));

$row[0] = {fruit => 'sear'};
$qry = new Relations::Query('whatup');
$tbl = new Relations::Display::Table(-title     => 'The Second Event');
                                      

$dsp->set(-query      => $qry,
          -chart      => 'Funny',
          -width      => 'teeny',
          -height     => 'weeny',
          -prefix     => 'chokes',
          -x_axis     => 'Sucked',
          -legend     => 'Visor',
          -y_axis     => 'Panky',
          -aggregate  => 1,
          -settings   => {'giant' => 'yum'},
          -abstract   => 'BeeGee',
          -hide       => 'Pocket',
          -vertical   => ['Dash'],
          -horizontal => ['Family'],
          -matrix     => \@row,
          -table      => $tbl);

die "Display set failed" unless (($dsp->{query}->{'select'} eq 'whatup') and
                                 ($dsp->{chart} eq 'Funny') and
                                 ($dsp->{width} eq 'teeny') and
                                 ($dsp->{height} eq 'weeny') and
                                 ($dsp->{prefix} eq 'chokes') and
                                 ($dsp->{x_axis}->[0] eq 'Sucked') and
                                 ($dsp->{legend}->[0] eq 'Visor') and
                                 ($dsp->{aggregate} == 1) and
                                 ($dsp->{settings}->{giant} eq 'yum') and
                                 ($dsp->{abstract} eq 'BeeGee') and
                                 ($dsp->{hide}->{Pocket}) and
                                 ($dsp->{vertical}->[0] eq 'Dash') and
                                 ($dsp->{horizontal}->[0] eq 'Family') and
                                 ($dsp->{matrix}->[0]->{fruit} eq 'sear') and
                                 ($dsp->{table}->{title} eq 'The Second Event'));

$dsp->set(-chart      => 'Honey');

die "Display minor set failed" unless (($dsp->{query}->{'select'} eq 'whatup') and
                                       ($dsp->{chart} eq 'Honey') and
                                       ($dsp->{width} eq 'teeny') and
                                       ($dsp->{height} eq 'weeny') and
                                       ($dsp->{prefix} eq 'chokes') and
                                       ($dsp->{x_axis}->[0] eq 'Sucked') and
                                       ($dsp->{legend}->[0] eq 'Visor') and
                                       ($dsp->{aggregate} == 1) and
                                       ($dsp->{settings}->{giant} eq 'yum') and
                                       ($dsp->{abstract} eq 'BeeGee') and
                                       ($dsp->{hide}->{Pocket}) and
                                       ($dsp->{vertical}->[0] eq 'Dash') and
                                       ($dsp->{horizontal}->[0] eq 'Family') and
                                       ($dsp->{matrix}->[0]->{fruit} eq 'sear') and
                                       ($dsp->{table}->{title} eq 'The Second Event'));

$dsp->set(-chart      => '',
          -width      => '',
          -height     => '',
          -prefix     => '',
          -x_axis     => '',
          -legend     => '',
          -y_axis     => '',
          -aggregate  => 0,
          -settings   => {},
          -abstract   => '',
          -hide       => '',
          -vertical   => [],
          -horizontal => [],
          -matrix     => []);

die "Display minus set failed" unless (($dsp->{query}->{'select'} eq 'whatup') and
                                       ($dsp->{chart} eq '') and
                                       ($dsp->{width} eq '') and
                                       ($dsp->{height} eq '') and
                                       ($dsp->{prefix} eq '') and
                                       (!$dsp->{x_axis}->[0]) and
                                       (!$dsp->{legend}->[0]) and
                                       ($dsp->{aggregate} == 0) and
                                       (!$dsp->{settings}->{giant}) and
                                       ($dsp->{abstract} eq '') and
                                       (!$dsp->{hide}->{Pocket}) and
                                       (!$dsp->{vertical}->[0]) and
                                       (!$dsp->{horizontal}->[0]) and
                                       (!$dsp->{matrix}->[0]->{fruit}) and
                                       ($dsp->{table}->{title} eq 'The Second Event'));

$dsp = new Relations::Display(-query    => {-select   => {id    => 'co_id',
                                                          label => 'co_name'},
                                            -from     => 'county',
                                            -order_by => 'co_name'},
                              -abstract => $abs);

$mtx = $dsp->get_matrix();

die "Display get_matrix failed" unless (($mtx->[4]->{id} == 1) and
                                        ($mtx->[4]->{label} eq 'Rockingham') and
                                        ($mtx->[3]->{id} == 2) and
                                        ($mtx->[3]->{label} eq 'Merrimack') and
                                        ($mtx->[1]->{id} == 3) and
                                        ($mtx->[1]->{label} eq 'Coos') and
                                        ($mtx->[0]->{id} == 4) and
                                        ($mtx->[0]->{label} eq 'Boosely') and
                                        ($mtx->[2]->{id} == 5) and
                                        ($mtx->[2]->{label} eq 'Hazard'));

$dsp = new Relations::Display(-matrix   => $mtx,
                              -abstract => $abs);

$mtx = $dsp->get_matrix();

die "Display set get_matrix failed" unless (($mtx->[4]->{id} == 1) and
                                            ($mtx->[4]->{label} eq 'Rockingham') and
                                            ($mtx->[3]->{id} == 2) and
                                            ($mtx->[3]->{label} eq 'Merrimack') and
                                            ($mtx->[1]->{id} == 3) and
                                            ($mtx->[1]->{label} eq 'Coos') and
                                            ($mtx->[0]->{id} == 4) and
                                            ($mtx->[0]->{label} eq 'Boosely') and
                                            ($mtx->[2]->{id} == 5) and
                                            ($mtx->[2]->{label} eq 'Hazard'));

$dsp = new Relations::Display(-query      => {-select   => {total  => "count(*)",
                                                            first  => "'Bird'",
                                                            second => "'Count'",
                                                            third  => "if(gender='Male','Boy','Girl')",
                                                            tao    => "if(gender='Male','Yang','Yin')",
                                                            sex    => "gender",
                                                            kind   => "sp_name",
                                                            id     => "species.sp_id",
                                                            fourth => "(species.sp_id+50)",
                                                            vert   => "2",
                                                            horiz  => "1.5"},
                                              -from     => ['bird','species'],
                                              -where    => ['species.sp_id=bird.sp_id',
                                                            'species.sp_id < 4'],
                                              -group_by => ['sp_name','gender','first','second'],
                                              -order_by => ['gender','sp_name']},
                              -abstract   => $abs,
                              -prefix     => 'Whup',
                              -x_axis     => 'first,kind,id,fourth',
                              -legend     => 'second,third,tao,sex,vert,horiz',
                              -y_axis     => 'total',
                              -hide       => 'fourth,third,vert,horiz',
                              -vertical   => 'vert',
                              -horizontal => 'horiz',
                              -settings   => {title        => 'Happy',
                                              x_label      => 'Hoppy',
                                              y_label      => 'Joy',
                                              legend_label => 'Jay'});

$tbl = $dsp->get_table();

die "Display force get_table failed" unless (($tbl->{title} eq 'Happy') and
                                              ($tbl->{x_label} eq 'Hoppy') and
                                              ($tbl->{y_label} eq 'Joy') and
                                              ($tbl->{legend_label} eq 'Jay') and
                                              ($tbl->{x_axis_values}->[0] eq 'Blue Jay - 1 - 51') and
                                              ($tbl->{x_axis_values}->[1] eq 'Robin - 2 - 52') and
                                              ($tbl->{x_axis_values}->[2] eq 'Sparrow - 3 - 53') and
                                              ($tbl->{legend_values}->[0] eq 'Girl - Yin - Female') and
                                              ($tbl->{legend_values}->[1] eq 'Boy - Yang - Male') and
                                              ($tbl->{x_axis_titles}->{'Blue Jay - 1 - 51'} eq 'Blue Jay - 1') and
                                              ($tbl->{x_axis_titles}->{'Robin - 2 - 52'} eq 'Robin - 2') and
                                              ($tbl->{x_axis_titles}->{'Sparrow - 3 - 53'} eq 'Sparrow - 3') and
                                              ($tbl->{legend_titles}->{'Girl - Yin - Female'} eq 'Yin - Female') and
                                              ($tbl->{legend_titles}->{'Boy - Yang - Male'} eq 'Yang - Male') and
                                              ($tbl->{y_axis_values}->{'Blue Jay - 1 - 51'}{'Girl - Yin - Female'} == 1) and
                                              ($tbl->{y_axis_values}->{'Robin - 2 - 52'}{'Girl - Yin - Female'} == 2) and
                                              ($tbl->{y_axis_values}->{'Sparrow - 3 - 53'}{'Girl - Yin - Female'} == 1) and
                                              ($tbl->{y_axis_values}->{'Blue Jay - 1 - 51'}{'Boy - Yang - Male'} == 3) and
                                              ($tbl->{y_axis_values}->{'Robin - 2 - 52'}{'Boy - Yang - Male'} == 1) and
                                              ($tbl->{y_axis_values}->{'Sparrow - 3 - 53'}{'Boy - Yang - Male'} == 2));

$dsp = new Relations::Display(-table      => $tbl,
                              -abstract   => $abs,
                              -vertical   => 'vert',
                              -horizontal => 'horiz',
                              -settings   => {title        => 'Happy',
                                              x_label      => 'Hoppy',
                                              y_label      => 'Joy',
                                              legend_label => 'Jay'});

$tbl = $dsp->get_table();

die "Display set get_table failed" unless (($tbl->{title} eq 'Happy') and
                                            ($tbl->{x_label} eq 'Hoppy') and
                                            ($tbl->{y_label} eq 'Joy') and
                                            ($tbl->{legend_label} eq 'Jay') and
                                            ($tbl->{x_axis_values}->[0] eq 'Blue Jay - 1 - 51') and
                                            ($tbl->{x_axis_values}->[1] eq 'Robin - 2 - 52') and
                                            ($tbl->{x_axis_values}->[2] eq 'Sparrow - 3 - 53') and
                                            ($tbl->{legend_values}->[0] eq 'Girl - Yin - Female') and
                                            ($tbl->{legend_values}->[1] eq 'Boy - Yang - Male') and
                                            ($tbl->{x_axis_titles}->{'Blue Jay - 1 - 51'} eq 'Blue Jay - 1') and
                                            ($tbl->{x_axis_titles}->{'Robin - 2 - 52'} eq 'Robin - 2') and
                                            ($tbl->{x_axis_titles}->{'Sparrow - 3 - 53'} eq 'Sparrow - 3') and
                                            ($tbl->{legend_titles}->{'Girl - Yin - Female'} eq 'Yin - Female') and
                                            ($tbl->{legend_titles}->{'Boy - Yang - Male'} eq 'Yang - Male') and
                                            ($tbl->{y_axis_values}->{'Blue Jay - 1 - 51'}{'Girl - Yin - Female'} == 1) and
                                            ($tbl->{y_axis_values}->{'Robin - 2 - 52'}{'Girl - Yin - Female'} == 2) and
                                            ($tbl->{y_axis_values}->{'Sparrow - 3 - 53'}{'Girl - Yin - Female'} == 1) and
                                            ($tbl->{y_axis_values}->{'Blue Jay - 1 - 51'}{'Boy - Yang - Male'} == 3) and
                                            ($tbl->{y_axis_values}->{'Robin - 2 - 52'}{'Boy - Yang - Male'} == 1) and
                                            ($tbl->{y_axis_values}->{'Sparrow - 3 - 53'}{'Boy - Yang - Male'} == 2));

$dsp = new Relations::Display(-query      => {-select   => {first  => "'Bird'",
                                                            second => "'Count'",
                                                            third  => "if(gender='Male','Boy','Girl')",
                                                            tao    => "if(gender='Male','Yang','Yin')",
                                                            sex    => "gender",
                                                            kind   => "sp_name",
                                                            id     => "species.sp_id",
                                                            fourth => "(species.sp_id+50)",
                                                            vert   => "2",
                                                            horiz  => "1.5"},
                                              -from     => ['bird','species'],
                                              -where    => ['species.sp_id=bird.sp_id',
                                                            'species.sp_id < 4'],
                                              -order_by => ['gender','sp_name']},
                              -abstract   => $abs,
                              -prefix     => 'Whup',
                              -x_axis     => 'sex,third,tao',
                              -legend     => 'second,vert,horiz',
                              -y_axis     => 'id',
                              -aggregate  => 1,
                              -hide       => 'fourth,third,vert,horiz',
                              -vertical   => 'vert',
                              -horizontal => 'horiz');

$tbl = $dsp->get_table();

die "Display aggregate get_table failed" unless (($tbl->{title} eq 'Whup - Count') and
                                                ($tbl->{x_label} eq 'sex - tao') and
                                                ($tbl->{y_label} eq 'id') and
                                                ($tbl->{legend_label} eq '') and
                                                ($tbl->{x_axis_values}->[0] eq 'Female - Girl - Yin') and
                                                ($tbl->{x_axis_values}->[1] eq 'Male - Boy - Yang') and
                                                ($tbl->{legend_values}->[0] eq '') and
                                                ($tbl->{x_axis_titles}->{'Female - Girl - Yin'} eq 'Female - Yin') and
                                                ($tbl->{x_axis_titles}->{'Male - Boy - Yang'} eq 'Male - Yang') and
                                                ($tbl->{legend_titles}->{''} eq '') and
                                                ($tbl->{y_axis_values}->{'Female - Girl - Yin'}{''}->[0] == 1) and
                                                ($tbl->{y_axis_values}->{'Female - Girl - Yin'}{''}->[1] == 2) and
                                                ($tbl->{y_axis_values}->{'Female - Girl - Yin'}{''}->[2] == 2) and
                                                ($tbl->{y_axis_values}->{'Female - Girl - Yin'}{''}->[3] == 3) and
                                                ($tbl->{y_axis_values}->{'Male - Boy - Yang'}{''}->[0] == 1) and
                                                ($tbl->{y_axis_values}->{'Male - Boy - Yang'}{''}->[1] == 1) and
                                                ($tbl->{y_axis_values}->{'Male - Boy - Yang'}{''}->[2] == 1) and
                                                ($tbl->{y_axis_values}->{'Male - Boy - Yang'}{''}->[3] == 2) and
                                                ($tbl->{y_axis_values}->{'Male - Boy - Yang'}{''}->[4] == 3) and
                                                ($tbl->{y_axis_values}->{'Male - Boy - Yang'}{''}->[5] == 3));

$dsp->set(-chart  => 'boxplot',
          -width  => 400,
          -height => 400,
          -settings => {y_min_value => 0,
                        y_max_value => 3,
                        y_tick_number => 3,
                        transparent => 0}
          );

$gph = $dsp->get_graph();

$dsp = new Relations::Display(-query      => {-select   => {total  => "count(*)",
                                                            first  => "'Bird'",
                                                            second => "'Count'",
                                                            third  => "if(gender='Male','Boy','Girl')",
                                                            tao    => "if(gender='Male','Yang','Yin')",
                                                            "'sex type'" => "gender",
                                                            kind   => "sp_name",
                                                            id     => "species.sp_id",
                                                            fourth => "(species.sp_id+50)",
                                                            vert   => "2",
                                                            horiz  => "1.5"},
                                              -from     => ['bird','species'],
                                              -where    => ['species.sp_id=bird.sp_id',
                                                            'species.sp_id < 4'],
                                              -group_by => ['sp_name','gender','first','second'],
                                              -order_by => ['gender','sp_name']},
                              -abstract   => $abs,
                              -prefix     => 'Whup',
                              -x_axis     => 'first,kind,id,fourth',
                              -legend     => 'second,third,tao,sex type,vert,horiz',
                              -y_axis     => 'total',
                              -hide       => 'fourth,third,vert,horiz',
                              -vertical   => 'vert',
                              -horizontal => 'horiz');

$tbl = $dsp->get_table();

die "Display auto get_table failed" unless (($tbl->{title} eq 'Whup - Bird - Count') and
                                            ($tbl->{x_label} eq 'kind - id') and
                                            ($tbl->{y_label} eq 'total') and
                                            ($tbl->{legend_label} eq 'tao - sex type') and
                                            ($tbl->{x_axis_values}->[0] eq 'Blue Jay - 1 - 51') and
                                            ($tbl->{x_axis_values}->[1] eq 'Robin - 2 - 52') and
                                            ($tbl->{x_axis_values}->[2] eq 'Sparrow - 3 - 53') and
                                            ($tbl->{legend_values}->[0] eq 'Girl - Yin - Female') and
                                            ($tbl->{legend_values}->[1] eq 'Boy - Yang - Male') and
                                            ($tbl->{x_axis_titles}->{'Blue Jay - 1 - 51'} eq 'Blue Jay - 1') and
                                            ($tbl->{x_axis_titles}->{'Robin - 2 - 52'} eq 'Robin - 2') and
                                            ($tbl->{x_axis_titles}->{'Sparrow - 3 - 53'} eq 'Sparrow - 3') and
                                            ($tbl->{legend_titles}->{'Girl - Yin - Female'} eq 'Yin - Female') and
                                            ($tbl->{legend_titles}->{'Boy - Yang - Male'} eq 'Yang - Male') and
                                            ($tbl->{y_axis_values}->{'Blue Jay - 1 - 51'}{'Girl - Yin - Female'} == 1) and
                                            ($tbl->{y_axis_values}->{'Robin - 2 - 52'}{'Girl - Yin - Female'} == 2) and
                                            ($tbl->{y_axis_values}->{'Sparrow - 3 - 53'}{'Girl - Yin - Female'} == 1) and
                                            ($tbl->{y_axis_values}->{'Blue Jay - 1 - 51'}{'Boy - Yang - Male'} == 3) and
                                            ($tbl->{y_axis_values}->{'Robin - 2 - 52'}{'Boy - Yang - Male'} == 1) and
                                            ($tbl->{y_axis_values}->{'Sparrow - 3 - 53'}{'Boy - Yang - Male'} == 2));

$dsp->set(-chart  => 'bars',
          -width  => 400,
          -height => 400,
          -settings => {y_min_value => 0,
                        y_max_value => 3,
                        y_tick_number => 3,
                        transparent => 0}
          );

$gph = $dsp->get_graph();

$gd = $gph->gd();

open(IMG, '>test.png') or die $!;
binmode IMG;
print IMG $gd->png;

print "\nEverything seems fine\n";

sub create_watcher {

  my $abs = shift;
  my $database = shift;

  $create = "

    DROP DATABASE IF EXISTS $database;
    CREATE DATABASE $database;
    USE $database;

    CREATE TABLE bird (
       bd_id int(10) unsigned NOT NULL auto_increment,
       sp_id int(10) unsigned DEFAULT '0' NOT NULL,
       co_id int(10) unsigned DEFAULT '0' NOT NULL,
       bd_name char(16) NOT NULL,
       gender enum('Female','Male') DEFAULT 'Male' NOT NULL,
       age tinyint(3) unsigned DEFAULT '0' NOT NULL,
       PRIMARY KEY (bd_id),
       UNIQUE bd_name (bd_name),
       KEY sp_id (sp_id)
    );

    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '1', '1', '2', 'Joe', 'Male', '2');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '2', '5', '1', 'Sally', 'Female', '3');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '3', '7', '4', 'Smiley', 'Female', '1');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '4', '5', '4', 'Fred', 'Male', '8');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '5', '1', '1', 'Blue Lou', 'Male', '4');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '6', '2', '3', 'Red', 'Female', '5');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '7', '4', '5', 'Speedy', 'Male', '4');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '8', '6', '5', 'African', 'Male', '3');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '9', '6', '2', 'Eastern', 'Female', '2');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '10', '3', '3', 'Micky-D', 'Male', '6');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '11', '3', '4', 'BK', 'Male', '4');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '12', '3', '1', 'Wendy', 'Female', '9');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '13', '2', '4', 'Round', 'Female', '5');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '14', '1', '2', 'Fly Boy', 'Male', '4');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '15', '5', '5', 'Mike', 'Male', '4');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '16', '2', '3', 'Jonny', 'Male', '1');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '17', '4', '4', 'Suzy', 'Female', '5');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '18', '4', '2', 'Sammy', 'Female', '7');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '19', '6', '5', 'Coco', 'Male', '8');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '20', '7', '3', 'Bull', 'Male', '4');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '21', '7', '4', 'Gaffer', 'Male', '4');
    INSERT INTO bird (bd_id, sp_id, co_id, bd_name, gender, age) VALUES ( '22', '1', '1', 'Sweety', 'Female', '4');

    CREATE TABLE county (
       co_id int(10) unsigned NOT NULL auto_increment,
       co_name char(32) NOT NULL,
       PRIMARY KEY (co_id),
       UNIQUE co_name (co_name)
    );

    INSERT INTO county (co_id, co_name) VALUES ( '1', 'Rockingham');
    INSERT INTO county (co_id, co_name) VALUES ( '2', 'Merrimack');
    INSERT INTO county (co_id, co_name) VALUES ( '3', 'Coos');
    INSERT INTO county (co_id, co_name) VALUES ( '4', 'Boosely');
    INSERT INTO county (co_id, co_name) VALUES ( '5', 'Hazard');

    CREATE TABLE species (
       sp_id int(10) unsigned NOT NULL auto_increment,
       sp_name char(24) NOT NULL,
       PRIMARY KEY (sp_id),
       UNIQUE sp_name (sp_name)
    );

    INSERT INTO species (sp_id, sp_name) VALUES ( '1', 'Blue Jay');
    INSERT INTO species (sp_id, sp_name) VALUES ( '2', 'Robin');
    INSERT INTO species (sp_id, sp_name) VALUES ( '3', 'Sparrow');
    INSERT INTO species (sp_id, sp_name) VALUES ( '4', 'Flicker');
    INSERT INTO species (sp_id, sp_name) VALUES ( '5', 'Black Bird');
    INSERT INTO species (sp_id, sp_name) VALUES ( '6', 'Swallow');
    INSERT INTO species (sp_id, sp_name) VALUES ( '7', 'Finch')
        
  ";

  @create = split ';',$create;

  foreach $create (@create) {

    $abs->run_query($create);

  }

}

