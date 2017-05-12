# -*-perl-*-

## TODO: (Gly4Ser)3. PPG[W, F, Y, M, L] ...

#use Test::More qw(no_plan);
use Test::More tests => 63;

use Peptide::Pubmed;
use Data::Dumper;
use Carp;
use warnings;
use strict;

my $verbose = defined $ENV{TEST_VERBOSE} ? $ENV{TEST_VERBOSE} : 1;

my $parser = Peptide::Pubmed->new(verbose => $verbose);

# to_aa1 tests:

# is($parser->to_aa1(''), '', 
#    q[x]);

isnt($parser->to_aa1('BLACK'), 'LACK', 
   q[isnt to_aa1('BLACK'), 'LACK';; B is not valid 1 letter symbol]);
isnt($parser->to_aa1('XLAC'), 'XLACZ', 
   q[isnt to_aa1('XLAC'), 'XLACZ';; Z is not valid 1 letter symbol]);
is($parser->to_aa1('GETRAPL'), 'GETRAPL', 
   q[to_aa1('GETRAPL'), 'GETRAPL';; only 1 letter symbols]);
is($parser->to_aa1('SELEX'), 'SELEX', 
   q[to_aa1('SELEX'), 'SELEX';; scientific term that looks like peptide sequence; known bug]);
is($parser->to_aa1('ACCCGTNA'), 'ACCCGTNA', 
   q[to_aa1('ACCCGTNA'), 'ACCCGTNA';; DNA that looks like peptide sequence; known bug]);
is($parser->to_aa1('FVIII'), 'FVIII', 
   q[to_aa1('FVIII'), 'FVIII';; gene symbol that looks like peptide sequence; known bug]);
is($parser->to_aa1('14RRVPTETRSSF24'), 'RRVPTETRSSF', 
   q[to_aa1('14RRVPTETRSSF24'), 'RRVPTETRSSF';; sequence with aa positions]);
is($parser->to_aa1('TRDI-pY-ETD-pY-pY-RK'), 'TRDIYETDYYRK', 
   q[to_aa1('TRDI-pY-ETD-pY-pY-RK'), 'TRDIYETDYYRK';; phospho-aa]);
is($parser->to_aa1('MDWxxxxx(L/I)Fxx(L/F)'), 'MDWXXXXX(L/I)FXX(L/F)', 
   q[to_aa1('MDWxxxxx(L/I)Fxx(L/F)'), 'MDWXXXXX(L/I)FXX(L/F)';; change x to X; keep (A/B/etc)]);
is($parser->to_aa1('H(2)N-KLLKLLLKLLLKLLK-CO-Ph'), 'KLLKLLLKLLLKLLK', 
   q[to_aa1('H(2)N-KLLKLLLKLLLKLLK-CO-Ph'), 'KLLKLLLKLLLKLLK';; delete terminal marks]);
is($parser->to_aa1('TGWMDF-NH2'), 'TGWMDF', 
   q[to_aa1('TGWMDF-NH2'), 'TGWMDF';; delete terminal marks]);
is($parser->to_aa1('VPVIAEKL-NH(2)'), 'VPVIAEKL', 
   q[to_aa1('VPVIAEKL-NH(2)'), 'VPVIAEKL';; delete terminal marks]);
is($parser->to_aa1('(200)HACQ(219)'), 'HACQ', 
   q[to_aa1('(200)HACQ(219)'), 'HACQ';; change Y(n) to Y]);
is($parser->to_aa1('[KKEKKKS-KKDKKAK(X)(17)KKKKKKKKAKEVELVSE]'), 'KKEKKKSKKDKKAKX', 
   q[to_aa1('[KKEKKKS-KKDKKAK(X)(17)KKKKKKKKAKEVELVSE]'), 'KKEKKKSKKDKKAKX';; delete digits; known bug: expected: X repeated 17 times]); # known bug: only the first sequence in the word is extracted in to_aa1() and digits are not allowed.
is($parser->to_aa1('(Z-DEVD-FMK).'), 'DEVD',
   q[to_aa1('(Z-DEVD-FMK).'), 'DEVD';; delete FMK]);

# handle parens:

is($parser->to_aa1('C-(ELDKWA-G)4'), 'CELDKWAG', 
   q[to_aa1('C-(ELDKWA-G)4'), 'CELDKWAG';; change (ABC...) to ABC...]);
is($parser->to_aa1('GVFFEL(I)VG'), 'GVFFELIVG', 
   q[to_aa1('GVFFEL(I)VG'), 'GVFFELIVG';; change (Y) to Y; known bug. correct: GVFFE(L/I)VG]);

# handle '/':

