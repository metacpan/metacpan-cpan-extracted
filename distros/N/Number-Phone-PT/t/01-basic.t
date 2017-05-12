# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 206;
BEGIN { use_ok('Number::Phone::PT') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(is_valid('219523042'),1);
is(is_valid('222006636'),1);
is(is_valid('223399415'),1);
is(is_valid('229387507'),1);
is(is_valid('234378755'),1);
is(is_valid('234403303'),1);
is(is_valid('234424910'),1);
is(is_valid('234428704'),1);
is(is_valid('234550843'),1);
is(is_valid('251565010'),1);
is(is_valid('251795925'),1);
is(is_valid('252681496'),1);
is(is_valid('253266237'),1);
is(is_valid('253278162'),1);
is(is_valid('253279426'),1);
is(is_valid('253285409'),1);
is(is_valid('253312870'),1);
is(is_valid('253425080'),1);
is(is_valid('253604981'),1);
is(is_valid('253605258'),1);
is(is_valid('253605282'),1);
is(is_valid('253617125'),1);
is(is_valid('253674956'),1);
is(is_valid('253678382'),1);
is(is_valid('253679358'),1);
is(is_valid('253880967'),1);
is(is_valid('256281510'),1);
is(is_valid('258321896'),1);
is(is_valid('258322189'),1);
is(is_valid('258322968'),1);
is(is_valid('258323198'),1);
is(is_valid('258331637'),1);
is(is_valid('258802062'),1);
is(is_valid('258808875'),1);
is(is_valid('258808879'),1);
is(is_valid('258808881'),1);
is(is_valid('258809695'),1);
is(is_valid('258811116'),1);
is(is_valid('258811404'),1);
is(is_valid('258821856'),1);
is(is_valid('258821859'),1);
is(is_valid('258822428'),1);
is(is_valid('258823879'),1);
is(is_valid('258824210'),1);
is(is_valid('258825248'),1);
is(is_valid('258827119'),1);
is(is_valid('258827143'),1);
is(is_valid('258827668'),1);
is(is_valid('258828822'),1);
is(is_valid('258829871'),1);
is(is_valid('258833146'),1);
is(is_valid('258836553'),1);
is(is_valid('258842458'),1);
is(is_valid('258842824'),1);
is(is_valid('258843368'),1);
is(is_valid('258843572'),1);
is(is_valid('258843865'),1);
is(is_valid('258843891'),1);
is(is_valid('258843971'),1);
is(is_valid('296639274'),1);

is(is_valid('914677482'),1);
is(is_valid('914705102'),1);
is(is_valid('916405649'),1);
is(is_valid('916490404'),1);
is(is_valid('916525407'),1);
is(is_valid('916689520'),1);
is(is_valid('916733305'),1);
is(is_valid('917042704'),1);
is(is_valid('917097477'),1);
is(is_valid('917414221'),1);
is(is_valid('917414232'),1);
is(is_valid('918234258'),1);
is(is_valid('918579327'),1);
is(is_valid('918652617'),1);
is(is_valid('919195276'),1);
is(is_valid('919255790'),1);
is(is_valid('919600459'),1);
is(is_valid('919640822'),1);
is(is_valid('919749482'),1);
is(is_valid('919896618'),1);

is(is_valid('933256668'),1);
is(is_valid('933306238'),1);
is(is_valid('933311645'),1);
is(is_valid('933324706'),1);
is(is_valid('933394648'),1);
is(is_valid('933465337'),1);
is(is_valid('933567185'),1);
is(is_valid('933749909'),1);
is(is_valid('934203304'),1);
is(is_valid('934208834'),1);
is(is_valid('934265690'),1);
is(is_valid('934904840'),1);
is(is_valid('934906487'),1);
is(is_valid('936253283'),1);
is(is_valid('936264649'),1);
is(is_valid('936327932'),1);
is(is_valid('936567901'),1);
is(is_valid('936941615'),1);
is(is_valid('937021678'),1);
is(is_valid('938075232'),1);
is(is_valid('938100403'),1);
is(is_valid('938319086'),1);
is(is_valid('938337209'),1);
is(is_valid('938342070'),1);
is(is_valid('938430343'),1);
is(is_valid('938432334'),1);
is(is_valid('938689432'),1);
is(is_valid('939303087'),1);
is(is_valid('939425693'),1);

is(is_valid('962357605'),1);
is(is_valid('962359477'),1);
is(is_valid('962429800'),1);
is(is_valid('962453422'),1);
is(is_valid('962550047'),1);
is(is_valid('962581555'),1);
is(is_valid('962652387'),1);
is(is_valid('962715627'),1);
is(is_valid('962899157'),1);
is(is_valid('962921257'),1);
is(is_valid('962951938'),1);
is(is_valid('963003246'),1);
is(is_valid('963026796'),1);
is(is_valid('963045275'),1);
is(is_valid('963080656'),1);
is(is_valid('963117393'),1);
is(is_valid('963209089'),1);
is(is_valid('963410711'),1);
is(is_valid('963450700'),1);
is(is_valid('963519249'),1);
is(is_valid('963570895'),1);
is(is_valid('963755159'),1);
is(is_valid('963813794'),1);
is(is_valid('964140319'),1);
is(is_valid('964208026'),1);
is(is_valid('964333222'),1);
is(is_valid('964366193'),1);
is(is_valid('964404449'),1);
is(is_valid('964438336'),1);
is(is_valid('964476001'),1);
is(is_valid('964774174'),1);
is(is_valid('964848798'),1);
is(is_valid('965088226'),1);
is(is_valid('965089186'),1);
is(is_valid('965102000'),1);
is(is_valid('965184013'),1);
is(is_valid('965236598'),1);
is(is_valid('965237214'),1);
is(is_valid('965278586'),1);
is(is_valid('965294608'),1);
is(is_valid('965559298'),1);
is(is_valid('965653715'),1);
is(is_valid('965666079'),1);
is(is_valid('965671345'),1);
is(is_valid('965790238'),1);
is(is_valid('965801144'),1);
is(is_valid('965803707'),1);
is(is_valid('965909647'),1);
is(is_valid('966183037'),1);
is(is_valid('966184308'),1);
is(is_valid('966186777'),1);
is(is_valid('966205430'),1);
is(is_valid('966483612'),1);
is(is_valid('966511148'),1);
is(is_valid('966516544'),1);
is(is_valid('966525610'),1);
is(is_valid('966568618'),1);
is(is_valid('966606736'),1);
is(is_valid('966654732'),1);
is(is_valid('966796786'),1);
is(is_valid('966908173'),1);
is(is_valid('966952025'),1);
is(is_valid('966954981'),1);
is(is_valid('967052840'),1);
is(is_valid('967090316'),1);
is(is_valid('967102613'),1);
is(is_valid('967633719'),1);
is(is_valid('968204787'),1);
is(is_valid('968333799'),1);
is(is_valid('968352493'),1);
is(is_valid('968413336'),1);
is(is_valid('968416362'),1);
is(is_valid('968432652'),1);
is(is_valid('968590769'),1);
is(is_valid('968712029'),1);
is(is_valid('969315892'),1);
is(is_valid('969615084'),1);
is(is_valid('969658403'),1);
is(is_valid('969697633'),1);

is(is_valid('39348970'),0);
is(is_valid('209663007'),0);
is(is_valid('7'),0);

is(is_residential(223453456),1);
is(is_residential(213423442),1);

is(is_residential(933453456),0);
is(is_residential(707423442),0);

is(is_mobile(918574912),1);
is(is_mobile(968514926),1);

is(is_mobile(245928375),0);
is(is_mobile(800348375),0);

is(is_personal(219287789),1);
is(is_personal(962738909),1);

is(is_personal(234),0);
is(is_personal(800898987),0);

is(area_of(217898987),'lisboa');
is(area_of(258283948),'viana do castelo');
