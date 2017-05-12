use Test::More;
use IO::All;
use File::Temp 'tempfile';
use Data::Dumper;

use_ok('Parse::SAMGov');

my $p = new_ok('Parse::SAMGov');
can_ok($p, 'parse_file');

subtest 'Parse Entity file' => sub {
    my $content = <<'ENTITY';
BOF PUBLIC 20160720 20160720 0003864 0005497
039205559||1XPC6|DODFA4877|3|Z5|20140224|20170719|20160719|20160719|AIR FORCE, UNITED STATES DEPARTMENT OF THE|355 FORCE SUPPORT SQUADRON|||5260 E GRANITE ST||TUCSON|AZ|85707|3009|USA|02|20041001|0930||2A|||0003|2R~NG~VW|321999|0001|321999N|0001|AC94|N||3515 SOUTH 5TH STREET||TUCSON|85707||USA|AZ|LISA||CHAMBERLAIN||355 FSS/FSR|3515 S FIFTH STREET|TUCSON|85707||USA|AZ|5202280500||||lisa.chamberlain@us.af.mil|||||||||||||||||||||||||||||||||||||||||||||||||LISA||CHAMBERLAIN||355 FSS/FSR|3515 S FIFTH STREET|TUCSON|85707||USA|AZ|5202280500||||lisa.chamberlain@us.af.mil|||||||||||||||||0000||N||0000||NPDY|0000||!end
016572013||0U345|DODW905MW|4|Z5||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||!end
128900441||1PPW0|DODW90F7Z|3|Z2|20130730|20170719|20160719|20160719|ARMY, UNITED STATES DEPARTMENT OF THE|INSTALLATION MORALE WELFARE|||600 THOMAS AVE UNIT 2||FORT LEAVENWORTH|KS|66027|1417|USA|02|20031001|0930||2A|||0003|2R~NG~VW|722513|0001|722513N|0000||||600 THOMAS AVE UNIT 2||FORT LEAVENWORTH|66027|1417|USA|KS|LORI||FOSKETT||PO BOX 3430||FORT LEAVENWORTH|66027||USA|KS|9136841839|||9136841831|lori.j.foskett.naf@us.army.mil|||||||||||||||||||||||||||||||||||||||||||||||||LORI||FOSKETT||PO BOX 3430||FORT LEAVENWORTH|66027||USA|KS|9136841839|||9136841831|lori.j.foskett.naf@us.army.mil|||||||||||||||||0000||N||0000|||0000||!end
001006360||96217||3|Z2|20090416|20161115|20160718|20151117|HOLLINGSWORTH & VOSE COMPANY||||112 WASHINGTON ST||EAST WALPOLE|MA|02032|1008|USA|08|18920606|1231||2L|MA|USA|0003|2X~MF~VW|322121|0001|322121N|0000||Y||112 WASHINGTON STREET||EAST WALPOLE|02032|1008|USA|MA|ANGELIKA||MAYMAN||112 WASHINGTON STREET||EAST WALPOLE|02032|1008|USA|MA|5088502205|||5086683557|angelika.mayman@hovo.com|NICOLAS||STARITA||112 WASHINGTON STREET||EAST WALPOLE|02032|1008|USA|MA|5088502000|||5086602168|Nick.Starita@hovo.com|||||||||||||||||||||||||||||||||JOHN||ETZEL||112 WASHINGTON STREET||EAST WALPOLE|02032|1008|USA|MA|5088502000|||5086686526|John.Etzel@hovo.com|TAMAH||VEST||112 WASHINGTON STREET||EAST WALPOLE|02032||USA|MA|5088502146|||5086686526|Tamah.Vest@hovo.com|0000||N||0000|||0000||!end
001022961||03249||3|Z2|20010611|20170719|20160719|20160719|B. C. AMES INCORPORATED||||1644 CONCORD ST||FRAMINGHAM|MA|01701||USA|03|20010726|1231||2L|MA|USA|0003|2X~MF~VW|332216|0001|332216Y|0000||Y||1644 CONCORD STREET||FRAMINGHAM|01701|3531|USA|MA|FRANCIS||GARDNER|PRESIDENT|1644 CONCORD STREET||FRAMINGHAM|01701||USA|MA|7818930095|||7816473356|info@bcames.com|FRANCIS||GARDNER|PRESIDENT|1644 CONCORD STREET||FRAMINGHAM|01701||USA|MA|7818930095|||7816473356|info@bcames.com|FRANCIS||GARDNER|PRESIDENT|1644 CONCORD STREET||FRAMINGHAM|01701||USA|MA|7818930095|||7816473356|info@bcames.com|FRANCIS||GARDNER|PRESIDENT|1644 CONCORD STREET||FRAMINGHAM|01701||USA|MA|7818930095|||7816473356|info@bcames.com|FRANCIS||GARDNER|PRESIDENT|1644 CONCORD STREET||FRAMINGHAM|01701||USA|MA|7818930095|||7816473356|info@bcames.com|FRANCIS||GARDNER|PRESIDENT|1644 CONCORD STREET||FRAMINGHAM|01701||USA|MA|7818930095|||7816473356|info@bcames.com|0000||N||0000|||0000||!end
832866987||4ABM1||A|Z2|20091209|20161103|20151101|20151101|ABC EXAMPLE LLC||||789 WASHINGTON AVENUE||BORINGTOWN|NY|11211|1111|USA|06|20090418|1231|http://example.com|2L|NY|USA|0005|23~2X~LJ~QZ~VW|541519|0004|541511Y~541512Y~541519E~541712E|0000||A||789 WASHINGTON AVENUE||BORINGTOWN|11211|1111|USA|NY|JAMES|A|ELIOT|CEO|789 WASHINGTON AVENUE||BORINGTOWN|11211|1111|USA|NY|8882345678|||8882345678|abc@exampleintellect.com|JAMES|A|ELIOT|CEO|789 WASHINGTON AVENUE||BORINGTOWN|11211|1111|USA|NY|8882345678|||8882345678|abc@exampleintellect.com|JAMES|A|ELIOT|CEO|789 WASHINGTON AVENUE||BORINGTOWN|11211|1111|USA|NY|8882345678|||8882345678|abc@exampleintellect.com|JAMES|A|ELIOT|CEO|789 WASHINGTON AVENUE||BORINGTOWN|11211|1111|USA|NY|8882345678|||8882345678|abc@exampleintellect.com|JAMES|A|ELIOT|CEO|789 WASHINGTON AVENUE||BORINGTOWN|11211|1111|USA|NY|8882345678|||8882345678|abc@exampleintellect.com|JAMES|A|ELIOT|CEO|789 WASHINGTON AVENUE||BORINGTOWN|11211|1111|USA|NY|8882345678|||8882345678|abc@exampleintellect.com|0002|541519YY ~541712YYYY|A||0000||NPDY|0000||!end
EOF PUBLIC 20160720 20160720 0003864 0005497
ENTITY
    my ($ftmp, $filename) = tempfile();
    $content > io($filename);
    my $entities = $p->parse_file($filename);
    isnt($entities, undef, 'Entities were parsed');
    isa_ok($entities, 'ARRAY');
    cmp_ok(scalar(@$entities), '>', 0, 'Parsed entities >= 1');
    foreach my $e (@$entities) {
        isa_ok($e, 'Parse::SAMGov::Entity');
        note $e;
    }
    my $entity_541511 = $p->parse_file($filename, sub {
            return 1 if $_[0]->NAICS->{541511};
            return undef;
        });
    isa_ok($entity_541511, 'ARRAY');
    is(scalar(@$entity_541511), 1, 'Result has 1 element');
    is(ref $entity_541511->[0]->NAICS->{541511}, 'HASH');
    unlink $filename;
    done_testing();
};

