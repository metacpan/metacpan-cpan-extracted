package TableData::Chemistry::Element;

use strict;
use utf8;

use Role::Tiny::With;
with 'TableDataRole::Source::CSVInDATA';
with 'TableDataRole::Spec::TableDef';

sub get_table_def {
    return +{
        fields => {
            atomic_number => {pos=>0, schema=>'posint*'},
            symbol        => {pos=>1, schema=>'str*'},
            eng_name      => {pos=>2, schema=>'str*'},
            ind_name      => {pos=>3, schema=>'str*'},
            name_origin   => {pos=>4, schema=>'str*'},
            group         => {pos=>5, schema=>'str*'},
            period        => {pos=>6, schema=>'str*'},
            block         => {pos=>7, schema=>'str*'},
            standard_atomic_weight => {pos=>8, schema=>'float*'},
            density       => {pos=>9, schema=>'float*'},
            melting_point => {pos=>10, schema=>'float*'},
            boiling_point => {pos=>11, schema=>'float*'},
            specific_heat_capacity => {pos=>12, schema=>'float*'},
            electronegativity => {pos=>13, schema=>'float*'},
            abundance_in_earth_crust => {pos=>14, schema=>'str*'},
            origin        => {pos=>15, schema=>'str*'},
            phase_at_rt   => {pos=>16, schema=>'str*'},
        },
        pk => 'atomic_number',
    };
}

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-24'; # DATE
our $DIST = 'TableData-Chemistry-Element'; # DIST
our $VERSION = '0.004'; # VERSION

our %STATS = ("num_columns",17,"num_rows",118); # STATS

1;
# ABSTRACT: Chemical elements

=pod

=encoding UTF-8

=head1 NAME

TableData::Chemistry::Element - Chemical elements

=head1 VERSION

This document describes version 0.004 of TableData::Chemistry::Element (from Perl distribution TableData-Chemistry-Element), released on 2023-02-24.

=head1 SYNOPSIS

To use from Perl code:

 use TableData::Chemistry::Element;

 my $td = TableData::Chemistry::Element->new;

 # Iterate rows of the table
 $td->each_row_arrayref(sub { my $row = shift; ... });
 $td->each_row_hashref (sub { my $row = shift; ... });

 # Get the list of column names
 my @columns = $td->get_column_names;

 # Get the number of rows
 my $row_count = $td->get_row_count;

See also L<TableDataRole::Spec::Basic> for other methods.

To use from command-line (using L<tabledata> CLI):

 # Display as ASCII table and view with pager
 % tabledata Chemistry::Element --page

 # Get number of rows
 % tabledata --action count_rows Chemistry::Element

See the L<tabledata> CLI's documentation for other available actions and options.

=head1 TABLEDATA STATISTICS

 +-------------+-------+
 | key         | value |
 +-------------+-------+
 | num_columns | 17    |
 | num_rows    | 118   |
 +-------------+-------+

The statistics is available in the C<%STATS> package variable.

=for Pod::Coverage ^(get_table_def)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-Chemistry-Element>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Chemistry-Element>.

=head1 SEE ALSO

