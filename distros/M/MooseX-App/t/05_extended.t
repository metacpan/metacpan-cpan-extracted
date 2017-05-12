# -*- perl -*-

# t/05_extended.t - Extended tests

use Test::Most tests => 29+1;
use Test::NoWarnings;

use FindBin qw();
use lib 't/testlib';

use Test03;

Test03->meta->app_fuzzy(0);
Test03->meta->app_strict(1);

subtest 'Non-Fuzzy command matching' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(some --private 1)]);
    my $test01 = Test03->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    is($test01->blocks->[0]->header,"Unknown command 'some'","Message ok");
};

subtest 'Non-Fuzzy attribute matching' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(somecommand --private 1)]);
    my $test01 = Test03->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    is($test01->blocks->[0]->header,"Unknown option 'private'","Message ok");
};

Test03->meta->app_fuzzy(1);

subtest 'Private option is not exposed' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(some --private 1)]);
    my $test01 = Test03->new_with_command;
    isa_ok($test01,'MooseX::App::Message::Envelope');
    is($test01->blocks->[0]->header,"Unknown option 'private'","Message ok");
    is($test01->blocks->[0]->type,"error",'Message is of type error');
};

subtest 'Options from role' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(some --another 10 --role 15)]);
    my $test02 = Test03->new_with_command;
    isa_ok($test02,'Test03::SomeCommand');
    is($test02->another_option,'10','Param is set');
    is($test02->roleattr,'15','Role param is set');
};

subtest 'Missing attribute value' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(some --another)]);
    my $test03 = Test03->new_with_command;
    isa_ok($test03,'MooseX::App::Message::Envelope');
    is($test03->blocks->[0]->header,"Missing value for 'another'","Message ok");
    is($test03->blocks->[0]->type,"error",'Message is of type error');
};

subtest 'All options available & no description' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(some --help)]);
    my $test04 = Test03->new_with_command;
    isa_ok($test04,'MooseX::App::Message::Envelope');
    is($test04->blocks->[2]->header,'options:','No description');
    is($test04->blocks->[2]->body,"    --global_option       Enable this to do fancy stuff [Flag]
    --roleattr            [Role]
    --some_option         Very important option!
    --another             [Required; Not important]
    --list                [Multiple]
    --help -h --usage -?  Prints this usage information. [Flag]","Message ok");
};

# Not working on cpan testers
#subtest 'Test wrapper script encoding' => sub {
#    my $output = `LANG=en_US.UTF-8 $^X $FindBin::Bin/example/test03.pl some_command --another töst\\ möre --some_option "anöther täst"`;
#    is($output,'RUN:anöther täst:töst möre','Encoded output');
#}

subtest 'Test type constraints integer' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(another --int 1a)]);
    my $test05 = Test03->new_with_command;
    isa_ok($test05,'MooseX::App::Message::Envelope');
    is($test05->blocks->[0]->header,"Invalid value for 'integer'","Message ok");
};

subtest 'Test type constraints hash' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(another --hash xx)]);
    my $test06 = Test03->new_with_command;
    isa_ok($test06,'MooseX::App::Message::Envelope');
    is($test06->blocks->[0]->header,"Invalid value for 'hash'","Message ok");
};

subtest 'Test type constraints number' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(another --number 2a)]);
    my $test07 = Test03->new_with_command;
    isa_ok($test07,'MooseX::App::Message::Envelope');
    is($test07->blocks->[0]->header,"Invalid value for 'number'","Message ok");
};

subtest 'Test type constraints custom1' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(another --custom1 9)]);
    my $test08 = Test03->new_with_command;
    isa_ok($test08,'MooseX::App::Message::Envelope');
    is($test08->blocks->[0]->header,"Invalid value for 'custom1'","Message ok");
};

