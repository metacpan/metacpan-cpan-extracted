#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Parse::PhoneNumber::ID qw(extract_id_phones parse_id_phone);

test_extract(
    name => 'too short',
    args => {text=>'022 1234'},
    num  => 0,
);
test_extract(
    name => 'too long',
    args => {text=>'022 123456789'},
    num  => 0,
);

test_extract(
    name => 'pat ind+cc+karea+local+ext, local_number, area_code',
    args => {text=>'Hub: (+62) 22 12345678 ext 100'},
    num  => 1,
    res  => [{standard=>'+62.22.12345678.ext100',
              province=>'jabar', area_code=>'022', ext=>'100'}],
);
test_extract(
    name => 'pat ind+cc+prefix+local, country_code, non-id number, is_fax',
    args => {text=>'Fax: +65.12.123456'},
    num  => 1,
    res  => [{standard=>'+65.12.123456', country_code=>'65', is_fax=>1}],
);
TODO: {
    local $TODO = "todo";
    fail("reject intl number 65-(022)-23918233");
}
test_extract(
    name => 'pat ind+karea+local+ext',
    args => {text=>'Hub: 022 12345678 extension 2000'},
    num  => 1,
    res  => [{standard=>'+62.22.12345678.ext2000', province=>'jabar'}],
);
test_extract(
    name => 'pat ind+kprefix+local',
    args => {text=>'T.0812.123-4567'},
    num  => 1,
    res  => [{standard=>'+62.812.1234567', operator=>'telkomsel'}],
);
test_extract(
    name => 'pat ind+prefix+local, unknown prefix',
    args => {text=>'T.0444.123-4567'},
    num  => 1,
    res  => [{standard=>'+62.444.1234567', is_cell=>0, is_land=>0}],
);
test_extract(
    name => 'pat ind+local, without default_area_code',
    args => {text=>'Telp71234567'},
    num  => 0,
);
test_extract(
    name => 'pat ind+local, with default_area_code, fwa area_code',
    args => {text=>'Tlp:71-23-4567', default_area_code=>'022'},
    num  => 1,
    res  => [{standard=>'+62.22.71234567', is_cdma=>1, operator=>'telkom',
              product=>'flexi'}],
);

test_extract(
    name => 'pat cc+karea+local+ext',
    args => {text=>'(+62) 22 12345678 ext 100'},
    num  => 1,
    res  => [{standard=>'+62.22.12345678.ext100'}],
);
test_extract(
    name => 'pat cc+prefix+local',
    args => {text=>'Fax: +65.12.123456'},
    num  => 1,
    res  => [{standard=>'+65.12.123456'}],
);
test_extract(
    name => 'pat kprefix+local',
    args => {text=>'0812.123-4567'},
    num  => 1,
    res  => [{standard=>'+62.812.1234567'}],
);
test_extract(
    name => 'pat prefix+local',
    args => {text=>'0444.123-4567'},
    num  => 1,
    res  => [{standard=>'+62.444.1234567'}],
);
test_extract(
    name => 'local',
    args => {text=>'91234567', default_area_code=>'021'},
    num  => 1,
    res  => [{standard=>'+62.21.91234567'}],
);

test_extract(
    name => 'preprocess remove spaces',
    args => {text=>'022 9 1 2 3 4 5 6 7', level=>6},
    num  => 1,
    res  => [{standard=>'+62.22.91234567'}],
);

test_extract(
    name => 'preprocess letters->digits',
    args => {text=>'022 9oool23', level=>6},
    num  => 1,
    res  => [{standard=>'+62.22.9000123'}],
);

test_extract(
    name => 'adjacent kprefix+local',
    args => {text=>'021-91234567/68'},
    num  => 2,
    res  => [{standard=>'+62.21.91234567'}, {standard=>'+62.21.91234568'}],
);
test_extract(
    name => 'adjacent ind+local',
    args => {text=>'Kontak: 9123459/60', default_area_code=>'0276'},
    num  => 2,
    res  => [{standard=>'+62.276.9123459'}, {standard=>'+62.276.9123460'}],
);

test_extract(
    name => 'prefers numbers at the end',
    args => {text=>'Kode 2501234 Hubungi: 2501235', default_area_code=>'022',
             max_numbers=>1},
    num  => 1,
    res  => [{standard=>'+62.22.2501235'}],
);

TODO: {
    local $TODO = "todo";
    fail("preprocess words->digit");
    # e.g.: nol (de)lapan limaenamsatuduatiga empat lima enam -> 0856 123456
}

my %sample_data = (
    # from PR 2011-03-07
    "hny 50rbSpa&Massage,Sunda 71\nNewTeraphist+Room,91641176" => ['+62.22.91641176'],
    "NbDelC2D=2,9AcerAspire+Wbca\nm+DVDRW=2,3 T.082115768730"   => ['+62.821.15768730'],
    "APV.T:022-73999999/91819999" => ['+62.22.73999999', '+62.22.91819999'],
    "WIDITOUR2005813-2005814" => ['+62.22.2005813', '+62.22.2005814'],
    "Drop Max 6Org 400Rb:7OOO9661" => ['+62.22.70009661'],
    "Hub:Hp:0813 9450 6959" => ['+62.813.94506959'],
    "MRH,GRS T.7 2 3 2 5 7 3" => ['+62.22.7232573'],
    "MM-A. Yani221 KavB12-7276756" => ['+62.22.7276756'], # klocal before prefix+local
    "HPL Mimik5211262/0818424693" => ['+62.818.424693', '+62.22.5211262'],
    #"022--1234567" => ['+62.'], # TODO: em dash
    "T:7041.0835-0812.8456.3465" => ['+62.22.70410835', '+62.812.84563465'],
    "T:022-70362090-08122021027" => ['+62.22.70362090', '+62.812.2021027'],
    "N.EYES & MP320/BMW/JAZZ/\nINV/AVZ/APV:08122121135" => ['+62.812.2121135'],
    "0813.8080\n1549;BANDUNG/022-72249239" => ['+62.813.80801549', '+62.22.72249239'], # num separated by newline
    "Soekarno Hatta 45-61151901" => ['+62.22.61151901'], # klocal before prefix+local
    "MB/Proc 750/1130\n71123030" => ['+62.22.71123030'], # 750/1130 is price (in thousand Rp).
);
for my $t (sort keys %sample_data) {
    my $t_ = $t; $t_ =~ s/\n/\\n/g;
    my $d = $sample_data{$t};
    test_extract(
        name => "sample data ($t_)",
        args => {text=>$t, default_area_code=>'022', level=>6},
        num=>scalar(@$d),
        res=>[map {{standard=>$_}} @$d]
    );
}

my $res = parse_id_phone(text=>'022-123-4567');
is($res->{standard}, "+62.22.1234567", "parse");

done_testing();

sub test_extract {
    my %args = @_;
    my $extract_args = $args{args};
    my $res = extract_id_phones(%$extract_args);

    subtest "extract: $args{name}" => sub {
        if (defined $args{num}) {
            is(scalar @$res, $args{num},
               "number of extracted phones");
        }
        if ($args{res}) {
            for my $i (0..@{ $args{res} }-1) {
                my $r = $args{res}[$i];
                for (keys %$r) {
                    is($res->[$i]{$_}, $r->{$_}, "res[$i]{$_}");
                }
            }
        }
    };
}