is($parser->to_aa1('(PXXP/GXPXP)'), 'PXX(P/G)XPXP', 
   q[to_aa1('(PXXP/GXPXP)'), 'PXX(P/G)XPXP';; replace Y/Z with (Y/Z)]); # allow (Y/Z) inside ()
is($parser->to_aa1('(PXXP/PXPXP)'), 'PXPXP', 
   q[to_aa1('(PXXP/PXPXP)'), 'PXPXP';; do not allow repeats, eg Y/.../Y inside (); split on '/' instead]);
is($parser->to_aa1('(PXXP/XXPXP)'), 'XXPXP', 
   q[to_aa1('(PXXP/XXPXP)'), 'XXPXP';; do not allow X inside (); split on '/' instead]);

# aa3_to_aa1 tests:

# is($parser->aa3_to_aa1(''), '', 
#    q[x]);

# handle separators:

is($parser->aa3_to_aa1('N\'-Ser-Ile-Leu-Pro-Tyr-ProTyr-C\''), 'SILPYPY', 
   q[aa3_to_aa1('N\'-Ser-Ile-Leu-Pro-Tyr-ProTyr-C\''), 'SILPYPY';; remove terminal marks; handle separators: -, none]);
is($parser->aa3_to_aa1('(acetyl-AspTrpLeu-amide)'), 'DWL', 
   q[aa3_to_aa1('(acetyl-AspTrpLeu-amide)'), 'DWL';; remove terminal marks; handle separators: -, none]);
is($parser->aa3_to_aa1('Gly>His>Asn>Arg'), 'GHNR', 
   q[aa3_to_aa1('Gly>His>Asn>Arg'), 'GHNR';; handle separator: >]);
is($parser->aa3_to_aa1('Glu,Pro,Dpr,Tyr-NH(2))(2)human'), 'EPXY', 
   q[aa3_to_aa1('Glu,Pro,Dpr,Tyr-NH(2))(2)human'), 'EPXY';; handle separator: ,]);

# handle modified amino acids:

is($parser->aa3_to_aa1('cyclo(-Arg-Gly-Asp-dPhe-Val)'), 'RGDFV', 
   q[aa3_to_aa1('cyclo(-Arg-Gly-Asp-dPhe-Val)'), 'RGDFV';; handle cyclic sequences and d-amino acids]);
is($parser->aa3_to_aa1('Ac-cyclo(D-Lys-D-Ile-Leu-Asp-Val)'), 'KILDV', 
   q[aa3_to_aa1('Ac-cyclo(D-Lys-D-Ile-Leu-Asp-Val)'), 'KILDV';; handle d-amino acids]);
is($parser->aa3_to_aa1('Asn-x-Glu-x-x-(aromatic)-x-x-Gly'), 'NXEXXXXG', 
   q[aa3_to_aa1('Asn-x-Glu-x-x-(aromatic)-x-x-Gly'), 'NXEXXXXG';; handle x; known bug: aromatic is deleted; expected: changed to X]);
is($parser->aa3_to_aa1('Lys(epsilon-palmitoyl)-Phe-Phe'), 'KFF', 
   q[aa3_to_aa1('Lys(epsilon-palmitoyl)-Phe-Phe'), 'KFF';; handle modified aa: delete modifications]);
is($parser->aa3_to_aa1('(pGlu5-Arg-Pro)'), 'ERP', 
   q[aa3_to_aa1('(pGlu5-Arg-Pro)'), 'ERP';; handle phospho-aa]);
is($parser->aa3_to_aa1('Phe-Ser*-Gly-Glu'), 'FSGE', 
   q[aa3_to_aa1('Phe-Ser*-Gly-Glu'), 'FSGE';; handle marked aa]);
is($parser->aa3_to_aa1('benzyloxycarbonyl-Val-Ala-Asp-fluoromethylketone'), 'VAD', 
   q[aa3_to_aa1('benzyloxycarbonyl-Val-Ala-Asp-fluoromethylketone'), 'VAD';; handle modifications of aa which match 'x': delete them, delete x]);
is($parser->aa3_to_aa1('AspTrePheXxxAsxXxxXxxTrpAsp'), 'DFXXXXWD', 
   q[a3_to_aa1('AspTrePheXxxAsxXxxXxxTrpAsp'), 'DFXXXXWD';; handle XxxXxx and typo:Tre]);
is($parser->aa3_to_aa1('Pro-Pro-Xxx-Xxx-Tyr'), 'PPXXY', 
   q[to_aa1('Pro-Pro-Xxx-Xxx-Tyr'), 'PPXXY';; handle Xxx-Xxx]);