Source: L<https://en.wikipedia.org/wiki/List_of_chemical_elements>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData-Chemistry-Element>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__DATA__
atomic_number,symbol,eng_name,ind_name,name_origin,group,period,block,standard_atomic_weight,density,melting_point,boiling_point,specific_heat_capacity,electronegativity,abundance_in_earth_crust,origin,phase_at_rt
1,H ,Hydrogen ,Hidrogen,"Greek elements hydro- and -gen, 'water-forming' ",1,1,s-block ,1.008,0.00008988,14.01,20.28,14.304,2.2,1400,primordial ,gas
2,He ,Helium ,Helium,"Greek hḗlios, 'sun' ",18,1,s-block ,4.0026,0.0001785,– ,4.22,5.193,– ,0.008,primordial ,gas
3,Li ,Lithium ,Litium,"Greek líthos, 'stone' ",1,2,s-block ,6.94,0.534,453.69,1560,3.582,0.98,20,primordial ,solid
4,Be ,Beryllium ,Berilium,"Beryl, a mineral (ultimately from the name of Belur in southern India)",2,2,s-block ,9.0122,1.85,1560,2742,1.825,1.57,2.8,primordial ,solid
5,B ,Boron ,Boron,"Borax, a mineral (from Arabic bawraq, Middle Persian *bōrag) ",13,2,p-block ,10.81,2.34,2349,4200,1.026,2.04,10,primordial ,solid
6,C ,Carbon ,Karbon,"Latin carbo, 'coal' ",14,2,p-block ,12.011,2.267,>4000 ,4300,0.709,2.55,200,primordial ,solid
7,N ,Nitrogen ,Nitrogen,"Greek nítron and -gen, 'niter-forming' ",15,2,p-block ,14.007,0.0012506,63.15,77.36,1.04,3.04,19,primordial ,gas
8,O ,Oxygen ,Oksigen,"Greek oxy- and -gen, 'acid-forming' ",16,2,p-block ,15.999,0.001429,54.36,90.2,0.918,3.44,461000,primordial ,gas
9,F ,Fluorine ,Fluorin,"Latin fluere, 'to flow' ",17,2,p-block ,18.998,0.001696,53.53,85.03,0.824,3.98,585,primordial ,gas
10,Ne ,Neon ,Neon,"Greek néon, 'new' ",18,2,p-block ,20.18,0.0009002,24.56,27.07,1.03,– ,0.005,primordial ,gas
11,Na ,Sodium ,Natrium,"English (from medieval Latin) soda
 ·  Symbol Na is derived from New Latin natrium, coined from German Natron, 'natron' ",1,3,s-block ,22.99,0.968,370.87,1156,1.228,0.93,23600,primordial ,solid
12,Mg ,Magnesium ,Magnesium,"Magnesia, a district of Eastern Thessaly in Greece ",2,3,s-block ,24.305,1.738,923,1363,1.023,1.31,23300,primordial ,solid
13,Al ,Aluminium ,Aluminium,"Alumina, from Latin alumen (gen. aluminis), 'bitter salt, alum' ",13,3,p-block ,26.982,2.7,933.47,2792,0.897,1.61,82300,primordial ,solid
14,Si ,Silicon ,Silikon,"Latin silex, 'flint' (originally silicium) ",14,3,p-block ,28.085,2.329,1687,3538,0.705,1.9,282000,primordial ,solid
15,P ,Phosphorus ,Fosforus,"Greek phōsphóros, 'light-bearing' ",15,3,p-block ,30.974,1.823,317.3,550,0.769,2.19,1050,primordial ,solid
16,S ,Sulfur ,Belerang,"Latin sulphur, 'brimstone' ",16,3,p-block ,32.06,2.07,388.36,717.87,0.71,2.58,350,primordial ,solid
17,Cl ,Chlorine ,Klorin,"Greek chlōrós, 'greenish yellow' ",17,3,p-block ,35.45,0.0032,171.6,239.11,0.479,3.16,145,primordial ,gas
18,Ar ,Argon ,Argon,"Greek argós, 'idle' (because of its inertness) ",18,3,p-block ,39.95,0.001784,83.8,87.3,0.52,– ,3.5,primordial ,gas
19,K ,Potassium ,Kalium,"New Latin potassa, 'potash', itself from pot and ash
 ·  Symbol K is derived from Latin kalium ",1,4,s-block ,39.098,0.89,336.53,1032,0.757,0.82,20900,primordial ,solid
20,Ca ,Calcium ,Kalsium,"Latin calx, 'lime' ",2,4,s-block ,40.078,1.55,1115,1757,0.647,1,41500,primordial ,solid
21,Sc ,Scandium ,Skandium,"Latin Scandia, 'Scandinavia' ",3,4,d-block ,44.956,2.985,1814,3109,0.568,1.36,22,primordial ,solid
22,Ti ,Titanium ,Titanium,"Titans, the sons of the Earth goddess of Greek mythology ",4,4,d-block ,47.867,4.506,1941,3560,0.523,1.54,5650,primordial ,solid
23,V ,Vanadium ,Vanadium,"Vanadis, an Old Norse name for the Scandinavian goddess Freyja ",5,4,d-block ,50.942,6.11,2183,3680,0.489,1.63,120,primordial ,solid
24,Cr ,Chromium ,Kromium,"Greek chróma, 'colour' ",6,4,d-block ,51.996,7.15,2180,2944,0.449,1.66,102,primordial ,solid
25,Mn ,Manganese ,Mangan,Corrupted from magnesia negra; see § magnesium ,7,4,d-block ,54.938,7.21,1519,2334,0.479,1.55,950,primordial ,solid
26,Fe ,Iron ,Besi,"English word, from Proto-Celtic *īsarnom ('iron'), from a root meaning 'blood'
 ·  Symbol Fe is derived from Latin ferrum ",8,4,d-block ,55.845,7.874,1811,3134,0.449,1.83,56300,primordial ,solid
