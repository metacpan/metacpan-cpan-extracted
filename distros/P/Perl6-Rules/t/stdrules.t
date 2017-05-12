use Perl6::Rules;
use Test::Simple "no_plan";
use charnames ":full";

ok( "abc1_2" =~ m/^ <?ident> $/, "<?ident>" );
ok( $0->{ident} eq 'abc1_2', "Captured <ident>" );
ok( "abc1_2" =~ m/^ <ident> $/, "<ident>" );
ok( !defined $0->{ident}, "Uncaptured <ident>" );
ok( "7abc1_2" !~ m/^ <ident> $/, "not <ident>" );

ok( "\t \n\t" =~ m/^ <ws> $/, "<ws>" );
ok( !defined $0->{ws}, "Uncaptured <ws>" );
ok( "7abc1_2" !~ m/^ <ws> $/, "not <ws>" );

ok( " " =~ m/^ <sp> $/, "<sp>" );
ok( !defined $0->{sp}, "Uncaptured <sp>" );
ok( "7abc1_2" !~ m/<sp>/, "not <sp>" );

ok( " \t\t \t" =~ m/^ (\h+) $/, '\h' );
ok( $0 eq " \t\t \t", 'captured \h' );
ok( " \t\n " !~ m/^ (\h+) $/, 'not \h' );

ok( "\n\n" =~ m/^ (\v+) $/, '\v' );
ok( $0 eq "\n\n", 'captured \v' );
ok( " \t\n " !~ m/^ (\v+) $/, 'not \v' );


# alpha

