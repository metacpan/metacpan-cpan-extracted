#no code; these are just to shut up CPANTS
use strict;
use warnings;

=head1 NAME

PDF::Cairo::Papers - a list of valid paper sizes to use in new()
newpage(), and paper_size(), and their dimensions in points, extracted
from F<papers.txt>. Size names are converted to lower-case characters
before lookup.

=head1 PAPER SIZES

=over 4

=item B<10x11>

720pts x 792pts

=item B<10x13>

720pts x 936pts

=item B<10x14>

720pts x 1008pts

=item B<12x11>

864pts x 792pts

=item B<15x11>

1080pts x 792pts

=item B<4x6>

288pts x 432pts

=item B<7x9>

504pts x 648pts

=item B<8x10>

576pts x 720pts

=item B<9x11>

648pts x 792pts

=item B<11x17>

(same as Tabloid)

=item B<12x18>

(same as ARCHB)

=item B<17x11>

(same as Ledger)

=item B<17x22>

(same as AnsiC)

=item B<18x24>

(same as ARCHC)

=item B<22x34>

(same as AnsiD)

=item B<24x36>

(same as ARCHD)

=item B<34x44>

(same as AnsiE)

=item B<36x48>

(same as ARCHE)

=item B<8.5x11>

(same as Letter)

=item B<8.5x14>

(same as Legal)

=item B<9x12>

(same as ARCHA)

=item B<A0>

2384pts x 3370pts

=item B<A1>

1684pts x 2384pts

=item B<A2>

1191pts x 1684pts

=item B<A3>

842pts x 1191pts

=item B<A3Extra>

913pts x 1262pts

=item B<A4>

595pts x 842pts

=item B<A4Extra>

667pts x 914pts

=item B<A4Plus>

595pts x 936pts

=item B<A4Small>

595pts x 842pts

=item B<A5>

420pts x 595pts

=item B<A5Extra>

492pts x 668pts

=item B<A6>

297pts x 420pts

=item B<A7>

210pts x 297pts

=item B<A8>

148pts x 210pts

=item B<A9>

105pts x 148pts

=item B<A10>

73pts x 105pts

=item B<AnsiC>

1224pts x 1584pts

=item B<AnsiD>

1584pts x 2448pts

=item B<AnsiE>

2448pts x 3168pts

=item B<ARCHA>

648pts x 864pts

=item B<ARCHB>

864pts x 1296pts

=item B<ARCHC>

1296pts x 1728pts

=item B<ARCHD>

1728pts x 2592pts

=item B<ARCHE>

2592pts x 3456pts

=item B<B0>

2920pts x 4127pts

=item B<B1>

2064pts x 2920pts

=item B<B2>

1460pts x 2064pts

=item B<B3>

1032pts x 1460pts

=item B<B4>

729pts x 1032pts

=item B<B5>

516pts x 729pts

=item B<B6>

363pts x 516pts

=item B<B7>

258pts x 363pts

=item B<B8>

181pts x 258pts

=item B<B9>

127pts x 181pts

=item B<B10>

91pts x 127pts

=item B<C4>

(same as EnvC4)

=item B<C5>

(same as EnvC5)

=item B<C6>

(same as EnvC6)

=item B<Comm10>

(same as Env10)

=item B<DL>

(same as EnvDL)

=item B<DoublePostcard>

567pts x 419.5pts

=item B<Env9>

279pts x 639pts

=item B<Env10>

297pts x 684pts

=item B<Env11>

324pts x 747pts

=item B<Env12>

342pts x 792pts

=item B<Env14>

360pts x 828pts

=item B<EnvC0>

2599pts x 3676pts

=item B<EnvC1>

1837pts x 2599pts

=item B<EnvC2>

1298pts x 1837pts

=item B<EnvC3>

918pts x 1296pts

=item B<EnvC4>

649pts x 918pts

=item B<EnvC5>

459pts x 649pts

=item B<EnvC6>

323pts x 459pts

=item B<EnvC65>

324pts x 648pts

=item B<EnvC7>

230pts x 323pts

=item B<EnvChou3>

340pts x 666pts

=item B<EnvChou4>

255pts x 581pts

=item B<Envdl>

312pts x 624pts

=item B<EnvInvite>

624pts x 624pts

=item B<EnvISOB4>