is($parser->aa3_to_aa1('Xaa-Pro-Yaa-Gln'), 'XPXQ', 
   q[to_aa1('Xaa-Pro-Yaa-Gln'), 'XPXQ';; handle Yaa]);
is($parser->aa3_to_aa1('NAc-lys-gly-gln-OH'), 'KGQ', 
   q[aa3_to_aa1('NAc-lys-gly-gln-OH'), 'KGQ';; handle lowercase 3 letter symbols]);
is($parser->aa3_to_aa1('pglu-ile-gly-ala'), 'IGA', 
   q[aa3_to_aa1('pglu-ile-gly-ala'), 'IGA';; handle phospho-lowercase 3 letter symbols: known bug: deleted pglu; expected: glu]);
is($parser->aa3_to_aa1('(Arg-Glu(EDANS)-Ser-Gln)'), 'RESQ', 
   q[aa3_to_aa1('(Arg-Glu(EDANS)-Ser-Gln)'), 'RESQ';; for 3 letter symbols, delete all non-3 letter symbols]);
is($parser->aa3_to_aa1('beta-Mpa(beta-(CH2)5)(Bzl)-Tyr(Bzl)-Ile-Gln-Asn-Cys(Bzl)-Pro-Leu-Gly-NH2'), 'YIQNCPLG', 
   q[aa3_to_aa1('beta-Mpa(beta-(CH2)5)(Bzl)-Tyr(Bzl)-Ile-Gln-Asn-Cys(Bzl)-Pro-Leu-Gly-NH2'), 'YIQNCPLG';; handle many modifications inside sequence with 3 letter symbols]);
is($parser->aa3_to_aa1('Gly-Met(OX)-Ala'), 'GMA', 
   q[aa3_to_aa1('Gly-Met(OX)-Ala'), 'GMA';; delete X if X = modification, not X= amino acid]);


# handle parens and numbers: simple cases:
is($parser->aa3_to_aa1('Phe-Arg-(/)-Pro-Pro-(/)-Thr'), 'FRPPT', 
   q[aa3_to_aa1('Phe-Arg-(/)-Pro-Pro-(/)-Thr'), 'FRPPT';; delete (/)]);

# handle parens and numbers: cases with X or Xaa:
is($parser->aa3_to_aa1('Cys-X-Cys-X(3)-Cys'), 'CXCXXXC', 
   q[aa3_to_aa1('Cys-X-Cys-X(3)-Cys'), 'CXCXXXC';; change X(n) to X repeated n times]);
is($parser->aa3_to_aa1('Lys-Xaa(4)-Asn-Xaa(2)-His'), 'KXXXXNXXH', 
   q[aa3_to_aa1('Lys-Xaa(4)-Asn-Xaa(2)-His'), 'KXXXXNXXH';; change Xaa(n) to X repeated n times]); 
is($parser->aa3_to_aa1('[Phe-(Xaa)4-Ile-(Xaa)2-Leu]'), 'FXXXXIXXL', 
   q[aa3_to_aa1('[Phe-(Xaa)4-Ile-(Xaa)2-Leu]'), 'FXXXXIXXL';; change (Xaa)n to X repeated n times]);
is($parser->aa3_to_aa1('Hyp)(4)-Ser-Hyp-Ser-(Hyp)(4)-Tyr'), 'XXXXSXSXXXXY', 
   q[aa3_to_aa1('Hyp)(4)-Ser-Hyp-Ser-(Hyp)(4)-Tyr'), 'XXXXSXSXXXXY';; change (Hyp)(n) to Xn to X repeated n times; disregard the nonmatching parens typo]);

# handle parens and numbers: cases with Y or Yaa:
is($parser->aa3_to_aa1('(Pro-Pro-Gly)(n)'), 'PPG', 
   q[aa3_to_aa1('(Pro-Pro-Gly)(n)'), 'PPG';; handle simple parens]);
is($parser->aa3_to_aa1('cyclo-(Ala(1)-Pro(2)-Asp(3)-Glu(4))'), 'APDE', 
   q[aa3_to_aa1('cyclo-(Ala(1)-Pro(2)-Asp(3)-Glu(4))'), 'APDE';; change Y(n) to Y]);
is($parser->aa3_to_aa1('Gly1-Val2-Thr3-Ser4'), 'GVTS', 
   q[aa3_to_aa1('Gly1-Val2-Thr3-Ser4'), 'GVTS';; handle Yn: change Yn to Y]);
is($parser->aa3_to_aa1('(Pro-Hyp-Gly)(3)-Ile-Thr'), 'PXGIT', 
   q[aa3_to_aa1('(Pro-Hyp-Gly)(3)-Ile-Thr'), 'PXGIT';; change (ABC...)(n) to ABC...; known bug: expected: ABC... repeated n times]);
