# -*- perl -*-

# t/03_utils.t

use Test::Most tests => 4+1;
use Test::NoWarnings;

use MooseX::App::Utils;
use MooseX::App::ParsedArgv;

subtest 'Class to command' => sub {
    is(MooseX::App::Utils::class_to_command('Command'),'command','Command ok');
    is(MooseX::App::Utils::class_to_command('CommandSuper'),'command_super','Command ok');
    is(MooseX::App::Utils::class_to_command('CommandBA'),'command_ba','Command ok');
    is(MooseX::App::Utils::class_to_command('CommandBA12'),'command_ba12','Command ok');
    is(MooseX::App::Utils::class_to_command('CommandBALow'),'command_ba_low','Command ok');
};

subtest 'Format text' => sub {
    is(
        MooseX::App::Utils::format_text('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vitae lectus purus, quis dapibus orci. Proin mollis est in nisl congue vel ornare felis imperdiet.'),
'    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vitae
    lectus purus, quis dapibus orci. Proin mollis est in nisl congue vel
    ornare felis imperdiet.',
        'Format text ok');
    is(
        MooseX::App::Utils::format_text('Loremipsumdolorsitamet,consecteturadipiscingelit.Namegetarcunecdolorbibendumblanditsitametnonipsum.'),
'    Loremipsumdolorsitamet,consecteturadipiscingelit.
    Namegetarcunecdolorbibendumblanditsitametnonipsum.',
        'Format text ok');
    is(
        MooseX::App::Utils::format_text('LoremipsumdolorsitametconsecteturadipiscingelitNamegetarcunecdolorbibendumblanditsitametnonipsum.'),
'    LoremipsumdolorsitametconsecteturadipiscingelitNamegetarcunecdolorbibendum
    blanditsitametnonipsum.',
        'Format text ok');
};

subtest 'Formater' => sub {

    my $list = MooseX::App::Utils::format_list(
        ['part1','Lorem ipsum dolor sit amet, consectetur adipiscing elit. vitae lectus purus, quis dapibus orci.'],
        ['part2_something','Lorem ipsum dolor sit amet, consectetur adipiscing elit.'],
        ['part3',''],
    );

    is(
        $list,
'    part1            Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                     vitae lectus purus, quis dapibus orci.
    part2_something  Lorem ipsum dolor sit amet, consectetur adipiscing elit.
    part3            ',
        'Format list ok'
    );
};

subtest 'Parser' => sub {
    my $parser = MooseX::App::ParsedArgv->new({
        argv            => ['hello','--bool','mellow','-hui','--help','--help','--test','1','baer','--test','2','--xxx','x1','x2','--key=value1','--key=value2','-u','--','hase','--luchs'],
        hints_novalue   => ['bool'],
        hints_permute   => ['xxx'],
    });

    is(scalar(@{$parser->elements}),13,'Has 13 elements');
    is($parser->elements->[0]->key,'hello','Parameter parsed ok');
    is($parser->elements->[0]->type,'parameter','Parameter type ok');
    is($parser->elements->[1]->key,'bool','Flag parsed ok');
    is($parser->elements->[1]->type,'option','Flag type ok');
    is($parser->elements->[2]->key,'mellow','Parameter parsed ok');
    is($parser->elements->[3]->key,'h','Flag parsed ok');
    is($parser->elements->[4]->key,'u','Flag parsed ok');
    is($parser->elements->[5]->key,'i','Flag parsed ok');
    is($parser->elements->[6]->key,'help','Flag parsed ok');
    is($parser->elements->[7]->key,'test','Option parsed ok');
    cmp_deeply([$parser->elements->[7]->all_scalar_values],[1,2], 'Option value ok');
    is($parser->elements->[8]->key,'baer','Parameter parsed ok');
    is($parser->elements->[9]->key,'xxx','Parameter parsed ok');
    cmp_deeply([$parser->elements->[9]->all_scalar_values],['x1','x2'],'Option value ok');
    is($parser->elements->[10]->key,'key','Option parsed ok');
    is($parser->elements->[10]->key,'key','Extra parsed ok');
    cmp_deeply([$parser->elements->[10]->all_scalar_values],['value1','value2'],'Option value ok');
    is($parser->elements->[11]->key,'hase','Extra parsed ok');
    is($parser->elements->[12]->key,'--luchs','Extra parsed ok');
};