708pts x 1001pts

=item B<EnvISOB5>

499pts x 709pts

=item B<EnvISOB6>

499pts x 354pts

=item B<EnvItalian>

312pts x 652pts

=item B<EnvKaku2>

680pts x 941pts

=item B<EnvKaku3>

612pts x 785pts

=item B<EnvMonarch>

279pts x 540pts

=item B<EnvPersonal>

261pts x 468pts

=item B<EnvPRC1>

289pts x 468pts

=item B<EnvPRC2>

289pts x 499pts

=item B<EnvPRC3>

354pts x 499pts

=item B<EnvPRC4>

312pts x 590pts

=item B<EnvPRC5>

312pts x 624pts

=item B<EnvPRC6>

340pts x 652pts

=item B<EnvPRC7>

454pts x 652pts

=item B<EnvPRC8>

340pts x 876pts

=item B<EnvPRC9>

649pts x 918pts

=item B<EnvPRC10>

918pts x 1298pts

=item B<EnvYou4>

298pts x 666pts

=item B<Chou3>

(same as EnvChou3)

=item B<Chou4>

(same as EnvChou4)

=item B<Invite>

(same as EnvInvite)

=item B<Italian>

(same as EnvItalian)

=item B<Kaku2>

(same as EnvKaku2)

=item B<Kaku3>

(same as EnvKaku3)

=item B<Monarch>

(same as EnvMonarch)

=item B<Personal>

(same as EnvPersonal)

=item B<PRC1>

(same as EnvPRC1)

=item B<PRC2>

(same as EnvPRC2)

=item B<PRC3>

(same as EnvPRC3)

=item B<PRC4>

(same as EnvPRC4)

=item B<PRC5>

(same as EnvPRC5)

=item B<PRC6>

(same as EnvPRC6)

=item B<PRC7>

(same as EnvPRC7)

=item B<PRC8>

(same as EnvPRC8)

=item B<PRC9>

(same as EnvPRC9)

=item B<PRC10>

(same as EnvPRC10)

=item B<You4>

(same as EnvYou4)

=item B<Executive>

522pts x 756pts

=item B<FanFoldUS>

1071pts x 792pts

=item B<FanFoldGerman>

612pts x 864pts

=item B<FanFoldGermanLegal>

612pts x 936pts

=item B<Folio>

595pts x 935pts

=item B<FanFold>

(same as FanFoldUS)

=item B<ISOB0>

2835pts x 4008pts

=item B<ISOB1>

2004pts x 2835pts

=item B<ISOB2>

1417pts x 2004pts

=item B<ISOB3>

1001pts x 1417pts

=item B<ISOB4>

709pts x 1001pts

=item B<ISOB5>

499pts x 709pts

=item B<ISOB5Extra>

569.7pts x 782pts

=item B<ISOB6>

354pts x 499pts

=item B<ISOB7>

249pts x 354pts

=item B<ISOB8>

176pts x 249pts

=item B<ISOB9>

125pts x 176pts

=item B<ISOB10>

88pts x 125pts

=item B<Ledger>

(same as Tabloid,Rotated)

=item B<Legal>

612pts x 1008pts

=item B<LegalExtra>

684pts x 1080pts

=item B<Letter>

612pts x 792pts

=item B<LetterExtra>

684pts x 864pts

=item B<LetterPlus>

612pts x 913.7pts

=item B<LetterSmall>

612pts x 792pts

=item B<Note>

612pts x 792pts

=item B<Postcard>

284pts x 419pts

=item B<PRC16K>

414pts x 610pts

=item B<PRC32K>

275pts x 428pts

=item B<PRC32KBig>

(same as PRC32K)

=item B<Quarto>

610pts x 780pts

=item B<Statement>

396pts x 612pts

=item B<SuperA>

643pts x 1009pts

=item B<SuperB>

864pts x 1380pts

=item B<Tabloid>

792pts x 1224pts

=item B<TabloidExtra>

864pts x 1296pts

=item B<USLegal>

(same as Legal)

=item B<USLetter>

(same as Letter)

=item B<LegalUS>

(same as Legal)

=item B<LetterUS>

(same as Letter)

=item B<Kindle>

259pts x 346pts

=item B<KindleOasis>

304pts x 403pts

=item B<Sony>

249pts x 326pts

=back