27,Co ,Cobalt ,Kobalt,"German Kobold, 'goblin' ",9,4,d-block ,58.933,8.9,1768,3200,0.421,1.88,25,primordial ,solid
28,Ni ,Nickel ,Nikel,"Nickel, a mischievous sprite of German miner mythology ",10,4,d-block ,58.693,8.908,1728,3186,0.444,1.91,84,primordial ,solid
29,Cu ,Copper ,Tembaga,"English word, from Latin cuprum, from Ancient Greek Kýpros 'Cyprus' ",11,4,d-block ,63.546,8.96,1357.77,2835,0.385,1.9,60,primordial ,solid
30,Zn ,Zinc ,Seng,"Most likely from German Zinke, 'prong' or 'tooth', though some suggest Persian sang, 'stone' ",12,4,d-block ,65.38,7.14,692.88,1180,0.388,1.65,70,primordial ,solid
31,Ga ,Gallium ,Galium,"Latin Gallia, 'France' ",13,4,p-block ,69.723,5.91,302.9146,2673,0.371,1.81,19,primordial ,solid
32,Ge ,Germanium ,Germanium,"Latin Germania, 'Germany' ",14,4,p-block ,72.63,5.323,1211.4,3106,0.32,2.01,1.5,primordial ,solid
33,As ,Arsenic ,Arsen,"French arsenic, from Greek arsenikón 'yellow arsenic' (influenced by arsenikós, 'masculine' or 'virile'), from a West Asian wanderword ultimately from Old Iranian *zarniya-ka, 'golden' ",15,4,p-block ,74.922,5.727,1090,887,0.329,2.18,1.8,primordial ,solid
34,Se ,Selenium ,Selenium,"Greek selḗnē, 'moon' ",16,4,p-block ,78.971,4.81,453,958,0.321,2.55,0.05,primordial ,solid
35,Br ,Bromine ,Bromin,"Greek brômos, 'stench' ",17,4,p-block ,79.904,3.1028,265.8,332,0.474,2.96,2.4,primordial ,liquid
36,Kr ,Krypton ,Kripton,"Greek kryptós, 'hidden' ",18,4,p-block ,83.798,0.003749,115.79,119.93,0.248,3,0.0001,primordial ,gas
37,Rb ,Rubidium ,Rubidium,"Latin rubidus, 'deep red' ",1,5,s-block ,85.468,1.532,312.46,961,0.363,0.82,90,primordial ,solid
38,Sr ,Strontium ,Stronsium,"Strontian, a village in Scotland, where it was found ",2,5,s-block ,87.62,2.64,1050,1655,0.301,0.95,370,primordial ,solid
39,Y ,Yttrium ,Itrium,"Ytterby, Sweden, where it was found; see also terbium, erbium, ytterbium ",3,5,d-block ,88.906,4.472,1799,3609,0.298,1.22,33,primordial ,solid
40,Zr ,Zirconium ,Zirkonium,"Zircon, a mineral, from Persian zargun, 'gold-hued' ",4,5,d-block ,91.224,6.52,2128,4682,0.278,1.33,165,primordial ,solid
41,Nb ,Niobium ,Niobium,"Niobe, daughter of king Tantalus from Greek mythology; see also tantalum ",5,5,d-block ,92.906,8.57,2750,5017,0.265,1.6,20,primordial ,solid
42,Mo ,Molybdenum ,Molibdenum,"Greek molýbdaina, 'piece of lead', from mólybdos, 'lead', due to confusion with lead ore galena (PbS) ",6,5,d-block ,95.95,10.28,2896,4912,0.251,2.16,1.2,primordial ,solid
43,Tc ,Technetium ,Teknesium,"Greek tekhnētós, 'artificial' ",7,5,d-block ,[97],11,2430,4538,– ,1.9,0.000000003,from decay ,solid
44,Ru ,Ruthenium ,Rutenium,"New Latin Ruthenia, 'Russia' ",8,5,d-block ,101.07,12.45,2607,4423,0.238,2.2,0.001,primordial ,solid
45,Rh ,Rhodium ,Rodium,"Greek rhodóeis, 'rose-coloured', from rhódon, 'rose' ",9,5,d-block ,102.91,12.41,2237,3968,0.243,2.28,0.001,primordial ,solid
46,Pd ,Palladium ,Paladium,"Pallas, an asteroid, considered a planet at the time ",10,5,d-block ,106.42,12.023,1828.05,3236,0.244,2.2,0.015,primordial ,solid
47,Ag ,Silver ,Perak,"English word
 ·  Symbol Ag is derived from Latin argentum ",11,5,d-block ,107.87,10.49,1234.93,2435,0.235,1.93,0.075,primordial ,solid