subtest 'Parse Exclusion File' => sub {
    my $content = << 'EXCLUSION';
"Classification","Name","Prefix","First","Middle","Last","Suffix","Address 1","Address 2","Address 3","Address 4","City","State / Province","Country","Zip Code","DUNS","Exclusion Program","Excluding Agency","CT Code","Exclusion Type","Additional Comments","Active Date","Termination Date","Record Status","Cross-Reference","SAM Number","CAGE","NPI"
"Individual","","","DAVID","M.","FINK","","","","","","METUCHEN","NJ","USA","08840","","Reciprocal","HHS","Z1","Prohibition/Restriction","Excluded by the Department of Health and Human Services from participation in all Federal health care programs pursuant to 42 U.S.C. ? 1320a-7 or other sections of the Social Security Act, as amended and codified in Chapter 7 of Title 42 of the United States Code (the scope and effect of Federal health care program exclusions is described in 42 C.F.R. ? 1001.1901).","05/20/2003","Indefinite","","","S4MR3MT0K","",""
"Individual","","","DAVID","M.","FINK","","","","","","METUCHEN","NJ","USA","08840","","Reciprocal","OPM","Z2","Prohibition/Restriction","","05/12/2005","Indefinite","","","S4MR3MT0K","",""
"Individual","","","DAVID","B.","FINZI","","","","","","MIAMI","FL","USA","331303038","","Reciprocal","HUD","R","Ineligible (Proceedings Completed)","","07/30/2007","Indefinite","","","S4MR3R0D2","",""
"Individual","","","DAVID","MICHAEL","FISHER","","","","","","SHAMOKIN","PA","USA","17872","","Reciprocal","HHS","Z1","Prohibition/Restriction","Excluded by the Department of Health and Human Services from participation in all Federal health care programs pursuant to 42 U.S.C. ? 1320a-7 or other sections of the Social Security Act, as amended and codified in Chapter 7 of Title 42 of the United States Code (the scope and effect of Federal health care program exclusions is described in 42 C.F.R. ? 1001.1901).","02/20/2001","Indefinite","","","S4MR3QK9Q","",""
EXCLUSION
    my ($ftmp, $filename) = tempfile();
    $content > io($filename);
    my $exclusions = $p->parse_file($filename);
    isnt($exclusions, undef, 'Exclusions were parsed');
    isa_ok($exclusions, 'ARRAY');
    cmp_ok(scalar(@$exclusions), '>', 0, 'Parsed exclusions >= 1');
    foreach my $e (@$exclusions) {
        isa_ok($e, 'Parse::SAMGov::Exclusion');
        note $e;
    }
    unlink $filename;
    done_testing();
};

done_testing();
__END__
### COPYRIGHT: Selective Intellect LLC.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