subtest 'Test pass type constraints' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(another --hash key1=value1 --split a;b --split c --hash key2=value2 --integer 10 --number 10.10 --custom1 11 --custom2 test --extra1 wurtsch --count --count --cou)]);
    my $test09 = Test03->new_with_command;
    isa_ok($test09,'Test03::AnotherCommand');
    is($test09->hash->{key1},"value1","Hash ok");
    is($test09->hash->{key2},"value2","Hash ok");
    is($test09->integer,10,"Integer ok");
    is($test09->custom1,11,"Custom type 1 ok");
    is(ref($test09->custom2),'SCALAR',"Custom type 2 ok");
    is(${$test09->custom2},'test',"Custom type 2 ok");
    is($test09->extra1,'wurtsch',"Attr set ok");
    is($test09->count,3,"Count set ok");
    cmp_deeply($test09->split,[qw(a b c)],'Split ok');
};

subtest 'Test ambiguous options' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(another --custom 1 --custom 2)]);
    my $test10 = Test03->new_with_command;
    isa_ok($test10,'MooseX::App::Message::Envelope');
    is($test10->blocks->[0]->header,"Ambiguous option 'custom'","Message ok");
    like($test10->blocks->[0]->body,qr/Could be
    custom1  
    custom2/,"Message ok");
};

subtest 'Test flags & defaults' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(yet --bool3)]);
    my $test11 = Test03->new_with_command;
    isa_ok($test11,'Test03::YetAnotherCommand');
    is($test11->bool1,undef,'Bool1 flag is undef');
    is($test11->bool2,1,'Bool2 flag is set');
    is($test11->bool3,1,'Bool3 flag is set');
    is($test11->value,'hase','Value is default');
};

subtest 'Test more flags & defaults' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(yet --bool3 -ab --value baer)]);
    my $test11 = Test03->new_with_command;
    isa_ok($test11,'Test03::YetAnotherCommand');
    is($test11->bool1,1,'Bool1 flag is undef');
    is($test11->bool2,1,'Bool2 flag is unset');
    is($test11->bool3,1,'Bool3 flag is set');
    is($test11->value,'baer','Value is set');
};

subtest 'Test Negate boolean options' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(yet --no-bool3)]);
    my $test11 = Test03->new_with_command;
    isa_ok($test11,'Test03::YetAnotherCommand');
    is($test11->bool3,0,'Bool3 flag is negated');
};

subtest 'Test positional params' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(extra hui --value baer)]);
    my $test12 = Test03->new_with_command;
    isa_ok($test12,'Test03::ExtraCommand');
    is($test12->extra1,'hui','Extra1 value is "hui"');
    is($test12->extra2, undef,'Extra2 value is undef');
    is($test12->alpha, undef,'alpha value is undef');
    is($test12->value,'baer','Value is set');
};

subtest 'Test positional params' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(extra --value baer hui)]);
    my $test12 = Test03->new_with_command;
    isa_ok($test12,'Test03::ExtraCommand');
    is($test12->extra1,'hui','Extra1 value is "hui"');
    is($test12->extra2, undef,'Extra2 value is undef');
    is($test12->alpha, undef,'alpha value is undef');
    is($test12->value,'baer','Value is set');
};

subtest 'Test optional positional params' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(extra hui 11 --value baer)]);
    my $test12 = Test03->new_with_command;
    isa_ok($test12,'Test03::ExtraCommand');
    is($test12->extra1,'hui','Extra1 value is "hui"');
    is($test12->extra2,11,'Extra2 value is "11"');
    is($test12->alpha, undef,'alpha value is undef');
    is($test12->value,'baer','Value is set');
};

subtest 'Test wrong positional params' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(extra hui aa --value baer)]);
    my $test13 = Test03->new_with_command;
    isa_ok($test13,'MooseX::App::Message::Envelope');
    is($test13->blocks->[0]->header,"Invalid value for 'extra2'","Error message ok");
    is($test13->blocks->[2]->header,"parameters:","Usage header ok");
    is($test13->blocks->[2]->body,"    extra1  Important extra parameter [Required]
    extra2  [Integer]
    alpha   [Integer]","Usage body ok");
};

subtest 'Test missing positional params' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(extra  --value  baer)]);
    my $test14 = Test03->new_with_command;
    isa_ok($test14,'MooseX::App::Message::Envelope');
    is($test14->blocks->[0]->header,"Required parameter 'extra1' missing","Message ok");
};

Test03->meta->app_fuzzy(1);
Test03->meta->app_strict(0);