ok( "\N{LATIN CAPITAL LETTER A}" =~ m/^<alpha>$/, q{Match alpha as subrule} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<!alpha>.$/, q{Don't match negated alpha as subrule} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<-alpha>$/, q{Don't match inverted alpha as subrule} );
ok( "\N{BELL}"  !~ m/^<alpha>$/, q{Don't match unrelated alpha as subrule} );
ok( "\N{BELL}"  =~ m/^<!alpha>.$/, q{Match unrelated negated alpha as subrule} );
ok( "\N{BELL}"  =~ m/^<-alpha>$/, q{Match unrelated inverted alpha as subrule} );
 
ok( "\N{LATIN CAPITAL LETTER A}" =~ m/^<+<alpha>>$/, q{Match alpha as charset} );
ok( "\N{LATIN CAPITAL LETTER A}" =~ m/^<[A]+<alpha>>$/, q{Match compound alpha as charset} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<-<alpha>>$/, q{Don't match externally inverted alpha as charset} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<[A]-<alpha>>$/, q{Don't match compound inverted alpha as charset} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<+<-alpha>>$/, q{Don't match internally inverted alpha as charset} );
ok( "\N{BELL}"  !~ m/^<+<alpha>>$/, q{Don't match unrelated alpha as charset} );
ok( "\N{BELL}"  =~ m/^<-<alpha>>$/, q{Match unrelated externally inverted alpha as charset} );
ok( "\N{BELL}"  =~ m/^<+<-alpha>>$/, q{Match unrelated internally inverted alpha as charset} );
ok( "\N{BELL}\N{LATIN CAPITAL LETTER A}" =~ m/<+<alpha>>/, q{Match unanchored alpha as charset} );

# space

ok( "\N{CHARACTER TABULATION}" =~ m/^<space>$/, q{Match space as subrule} );
ok( "\N{CHARACTER TABULATION}" !~ m/^<!space>.$/, q{Don't match negated space as subrule} );
ok( "\N{CHARACTER TABULATION}" !~ m/^<-space>$/, q{Don't match inverted space as subrule} );
ok( "\N{LEFT PARENTHESIS}"  !~ m/^<space>$/, q{Don't match unrelated space as subrule} );
ok( "\N{LEFT PARENTHESIS}"  =~ m/^<!space>.$/, q{Match unrelated negated space as subrule} );
ok( "\N{LEFT PARENTHESIS}"  =~ m/^<-space>$/, q{Match unrelated inverted space as subrule} );

ok( "\N{CHARACTER TABULATION}" =~ m/^<+<space>>$/, q{Match space as charset} );
ok( "\N{CHARACTER TABULATION}" =~ m/^<[A]+<space>>$/, q{Match compound space as charset} );
ok( "\N{CHARACTER TABULATION}" !~ m/^<-<space>>$/, q{Don't match externally inverted space as charset} );
ok( "\N{CHARACTER TABULATION}" !~ m/^<[A]-<space>>$/, q{Don't match compound inverted space as charset} );
ok( "\N{CHARACTER TABULATION}" !~ m/^<+<-space>>$/, q{Don't match internally inverted space as charset} );
ok( "\N{LEFT PARENTHESIS}"  !~ m/^<+<space>>$/, q{Don't match unrelated space as charset} );
ok( "\N{LEFT PARENTHESIS}"  =~ m/^<-<space>>$/, q{Match unrelated externally inverted space as charset} );
ok( "\N{LEFT PARENTHESIS}"  =~ m/^<+<-space>>$/, q{Match unrelated internally inverted space as charset} );
ok( "\N{LEFT PARENTHESIS}\N{CHARACTER TABULATION}" =~ m/<+<space>>/, q{Match unanchored space as charset} );

# digit

ok( "\N{DIGIT ZERO}" =~ m/^<digit>$/, q{Match digit as subrule} );
ok( "\N{DIGIT ZERO}" !~ m/^<!digit>.$/, q{Don't match negated digit as subrule} );
ok( "\N{DIGIT ZERO}" !~ m/^<-digit>$/, q{Don't match inverted digit as subrule} );
ok( "\N{FORM FEED (FF)}"  !~ m/^<digit>$/, q{Don't match unrelated digit as subrule} );
ok( "\N{FORM FEED (FF)}"  =~ m/^<!digit>.$/, q{Match unrelated negated digit as subrule} );
ok( "\N{FORM FEED (FF)}"  =~ m/^<-digit>$/, q{Match unrelated inverted digit as subrule} );

ok( "\N{DIGIT ZERO}" =~ m/^<+<digit>>$/, q{Match digit as charset} );
ok( "\N{DIGIT ZERO}" =~ m/^<[A]+<digit>>$/, q{Match compound digit as charset} );
ok( "\N{DIGIT ZERO}" !~ m/^<-<digit>>$/, q{Don't match externally inverted digit as charset} );
ok( "\N{DIGIT ZERO}" !~ m/^<[A]-<digit>>$/, q{Don't match compound inverted digit as charset} );
ok( "\N{DIGIT ZERO}" !~ m/^<+<-digit>>$/, q{Don't match internally inverted digit as charset} );
ok( "\N{FORM FEED (FF)}"  !~ m/^<+<digit>>$/, q{Don't match unrelated digit as charset} );
ok( "\N{FORM FEED (FF)}"  =~ m/^<-<digit>>$/, q{Match unrelated externally inverted digit as charset} );
ok( "\N{FORM FEED (FF)}"  =~ m/^<+<-digit>>$/, q{Match unrelated internally inverted digit as charset} );
ok( "\N{FORM FEED (FF)}\N{DIGIT ZERO}" =~ m/<+<digit>>/, q{Match unanchored digit as charset} );

# alnum

ok( "\N{LATIN SMALL LETTER N}" =~ m/^<alnum>$/, q{Match alnum as subrule} );
ok( "\N{LATIN SMALL LETTER N}" !~ m/^<!alnum>.$/, q{Don't match negated alnum as subrule} );
ok( "\N{LATIN SMALL LETTER N}" !~ m/^<-alnum>$/, q{Don't match inverted alnum as subrule} );
ok( "\N{LEFT CURLY BRACKET}"  !~ m/^<alnum>$/, q{Don't match unrelated alnum as subrule} );
ok( "\N{LEFT CURLY BRACKET}"  =~ m/^<!alnum>.$/, q{Match unrelated negated alnum as subrule} );
ok( "\N{LEFT CURLY BRACKET}"  =~ m/^<-alnum>$/, q{Match unrelated inverted alnum as subrule} );

ok( "\N{LATIN SMALL LETTER N}" =~ m/^<+<alnum>>$/, q{Match alnum as charset} );
ok( "\N{LATIN SMALL LETTER N}" =~ m/^<[A]+<alnum>>$/, q{Match compound alnum as charset} );
ok( "\N{LATIN SMALL LETTER N}" !~ m/^<-<alnum>>$/, q{Don't match externally inverted alnum as charset} );
ok( "\N{LATIN SMALL LETTER N}" !~ m/^<[A]-<alnum>>$/, q{Don't match compound inverted alnum as charset} );
ok( "\N{LATIN SMALL LETTER N}" !~ m/^<+<-alnum>>$/, q{Don't match internally inverted alnum as charset} );
ok( "\N{LEFT CURLY BRACKET}"  !~ m/^<+<alnum>>$/, q{Don't match unrelated alnum as charset} );
ok( "\N{LEFT CURLY BRACKET}"  =~ m/^<-<alnum>>$/, q{Match unrelated externally inverted alnum as charset} );
ok( "\N{LEFT CURLY BRACKET}"  =~ m/^<+<-alnum>>$/, q{Match unrelated internally inverted alnum as charset} );
ok( "\N{LEFT CURLY BRACKET}\N{LATIN SMALL LETTER N}" =~ m/<+<alnum>>/, q{Match unanchored alnum as charset} );

# ascii

ok( "\N{PLUS SIGN}" =~ m/^<ascii>$/, q{Match ascii as subrule} );
ok( "\N{PLUS SIGN}" !~ m/^<!ascii>.$/, q{Don't match negated ascii as subrule} );
ok( "\N{PLUS SIGN}" !~ m/^<-ascii>$/, q{Don't match inverted ascii as subrule} );

ok( "\N{PLUS SIGN}" =~ m/^<+<ascii>>$/, q{Match ascii as charset} );
ok( "\N{PLUS SIGN}" =~ m/^<[A]+<ascii>>$/, q{Match compound ascii as charset} );
ok( "\N{PLUS SIGN}" !~ m/^<-<ascii>>$/, q{Don't match externally inverted ascii as charset} );
ok( "\N{PLUS SIGN}" !~ m/^<[A]-<ascii>>$/, q{Don't match compound inverted ascii as charset} );
ok( "\N{PLUS SIGN}" !~ m/^<+<-ascii>>$/, q{Don't match internally inverted ascii as charset} );
ok( "\N{PLUS SIGN}" =~ m/<+<ascii>>/, q{Match unanchored ascii as charset} );

# blank

ok( "\N{CHARACTER TABULATION}" =~ m/^<blank>$/, q{Match blank as subrule} );
ok( "\N{CHARACTER TABULATION}" !~ m/^<!blank>.$/, q{Don't match negated blank as subrule} );
ok( "\N{CHARACTER TABULATION}" !~ m/^<-blank>$/, q{Don't match inverted blank as subrule} );
ok( "\N{AMPERSAND}"  !~ m/^<blank>$/, q{Don't match unrelated blank as subrule} );
ok( "\N{AMPERSAND}"  =~ m/^<!blank>.$/, q{Match unrelated negated blank as subrule} );
ok( "\N{AMPERSAND}"  =~ m/^<-blank>$/, q{Match unrelated inverted blank as subrule} );

ok( "\N{CHARACTER TABULATION}" =~ m/^<+<blank>>$/, q{Match blank as charset} );
ok( "\N{CHARACTER TABULATION}" =~ m/^<[A]+<blank>>$/, q{Match compound blank as charset} );
ok( "\N{CHARACTER TABULATION}" !~ m/^<-<blank>>$/, q{Don't match externally inverted blank as charset} );
ok( "\N{CHARACTER TABULATION}" !~ m/^<[A]-<blank>>$/, q{Don't match compound inverted blank as charset} );
ok( "\N{CHARACTER TABULATION}" !~ m/^<+<-blank>>$/, q{Don't match internally inverted blank as charset} );
ok( "\N{AMPERSAND}"  !~ m/^<+<blank>>$/, q{Don't match unrelated blank as charset} );
ok( "\N{AMPERSAND}"  =~ m/^<-<blank>>$/, q{Match unrelated externally inverted blank as charset} );
ok( "\N{AMPERSAND}"  =~ m/^<+<-blank>>$/, q{Match unrelated internally inverted blank as charset} );
ok( "\N{AMPERSAND}\N{CHARACTER TABULATION}" =~ m/<+<blank>>/, q{Match unanchored blank as charset} );

# cntrl

ok( "\N{DELETE}" =~ m/^<cntrl>$/, q{Match cntrl as subrule} );
ok( "\N{DELETE}" !~ m/^<!cntrl>.$/, q{Don't match negated cntrl as subrule} );
ok( "\N{DELETE}" !~ m/^<-cntrl>$/, q{Don't match inverted cntrl as subrule} );
ok( "\N{EQUALS SIGN}"  !~ m/^<cntrl>$/, q{Don't match unrelated cntrl as subrule} );
ok( "\N{EQUALS SIGN}"  =~ m/^<!cntrl>.$/, q{Match unrelated negated cntrl as subrule} );
ok( "\N{EQUALS SIGN}"  =~ m/^<-cntrl>$/, q{Match unrelated inverted cntrl as subrule} );

ok( "\N{DELETE}" =~ m/^<+<cntrl>>$/, q{Match cntrl as charset} );
ok( "\N{DELETE}" =~ m/^<[A]+<cntrl>>$/, q{Match compound cntrl as charset} );
ok( "\N{DELETE}" !~ m/^<-<cntrl>>$/, q{Don't match externally inverted cntrl as charset} );
ok( "\N{DELETE}" !~ m/^<[A]-<cntrl>>$/, q{Don't match compound inverted cntrl as charset} );
ok( "\N{DELETE}" !~ m/^<+<-cntrl>>$/, q{Don't match internally inverted cntrl as charset} );
ok( "\N{EQUALS SIGN}"  !~ m/^<+<cntrl>>$/, q{Don't match unrelated cntrl as charset} );
ok( "\N{EQUALS SIGN}"  =~ m/^<-<cntrl>>$/, q{Match unrelated externally inverted cntrl as charset} );
ok( "\N{EQUALS SIGN}"  =~ m/^<+<-cntrl>>$/, q{Match unrelated internally inverted cntrl as charset} );
ok( "\N{EQUALS SIGN}\N{DELETE}" =~ m/<+<cntrl>>/, q{Match unanchored cntrl as charset} );

# graph

ok( "\N{LATIN CAPITAL LETTER V}" =~ m/^<graph>$/, q{Match graph as subrule} );
ok( "\N{LATIN CAPITAL LETTER V}" !~ m/^<!graph>.$/, q{Don't match negated graph as subrule} );
ok( "\N{LATIN CAPITAL LETTER V}" !~ m/^<-graph>$/, q{Don't match inverted graph as subrule} );
ok( "\N{DELETE}"  !~ m/^<graph>$/, q{Don't match unrelated graph as subrule} );
ok( "\N{DELETE}"  =~ m/^<!graph>.$/, q{Match unrelated negated graph as subrule} );
ok( "\N{DELETE}"  =~ m/^<-graph>$/, q{Match unrelated inverted graph as subrule} );

ok( "\N{LATIN CAPITAL LETTER V}" =~ m/^<+<graph>>$/, q{Match graph as charset} );
ok( "\N{LATIN CAPITAL LETTER V}" =~ m/^<[A]+<graph>>$/, q{Match compound graph as charset} );
ok( "\N{LATIN CAPITAL LETTER V}" !~ m/^<-<graph>>$/, q{Don't match externally inverted graph as charset} );
ok( "\N{LATIN CAPITAL LETTER V}" !~ m/^<[A]-<graph>>$/, q{Don't match compound inverted graph as charset} );
ok( "\N{LATIN CAPITAL LETTER V}" !~ m/^<+<-graph>>$/, q{Don't match internally inverted graph as charset} );
ok( "\N{DELETE}"  !~ m/^<+<graph>>$/, q{Don't match unrelated graph as charset} );
ok( "\N{DELETE}"  =~ m/^<-<graph>>$/, q{Match unrelated externally inverted graph as charset} );
ok( "\N{DELETE}"  =~ m/^<+<-graph>>$/, q{Match unrelated internally inverted graph as charset} );
ok( "\N{DELETE}\N{LATIN CAPITAL LETTER V}" =~ m/<+<graph>>/, q{Match unanchored graph as charset} );

# lower

ok( "\N{LATIN SMALL LETTER A}" =~ m/^<lower>$/, q{Match lower as subrule} );
ok( "\N{LATIN SMALL LETTER A}" !~ m/^<!lower>.$/, q{Don't match negated lower as subrule} );
ok( "\N{LATIN SMALL LETTER A}" !~ m/^<-lower>$/, q{Don't match inverted lower as subrule} );
ok( "\N{INFORMATION SEPARATOR TWO}"  !~ m/^<lower>$/, q{Don't match unrelated lower as subrule} );
ok( "\N{INFORMATION SEPARATOR TWO}"  =~ m/^<!lower>.$/, q{Match unrelated negated lower as subrule} );
ok( "\N{INFORMATION SEPARATOR TWO}"  =~ m/^<-lower>$/, q{Match unrelated inverted lower as subrule} );

ok( "\N{LATIN SMALL LETTER A}" =~ m/^<+<lower>>$/, q{Match lower as charset} );
ok( "\N{LATIN SMALL LETTER A}" =~ m/^<[A]+<lower>>$/, q{Match compound lower as charset} );
ok( "\N{LATIN SMALL LETTER A}" !~ m/^<-<lower>>$/, q{Don't match externally inverted lower as charset} );
ok( "\N{LATIN SMALL LETTER A}" !~ m/^<[A]-<lower>>$/, q{Don't match compound inverted lower as charset} );
ok( "\N{LATIN SMALL LETTER A}" !~ m/^<+<-lower>>$/, q{Don't match internally inverted lower as charset} );
ok( "\N{INFORMATION SEPARATOR TWO}"  !~ m/^<+<lower>>$/, q{Don't match unrelated lower as charset} );
ok( "\N{INFORMATION SEPARATOR TWO}"  =~ m/^<-<lower>>$/, q{Match unrelated externally inverted lower as charset} );
ok( "\N{INFORMATION SEPARATOR TWO}"  =~ m/^<+<-lower>>$/, q{Match unrelated internally inverted lower as charset} );
ok( "\N{INFORMATION SEPARATOR TWO}\N{LATIN SMALL LETTER A}" =~ m/<+<lower>>/, q{Match unanchored lower as charset} );

# print

ok( "\N{LATIN CAPITAL LETTER M}" =~ m/^<print>$/, q{Match print as subrule} );
ok( "\N{LATIN CAPITAL LETTER M}" !~ m/^<!print>.$/, q{Don't match negated print as subrule} );
ok( "\N{LATIN CAPITAL LETTER M}" !~ m/^<-print>$/, q{Don't match inverted print as subrule} );
ok( "\N{DELETE}"  !~ m/^<print>$/, q{Don't match unrelated print as subrule} );
ok( "\N{DELETE}"  =~ m/^<!print>.$/, q{Match unrelated negated print as subrule} );
ok( "\N{DELETE}"  =~ m/^<-print>$/, q{Match unrelated inverted print as subrule} );

ok( "\N{LATIN CAPITAL LETTER M}" =~ m/^<+<print>>$/, q{Match print as charset} );
ok( "\N{LATIN CAPITAL LETTER M}" =~ m/^<[A]+<print>>$/, q{Match compound print as charset} );
ok( "\N{LATIN CAPITAL LETTER M}" !~ m/^<-<print>>$/, q{Don't match externally inverted print as charset} );
ok( "\N{LATIN CAPITAL LETTER M}" !~ m/^<[A]-<print>>$/, q{Don't match compound inverted print as charset} );
ok( "\N{LATIN CAPITAL LETTER M}" !~ m/^<+<-print>>$/, q{Don't match internally inverted print as charset} );
ok( "\N{DELETE}"  !~ m/^<+<print>>$/, q{Don't match unrelated print as charset} );
ok( "\N{DELETE}"  =~ m/^<-<print>>$/, q{Match unrelated externally inverted print as charset} );
ok( "\N{DELETE}"  =~ m/^<+<-print>>$/, q{Match unrelated internally inverted print as charset} );
ok( "\N{DELETE}\N{LATIN CAPITAL LETTER M}" =~ m/<+<print>>/, q{Match unanchored print as charset} );

# punct

ok( "\N{LEFT SQUARE BRACKET}" =~ m/^<punct>$/, q{Match punct as subrule} );
ok( "\N{LEFT SQUARE BRACKET}" !~ m/^<!punct>.$/, q{Don't match negated punct as subrule} );
ok( "\N{LEFT SQUARE BRACKET}" !~ m/^<-punct>$/, q{Don't match inverted punct as subrule} );
ok( "\N{LATIN CAPITAL LETTER F}"  !~ m/^<punct>$/, q{Don't match unrelated punct as subrule} );
ok( "\N{LATIN CAPITAL LETTER F}"  =~ m/^<!punct>.$/, q{Match unrelated negated punct as subrule} );
ok( "\N{LATIN CAPITAL LETTER F}"  =~ m/^<-punct>$/, q{Match unrelated inverted punct as subrule} );

ok( "\N{LEFT SQUARE BRACKET}" =~ m/^<+<punct>>$/, q{Match punct as charset} );
ok( "\N{LEFT SQUARE BRACKET}" =~ m/^<[A]+<punct>>$/, q{Match compound punct as charset} );
ok( "\N{LEFT SQUARE BRACKET}" !~ m/^<-<punct>>$/, q{Don't match externally inverted punct as charset} );
ok( "\N{LEFT SQUARE BRACKET}" !~ m/^<[A]-<punct>>$/, q{Don't match compound inverted punct as charset} );
ok( "\N{LEFT SQUARE BRACKET}" !~ m/^<+<-punct>>$/, q{Don't match internally inverted punct as charset} );
ok( "\N{LATIN CAPITAL LETTER F}"  !~ m/^<+<punct>>$/, q{Don't match unrelated punct as charset} );
ok( "\N{LATIN CAPITAL LETTER F}"  =~ m/^<-<punct>>$/, q{Match unrelated externally inverted punct as charset} );
ok( "\N{LATIN CAPITAL LETTER F}"  =~ m/^<+<-punct>>$/, q{Match unrelated internally inverted punct as charset} );
ok( "\N{LATIN CAPITAL LETTER F}\N{LEFT SQUARE BRACKET}" =~ m/<+<punct>>/, q{Match unanchored punct as charset} );

# upper

ok( "\N{LATIN CAPITAL LETTER A}" =~ m/^<upper>$/, q{Match upper as subrule} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<!upper>.$/, q{Don't match negated upper as subrule} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<-upper>$/, q{Don't match inverted upper as subrule} );
ok( "\N{LOW LINE}"  !~ m/^<upper>$/, q{Don't match unrelated upper as subrule} );
ok( "\N{LOW LINE}"  =~ m/^<!upper>.$/, q{Match unrelated negated upper as subrule} );
ok( "\N{LOW LINE}"  =~ m/^<-upper>$/, q{Match unrelated inverted upper as subrule} );

ok( "\N{LATIN CAPITAL LETTER A}" =~ m/^<+<upper>>$/, q{Match upper as charset} );
ok( "\N{LATIN CAPITAL LETTER A}" =~ m/^<[A]+<upper>>$/, q{Match compound upper as charset} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<-<upper>>$/, q{Don't match externally inverted upper as charset} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<[A]-<upper>>$/, q{Don't match compound inverted upper as charset} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<+<-upper>>$/, q{Don't match internally inverted upper as charset} );
ok( "\N{LOW LINE}"  !~ m/^<+<upper>>$/, q{Don't match unrelated upper as charset} );
ok( "\N{LOW LINE}"  =~ m/^<-<upper>>$/, q{Match unrelated externally inverted upper as charset} );
ok( "\N{LOW LINE}"  =~ m/^<+<-upper>>$/, q{Match unrelated internally inverted upper as charset} );
ok( "\N{LOW LINE}\N{LATIN CAPITAL LETTER A}" =~ m/<+<upper>>/, q{Match unanchored upper as charset} );

# word

ok( "\N{LATIN SMALL LETTER B}" =~ m/^<word>$/, q{Match word as subrule} );
ok( "\N{LATIN SMALL LETTER B}" !~ m/^<!word>.$/, q{Don't match negated word as subrule} );
ok( "\N{LATIN SMALL LETTER B}" !~ m/^<-word>$/, q{Don't match inverted word as subrule} );
ok( "\N{LEFT CURLY BRACKET}"  !~ m/^<word>$/, q{Don't match unrelated word as subrule} );
ok( "\N{LEFT CURLY BRACKET}"  =~ m/^<!word>.$/, q{Match unrelated negated word as subrule} );
ok( "\N{LEFT CURLY BRACKET}"  =~ m/^<-word>$/, q{Match unrelated inverted word as subrule} );

ok( "\N{LATIN SMALL LETTER B}" =~ m/^<+<word>>$/, q{Match word as charset} );
ok( "\N{LATIN SMALL LETTER B}" =~ m/^<[A]+<word>>$/, q{Match compound word as charset} );
ok( "\N{LATIN SMALL LETTER B}" !~ m/^<-<word>>$/, q{Don't match externally inverted word as charset} );
ok( "\N{LATIN SMALL LETTER B}" !~ m/^<[A]-<word>>$/, q{Don't match compound inverted word as charset} );
ok( "\N{LATIN SMALL LETTER B}" !~ m/^<+<-word>>$/, q{Don't match internally inverted word as charset} );
ok( "\N{LEFT CURLY BRACKET}"  !~ m/^<+<word>>$/, q{Don't match unrelated word as charset} );
ok( "\N{LEFT CURLY BRACKET}"  =~ m/^<-<word>>$/, q{Match unrelated externally inverted word as charset} );
ok( "\N{LEFT CURLY BRACKET}"  =~ m/^<+<-word>>$/, q{Match unrelated internally inverted word as charset} );
ok( "\N{LEFT CURLY BRACKET}\N{LATIN SMALL LETTER B}" =~ m/<+<word>>/, q{Match unanchored word as charset} );

# xdigit

ok( "\N{DIGIT ZERO}" =~ m/^<xdigit>$/, q{Match xdigit as subrule} );
ok( "\N{DIGIT ZERO}" !~ m/^<!xdigit>.$/, q{Don't match negated xdigit as subrule} );
ok( "\N{DIGIT ZERO}" !~ m/^<-xdigit>$/, q{Don't match inverted xdigit as subrule} );
ok( "\N{RIGHT CURLY BRACKET}"  !~ m/^<xdigit>$/, q{Don't match unrelated xdigit as subrule} );
ok( "\N{RIGHT CURLY BRACKET}"  =~ m/^<!xdigit>.$/, q{Match unrelated negated xdigit as subrule} );
ok( "\N{RIGHT CURLY BRACKET}"  =~ m/^<-xdigit>$/, q{Match unrelated inverted xdigit as subrule} );

ok( "\N{DIGIT ZERO}" =~ m/^<+<xdigit>>$/, q{Match xdigit as charset} );
ok( "\N{DIGIT ZERO}" =~ m/^<[A]+<xdigit>>$/, q{Match compound xdigit as charset} );
ok( "\N{DIGIT ZERO}" !~ m/^<-<xdigit>>$/, q{Don't match externally inverted xdigit as charset} );
ok( "\N{DIGIT ZERO}" !~ m/^<[A]-<xdigit>>$/, q{Don't match compound inverted xdigit as charset} );
ok( "\N{DIGIT ZERO}" !~ m/^<+<-xdigit>>$/, q{Don't match internally inverted xdigit as charset} );
ok( "\N{RIGHT CURLY BRACKET}"  !~ m/^<+<xdigit>>$/, q{Don't match unrelated xdigit as charset} );
ok( "\N{RIGHT CURLY BRACKET}"  =~ m/^<-<xdigit>>$/, q{Match unrelated externally inverted xdigit as charset} );
ok( "\N{RIGHT CURLY BRACKET}"  =~ m/^<+<-xdigit>>$/, q{Match unrelated internally inverted xdigit as charset} );
ok( "\N{RIGHT CURLY BRACKET}\N{DIGIT ZERO}" =~ m/<+<xdigit>>/, q{Match unanchored xdigit as charset} );
