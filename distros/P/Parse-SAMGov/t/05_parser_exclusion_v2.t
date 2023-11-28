use Test::More;
use IO::All;
use File::Temp 'tempfile';
use Data::Dumper;

use_ok('Parse::SAMGov');

my $p = new_ok('Parse::SAMGov');
can_ok($p, 'parse_file');

subtest 'Parse Exclusion File' => sub {
    my $content = << 'EXCLUSION';
"Classification","Name","Prefix","First","Middle","Last","Suffix","Address 1","Address 2","Address 3","Address 4","City","State / Province","Country","Zip Code","Open Data Flag","Blank (Deprecated)","Unique Entity ID","Exclusion Program","Excluding Agency","CT Code","Exclusion Type","Additional Comments","Active Date","Termination Date","Record Status","Cross-Reference","SAM Number","CAGE","NPI","Creation_Date"
"Firm","ZTE CORPORATION","","","","","","NO.55, HI-TECH SOUTH ROAD, NANSHAN DISTRICT","","","","SHENZHEN","","CHN","518057","","","HWEKRJ3F3N29","Reciprocal","GSA","","Prohibition/Restriction","Prohibition is limited to certain products and services. The entity is not itself excluded. See FAR (48 CFR) subpart 4.21, implementing section 889(a)(1)(A) of Public Law 115-232, which restricts purchase of any equipment, system, or services that uses covered telecommunications equipment or services as a substantial or essential component of any system, or as critical technology as part of any system.","12/13/2019","Indefinite","","","S4MRB9MLP","","","2019-12-13"
"Individual","","","ANTONIO","","FLORES","III","","","","","SAN ANTONIO","TX","USA","78258","","","","Reciprocal","","","Ineligible (Proceedings Pending)","","11/20/2023","Indefinite","","(also TERRA KLEAN SOLUTIONS INC.)","S4MRRFG44","","","2023-11-20"
"Individual","","","CARLOS","","PIEXOTTO","","","","","","BROOKLYN","NY","USA","11236","","","","Reciprocal","GSA","","Ineligible (Proceedings Completed)","","11/22/2023","10/19/2026","","","S4MRRFZSX","","","2023-11-22"
"Individual","","","CASSIE","","COLLINS","","","","","","WASHINGTON","DC","USA","20210","","","","Reciprocal","DOL","","Ineligible (Proceedings Completed)","","11/21/2023","11/20/2026","","(also PEANUT BUTTER, LLC)","S4MRRFN2S","","","2023-11-21"
"Individual","","MR.","FRANCISCO","ENRIQUE","BERZUNZA LARA","","","","","","MEXICO CITY","","MEX","04010","","","","Reciprocal","DOS","","Ineligible (Proceedings Completed)","","11/21/2023","09/19/2026","","(also IDRIS NAIM AC)","S4MRRFQ3W","","","2023-11-21"
"Individual","","","MARQUIS","ASAAD","HOOPER","","","","","","NORTH LAS VEGAS","NV","USA","89031","","","","Reciprocal","NAVY","","Ineligible (Proceedings Pending)","Proposed Debarment: 11-20-2023 ","11/20/2023","Indefinite","","","S4MRRFNFM","","","2023-11-21"
"Individual","","","RONALD","WAYNE","TRUITT","","","","","","FAIRMOUNT CITY","PA","USA","16224","","","","Reciprocal","PS","","Ineligible (Proceedings Pending)","","10/27/2023","10/26/2024","","(also TRUITTSBURGH SEALERS CO.)","S4MRRFXX7","","","2023-11-22"
"Individual","","","VICTOR","","MARTINEZ","","","","","","LAUREL","MD","USA","20707","","","","Reciprocal","","","Voluntary Exclusion","The contractor agreed to be debarred to settle government charges that the contractor violated the Davis-Bacon Act, 40 USC 3141-3148.  The contractor, or any firm, corporation, partnership, or association in which the contractor has an interest, is ineligible to receive any contract or subcontract of the United States or the District of Columbia and any contract or subcontract subject to the labor standards provisions of the statutes listed in 29 CFR 5.1.  Debarment is for a 3-year period to terminate on the date shown.  There are no exceptions and no dollar amount thresholds applicable to this Davis-Bacon Act debarment.","11/21/2023","11/21/2026","","(also MTZ ELECTRIC SERVICE LLC)","S4MRRFPZG","","","2023-11-21"
"Individual","","","VICTOR","","TORRES","","","","","","EL PASO","TX","USA","79905","","","","Reciprocal","","","Ineligible (Proceedings Completed)","The contractor has been debarred by the Comptroller General for violation of the Davis-Bacon Act, 40 USC 3141-3148.  The contractor, or any firm, corporation, partnership, or association in which the contractor has an interest, is ineligible to receive any contract or subcontract of the United States or District of Columbia and any contract or subcontract subject to the labor standards provisions of the statutes listed in 29 CFR 5.1.  Debarment is for a 3-year period to terminate on the date shown.  There are no exceptions and no dollar amount thresholds applicable to this 3-year period of debarment under the Davis-Bacon Act.  Please disregard the information listed under “Effect” above, which is incorrect as to Davis-Bacon Act debarments.","08/19/2022","08/20/2025","","(also VMC CONSTRUCTION, LLC, VMC CONSTRUCTION, LLC  DBA VICTOR TORRES CONSTRUCTION)","S4MRRFPZD","","","2023-11-21"
"Individual","","","MOJTABA","","JAHANDUST","","","","","","","","IRN","","","","G1XMB5VWMSW8","Reciprocal","TREAS-OFAC","","Prohibition/Restriction","PII data has been masked from view","11/17/2023","Indefinite","","","S4MRRFYKV","","","2023-11-22"
"Special Entity Designation","IDRIS NAIM AC","","","","","","CALLEJON DE LA ESCONDIDA","71 COYOACAN","","","MEXICO CITY","","MEX","04010","","","DVNJGJ7DZNX6","Reciprocal","DOS","","Ineligible (Proceedings Completed)","","11/21/2023","09/19/2026","","(also FRANCISCO BERZUNZA LARA)","S4MRRFQ1B","","","2023-11-21"
"Firm","MTZ ELECTRIC SERVICE LLC","","","","","","1017 8TH ST.","","","","LAUREL","MD","USA","20707","","","DXWFKNNDNFM8","Reciprocal","","","Voluntary Exclusion","The contractor agreed to be debarred to settle government charges that the contractor violated the Davis-Bacon Act, 40 USC 3141-3148.  The contractor, or any firm, corporation, partnership, or association in which the contractor has an interest, is ineligible to receive any contract or subcontract of the United States or the District of Columbia and any contract or subcontract subject to the labor standards provisions of the statutes listed in 29 CFR 5.1.  Debarment is for a 3-year period to terminate on the date shown.  There are no exceptions and no dollar amount thresholds applicable to this Davis-Bacon Act debarment.","11/21/2023","11/21/2026","","(also VICTOR MARTINEZ)","S4MRRFQBB","","","2023-11-21"
"Special Entity Designation","PEANUT BUTTER, LLC","","","","","","1234 INTERNAL PLACE","","","","WASHINGTON","DC","USA","20210","","","D7GNQG8Z26T3","Reciprocal","DOL","","Ineligible (Proceedings Completed)","","11/21/2023","11/20/2026","","(also CASSIE COLLINS)","S4MRRFN2R","","","2023-11-21"
"Firm","TERRA KLEAN SOLUTIONS INC.","","","","","","15303 TRADESMAN","","","","SAN ANTONIO","TX","USA","78249","","","MQRCYCN81E24","Reciprocal","","","Ineligible (Proceedings Pending)","","11/20/2023","Indefinite","","(also TERRA KLEAN SOLUTIONS INC., ANTONIO FLORES)","S4MR1Y9QG","6V6U5","","2023-11-20"
"Firm","TERRA KLEAN SOLUTIONS INC.","","","","","","15303 TRADESMAN","","","","SAN ANTONIO","TX","USA","78249","","","MQRCYCN81E24","Reciprocal","","","Ineligible (Proceedings Pending)","","11/20/2023","Indefinite","","(also TERRA KLEAN SOLUTIONS INC., ANTONIO FLORES)","S4MR1Y9QG","6V6U5","","2023-11-20"
"Special Entity Designation","TRUITTSBURGH SEALERS CO.","","","","","","1135 CARRIAGE ROAD","","","","FAIRMOUNT CITY","PA","USA","162242605","","","FWCAHENFZAA2","Reciprocal","PS","","Ineligible (Proceedings Pending)","","10/27/2023","10/26/2024","","(also RONALD TRUITT)","S4MRRFY1Q","","","2023-11-22"
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