48,Cd ,Cadmium ,Kadmium,"New Latin cadmia, from King Kadmos ",12,5,d-block ,112.41,8.65,594.22,1040,0.232,1.69,0.159,primordial ,solid
49,In ,Indium ,Indium,"Latin indicum, 'indigo', the blue colour found in its spectrum ",13,5,p-block ,114.82,7.31,429.75,2345,0.233,1.78,0.25,primordial ,solid
50,Sn ,Tin ,Timah,"English word
 ·  Symbol Sn is derived from Latin stannum ",14,5,p-block ,118.71,7.265,505.08,2875,0.228,1.96,2.3,primordial ,solid
51,Sb ,Antimony ,Antimon,"Latin antimonium, the origin of which is uncertain: folk etymologies suggest it is derived from Greek antí ('against') + mónos ('alone'), or Old French anti-moine, 'Monk's bane', but it could plausibly be from or related to Arabic ʾiṯmid, 'antimony', reformatted as a Latin word
 ·  Symbol Sb is derived from Latin stibium 'stibnite' ",15,5,p-block ,121.76,6.697,903.78,1860,0.207,2.05,0.2,primordial ,solid
52,Te ,Tellurium ,Telurium,"Latin tellus, 'the ground, earth' ",16,5,p-block ,127.6,6.24,722.66,1261,0.202,2.1,0.001,primordial ,solid
53,I ,Iodine ,Iodin,"French iode, from Greek ioeidḗs, 'violet' ",17,5,p-block ,126.9,4.933,386.85,457.4,0.214,2.66,0.45,primordial ,solid
54,Xe ,Xenon ,Xenon,"Greek xénon, neuter form of xénos 'strange' ",18,5,p-block ,131.29,0.005894,161.4,165.03,0.158,2.6,0.00003,primordial ,gas
55,Cs ,Caesium ,Sesium,"Latin caesius, 'sky-blue' ",1,6,s-block ,132.91,1.93,301.59,944,0.242,0.79,3,primordial ,solid
56,Ba ,Barium ,Barium,"Greek barýs, 'heavy' ",2,6,s-block ,137.33,3.51,1000,2170,0.204,0.89,425,primordial ,solid
57,La ,Lanthanum ,Lantanum,"Greek lanthánein, 'to lie hidden' ",f-block groups ,6,f-block ,138.91,6.162,1193,3737,0.195,1.1,39,primordial ,solid
58,Ce ,Cerium ,Serium,"Ceres, a dwarf planet, considered a planet at the time ",f-block groups ,6,f-block ,140.12,6.77,1068,3716,0.192,1.12,66.5,primordial ,solid
59,Pr ,Praseodymium ,Praseodimium,"Greek prásios dídymos, 'green twin' ",f-block groups ,6,f-block ,140.91,6.77,1208,3793,0.193,1.13,9.2,primordial ,solid
60,Nd ,Neodymium ,Neodimium,"Greek néos dídymos, 'new twin' ",f-block groups ,6,f-block ,144.24,7.01,1297,3347,0.19,1.14,41.5,primordial ,solid
61,Pm ,Promethium ,Prometium,"Prometheus, a figure in Greek mythology ",f-block groups ,6,f-block ,[145] ,7.26,1315,3273,– ,1.13,2×10−19 ,from decay ,solid
62,Sm ,Samarium ,Samarium,"Samarskite, a mineral named after V. Samarsky-Bykhovets, Russian mine official ",f-block groups ,6,f-block ,150.36,7.52,1345,2067,0.197,1.17,7.05,primordial ,solid
63,Eu ,Europium ,Europium,Europe ,f-block groups ,6,f-block ,151.96,5.244,1099,1802,0.182,1.2,2,primordial ,solid
64,Gd ,Gadolinium ,Gadolinium,"Gadolinite, a mineral named after Johan Gadolin, Finnish chemist, physicist and mineralogist ",f-block groups ,6,f-block ,157.25,7.9,1585,3546,0.236,1.2,6.2,primordial ,solid
65,Tb ,Terbium ,Terbium,"Ytterby, Sweden, where it was found; see also yttrium, erbium, ytterbium ",f-block groups ,6,f-block ,158.93,8.23,1629,3503,0.182,1.2,1.2,primordial ,solid
66,Dy ,Dysprosium ,Disprosium,"Greek dysprósitos, 'hard to get' ",f-block groups ,6,f-block ,162.5,8.54,1680,2840,0.17,1.22,5.2,primordial ,solid
67,Ho ,Holmium ,Holmium,"New Latin Holmia, 'Stockholm' ",f-block groups ,6,f-block ,164.93,8.79,1734,2993,0.165,1.23,1.3,primordial ,solid
68,Er ,Erbium ,Erbium,"Ytterby, Sweden, where it was found; see also yttrium, terbium, ytterbium ",f-block groups ,6,f-block ,167.26,9.066,1802,3141,0.168,1.24,3.5,primordial ,solid
69,Tm ,Thulium ,Tulium,"Thule, the ancient name for an unclear northern location ",f-block groups ,6,f-block ,168.93,9.32,1818,2223,0.16,1.25,0.52,primordial ,solid
70,Yb ,Ytterbium ,Iterbium,"Ytterby, Sweden, where it was found; see also yttrium, terbium, erbium ",f-block groups ,6,f-block ,173.05,6.9,1097,1469,0.155,1.1,3.2,primordial ,solid
71,Lu ,Lutetium ,Lutesium,"Latin Lutetia, 'Paris' ",3,6,d-block ,174.97,9.841,1925,3675,0.154,1.27,0.8,primordial ,solid
72,Hf ,Hafnium ,Hafnium,"New Latin Hafnia, 'Copenhagen' (from Danish havn, harbour) ",4,6,d-block ,178.49,13.31,2506,4876,0.144,1.3,3,primordial ,solid
73,Ta ,Tantalum ,Tantalum,"King Tantalus, father of Niobe from Greek mythology; see also niobium ",5,6,d-block ,180.95,16.69,3290,5731,0.14,1.5,2,primordial ,solid
74,W ,Tungsten ,Wolfram,"Swedish tung sten, 'heavy stone'
 ·  Symbol W is from Wolfram, originally from Middle High German wolf-rahm 'wolf's foam' describing the mineral wolframite",6,6,d-block ,183.84,19.25,3695,5828,0.132,2.36,1.3,primordial ,solid