is($parser->aa3_to_aa1('Thr-(125I-Tyr)-Thr'), 'TYT', 
   q[aa3_to_aa1('Thr-(125I-Tyr)-Thr'), 'TYT';; change (Y) to Y]);
is($parser->aa3_to_aa1('Phe-(D-Trp)-Lys'), 'FWK', 
   q[aa3_to_aa1('Phe-(D-Trp)-Lys'), 'FWK';; change (Y) to Y]);
is($parser->aa3_to_aa1('(Gly-Thr-Pro-(Ser?)-Lys),'), 'GTPSK',
   q[aa3_to_aa1('(Gly-Thr-Pro-(Ser?)-Lys),'), 'GTPSK';; change (Y) to Y]);
is($parser->aa3_to_aa1('(Lys)-Lys-Gln'), 'KKQ', 
   q[aa3_to_aa1('(Lys)-Lys-Gln'), 'KKQ';; change (Y) to Y at the beginning of the string]);
is($parser->aa3_to_aa1('(Glu)(5)(Gly-Ala-Pro-Gly-Pro-Pro)(6)(Glu)(5)'), 'EGAPGPPE', 
   q[aa3_to_aa1('(Glu)(5)(Gly-Ala-Pro-Gly-Pro-Pro)(6)(Glu)(5)'), 'EGAPGPPE';; change (Y)(n) or (ABC...) to Y and ABC...; known bug: expected Y or ABC... repeated n times]);
is($parser->aa3_to_aa1('Ac-(Pro)2-His-(Ala)2-His'), 'PHAH', 
   q[aa3_to_aa1('Ac-(Pro)2-His-(Ala)2-His'), 'PHAH';; change (Y)n to Y; known bug: expected Y repeated n times]);

# handle slashes:
is($parser->aa3_to_aa1('Cys-(Xaa)(3)-Lys/Arg-Arg-'), 'CXXX(K/R)R', 
   q[aa3_to_aa1('Cys-(Xaa)(3)-Lys/Arg-Arg-'), 'CXXX(K/R)R;; change A/B to (A/B)]);
is($parser->aa3_to_aa1('(287SerLeuThrSerSer291/287AlaLeuAlaAlaAla291)'), 'SLTS(S/A)LAAA', 
   q[aa3_to_aa1('(287SerLeuThrSerSer291/287AlaLeuAlaAlaAla291)'), 'SLTS(S/A)LAAA';; change A/B to (A/B): known bug: expected to split on '/' into 2 sequences]);
is($parser->aa3_to_aa1('Gly-(Leu/Pro/Gln)-(Pro/Leu)-Leu'), 'G(L/P/Q)(P/L)L', 
   q[aa3_to_aa1('Gly-(Leu/Pro/Gln)-(Pro/Leu)-Leu'), 'G(L/P/Q)(P/L)L';; keep (A/B/...)]);
is($parser->aa3_to_aa1('Val-Val-Asp/isoAsp-Ser-Ala-Tyr-Glu'), 'DSAYE', 
   q[aa3_to_aa1('Val-Val-Asp/isoAsp-Ser-Ala-Tyr-Glu'), 'DSAYE';; do not allow repeats inside (), split on '/' instead]);

# full names

is($parser->aa3_to_aa1('histidine-tryptophane-glycine-phenylalanine'), 'HWGF', 
   q[aa3_to_aa1('histidine-tryptophane-glycine-phenylalanine'), 'HWGF';; all full names]);
is($parser->aa3_to_aa1('X-proline-X-X-proline'), 'XPXXP', 
   q[aa3_to_aa1('X-proline-X-X-proline'), 'XPXXP';; full names and Xs]);
is($parser->aa3_to_aa1('methylcysteinylthreonylseryl-gamma-tert-butylglutamylvalylserine'), 'CTSEVS', 
   q[aa3_to_aa1('methylcysteinylthreonylseryl-gamma-tert-butylglutamylvalylserine'), 'CTSEVS';; full names and full names with 'yl']);
is($parser->aa3_to_aa1('Asp-Glu-Val-L-aspartic acid'), 'DEVD', 
   q[aa3_to_aa1('Asp-Glu-Val-L-aspartic acid'), 'DEVD';; full names and 3 letter symbols]);
is($parser->aa3_to_aa1('N-acetyl-l-aspartyl-l-glutamyl-l-valyl-l-aspartyl-7-amino-4-methylcoumarin'), 'DEVD', 
   q[aa3_to_aa1('N-acetyl-l-aspartyl-l-glutamyl-l-valyl-l-aspartyl-7-amino-4-methylcoumarin'), 'DEVD';; full names with 'yl' and numbers]);