subtest 'Test extra positional params' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(extra p1 22 33 marder dachs --value 44 --flag luchs --flagg fuchs -- baer --hase)]);
    my $test15 = Test03->new_with_command;
    isa_ok($test15,'Test03::ExtraCommand');
    is($test15->extra1,'p1','Param 1 ok');
    is($test15->extra2,'22','Param 2 ok');
    is($test15->alpha,'33','Param 3 ok');
    cmp_deeply($test15->extra_argv,[qw(marder dachs luchs fuchs baer --hase)],'Uncomsumed option ok');
};

subtest 'Test parameter preference' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(extra extra1 22 --value 13 --flag)]);
    my $test16 = Test03->new_with_command(extra1 => 'extra1man', value => 14, flag => 0, flaggo => 1);
    isa_ok($test16,'Test03::ExtraCommand');
    is($test16->extra1,"extra1man","Extra param from new_with_command ok");
    is($test16->extra2,22,"Extra param from argv ok");
    is($test16->value,14,"value option from argv ok");
    is($test16->flag,0,"Flag from new_with_command ok");
    is($test16->flaggo,1,"Flago from new_with_command ok");
};

Test03->meta->app_prefer_commandline(1);

subtest 'Test parameter preference reverse' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(extra extra1 22  --value 13 --flag)]);
    my $test17 = Test03->new_with_command(extra1 => 'extra1man', value => 14, flag => 0, flaggo => 1);
    isa_ok($test17,'Test03::ExtraCommand');
    is($test17->extra1,"extra1","Extra param from new_with_command ok");
    is($test17->extra2,22,"Extra param from argv ok");
    is($test17->value,13,"value option from argv ok");
    is($test17->flag,1,"Flag from new_with_command ok");
    is($test17->flaggo,1,"Flago from new_with_command ok");
};

subtest 'Test enum error message' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(somecommand --another hase hh h ggg)]);
    my $test18 = Test03->new_with_command();
    isa_ok($test18,'MooseX::App::Message::Envelope');
    is($test18->blocks->[0]->body,"Value must be one of these values: aaa, bbb, ccc, ddd, eee, fff (not 'ggg')","Check enum error message");
};

subtest 'Test empty multi' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(somecommand --another hase --list val1 --list val2 --list)]);
    my $test19 = Test03->new_with_command();
    isa_ok($test19,'Test03::SomeCommand');
    is(scalar(@{$test19->list}),3,'Has three list items');
    is($test19->list->[0],'val1','First value ok');
    is($test19->list->[1],'val2','Second value ok');
    is($test19->list->[2],undef,'First value empty');
};

subtest 'Test permute' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(differentcommand --list elem1 elem2 --list elem3 --int 10 --hash key1=val1 key2=val2)]);
    my $test20 = Test03->new_with_command();
    cmp_deeply($test20->list,[qw(elem1 elem2 elem3)],'Permute array ok');
    cmp_deeply($test20->hash,{ key1 => 'val1', key2 => 'val2' },'Permute hash ok');
};

subtest 'Test permute off' => sub {
    Test03->meta->app_permute(0);
    MooseX::App::ParsedArgv->new(argv => [qw(differentcommand --list elem1 elem2 --list elem3 --int 10 --hash key1=val1 key2=val2)]);
    my $test20 = Test03->new_with_command();
    cmp_deeply($test20->list,[qw(elem1 elem3)],'No permute array ok');
    cmp_deeply($test20->hash,{ key1 => 'val1' },'No permute hash ok');
    Test03->meta->app_permute(1);
};

subtest 'Test parameter order' => sub {
    MooseX::App::ParsedArgv->new(argv => [qw(somecommand cc1  --another dd aa1 bbb)]);
    my $test21 = Test03->new_with_command();
    is($test21->param_a,'aa1','Param a ok');
    is($test21->param_b,'bbb','Param b ok');
    is($test21->param_c,'cc1','Param c ok');
};

subtest 'Test mixed multi' => sub {
    my $x = MooseX::App::ParsedArgv->new(argv => [qw(somecommand --another hase --li val1 --lis val2 --list val3 --lis val4)]);
    my $test22 = Test03->new_with_command();
    isa_ok($test22,'Test03::SomeCommand');
    cmp_deeply($test22->list,[qw(val1 val2 val3 val4)],'List ok');
};