75,Re ,Rhenium ,Renium,"Latin Rhenus, 'the Rhine' ",7,6,d-block ,186.21,21.02,3459,5869,0.137,1.9,0.0007,primordial ,solid
76,Os ,Osmium ,Osmium,"Greek osmḗ, 'smell' ",8,6,d-block ,190.23,22.59,3306,5285,0.13,2.2,0.002,primordial ,solid
77,Ir ,Iridium ,Iridium,"Iris, the Greek goddess of the rainbow ",9,6,d-block ,192.22,22.56,2719,4701,0.131,2.2,0.001,primordial ,solid
78,Pt ,Platinum ,Platinum,"Spanish platina, 'little silver', from plata 'silver' ",10,6,d-block ,195.08,21.45,2041.4,4098,0.133,2.28,0.005,primordial ,solid
79,Au ,Gold ,Emas,"English word, from the same root as 'yellow'
 ·  Symbol Au is derived from Latin aurum ",11,6,d-block ,196.97,19.3,1337.33,3129,0.129,2.54,0.004,primordial ,solid
80,Hg ,Mercury ,Raksa,"Mercury, Roman god of commerce, communication, and luck, known for his speed and mobility
 ·  Symbol Hg is derived from its Latin name hydrargyrum, from Greek hydrárgyros, 'water-silver' ",12,6,d-block ,200.59,13.534,234.43,629.88,0.14,2,0.085,primordial ,liquid
81,Tl ,Thallium ,Talium,"Greek thallós, 'green shoot or twig' ",13,6,p-block ,204.38,11.85,577,1746,0.129,1.62,0.85,primordial ,solid
82,Pb ,Lead ,Timbal,"English word, from Proto-Celtic *ɸloudom, from a root meaning 'flow'
 ·  Symbol Pb is derived from Latin plumbum ",14,6,p-block ,207.2,11.34,600.61,2022,0.129,"1.87 (2+)
2.33 (4+) ",14,primordial ,solid
83,Bi ,Bismuth ,Bismut,"German Wismut, from weiß Masse 'white mass', unless from Arabic ",15,6,p-block ,208.98,9.78,544.7,1837,0.122,2.02,0.009,primordial ,solid
84,Po ,Polonium ,Polonium,"Latin Polonia, 'Poland', home country of Marie Curie ",16,6,p-block ,[209],9.196,527,1235,– ,2,2E-10,from decay ,solid
85,At ,Astatine ,Astatin,"Greek ástatos, 'unstable' ",17,6,p-block ,[210] ,(8.91–8.95) ,575,610,– ,2.2,3E-20,from decay ,unknown phase
86,Rn ,Radon ,Radon,"Radium emanation, originally the name of the isotope Radon-222 ",18,6,p-block ,[222] ,0.00973,202,211.3,0.094,2.2,4E-13,from decay ,gas
87,Fr ,Francium ,Fransium,"France, home country of discoverer Marguerite Perey ",1,7,s-block ,[223] ,(2.48) ,281,890,– ,>0.79,1E-18,from decay ,unknown phase
88,Ra ,Radium ,Radium,"French radium, from Latin radius, 'ray' ",2,7,s-block ,[226] ,5.5,973,2010,0.094,0.9,0.0000009,from decay ,solid
89,Ac ,Actinium ,Aktinium,"Greek aktís, 'ray' ",f-block groups ,7,f-block ,[227] ,10,1323,3471,0.12,1.1,5.5E-10,from decay ,solid
90,Th ,Thorium ,Torium,"Thor, the Scandinavian god of thunder ",f-block groups ,7,f-block ,232.04,11.7,2115,5061,0.113,1.3,9.6,primordial ,solid
91,Pa ,Protactinium ,Protaktinium,"Proto- (from Greek prôtos, 'first, before') + actinium, since actinium is produced through the radioactive decay of protactinium ",f-block groups ,7,f-block ,231.04,15.37,1841,4300,– ,1.5,0.0000014,from decay ,solid
92,U ,Uranium ,Uranium,"Uranus, the seventh planet in the Solar System ",f-block groups ,7,f-block ,238.03,19.1,1405.3,4404,0.116,1.38,2.7,primordial ,solid
93,Np ,Neptunium ,Neptunium,"Neptune, the eighth planet in the Solar System ",f-block groups ,7,f-block ,[237] ,20.45,917,4273,– ,1.36,3E-12,from decay ,solid
94,Pu ,Plutonium ,Plutonium,"Pluto, a dwarf planet, considered a planet in the Solar System at the time ",f-block groups ,7,f-block ,[244] ,19.85,912.5,3501,– ,1.28,3E-11,from decay ,solid
95,Am ,Americium ,Amerisium,"The Americas, where the element was first synthesised, by analogy with its homologue § europium ",f-block groups ,7,f-block ,[243] ,12,1449,2880,– ,1.13,– ,synthetic ,solid
96,Cm ,Curium ,Kurium,"Pierre Curie and Marie Curie, French physicists and chemists ",f-block groups ,7,f-block ,[247] ,13.51,1613,3383,– ,1.28,– ,synthetic ,solid
97,Bk ,Berkelium ,Berkelium,"Berkeley, California, where the element was first synthesised ",f-block groups ,7,f-block ,[247] ,14.78,1259,2900,– ,1.3,– ,synthetic ,solid
98,Cf ,Californium ,Kalifornium,"California, where the element was first synthesised in the LBNL laboratory ",f-block groups ,7,f-block ,[251] ,15.1,1173,-1743,– ,1.3,– ,synthetic ,solid
99,Es ,Einsteinium ,Einsteinium,"Albert Einstein, German physicist ",f-block groups ,7,f-block ,[252] ,8.84,1133,(1269) ,– ,1.3,– ,synthetic ,solid
100,Fm ,Fermium ,Fermium,"Enrico Fermi, Italian physicist ",f-block groups ,7,f-block ,[257] ,-9.7,"(1125)
(1800)",– ,– ,1.3,– ,synthetic ,unknown phase
101,Md ,Mendelevium ,Mendelevium,"Dmitri Mendeleev, Russian chemist who proposed the periodic table ",f-block groups ,7,f-block ,[258] ,(10.3) ,(1100) ,– ,– ,1.3,– ,synthetic ,unknown phase
102,No ,Nobelium ,Nobelium,"Alfred Nobel, Swedish chemist and engineer ",f-block groups ,7,f-block ,[259] ,(9.9) ,(1100) ,– ,– ,1.3,– ,synthetic ,unknown phase
103,Lr ,Lawrencium ,Lawrensium,"Ernest Lawrence, American physicist ",3,7,d-block ,[266] ,(14.4) ,(1900) ,– ,– ,1.3,– ,synthetic ,unknown phase
104,Rf ,Rutherfordium ,Ruterfordium,"Ernest Rutherford, chemist and physicist from New Zealand ",4,7,d-block ,[267] ,(17) ,(2400) ,(5800) ,– ,– ,– ,synthetic ,unknown phase
105,Db ,Dubnium ,Dubnium,"Dubna, Russia, where the element was discovered in the JINR laboratory ",5,7,d-block ,[268] ,(21.6) ,– ,– ,– ,– ,– ,synthetic ,unknown phase
106,Sg ,Seaborgium ,Seaborgium,"Glenn T. Seaborg, American chemist ",6,7,d-block ,[269] ,(23–24) ,– ,– ,– ,– ,– ,synthetic ,unknown phase
107,Bh ,Bohrium ,Bohrium,"Niels Bohr, Danish physicist ",7,7,d-block ,[270] ,(26–27) ,– ,– ,– ,– ,– ,synthetic ,unknown phase
108,Hs ,Hassium ,Hasium,"New Latin Hassia, 'Hesse', a state in Germany ",8,7,d-block ,[269] ,(27–29) ,– ,– ,– ,– ,– ,synthetic ,unknown phase
109,Mt ,Meitnerium ,Meitnerium,"Lise Meitner, Austrian physicist ",9,7,d-block ,[278] ,(27–28) ,– ,– ,– ,– ,– ,synthetic ,unknown phase
110,Ds ,Darmstadtium ,Darmstadtium,"Darmstadt, Germany, where the element was first synthesised in the GSI laboratories ",10,7,d-block ,[281] ,(26–27) ,– ,– ,– ,– ,– ,synthetic ,unknown phase
111,Rg ,Roentgenium ,Roentgenium,"Wilhelm Conrad Röntgen, German physicist ",11,7,d-block ,[282] ,(22–24) ,– ,– ,– ,– ,– ,synthetic ,unknown phase
112,Cn ,Copernicium ,Kopernisium,"Nicolaus Copernicus, Polish astronomer ",12,7,d-block ,[285] ,(14.0) ,(283±11) ,(340±10),– ,– ,– ,synthetic ,unknown phase
113,Nh ,Nihonium ,Nihonium,"Japanese Nihon, 'Japan', where the element was first synthesised in the Riken laboratories ",13,7,p-block ,[286] ,(16) ,(700) ,(1400) ,– ,– ,– ,synthetic ,unknown phase
114,Fl ,Flerovium ,Flerovium,"Flerov Laboratory of Nuclear Reactions, part of JINR, where the element was synthesised; itself named after Georgy Flyorov, Russian physicist ",14,7,p-block ,[289] ,(11.4±0.3) ,(284±50),– ,– ,– ,– ,synthetic ,unknown phase
115,Mc ,Moscovium ,Moskovium,"Moscow, Russia, where the element was first synthesised in the JINR laboratories ",15,7,p-block ,[290] ,(13.5) ,(700) ,(1400) ,– ,– ,– ,synthetic ,unknown phase
116,Lv ,Livermorium ,Livermorium,"Lawrence Livermore National Laboratory in Livermore, California ",16,7,p-block ,[293] ,(12.9) ,(700) ,(1100) ,– ,– ,– ,synthetic ,unknown phase
117,Ts ,Tennessine ,Tenesin,"Tennessee, United States, where Oak Ridge National Laboratory is located ",17,7,p-block ,[294] ,(7.1–7.3) ,(700) ,(883) ,– ,– ,– ,synthetic ,unknown phase
118,Og ,Oganesson ,Organeson,"Yuri Oganessian, Russian physicist ",18,7,p-block ,[294] ,(7) ,(325±15) ,(450±10) ,– ,– ,– ,synthetic ,unknown phase
