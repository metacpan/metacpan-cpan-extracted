use Perl6::Rules;
use Test::Simple "no_plan";
use charnames ":full";


# L           Letter


ok( "\x{846D}" =~ m/^<L>$/, q{Match <L> (Letter)} );
ok( "\x{846D}" !~ m/^<!L>.$/, q{Don't match negated <L> (Letter)} );
ok( "\x{846D}" !~ m/^<-L>$/, q{Don't match inverted <L> (Letter)} );
ok( "\x{9FA6}"  !~ m/^<L>$/, q{Don't match unrelated <L> (Letter)} );
ok( "\x{9FA6}"  =~ m/^<!L>.$/, q{Match unrelated negated <L> (Letter)} );
ok( "\x{9FA6}"  =~ m/^<-L>$/, q{Match unrelated inverted <L> (Letter)} );
ok( "\x{9FA6}\x{846D}" =~ m/<L>/, q{Match unanchored <L> (Letter)} );

ok( "\x{6DF7}" =~ m/^<Letter>$/, q{Match <Letter>} );
ok( "\x{6DF7}" !~ m/^<!Letter>.$/, q{Don't match negated <Letter>} );
ok( "\x{6DF7}" !~ m/^<-Letter>$/, q{Don't match inverted <Letter>} );
ok( "\x{9FA6}"  !~ m/^<Letter>$/, q{Don't match unrelated <Letter>} );
ok( "\x{9FA6}"  =~ m/^<!Letter>.$/, q{Match unrelated negated <Letter>} );
ok( "\x{9FA6}"  =~ m/^<-Letter>$/, q{Match unrelated inverted <Letter>} );
ok( "\x{9FA6}\x{6DF7}" =~ m/<Letter>/, q{Match unanchored <Letter>} );

# Lu          UppercaseLetter


ok( "\N{LATIN CAPITAL LETTER A}" =~ m/^<Lu>$/, q{Match <Lu> (UppercaseLetter)} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<!Lu>.$/, q{Don't match negated <Lu> (UppercaseLetter)} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<-Lu>$/, q{Don't match inverted <Lu> (UppercaseLetter)} );
ok( "\x{C767}"  !~ m/^<Lu>$/, q{Don't match unrelated <Lu> (UppercaseLetter)} );
ok( "\x{C767}"  =~ m/^<!Lu>.$/, q{Match unrelated negated <Lu> (UppercaseLetter)} );
ok( "\x{C767}"  =~ m/^<-Lu>$/, q{Match unrelated inverted <Lu> (UppercaseLetter)} );
ok( "\x{C767}" !~ m/^<Lu>$/, q{Don't match related <Lu> (UppercaseLetter)} );
ok( "\x{C767}" =~ m/^<!Lu>.$/, q{Match related negated <Lu> (UppercaseLetter)} );
ok( "\x{C767}" =~ m/^<-Lu>$/, q{Match related inverted <Lu> (UppercaseLetter)} );
ok( "\x{C767}\x{C767}\N{LATIN CAPITAL LETTER A}" =~ m/<Lu>/, q{Match unanchored <Lu> (UppercaseLetter)} );

ok( "\N{LATIN CAPITAL LETTER A}" =~ m/^<UppercaseLetter>$/, q{Match <UppercaseLetter>} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<!UppercaseLetter>.$/, q{Don't match negated <UppercaseLetter>} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<-UppercaseLetter>$/, q{Don't match inverted <UppercaseLetter>} );
ok( "\N{YI SYLLABLE NBA}"  !~ m/^<UppercaseLetter>$/, q{Don't match unrelated <UppercaseLetter>} );
ok( "\N{YI SYLLABLE NBA}"  =~ m/^<!UppercaseLetter>.$/, q{Match unrelated negated <UppercaseLetter>} );
ok( "\N{YI SYLLABLE NBA}"  =~ m/^<-UppercaseLetter>$/, q{Match unrelated inverted <UppercaseLetter>} );
ok( "\N{YI SYLLABLE NBA}\N{LATIN CAPITAL LETTER A}" =~ m/<UppercaseLetter>/, q{Match unanchored <UppercaseLetter>} );

# Ll          LowercaseLetter


ok( "\N{LATIN SMALL LETTER A}" =~ m/^<Ll>$/, q{Match <Ll> (LowercaseLetter)} );
ok( "\N{LATIN SMALL LETTER A}" !~ m/^<!Ll>.$/, q{Don't match negated <Ll> (LowercaseLetter)} );
ok( "\N{LATIN SMALL LETTER A}" !~ m/^<-Ll>$/, q{Don't match inverted <Ll> (LowercaseLetter)} );
ok( "\N{BOPOMOFO FINAL LETTER H}"  !~ m/^<Ll>$/, q{Don't match unrelated <Ll> (LowercaseLetter)} );
ok( "\N{BOPOMOFO FINAL LETTER H}"  =~ m/^<!Ll>.$/, q{Match unrelated negated <Ll> (LowercaseLetter)} );
ok( "\N{BOPOMOFO FINAL LETTER H}"  =~ m/^<-Ll>$/, q{Match unrelated inverted <Ll> (LowercaseLetter)} );
ok( "\N{BOPOMOFO FINAL LETTER H}" !~ m/^<Ll>$/, q{Don't match related <Ll> (LowercaseLetter)} );
ok( "\N{BOPOMOFO FINAL LETTER H}" =~ m/^<!Ll>.$/, q{Match related negated <Ll> (LowercaseLetter)} );
ok( "\N{BOPOMOFO FINAL LETTER H}" =~ m/^<-Ll>$/, q{Match related inverted <Ll> (LowercaseLetter)} );
ok( "\N{BOPOMOFO FINAL LETTER H}\N{BOPOMOFO FINAL LETTER H}\N{LATIN SMALL LETTER A}" =~ m/<Ll>/, q{Match unanchored <Ll> (LowercaseLetter)} );

ok( "\N{LATIN SMALL LETTER A}" =~ m/^<LowercaseLetter>$/, q{Match <LowercaseLetter>} );
ok( "\N{LATIN SMALL LETTER A}" !~ m/^<!LowercaseLetter>.$/, q{Don't match negated <LowercaseLetter>} );
ok( "\N{LATIN SMALL LETTER A}" !~ m/^<-LowercaseLetter>$/, q{Don't match inverted <LowercaseLetter>} );
ok( "\x{86CA}"  !~ m/^<LowercaseLetter>$/, q{Don't match unrelated <LowercaseLetter>} );
ok( "\x{86CA}"  =~ m/^<!LowercaseLetter>.$/, q{Match unrelated negated <LowercaseLetter>} );
ok( "\x{86CA}"  =~ m/^<-LowercaseLetter>$/, q{Match unrelated inverted <LowercaseLetter>} );
ok( "\x{86CA}" !~ m/^<LowercaseLetter>$/, q{Don't match related <LowercaseLetter>} );
ok( "\x{86CA}" =~ m/^<!LowercaseLetter>.$/, q{Match related negated <LowercaseLetter>} );
ok( "\x{86CA}" =~ m/^<-LowercaseLetter>$/, q{Match related inverted <LowercaseLetter>} );
ok( "\x{86CA}\x{86CA}\N{LATIN SMALL LETTER A}" =~ m/<LowercaseLetter>/, q{Match unanchored <LowercaseLetter>} );

# Lt          TitlecaseLetter


ok( "\N{LATIN CAPITAL LETTER D WITH SMALL LETTER Z WITH CARON}" =~ m/^<Lt>$/, q{Match <Lt> (TitlecaseLetter)} );
ok( "\N{LATIN CAPITAL LETTER D WITH SMALL LETTER Z WITH CARON}" !~ m/^<!Lt>.$/, q{Don't match negated <Lt> (TitlecaseLetter)} );
ok( "\N{LATIN CAPITAL LETTER D WITH SMALL LETTER Z WITH CARON}" !~ m/^<-Lt>$/, q{Don't match inverted <Lt> (TitlecaseLetter)} );
ok( "\x{6DC8}"  !~ m/^<Lt>$/, q{Don't match unrelated <Lt> (TitlecaseLetter)} );
ok( "\x{6DC8}"  =~ m/^<!Lt>.$/, q{Match unrelated negated <Lt> (TitlecaseLetter)} );
ok( "\x{6DC8}"  =~ m/^<-Lt>$/, q{Match unrelated inverted <Lt> (TitlecaseLetter)} );
ok( "\x{6DC8}" !~ m/^<Lt>$/, q{Don't match related <Lt> (TitlecaseLetter)} );
ok( "\x{6DC8}" =~ m/^<!Lt>.$/, q{Match related negated <Lt> (TitlecaseLetter)} );
ok( "\x{6DC8}" =~ m/^<-Lt>$/, q{Match related inverted <Lt> (TitlecaseLetter)} );
ok( "\x{6DC8}\x{6DC8}\N{LATIN CAPITAL LETTER D WITH SMALL LETTER Z WITH CARON}" =~ m/<Lt>/, q{Match unanchored <Lt> (TitlecaseLetter)} );

ok( "\N{GREEK CAPITAL LETTER ALPHA WITH PSILI AND PROSGEGRAMMENI}" =~ m/^<TitlecaseLetter>$/, q{Match <TitlecaseLetter>} );
ok( "\N{GREEK CAPITAL LETTER ALPHA WITH PSILI AND PROSGEGRAMMENI}" !~ m/^<!TitlecaseLetter>.$/, q{Don't match negated <TitlecaseLetter>} );
ok( "\N{GREEK CAPITAL LETTER ALPHA WITH PSILI AND PROSGEGRAMMENI}" !~ m/^<-TitlecaseLetter>$/, q{Don't match inverted <TitlecaseLetter>} );
ok( "\x{0C4E}"  !~ m/^<TitlecaseLetter>$/, q{Don't match unrelated <TitlecaseLetter>} );
ok( "\x{0C4E}"  =~ m/^<!TitlecaseLetter>.$/, q{Match unrelated negated <TitlecaseLetter>} );
ok( "\x{0C4E}"  =~ m/^<-TitlecaseLetter>$/, q{Match unrelated inverted <TitlecaseLetter>} );
ok( "\x{0C4E}\N{GREEK CAPITAL LETTER ALPHA WITH PSILI AND PROSGEGRAMMENI}" =~ m/<TitlecaseLetter>/, q{Match unanchored <TitlecaseLetter>} );

# Lm          ModifierLetter


ok( "\N{IDEOGRAPHIC ITERATION MARK}" =~ m/^<Lm>$/, q{Match <Lm> (ModifierLetter)} );
ok( "\N{IDEOGRAPHIC ITERATION MARK}" !~ m/^<!Lm>.$/, q{Don't match negated <Lm> (ModifierLetter)} );
ok( "\N{IDEOGRAPHIC ITERATION MARK}" !~ m/^<-Lm>$/, q{Don't match inverted <Lm> (ModifierLetter)} );
ok( "\x{2B61}"  !~ m/^<Lm>$/, q{Don't match unrelated <Lm> (ModifierLetter)} );
ok( "\x{2B61}"  =~ m/^<!Lm>.$/, q{Match unrelated negated <Lm> (ModifierLetter)} );
ok( "\x{2B61}"  =~ m/^<-Lm>$/, q{Match unrelated inverted <Lm> (ModifierLetter)} );
ok( "\N{IDEOGRAPHIC CLOSING MARK}" !~ m/^<Lm>$/, q{Don't match related <Lm> (ModifierLetter)} );
ok( "\N{IDEOGRAPHIC CLOSING MARK}" =~ m/^<!Lm>.$/, q{Match related negated <Lm> (ModifierLetter)} );
ok( "\N{IDEOGRAPHIC CLOSING MARK}" =~ m/^<-Lm>$/, q{Match related inverted <Lm> (ModifierLetter)} );
ok( "\x{2B61}\N{IDEOGRAPHIC CLOSING MARK}\N{IDEOGRAPHIC ITERATION MARK}" =~ m/<Lm>/, q{Match unanchored <Lm> (ModifierLetter)} );

ok( "\N{MODIFIER LETTER SMALL H}" =~ m/^<ModifierLetter>$/, q{Match <ModifierLetter>} );
ok( "\N{MODIFIER LETTER SMALL H}" !~ m/^<!ModifierLetter>.$/, q{Don't match negated <ModifierLetter>} );
ok( "\N{MODIFIER LETTER SMALL H}" !~ m/^<-ModifierLetter>$/, q{Don't match inverted <ModifierLetter>} );
ok( "\N{YI SYLLABLE HA}"  !~ m/^<ModifierLetter>$/, q{Don't match unrelated <ModifierLetter>} );
ok( "\N{YI SYLLABLE HA}"  =~ m/^<!ModifierLetter>.$/, q{Match unrelated negated <ModifierLetter>} );
ok( "\N{YI SYLLABLE HA}"  =~ m/^<-ModifierLetter>$/, q{Match unrelated inverted <ModifierLetter>} );
ok( "\N{YI SYLLABLE HA}\N{MODIFIER LETTER SMALL H}" =~ m/<ModifierLetter>/, q{Match unanchored <ModifierLetter>} );

# Lo          OtherLetter


ok( "\N{LATIN LETTER TWO WITH STROKE}" =~ m/^<Lo>$/, q{Match <Lo> (OtherLetter)} );
ok( "\N{LATIN LETTER TWO WITH STROKE}" !~ m/^<!Lo>.$/, q{Don't match negated <Lo> (OtherLetter)} );
ok( "\N{LATIN LETTER TWO WITH STROKE}" !~ m/^<-Lo>$/, q{Don't match inverted <Lo> (OtherLetter)} );
ok( "\N{LATIN SMALL LETTER TURNED DELTA}"  !~ m/^<Lo>$/, q{Don't match unrelated <Lo> (OtherLetter)} );
ok( "\N{LATIN SMALL LETTER TURNED DELTA}"  =~ m/^<!Lo>.$/, q{Match unrelated negated <Lo> (OtherLetter)} );
ok( "\N{LATIN SMALL LETTER TURNED DELTA}"  =~ m/^<-Lo>$/, q{Match unrelated inverted <Lo> (OtherLetter)} );
ok( "\N{LATIN SMALL LETTER TURNED DELTA}" !~ m/^<Lo>$/, q{Don't match related <Lo> (OtherLetter)} );
ok( "\N{LATIN SMALL LETTER TURNED DELTA}" =~ m/^<!Lo>.$/, q{Match related negated <Lo> (OtherLetter)} );
ok( "\N{LATIN SMALL LETTER TURNED DELTA}" =~ m/^<-Lo>$/, q{Match related inverted <Lo> (OtherLetter)} );
ok( "\N{LATIN SMALL LETTER TURNED DELTA}\N{LATIN SMALL LETTER TURNED DELTA}\N{LATIN LETTER TWO WITH STROKE}" =~ m/<Lo>/, q{Match unanchored <Lo> (OtherLetter)} );

ok( "\N{ETHIOPIC SYLLABLE GLOTTAL A}" =~ m/^<OtherLetter>$/, q{Match <OtherLetter>} );
ok( "\N{ETHIOPIC SYLLABLE GLOTTAL A}" !~ m/^<!OtherLetter>.$/, q{Don't match negated <OtherLetter>} );
ok( "\N{ETHIOPIC SYLLABLE GLOTTAL A}" !~ m/^<-OtherLetter>$/, q{Don't match inverted <OtherLetter>} );
ok( "\x{12AF}"  !~ m/^<OtherLetter>$/, q{Don't match unrelated <OtherLetter>} );
ok( "\x{12AF}"  =~ m/^<!OtherLetter>.$/, q{Match unrelated negated <OtherLetter>} );
ok( "\x{12AF}"  =~ m/^<-OtherLetter>$/, q{Match unrelated inverted <OtherLetter>} );
ok( "\x{12AF}\N{ETHIOPIC SYLLABLE GLOTTAL A}" =~ m/<OtherLetter>/, q{Match unanchored <OtherLetter>} );

# Lr		 	# Alias for "Ll", "Lu", and "Lt".


ok( "\N{LATIN CAPITAL LETTER A}" =~ m/^<Lr>$/, q{Match (Alias for "Ll", "Lu", and "Lt".)} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<!Lr>.$/, q{Don't match negated (Alias for "Ll", "Lu", and "Lt".)} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<-Lr>$/, q{Don't match inverted (Alias for "Ll", "Lu", and "Lt".)} );
ok( "\x{87B5}"  !~ m/^<Lr>$/, q{Don't match unrelated (Alias for "Ll", "Lu", and "Lt".)} );
ok( "\x{87B5}"  =~ m/^<!Lr>.$/, q{Match unrelated negated (Alias for "Ll", "Lu", and "Lt".)} );
ok( "\x{87B5}"  =~ m/^<-Lr>$/, q{Match unrelated inverted (Alias for "Ll", "Lu", and "Lt".)} );
ok( "\x{87B5}" !~ m/^<Lr>$/, q{Don't match related (Alias for "Ll", "Lu", and "Lt".)} );
ok( "\x{87B5}" =~ m/^<!Lr>.$/, q{Match related negated (Alias for "Ll", "Lu", and "Lt".)} );
ok( "\x{87B5}" =~ m/^<-Lr>$/, q{Match related inverted (Alias for "Ll", "Lu", and "Lt".)} );
ok( "\x{87B5}\x{87B5}\N{LATIN CAPITAL LETTER A}" =~ m/<Lr>/, q{Match unanchored (Alias for "Ll", "Lu", and "Lt".)} );

# M           Mark


ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<M>$/, q{Match <M> (Mark)} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<!M>.$/, q{Don't match negated <M> (Mark)} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<-M>$/, q{Don't match inverted <M> (Mark)} );
ok( "\x{D0AA}"  !~ m/^<M>$/, q{Don't match unrelated <M> (Mark)} );
ok( "\x{D0AA}"  =~ m/^<!M>.$/, q{Match unrelated negated <M> (Mark)} );
ok( "\x{D0AA}"  =~ m/^<-M>$/, q{Match unrelated inverted <M> (Mark)} );
ok( "\x{D0AA}\N{COMBINING GRAVE ACCENT}" =~ m/<M>/, q{Match unanchored <M> (Mark)} );

ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<Mark>$/, q{Match <Mark>} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<!Mark>.$/, q{Don't match negated <Mark>} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<-Mark>$/, q{Don't match inverted <Mark>} );
ok( "\x{BE64}"  !~ m/^<Mark>$/, q{Don't match unrelated <Mark>} );
ok( "\x{BE64}"  =~ m/^<!Mark>.$/, q{Match unrelated negated <Mark>} );
ok( "\x{BE64}"  =~ m/^<-Mark>$/, q{Match unrelated inverted <Mark>} );
ok( "\x{BE64}\N{COMBINING GRAVE ACCENT}" =~ m/<Mark>/, q{Match unanchored <Mark>} );

# Mn          NonspacingMark


ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<Mn>$/, q{Match <Mn> (NonspacingMark)} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<!Mn>.$/, q{Don't match negated <Mn> (NonspacingMark)} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<-Mn>$/, q{Don't match inverted <Mn> (NonspacingMark)} );
ok( "\x{47A5}"  !~ m/^<Mn>$/, q{Don't match unrelated <Mn> (NonspacingMark)} );
ok( "\x{47A5}"  =~ m/^<!Mn>.$/, q{Match unrelated negated <Mn> (NonspacingMark)} );
ok( "\x{47A5}"  =~ m/^<-Mn>$/, q{Match unrelated inverted <Mn> (NonspacingMark)} );
ok( "\N{COMBINING CYRILLIC HUNDRED THOUSANDS SIGN}" !~ m/^<Mn>$/, q{Don't match related <Mn> (NonspacingMark)} );
ok( "\N{COMBINING CYRILLIC HUNDRED THOUSANDS SIGN}" =~ m/^<!Mn>.$/, q{Match related negated <Mn> (NonspacingMark)} );
ok( "\N{COMBINING CYRILLIC HUNDRED THOUSANDS SIGN}" =~ m/^<-Mn>$/, q{Match related inverted <Mn> (NonspacingMark)} );
ok( "\x{47A5}\N{COMBINING CYRILLIC HUNDRED THOUSANDS SIGN}\N{COMBINING GRAVE ACCENT}" =~ m/<Mn>/, q{Match unanchored <Mn> (NonspacingMark)} );

ok( "\N{TAGALOG VOWEL SIGN I}" =~ m/^<NonspacingMark>$/, q{Match <NonspacingMark>} );
ok( "\N{TAGALOG VOWEL SIGN I}" !~ m/^<!NonspacingMark>.$/, q{Don't match negated <NonspacingMark>} );
ok( "\N{TAGALOG VOWEL SIGN I}" !~ m/^<-NonspacingMark>$/, q{Don't match inverted <NonspacingMark>} );
ok( "\N{CANADIAN SYLLABICS TYA}"  !~ m/^<NonspacingMark>$/, q{Don't match unrelated <NonspacingMark>} );
ok( "\N{CANADIAN SYLLABICS TYA}"  =~ m/^<!NonspacingMark>.$/, q{Match unrelated negated <NonspacingMark>} );
ok( "\N{CANADIAN SYLLABICS TYA}"  =~ m/^<-NonspacingMark>$/, q{Match unrelated inverted <NonspacingMark>} );
ok( "\N{CANADIAN SYLLABICS TYA}\N{TAGALOG VOWEL SIGN I}" =~ m/<NonspacingMark>/, q{Match unanchored <NonspacingMark>} );

# Mc          SpacingMark


ok( "\N{DEVANAGARI SIGN VISARGA}" =~ m/^<Mc>$/, q{Match <Mc> (SpacingMark)} );
ok( "\N{DEVANAGARI SIGN VISARGA}" !~ m/^<!Mc>.$/, q{Don't match negated <Mc> (SpacingMark)} );
ok( "\N{DEVANAGARI SIGN VISARGA}" !~ m/^<-Mc>$/, q{Don't match inverted <Mc> (SpacingMark)} );
ok( "\x{9981}"  !~ m/^<Mc>$/, q{Don't match unrelated <Mc> (SpacingMark)} );
ok( "\x{9981}"  =~ m/^<!Mc>.$/, q{Match unrelated negated <Mc> (SpacingMark)} );
ok( "\x{9981}"  =~ m/^<-Mc>$/, q{Match unrelated inverted <Mc> (SpacingMark)} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<Mc>$/, q{Don't match related <Mc> (SpacingMark)} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<!Mc>.$/, q{Match related negated <Mc> (SpacingMark)} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<-Mc>$/, q{Match related inverted <Mc> (SpacingMark)} );
ok( "\x{9981}\N{COMBINING GRAVE ACCENT}\N{DEVANAGARI SIGN VISARGA}" =~ m/<Mc>/, q{Match unanchored <Mc> (SpacingMark)} );

ok( "\N{DEVANAGARI SIGN VISARGA}" =~ m/^<SpacingMark>$/, q{Match <SpacingMark>} );
ok( "\N{DEVANAGARI SIGN VISARGA}" !~ m/^<!SpacingMark>.$/, q{Don't match negated <SpacingMark>} );
ok( "\N{DEVANAGARI SIGN VISARGA}" !~ m/^<-SpacingMark>$/, q{Don't match inverted <SpacingMark>} );
ok( "\x{35E3}"  !~ m/^<SpacingMark>$/, q{Don't match unrelated <SpacingMark>} );
ok( "\x{35E3}"  =~ m/^<!SpacingMark>.$/, q{Match unrelated negated <SpacingMark>} );
ok( "\x{35E3}"  =~ m/^<-SpacingMark>$/, q{Match unrelated inverted <SpacingMark>} );
ok( "\x{35E3}\N{DEVANAGARI SIGN VISARGA}" =~ m/<SpacingMark>/, q{Match unanchored <SpacingMark>} );

# Me          EnclosingMark


ok( "\N{COMBINING CYRILLIC HUNDRED THOUSANDS SIGN}" =~ m/^<Me>$/, q{Match <Me> (EnclosingMark)} );
ok( "\N{COMBINING CYRILLIC HUNDRED THOUSANDS SIGN}" !~ m/^<!Me>.$/, q{Don't match negated <Me> (EnclosingMark)} );
ok( "\N{COMBINING CYRILLIC HUNDRED THOUSANDS SIGN}" !~ m/^<-Me>$/, q{Don't match inverted <Me> (EnclosingMark)} );
ok( "\x{9400}"  !~ m/^<Me>$/, q{Don't match unrelated <Me> (EnclosingMark)} );
ok( "\x{9400}"  =~ m/^<!Me>.$/, q{Match unrelated negated <Me> (EnclosingMark)} );
ok( "\x{9400}"  =~ m/^<-Me>$/, q{Match unrelated inverted <Me> (EnclosingMark)} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<Me>$/, q{Don't match related <Me> (EnclosingMark)} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<!Me>.$/, q{Match related negated <Me> (EnclosingMark)} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<-Me>$/, q{Match related inverted <Me> (EnclosingMark)} );
ok( "\x{9400}\N{COMBINING GRAVE ACCENT}\N{COMBINING CYRILLIC HUNDRED THOUSANDS SIGN}" =~ m/<Me>/, q{Match unanchored <Me> (EnclosingMark)} );

ok( "\N{COMBINING CYRILLIC HUNDRED THOUSANDS SIGN}" =~ m/^<EnclosingMark>$/, q{Match <EnclosingMark>} );
ok( "\N{COMBINING CYRILLIC HUNDRED THOUSANDS SIGN}" !~ m/^<!EnclosingMark>.$/, q{Don't match negated <EnclosingMark>} );
ok( "\N{COMBINING CYRILLIC HUNDRED THOUSANDS SIGN}" !~ m/^<-EnclosingMark>$/, q{Don't match inverted <EnclosingMark>} );
ok( "\x{7C68}"  !~ m/^<EnclosingMark>$/, q{Don't match unrelated <EnclosingMark>} );
ok( "\x{7C68}"  =~ m/^<!EnclosingMark>.$/, q{Match unrelated negated <EnclosingMark>} );
ok( "\x{7C68}"  =~ m/^<-EnclosingMark>$/, q{Match unrelated inverted <EnclosingMark>} );
ok( "\x{7C68}\N{COMBINING CYRILLIC HUNDRED THOUSANDS SIGN}" =~ m/<EnclosingMark>/, q{Match unanchored <EnclosingMark>} );

# N           Number


ok( "\N{SUPERSCRIPT ZERO}" =~ m/^<N>$/, q{Match <N> (Number)} );
ok( "\N{SUPERSCRIPT ZERO}" !~ m/^<!N>.$/, q{Don't match negated <N> (Number)} );
ok( "\N{SUPERSCRIPT ZERO}" !~ m/^<-N>$/, q{Don't match inverted <N> (Number)} );
ok( "\N{LATIN LETTER SMALL CAPITAL E}"  !~ m/^<N>$/, q{Don't match unrelated <N> (Number)} );
ok( "\N{LATIN LETTER SMALL CAPITAL E}"  =~ m/^<!N>.$/, q{Match unrelated negated <N> (Number)} );
ok( "\N{LATIN LETTER SMALL CAPITAL E}"  =~ m/^<-N>$/, q{Match unrelated inverted <N> (Number)} );
ok( "\N{LATIN LETTER SMALL CAPITAL E}\N{SUPERSCRIPT ZERO}" =~ m/<N>/, q{Match unanchored <N> (Number)} );

ok( "\N{DIGIT ZERO}" =~ m/^<Number>$/, q{Match <Number>} );
ok( "\N{DIGIT ZERO}" !~ m/^<!Number>.$/, q{Don't match negated <Number>} );
ok( "\N{DIGIT ZERO}" !~ m/^<-Number>$/, q{Don't match inverted <Number>} );
ok( "\x{A994}"  !~ m/^<Number>$/, q{Don't match unrelated <Number>} );
ok( "\x{A994}"  =~ m/^<!Number>.$/, q{Match unrelated negated <Number>} );
ok( "\x{A994}"  =~ m/^<-Number>$/, q{Match unrelated inverted <Number>} );
ok( "\x{A994}\N{DIGIT ZERO}" =~ m/<Number>/, q{Match unanchored <Number>} );

# Nd          DecimalNumber


ok( "\N{DIGIT ZERO}" =~ m/^<Nd>$/, q{Match <Nd> (DecimalNumber)} );
ok( "\N{DIGIT ZERO}" !~ m/^<!Nd>.$/, q{Don't match negated <Nd> (DecimalNumber)} );
ok( "\N{DIGIT ZERO}" !~ m/^<-Nd>$/, q{Don't match inverted <Nd> (DecimalNumber)} );
ok( "\x{4E2C}"  !~ m/^<Nd>$/, q{Don't match unrelated <Nd> (DecimalNumber)} );
ok( "\x{4E2C}"  =~ m/^<!Nd>.$/, q{Match unrelated negated <Nd> (DecimalNumber)} );
ok( "\x{4E2C}"  =~ m/^<-Nd>$/, q{Match unrelated inverted <Nd> (DecimalNumber)} );
ok( "\N{SUPERSCRIPT TWO}" !~ m/^<Nd>$/, q{Don't match related <Nd> (DecimalNumber)} );
ok( "\N{SUPERSCRIPT TWO}" =~ m/^<!Nd>.$/, q{Match related negated <Nd> (DecimalNumber)} );
ok( "\N{SUPERSCRIPT TWO}" =~ m/^<-Nd>$/, q{Match related inverted <Nd> (DecimalNumber)} );
ok( "\x{4E2C}\N{SUPERSCRIPT TWO}\N{DIGIT ZERO}" =~ m/<Nd>/, q{Match unanchored <Nd> (DecimalNumber)} );

ok( "\N{DIGIT ZERO}" =~ m/^<DecimalNumber>$/, q{Match <DecimalNumber>} );
ok( "\N{DIGIT ZERO}" !~ m/^<!DecimalNumber>.$/, q{Don't match negated <DecimalNumber>} );
ok( "\N{DIGIT ZERO}" !~ m/^<-DecimalNumber>$/, q{Don't match inverted <DecimalNumber>} );
ok( "\x{A652}"  !~ m/^<DecimalNumber>$/, q{Don't match unrelated <DecimalNumber>} );
ok( "\x{A652}"  =~ m/^<!DecimalNumber>.$/, q{Match unrelated negated <DecimalNumber>} );
ok( "\x{A652}"  =~ m/^<-DecimalNumber>$/, q{Match unrelated inverted <DecimalNumber>} );
ok( "\x{A652}\N{DIGIT ZERO}" =~ m/<DecimalNumber>/, q{Match unanchored <DecimalNumber>} );

# Nl          LetterNumber


ok( "\N{RUNIC ARLAUG SYMBOL}" =~ m/^<Nl>$/, q{Match <Nl> (LetterNumber)} );
ok( "\N{RUNIC ARLAUG SYMBOL}" !~ m/^<!Nl>.$/, q{Don't match negated <Nl> (LetterNumber)} );
ok( "\N{RUNIC ARLAUG SYMBOL}" !~ m/^<-Nl>$/, q{Don't match inverted <Nl> (LetterNumber)} );
ok( "\x{6C2F}"  !~ m/^<Nl>$/, q{Don't match unrelated <Nl> (LetterNumber)} );
ok( "\x{6C2F}"  =~ m/^<!Nl>.$/, q{Match unrelated negated <Nl> (LetterNumber)} );
ok( "\x{6C2F}"  =~ m/^<-Nl>$/, q{Match unrelated inverted <Nl> (LetterNumber)} );
ok( "\N{DIGIT ZERO}" !~ m/^<Nl>$/, q{Don't match related <Nl> (LetterNumber)} );
ok( "\N{DIGIT ZERO}" =~ m/^<!Nl>.$/, q{Match related negated <Nl> (LetterNumber)} );
ok( "\N{DIGIT ZERO}" =~ m/^<-Nl>$/, q{Match related inverted <Nl> (LetterNumber)} );
ok( "\x{6C2F}\N{DIGIT ZERO}\N{RUNIC ARLAUG SYMBOL}" =~ m/<Nl>/, q{Match unanchored <Nl> (LetterNumber)} );

ok( "\N{RUNIC ARLAUG SYMBOL}" =~ m/^<LetterNumber>$/, q{Match <LetterNumber>} );
ok( "\N{RUNIC ARLAUG SYMBOL}" !~ m/^<!LetterNumber>.$/, q{Don't match negated <LetterNumber>} );
ok( "\N{RUNIC ARLAUG SYMBOL}" !~ m/^<-LetterNumber>$/, q{Don't match inverted <LetterNumber>} );
ok( "\x{80A5}"  !~ m/^<LetterNumber>$/, q{Don't match unrelated <LetterNumber>} );
ok( "\x{80A5}"  =~ m/^<!LetterNumber>.$/, q{Match unrelated negated <LetterNumber>} );
ok( "\x{80A5}"  =~ m/^<-LetterNumber>$/, q{Match unrelated inverted <LetterNumber>} );
ok( "\x{80A5}" !~ m/^<LetterNumber>$/, q{Don't match related <LetterNumber>} );
ok( "\x{80A5}" =~ m/^<!LetterNumber>.$/, q{Match related negated <LetterNumber>} );
ok( "\x{80A5}" =~ m/^<-LetterNumber>$/, q{Match related inverted <LetterNumber>} );
ok( "\x{80A5}\x{80A5}\N{RUNIC ARLAUG SYMBOL}" =~ m/<LetterNumber>/, q{Match unanchored <LetterNumber>} );

# No          OtherNumber


ok( "\N{SUPERSCRIPT TWO}" =~ m/^<No>$/, q{Match <No> (OtherNumber)} );
ok( "\N{SUPERSCRIPT TWO}" !~ m/^<!No>.$/, q{Don't match negated <No> (OtherNumber)} );
ok( "\N{SUPERSCRIPT TWO}" !~ m/^<-No>$/, q{Don't match inverted <No> (OtherNumber)} );
ok( "\x{92F3}"  !~ m/^<No>$/, q{Don't match unrelated <No> (OtherNumber)} );
ok( "\x{92F3}"  =~ m/^<!No>.$/, q{Match unrelated negated <No> (OtherNumber)} );
ok( "\x{92F3}"  =~ m/^<-No>$/, q{Match unrelated inverted <No> (OtherNumber)} );
ok( "\N{DIGIT ZERO}" !~ m/^<No>$/, q{Don't match related <No> (OtherNumber)} );
ok( "\N{DIGIT ZERO}" =~ m/^<!No>.$/, q{Match related negated <No> (OtherNumber)} );
ok( "\N{DIGIT ZERO}" =~ m/^<-No>$/, q{Match related inverted <No> (OtherNumber)} );
ok( "\x{92F3}\N{DIGIT ZERO}\N{SUPERSCRIPT TWO}" =~ m/<No>/, q{Match unanchored <No> (OtherNumber)} );

ok( "\N{SUPERSCRIPT TWO}" =~ m/^<OtherNumber>$/, q{Match <OtherNumber>} );
ok( "\N{SUPERSCRIPT TWO}" !~ m/^<!OtherNumber>.$/, q{Don't match negated <OtherNumber>} );
ok( "\N{SUPERSCRIPT TWO}" !~ m/^<-OtherNumber>$/, q{Don't match inverted <OtherNumber>} );
ok( "\x{5363}"  !~ m/^<OtherNumber>$/, q{Don't match unrelated <OtherNumber>} );
ok( "\x{5363}"  =~ m/^<!OtherNumber>.$/, q{Match unrelated negated <OtherNumber>} );
ok( "\x{5363}"  =~ m/^<-OtherNumber>$/, q{Match unrelated inverted <OtherNumber>} );
ok( "\x{5363}\N{SUPERSCRIPT TWO}" =~ m/<OtherNumber>/, q{Match unanchored <OtherNumber>} );

# P           Punctuation


ok( "\N{EXCLAMATION MARK}" =~ m/^<P>$/, q{Match <P> (Punctuation)} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<!P>.$/, q{Don't match negated <P> (Punctuation)} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<-P>$/, q{Don't match inverted <P> (Punctuation)} );
ok( "\x{A918}"  !~ m/^<P>$/, q{Don't match unrelated <P> (Punctuation)} );
ok( "\x{A918}"  =~ m/^<!P>.$/, q{Match unrelated negated <P> (Punctuation)} );
ok( "\x{A918}"  =~ m/^<-P>$/, q{Match unrelated inverted <P> (Punctuation)} );
ok( "\x{A918}\N{EXCLAMATION MARK}" =~ m/<P>/, q{Match unanchored <P> (Punctuation)} );

ok( "\N{EXCLAMATION MARK}" =~ m/^<Punctuation>$/, q{Match <Punctuation>} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<!Punctuation>.$/, q{Don't match negated <Punctuation>} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<-Punctuation>$/, q{Don't match inverted <Punctuation>} );
ok( "\x{CE60}"  !~ m/^<Punctuation>$/, q{Don't match unrelated <Punctuation>} );
ok( "\x{CE60}"  =~ m/^<!Punctuation>.$/, q{Match unrelated negated <Punctuation>} );
ok( "\x{CE60}"  =~ m/^<-Punctuation>$/, q{Match unrelated inverted <Punctuation>} );
ok( "\x{CE60}\N{EXCLAMATION MARK}" =~ m/<Punctuation>/, q{Match unanchored <Punctuation>} );

# Pc          ConnectorPunctuation


ok( "\N{LOW LINE}" =~ m/^<Pc>$/, q{Match <Pc> (ConnectorPunctuation)} );
ok( "\N{LOW LINE}" !~ m/^<!Pc>.$/, q{Don't match negated <Pc> (ConnectorPunctuation)} );
ok( "\N{LOW LINE}" !~ m/^<-Pc>$/, q{Don't match inverted <Pc> (ConnectorPunctuation)} );
ok( "\x{5F19}"  !~ m/^<Pc>$/, q{Don't match unrelated <Pc> (ConnectorPunctuation)} );
ok( "\x{5F19}"  =~ m/^<!Pc>.$/, q{Match unrelated negated <Pc> (ConnectorPunctuation)} );
ok( "\x{5F19}"  =~ m/^<-Pc>$/, q{Match unrelated inverted <Pc> (ConnectorPunctuation)} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<Pc>$/, q{Don't match related <Pc> (ConnectorPunctuation)} );
ok( "\N{EXCLAMATION MARK}" =~ m/^<!Pc>.$/, q{Match related negated <Pc> (ConnectorPunctuation)} );
ok( "\N{EXCLAMATION MARK}" =~ m/^<-Pc>$/, q{Match related inverted <Pc> (ConnectorPunctuation)} );
ok( "\x{5F19}\N{EXCLAMATION MARK}\N{LOW LINE}" =~ m/<Pc>/, q{Match unanchored <Pc> (ConnectorPunctuation)} );

ok( "\N{LOW LINE}" =~ m/^<ConnectorPunctuation>$/, q{Match <ConnectorPunctuation>} );
ok( "\N{LOW LINE}" !~ m/^<!ConnectorPunctuation>.$/, q{Don't match negated <ConnectorPunctuation>} );
ok( "\N{LOW LINE}" !~ m/^<-ConnectorPunctuation>$/, q{Don't match inverted <ConnectorPunctuation>} );
ok( "\N{YI SYLLABLE MGOX}"  !~ m/^<ConnectorPunctuation>$/, q{Don't match unrelated <ConnectorPunctuation>} );
ok( "\N{YI SYLLABLE MGOX}"  =~ m/^<!ConnectorPunctuation>.$/, q{Match unrelated negated <ConnectorPunctuation>} );
ok( "\N{YI SYLLABLE MGOX}"  =~ m/^<-ConnectorPunctuation>$/, q{Match unrelated inverted <ConnectorPunctuation>} );
ok( "\N{YI SYLLABLE MGOX}\N{LOW LINE}" =~ m/<ConnectorPunctuation>/, q{Match unanchored <ConnectorPunctuation>} );

# Pd          DashPunctuation


ok( "\N{HYPHEN-MINUS}" =~ m/^<Pd>$/, q{Match <Pd> (DashPunctuation)} );
ok( "\N{HYPHEN-MINUS}" !~ m/^<!Pd>.$/, q{Don't match negated <Pd> (DashPunctuation)} );
ok( "\N{HYPHEN-MINUS}" !~ m/^<-Pd>$/, q{Don't match inverted <Pd> (DashPunctuation)} );
ok( "\x{49A1}"  !~ m/^<Pd>$/, q{Don't match unrelated <Pd> (DashPunctuation)} );
ok( "\x{49A1}"  =~ m/^<!Pd>.$/, q{Match unrelated negated <Pd> (DashPunctuation)} );
ok( "\x{49A1}"  =~ m/^<-Pd>$/, q{Match unrelated inverted <Pd> (DashPunctuation)} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<Pd>$/, q{Don't match related <Pd> (DashPunctuation)} );
ok( "\N{EXCLAMATION MARK}" =~ m/^<!Pd>.$/, q{Match related negated <Pd> (DashPunctuation)} );
ok( "\N{EXCLAMATION MARK}" =~ m/^<-Pd>$/, q{Match related inverted <Pd> (DashPunctuation)} );
ok( "\x{49A1}\N{EXCLAMATION MARK}\N{HYPHEN-MINUS}" =~ m/<Pd>/, q{Match unanchored <Pd> (DashPunctuation)} );

ok( "\N{HYPHEN-MINUS}" =~ m/^<DashPunctuation>$/, q{Match <DashPunctuation>} );
ok( "\N{HYPHEN-MINUS}" !~ m/^<!DashPunctuation>.$/, q{Don't match negated <DashPunctuation>} );
ok( "\N{HYPHEN-MINUS}" !~ m/^<-DashPunctuation>$/, q{Don't match inverted <DashPunctuation>} );
ok( "\x{3C6E}"  !~ m/^<DashPunctuation>$/, q{Don't match unrelated <DashPunctuation>} );
ok( "\x{3C6E}"  =~ m/^<!DashPunctuation>.$/, q{Match unrelated negated <DashPunctuation>} );
ok( "\x{3C6E}"  =~ m/^<-DashPunctuation>$/, q{Match unrelated inverted <DashPunctuation>} );
ok( "\x{3C6E}\N{HYPHEN-MINUS}" =~ m/<DashPunctuation>/, q{Match unanchored <DashPunctuation>} );

# Ps          OpenPunctuation


ok( "\N{LEFT PARENTHESIS}" =~ m/^<Ps>$/, q{Match <Ps> (OpenPunctuation)} );
ok( "\N{LEFT PARENTHESIS}" !~ m/^<!Ps>.$/, q{Don't match negated <Ps> (OpenPunctuation)} );
ok( "\N{LEFT PARENTHESIS}" !~ m/^<-Ps>$/, q{Don't match inverted <Ps> (OpenPunctuation)} );
ok( "\x{C8A5}"  !~ m/^<Ps>$/, q{Don't match unrelated <Ps> (OpenPunctuation)} );
ok( "\x{C8A5}"  =~ m/^<!Ps>.$/, q{Match unrelated negated <Ps> (OpenPunctuation)} );
ok( "\x{C8A5}"  =~ m/^<-Ps>$/, q{Match unrelated inverted <Ps> (OpenPunctuation)} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<Ps>$/, q{Don't match related <Ps> (OpenPunctuation)} );
ok( "\N{EXCLAMATION MARK}" =~ m/^<!Ps>.$/, q{Match related negated <Ps> (OpenPunctuation)} );
ok( "\N{EXCLAMATION MARK}" =~ m/^<-Ps>$/, q{Match related inverted <Ps> (OpenPunctuation)} );
ok( "\x{C8A5}\N{EXCLAMATION MARK}\N{LEFT PARENTHESIS}" =~ m/<Ps>/, q{Match unanchored <Ps> (OpenPunctuation)} );

ok( "\N{LEFT PARENTHESIS}" =~ m/^<OpenPunctuation>$/, q{Match <OpenPunctuation>} );
ok( "\N{LEFT PARENTHESIS}" !~ m/^<!OpenPunctuation>.$/, q{Don't match negated <OpenPunctuation>} );
ok( "\N{LEFT PARENTHESIS}" !~ m/^<-OpenPunctuation>$/, q{Don't match inverted <OpenPunctuation>} );
ok( "\x{84B8}"  !~ m/^<OpenPunctuation>$/, q{Don't match unrelated <OpenPunctuation>} );
ok( "\x{84B8}"  =~ m/^<!OpenPunctuation>.$/, q{Match unrelated negated <OpenPunctuation>} );
ok( "\x{84B8}"  =~ m/^<-OpenPunctuation>$/, q{Match unrelated inverted <OpenPunctuation>} );
ok( "\x{84B8}\N{LEFT PARENTHESIS}" =~ m/<OpenPunctuation>/, q{Match unanchored <OpenPunctuation>} );

# Pe          ClosePunctuation


ok( "\N{RIGHT PARENTHESIS}" =~ m/^<Pe>$/, q{Match <Pe> (ClosePunctuation)} );
ok( "\N{RIGHT PARENTHESIS}" !~ m/^<!Pe>.$/, q{Don't match negated <Pe> (ClosePunctuation)} );
ok( "\N{RIGHT PARENTHESIS}" !~ m/^<-Pe>$/, q{Don't match inverted <Pe> (ClosePunctuation)} );
ok( "\x{BB92}"  !~ m/^<Pe>$/, q{Don't match unrelated <Pe> (ClosePunctuation)} );
ok( "\x{BB92}"  =~ m/^<!Pe>.$/, q{Match unrelated negated <Pe> (ClosePunctuation)} );
ok( "\x{BB92}"  =~ m/^<-Pe>$/, q{Match unrelated inverted <Pe> (ClosePunctuation)} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<Pe>$/, q{Don't match related <Pe> (ClosePunctuation)} );
ok( "\N{EXCLAMATION MARK}" =~ m/^<!Pe>.$/, q{Match related negated <Pe> (ClosePunctuation)} );
ok( "\N{EXCLAMATION MARK}" =~ m/^<-Pe>$/, q{Match related inverted <Pe> (ClosePunctuation)} );
ok( "\x{BB92}\N{EXCLAMATION MARK}\N{RIGHT PARENTHESIS}" =~ m/<Pe>/, q{Match unanchored <Pe> (ClosePunctuation)} );

ok( "\N{RIGHT PARENTHESIS}" =~ m/^<ClosePunctuation>$/, q{Match <ClosePunctuation>} );
ok( "\N{RIGHT PARENTHESIS}" !~ m/^<!ClosePunctuation>.$/, q{Don't match negated <ClosePunctuation>} );
ok( "\N{RIGHT PARENTHESIS}" !~ m/^<-ClosePunctuation>$/, q{Don't match inverted <ClosePunctuation>} );
ok( "\x{D55D}"  !~ m/^<ClosePunctuation>$/, q{Don't match unrelated <ClosePunctuation>} );
ok( "\x{D55D}"  =~ m/^<!ClosePunctuation>.$/, q{Match unrelated negated <ClosePunctuation>} );
ok( "\x{D55D}"  =~ m/^<-ClosePunctuation>$/, q{Match unrelated inverted <ClosePunctuation>} );
ok( "\x{D55D}\N{RIGHT PARENTHESIS}" =~ m/<ClosePunctuation>/, q{Match unanchored <ClosePunctuation>} );

# Pi          InitialPunctuation


ok( "\N{LEFT-POINTING DOUBLE ANGLE QUOTATION MARK}" =~ m/^<Pi>$/, q{Match <Pi> (InitialPunctuation)} );
ok( "\N{LEFT-POINTING DOUBLE ANGLE QUOTATION MARK}" !~ m/^<!Pi>.$/, q{Don't match negated <Pi> (InitialPunctuation)} );
ok( "\N{LEFT-POINTING DOUBLE ANGLE QUOTATION MARK}" !~ m/^<-Pi>$/, q{Don't match inverted <Pi> (InitialPunctuation)} );
ok( "\x{3A35}"  !~ m/^<Pi>$/, q{Don't match unrelated <Pi> (InitialPunctuation)} );
ok( "\x{3A35}"  =~ m/^<!Pi>.$/, q{Match unrelated negated <Pi> (InitialPunctuation)} );
ok( "\x{3A35}"  =~ m/^<-Pi>$/, q{Match unrelated inverted <Pi> (InitialPunctuation)} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<Pi>$/, q{Don't match related <Pi> (InitialPunctuation)} );
ok( "\N{EXCLAMATION MARK}" =~ m/^<!Pi>.$/, q{Match related negated <Pi> (InitialPunctuation)} );
ok( "\N{EXCLAMATION MARK}" =~ m/^<-Pi>$/, q{Match related inverted <Pi> (InitialPunctuation)} );
ok( "\x{3A35}\N{EXCLAMATION MARK}\N{LEFT-POINTING DOUBLE ANGLE QUOTATION MARK}" =~ m/<Pi>/, q{Match unanchored <Pi> (InitialPunctuation)} );

ok( "\N{LEFT-POINTING DOUBLE ANGLE QUOTATION MARK}" =~ m/^<InitialPunctuation>$/, q{Match <InitialPunctuation>} );
ok( "\N{LEFT-POINTING DOUBLE ANGLE QUOTATION MARK}" !~ m/^<!InitialPunctuation>.$/, q{Don't match negated <InitialPunctuation>} );
ok( "\N{LEFT-POINTING DOUBLE ANGLE QUOTATION MARK}" !~ m/^<-InitialPunctuation>$/, q{Don't match inverted <InitialPunctuation>} );
ok( "\x{B84F}"  !~ m/^<InitialPunctuation>$/, q{Don't match unrelated <InitialPunctuation>} );
ok( "\x{B84F}"  =~ m/^<!InitialPunctuation>.$/, q{Match unrelated negated <InitialPunctuation>} );
ok( "\x{B84F}"  =~ m/^<-InitialPunctuation>$/, q{Match unrelated inverted <InitialPunctuation>} );
ok( "\x{B84F}\N{LEFT-POINTING DOUBLE ANGLE QUOTATION MARK}" =~ m/<InitialPunctuation>/, q{Match unanchored <InitialPunctuation>} );

# Pf          FinalPunctuation


ok( "\N{RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK}" =~ m/^<Pf>$/, q{Match <Pf> (FinalPunctuation)} );
ok( "\N{RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK}" !~ m/^<!Pf>.$/, q{Don't match negated <Pf> (FinalPunctuation)} );
ok( "\N{RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK}" !~ m/^<-Pf>$/, q{Don't match inverted <Pf> (FinalPunctuation)} );
ok( "\x{27CF}"  !~ m/^<Pf>$/, q{Don't match unrelated <Pf> (FinalPunctuation)} );
ok( "\x{27CF}"  =~ m/^<!Pf>.$/, q{Match unrelated negated <Pf> (FinalPunctuation)} );
ok( "\x{27CF}"  =~ m/^<-Pf>$/, q{Match unrelated inverted <Pf> (FinalPunctuation)} );
ok( "\N{MATHEMATICAL LEFT WHITE SQUARE BRACKET}" !~ m/^<Pf>$/, q{Don't match related <Pf> (FinalPunctuation)} );
ok( "\N{MATHEMATICAL LEFT WHITE SQUARE BRACKET}" =~ m/^<!Pf>.$/, q{Match related negated <Pf> (FinalPunctuation)} );
ok( "\N{MATHEMATICAL LEFT WHITE SQUARE BRACKET}" =~ m/^<-Pf>$/, q{Match related inverted <Pf> (FinalPunctuation)} );
ok( "\x{27CF}\N{MATHEMATICAL LEFT WHITE SQUARE BRACKET}\N{RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK}" =~ m/<Pf>/, q{Match unanchored <Pf> (FinalPunctuation)} );

ok( "\N{RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK}" =~ m/^<FinalPunctuation>$/, q{Match <FinalPunctuation>} );
ok( "\N{RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK}" !~ m/^<!FinalPunctuation>.$/, q{Don't match negated <FinalPunctuation>} );
ok( "\N{RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK}" !~ m/^<-FinalPunctuation>$/, q{Don't match inverted <FinalPunctuation>} );
ok( "\x{4F65}"  !~ m/^<FinalPunctuation>$/, q{Don't match unrelated <FinalPunctuation>} );
ok( "\x{4F65}"  =~ m/^<!FinalPunctuation>.$/, q{Match unrelated negated <FinalPunctuation>} );
ok( "\x{4F65}"  =~ m/^<-FinalPunctuation>$/, q{Match unrelated inverted <FinalPunctuation>} );
ok( "\x{4F65}\N{RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK}" =~ m/<FinalPunctuation>/, q{Match unanchored <FinalPunctuation>} );

# Po          OtherPunctuation


ok( "\N{EXCLAMATION MARK}" =~ m/^<Po>$/, q{Match <Po> (OtherPunctuation)} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<!Po>.$/, q{Don't match negated <Po> (OtherPunctuation)} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<-Po>$/, q{Don't match inverted <Po> (OtherPunctuation)} );
ok( "\x{AA74}"  !~ m/^<Po>$/, q{Don't match unrelated <Po> (OtherPunctuation)} );
ok( "\x{AA74}"  =~ m/^<!Po>.$/, q{Match unrelated negated <Po> (OtherPunctuation)} );
ok( "\x{AA74}"  =~ m/^<-Po>$/, q{Match unrelated inverted <Po> (OtherPunctuation)} );
ok( "\N{LEFT PARENTHESIS}" !~ m/^<Po>$/, q{Don't match related <Po> (OtherPunctuation)} );
ok( "\N{LEFT PARENTHESIS}" =~ m/^<!Po>.$/, q{Match related negated <Po> (OtherPunctuation)} );
ok( "\N{LEFT PARENTHESIS}" =~ m/^<-Po>$/, q{Match related inverted <Po> (OtherPunctuation)} );
ok( "\x{AA74}\N{LEFT PARENTHESIS}\N{EXCLAMATION MARK}" =~ m/<Po>/, q{Match unanchored <Po> (OtherPunctuation)} );

ok( "\N{EXCLAMATION MARK}" =~ m/^<OtherPunctuation>$/, q{Match <OtherPunctuation>} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<!OtherPunctuation>.$/, q{Don't match negated <OtherPunctuation>} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<-OtherPunctuation>$/, q{Don't match inverted <OtherPunctuation>} );
ok( "\x{7DD2}"  !~ m/^<OtherPunctuation>$/, q{Don't match unrelated <OtherPunctuation>} );
ok( "\x{7DD2}"  =~ m/^<!OtherPunctuation>.$/, q{Match unrelated negated <OtherPunctuation>} );
ok( "\x{7DD2}"  =~ m/^<-OtherPunctuation>$/, q{Match unrelated inverted <OtherPunctuation>} );
ok( "\x{7DD2}\N{EXCLAMATION MARK}" =~ m/<OtherPunctuation>/, q{Match unanchored <OtherPunctuation>} );

# S           Symbol


ok( "\N{YI RADICAL QOT}" =~ m/^<S>$/, q{Match <S> (Symbol)} );
ok( "\N{YI RADICAL QOT}" !~ m/^<!S>.$/, q{Don't match negated <S> (Symbol)} );
ok( "\N{YI RADICAL QOT}" !~ m/^<-S>$/, q{Don't match inverted <S> (Symbol)} );
ok( "\x{8839}"  !~ m/^<S>$/, q{Don't match unrelated <S> (Symbol)} );
ok( "\x{8839}"  =~ m/^<!S>.$/, q{Match unrelated negated <S> (Symbol)} );
ok( "\x{8839}"  =~ m/^<-S>$/, q{Match unrelated inverted <S> (Symbol)} );
ok( "\x{8839}\N{YI RADICAL QOT}" =~ m/<S>/, q{Match unanchored <S> (Symbol)} );

ok( "\N{HEXAGRAM FOR THE CREATIVE HEAVEN}" =~ m/^<Symbol>$/, q{Match <Symbol>} );
ok( "\N{HEXAGRAM FOR THE CREATIVE HEAVEN}" !~ m/^<!Symbol>.$/, q{Don't match negated <Symbol>} );
ok( "\N{HEXAGRAM FOR THE CREATIVE HEAVEN}" !~ m/^<-Symbol>$/, q{Don't match inverted <Symbol>} );
ok( "\x{4A1C}"  !~ m/^<Symbol>$/, q{Don't match unrelated <Symbol>} );
ok( "\x{4A1C}"  =~ m/^<!Symbol>.$/, q{Match unrelated negated <Symbol>} );
ok( "\x{4A1C}"  =~ m/^<-Symbol>$/, q{Match unrelated inverted <Symbol>} );
ok( "\x{4A1C}\N{HEXAGRAM FOR THE CREATIVE HEAVEN}" =~ m/<Symbol>/, q{Match unanchored <Symbol>} );

# Sm          MathSymbol


ok( "\N{PLUS SIGN}" =~ m/^<Sm>$/, q{Match <Sm> (MathSymbol)} );
ok( "\N{PLUS SIGN}" !~ m/^<!Sm>.$/, q{Don't match negated <Sm> (MathSymbol)} );
ok( "\N{PLUS SIGN}" !~ m/^<-Sm>$/, q{Don't match inverted <Sm> (MathSymbol)} );
ok( "\x{B258}"  !~ m/^<Sm>$/, q{Don't match unrelated <Sm> (MathSymbol)} );
ok( "\x{B258}"  =~ m/^<!Sm>.$/, q{Match unrelated negated <Sm> (MathSymbol)} );
ok( "\x{B258}"  =~ m/^<-Sm>$/, q{Match unrelated inverted <Sm> (MathSymbol)} );
ok( "\N{DOLLAR SIGN}" !~ m/^<Sm>$/, q{Don't match related <Sm> (MathSymbol)} );
ok( "\N{DOLLAR SIGN}" =~ m/^<!Sm>.$/, q{Match related negated <Sm> (MathSymbol)} );
ok( "\N{DOLLAR SIGN}" =~ m/^<-Sm>$/, q{Match related inverted <Sm> (MathSymbol)} );
ok( "\x{B258}\N{DOLLAR SIGN}\N{PLUS SIGN}" =~ m/<Sm>/, q{Match unanchored <Sm> (MathSymbol)} );

ok( "\N{PLUS SIGN}" =~ m/^<MathSymbol>$/, q{Match <MathSymbol>} );
ok( "\N{PLUS SIGN}" !~ m/^<!MathSymbol>.$/, q{Don't match negated <MathSymbol>} );
ok( "\N{PLUS SIGN}" !~ m/^<-MathSymbol>$/, q{Don't match inverted <MathSymbol>} );
ok( "\x{98FF}"  !~ m/^<MathSymbol>$/, q{Don't match unrelated <MathSymbol>} );
ok( "\x{98FF}"  =~ m/^<!MathSymbol>.$/, q{Match unrelated negated <MathSymbol>} );
ok( "\x{98FF}"  =~ m/^<-MathSymbol>$/, q{Match unrelated inverted <MathSymbol>} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<MathSymbol>$/, q{Don't match related <MathSymbol>} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<!MathSymbol>.$/, q{Match related negated <MathSymbol>} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<-MathSymbol>$/, q{Match related inverted <MathSymbol>} );
ok( "\x{98FF}\N{COMBINING GRAVE ACCENT}\N{PLUS SIGN}" =~ m/<MathSymbol>/, q{Match unanchored <MathSymbol>} );

# Sc          CurrencySymbol


ok( "\N{DOLLAR SIGN}" =~ m/^<Sc>$/, q{Match <Sc> (CurrencySymbol)} );
ok( "\N{DOLLAR SIGN}" !~ m/^<!Sc>.$/, q{Don't match negated <Sc> (CurrencySymbol)} );
ok( "\N{DOLLAR SIGN}" !~ m/^<-Sc>$/, q{Don't match inverted <Sc> (CurrencySymbol)} );
ok( "\x{994C}"  !~ m/^<Sc>$/, q{Don't match unrelated <Sc> (CurrencySymbol)} );
ok( "\x{994C}"  =~ m/^<!Sc>.$/, q{Match unrelated negated <Sc> (CurrencySymbol)} );
ok( "\x{994C}"  =~ m/^<-Sc>$/, q{Match unrelated inverted <Sc> (CurrencySymbol)} );
ok( "\N{YI RADICAL QOT}" !~ m/^<Sc>$/, q{Don't match related <Sc> (CurrencySymbol)} );
ok( "\N{YI RADICAL QOT}" =~ m/^<!Sc>.$/, q{Match related negated <Sc> (CurrencySymbol)} );
ok( "\N{YI RADICAL QOT}" =~ m/^<-Sc>$/, q{Match related inverted <Sc> (CurrencySymbol)} );
ok( "\x{994C}\N{YI RADICAL QOT}\N{DOLLAR SIGN}" =~ m/<Sc>/, q{Match unanchored <Sc> (CurrencySymbol)} );

ok( "\N{DOLLAR SIGN}" =~ m/^<CurrencySymbol>$/, q{Match <CurrencySymbol>} );
ok( "\N{DOLLAR SIGN}" !~ m/^<!CurrencySymbol>.$/, q{Don't match negated <CurrencySymbol>} );
ok( "\N{DOLLAR SIGN}" !~ m/^<-CurrencySymbol>$/, q{Don't match inverted <CurrencySymbol>} );
ok( "\x{37C0}"  !~ m/^<CurrencySymbol>$/, q{Don't match unrelated <CurrencySymbol>} );
ok( "\x{37C0}"  =~ m/^<!CurrencySymbol>.$/, q{Match unrelated negated <CurrencySymbol>} );
ok( "\x{37C0}"  =~ m/^<-CurrencySymbol>$/, q{Match unrelated inverted <CurrencySymbol>} );
ok( "\x{37C0}\N{DOLLAR SIGN}" =~ m/<CurrencySymbol>/, q{Match unanchored <CurrencySymbol>} );

# Sk          ModifierSymbol


ok( "\N{CIRCUMFLEX ACCENT}" =~ m/^<Sk>$/, q{Match <Sk> (ModifierSymbol)} );
ok( "\N{CIRCUMFLEX ACCENT}" !~ m/^<!Sk>.$/, q{Don't match negated <Sk> (ModifierSymbol)} );
ok( "\N{CIRCUMFLEX ACCENT}" !~ m/^<-Sk>$/, q{Don't match inverted <Sk> (ModifierSymbol)} );
ok( "\x{4578}"  !~ m/^<Sk>$/, q{Don't match unrelated <Sk> (ModifierSymbol)} );
ok( "\x{4578}"  =~ m/^<!Sk>.$/, q{Match unrelated negated <Sk> (ModifierSymbol)} );
ok( "\x{4578}"  =~ m/^<-Sk>$/, q{Match unrelated inverted <Sk> (ModifierSymbol)} );
ok( "\N{HEXAGRAM FOR THE CREATIVE HEAVEN}" !~ m/^<Sk>$/, q{Don't match related <Sk> (ModifierSymbol)} );
ok( "\N{HEXAGRAM FOR THE CREATIVE HEAVEN}" =~ m/^<!Sk>.$/, q{Match related negated <Sk> (ModifierSymbol)} );
ok( "\N{HEXAGRAM FOR THE CREATIVE HEAVEN}" =~ m/^<-Sk>$/, q{Match related inverted <Sk> (ModifierSymbol)} );
ok( "\x{4578}\N{HEXAGRAM FOR THE CREATIVE HEAVEN}\N{CIRCUMFLEX ACCENT}" =~ m/<Sk>/, q{Match unanchored <Sk> (ModifierSymbol)} );

ok( "\N{CIRCUMFLEX ACCENT}" =~ m/^<ModifierSymbol>$/, q{Match <ModifierSymbol>} );
ok( "\N{CIRCUMFLEX ACCENT}" !~ m/^<!ModifierSymbol>.$/, q{Don't match negated <ModifierSymbol>} );
ok( "\N{CIRCUMFLEX ACCENT}" !~ m/^<-ModifierSymbol>$/, q{Don't match inverted <ModifierSymbol>} );
ok( "\x{42F1}"  !~ m/^<ModifierSymbol>$/, q{Don't match unrelated <ModifierSymbol>} );
ok( "\x{42F1}"  =~ m/^<!ModifierSymbol>.$/, q{Match unrelated negated <ModifierSymbol>} );
ok( "\x{42F1}"  =~ m/^<-ModifierSymbol>$/, q{Match unrelated inverted <ModifierSymbol>} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<ModifierSymbol>$/, q{Don't match related <ModifierSymbol>} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<!ModifierSymbol>.$/, q{Match related negated <ModifierSymbol>} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<-ModifierSymbol>$/, q{Match related inverted <ModifierSymbol>} );
ok( "\x{42F1}\N{COMBINING GRAVE ACCENT}\N{CIRCUMFLEX ACCENT}" =~ m/<ModifierSymbol>/, q{Match unanchored <ModifierSymbol>} );

# So          OtherSymbol


ok( "\N{YI RADICAL QOT}" =~ m/^<So>$/, q{Match <So> (OtherSymbol)} );
ok( "\N{YI RADICAL QOT}" !~ m/^<!So>.$/, q{Don't match negated <So> (OtherSymbol)} );
ok( "\N{YI RADICAL QOT}" !~ m/^<-So>$/, q{Don't match inverted <So> (OtherSymbol)} );
ok( "\x{83DE}"  !~ m/^<So>$/, q{Don't match unrelated <So> (OtherSymbol)} );
ok( "\x{83DE}"  =~ m/^<!So>.$/, q{Match unrelated negated <So> (OtherSymbol)} );
ok( "\x{83DE}"  =~ m/^<-So>$/, q{Match unrelated inverted <So> (OtherSymbol)} );
ok( "\N{DOLLAR SIGN}" !~ m/^<So>$/, q{Don't match related <So> (OtherSymbol)} );
ok( "\N{DOLLAR SIGN}" =~ m/^<!So>.$/, q{Match related negated <So> (OtherSymbol)} );
ok( "\N{DOLLAR SIGN}" =~ m/^<-So>$/, q{Match related inverted <So> (OtherSymbol)} );
ok( "\x{83DE}\N{DOLLAR SIGN}\N{YI RADICAL QOT}" =~ m/<So>/, q{Match unanchored <So> (OtherSymbol)} );

ok( "\N{YI RADICAL QOT}" =~ m/^<OtherSymbol>$/, q{Match <OtherSymbol>} );
ok( "\N{YI RADICAL QOT}" !~ m/^<!OtherSymbol>.$/, q{Don't match negated <OtherSymbol>} );
ok( "\N{YI RADICAL QOT}" !~ m/^<-OtherSymbol>$/, q{Don't match inverted <OtherSymbol>} );
ok( "\x{9B2C}"  !~ m/^<OtherSymbol>$/, q{Don't match unrelated <OtherSymbol>} );
ok( "\x{9B2C}"  =~ m/^<!OtherSymbol>.$/, q{Match unrelated negated <OtherSymbol>} );
ok( "\x{9B2C}"  =~ m/^<-OtherSymbol>$/, q{Match unrelated inverted <OtherSymbol>} );
ok( "\x{9B2C}\N{YI RADICAL QOT}" =~ m/<OtherSymbol>/, q{Match unanchored <OtherSymbol>} );

# Z           Separator


ok( "\N{IDEOGRAPHIC SPACE}" =~ m/^<Z>$/, q{Match <Z> (Separator)} );
ok( "\N{IDEOGRAPHIC SPACE}" !~ m/^<!Z>.$/, q{Don't match negated <Z> (Separator)} );
ok( "\N{IDEOGRAPHIC SPACE}" !~ m/^<-Z>$/, q{Don't match inverted <Z> (Separator)} );
ok( "\x{2C08}"  !~ m/^<Z>$/, q{Don't match unrelated <Z> (Separator)} );
ok( "\x{2C08}"  =~ m/^<!Z>.$/, q{Match unrelated negated <Z> (Separator)} );
ok( "\x{2C08}"  =~ m/^<-Z>$/, q{Match unrelated inverted <Z> (Separator)} );
ok( "\x{2C08}\N{IDEOGRAPHIC SPACE}" =~ m/<Z>/, q{Match unanchored <Z> (Separator)} );

ok( "\N{SPACE}" =~ m/^<Separator>$/, q{Match <Separator>} );
ok( "\N{SPACE}" !~ m/^<!Separator>.$/, q{Don't match negated <Separator>} );
ok( "\N{SPACE}" !~ m/^<-Separator>$/, q{Don't match inverted <Separator>} );
ok( "\N{YI SYLLABLE SOX}"  !~ m/^<Separator>$/, q{Don't match unrelated <Separator>} );
ok( "\N{YI SYLLABLE SOX}"  =~ m/^<!Separator>.$/, q{Match unrelated negated <Separator>} );
ok( "\N{YI SYLLABLE SOX}"  =~ m/^<-Separator>$/, q{Match unrelated inverted <Separator>} );
ok( "\N{YI RADICAL QOT}" !~ m/^<Separator>$/, q{Don't match related <Separator>} );
ok( "\N{YI RADICAL QOT}" =~ m/^<!Separator>.$/, q{Match related negated <Separator>} );
ok( "\N{YI RADICAL QOT}" =~ m/^<-Separator>$/, q{Match related inverted <Separator>} );
ok( "\N{YI SYLLABLE SOX}\N{YI RADICAL QOT}\N{SPACE}" =~ m/<Separator>/, q{Match unanchored <Separator>} );

# Zs          SpaceSeparator


ok( "\N{SPACE}" =~ m/^<Zs>$/, q{Match <Zs> (SpaceSeparator)} );
ok( "\N{SPACE}" !~ m/^<!Zs>.$/, q{Don't match negated <Zs> (SpaceSeparator)} );
ok( "\N{SPACE}" !~ m/^<-Zs>$/, q{Don't match inverted <Zs> (SpaceSeparator)} );
ok( "\x{88DD}"  !~ m/^<Zs>$/, q{Don't match unrelated <Zs> (SpaceSeparator)} );
ok( "\x{88DD}"  =~ m/^<!Zs>.$/, q{Match unrelated negated <Zs> (SpaceSeparator)} );
ok( "\x{88DD}"  =~ m/^<-Zs>$/, q{Match unrelated inverted <Zs> (SpaceSeparator)} );
ok( "\N{LINE SEPARATOR}" !~ m/^<Zs>$/, q{Don't match related <Zs> (SpaceSeparator)} );
ok( "\N{LINE SEPARATOR}" =~ m/^<!Zs>.$/, q{Match related negated <Zs> (SpaceSeparator)} );
ok( "\N{LINE SEPARATOR}" =~ m/^<-Zs>$/, q{Match related inverted <Zs> (SpaceSeparator)} );
ok( "\x{88DD}\N{LINE SEPARATOR}\N{SPACE}" =~ m/<Zs>/, q{Match unanchored <Zs> (SpaceSeparator)} );

ok( "\N{SPACE}" =~ m/^<SpaceSeparator>$/, q{Match <SpaceSeparator>} );
ok( "\N{SPACE}" !~ m/^<!SpaceSeparator>.$/, q{Don't match negated <SpaceSeparator>} );
ok( "\N{SPACE}" !~ m/^<-SpaceSeparator>$/, q{Don't match inverted <SpaceSeparator>} );
ok( "\x{C808}"  !~ m/^<SpaceSeparator>$/, q{Don't match unrelated <SpaceSeparator>} );
ok( "\x{C808}"  =~ m/^<!SpaceSeparator>.$/, q{Match unrelated negated <SpaceSeparator>} );
ok( "\x{C808}"  =~ m/^<-SpaceSeparator>$/, q{Match unrelated inverted <SpaceSeparator>} );
ok( "\N{DOLLAR SIGN}" !~ m/^<SpaceSeparator>$/, q{Don't match related <SpaceSeparator>} );
ok( "\N{DOLLAR SIGN}" =~ m/^<!SpaceSeparator>.$/, q{Match related negated <SpaceSeparator>} );
ok( "\N{DOLLAR SIGN}" =~ m/^<-SpaceSeparator>$/, q{Match related inverted <SpaceSeparator>} );
ok( "\x{C808}\N{DOLLAR SIGN}\N{SPACE}" =~ m/<SpaceSeparator>/, q{Match unanchored <SpaceSeparator>} );

# Zl          LineSeparator


ok( "\N{LINE SEPARATOR}" =~ m/^<Zl>$/, q{Match <Zl> (LineSeparator)} );
ok( "\N{LINE SEPARATOR}" !~ m/^<!Zl>.$/, q{Don't match negated <Zl> (LineSeparator)} );
ok( "\N{LINE SEPARATOR}" !~ m/^<-Zl>$/, q{Don't match inverted <Zl> (LineSeparator)} );
ok( "\x{B822}"  !~ m/^<Zl>$/, q{Don't match unrelated <Zl> (LineSeparator)} );
ok( "\x{B822}"  =~ m/^<!Zl>.$/, q{Match unrelated negated <Zl> (LineSeparator)} );
ok( "\x{B822}"  =~ m/^<-Zl>$/, q{Match unrelated inverted <Zl> (LineSeparator)} );
ok( "\N{SPACE}" !~ m/^<Zl>$/, q{Don't match related <Zl> (LineSeparator)} );
ok( "\N{SPACE}" =~ m/^<!Zl>.$/, q{Match related negated <Zl> (LineSeparator)} );
ok( "\N{SPACE}" =~ m/^<-Zl>$/, q{Match related inverted <Zl> (LineSeparator)} );
ok( "\x{B822}\N{SPACE}\N{LINE SEPARATOR}" =~ m/<Zl>/, q{Match unanchored <Zl> (LineSeparator)} );

ok( "\N{LINE SEPARATOR}" =~ m/^<LineSeparator>$/, q{Match <LineSeparator>} );
ok( "\N{LINE SEPARATOR}" !~ m/^<!LineSeparator>.$/, q{Don't match negated <LineSeparator>} );
ok( "\N{LINE SEPARATOR}" !~ m/^<-LineSeparator>$/, q{Don't match inverted <LineSeparator>} );
ok( "\x{1390}"  !~ m/^<LineSeparator>$/, q{Don't match unrelated <LineSeparator>} );
ok( "\x{1390}"  =~ m/^<!LineSeparator>.$/, q{Match unrelated negated <LineSeparator>} );
ok( "\x{1390}"  =~ m/^<-LineSeparator>$/, q{Match unrelated inverted <LineSeparator>} );
ok( "\N{CHEROKEE LETTER A}" !~ m/^<LineSeparator>$/, q{Don't match related <LineSeparator>} );
ok( "\N{CHEROKEE LETTER A}" =~ m/^<!LineSeparator>.$/, q{Match related negated <LineSeparator>} );
ok( "\N{CHEROKEE LETTER A}" =~ m/^<-LineSeparator>$/, q{Match related inverted <LineSeparator>} );
ok( "\x{1390}\N{CHEROKEE LETTER A}\N{LINE SEPARATOR}" =~ m/<LineSeparator>/, q{Match unanchored <LineSeparator>} );

# Zp          ParagraphSeparator


ok( "\N{PARAGRAPH SEPARATOR}" =~ m/^<Zp>$/, q{Match <Zp> (ParagraphSeparator)} );
ok( "\N{PARAGRAPH SEPARATOR}" !~ m/^<!Zp>.$/, q{Don't match negated <Zp> (ParagraphSeparator)} );
ok( "\N{PARAGRAPH SEPARATOR}" !~ m/^<-Zp>$/, q{Don't match inverted <Zp> (ParagraphSeparator)} );
ok( "\x{5FDE}"  !~ m/^<Zp>$/, q{Don't match unrelated <Zp> (ParagraphSeparator)} );
ok( "\x{5FDE}"  =~ m/^<!Zp>.$/, q{Match unrelated negated <Zp> (ParagraphSeparator)} );
ok( "\x{5FDE}"  =~ m/^<-Zp>$/, q{Match unrelated inverted <Zp> (ParagraphSeparator)} );
ok( "\N{SPACE}" !~ m/^<Zp>$/, q{Don't match related <Zp> (ParagraphSeparator)} );
ok( "\N{SPACE}" =~ m/^<!Zp>.$/, q{Match related negated <Zp> (ParagraphSeparator)} );
ok( "\N{SPACE}" =~ m/^<-Zp>$/, q{Match related inverted <Zp> (ParagraphSeparator)} );
ok( "\x{5FDE}\N{SPACE}\N{PARAGRAPH SEPARATOR}" =~ m/<Zp>/, q{Match unanchored <Zp> (ParagraphSeparator)} );

ok( "\N{PARAGRAPH SEPARATOR}" =~ m/^<ParagraphSeparator>$/, q{Match <ParagraphSeparator>} );
ok( "\N{PARAGRAPH SEPARATOR}" !~ m/^<!ParagraphSeparator>.$/, q{Don't match negated <ParagraphSeparator>} );
ok( "\N{PARAGRAPH SEPARATOR}" !~ m/^<-ParagraphSeparator>$/, q{Don't match inverted <ParagraphSeparator>} );
ok( "\x{345B}"  !~ m/^<ParagraphSeparator>$/, q{Don't match unrelated <ParagraphSeparator>} );
ok( "\x{345B}"  =~ m/^<!ParagraphSeparator>.$/, q{Match unrelated negated <ParagraphSeparator>} );
ok( "\x{345B}"  =~ m/^<-ParagraphSeparator>$/, q{Match unrelated inverted <ParagraphSeparator>} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<ParagraphSeparator>$/, q{Don't match related <ParagraphSeparator>} );
ok( "\N{EXCLAMATION MARK}" =~ m/^<!ParagraphSeparator>.$/, q{Match related negated <ParagraphSeparator>} );
ok( "\N{EXCLAMATION MARK}" =~ m/^<-ParagraphSeparator>$/, q{Match related inverted <ParagraphSeparator>} );
ok( "\x{345B}\N{EXCLAMATION MARK}\N{PARAGRAPH SEPARATOR}" =~ m/<ParagraphSeparator>/, q{Match unanchored <ParagraphSeparator>} );

# C           Other


ok( "\x{9FA6}" =~ m/^<C>$/, q{Match <C> (Other)} );
ok( "\x{9FA6}" !~ m/^<!C>.$/, q{Don't match negated <C> (Other)} );
ok( "\x{9FA6}" !~ m/^<-C>$/, q{Don't match inverted <C> (Other)} );
ok( "\x{6A3F}"  !~ m/^<C>$/, q{Don't match unrelated <C> (Other)} );
ok( "\x{6A3F}"  =~ m/^<!C>.$/, q{Match unrelated negated <C> (Other)} );
ok( "\x{6A3F}"  =~ m/^<-C>$/, q{Match unrelated inverted <C> (Other)} );
ok( "\x{6A3F}\x{9FA6}" =~ m/<C>/, q{Match unanchored <C> (Other)} );

ok( "\x{A679}" =~ m/^<Other>$/, q{Match <Other>} );
ok( "\x{A679}" !~ m/^<!Other>.$/, q{Don't match negated <Other>} );
ok( "\x{A679}" !~ m/^<-Other>$/, q{Don't match inverted <Other>} );
ok( "\x{AC00}"  !~ m/^<Other>$/, q{Don't match unrelated <Other>} );
ok( "\x{AC00}"  =~ m/^<!Other>.$/, q{Match unrelated negated <Other>} );
ok( "\x{AC00}"  =~ m/^<-Other>$/, q{Match unrelated inverted <Other>} );
ok( "\x{AC00}\x{A679}" =~ m/<Other>/, q{Match unanchored <Other>} );

# Cc          Control


ok( "\N{NULL}" =~ m/^<Cc>$/, q{Match <Cc> (Control)} );
ok( "\N{NULL}" !~ m/^<!Cc>.$/, q{Don't match negated <Cc> (Control)} );
ok( "\N{NULL}" !~ m/^<-Cc>$/, q{Don't match inverted <Cc> (Control)} );
ok( "\x{0A7A}"  !~ m/^<Cc>$/, q{Don't match unrelated <Cc> (Control)} );
ok( "\x{0A7A}"  =~ m/^<!Cc>.$/, q{Match unrelated negated <Cc> (Control)} );
ok( "\x{0A7A}"  =~ m/^<-Cc>$/, q{Match unrelated inverted <Cc> (Control)} );
ok( "\x{0A7A}" !~ m/^<Cc>$/, q{Don't match related <Cc> (Control)} );
ok( "\x{0A7A}" =~ m/^<!Cc>.$/, q{Match related negated <Cc> (Control)} );
ok( "\x{0A7A}" =~ m/^<-Cc>$/, q{Match related inverted <Cc> (Control)} );
ok( "\x{0A7A}\x{0A7A}\N{NULL}" =~ m/<Cc>/, q{Match unanchored <Cc> (Control)} );

ok( "\N{NULL}" =~ m/^<Control>$/, q{Match <Control>} );
ok( "\N{NULL}" !~ m/^<!Control>.$/, q{Don't match negated <Control>} );
ok( "\N{NULL}" !~ m/^<-Control>$/, q{Don't match inverted <Control>} );
ok( "\x{4886}"  !~ m/^<Control>$/, q{Don't match unrelated <Control>} );
ok( "\x{4886}"  =~ m/^<!Control>.$/, q{Match unrelated negated <Control>} );
ok( "\x{4886}"  =~ m/^<-Control>$/, q{Match unrelated inverted <Control>} );
ok( "\x{4DB6}" !~ m/^<Control>$/, q{Don't match related <Control>} );
ok( "\x{4DB6}" =~ m/^<!Control>.$/, q{Match related negated <Control>} );
ok( "\x{4DB6}" =~ m/^<-Control>$/, q{Match related inverted <Control>} );
ok( "\x{4886}\x{4DB6}\N{NULL}" =~ m/<Control>/, q{Match unanchored <Control>} );

# Cf          Format


ok( "\N{SOFT HYPHEN}" =~ m/^<Cf>$/, q{Match <Cf> (Format)} );
ok( "\N{SOFT HYPHEN}" !~ m/^<!Cf>.$/, q{Don't match negated <Cf> (Format)} );
ok( "\N{SOFT HYPHEN}" !~ m/^<-Cf>$/, q{Don't match inverted <Cf> (Format)} );
ok( "\x{77B8}"  !~ m/^<Cf>$/, q{Don't match unrelated <Cf> (Format)} );
ok( "\x{77B8}"  =~ m/^<!Cf>.$/, q{Match unrelated negated <Cf> (Format)} );
ok( "\x{77B8}"  =~ m/^<-Cf>$/, q{Match unrelated inverted <Cf> (Format)} );
ok( "\x{9FA6}" !~ m/^<Cf>$/, q{Don't match related <Cf> (Format)} );
ok( "\x{9FA6}" =~ m/^<!Cf>.$/, q{Match related negated <Cf> (Format)} );
ok( "\x{9FA6}" =~ m/^<-Cf>$/, q{Match related inverted <Cf> (Format)} );
ok( "\x{77B8}\x{9FA6}\N{SOFT HYPHEN}" =~ m/<Cf>/, q{Match unanchored <Cf> (Format)} );

ok( "\N{KHMER VOWEL INHERENT AQ}" =~ m/^<Format>$/, q{Match <Format>} );
ok( "\N{KHMER VOWEL INHERENT AQ}" !~ m/^<!Format>.$/, q{Don't match negated <Format>} );
ok( "\N{KHMER VOWEL INHERENT AQ}" !~ m/^<-Format>$/, q{Don't match inverted <Format>} );
ok( "\N{DEVANAGARI VOWEL SIGN AU}"  !~ m/^<Format>$/, q{Don't match unrelated <Format>} );
ok( "\N{DEVANAGARI VOWEL SIGN AU}"  =~ m/^<!Format>.$/, q{Match unrelated negated <Format>} );
ok( "\N{DEVANAGARI VOWEL SIGN AU}"  =~ m/^<-Format>$/, q{Match unrelated inverted <Format>} );
ok( "\N{DEVANAGARI VOWEL SIGN AU}\N{KHMER VOWEL INHERENT AQ}" =~ m/<Format>/, q{Match unanchored <Format>} );

# BidiL       # Left-to-Right


ok( "\N{YI SYLLABLE IT}" =~ m/^<BidiL>$/, q{Match (Left-to-Right)} );
ok( "\N{YI SYLLABLE IT}" !~ m/^<!BidiL>.$/, q{Don't match negated (Left-to-Right)} );
ok( "\N{YI SYLLABLE IT}" !~ m/^<-BidiL>$/, q{Don't match inverted (Left-to-Right)} );
ok( "\x{5A87}"  !~ m/^<BidiL>$/, q{Don't match unrelated (Left-to-Right)} );
ok( "\x{5A87}"  =~ m/^<!BidiL>.$/, q{Match unrelated negated (Left-to-Right)} );
ok( "\x{5A87}"  =~ m/^<-BidiL>$/, q{Match unrelated inverted (Left-to-Right)} );
ok( "\x{5A87}\N{YI SYLLABLE IT}" =~ m/<BidiL>/, q{Match unanchored (Left-to-Right)} );

# BidiEN      # European Number


ok( "\N{DIGIT ZERO}" =~ m/^<BidiEN>$/, q{Match (European Number)} );
ok( "\N{DIGIT ZERO}" !~ m/^<!BidiEN>.$/, q{Don't match negated (European Number)} );
ok( "\N{DIGIT ZERO}" !~ m/^<-BidiEN>$/, q{Don't match inverted (European Number)} );
ok( "\x{AFFB}"  !~ m/^<BidiEN>$/, q{Don't match unrelated (European Number)} );
ok( "\x{AFFB}"  =~ m/^<!BidiEN>.$/, q{Match unrelated negated (European Number)} );
ok( "\x{AFFB}"  =~ m/^<-BidiEN>$/, q{Match unrelated inverted (European Number)} );
ok( "\x{AFFB}\N{DIGIT ZERO}" =~ m/<BidiEN>/, q{Match unanchored (European Number)} );

# BidiES      # European Number Separator


ok( "\N{SOLIDUS}" =~ m/^<BidiES>$/, q{Match (European Number Separator)} );
ok( "\N{SOLIDUS}" !~ m/^<!BidiES>.$/, q{Don't match negated (European Number Separator)} );
ok( "\N{SOLIDUS}" !~ m/^<-BidiES>$/, q{Don't match inverted (European Number Separator)} );
ok( "\x{7B89}"  !~ m/^<BidiES>$/, q{Don't match unrelated (European Number Separator)} );
ok( "\x{7B89}"  =~ m/^<!BidiES>.$/, q{Match unrelated negated (European Number Separator)} );
ok( "\x{7B89}"  =~ m/^<-BidiES>$/, q{Match unrelated inverted (European Number Separator)} );
ok( "\x{7B89}\N{SOLIDUS}" =~ m/<BidiES>/, q{Match unanchored (European Number Separator)} );

# BidiET      # European Number Terminator


ok( "\N{NUMBER SIGN}" =~ m/^<BidiET>$/, q{Match (European Number Terminator)} );
ok( "\N{NUMBER SIGN}" !~ m/^<!BidiET>.$/, q{Don't match negated (European Number Terminator)} );
ok( "\N{NUMBER SIGN}" !~ m/^<-BidiET>$/, q{Don't match inverted (European Number Terminator)} );
ok( "\x{6780}"  !~ m/^<BidiET>$/, q{Don't match unrelated (European Number Terminator)} );
ok( "\x{6780}"  =~ m/^<!BidiET>.$/, q{Match unrelated negated (European Number Terminator)} );
ok( "\x{6780}"  =~ m/^<-BidiET>$/, q{Match unrelated inverted (European Number Terminator)} );
ok( "\x{6780}\N{NUMBER SIGN}" =~ m/<BidiET>/, q{Match unanchored (European Number Terminator)} );

# BidiWS      # Whitespace


ok( "\N{FORM FEED (FF)}" =~ m/^<BidiWS>$/, q{Match (Whitespace)} );
ok( "\N{FORM FEED (FF)}" !~ m/^<!BidiWS>.$/, q{Don't match negated (Whitespace)} );
ok( "\N{FORM FEED (FF)}" !~ m/^<-BidiWS>$/, q{Don't match inverted (Whitespace)} );
ok( "\x{6CF9}"  !~ m/^<BidiWS>$/, q{Don't match unrelated (Whitespace)} );
ok( "\x{6CF9}"  =~ m/^<!BidiWS>.$/, q{Match unrelated negated (Whitespace)} );
ok( "\x{6CF9}"  =~ m/^<-BidiWS>$/, q{Match unrelated inverted (Whitespace)} );
ok( "\x{6CF9}\N{FORM FEED (FF)}" =~ m/<BidiWS>/, q{Match unanchored (Whitespace)} );

# Arabic


ok( "\N{ARABIC LETTER HAMZA}" =~ m/^<Arabic>$/, q{Match <Arabic>} );
ok( "\N{ARABIC LETTER HAMZA}" !~ m/^<!Arabic>.$/, q{Don't match negated <Arabic>} );
ok( "\N{ARABIC LETTER HAMZA}" !~ m/^<-Arabic>$/, q{Don't match inverted <Arabic>} );
ok( "\x{A649}"  !~ m/^<Arabic>$/, q{Don't match unrelated <Arabic>} );
ok( "\x{A649}"  =~ m/^<!Arabic>.$/, q{Match unrelated negated <Arabic>} );
ok( "\x{A649}"  =~ m/^<-Arabic>$/, q{Match unrelated inverted <Arabic>} );
ok( "\x{A649}\N{ARABIC LETTER HAMZA}" =~ m/<Arabic>/, q{Match unanchored <Arabic>} );

# Armenian


ok( "\N{ARMENIAN CAPITAL LETTER AYB}" =~ m/^<Armenian>$/, q{Match <Armenian>} );
ok( "\N{ARMENIAN CAPITAL LETTER AYB}" !~ m/^<!Armenian>.$/, q{Don't match negated <Armenian>} );
ok( "\N{ARMENIAN CAPITAL LETTER AYB}" !~ m/^<-Armenian>$/, q{Don't match inverted <Armenian>} );
ok( "\x{CBFF}"  !~ m/^<Armenian>$/, q{Don't match unrelated <Armenian>} );
ok( "\x{CBFF}"  =~ m/^<!Armenian>.$/, q{Match unrelated negated <Armenian>} );
ok( "\x{CBFF}"  =~ m/^<-Armenian>$/, q{Match unrelated inverted <Armenian>} );
ok( "\x{CBFF}\N{ARMENIAN CAPITAL LETTER AYB}" =~ m/<Armenian>/, q{Match unanchored <Armenian>} );

# Bengali


ok( "\N{BENGALI SIGN CANDRABINDU}" =~ m/^<Bengali>$/, q{Match <Bengali>} );
ok( "\N{BENGALI SIGN CANDRABINDU}" !~ m/^<!Bengali>.$/, q{Don't match negated <Bengali>} );
ok( "\N{BENGALI SIGN CANDRABINDU}" !~ m/^<-Bengali>$/, q{Don't match inverted <Bengali>} );
ok( "\x{D1E8}"  !~ m/^<Bengali>$/, q{Don't match unrelated <Bengali>} );
ok( "\x{D1E8}"  =~ m/^<!Bengali>.$/, q{Match unrelated negated <Bengali>} );
ok( "\x{D1E8}"  =~ m/^<-Bengali>$/, q{Match unrelated inverted <Bengali>} );
ok( "\x{D1E8}\N{BENGALI SIGN CANDRABINDU}" =~ m/<Bengali>/, q{Match unanchored <Bengali>} );

# Bopomofo


ok( "\N{BOPOMOFO LETTER B}" =~ m/^<Bopomofo>$/, q{Match <Bopomofo>} );
ok( "\N{BOPOMOFO LETTER B}" !~ m/^<!Bopomofo>.$/, q{Don't match negated <Bopomofo>} );
ok( "\N{BOPOMOFO LETTER B}" !~ m/^<-Bopomofo>$/, q{Don't match inverted <Bopomofo>} );
ok( "\x{B093}"  !~ m/^<Bopomofo>$/, q{Don't match unrelated <Bopomofo>} );
ok( "\x{B093}"  =~ m/^<!Bopomofo>.$/, q{Match unrelated negated <Bopomofo>} );
ok( "\x{B093}"  =~ m/^<-Bopomofo>$/, q{Match unrelated inverted <Bopomofo>} );
ok( "\x{B093}\N{BOPOMOFO LETTER B}" =~ m/<Bopomofo>/, q{Match unanchored <Bopomofo>} );

# Buhid


ok( "\N{BUHID LETTER A}" =~ m/^<Buhid>$/, q{Match <Buhid>} );
ok( "\N{BUHID LETTER A}" !~ m/^<!Buhid>.$/, q{Don't match negated <Buhid>} );
ok( "\N{BUHID LETTER A}" !~ m/^<-Buhid>$/, q{Don't match inverted <Buhid>} );
ok( "\x{C682}"  !~ m/^<Buhid>$/, q{Don't match unrelated <Buhid>} );
ok( "\x{C682}"  =~ m/^<!Buhid>.$/, q{Match unrelated negated <Buhid>} );
ok( "\x{C682}"  =~ m/^<-Buhid>$/, q{Match unrelated inverted <Buhid>} );
ok( "\x{C682}\N{BUHID LETTER A}" =~ m/<Buhid>/, q{Match unanchored <Buhid>} );

# CanadianAboriginal


ok( "\N{CANADIAN SYLLABICS E}" =~ m/^<CanadianAboriginal>$/, q{Match <CanadianAboriginal>} );
ok( "\N{CANADIAN SYLLABICS E}" !~ m/^<!CanadianAboriginal>.$/, q{Don't match negated <CanadianAboriginal>} );
ok( "\N{CANADIAN SYLLABICS E}" !~ m/^<-CanadianAboriginal>$/, q{Don't match inverted <CanadianAboriginal>} );
ok( "\x{888B}"  !~ m/^<CanadianAboriginal>$/, q{Don't match unrelated <CanadianAboriginal>} );
ok( "\x{888B}"  =~ m/^<!CanadianAboriginal>.$/, q{Match unrelated negated <CanadianAboriginal>} );
ok( "\x{888B}"  =~ m/^<-CanadianAboriginal>$/, q{Match unrelated inverted <CanadianAboriginal>} );
ok( "\x{9FA6}" !~ m/^<CanadianAboriginal>$/, q{Don't match related <CanadianAboriginal>} );
ok( "\x{9FA6}" =~ m/^<!CanadianAboriginal>.$/, q{Match related negated <CanadianAboriginal>} );
ok( "\x{9FA6}" =~ m/^<-CanadianAboriginal>$/, q{Match related inverted <CanadianAboriginal>} );
ok( "\x{888B}\x{9FA6}\N{CANADIAN SYLLABICS E}" =~ m/<CanadianAboriginal>/, q{Match unanchored <CanadianAboriginal>} );

# Cherokee


ok( "\N{CHEROKEE LETTER A}" =~ m/^<Cherokee>$/, q{Match <Cherokee>} );
ok( "\N{CHEROKEE LETTER A}" !~ m/^<!Cherokee>.$/, q{Don't match negated <Cherokee>} );
ok( "\N{CHEROKEE LETTER A}" !~ m/^<-Cherokee>$/, q{Don't match inverted <Cherokee>} );
ok( "\x{8260}"  !~ m/^<Cherokee>$/, q{Don't match unrelated <Cherokee>} );
ok( "\x{8260}"  =~ m/^<!Cherokee>.$/, q{Match unrelated negated <Cherokee>} );
ok( "\x{8260}"  =~ m/^<-Cherokee>$/, q{Match unrelated inverted <Cherokee>} );
ok( "\x{9FA6}" !~ m/^<Cherokee>$/, q{Don't match related <Cherokee>} );
ok( "\x{9FA6}" =~ m/^<!Cherokee>.$/, q{Match related negated <Cherokee>} );
ok( "\x{9FA6}" =~ m/^<-Cherokee>$/, q{Match related inverted <Cherokee>} );
ok( "\x{8260}\x{9FA6}\N{CHEROKEE LETTER A}" =~ m/<Cherokee>/, q{Match unanchored <Cherokee>} );

# Cyrillic


ok( "\N{CYRILLIC CAPITAL LETTER IE WITH GRAVE}" =~ m/^<Cyrillic>$/, q{Match <Cyrillic>} );
ok( "\N{CYRILLIC CAPITAL LETTER IE WITH GRAVE}" !~ m/^<!Cyrillic>.$/, q{Don't match negated <Cyrillic>} );
ok( "\N{CYRILLIC CAPITAL LETTER IE WITH GRAVE}" !~ m/^<-Cyrillic>$/, q{Don't match inverted <Cyrillic>} );
ok( "\x{B7DF}"  !~ m/^<Cyrillic>$/, q{Don't match unrelated <Cyrillic>} );
ok( "\x{B7DF}"  =~ m/^<!Cyrillic>.$/, q{Match unrelated negated <Cyrillic>} );
ok( "\x{B7DF}"  =~ m/^<-Cyrillic>$/, q{Match unrelated inverted <Cyrillic>} );
ok( "\x{D7A4}" !~ m/^<Cyrillic>$/, q{Don't match related <Cyrillic>} );
ok( "\x{D7A4}" =~ m/^<!Cyrillic>.$/, q{Match related negated <Cyrillic>} );
ok( "\x{D7A4}" =~ m/^<-Cyrillic>$/, q{Match related inverted <Cyrillic>} );
ok( "\x{B7DF}\x{D7A4}\N{CYRILLIC CAPITAL LETTER IE WITH GRAVE}" =~ m/<Cyrillic>/, q{Match unanchored <Cyrillic>} );

# Deseret


ok( "\x{A8A0}"  !~ m/^<Deseret>$/, q{Don't match unrelated <Deseret>} );
ok( "\x{A8A0}"  =~ m/^<!Deseret>.$/, q{Match unrelated negated <Deseret>} );
ok( "\x{A8A0}"  =~ m/^<-Deseret>$/, q{Match unrelated inverted <Deseret>} );

# Devanagari


ok( "\N{DEVANAGARI SIGN CANDRABINDU}" =~ m/^<Devanagari>$/, q{Match <Devanagari>} );
ok( "\N{DEVANAGARI SIGN CANDRABINDU}" !~ m/^<!Devanagari>.$/, q{Don't match negated <Devanagari>} );
ok( "\N{DEVANAGARI SIGN CANDRABINDU}" !~ m/^<-Devanagari>$/, q{Don't match inverted <Devanagari>} );
ok( "\x{D291}"  !~ m/^<Devanagari>$/, q{Don't match unrelated <Devanagari>} );
ok( "\x{D291}"  =~ m/^<!Devanagari>.$/, q{Match unrelated negated <Devanagari>} );
ok( "\x{D291}"  =~ m/^<-Devanagari>$/, q{Match unrelated inverted <Devanagari>} );
ok( "\x{D291}\N{DEVANAGARI SIGN CANDRABINDU}" =~ m/<Devanagari>/, q{Match unanchored <Devanagari>} );

# Ethiopic


ok( "\N{ETHIOPIC SYLLABLE HA}" =~ m/^<Ethiopic>$/, q{Match <Ethiopic>} );
ok( "\N{ETHIOPIC SYLLABLE HA}" !~ m/^<!Ethiopic>.$/, q{Don't match negated <Ethiopic>} );
ok( "\N{ETHIOPIC SYLLABLE HA}" !~ m/^<-Ethiopic>$/, q{Don't match inverted <Ethiopic>} );
ok( "\x{A9FA}"  !~ m/^<Ethiopic>$/, q{Don't match unrelated <Ethiopic>} );
ok( "\x{A9FA}"  =~ m/^<!Ethiopic>.$/, q{Match unrelated negated <Ethiopic>} );
ok( "\x{A9FA}"  =~ m/^<-Ethiopic>$/, q{Match unrelated inverted <Ethiopic>} );
ok( "\x{A9FA}\N{ETHIOPIC SYLLABLE HA}" =~ m/<Ethiopic>/, q{Match unanchored <Ethiopic>} );

# Georgian


ok( "\N{GEORGIAN CAPITAL LETTER AN}" =~ m/^<Georgian>$/, q{Match <Georgian>} );
ok( "\N{GEORGIAN CAPITAL LETTER AN}" !~ m/^<!Georgian>.$/, q{Don't match negated <Georgian>} );
ok( "\N{GEORGIAN CAPITAL LETTER AN}" !~ m/^<-Georgian>$/, q{Don't match inverted <Georgian>} );
ok( "\x{BBC9}"  !~ m/^<Georgian>$/, q{Don't match unrelated <Georgian>} );
ok( "\x{BBC9}"  =~ m/^<!Georgian>.$/, q{Match unrelated negated <Georgian>} );
ok( "\x{BBC9}"  =~ m/^<-Georgian>$/, q{Match unrelated inverted <Georgian>} );
ok( "\x{BBC9}\N{GEORGIAN CAPITAL LETTER AN}" =~ m/<Georgian>/, q{Match unanchored <Georgian>} );

# Gothic


ok( "\x{5888}"  !~ m/^<Gothic>$/, q{Don't match unrelated <Gothic>} );
ok( "\x{5888}"  =~ m/^<!Gothic>.$/, q{Match unrelated negated <Gothic>} );
ok( "\x{5888}"  =~ m/^<-Gothic>$/, q{Match unrelated inverted <Gothic>} );

# Greek


ok( "\N{GREEK LETTER SMALL CAPITAL GAMMA}" =~ m/^<Greek>$/, q{Match <Greek>} );
ok( "\N{GREEK LETTER SMALL CAPITAL GAMMA}" !~ m/^<!Greek>.$/, q{Don't match negated <Greek>} );
ok( "\N{GREEK LETTER SMALL CAPITAL GAMMA}" !~ m/^<-Greek>$/, q{Don't match inverted <Greek>} );
ok( "\N{ETHIOPIC SYLLABLE KEE}"  !~ m/^<Greek>$/, q{Don't match unrelated <Greek>} );
ok( "\N{ETHIOPIC SYLLABLE KEE}"  =~ m/^<!Greek>.$/, q{Match unrelated negated <Greek>} );
ok( "\N{ETHIOPIC SYLLABLE KEE}"  =~ m/^<-Greek>$/, q{Match unrelated inverted <Greek>} );
ok( "\N{ETHIOPIC SYLLABLE KEE}\N{GREEK LETTER SMALL CAPITAL GAMMA}" =~ m/<Greek>/, q{Match unanchored <Greek>} );

# Gujarati


ok( "\N{GUJARATI SIGN CANDRABINDU}" =~ m/^<Gujarati>$/, q{Match <Gujarati>} );
ok( "\N{GUJARATI SIGN CANDRABINDU}" !~ m/^<!Gujarati>.$/, q{Don't match negated <Gujarati>} );
ok( "\N{GUJARATI SIGN CANDRABINDU}" !~ m/^<-Gujarati>$/, q{Don't match inverted <Gujarati>} );
ok( "\x{D108}"  !~ m/^<Gujarati>$/, q{Don't match unrelated <Gujarati>} );
ok( "\x{D108}"  =~ m/^<!Gujarati>.$/, q{Match unrelated negated <Gujarati>} );
ok( "\x{D108}"  =~ m/^<-Gujarati>$/, q{Match unrelated inverted <Gujarati>} );
ok( "\x{D108}\N{GUJARATI SIGN CANDRABINDU}" =~ m/<Gujarati>/, q{Match unanchored <Gujarati>} );

# Gurmukhi


ok( "\N{GURMUKHI SIGN BINDI}" =~ m/^<Gurmukhi>$/, q{Match <Gurmukhi>} );
ok( "\N{GURMUKHI SIGN BINDI}" !~ m/^<!Gurmukhi>.$/, q{Don't match negated <Gurmukhi>} );
ok( "\N{GURMUKHI SIGN BINDI}" !~ m/^<-Gurmukhi>$/, q{Don't match inverted <Gurmukhi>} );
ok( "\x{5E05}"  !~ m/^<Gurmukhi>$/, q{Don't match unrelated <Gurmukhi>} );
ok( "\x{5E05}"  =~ m/^<!Gurmukhi>.$/, q{Match unrelated negated <Gurmukhi>} );
ok( "\x{5E05}"  =~ m/^<-Gurmukhi>$/, q{Match unrelated inverted <Gurmukhi>} );
ok( "\x{5E05}\N{GURMUKHI SIGN BINDI}" =~ m/<Gurmukhi>/, q{Match unanchored <Gurmukhi>} );

# Han


ok( "\N{CJK RADICAL REPEAT}" =~ m/^<Han>$/, q{Match <Han>} );
ok( "\N{CJK RADICAL REPEAT}" !~ m/^<!Han>.$/, q{Don't match negated <Han>} );
ok( "\N{CJK RADICAL REPEAT}" !~ m/^<-Han>$/, q{Don't match inverted <Han>} );
ok( "\N{CANADIAN SYLLABICS KAA}"  !~ m/^<Han>$/, q{Don't match unrelated <Han>} );
ok( "\N{CANADIAN SYLLABICS KAA}"  =~ m/^<!Han>.$/, q{Match unrelated negated <Han>} );
ok( "\N{CANADIAN SYLLABICS KAA}"  =~ m/^<-Han>$/, q{Match unrelated inverted <Han>} );
ok( "\N{CANADIAN SYLLABICS KAA}\N{CJK RADICAL REPEAT}" =~ m/<Han>/, q{Match unanchored <Han>} );

# Hangul


ok( "\x{AC00}" =~ m/^<Hangul>$/, q{Match <Hangul>} );
ok( "\x{AC00}" !~ m/^<!Hangul>.$/, q{Don't match negated <Hangul>} );
ok( "\x{AC00}" !~ m/^<-Hangul>$/, q{Don't match inverted <Hangul>} );
ok( "\x{9583}"  !~ m/^<Hangul>$/, q{Don't match unrelated <Hangul>} );
ok( "\x{9583}"  =~ m/^<!Hangul>.$/, q{Match unrelated negated <Hangul>} );
ok( "\x{9583}"  =~ m/^<-Hangul>$/, q{Match unrelated inverted <Hangul>} );
ok( "\x{9583}\x{AC00}" =~ m/<Hangul>/, q{Match unanchored <Hangul>} );

# Hanunoo


ok( "\N{HANUNOO LETTER A}" =~ m/^<Hanunoo>$/, q{Match <Hanunoo>} );
ok( "\N{HANUNOO LETTER A}" !~ m/^<!Hanunoo>.$/, q{Don't match negated <Hanunoo>} );
ok( "\N{HANUNOO LETTER A}" !~ m/^<-Hanunoo>$/, q{Don't match inverted <Hanunoo>} );
ok( "\x{7625}"  !~ m/^<Hanunoo>$/, q{Don't match unrelated <Hanunoo>} );
ok( "\x{7625}"  =~ m/^<!Hanunoo>.$/, q{Match unrelated negated <Hanunoo>} );
ok( "\x{7625}"  =~ m/^<-Hanunoo>$/, q{Match unrelated inverted <Hanunoo>} );
ok( "\x{7625}\N{HANUNOO LETTER A}" =~ m/<Hanunoo>/, q{Match unanchored <Hanunoo>} );

# Hebrew


ok( "\N{HEBREW LETTER ALEF}" =~ m/^<Hebrew>$/, q{Match <Hebrew>} );
ok( "\N{HEBREW LETTER ALEF}" !~ m/^<!Hebrew>.$/, q{Don't match negated <Hebrew>} );
ok( "\N{HEBREW LETTER ALEF}" !~ m/^<-Hebrew>$/, q{Don't match inverted <Hebrew>} );
ok( "\N{YI SYLLABLE SSIT}"  !~ m/^<Hebrew>$/, q{Don't match unrelated <Hebrew>} );
ok( "\N{YI SYLLABLE SSIT}"  =~ m/^<!Hebrew>.$/, q{Match unrelated negated <Hebrew>} );
ok( "\N{YI SYLLABLE SSIT}"  =~ m/^<-Hebrew>$/, q{Match unrelated inverted <Hebrew>} );
ok( "\N{YI SYLLABLE SSIT}\N{HEBREW LETTER ALEF}" =~ m/<Hebrew>/, q{Match unanchored <Hebrew>} );

# Hiragana


ok( "\N{HIRAGANA LETTER SMALL A}" =~ m/^<Hiragana>$/, q{Match <Hiragana>} );
ok( "\N{HIRAGANA LETTER SMALL A}" !~ m/^<!Hiragana>.$/, q{Don't match negated <Hiragana>} );
ok( "\N{HIRAGANA LETTER SMALL A}" !~ m/^<-Hiragana>$/, q{Don't match inverted <Hiragana>} );
ok( "\N{CANADIAN SYLLABICS Y}"  !~ m/^<Hiragana>$/, q{Don't match unrelated <Hiragana>} );
ok( "\N{CANADIAN SYLLABICS Y}"  =~ m/^<!Hiragana>.$/, q{Match unrelated negated <Hiragana>} );
ok( "\N{CANADIAN SYLLABICS Y}"  =~ m/^<-Hiragana>$/, q{Match unrelated inverted <Hiragana>} );
ok( "\N{CANADIAN SYLLABICS Y}\N{HIRAGANA LETTER SMALL A}" =~ m/<Hiragana>/, q{Match unanchored <Hiragana>} );

# Inherited


ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<Inherited>$/, q{Match <Inherited>} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<!Inherited>.$/, q{Don't match negated <Inherited>} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<-Inherited>$/, q{Don't match inverted <Inherited>} );
ok( "\x{75FA}"  !~ m/^<Inherited>$/, q{Don't match unrelated <Inherited>} );
ok( "\x{75FA}"  =~ m/^<!Inherited>.$/, q{Match unrelated negated <Inherited>} );
ok( "\x{75FA}"  =~ m/^<-Inherited>$/, q{Match unrelated inverted <Inherited>} );
ok( "\x{75FA}\N{COMBINING GRAVE ACCENT}" =~ m/<Inherited>/, q{Match unanchored <Inherited>} );

# Kannada


ok( "\N{KANNADA SIGN ANUSVARA}" =~ m/^<Kannada>$/, q{Match <Kannada>} );
ok( "\N{KANNADA SIGN ANUSVARA}" !~ m/^<!Kannada>.$/, q{Don't match negated <Kannada>} );
ok( "\N{KANNADA SIGN ANUSVARA}" !~ m/^<-Kannada>$/, q{Don't match inverted <Kannada>} );
ok( "\x{C1DF}"  !~ m/^<Kannada>$/, q{Don't match unrelated <Kannada>} );
ok( "\x{C1DF}"  =~ m/^<!Kannada>.$/, q{Match unrelated negated <Kannada>} );
ok( "\x{C1DF}"  =~ m/^<-Kannada>$/, q{Match unrelated inverted <Kannada>} );
ok( "\x{C1DF}\N{KANNADA SIGN ANUSVARA}" =~ m/<Kannada>/, q{Match unanchored <Kannada>} );

# Katakana


ok( "\N{KATAKANA LETTER SMALL A}" =~ m/^<Katakana>$/, q{Match <Katakana>} );
ok( "\N{KATAKANA LETTER SMALL A}" !~ m/^<!Katakana>.$/, q{Don't match negated <Katakana>} );
ok( "\N{KATAKANA LETTER SMALL A}" !~ m/^<-Katakana>$/, q{Don't match inverted <Katakana>} );
ok( "\x{177A}"  !~ m/^<Katakana>$/, q{Don't match unrelated <Katakana>} );
ok( "\x{177A}"  =~ m/^<!Katakana>.$/, q{Match unrelated negated <Katakana>} );
ok( "\x{177A}"  =~ m/^<-Katakana>$/, q{Match unrelated inverted <Katakana>} );
ok( "\x{177A}\N{KATAKANA LETTER SMALL A}" =~ m/<Katakana>/, q{Match unanchored <Katakana>} );

# Khmer


ok( "\N{KHMER LETTER KA}" =~ m/^<Khmer>$/, q{Match <Khmer>} );
ok( "\N{KHMER LETTER KA}" !~ m/^<!Khmer>.$/, q{Don't match negated <Khmer>} );
ok( "\N{KHMER LETTER KA}" !~ m/^<-Khmer>$/, q{Don't match inverted <Khmer>} );
ok( "\N{GEORGIAN LETTER QAR}"  !~ m/^<Khmer>$/, q{Don't match unrelated <Khmer>} );
ok( "\N{GEORGIAN LETTER QAR}"  =~ m/^<!Khmer>.$/, q{Match unrelated negated <Khmer>} );
ok( "\N{GEORGIAN LETTER QAR}"  =~ m/^<-Khmer>$/, q{Match unrelated inverted <Khmer>} );
ok( "\N{GEORGIAN LETTER QAR}\N{KHMER LETTER KA}" =~ m/<Khmer>/, q{Match unanchored <Khmer>} );

# Lao


ok( "\N{LAO LETTER KO}" =~ m/^<Lao>$/, q{Match <Lao>} );
ok( "\N{LAO LETTER KO}" !~ m/^<!Lao>.$/, q{Don't match negated <Lao>} );
ok( "\N{LAO LETTER KO}" !~ m/^<-Lao>$/, q{Don't match inverted <Lao>} );
ok( "\x{3DA9}"  !~ m/^<Lao>$/, q{Don't match unrelated <Lao>} );
ok( "\x{3DA9}"  =~ m/^<!Lao>.$/, q{Match unrelated negated <Lao>} );
ok( "\x{3DA9}"  =~ m/^<-Lao>$/, q{Match unrelated inverted <Lao>} );
ok( "\x{3DA9}" !~ m/^<Lao>$/, q{Don't match related <Lao>} );
ok( "\x{3DA9}" =~ m/^<!Lao>.$/, q{Match related negated <Lao>} );
ok( "\x{3DA9}" =~ m/^<-Lao>$/, q{Match related inverted <Lao>} );
ok( "\x{3DA9}\x{3DA9}\N{LAO LETTER KO}" =~ m/<Lao>/, q{Match unanchored <Lao>} );

# Latin


ok( "\N{LATIN CAPITAL LETTER A}" =~ m/^<Latin>$/, q{Match <Latin>} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<!Latin>.$/, q{Don't match negated <Latin>} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<-Latin>$/, q{Don't match inverted <Latin>} );
ok( "\x{C549}"  !~ m/^<Latin>$/, q{Don't match unrelated <Latin>} );
ok( "\x{C549}"  =~ m/^<!Latin>.$/, q{Match unrelated negated <Latin>} );
ok( "\x{C549}"  =~ m/^<-Latin>$/, q{Match unrelated inverted <Latin>} );
ok( "\x{C549}" !~ m/^<Latin>$/, q{Don't match related <Latin>} );
ok( "\x{C549}" =~ m/^<!Latin>.$/, q{Match related negated <Latin>} );
ok( "\x{C549}" =~ m/^<-Latin>$/, q{Match related inverted <Latin>} );
ok( "\x{C549}\x{C549}\N{LATIN CAPITAL LETTER A}" =~ m/<Latin>/, q{Match unanchored <Latin>} );

# Malayalam


ok( "\N{MALAYALAM SIGN ANUSVARA}" =~ m/^<Malayalam>$/, q{Match <Malayalam>} );
ok( "\N{MALAYALAM SIGN ANUSVARA}" !~ m/^<!Malayalam>.$/, q{Don't match negated <Malayalam>} );
ok( "\N{MALAYALAM SIGN ANUSVARA}" !~ m/^<-Malayalam>$/, q{Don't match inverted <Malayalam>} );
ok( "\x{625C}"  !~ m/^<Malayalam>$/, q{Don't match unrelated <Malayalam>} );
ok( "\x{625C}"  =~ m/^<!Malayalam>.$/, q{Match unrelated negated <Malayalam>} );
ok( "\x{625C}"  =~ m/^<-Malayalam>$/, q{Match unrelated inverted <Malayalam>} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<Malayalam>$/, q{Don't match related <Malayalam>} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<!Malayalam>.$/, q{Match related negated <Malayalam>} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<-Malayalam>$/, q{Match related inverted <Malayalam>} );
ok( "\x{625C}\N{COMBINING GRAVE ACCENT}\N{MALAYALAM SIGN ANUSVARA}" =~ m/<Malayalam>/, q{Match unanchored <Malayalam>} );

# Mongolian


ok( "\N{MONGOLIAN DIGIT ZERO}" =~ m/^<Mongolian>$/, q{Match <Mongolian>} );
ok( "\N{MONGOLIAN DIGIT ZERO}" !~ m/^<!Mongolian>.$/, q{Don't match negated <Mongolian>} );
ok( "\N{MONGOLIAN DIGIT ZERO}" !~ m/^<-Mongolian>$/, q{Don't match inverted <Mongolian>} );
ok( "\x{5F93}"  !~ m/^<Mongolian>$/, q{Don't match unrelated <Mongolian>} );
ok( "\x{5F93}"  =~ m/^<!Mongolian>.$/, q{Match unrelated negated <Mongolian>} );
ok( "\x{5F93}"  =~ m/^<-Mongolian>$/, q{Match unrelated inverted <Mongolian>} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<Mongolian>$/, q{Don't match related <Mongolian>} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<!Mongolian>.$/, q{Match related negated <Mongolian>} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<-Mongolian>$/, q{Match related inverted <Mongolian>} );
ok( "\x{5F93}\N{COMBINING GRAVE ACCENT}\N{MONGOLIAN DIGIT ZERO}" =~ m/<Mongolian>/, q{Match unanchored <Mongolian>} );

# Myanmar


ok( "\N{MYANMAR LETTER KA}" =~ m/^<Myanmar>$/, q{Match <Myanmar>} );
ok( "\N{MYANMAR LETTER KA}" !~ m/^<!Myanmar>.$/, q{Don't match negated <Myanmar>} );
ok( "\N{MYANMAR LETTER KA}" !~ m/^<-Myanmar>$/, q{Don't match inverted <Myanmar>} );
ok( "\x{649A}"  !~ m/^<Myanmar>$/, q{Don't match unrelated <Myanmar>} );
ok( "\x{649A}"  =~ m/^<!Myanmar>.$/, q{Match unrelated negated <Myanmar>} );
ok( "\x{649A}"  =~ m/^<-Myanmar>$/, q{Match unrelated inverted <Myanmar>} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<Myanmar>$/, q{Don't match related <Myanmar>} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<!Myanmar>.$/, q{Match related negated <Myanmar>} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<-Myanmar>$/, q{Match related inverted <Myanmar>} );
ok( "\x{649A}\N{COMBINING GRAVE ACCENT}\N{MYANMAR LETTER KA}" =~ m/<Myanmar>/, q{Match unanchored <Myanmar>} );

# Ogham


ok( "\N{OGHAM LETTER BEITH}" =~ m/^<Ogham>$/, q{Match <Ogham>} );
ok( "\N{OGHAM LETTER BEITH}" !~ m/^<!Ogham>.$/, q{Don't match negated <Ogham>} );
ok( "\N{OGHAM LETTER BEITH}" !~ m/^<-Ogham>$/, q{Don't match inverted <Ogham>} );
ok( "\N{KATAKANA LETTER KA}"  !~ m/^<Ogham>$/, q{Don't match unrelated <Ogham>} );
ok( "\N{KATAKANA LETTER KA}"  =~ m/^<!Ogham>.$/, q{Match unrelated negated <Ogham>} );
ok( "\N{KATAKANA LETTER KA}"  =~ m/^<-Ogham>$/, q{Match unrelated inverted <Ogham>} );
ok( "\N{KATAKANA LETTER KA}\N{OGHAM LETTER BEITH}" =~ m/<Ogham>/, q{Match unanchored <Ogham>} );

# OldItalic


ok( "\x{8BB7}"  !~ m/^<OldItalic>$/, q{Don't match unrelated <OldItalic>} );
ok( "\x{8BB7}"  =~ m/^<!OldItalic>.$/, q{Match unrelated negated <OldItalic>} );
ok( "\x{8BB7}"  =~ m/^<-OldItalic>$/, q{Match unrelated inverted <OldItalic>} );

# Oriya


ok( "\N{ORIYA SIGN CANDRABINDU}" =~ m/^<Oriya>$/, q{Match <Oriya>} );
ok( "\N{ORIYA SIGN CANDRABINDU}" !~ m/^<!Oriya>.$/, q{Don't match negated <Oriya>} );
ok( "\N{ORIYA SIGN CANDRABINDU}" !~ m/^<-Oriya>$/, q{Don't match inverted <Oriya>} );
ok( "\x{4292}"  !~ m/^<Oriya>$/, q{Don't match unrelated <Oriya>} );
ok( "\x{4292}"  =~ m/^<!Oriya>.$/, q{Match unrelated negated <Oriya>} );
ok( "\x{4292}"  =~ m/^<-Oriya>$/, q{Match unrelated inverted <Oriya>} );
ok( "\x{4292}\N{ORIYA SIGN CANDRABINDU}" =~ m/<Oriya>/, q{Match unanchored <Oriya>} );

# Runic


ok( "\N{RUNIC LETTER FEHU FEOH FE F}" =~ m/^<Runic>$/, q{Match <Runic>} );
ok( "\N{RUNIC LETTER FEHU FEOH FE F}" !~ m/^<!Runic>.$/, q{Don't match negated <Runic>} );
ok( "\N{RUNIC LETTER FEHU FEOH FE F}" !~ m/^<-Runic>$/, q{Don't match inverted <Runic>} );
ok( "\x{9857}"  !~ m/^<Runic>$/, q{Don't match unrelated <Runic>} );
ok( "\x{9857}"  =~ m/^<!Runic>.$/, q{Match unrelated negated <Runic>} );
ok( "\x{9857}"  =~ m/^<-Runic>$/, q{Match unrelated inverted <Runic>} );
ok( "\x{9857}\N{RUNIC LETTER FEHU FEOH FE F}" =~ m/<Runic>/, q{Match unanchored <Runic>} );

# Sinhala


ok( "\N{SINHALA SIGN ANUSVARAYA}" =~ m/^<Sinhala>$/, q{Match <Sinhala>} );
ok( "\N{SINHALA SIGN ANUSVARAYA}" !~ m/^<!Sinhala>.$/, q{Don't match negated <Sinhala>} );
ok( "\N{SINHALA SIGN ANUSVARAYA}" !~ m/^<-Sinhala>$/, q{Don't match inverted <Sinhala>} );
ok( "\x{5DF5}"  !~ m/^<Sinhala>$/, q{Don't match unrelated <Sinhala>} );
ok( "\x{5DF5}"  =~ m/^<!Sinhala>.$/, q{Match unrelated negated <Sinhala>} );
ok( "\x{5DF5}"  =~ m/^<-Sinhala>$/, q{Match unrelated inverted <Sinhala>} );
ok( "\N{YI RADICAL QOT}" !~ m/^<Sinhala>$/, q{Don't match related <Sinhala>} );
ok( "\N{YI RADICAL QOT}" =~ m/^<!Sinhala>.$/, q{Match related negated <Sinhala>} );
ok( "\N{YI RADICAL QOT}" =~ m/^<-Sinhala>$/, q{Match related inverted <Sinhala>} );
ok( "\x{5DF5}\N{YI RADICAL QOT}\N{SINHALA SIGN ANUSVARAYA}" =~ m/<Sinhala>/, q{Match unanchored <Sinhala>} );

# Syriac


ok( "\N{SYRIAC LETTER ALAPH}" =~ m/^<Syriac>$/, q{Match <Syriac>} );
ok( "\N{SYRIAC LETTER ALAPH}" !~ m/^<!Syriac>.$/, q{Don't match negated <Syriac>} );
ok( "\N{SYRIAC LETTER ALAPH}" !~ m/^<-Syriac>$/, q{Don't match inverted <Syriac>} );
ok( "\x{57F0}"  !~ m/^<Syriac>$/, q{Don't match unrelated <Syriac>} );
ok( "\x{57F0}"  =~ m/^<!Syriac>.$/, q{Match unrelated negated <Syriac>} );
ok( "\x{57F0}"  =~ m/^<-Syriac>$/, q{Match unrelated inverted <Syriac>} );
ok( "\N{YI RADICAL QOT}" !~ m/^<Syriac>$/, q{Don't match related <Syriac>} );
ok( "\N{YI RADICAL QOT}" =~ m/^<!Syriac>.$/, q{Match related negated <Syriac>} );
ok( "\N{YI RADICAL QOT}" =~ m/^<-Syriac>$/, q{Match related inverted <Syriac>} );
ok( "\x{57F0}\N{YI RADICAL QOT}\N{SYRIAC LETTER ALAPH}" =~ m/<Syriac>/, q{Match unanchored <Syriac>} );

# Tagalog


ok( "\N{TAGALOG LETTER A}" =~ m/^<Tagalog>$/, q{Match <Tagalog>} );
ok( "\N{TAGALOG LETTER A}" !~ m/^<!Tagalog>.$/, q{Don't match negated <Tagalog>} );
ok( "\N{TAGALOG LETTER A}" !~ m/^<-Tagalog>$/, q{Don't match inverted <Tagalog>} );
ok( "\x{3DE8}"  !~ m/^<Tagalog>$/, q{Don't match unrelated <Tagalog>} );
ok( "\x{3DE8}"  =~ m/^<!Tagalog>.$/, q{Match unrelated negated <Tagalog>} );
ok( "\x{3DE8}"  =~ m/^<-Tagalog>$/, q{Match unrelated inverted <Tagalog>} );
ok( "\x{3DE8}\N{TAGALOG LETTER A}" =~ m/<Tagalog>/, q{Match unanchored <Tagalog>} );

# Tagbanwa


ok( "\N{TAGBANWA LETTER A}" =~ m/^<Tagbanwa>$/, q{Match <Tagbanwa>} );
ok( "\N{TAGBANWA LETTER A}" !~ m/^<!Tagbanwa>.$/, q{Don't match negated <Tagbanwa>} );
ok( "\N{TAGBANWA LETTER A}" !~ m/^<-Tagbanwa>$/, q{Don't match inverted <Tagbanwa>} );
ok( "\N{CHEROKEE LETTER TLV}"  !~ m/^<Tagbanwa>$/, q{Don't match unrelated <Tagbanwa>} );
ok( "\N{CHEROKEE LETTER TLV}"  =~ m/^<!Tagbanwa>.$/, q{Match unrelated negated <Tagbanwa>} );
ok( "\N{CHEROKEE LETTER TLV}"  =~ m/^<-Tagbanwa>$/, q{Match unrelated inverted <Tagbanwa>} );
ok( "\N{CHEROKEE LETTER TLV}\N{TAGBANWA LETTER A}" =~ m/<Tagbanwa>/, q{Match unanchored <Tagbanwa>} );

# Tamil


ok( "\N{TAMIL SIGN ANUSVARA}" =~ m/^<Tamil>$/, q{Match <Tamil>} );
ok( "\N{TAMIL SIGN ANUSVARA}" !~ m/^<!Tamil>.$/, q{Don't match negated <Tamil>} );
ok( "\N{TAMIL SIGN ANUSVARA}" !~ m/^<-Tamil>$/, q{Don't match inverted <Tamil>} );
ok( "\x{8DF2}"  !~ m/^<Tamil>$/, q{Don't match unrelated <Tamil>} );
ok( "\x{8DF2}"  =~ m/^<!Tamil>.$/, q{Match unrelated negated <Tamil>} );
ok( "\x{8DF2}"  =~ m/^<-Tamil>$/, q{Match unrelated inverted <Tamil>} );
ok( "\x{8DF2}\N{TAMIL SIGN ANUSVARA}" =~ m/<Tamil>/, q{Match unanchored <Tamil>} );

# Telugu


ok( "\N{TELUGU SIGN CANDRABINDU}" =~ m/^<Telugu>$/, q{Match <Telugu>} );
ok( "\N{TELUGU SIGN CANDRABINDU}" !~ m/^<!Telugu>.$/, q{Don't match negated <Telugu>} );
ok( "\N{TELUGU SIGN CANDRABINDU}" !~ m/^<-Telugu>$/, q{Don't match inverted <Telugu>} );
ok( "\x{8088}"  !~ m/^<Telugu>$/, q{Don't match unrelated <Telugu>} );
ok( "\x{8088}"  =~ m/^<!Telugu>.$/, q{Match unrelated negated <Telugu>} );
ok( "\x{8088}"  =~ m/^<-Telugu>$/, q{Match unrelated inverted <Telugu>} );
ok( "\x{8088}\N{TELUGU SIGN CANDRABINDU}" =~ m/<Telugu>/, q{Match unanchored <Telugu>} );

# Thaana


ok( "\N{THAANA LETTER HAA}" =~ m/^<Thaana>$/, q{Match <Thaana>} );
ok( "\N{THAANA LETTER HAA}" !~ m/^<!Thaana>.$/, q{Don't match negated <Thaana>} );
ok( "\N{THAANA LETTER HAA}" !~ m/^<-Thaana>$/, q{Don't match inverted <Thaana>} );
ok( "\x{5240}"  !~ m/^<Thaana>$/, q{Don't match unrelated <Thaana>} );
ok( "\x{5240}"  =~ m/^<!Thaana>.$/, q{Match unrelated negated <Thaana>} );
ok( "\x{5240}"  =~ m/^<-Thaana>$/, q{Match unrelated inverted <Thaana>} );
ok( "\x{5240}\N{THAANA LETTER HAA}" =~ m/<Thaana>/, q{Match unanchored <Thaana>} );

# Thai


ok( "\N{THAI CHARACTER KO KAI}" =~ m/^<Thai>$/, q{Match <Thai>} );
ok( "\N{THAI CHARACTER KO KAI}" !~ m/^<!Thai>.$/, q{Don't match negated <Thai>} );
ok( "\N{THAI CHARACTER KO KAI}" !~ m/^<-Thai>$/, q{Don't match inverted <Thai>} );
ok( "\x{CAD3}"  !~ m/^<Thai>$/, q{Don't match unrelated <Thai>} );
ok( "\x{CAD3}"  =~ m/^<!Thai>.$/, q{Match unrelated negated <Thai>} );
ok( "\x{CAD3}"  =~ m/^<-Thai>$/, q{Match unrelated inverted <Thai>} );
ok( "\x{CAD3}\N{THAI CHARACTER KO KAI}" =~ m/<Thai>/, q{Match unanchored <Thai>} );

# Tibetan


ok( "\N{TIBETAN SYLLABLE OM}" =~ m/^<Tibetan>$/, q{Match <Tibetan>} );
ok( "\N{TIBETAN SYLLABLE OM}" !~ m/^<!Tibetan>.$/, q{Don't match negated <Tibetan>} );
ok( "\N{TIBETAN SYLLABLE OM}" !~ m/^<-Tibetan>$/, q{Don't match inverted <Tibetan>} );
ok( "\x{8557}"  !~ m/^<Tibetan>$/, q{Don't match unrelated <Tibetan>} );
ok( "\x{8557}"  =~ m/^<!Tibetan>.$/, q{Match unrelated negated <Tibetan>} );
ok( "\x{8557}"  =~ m/^<-Tibetan>$/, q{Match unrelated inverted <Tibetan>} );
ok( "\x{8557}\N{TIBETAN SYLLABLE OM}" =~ m/<Tibetan>/, q{Match unanchored <Tibetan>} );

# Yi


ok( "\N{YI SYLLABLE IT}" =~ m/^<Yi>$/, q{Match <Yi>} );
ok( "\N{YI SYLLABLE IT}" !~ m/^<!Yi>.$/, q{Don't match negated <Yi>} );
ok( "\N{YI SYLLABLE IT}" !~ m/^<-Yi>$/, q{Don't match inverted <Yi>} );
ok( "\x{BCD0}"  !~ m/^<Yi>$/, q{Don't match unrelated <Yi>} );
ok( "\x{BCD0}"  =~ m/^<!Yi>.$/, q{Match unrelated negated <Yi>} );
ok( "\x{BCD0}"  =~ m/^<-Yi>$/, q{Match unrelated inverted <Yi>} );
ok( "\x{BCD0}\N{YI SYLLABLE IT}" =~ m/<Yi>/, q{Match unanchored <Yi>} );

# ASCIIHexDigit


ok( "\N{DIGIT ZERO}" =~ m/^<ASCIIHexDigit>$/, q{Match <ASCIIHexDigit>} );
ok( "\N{DIGIT ZERO}" !~ m/^<!ASCIIHexDigit>.$/, q{Don't match negated <ASCIIHexDigit>} );
ok( "\N{DIGIT ZERO}" !~ m/^<-ASCIIHexDigit>$/, q{Don't match inverted <ASCIIHexDigit>} );
ok( "\x{53BA}"  !~ m/^<ASCIIHexDigit>$/, q{Don't match unrelated <ASCIIHexDigit>} );
ok( "\x{53BA}"  =~ m/^<!ASCIIHexDigit>.$/, q{Match unrelated negated <ASCIIHexDigit>} );
ok( "\x{53BA}"  =~ m/^<-ASCIIHexDigit>$/, q{Match unrelated inverted <ASCIIHexDigit>} );
ok( "\x{53BA}\N{DIGIT ZERO}" =~ m/<ASCIIHexDigit>/, q{Match unanchored <ASCIIHexDigit>} );

# Dash


ok( "\N{HYPHEN-MINUS}" =~ m/^<Dash>$/, q{Match <Dash>} );
ok( "\N{HYPHEN-MINUS}" !~ m/^<!Dash>.$/, q{Don't match negated <Dash>} );
ok( "\N{HYPHEN-MINUS}" !~ m/^<-Dash>$/, q{Don't match inverted <Dash>} );
ok( "\x{53F7}"  !~ m/^<Dash>$/, q{Don't match unrelated <Dash>} );
ok( "\x{53F7}"  =~ m/^<!Dash>.$/, q{Match unrelated negated <Dash>} );
ok( "\x{53F7}"  =~ m/^<-Dash>$/, q{Match unrelated inverted <Dash>} );
ok( "\x{53F7}\N{HYPHEN-MINUS}" =~ m/<Dash>/, q{Match unanchored <Dash>} );

# Diacritic


ok( "\N{MODIFIER LETTER CAPITAL A}" =~ m/^<Diacritic>$/, q{Match <Diacritic>} );
ok( "\N{MODIFIER LETTER CAPITAL A}" !~ m/^<!Diacritic>.$/, q{Don't match negated <Diacritic>} );
ok( "\N{MODIFIER LETTER CAPITAL A}" !~ m/^<-Diacritic>$/, q{Don't match inverted <Diacritic>} );
ok( "\x{1BCD}"  !~ m/^<Diacritic>$/, q{Don't match unrelated <Diacritic>} );
ok( "\x{1BCD}"  =~ m/^<!Diacritic>.$/, q{Match unrelated negated <Diacritic>} );
ok( "\x{1BCD}"  =~ m/^<-Diacritic>$/, q{Match unrelated inverted <Diacritic>} );
ok( "\x{1BCD}\N{MODIFIER LETTER CAPITAL A}" =~ m/<Diacritic>/, q{Match unanchored <Diacritic>} );

# Extender


ok( "\N{MIDDLE DOT}" =~ m/^<Extender>$/, q{Match <Extender>} );
ok( "\N{MIDDLE DOT}" !~ m/^<!Extender>.$/, q{Don't match negated <Extender>} );
ok( "\N{MIDDLE DOT}" !~ m/^<-Extender>$/, q{Don't match inverted <Extender>} );
ok( "\x{3A18}"  !~ m/^<Extender>$/, q{Don't match unrelated <Extender>} );
ok( "\x{3A18}"  =~ m/^<!Extender>.$/, q{Match unrelated negated <Extender>} );
ok( "\x{3A18}"  =~ m/^<-Extender>$/, q{Match unrelated inverted <Extender>} );
ok( "\x{3A18}\N{MIDDLE DOT}" =~ m/<Extender>/, q{Match unanchored <Extender>} );

# GraphemeLink


ok( "\N{COMBINING GRAPHEME JOINER}" =~ m/^<GraphemeLink>$/, q{Match <GraphemeLink>} );
ok( "\N{COMBINING GRAPHEME JOINER}" !~ m/^<!GraphemeLink>.$/, q{Don't match negated <GraphemeLink>} );
ok( "\N{COMBINING GRAPHEME JOINER}" !~ m/^<-GraphemeLink>$/, q{Don't match inverted <GraphemeLink>} );
ok( "\x{4989}"  !~ m/^<GraphemeLink>$/, q{Don't match unrelated <GraphemeLink>} );
ok( "\x{4989}"  =~ m/^<!GraphemeLink>.$/, q{Match unrelated negated <GraphemeLink>} );
ok( "\x{4989}"  =~ m/^<-GraphemeLink>$/, q{Match unrelated inverted <GraphemeLink>} );
ok( "\x{4989}\N{COMBINING GRAPHEME JOINER}" =~ m/<GraphemeLink>/, q{Match unanchored <GraphemeLink>} );

# HexDigit


ok( "\N{DIGIT ZERO}" =~ m/^<HexDigit>$/, q{Match <HexDigit>} );
ok( "\N{DIGIT ZERO}" !~ m/^<!HexDigit>.$/, q{Don't match negated <HexDigit>} );
ok( "\N{DIGIT ZERO}" !~ m/^<-HexDigit>$/, q{Don't match inverted <HexDigit>} );
ok( "\x{6292}"  !~ m/^<HexDigit>$/, q{Don't match unrelated <HexDigit>} );
ok( "\x{6292}"  =~ m/^<!HexDigit>.$/, q{Match unrelated negated <HexDigit>} );
ok( "\x{6292}"  =~ m/^<-HexDigit>$/, q{Match unrelated inverted <HexDigit>} );
ok( "\x{6292}\N{DIGIT ZERO}" =~ m/<HexDigit>/, q{Match unanchored <HexDigit>} );

# Hyphen

ok( "\N{KATAKANA MIDDLE DOT}" =~ m/^<Hyphen>$/, q{Match <Hyphen>} );
ok( "\N{KATAKANA MIDDLE DOT}" !~ m/^<!Hyphen>.$/, q{Don't match negated <Hyphen>} );
ok( "\N{KATAKANA MIDDLE DOT}" !~ m/^<-Hyphen>$/, q{Don't match inverted <Hyphen>} );
ok( "\N{BOX DRAWINGS DOWN DOUBLE AND LEFT SINGLE}"  !~ m/^<Hyphen>$/, q{Don't match unrelated <Hyphen>} );
ok( "\N{BOX DRAWINGS DOWN DOUBLE AND LEFT SINGLE}"  =~ m/^<!Hyphen>.$/, q{Match unrelated negated <Hyphen>} );
ok( "\N{BOX DRAWINGS DOWN DOUBLE AND LEFT SINGLE}"  =~ m/^<-Hyphen>$/, q{Match unrelated inverted <Hyphen>} );
ok( "\N{BOX DRAWINGS DOWN DOUBLE AND LEFT SINGLE}\N{KATAKANA MIDDLE DOT}" =~ m/<Hyphen>/, q{Match unanchored <Hyphen>} );

# Ideographic


ok( "\x{8AB0}" =~ m/^<Ideographic>$/, q{Match <Ideographic>} );
ok( "\x{8AB0}" !~ m/^<!Ideographic>.$/, q{Don't match negated <Ideographic>} );
ok( "\x{8AB0}" !~ m/^<-Ideographic>$/, q{Don't match inverted <Ideographic>} );
ok( "\x{9FA6}"  !~ m/^<Ideographic>$/, q{Don't match unrelated <Ideographic>} );
ok( "\x{9FA6}"  =~ m/^<!Ideographic>.$/, q{Match unrelated negated <Ideographic>} );
ok( "\x{9FA6}"  =~ m/^<-Ideographic>$/, q{Match unrelated inverted <Ideographic>} );
ok( "\x{9FA6}\x{8AB0}" =~ m/<Ideographic>/, q{Match unanchored <Ideographic>} );

# IDSBinaryOperator


ok( "\N{IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO RIGHT}" =~ m/^<IDSBinaryOperator>$/, q{Match <IDSBinaryOperator>} );
ok( "\N{IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO RIGHT}" !~ m/^<!IDSBinaryOperator>.$/, q{Don't match negated <IDSBinaryOperator>} );
ok( "\N{IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO RIGHT}" !~ m/^<-IDSBinaryOperator>$/, q{Don't match inverted <IDSBinaryOperator>} );
ok( "\x{59E9}"  !~ m/^<IDSBinaryOperator>$/, q{Don't match unrelated <IDSBinaryOperator>} );
ok( "\x{59E9}"  =~ m/^<!IDSBinaryOperator>.$/, q{Match unrelated negated <IDSBinaryOperator>} );
ok( "\x{59E9}"  =~ m/^<-IDSBinaryOperator>$/, q{Match unrelated inverted <IDSBinaryOperator>} );
ok( "\x{59E9}\N{IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO RIGHT}" =~ m/<IDSBinaryOperator>/, q{Match unanchored <IDSBinaryOperator>} );

# IDSTrinaryOperator


ok( "\N{IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO MIDDLE AND RIGHT}" =~ m/^<IDSTrinaryOperator>$/, q{Match <IDSTrinaryOperator>} );
ok( "\N{IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO MIDDLE AND RIGHT}" !~ m/^<!IDSTrinaryOperator>.$/, q{Don't match negated <IDSTrinaryOperator>} );
ok( "\N{IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO MIDDLE AND RIGHT}" !~ m/^<-IDSTrinaryOperator>$/, q{Don't match inverted <IDSTrinaryOperator>} );
ok( "\x{9224}"  !~ m/^<IDSTrinaryOperator>$/, q{Don't match unrelated <IDSTrinaryOperator>} );
ok( "\x{9224}"  =~ m/^<!IDSTrinaryOperator>.$/, q{Match unrelated negated <IDSTrinaryOperator>} );
ok( "\x{9224}"  =~ m/^<-IDSTrinaryOperator>$/, q{Match unrelated inverted <IDSTrinaryOperator>} );
ok( "\x{9224}\N{IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO MIDDLE AND RIGHT}" =~ m/<IDSTrinaryOperator>/, q{Match unanchored <IDSTrinaryOperator>} );

# JoinControl


ok( "\N{ZERO WIDTH NON-JOINER}" =~ m/^<JoinControl>$/, q{Match <JoinControl>} );
ok( "\N{ZERO WIDTH NON-JOINER}" !~ m/^<!JoinControl>.$/, q{Don't match negated <JoinControl>} );
ok( "\N{ZERO WIDTH NON-JOINER}" !~ m/^<-JoinControl>$/, q{Don't match inverted <JoinControl>} );
ok( "\N{BENGALI LETTER DDHA}"  !~ m/^<JoinControl>$/, q{Don't match unrelated <JoinControl>} );
ok( "\N{BENGALI LETTER DDHA}"  =~ m/^<!JoinControl>.$/, q{Match unrelated negated <JoinControl>} );
ok( "\N{BENGALI LETTER DDHA}"  =~ m/^<-JoinControl>$/, q{Match unrelated inverted <JoinControl>} );
ok( "\N{BENGALI LETTER DDHA}\N{ZERO WIDTH NON-JOINER}" =~ m/<JoinControl>/, q{Match unanchored <JoinControl>} );

# LogicalOrderException


ok( "\N{THAI CHARACTER SARA E}" =~ m/^<LogicalOrderException>$/, q{Match <LogicalOrderException>} );
ok( "\N{THAI CHARACTER SARA E}" !~ m/^<!LogicalOrderException>.$/, q{Don't match negated <LogicalOrderException>} );
ok( "\N{THAI CHARACTER SARA E}" !~ m/^<-LogicalOrderException>$/, q{Don't match inverted <LogicalOrderException>} );
ok( "\x{857B}"  !~ m/^<LogicalOrderException>$/, q{Don't match unrelated <LogicalOrderException>} );
ok( "\x{857B}"  =~ m/^<!LogicalOrderException>.$/, q{Match unrelated negated <LogicalOrderException>} );
ok( "\x{857B}"  =~ m/^<-LogicalOrderException>$/, q{Match unrelated inverted <LogicalOrderException>} );
ok( "\x{857B}" !~ m/^<LogicalOrderException>$/, q{Don't match related <LogicalOrderException>} );
ok( "\x{857B}" =~ m/^<!LogicalOrderException>.$/, q{Match related negated <LogicalOrderException>} );
ok( "\x{857B}" =~ m/^<-LogicalOrderException>$/, q{Match related inverted <LogicalOrderException>} );
ok( "\x{857B}\x{857B}\N{THAI CHARACTER SARA E}" =~ m/<LogicalOrderException>/, q{Match unanchored <LogicalOrderException>} );

# NoncharacterCodePoint


ok( "\N{LATIN LETTER REVERSED GLOTTAL STOP WITH STROKE}"  !~ m/^<NoncharacterCodePoint>$/, q{Don't match unrelated <NoncharacterCodePoint>} );
ok( "\N{LATIN LETTER REVERSED GLOTTAL STOP WITH STROKE}"  =~ m/^<!NoncharacterCodePoint>.$/, q{Match unrelated negated <NoncharacterCodePoint>} );
ok( "\N{LATIN LETTER REVERSED GLOTTAL STOP WITH STROKE}"  =~ m/^<-NoncharacterCodePoint>$/, q{Match unrelated inverted <NoncharacterCodePoint>} );
ok( "\N{ARABIC-INDIC DIGIT ZERO}" !~ m/^<NoncharacterCodePoint>$/, q{Don't match related <NoncharacterCodePoint>} );
ok( "\N{ARABIC-INDIC DIGIT ZERO}" =~ m/^<!NoncharacterCodePoint>.$/, q{Match related negated <NoncharacterCodePoint>} );
ok( "\N{ARABIC-INDIC DIGIT ZERO}" =~ m/^<-NoncharacterCodePoint>$/, q{Match related inverted <NoncharacterCodePoint>} );

# OtherAlphabetic


ok( "\N{COMBINING GREEK YPOGEGRAMMENI}" =~ m/^<OtherAlphabetic>$/, q{Match <OtherAlphabetic>} );
ok( "\N{COMBINING GREEK YPOGEGRAMMENI}" !~ m/^<!OtherAlphabetic>.$/, q{Don't match negated <OtherAlphabetic>} );
ok( "\N{COMBINING GREEK YPOGEGRAMMENI}" !~ m/^<-OtherAlphabetic>$/, q{Don't match inverted <OtherAlphabetic>} );
ok( "\x{413C}"  !~ m/^<OtherAlphabetic>$/, q{Don't match unrelated <OtherAlphabetic>} );
ok( "\x{413C}"  =~ m/^<!OtherAlphabetic>.$/, q{Match unrelated negated <OtherAlphabetic>} );
ok( "\x{413C}"  =~ m/^<-OtherAlphabetic>$/, q{Match unrelated inverted <OtherAlphabetic>} );
ok( "\x{413C}\N{COMBINING GREEK YPOGEGRAMMENI}" =~ m/<OtherAlphabetic>/, q{Match unanchored <OtherAlphabetic>} );

# OtherDefaultIgnorableCodePoint


ok( "\N{HANGUL FILLER}" =~ m/^<OtherDefaultIgnorableCodePoint>$/, q{Match <OtherDefaultIgnorableCodePoint>} );
ok( "\N{HANGUL FILLER}" !~ m/^<!OtherDefaultIgnorableCodePoint>.$/, q{Don't match negated <OtherDefaultIgnorableCodePoint>} );
ok( "\N{HANGUL FILLER}" !~ m/^<-OtherDefaultIgnorableCodePoint>$/, q{Don't match inverted <OtherDefaultIgnorableCodePoint>} );
ok( "\N{VERTICAL BAR DOUBLE LEFT TURNSTILE}"  !~ m/^<OtherDefaultIgnorableCodePoint>$/, q{Don't match unrelated <OtherDefaultIgnorableCodePoint>} );
ok( "\N{VERTICAL BAR DOUBLE LEFT TURNSTILE}"  =~ m/^<!OtherDefaultIgnorableCodePoint>.$/, q{Match unrelated negated <OtherDefaultIgnorableCodePoint>} );
ok( "\N{VERTICAL BAR DOUBLE LEFT TURNSTILE}"  =~ m/^<-OtherDefaultIgnorableCodePoint>$/, q{Match unrelated inverted <OtherDefaultIgnorableCodePoint>} );
ok( "\N{VERTICAL BAR DOUBLE LEFT TURNSTILE}\N{HANGUL FILLER}" =~ m/<OtherDefaultIgnorableCodePoint>/, q{Match unanchored <OtherDefaultIgnorableCodePoint>} );

# OtherGraphemeExtend


ok( "\N{BENGALI VOWEL SIGN AA}" =~ m/^<OtherGraphemeExtend>$/, q{Match <OtherGraphemeExtend>} );
ok( "\N{BENGALI VOWEL SIGN AA}" !~ m/^<!OtherGraphemeExtend>.$/, q{Don't match negated <OtherGraphemeExtend>} );
ok( "\N{BENGALI VOWEL SIGN AA}" !~ m/^<-OtherGraphemeExtend>$/, q{Don't match inverted <OtherGraphemeExtend>} );
ok( "\N{APL FUNCTIONAL SYMBOL EPSILON UNDERBAR}"  !~ m/^<OtherGraphemeExtend>$/, q{Don't match unrelated <OtherGraphemeExtend>} );
ok( "\N{APL FUNCTIONAL SYMBOL EPSILON UNDERBAR}"  =~ m/^<!OtherGraphemeExtend>.$/, q{Match unrelated negated <OtherGraphemeExtend>} );
ok( "\N{APL FUNCTIONAL SYMBOL EPSILON UNDERBAR}"  =~ m/^<-OtherGraphemeExtend>$/, q{Match unrelated inverted <OtherGraphemeExtend>} );
ok( "\N{APL FUNCTIONAL SYMBOL EPSILON UNDERBAR}\N{BENGALI VOWEL SIGN AA}" =~ m/<OtherGraphemeExtend>/, q{Match unanchored <OtherGraphemeExtend>} );

# OtherLowercase


ok( "\N{MODIFIER LETTER SMALL H}" =~ m/^<OtherLowercase>$/, q{Match <OtherLowercase>} );
ok( "\N{MODIFIER LETTER SMALL H}" !~ m/^<!OtherLowercase>.$/, q{Don't match negated <OtherLowercase>} );
ok( "\N{MODIFIER LETTER SMALL H}" !~ m/^<-OtherLowercase>$/, q{Don't match inverted <OtherLowercase>} );
ok( "\N{HANGUL LETTER NIEUN-CIEUC}"  !~ m/^<OtherLowercase>$/, q{Don't match unrelated <OtherLowercase>} );
ok( "\N{HANGUL LETTER NIEUN-CIEUC}"  =~ m/^<!OtherLowercase>.$/, q{Match unrelated negated <OtherLowercase>} );
ok( "\N{HANGUL LETTER NIEUN-CIEUC}"  =~ m/^<-OtherLowercase>$/, q{Match unrelated inverted <OtherLowercase>} );
ok( "\N{HANGUL LETTER NIEUN-CIEUC}\N{MODIFIER LETTER SMALL H}" =~ m/<OtherLowercase>/, q{Match unanchored <OtherLowercase>} );

# OtherMath


ok( "\N{LEFT PARENTHESIS}" =~ m/^<OtherMath>$/, q{Match <OtherMath>} );
ok( "\N{LEFT PARENTHESIS}" !~ m/^<!OtherMath>.$/, q{Don't match negated <OtherMath>} );
ok( "\N{LEFT PARENTHESIS}" !~ m/^<-OtherMath>$/, q{Don't match inverted <OtherMath>} );
ok( "\x{B43A}"  !~ m/^<OtherMath>$/, q{Don't match unrelated <OtherMath>} );
ok( "\x{B43A}"  =~ m/^<!OtherMath>.$/, q{Match unrelated negated <OtherMath>} );
ok( "\x{B43A}"  =~ m/^<-OtherMath>$/, q{Match unrelated inverted <OtherMath>} );
ok( "\x{B43A}\N{LEFT PARENTHESIS}" =~ m/<OtherMath>/, q{Match unanchored <OtherMath>} );

# OtherUppercase


ok( "\N{ROMAN NUMERAL ONE}" =~ m/^<OtherUppercase>$/, q{Match <OtherUppercase>} );
ok( "\N{ROMAN NUMERAL ONE}" !~ m/^<!OtherUppercase>.$/, q{Don't match negated <OtherUppercase>} );
ok( "\N{ROMAN NUMERAL ONE}" !~ m/^<-OtherUppercase>$/, q{Don't match inverted <OtherUppercase>} );
ok( "\x{D246}"  !~ m/^<OtherUppercase>$/, q{Don't match unrelated <OtherUppercase>} );
ok( "\x{D246}"  =~ m/^<!OtherUppercase>.$/, q{Match unrelated negated <OtherUppercase>} );
ok( "\x{D246}"  =~ m/^<-OtherUppercase>$/, q{Match unrelated inverted <OtherUppercase>} );
ok( "\x{D246}\N{ROMAN NUMERAL ONE}" =~ m/<OtherUppercase>/, q{Match unanchored <OtherUppercase>} );

# QuotationMark


ok( "\N{QUOTATION MARK}" =~ m/^<QuotationMark>$/, q{Match <QuotationMark>} );
ok( "\N{QUOTATION MARK}" !~ m/^<!QuotationMark>.$/, q{Don't match negated <QuotationMark>} );
ok( "\N{QUOTATION MARK}" !~ m/^<-QuotationMark>$/, q{Don't match inverted <QuotationMark>} );
ok( "\x{C890}"  !~ m/^<QuotationMark>$/, q{Don't match unrelated <QuotationMark>} );
ok( "\x{C890}"  =~ m/^<!QuotationMark>.$/, q{Match unrelated negated <QuotationMark>} );
ok( "\x{C890}"  =~ m/^<-QuotationMark>$/, q{Match unrelated inverted <QuotationMark>} );
ok( "\x{C890}\N{QUOTATION MARK}" =~ m/<QuotationMark>/, q{Match unanchored <QuotationMark>} );

# Radical


ok( "\N{CJK RADICAL REPEAT}" =~ m/^<Radical>$/, q{Match <Radical>} );
ok( "\N{CJK RADICAL REPEAT}" !~ m/^<!Radical>.$/, q{Don't match negated <Radical>} );
ok( "\N{CJK RADICAL REPEAT}" !~ m/^<-Radical>$/, q{Don't match inverted <Radical>} );
ok( "\N{HANGUL JONGSEONG CHIEUCH}"  !~ m/^<Radical>$/, q{Don't match unrelated <Radical>} );
ok( "\N{HANGUL JONGSEONG CHIEUCH}"  =~ m/^<!Radical>.$/, q{Match unrelated negated <Radical>} );
ok( "\N{HANGUL JONGSEONG CHIEUCH}"  =~ m/^<-Radical>$/, q{Match unrelated inverted <Radical>} );
ok( "\N{HANGUL JONGSEONG CHIEUCH}\N{CJK RADICAL REPEAT}" =~ m/<Radical>/, q{Match unanchored <Radical>} );

# SoftDotted


ok( "\N{LATIN SMALL LETTER I}" =~ m/^<SoftDotted>$/, q{Match <SoftDotted>} );
ok( "\N{LATIN SMALL LETTER I}" !~ m/^<!SoftDotted>.$/, q{Don't match negated <SoftDotted>} );
ok( "\N{LATIN SMALL LETTER I}" !~ m/^<-SoftDotted>$/, q{Don't match inverted <SoftDotted>} );
ok( "\x{ADEF}"  !~ m/^<SoftDotted>$/, q{Don't match unrelated <SoftDotted>} );
ok( "\x{ADEF}"  =~ m/^<!SoftDotted>.$/, q{Match unrelated negated <SoftDotted>} );
ok( "\x{ADEF}"  =~ m/^<-SoftDotted>$/, q{Match unrelated inverted <SoftDotted>} );
ok( "\N{DOLLAR SIGN}" !~ m/^<SoftDotted>$/, q{Don't match related <SoftDotted>} );
ok( "\N{DOLLAR SIGN}" =~ m/^<!SoftDotted>.$/, q{Match related negated <SoftDotted>} );
ok( "\N{DOLLAR SIGN}" =~ m/^<-SoftDotted>$/, q{Match related inverted <SoftDotted>} );
ok( "\x{ADEF}\N{DOLLAR SIGN}\N{LATIN SMALL LETTER I}" =~ m/<SoftDotted>/, q{Match unanchored <SoftDotted>} );

# TerminalPunctuation


ok( "\N{EXCLAMATION MARK}" =~ m/^<TerminalPunctuation>$/, q{Match <TerminalPunctuation>} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<!TerminalPunctuation>.$/, q{Don't match negated <TerminalPunctuation>} );
ok( "\N{EXCLAMATION MARK}" !~ m/^<-TerminalPunctuation>$/, q{Don't match inverted <TerminalPunctuation>} );
ok( "\x{3C9D}"  !~ m/^<TerminalPunctuation>$/, q{Don't match unrelated <TerminalPunctuation>} );
ok( "\x{3C9D}"  =~ m/^<!TerminalPunctuation>.$/, q{Match unrelated negated <TerminalPunctuation>} );
ok( "\x{3C9D}"  =~ m/^<-TerminalPunctuation>$/, q{Match unrelated inverted <TerminalPunctuation>} );
ok( "\x{3C9D}\N{EXCLAMATION MARK}" =~ m/<TerminalPunctuation>/, q{Match unanchored <TerminalPunctuation>} );

# UnifiedIdeograph


ok( "\x{7896}" =~ m/^<UnifiedIdeograph>$/, q{Match <UnifiedIdeograph>} );
ok( "\x{7896}" !~ m/^<!UnifiedIdeograph>.$/, q{Don't match negated <UnifiedIdeograph>} );
ok( "\x{7896}" !~ m/^<-UnifiedIdeograph>$/, q{Don't match inverted <UnifiedIdeograph>} );
ok( "\x{9FA6}"  !~ m/^<UnifiedIdeograph>$/, q{Don't match unrelated <UnifiedIdeograph>} );
ok( "\x{9FA6}"  =~ m/^<!UnifiedIdeograph>.$/, q{Match unrelated negated <UnifiedIdeograph>} );
ok( "\x{9FA6}"  =~ m/^<-UnifiedIdeograph>$/, q{Match unrelated inverted <UnifiedIdeograph>} );
ok( "\x{9FA6}\x{7896}" =~ m/<UnifiedIdeograph>/, q{Match unanchored <UnifiedIdeograph>} );

# WhiteSpace


ok( "\N{CHARACTER TABULATION}" =~ m/^<WhiteSpace>$/, q{Match <WhiteSpace>} );
ok( "\N{CHARACTER TABULATION}" !~ m/^<!WhiteSpace>.$/, q{Don't match negated <WhiteSpace>} );
ok( "\N{CHARACTER TABULATION}" !~ m/^<-WhiteSpace>$/, q{Don't match inverted <WhiteSpace>} );
ok( "\x{6358}"  !~ m/^<WhiteSpace>$/, q{Don't match unrelated <WhiteSpace>} );
ok( "\x{6358}"  =~ m/^<!WhiteSpace>.$/, q{Match unrelated negated <WhiteSpace>} );
ok( "\x{6358}"  =~ m/^<-WhiteSpace>$/, q{Match unrelated inverted <WhiteSpace>} );
ok( "\x{6358}\N{CHARACTER TABULATION}" =~ m/<WhiteSpace>/, q{Match unanchored <WhiteSpace>} );

# Alphabetic      # Lu + Ll + Lt + Lm + Lo + OtherAlphabetic


ok( "\N{DEVANAGARI SIGN CANDRABINDU}" =~ m/^<Alphabetic>$/, q{Match (Lu + Ll + Lt + Lm + Lo + OtherAlphabetic)} );
ok( "\N{DEVANAGARI SIGN CANDRABINDU}" !~ m/^<!Alphabetic>.$/, q{Don't match negated (Lu + Ll + Lt + Lm + Lo + OtherAlphabetic)} );
ok( "\N{DEVANAGARI SIGN CANDRABINDU}" !~ m/^<-Alphabetic>$/, q{Don't match inverted (Lu + Ll + Lt + Lm + Lo + OtherAlphabetic)} );
ok( "\x{0855}"  !~ m/^<Alphabetic>$/, q{Don't match unrelated (Lu + Ll + Lt + Lm + Lo + OtherAlphabetic)} );
ok( "\x{0855}"  =~ m/^<!Alphabetic>.$/, q{Match unrelated negated (Lu + Ll + Lt + Lm + Lo + OtherAlphabetic)} );
ok( "\x{0855}"  =~ m/^<-Alphabetic>$/, q{Match unrelated inverted (Lu + Ll + Lt + Lm + Lo + OtherAlphabetic)} );
ok( "\x{0855}\N{DEVANAGARI SIGN CANDRABINDU}" =~ m/<Alphabetic>/, q{Match unanchored (Lu + Ll + Lt + Lm + Lo + OtherAlphabetic)} );

# Lowercase       # Ll + OtherLowercase


ok( "\N{LATIN SMALL LETTER A}" =~ m/^<Lowercase>$/, q{Match (Ll + OtherLowercase)} );
ok( "\N{LATIN SMALL LETTER A}" !~ m/^<!Lowercase>.$/, q{Don't match negated (Ll + OtherLowercase)} );
ok( "\N{LATIN SMALL LETTER A}" !~ m/^<-Lowercase>$/, q{Don't match inverted (Ll + OtherLowercase)} );
ok( "\x{6220}"  !~ m/^<Lowercase>$/, q{Don't match unrelated (Ll + OtherLowercase)} );
ok( "\x{6220}"  =~ m/^<!Lowercase>.$/, q{Match unrelated negated (Ll + OtherLowercase)} );
ok( "\x{6220}"  =~ m/^<-Lowercase>$/, q{Match unrelated inverted (Ll + OtherLowercase)} );
ok( "\x{6220}" !~ m/^<Lowercase>$/, q{Don't match related (Ll + OtherLowercase)} );
ok( "\x{6220}" =~ m/^<!Lowercase>.$/, q{Match related negated (Ll + OtherLowercase)} );
ok( "\x{6220}" =~ m/^<-Lowercase>$/, q{Match related inverted (Ll + OtherLowercase)} );
ok( "\x{6220}\x{6220}\N{LATIN SMALL LETTER A}" =~ m/<Lowercase>/, q{Match unanchored (Ll + OtherLowercase)} );

# Uppercase       # Lu + OtherUppercase


ok( "\N{LATIN CAPITAL LETTER A}" =~ m/^<Uppercase>$/, q{Match (Lu + OtherUppercase)} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<!Uppercase>.$/, q{Don't match negated (Lu + OtherUppercase)} );
ok( "\N{LATIN CAPITAL LETTER A}" !~ m/^<-Uppercase>$/, q{Don't match inverted (Lu + OtherUppercase)} );
ok( "\x{C080}"  !~ m/^<Uppercase>$/, q{Don't match unrelated (Lu + OtherUppercase)} );
ok( "\x{C080}"  =~ m/^<!Uppercase>.$/, q{Match unrelated negated (Lu + OtherUppercase)} );
ok( "\x{C080}"  =~ m/^<-Uppercase>$/, q{Match unrelated inverted (Lu + OtherUppercase)} );
ok( "\x{C080}\N{LATIN CAPITAL LETTER A}" =~ m/<Uppercase>/, q{Match unanchored (Lu + OtherUppercase)} );

# Math            # Sm + OtherMath


ok( "\N{LEFT PARENTHESIS}" =~ m/^<Math>$/, q{Match (Sm + OtherMath)} );
ok( "\N{LEFT PARENTHESIS}" !~ m/^<!Math>.$/, q{Don't match negated (Sm + OtherMath)} );
ok( "\N{LEFT PARENTHESIS}" !~ m/^<-Math>$/, q{Don't match inverted (Sm + OtherMath)} );
ok( "\x{D4D2}"  !~ m/^<Math>$/, q{Don't match unrelated (Sm + OtherMath)} );
ok( "\x{D4D2}"  =~ m/^<!Math>.$/, q{Match unrelated negated (Sm + OtherMath)} );
ok( "\x{D4D2}"  =~ m/^<-Math>$/, q{Match unrelated inverted (Sm + OtherMath)} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<Math>$/, q{Don't match related (Sm + OtherMath)} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<!Math>.$/, q{Match related negated (Sm + OtherMath)} );
ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<-Math>$/, q{Match related inverted (Sm + OtherMath)} );
ok( "\x{D4D2}\N{COMBINING GRAVE ACCENT}\N{LEFT PARENTHESIS}" =~ m/<Math>/, q{Match unanchored (Sm + OtherMath)} );

# ID_Start        # Lu + Ll + Lt + Lm + Lo + Nl


ok( "\x{C276}" =~ m/^<ID_Start>$/, q{Match (Lu + Ll + Lt + Lm + Lo + Nl)} );
ok( "\x{C276}" !~ m/^<!ID_Start>.$/, q{Don't match negated (Lu + Ll + Lt + Lm + Lo + Nl)} );
ok( "\x{C276}" !~ m/^<-ID_Start>$/, q{Don't match inverted (Lu + Ll + Lt + Lm + Lo + Nl)} );
ok( "\x{D7A4}"  !~ m/^<ID_Start>$/, q{Don't match unrelated (Lu + Ll + Lt + Lm + Lo + Nl)} );
ok( "\x{D7A4}"  =~ m/^<!ID_Start>.$/, q{Match unrelated negated (Lu + Ll + Lt + Lm + Lo + Nl)} );
ok( "\x{D7A4}"  =~ m/^<-ID_Start>$/, q{Match unrelated inverted (Lu + Ll + Lt + Lm + Lo + Nl)} );
ok( "\x{D7A4}\x{C276}" =~ m/<ID_Start>/, q{Match unanchored (Lu + Ll + Lt + Lm + Lo + Nl)} );

# ID_Continue     # ID_Start + Mn + Mc + Nd + Pc


ok( "\x{949B}" =~ m/^<ID_Continue>$/, q{Match (ID_Start + Mn + Mc + Nd + Pc)} );
ok( "\x{949B}" !~ m/^<!ID_Continue>.$/, q{Don't match negated (ID_Start + Mn + Mc + Nd + Pc)} );
ok( "\x{949B}" !~ m/^<-ID_Continue>$/, q{Don't match inverted (ID_Start + Mn + Mc + Nd + Pc)} );
ok( "\x{9FA6}"  !~ m/^<ID_Continue>$/, q{Don't match unrelated (ID_Start + Mn + Mc + Nd + Pc)} );
ok( "\x{9FA6}"  =~ m/^<!ID_Continue>.$/, q{Match unrelated negated (ID_Start + Mn + Mc + Nd + Pc)} );
ok( "\x{9FA6}"  =~ m/^<-ID_Continue>$/, q{Match unrelated inverted (ID_Start + Mn + Mc + Nd + Pc)} );
ok( "\x{9FA6}\x{949B}" =~ m/<ID_Continue>/, q{Match unanchored (ID_Start + Mn + Mc + Nd + Pc)} );

# Any             # Any character


ok( "\x{C709}" =~ m/^<Any>$/, q{Match (Any character)} );
ok( "\x{C709}" !~ m/^<!Any>.$/, q{Don't match negated (Any character)} );
ok( "\x{C709}" !~ m/^<-Any>$/, q{Don't match inverted (Any character)} );
ok( "\x{C709}" =~ m/<Any>/, q{Match unanchored (Any character)} );

# Assigned        # Any non-Cn character (i.e. synonym for \P{Cn})


ok( "\x{C99D}" =~ m/^<Assigned>$/, q{Match (Any non-Cn character (i.e. synonym for \P{Cn}))} );
ok( "\x{C99D}" !~ m/^<!Assigned>.$/, q{Don't match negated (Any non-Cn character (i.e. synonym for \P{Cn}))} );
ok( "\x{C99D}" !~ m/^<-Assigned>$/, q{Don't match inverted (Any non-Cn character (i.e. synonym for \P{Cn}))} );
ok( "\x{D7A4}"  !~ m/^<Assigned>$/, q{Don't match unrelated (Any non-Cn character (i.e. synonym for \P{Cn}))} );
ok( "\x{D7A4}"  =~ m/^<!Assigned>.$/, q{Match unrelated negated (Any non-Cn character (i.e. synonym for \P{Cn}))} );
ok( "\x{D7A4}"  =~ m/^<-Assigned>$/, q{Match unrelated inverted (Any non-Cn character (i.e. synonym for \P{Cn}))} );
ok( "\x{D7A4}\x{C99D}" =~ m/<Assigned>/, q{Match unanchored (Any non-Cn character (i.e. synonym for \P{Cn}))} );

# Unassigned      # Synonym for \p{Cn}


ok( "\x{27EC}" =~ m/^<Unassigned>$/, q{Match (Synonym for \p{Cn})} );
ok( "\x{27EC}" !~ m/^<!Unassigned>.$/, q{Don't match negated (Synonym for \p{Cn})} );
ok( "\x{27EC}" !~ m/^<-Unassigned>$/, q{Don't match inverted (Synonym for \p{Cn})} );
ok( "\N{RIGHT OUTER JOIN}"  !~ m/^<Unassigned>$/, q{Don't match unrelated (Synonym for \p{Cn})} );
ok( "\N{RIGHT OUTER JOIN}"  =~ m/^<!Unassigned>.$/, q{Match unrelated negated (Synonym for \p{Cn})} );
ok( "\N{RIGHT OUTER JOIN}"  =~ m/^<-Unassigned>$/, q{Match unrelated inverted (Synonym for \p{Cn})} );
ok( "\N{RIGHT OUTER JOIN}\x{27EC}" =~ m/<Unassigned>/, q{Match unanchored (Synonym for \p{Cn})} );

# Common          # Codepoint not explicitly assigned to a script


ok( "\x{0C7E}" =~ m/^<Common>$/, q{Match (Codepoint not explicitly assigned to a script)} );
ok( "\x{0C7E}" !~ m/^<!Common>.$/, q{Don't match negated (Codepoint not explicitly assigned to a script)} );
ok( "\x{0C7E}" !~ m/^<-Common>$/, q{Don't match inverted (Codepoint not explicitly assigned to a script)} );
ok( "\N{KANNADA SIGN ANUSVARA}"  !~ m/^<Common>$/, q{Don't match unrelated (Codepoint not explicitly assigned to a script)} );
ok( "\N{KANNADA SIGN ANUSVARA}"  =~ m/^<!Common>.$/, q{Match unrelated negated (Codepoint not explicitly assigned to a script)} );
ok( "\N{KANNADA SIGN ANUSVARA}"  =~ m/^<-Common>$/, q{Match unrelated inverted (Codepoint not explicitly assigned to a script)} );
ok( "\N{KHMER VOWEL INHERENT AQ}" !~ m/^<Common>$/, q{Don't match related (Codepoint not explicitly assigned to a script)} );
ok( "\N{KHMER VOWEL INHERENT AQ}" =~ m/^<!Common>.$/, q{Match related negated (Codepoint not explicitly assigned to a script)} );
ok( "\N{KHMER VOWEL INHERENT AQ}" =~ m/^<-Common>$/, q{Match related inverted (Codepoint not explicitly assigned to a script)} );
ok( "\N{KANNADA SIGN ANUSVARA}\N{KHMER VOWEL INHERENT AQ}\x{0C7E}" =~ m/<Common>/, q{Match unanchored (Codepoint not explicitly assigned to a script)} );

# InAlphabeticPresentationForms


ok( "\x{531A}"  !~ m/^<InAlphabeticPresentationForms>$/, q{Don't match unrelated <InAlphabeticPresentationForms>} );
ok( "\x{531A}"  =~ m/^<!InAlphabeticPresentationForms>.$/, q{Match unrelated negated <InAlphabeticPresentationForms>} );
ok( "\x{531A}"  =~ m/^<-InAlphabeticPresentationForms>$/, q{Match unrelated inverted <InAlphabeticPresentationForms>} );

# InArabic


ok( "\N{ARABIC NUMBER SIGN}" =~ m/^<InArabic>$/, q{Match <InArabic>} );
ok( "\N{ARABIC NUMBER SIGN}" !~ m/^<!InArabic>.$/, q{Don't match negated <InArabic>} );
ok( "\N{ARABIC NUMBER SIGN}" !~ m/^<-InArabic>$/, q{Don't match inverted <InArabic>} );
ok( "\x{7315}"  !~ m/^<InArabic>$/, q{Don't match unrelated <InArabic>} );
ok( "\x{7315}"  =~ m/^<!InArabic>.$/, q{Match unrelated negated <InArabic>} );
ok( "\x{7315}"  =~ m/^<-InArabic>$/, q{Match unrelated inverted <InArabic>} );
ok( "\x{7315}\N{ARABIC NUMBER SIGN}" =~ m/<InArabic>/, q{Match unanchored <InArabic>} );

# InArabicPresentationFormsA


ok( "\x{8340}"  !~ m/^<InArabicPresentationFormsA>$/, q{Don't match unrelated <InArabicPresentationFormsA>} );
ok( "\x{8340}"  =~ m/^<!InArabicPresentationFormsA>.$/, q{Match unrelated negated <InArabicPresentationFormsA>} );
ok( "\x{8340}"  =~ m/^<-InArabicPresentationFormsA>$/, q{Match unrelated inverted <InArabicPresentationFormsA>} );

# InArabicPresentationFormsB


ok( "\x{BEEC}"  !~ m/^<InArabicPresentationFormsB>$/, q{Don't match unrelated <InArabicPresentationFormsB>} );
ok( "\x{BEEC}"  =~ m/^<!InArabicPresentationFormsB>.$/, q{Match unrelated negated <InArabicPresentationFormsB>} );
ok( "\x{BEEC}"  =~ m/^<-InArabicPresentationFormsB>$/, q{Match unrelated inverted <InArabicPresentationFormsB>} );

# InArmenian


ok( "\x{0530}" =~ m/^<InArmenian>$/, q{Match <InArmenian>} );
ok( "\x{0530}" !~ m/^<!InArmenian>.$/, q{Don't match negated <InArmenian>} );
ok( "\x{0530}" !~ m/^<-InArmenian>$/, q{Don't match inverted <InArmenian>} );
ok( "\x{3B0D}"  !~ m/^<InArmenian>$/, q{Don't match unrelated <InArmenian>} );
ok( "\x{3B0D}"  =~ m/^<!InArmenian>.$/, q{Match unrelated negated <InArmenian>} );
ok( "\x{3B0D}"  =~ m/^<-InArmenian>$/, q{Match unrelated inverted <InArmenian>} );
ok( "\x{3B0D}\x{0530}" =~ m/<InArmenian>/, q{Match unanchored <InArmenian>} );

# InArrows


ok( "\N{LEFTWARDS ARROW}" =~ m/^<InArrows>$/, q{Match <InArrows>} );
ok( "\N{LEFTWARDS ARROW}" !~ m/^<!InArrows>.$/, q{Don't match negated <InArrows>} );
ok( "\N{LEFTWARDS ARROW}" !~ m/^<-InArrows>$/, q{Don't match inverted <InArrows>} );
ok( "\x{C401}"  !~ m/^<InArrows>$/, q{Don't match unrelated <InArrows>} );
ok( "\x{C401}"  =~ m/^<!InArrows>.$/, q{Match unrelated negated <InArrows>} );
ok( "\x{C401}"  =~ m/^<-InArrows>$/, q{Match unrelated inverted <InArrows>} );
ok( "\x{C401}\N{LEFTWARDS ARROW}" =~ m/<InArrows>/, q{Match unanchored <InArrows>} );

# InBasicLatin


ok( "\N{NULL}" =~ m/^<InBasicLatin>$/, q{Match <InBasicLatin>} );
ok( "\N{NULL}" !~ m/^<!InBasicLatin>.$/, q{Don't match negated <InBasicLatin>} );
ok( "\N{NULL}" !~ m/^<-InBasicLatin>$/, q{Don't match inverted <InBasicLatin>} );
ok( "\x{46EA}"  !~ m/^<InBasicLatin>$/, q{Don't match unrelated <InBasicLatin>} );
ok( "\x{46EA}"  =~ m/^<!InBasicLatin>.$/, q{Match unrelated negated <InBasicLatin>} );
ok( "\x{46EA}"  =~ m/^<-InBasicLatin>$/, q{Match unrelated inverted <InBasicLatin>} );
ok( "\x{46EA}\N{NULL}" =~ m/<InBasicLatin>/, q{Match unanchored <InBasicLatin>} );

# InBengali


ok( "\x{0980}" =~ m/^<InBengali>$/, q{Match <InBengali>} );
ok( "\x{0980}" !~ m/^<!InBengali>.$/, q{Don't match negated <InBengali>} );
ok( "\x{0980}" !~ m/^<-InBengali>$/, q{Don't match inverted <InBengali>} );
ok( "\N{YI SYLLABLE HMY}"  !~ m/^<InBengali>$/, q{Don't match unrelated <InBengali>} );
ok( "\N{YI SYLLABLE HMY}"  =~ m/^<!InBengali>.$/, q{Match unrelated negated <InBengali>} );
ok( "\N{YI SYLLABLE HMY}"  =~ m/^<-InBengali>$/, q{Match unrelated inverted <InBengali>} );
ok( "\N{YI SYLLABLE HMY}\x{0980}" =~ m/<InBengali>/, q{Match unanchored <InBengali>} );

# InBlockElements


ok( "\N{UPPER HALF BLOCK}" =~ m/^<InBlockElements>$/, q{Match <InBlockElements>} );
ok( "\N{UPPER HALF BLOCK}" !~ m/^<!InBlockElements>.$/, q{Don't match negated <InBlockElements>} );
ok( "\N{UPPER HALF BLOCK}" !~ m/^<-InBlockElements>$/, q{Don't match inverted <InBlockElements>} );
ok( "\x{5F41}"  !~ m/^<InBlockElements>$/, q{Don't match unrelated <InBlockElements>} );
ok( "\x{5F41}"  =~ m/^<!InBlockElements>.$/, q{Match unrelated negated <InBlockElements>} );
ok( "\x{5F41}"  =~ m/^<-InBlockElements>$/, q{Match unrelated inverted <InBlockElements>} );
ok( "\x{5F41}\N{UPPER HALF BLOCK}" =~ m/<InBlockElements>/, q{Match unanchored <InBlockElements>} );

# InBopomofo


ok( "\x{3100}" =~ m/^<InBopomofo>$/, q{Match <InBopomofo>} );
ok( "\x{3100}" !~ m/^<!InBopomofo>.$/, q{Don't match negated <InBopomofo>} );
ok( "\x{3100}" !~ m/^<-InBopomofo>$/, q{Don't match inverted <InBopomofo>} );
ok( "\x{9F8E}"  !~ m/^<InBopomofo>$/, q{Don't match unrelated <InBopomofo>} );
ok( "\x{9F8E}"  =~ m/^<!InBopomofo>.$/, q{Match unrelated negated <InBopomofo>} );
ok( "\x{9F8E}"  =~ m/^<-InBopomofo>$/, q{Match unrelated inverted <InBopomofo>} );
ok( "\x{9F8E}\x{3100}" =~ m/<InBopomofo>/, q{Match unanchored <InBopomofo>} );

# InBopomofoExtended


ok( "\N{BOPOMOFO LETTER BU}" =~ m/^<InBopomofoExtended>$/, q{Match <InBopomofoExtended>} );
ok( "\N{BOPOMOFO LETTER BU}" !~ m/^<!InBopomofoExtended>.$/, q{Don't match negated <InBopomofoExtended>} );
ok( "\N{BOPOMOFO LETTER BU}" !~ m/^<-InBopomofoExtended>$/, q{Don't match inverted <InBopomofoExtended>} );
ok( "\x{43A6}"  !~ m/^<InBopomofoExtended>$/, q{Don't match unrelated <InBopomofoExtended>} );
ok( "\x{43A6}"  =~ m/^<!InBopomofoExtended>.$/, q{Match unrelated negated <InBopomofoExtended>} );
ok( "\x{43A6}"  =~ m/^<-InBopomofoExtended>$/, q{Match unrelated inverted <InBopomofoExtended>} );
ok( "\x{43A6}\N{BOPOMOFO LETTER BU}" =~ m/<InBopomofoExtended>/, q{Match unanchored <InBopomofoExtended>} );

# InBoxDrawing


ok( "\N{BOX DRAWINGS LIGHT HORIZONTAL}" =~ m/^<InBoxDrawing>$/, q{Match <InBoxDrawing>} );
ok( "\N{BOX DRAWINGS LIGHT HORIZONTAL}" !~ m/^<!InBoxDrawing>.$/, q{Don't match negated <InBoxDrawing>} );
ok( "\N{BOX DRAWINGS LIGHT HORIZONTAL}" !~ m/^<-InBoxDrawing>$/, q{Don't match inverted <InBoxDrawing>} );
ok( "\x{7865}"  !~ m/^<InBoxDrawing>$/, q{Don't match unrelated <InBoxDrawing>} );
ok( "\x{7865}"  =~ m/^<!InBoxDrawing>.$/, q{Match unrelated negated <InBoxDrawing>} );
ok( "\x{7865}"  =~ m/^<-InBoxDrawing>$/, q{Match unrelated inverted <InBoxDrawing>} );
ok( "\x{7865}\N{BOX DRAWINGS LIGHT HORIZONTAL}" =~ m/<InBoxDrawing>/, q{Match unanchored <InBoxDrawing>} );

# InBraillePatterns


ok( "\N{BRAILLE PATTERN BLANK}" =~ m/^<InBraillePatterns>$/, q{Match <InBraillePatterns>} );
ok( "\N{BRAILLE PATTERN BLANK}" !~ m/^<!InBraillePatterns>.$/, q{Don't match negated <InBraillePatterns>} );
ok( "\N{BRAILLE PATTERN BLANK}" !~ m/^<-InBraillePatterns>$/, q{Don't match inverted <InBraillePatterns>} );
ok( "\N{THAI CHARACTER KHO KHAI}"  !~ m/^<InBraillePatterns>$/, q{Don't match unrelated <InBraillePatterns>} );
ok( "\N{THAI CHARACTER KHO KHAI}"  =~ m/^<!InBraillePatterns>.$/, q{Match unrelated negated <InBraillePatterns>} );
ok( "\N{THAI CHARACTER KHO KHAI}"  =~ m/^<-InBraillePatterns>$/, q{Match unrelated inverted <InBraillePatterns>} );
ok( "\N{THAI CHARACTER KHO KHAI}\N{BRAILLE PATTERN BLANK}" =~ m/<InBraillePatterns>/, q{Match unanchored <InBraillePatterns>} );

# InBuhid


ok( "\N{BUHID LETTER A}" =~ m/^<InBuhid>$/, q{Match <InBuhid>} );
ok( "\N{BUHID LETTER A}" !~ m/^<!InBuhid>.$/, q{Don't match negated <InBuhid>} );
ok( "\N{BUHID LETTER A}" !~ m/^<-InBuhid>$/, q{Don't match inverted <InBuhid>} );
ok( "\x{D208}"  !~ m/^<InBuhid>$/, q{Don't match unrelated <InBuhid>} );
ok( "\x{D208}"  =~ m/^<!InBuhid>.$/, q{Match unrelated negated <InBuhid>} );
ok( "\x{D208}"  =~ m/^<-InBuhid>$/, q{Match unrelated inverted <InBuhid>} );
ok( "\x{D208}\N{BUHID LETTER A}" =~ m/<InBuhid>/, q{Match unanchored <InBuhid>} );

# InByzantineMusicalSymbols


ok( "\x{9B1D}"  !~ m/^<InByzantineMusicalSymbols>$/, q{Don't match unrelated <InByzantineMusicalSymbols>} );
ok( "\x{9B1D}"  =~ m/^<!InByzantineMusicalSymbols>.$/, q{Match unrelated negated <InByzantineMusicalSymbols>} );
ok( "\x{9B1D}"  =~ m/^<-InByzantineMusicalSymbols>$/, q{Match unrelated inverted <InByzantineMusicalSymbols>} );

# InCJKCompatibility


ok( "\N{SQUARE APAATO}" =~ m/^<InCJKCompatibility>$/, q{Match <InCJKCompatibility>} );
ok( "\N{SQUARE APAATO}" !~ m/^<!InCJKCompatibility>.$/, q{Don't match negated <InCJKCompatibility>} );
ok( "\N{SQUARE APAATO}" !~ m/^<-InCJKCompatibility>$/, q{Don't match inverted <InCJKCompatibility>} );
ok( "\x{B8A5}"  !~ m/^<InCJKCompatibility>$/, q{Don't match unrelated <InCJKCompatibility>} );
ok( "\x{B8A5}"  =~ m/^<!InCJKCompatibility>.$/, q{Match unrelated negated <InCJKCompatibility>} );
ok( "\x{B8A5}"  =~ m/^<-InCJKCompatibility>$/, q{Match unrelated inverted <InCJKCompatibility>} );
ok( "\x{B8A5}\N{SQUARE APAATO}" =~ m/<InCJKCompatibility>/, q{Match unanchored <InCJKCompatibility>} );

# InCJKCompatibilityForms


ok( "\x{3528}"  !~ m/^<InCJKCompatibilityForms>$/, q{Don't match unrelated <InCJKCompatibilityForms>} );
ok( "\x{3528}"  =~ m/^<!InCJKCompatibilityForms>.$/, q{Match unrelated negated <InCJKCompatibilityForms>} );
ok( "\x{3528}"  =~ m/^<-InCJKCompatibilityForms>$/, q{Match unrelated inverted <InCJKCompatibilityForms>} );

# InCJKCompatibilityIdeographs


ok( "\x{69F7}"  !~ m/^<InCJKCompatibilityIdeographs>$/, q{Don't match unrelated <InCJKCompatibilityIdeographs>} );
ok( "\x{69F7}"  =~ m/^<!InCJKCompatibilityIdeographs>.$/, q{Match unrelated negated <InCJKCompatibilityIdeographs>} );
ok( "\x{69F7}"  =~ m/^<-InCJKCompatibilityIdeographs>$/, q{Match unrelated inverted <InCJKCompatibilityIdeographs>} );

# InCJKCompatibilityIdeographsSupplement


ok( "\N{CANADIAN SYLLABICS NUNAVIK HO}"  !~ m/^<InCJKCompatibilityIdeographsSupplement>$/, q{Don't match unrelated <InCJKCompatibilityIdeographsSupplement>} );
ok( "\N{CANADIAN SYLLABICS NUNAVIK HO}"  =~ m/^<!InCJKCompatibilityIdeographsSupplement>.$/, q{Match unrelated negated <InCJKCompatibilityIdeographsSupplement>} );
ok( "\N{CANADIAN SYLLABICS NUNAVIK HO}"  =~ m/^<-InCJKCompatibilityIdeographsSupplement>$/, q{Match unrelated inverted <InCJKCompatibilityIdeographsSupplement>} );

# InCJKRadicalsSupplement


ok( "\N{CJK RADICAL REPEAT}" =~ m/^<InCJKRadicalsSupplement>$/, q{Match <InCJKRadicalsSupplement>} );
ok( "\N{CJK RADICAL REPEAT}" !~ m/^<!InCJKRadicalsSupplement>.$/, q{Don't match negated <InCJKRadicalsSupplement>} );
ok( "\N{CJK RADICAL REPEAT}" !~ m/^<-InCJKRadicalsSupplement>$/, q{Don't match inverted <InCJKRadicalsSupplement>} );
ok( "\x{37B4}"  !~ m/^<InCJKRadicalsSupplement>$/, q{Don't match unrelated <InCJKRadicalsSupplement>} );
ok( "\x{37B4}"  =~ m/^<!InCJKRadicalsSupplement>.$/, q{Match unrelated negated <InCJKRadicalsSupplement>} );
ok( "\x{37B4}"  =~ m/^<-InCJKRadicalsSupplement>$/, q{Match unrelated inverted <InCJKRadicalsSupplement>} );
ok( "\x{37B4}\N{CJK RADICAL REPEAT}" =~ m/<InCJKRadicalsSupplement>/, q{Match unanchored <InCJKRadicalsSupplement>} );

# InCJKSymbolsAndPunctuation


ok( "\N{IDEOGRAPHIC SPACE}" =~ m/^<InCJKSymbolsAndPunctuation>$/, q{Match <InCJKSymbolsAndPunctuation>} );
ok( "\N{IDEOGRAPHIC SPACE}" !~ m/^<!InCJKSymbolsAndPunctuation>.$/, q{Don't match negated <InCJKSymbolsAndPunctuation>} );
ok( "\N{IDEOGRAPHIC SPACE}" !~ m/^<-InCJKSymbolsAndPunctuation>$/, q{Don't match inverted <InCJKSymbolsAndPunctuation>} );
ok( "\x{80AA}"  !~ m/^<InCJKSymbolsAndPunctuation>$/, q{Don't match unrelated <InCJKSymbolsAndPunctuation>} );
ok( "\x{80AA}"  =~ m/^<!InCJKSymbolsAndPunctuation>.$/, q{Match unrelated negated <InCJKSymbolsAndPunctuation>} );
ok( "\x{80AA}"  =~ m/^<-InCJKSymbolsAndPunctuation>$/, q{Match unrelated inverted <InCJKSymbolsAndPunctuation>} );
ok( "\x{80AA}\N{IDEOGRAPHIC SPACE}" =~ m/<InCJKSymbolsAndPunctuation>/, q{Match unanchored <InCJKSymbolsAndPunctuation>} );

# InCJKUnifiedIdeographs


ok( "\x{4E00}" =~ m/^<InCJKUnifiedIdeographs>$/, q{Match <InCJKUnifiedIdeographs>} );
ok( "\x{4E00}" !~ m/^<!InCJKUnifiedIdeographs>.$/, q{Don't match negated <InCJKUnifiedIdeographs>} );
ok( "\x{4E00}" !~ m/^<-InCJKUnifiedIdeographs>$/, q{Don't match inverted <InCJKUnifiedIdeographs>} );
ok( "\x{3613}"  !~ m/^<InCJKUnifiedIdeographs>$/, q{Don't match unrelated <InCJKUnifiedIdeographs>} );
ok( "\x{3613}"  =~ m/^<!InCJKUnifiedIdeographs>.$/, q{Match unrelated negated <InCJKUnifiedIdeographs>} );
ok( "\x{3613}"  =~ m/^<-InCJKUnifiedIdeographs>$/, q{Match unrelated inverted <InCJKUnifiedIdeographs>} );
ok( "\x{3613}\x{4E00}" =~ m/<InCJKUnifiedIdeographs>/, q{Match unanchored <InCJKUnifiedIdeographs>} );

# InCJKUnifiedIdeographsExtensionA


ok( "\x{3400}" =~ m/^<InCJKUnifiedIdeographsExtensionA>$/, q{Match <InCJKUnifiedIdeographsExtensionA>} );
ok( "\x{3400}" !~ m/^<!InCJKUnifiedIdeographsExtensionA>.$/, q{Don't match negated <InCJKUnifiedIdeographsExtensionA>} );
ok( "\x{3400}" !~ m/^<-InCJKUnifiedIdeographsExtensionA>$/, q{Don't match inverted <InCJKUnifiedIdeographsExtensionA>} );
ok( "\N{SQUARE HOORU}"  !~ m/^<InCJKUnifiedIdeographsExtensionA>$/, q{Don't match unrelated <InCJKUnifiedIdeographsExtensionA>} );
ok( "\N{SQUARE HOORU}"  =~ m/^<!InCJKUnifiedIdeographsExtensionA>.$/, q{Match unrelated negated <InCJKUnifiedIdeographsExtensionA>} );
ok( "\N{SQUARE HOORU}"  =~ m/^<-InCJKUnifiedIdeographsExtensionA>$/, q{Match unrelated inverted <InCJKUnifiedIdeographsExtensionA>} );
ok( "\N{SQUARE HOORU}\x{3400}" =~ m/<InCJKUnifiedIdeographsExtensionA>/, q{Match unanchored <InCJKUnifiedIdeographsExtensionA>} );

# InCJKUnifiedIdeographsExtensionB


ok( "\x{AC3B}"  !~ m/^<InCJKUnifiedIdeographsExtensionB>$/, q{Don't match unrelated <InCJKUnifiedIdeographsExtensionB>} );
ok( "\x{AC3B}"  =~ m/^<!InCJKUnifiedIdeographsExtensionB>.$/, q{Match unrelated negated <InCJKUnifiedIdeographsExtensionB>} );
ok( "\x{AC3B}"  =~ m/^<-InCJKUnifiedIdeographsExtensionB>$/, q{Match unrelated inverted <InCJKUnifiedIdeographsExtensionB>} );

# InCherokee


ok( "\N{CHEROKEE LETTER A}" =~ m/^<InCherokee>$/, q{Match <InCherokee>} );
ok( "\N{CHEROKEE LETTER A}" !~ m/^<!InCherokee>.$/, q{Don't match negated <InCherokee>} );
ok( "\N{CHEROKEE LETTER A}" !~ m/^<-InCherokee>$/, q{Don't match inverted <InCherokee>} );
ok( "\x{985F}"  !~ m/^<InCherokee>$/, q{Don't match unrelated <InCherokee>} );
ok( "\x{985F}"  =~ m/^<!InCherokee>.$/, q{Match unrelated negated <InCherokee>} );
ok( "\x{985F}"  =~ m/^<-InCherokee>$/, q{Match unrelated inverted <InCherokee>} );
ok( "\x{985F}\N{CHEROKEE LETTER A}" =~ m/<InCherokee>/, q{Match unanchored <InCherokee>} );

# InCombiningDiacriticalMarks


ok( "\N{COMBINING GRAVE ACCENT}" =~ m/^<InCombiningDiacriticalMarks>$/, q{Match <InCombiningDiacriticalMarks>} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<!InCombiningDiacriticalMarks>.$/, q{Don't match negated <InCombiningDiacriticalMarks>} );
ok( "\N{COMBINING GRAVE ACCENT}" !~ m/^<-InCombiningDiacriticalMarks>$/, q{Don't match inverted <InCombiningDiacriticalMarks>} );
ok( "\x{76DA}"  !~ m/^<InCombiningDiacriticalMarks>$/, q{Don't match unrelated <InCombiningDiacriticalMarks>} );
ok( "\x{76DA}"  =~ m/^<!InCombiningDiacriticalMarks>.$/, q{Match unrelated negated <InCombiningDiacriticalMarks>} );
ok( "\x{76DA}"  =~ m/^<-InCombiningDiacriticalMarks>$/, q{Match unrelated inverted <InCombiningDiacriticalMarks>} );
ok( "\x{76DA}\N{COMBINING GRAVE ACCENT}" =~ m/<InCombiningDiacriticalMarks>/, q{Match unanchored <InCombiningDiacriticalMarks>} );

# InCombiningDiacriticalMarksforSymbols


ok( "\N{COMBINING LEFT HARPOON ABOVE}" =~ m/^<InCombiningDiacriticalMarksforSymbols>$/, q{Match <InCombiningDiacriticalMarksforSymbols>} );
ok( "\N{COMBINING LEFT HARPOON ABOVE}" !~ m/^<!InCombiningDiacriticalMarksforSymbols>.$/, q{Don't match negated <InCombiningDiacriticalMarksforSymbols>} );
ok( "\N{COMBINING LEFT HARPOON ABOVE}" !~ m/^<-InCombiningDiacriticalMarksforSymbols>$/, q{Don't match inverted <InCombiningDiacriticalMarksforSymbols>} );
ok( "\x{7345}"  !~ m/^<InCombiningDiacriticalMarksforSymbols>$/, q{Don't match unrelated <InCombiningDiacriticalMarksforSymbols>} );
ok( "\x{7345}"  =~ m/^<!InCombiningDiacriticalMarksforSymbols>.$/, q{Match unrelated negated <InCombiningDiacriticalMarksforSymbols>} );
ok( "\x{7345}"  =~ m/^<-InCombiningDiacriticalMarksforSymbols>$/, q{Match unrelated inverted <InCombiningDiacriticalMarksforSymbols>} );
ok( "\x{7345}\N{COMBINING LEFT HARPOON ABOVE}" =~ m/<InCombiningDiacriticalMarksforSymbols>/, q{Match unanchored <InCombiningDiacriticalMarksforSymbols>} );

# InCombiningHalfMarks


ok( "\x{6C2E}"  !~ m/^<InCombiningHalfMarks>$/, q{Don't match unrelated <InCombiningHalfMarks>} );
ok( "\x{6C2E}"  =~ m/^<!InCombiningHalfMarks>.$/, q{Match unrelated negated <InCombiningHalfMarks>} );
ok( "\x{6C2E}"  =~ m/^<-InCombiningHalfMarks>$/, q{Match unrelated inverted <InCombiningHalfMarks>} );

# InControlPictures


ok( "\N{SYMBOL FOR NULL}" =~ m/^<InControlPictures>$/, q{Match <InControlPictures>} );
ok( "\N{SYMBOL FOR NULL}" !~ m/^<!InControlPictures>.$/, q{Don't match negated <InControlPictures>} );
ok( "\N{SYMBOL FOR NULL}" !~ m/^<-InControlPictures>$/, q{Don't match inverted <InControlPictures>} );
ok( "\x{BCE2}"  !~ m/^<InControlPictures>$/, q{Don't match unrelated <InControlPictures>} );
ok( "\x{BCE2}"  =~ m/^<!InControlPictures>.$/, q{Match unrelated negated <InControlPictures>} );
ok( "\x{BCE2}"  =~ m/^<-InControlPictures>$/, q{Match unrelated inverted <InControlPictures>} );
ok( "\x{BCE2}\N{SYMBOL FOR NULL}" =~ m/<InControlPictures>/, q{Match unanchored <InControlPictures>} );

# InCurrencySymbols


ok( "\N{EURO-CURRENCY SIGN}" =~ m/^<InCurrencySymbols>$/, q{Match <InCurrencySymbols>} );
ok( "\N{EURO-CURRENCY SIGN}" !~ m/^<!InCurrencySymbols>.$/, q{Don't match negated <InCurrencySymbols>} );
ok( "\N{EURO-CURRENCY SIGN}" !~ m/^<-InCurrencySymbols>$/, q{Don't match inverted <InCurrencySymbols>} );
ok( "\x{8596}"  !~ m/^<InCurrencySymbols>$/, q{Don't match unrelated <InCurrencySymbols>} );
ok( "\x{8596}"  =~ m/^<!InCurrencySymbols>.$/, q{Match unrelated negated <InCurrencySymbols>} );
ok( "\x{8596}"  =~ m/^<-InCurrencySymbols>$/, q{Match unrelated inverted <InCurrencySymbols>} );
ok( "\x{8596}\N{EURO-CURRENCY SIGN}" =~ m/<InCurrencySymbols>/, q{Match unanchored <InCurrencySymbols>} );

# InCyrillic


ok( "\N{CYRILLIC CAPITAL LETTER IE WITH GRAVE}" =~ m/^<InCyrillic>$/, q{Match <InCyrillic>} );
ok( "\N{CYRILLIC CAPITAL LETTER IE WITH GRAVE}" !~ m/^<!InCyrillic>.$/, q{Don't match negated <InCyrillic>} );
ok( "\N{CYRILLIC CAPITAL LETTER IE WITH GRAVE}" !~ m/^<-InCyrillic>$/, q{Don't match inverted <InCyrillic>} );
ok( "\x{51B2}"  !~ m/^<InCyrillic>$/, q{Don't match unrelated <InCyrillic>} );
ok( "\x{51B2}"  =~ m/^<!InCyrillic>.$/, q{Match unrelated negated <InCyrillic>} );
ok( "\x{51B2}"  =~ m/^<-InCyrillic>$/, q{Match unrelated inverted <InCyrillic>} );
ok( "\x{51B2}\N{CYRILLIC CAPITAL LETTER IE WITH GRAVE}" =~ m/<InCyrillic>/, q{Match unanchored <InCyrillic>} );

# InCyrillicSupplementary


ok( "\N{CYRILLIC CAPITAL LETTER KOMI DE}" =~ m/^<InCyrillicSupplementary>$/, q{Match <InCyrillicSupplementary>} );
ok( "\N{CYRILLIC CAPITAL LETTER KOMI DE}" !~ m/^<!InCyrillicSupplementary>.$/, q{Don't match negated <InCyrillicSupplementary>} );
ok( "\N{CYRILLIC CAPITAL LETTER KOMI DE}" !~ m/^<-InCyrillicSupplementary>$/, q{Don't match inverted <InCyrillicSupplementary>} );
ok( "\x{7BD9}"  !~ m/^<InCyrillicSupplementary>$/, q{Don't match unrelated <InCyrillicSupplementary>} );
ok( "\x{7BD9}"  =~ m/^<!InCyrillicSupplementary>.$/, q{Match unrelated negated <InCyrillicSupplementary>} );
ok( "\x{7BD9}"  =~ m/^<-InCyrillicSupplementary>$/, q{Match unrelated inverted <InCyrillicSupplementary>} );
ok( "\x{7BD9}\N{CYRILLIC CAPITAL LETTER KOMI DE}" =~ m/<InCyrillicSupplementary>/, q{Match unanchored <InCyrillicSupplementary>} );

# InDeseret


ok( "\N{TAMIL DIGIT FOUR}"  !~ m/^<InDeseret>$/, q{Don't match unrelated <InDeseret>} );
ok( "\N{TAMIL DIGIT FOUR}"  =~ m/^<!InDeseret>.$/, q{Match unrelated negated <InDeseret>} );
ok( "\N{TAMIL DIGIT FOUR}"  =~ m/^<-InDeseret>$/, q{Match unrelated inverted <InDeseret>} );

# InDevanagari


ok( "\x{0900}" =~ m/^<InDevanagari>$/, q{Match <InDevanagari>} );
ok( "\x{0900}" !~ m/^<!InDevanagari>.$/, q{Don't match negated <InDevanagari>} );
ok( "\x{0900}" !~ m/^<-InDevanagari>$/, q{Don't match inverted <InDevanagari>} );
ok( "\x{BB12}"  !~ m/^<InDevanagari>$/, q{Don't match unrelated <InDevanagari>} );
ok( "\x{BB12}"  =~ m/^<!InDevanagari>.$/, q{Match unrelated negated <InDevanagari>} );
ok( "\x{BB12}"  =~ m/^<-InDevanagari>$/, q{Match unrelated inverted <InDevanagari>} );
ok( "\x{BB12}\x{0900}" =~ m/<InDevanagari>/, q{Match unanchored <InDevanagari>} );

# InDingbats


ok( "\x{2700}" =~ m/^<InDingbats>$/, q{Match <InDingbats>} );
ok( "\x{2700}" !~ m/^<!InDingbats>.$/, q{Don't match negated <InDingbats>} );
ok( "\x{2700}" !~ m/^<-InDingbats>$/, q{Don't match inverted <InDingbats>} );
ok( "\x{D7A8}"  !~ m/^<InDingbats>$/, q{Don't match unrelated <InDingbats>} );
ok( "\x{D7A8}"  =~ m/^<!InDingbats>.$/, q{Match unrelated negated <InDingbats>} );
ok( "\x{D7A8}"  =~ m/^<-InDingbats>$/, q{Match unrelated inverted <InDingbats>} );
ok( "\x{D7A8}\x{2700}" =~ m/<InDingbats>/, q{Match unanchored <InDingbats>} );

# InEnclosedAlphanumerics


ok( "\N{CIRCLED DIGIT ONE}" =~ m/^<InEnclosedAlphanumerics>$/, q{Match <InEnclosedAlphanumerics>} );
ok( "\N{CIRCLED DIGIT ONE}" !~ m/^<!InEnclosedAlphanumerics>.$/, q{Don't match negated <InEnclosedAlphanumerics>} );
ok( "\N{CIRCLED DIGIT ONE}" !~ m/^<-InEnclosedAlphanumerics>$/, q{Don't match inverted <InEnclosedAlphanumerics>} );
ok( "\x{C3A2}"  !~ m/^<InEnclosedAlphanumerics>$/, q{Don't match unrelated <InEnclosedAlphanumerics>} );
ok( "\x{C3A2}"  =~ m/^<!InEnclosedAlphanumerics>.$/, q{Match unrelated negated <InEnclosedAlphanumerics>} );
ok( "\x{C3A2}"  =~ m/^<-InEnclosedAlphanumerics>$/, q{Match unrelated inverted <InEnclosedAlphanumerics>} );
ok( "\x{C3A2}\N{CIRCLED DIGIT ONE}" =~ m/<InEnclosedAlphanumerics>/, q{Match unanchored <InEnclosedAlphanumerics>} );

# InEnclosedCJKLettersAndMonths


ok( "\N{PARENTHESIZED HANGUL KIYEOK}" =~ m/^<InEnclosedCJKLettersAndMonths>$/, q{Match <InEnclosedCJKLettersAndMonths>} );
ok( "\N{PARENTHESIZED HANGUL KIYEOK}" !~ m/^<!InEnclosedCJKLettersAndMonths>.$/, q{Don't match negated <InEnclosedCJKLettersAndMonths>} );
ok( "\N{PARENTHESIZED HANGUL KIYEOK}" !~ m/^<-InEnclosedCJKLettersAndMonths>$/, q{Don't match inverted <InEnclosedCJKLettersAndMonths>} );
ok( "\x{5B44}"  !~ m/^<InEnclosedCJKLettersAndMonths>$/, q{Don't match unrelated <InEnclosedCJKLettersAndMonths>} );
ok( "\x{5B44}"  =~ m/^<!InEnclosedCJKLettersAndMonths>.$/, q{Match unrelated negated <InEnclosedCJKLettersAndMonths>} );
ok( "\x{5B44}"  =~ m/^<-InEnclosedCJKLettersAndMonths>$/, q{Match unrelated inverted <InEnclosedCJKLettersAndMonths>} );
ok( "\x{5B44}\N{PARENTHESIZED HANGUL KIYEOK}" =~ m/<InEnclosedCJKLettersAndMonths>/, q{Match unanchored <InEnclosedCJKLettersAndMonths>} );

# InEthiopic


ok( "\N{ETHIOPIC SYLLABLE HA}" =~ m/^<InEthiopic>$/, q{Match <InEthiopic>} );
ok( "\N{ETHIOPIC SYLLABLE HA}" !~ m/^<!InEthiopic>.$/, q{Don't match negated <InEthiopic>} );
ok( "\N{ETHIOPIC SYLLABLE HA}" !~ m/^<-InEthiopic>$/, q{Don't match inverted <InEthiopic>} );
ok( "\x{BBAE}"  !~ m/^<InEthiopic>$/, q{Don't match unrelated <InEthiopic>} );
ok( "\x{BBAE}"  =~ m/^<!InEthiopic>.$/, q{Match unrelated negated <InEthiopic>} );
ok( "\x{BBAE}"  =~ m/^<-InEthiopic>$/, q{Match unrelated inverted <InEthiopic>} );
ok( "\x{BBAE}\N{ETHIOPIC SYLLABLE HA}" =~ m/<InEthiopic>/, q{Match unanchored <InEthiopic>} );

# InGeneralPunctuation


ok( "\N{EN QUAD}" =~ m/^<InGeneralPunctuation>$/, q{Match <InGeneralPunctuation>} );
ok( "\N{EN QUAD}" !~ m/^<!InGeneralPunctuation>.$/, q{Don't match negated <InGeneralPunctuation>} );
ok( "\N{EN QUAD}" !~ m/^<-InGeneralPunctuation>$/, q{Don't match inverted <InGeneralPunctuation>} );
ok( "\N{MEDIUM RIGHT PARENTHESIS ORNAMENT}"  !~ m/^<InGeneralPunctuation>$/, q{Don't match unrelated <InGeneralPunctuation>} );
ok( "\N{MEDIUM RIGHT PARENTHESIS ORNAMENT}"  =~ m/^<!InGeneralPunctuation>.$/, q{Match unrelated negated <InGeneralPunctuation>} );
ok( "\N{MEDIUM RIGHT PARENTHESIS ORNAMENT}"  =~ m/^<-InGeneralPunctuation>$/, q{Match unrelated inverted <InGeneralPunctuation>} );
ok( "\N{MEDIUM RIGHT PARENTHESIS ORNAMENT}\N{EN QUAD}" =~ m/<InGeneralPunctuation>/, q{Match unanchored <InGeneralPunctuation>} );

# InGeometricShapes


ok( "\N{BLACK SQUARE}" =~ m/^<InGeometricShapes>$/, q{Match <InGeometricShapes>} );
ok( "\N{BLACK SQUARE}" !~ m/^<!InGeometricShapes>.$/, q{Don't match negated <InGeometricShapes>} );
ok( "\N{BLACK SQUARE}" !~ m/^<-InGeometricShapes>$/, q{Don't match inverted <InGeometricShapes>} );
ok( "\x{B700}"  !~ m/^<InGeometricShapes>$/, q{Don't match unrelated <InGeometricShapes>} );
ok( "\x{B700}"  =~ m/^<!InGeometricShapes>.$/, q{Match unrelated negated <InGeometricShapes>} );
ok( "\x{B700}"  =~ m/^<-InGeometricShapes>$/, q{Match unrelated inverted <InGeometricShapes>} );
ok( "\x{B700}\N{BLACK SQUARE}" =~ m/<InGeometricShapes>/, q{Match unanchored <InGeometricShapes>} );

# InGeorgian


ok( "\N{GEORGIAN CAPITAL LETTER AN}" =~ m/^<InGeorgian>$/, q{Match <InGeorgian>} );
ok( "\N{GEORGIAN CAPITAL LETTER AN}" !~ m/^<!InGeorgian>.$/, q{Don't match negated <InGeorgian>} );
ok( "\N{GEORGIAN CAPITAL LETTER AN}" !~ m/^<-InGeorgian>$/, q{Don't match inverted <InGeorgian>} );
ok( "\N{IDEOGRAPHIC TELEGRAPH SYMBOL FOR HOUR ONE}"  !~ m/^<InGeorgian>$/, q{Don't match unrelated <InGeorgian>} );
ok( "\N{IDEOGRAPHIC TELEGRAPH SYMBOL FOR HOUR ONE}"  =~ m/^<!InGeorgian>.$/, q{Match unrelated negated <InGeorgian>} );
ok( "\N{IDEOGRAPHIC TELEGRAPH SYMBOL FOR HOUR ONE}"  =~ m/^<-InGeorgian>$/, q{Match unrelated inverted <InGeorgian>} );
ok( "\N{IDEOGRAPHIC TELEGRAPH SYMBOL FOR HOUR ONE}\N{GEORGIAN CAPITAL LETTER AN}" =~ m/<InGeorgian>/, q{Match unanchored <InGeorgian>} );

# InGothic


ok( "\x{4825}"  !~ m/^<InGothic>$/, q{Don't match unrelated <InGothic>} );
ok( "\x{4825}"  =~ m/^<!InGothic>.$/, q{Match unrelated negated <InGothic>} );
ok( "\x{4825}"  =~ m/^<-InGothic>$/, q{Match unrelated inverted <InGothic>} );

# InGreekExtended


ok( "\N{GREEK SMALL LETTER ALPHA WITH PSILI}" =~ m/^<InGreekExtended>$/, q{Match <InGreekExtended>} );
ok( "\N{GREEK SMALL LETTER ALPHA WITH PSILI}" !~ m/^<!InGreekExtended>.$/, q{Don't match negated <InGreekExtended>} );
ok( "\N{GREEK SMALL LETTER ALPHA WITH PSILI}" !~ m/^<-InGreekExtended>$/, q{Don't match inverted <InGreekExtended>} );
ok( "\x{B9B7}"  !~ m/^<InGreekExtended>$/, q{Don't match unrelated <InGreekExtended>} );
ok( "\x{B9B7}"  =~ m/^<!InGreekExtended>.$/, q{Match unrelated negated <InGreekExtended>} );
ok( "\x{B9B7}"  =~ m/^<-InGreekExtended>$/, q{Match unrelated inverted <InGreekExtended>} );
ok( "\x{B9B7}\N{GREEK SMALL LETTER ALPHA WITH PSILI}" =~ m/<InGreekExtended>/, q{Match unanchored <InGreekExtended>} );

# InGreekAndCoptic


ok( "\x{0370}" =~ m/^<InGreekAndCoptic>$/, q{Match <InGreekAndCoptic>} );
ok( "\x{0370}" !~ m/^<!InGreekAndCoptic>.$/, q{Don't match negated <InGreekAndCoptic>} );
ok( "\x{0370}" !~ m/^<-InGreekAndCoptic>$/, q{Don't match inverted <InGreekAndCoptic>} );
ok( "\x{7197}"  !~ m/^<InGreekAndCoptic>$/, q{Don't match unrelated <InGreekAndCoptic>} );
ok( "\x{7197}"  =~ m/^<!InGreekAndCoptic>.$/, q{Match unrelated negated <InGreekAndCoptic>} );
ok( "\x{7197}"  =~ m/^<-InGreekAndCoptic>$/, q{Match unrelated inverted <InGreekAndCoptic>} );
ok( "\x{7197}\x{0370}" =~ m/<InGreekAndCoptic>/, q{Match unanchored <InGreekAndCoptic>} );

# InGujarati


ok( "\x{0A80}" =~ m/^<InGujarati>$/, q{Match <InGujarati>} );
ok( "\x{0A80}" !~ m/^<!InGujarati>.$/, q{Don't match negated <InGujarati>} );
ok( "\x{0A80}" !~ m/^<-InGujarati>$/, q{Don't match inverted <InGujarati>} );
ok( "\x{3B63}"  !~ m/^<InGujarati>$/, q{Don't match unrelated <InGujarati>} );
ok( "\x{3B63}"  =~ m/^<!InGujarati>.$/, q{Match unrelated negated <InGujarati>} );
ok( "\x{3B63}"  =~ m/^<-InGujarati>$/, q{Match unrelated inverted <InGujarati>} );
ok( "\x{3B63}\x{0A80}" =~ m/<InGujarati>/, q{Match unanchored <InGujarati>} );

# InGurmukhi


ok( "\x{0A00}" =~ m/^<InGurmukhi>$/, q{Match <InGurmukhi>} );
ok( "\x{0A00}" !~ m/^<!InGurmukhi>.$/, q{Don't match negated <InGurmukhi>} );
ok( "\x{0A00}" !~ m/^<-InGurmukhi>$/, q{Don't match inverted <InGurmukhi>} );
ok( "\x{10C8}"  !~ m/^<InGurmukhi>$/, q{Don't match unrelated <InGurmukhi>} );
ok( "\x{10C8}"  =~ m/^<!InGurmukhi>.$/, q{Match unrelated negated <InGurmukhi>} );
ok( "\x{10C8}"  =~ m/^<-InGurmukhi>$/, q{Match unrelated inverted <InGurmukhi>} );
ok( "\x{10C8}\x{0A00}" =~ m/<InGurmukhi>/, q{Match unanchored <InGurmukhi>} );

# InHalfwidthAndFullwidthForms


ok( "\x{CA55}"  !~ m/^<InHalfwidthAndFullwidthForms>$/, q{Don't match unrelated <InHalfwidthAndFullwidthForms>} );
ok( "\x{CA55}"  =~ m/^<!InHalfwidthAndFullwidthForms>.$/, q{Match unrelated negated <InHalfwidthAndFullwidthForms>} );
ok( "\x{CA55}"  =~ m/^<-InHalfwidthAndFullwidthForms>$/, q{Match unrelated inverted <InHalfwidthAndFullwidthForms>} );

# InHangulCompatibilityJamo


ok( "\x{3130}" =~ m/^<InHangulCompatibilityJamo>$/, q{Match <InHangulCompatibilityJamo>} );
ok( "\x{3130}" !~ m/^<!InHangulCompatibilityJamo>.$/, q{Don't match negated <InHangulCompatibilityJamo>} );
ok( "\x{3130}" !~ m/^<-InHangulCompatibilityJamo>$/, q{Don't match inverted <InHangulCompatibilityJamo>} );
ok( "\N{MEASURED BY}"  !~ m/^<InHangulCompatibilityJamo>$/, q{Don't match unrelated <InHangulCompatibilityJamo>} );
ok( "\N{MEASURED BY}"  =~ m/^<!InHangulCompatibilityJamo>.$/, q{Match unrelated negated <InHangulCompatibilityJamo>} );
ok( "\N{MEASURED BY}"  =~ m/^<-InHangulCompatibilityJamo>$/, q{Match unrelated inverted <InHangulCompatibilityJamo>} );
ok( "\N{MEASURED BY}\x{3130}" =~ m/<InHangulCompatibilityJamo>/, q{Match unanchored <InHangulCompatibilityJamo>} );

# InHangulJamo


ok( "\N{HANGUL CHOSEONG KIYEOK}" =~ m/^<InHangulJamo>$/, q{Match <InHangulJamo>} );
ok( "\N{HANGUL CHOSEONG KIYEOK}" !~ m/^<!InHangulJamo>.$/, q{Don't match negated <InHangulJamo>} );
ok( "\N{HANGUL CHOSEONG KIYEOK}" !~ m/^<-InHangulJamo>$/, q{Don't match inverted <InHangulJamo>} );
ok( "\x{3B72}"  !~ m/^<InHangulJamo>$/, q{Don't match unrelated <InHangulJamo>} );
ok( "\x{3B72}"  =~ m/^<!InHangulJamo>.$/, q{Match unrelated negated <InHangulJamo>} );
ok( "\x{3B72}"  =~ m/^<-InHangulJamo>$/, q{Match unrelated inverted <InHangulJamo>} );
ok( "\x{3B72}\N{HANGUL CHOSEONG KIYEOK}" =~ m/<InHangulJamo>/, q{Match unanchored <InHangulJamo>} );

# InHangulSyllables


ok( "\x{CD95}" =~ m/^<InHangulSyllables>$/, q{Match <InHangulSyllables>} );
ok( "\x{CD95}" !~ m/^<!InHangulSyllables>.$/, q{Don't match negated <InHangulSyllables>} );
ok( "\x{CD95}" !~ m/^<-InHangulSyllables>$/, q{Don't match inverted <InHangulSyllables>} );
ok( "\x{D7B0}"  !~ m/^<InHangulSyllables>$/, q{Don't match unrelated <InHangulSyllables>} );
ok( "\x{D7B0}"  =~ m/^<!InHangulSyllables>.$/, q{Match unrelated negated <InHangulSyllables>} );
ok( "\x{D7B0}"  =~ m/^<-InHangulSyllables>$/, q{Match unrelated inverted <InHangulSyllables>} );
ok( "\x{D7B0}\x{CD95}" =~ m/<InHangulSyllables>/, q{Match unanchored <InHangulSyllables>} );

# InHanunoo


ok( "\N{HANUNOO LETTER A}" =~ m/^<InHanunoo>$/, q{Match <InHanunoo>} );
ok( "\N{HANUNOO LETTER A}" !~ m/^<!InHanunoo>.$/, q{Don't match negated <InHanunoo>} );
ok( "\N{HANUNOO LETTER A}" !~ m/^<-InHanunoo>$/, q{Don't match inverted <InHanunoo>} );
ok( "\x{6F4F}"  !~ m/^<InHanunoo>$/, q{Don't match unrelated <InHanunoo>} );
ok( "\x{6F4F}"  =~ m/^<!InHanunoo>.$/, q{Match unrelated negated <InHanunoo>} );
ok( "\x{6F4F}"  =~ m/^<-InHanunoo>$/, q{Match unrelated inverted <InHanunoo>} );
ok( "\x{6F4F}\N{HANUNOO LETTER A}" =~ m/<InHanunoo>/, q{Match unanchored <InHanunoo>} );

# InHebrew


ok( "\x{0590}" =~ m/^<InHebrew>$/, q{Match <InHebrew>} );
ok( "\x{0590}" !~ m/^<!InHebrew>.$/, q{Don't match negated <InHebrew>} );
ok( "\x{0590}" !~ m/^<-InHebrew>$/, q{Don't match inverted <InHebrew>} );
ok( "\x{0777}"  !~ m/^<InHebrew>$/, q{Don't match unrelated <InHebrew>} );
ok( "\x{0777}"  =~ m/^<!InHebrew>.$/, q{Match unrelated negated <InHebrew>} );
ok( "\x{0777}"  =~ m/^<-InHebrew>$/, q{Match unrelated inverted <InHebrew>} );
ok( "\x{0777}\x{0590}" =~ m/<InHebrew>/, q{Match unanchored <InHebrew>} );

# InHighPrivateUseSurrogates


ok( "\x{D04F}"  !~ m/^<InHighPrivateUseSurrogates>$/, q{Don't match unrelated <InHighPrivateUseSurrogates>} );
ok( "\x{D04F}"  =~ m/^<!InHighPrivateUseSurrogates>.$/, q{Match unrelated negated <InHighPrivateUseSurrogates>} );
ok( "\x{D04F}"  =~ m/^<-InHighPrivateUseSurrogates>$/, q{Match unrelated inverted <InHighPrivateUseSurrogates>} );

# InHighSurrogates


ok( "\x{D085}"  !~ m/^<InHighSurrogates>$/, q{Don't match unrelated <InHighSurrogates>} );
ok( "\x{D085}"  =~ m/^<!InHighSurrogates>.$/, q{Match unrelated negated <InHighSurrogates>} );
ok( "\x{D085}"  =~ m/^<-InHighSurrogates>$/, q{Match unrelated inverted <InHighSurrogates>} );

# InHiragana


ok( "\x{3040}" =~ m/^<InHiragana>$/, q{Match <InHiragana>} );
ok( "\x{3040}" !~ m/^<!InHiragana>.$/, q{Don't match negated <InHiragana>} );
ok( "\x{3040}" !~ m/^<-InHiragana>$/, q{Don't match inverted <InHiragana>} );
ok( "\x{AC7C}"  !~ m/^<InHiragana>$/, q{Don't match unrelated <InHiragana>} );
ok( "\x{AC7C}"  =~ m/^<!InHiragana>.$/, q{Match unrelated negated <InHiragana>} );
ok( "\x{AC7C}"  =~ m/^<-InHiragana>$/, q{Match unrelated inverted <InHiragana>} );
ok( "\x{AC7C}\x{3040}" =~ m/<InHiragana>/, q{Match unanchored <InHiragana>} );

# InIPAExtensions


ok( "\N{LATIN SMALL LETTER TURNED A}" =~ m/^<InIPAExtensions>$/, q{Match <InIPAExtensions>} );
ok( "\N{LATIN SMALL LETTER TURNED A}" !~ m/^<!InIPAExtensions>.$/, q{Don't match negated <InIPAExtensions>} );
ok( "\N{LATIN SMALL LETTER TURNED A}" !~ m/^<-InIPAExtensions>$/, q{Don't match inverted <InIPAExtensions>} );
ok( "\N{HANGUL LETTER SSANGIEUNG}"  !~ m/^<InIPAExtensions>$/, q{Don't match unrelated <InIPAExtensions>} );
ok( "\N{HANGUL LETTER SSANGIEUNG}"  =~ m/^<!InIPAExtensions>.$/, q{Match unrelated negated <InIPAExtensions>} );
ok( "\N{HANGUL LETTER SSANGIEUNG}"  =~ m/^<-InIPAExtensions>$/, q{Match unrelated inverted <InIPAExtensions>} );
ok( "\N{HANGUL LETTER SSANGIEUNG}\N{LATIN SMALL LETTER TURNED A}" =~ m/<InIPAExtensions>/, q{Match unanchored <InIPAExtensions>} );

# InIdeographicDescriptionCharacters


ok( "\N{IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO RIGHT}" =~ m/^<InIdeographicDescriptionCharacters>$/, q{Match <InIdeographicDescriptionCharacters>} );
ok( "\N{IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO RIGHT}" !~ m/^<!InIdeographicDescriptionCharacters>.$/, q{Don't match negated <InIdeographicDescriptionCharacters>} );
ok( "\N{IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO RIGHT}" !~ m/^<-InIdeographicDescriptionCharacters>$/, q{Don't match inverted <InIdeographicDescriptionCharacters>} );
ok( "\x{9160}"  !~ m/^<InIdeographicDescriptionCharacters>$/, q{Don't match unrelated <InIdeographicDescriptionCharacters>} );
ok( "\x{9160}"  =~ m/^<!InIdeographicDescriptionCharacters>.$/, q{Match unrelated negated <InIdeographicDescriptionCharacters>} );
ok( "\x{9160}"  =~ m/^<-InIdeographicDescriptionCharacters>$/, q{Match unrelated inverted <InIdeographicDescriptionCharacters>} );
ok( "\x{9160}\N{IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO RIGHT}" =~ m/<InIdeographicDescriptionCharacters>/, q{Match unanchored <InIdeographicDescriptionCharacters>} );

# InKanbun


ok( "\N{IDEOGRAPHIC ANNOTATION LINKING MARK}" =~ m/^<InKanbun>$/, q{Match <InKanbun>} );
ok( "\N{IDEOGRAPHIC ANNOTATION LINKING MARK}" !~ m/^<!InKanbun>.$/, q{Don't match negated <InKanbun>} );
ok( "\N{IDEOGRAPHIC ANNOTATION LINKING MARK}" !~ m/^<-InKanbun>$/, q{Don't match inverted <InKanbun>} );
ok( "\x{A80C}"  !~ m/^<InKanbun>$/, q{Don't match unrelated <InKanbun>} );
ok( "\x{A80C}"  =~ m/^<!InKanbun>.$/, q{Match unrelated negated <InKanbun>} );
ok( "\x{A80C}"  =~ m/^<-InKanbun>$/, q{Match unrelated inverted <InKanbun>} );
ok( "\x{A80C}\N{IDEOGRAPHIC ANNOTATION LINKING MARK}" =~ m/<InKanbun>/, q{Match unanchored <InKanbun>} );

# InKangxiRadicals


ok( "\N{KANGXI RADICAL ONE}" =~ m/^<InKangxiRadicals>$/, q{Match <InKangxiRadicals>} );
ok( "\N{KANGXI RADICAL ONE}" !~ m/^<!InKangxiRadicals>.$/, q{Don't match negated <InKangxiRadicals>} );
ok( "\N{KANGXI RADICAL ONE}" !~ m/^<-InKangxiRadicals>$/, q{Don't match inverted <InKangxiRadicals>} );
ok( "\x{891A}"  !~ m/^<InKangxiRadicals>$/, q{Don't match unrelated <InKangxiRadicals>} );
ok( "\x{891A}"  =~ m/^<!InKangxiRadicals>.$/, q{Match unrelated negated <InKangxiRadicals>} );
ok( "\x{891A}"  =~ m/^<-InKangxiRadicals>$/, q{Match unrelated inverted <InKangxiRadicals>} );
ok( "\x{891A}\N{KANGXI RADICAL ONE}" =~ m/<InKangxiRadicals>/, q{Match unanchored <InKangxiRadicals>} );

# InKannada


ok( "\x{0C80}" =~ m/^<InKannada>$/, q{Match <InKannada>} );
ok( "\x{0C80}" !~ m/^<!InKannada>.$/, q{Don't match negated <InKannada>} );
ok( "\x{0C80}" !~ m/^<-InKannada>$/, q{Don't match inverted <InKannada>} );
ok( "\x{B614}"  !~ m/^<InKannada>$/, q{Don't match unrelated <InKannada>} );
ok( "\x{B614}"  =~ m/^<!InKannada>.$/, q{Match unrelated negated <InKannada>} );
ok( "\x{B614}"  =~ m/^<-InKannada>$/, q{Match unrelated inverted <InKannada>} );
ok( "\x{B614}\x{0C80}" =~ m/<InKannada>/, q{Match unanchored <InKannada>} );

# InKatakana


ok( "\N{KATAKANA-HIRAGANA DOUBLE HYPHEN}" =~ m/^<InKatakana>$/, q{Match <InKatakana>} );
ok( "\N{KATAKANA-HIRAGANA DOUBLE HYPHEN}" !~ m/^<!InKatakana>.$/, q{Don't match negated <InKatakana>} );
ok( "\N{KATAKANA-HIRAGANA DOUBLE HYPHEN}" !~ m/^<-InKatakana>$/, q{Don't match inverted <InKatakana>} );
ok( "\x{7EB8}"  !~ m/^<InKatakana>$/, q{Don't match unrelated <InKatakana>} );
ok( "\x{7EB8}"  =~ m/^<!InKatakana>.$/, q{Match unrelated negated <InKatakana>} );
ok( "\x{7EB8}"  =~ m/^<-InKatakana>$/, q{Match unrelated inverted <InKatakana>} );
ok( "\x{7EB8}\N{KATAKANA-HIRAGANA DOUBLE HYPHEN}" =~ m/<InKatakana>/, q{Match unanchored <InKatakana>} );

# InKatakanaPhoneticExtensions


ok( "\N{KATAKANA LETTER SMALL KU}" =~ m/^<InKatakanaPhoneticExtensions>$/, q{Match <InKatakanaPhoneticExtensions>} );
ok( "\N{KATAKANA LETTER SMALL KU}" !~ m/^<!InKatakanaPhoneticExtensions>.$/, q{Don't match negated <InKatakanaPhoneticExtensions>} );
ok( "\N{KATAKANA LETTER SMALL KU}" !~ m/^<-InKatakanaPhoneticExtensions>$/, q{Don't match inverted <InKatakanaPhoneticExtensions>} );
ok( "\x{97C2}"  !~ m/^<InKatakanaPhoneticExtensions>$/, q{Don't match unrelated <InKatakanaPhoneticExtensions>} );
ok( "\x{97C2}"  =~ m/^<!InKatakanaPhoneticExtensions>.$/, q{Match unrelated negated <InKatakanaPhoneticExtensions>} );
ok( "\x{97C2}"  =~ m/^<-InKatakanaPhoneticExtensions>$/, q{Match unrelated inverted <InKatakanaPhoneticExtensions>} );
ok( "\x{97C2}\N{KATAKANA LETTER SMALL KU}" =~ m/<InKatakanaPhoneticExtensions>/, q{Match unanchored <InKatakanaPhoneticExtensions>} );

# InKhmer


ok( "\N{KHMER LETTER KA}" =~ m/^<InKhmer>$/, q{Match <InKhmer>} );
ok( "\N{KHMER LETTER KA}" !~ m/^<!InKhmer>.$/, q{Don't match negated <InKhmer>} );
ok( "\N{KHMER LETTER KA}" !~ m/^<-InKhmer>$/, q{Don't match inverted <InKhmer>} );
ok( "\x{CAFA}"  !~ m/^<InKhmer>$/, q{Don't match unrelated <InKhmer>} );
ok( "\x{CAFA}"  =~ m/^<!InKhmer>.$/, q{Match unrelated negated <InKhmer>} );
ok( "\x{CAFA}"  =~ m/^<-InKhmer>$/, q{Match unrelated inverted <InKhmer>} );
ok( "\x{CAFA}\N{KHMER LETTER KA}" =~ m/<InKhmer>/, q{Match unanchored <InKhmer>} );

# InLao


ok( "\x{0E80}" =~ m/^<InLao>$/, q{Match <InLao>} );
ok( "\x{0E80}" !~ m/^<!InLao>.$/, q{Don't match negated <InLao>} );
ok( "\x{0E80}" !~ m/^<-InLao>$/, q{Don't match inverted <InLao>} );
ok( "\x{07BF}"  !~ m/^<InLao>$/, q{Don't match unrelated <InLao>} );
ok( "\x{07BF}"  =~ m/^<!InLao>.$/, q{Match unrelated negated <InLao>} );
ok( "\x{07BF}"  =~ m/^<-InLao>$/, q{Match unrelated inverted <InLao>} );
ok( "\x{07BF}\x{0E80}" =~ m/<InLao>/, q{Match unanchored <InLao>} );

# InLatin1Supplement


ok( "\x{0080}" =~ m/^<InLatin1Supplement>$/, q{Match <InLatin1Supplement>} );
ok( "\x{0080}" !~ m/^<!InLatin1Supplement>.$/, q{Don't match negated <InLatin1Supplement>} );
ok( "\x{0080}" !~ m/^<-InLatin1Supplement>$/, q{Don't match inverted <InLatin1Supplement>} );
ok( "\x{D062}"  !~ m/^<InLatin1Supplement>$/, q{Don't match unrelated <InLatin1Supplement>} );
ok( "\x{D062}"  =~ m/^<!InLatin1Supplement>.$/, q{Match unrelated negated <InLatin1Supplement>} );
ok( "\x{D062}"  =~ m/^<-InLatin1Supplement>$/, q{Match unrelated inverted <InLatin1Supplement>} );
ok( "\x{D062}\x{0080}" =~ m/<InLatin1Supplement>/, q{Match unanchored <InLatin1Supplement>} );

# InLatinExtendedA


ok( "\N{LATIN CAPITAL LETTER A WITH MACRON}" =~ m/^<InLatinExtendedA>$/, q{Match <InLatinExtendedA>} );
ok( "\N{LATIN CAPITAL LETTER A WITH MACRON}" !~ m/^<!InLatinExtendedA>.$/, q{Don't match negated <InLatinExtendedA>} );
ok( "\N{LATIN CAPITAL LETTER A WITH MACRON}" !~ m/^<-InLatinExtendedA>$/, q{Don't match inverted <InLatinExtendedA>} );
ok( "\N{IDEOGRAPHIC ANNOTATION EARTH MARK}"  !~ m/^<InLatinExtendedA>$/, q{Don't match unrelated <InLatinExtendedA>} );
ok( "\N{IDEOGRAPHIC ANNOTATION EARTH MARK}"  =~ m/^<!InLatinExtendedA>.$/, q{Match unrelated negated <InLatinExtendedA>} );
ok( "\N{IDEOGRAPHIC ANNOTATION EARTH MARK}"  =~ m/^<-InLatinExtendedA>$/, q{Match unrelated inverted <InLatinExtendedA>} );
ok( "\N{IDEOGRAPHIC ANNOTATION EARTH MARK}\N{LATIN CAPITAL LETTER A WITH MACRON}" =~ m/<InLatinExtendedA>/, q{Match unanchored <InLatinExtendedA>} );

# InLatinExtendedAdditional


ok( "\N{LATIN CAPITAL LETTER A WITH RING BELOW}" =~ m/^<InLatinExtendedAdditional>$/, q{Match <InLatinExtendedAdditional>} );
ok( "\N{LATIN CAPITAL LETTER A WITH RING BELOW}" !~ m/^<!InLatinExtendedAdditional>.$/, q{Don't match negated <InLatinExtendedAdditional>} );
ok( "\N{LATIN CAPITAL LETTER A WITH RING BELOW}" !~ m/^<-InLatinExtendedAdditional>$/, q{Don't match inverted <InLatinExtendedAdditional>} );
ok( "\x{9A44}"  !~ m/^<InLatinExtendedAdditional>$/, q{Don't match unrelated <InLatinExtendedAdditional>} );
ok( "\x{9A44}"  =~ m/^<!InLatinExtendedAdditional>.$/, q{Match unrelated negated <InLatinExtendedAdditional>} );
ok( "\x{9A44}"  =~ m/^<-InLatinExtendedAdditional>$/, q{Match unrelated inverted <InLatinExtendedAdditional>} );
ok( "\x{9A44}\N{LATIN CAPITAL LETTER A WITH RING BELOW}" =~ m/<InLatinExtendedAdditional>/, q{Match unanchored <InLatinExtendedAdditional>} );

# InLatinExtendedB


ok( "\N{LATIN SMALL LETTER B WITH STROKE}" =~ m/^<InLatinExtendedB>$/, q{Match <InLatinExtendedB>} );
ok( "\N{LATIN SMALL LETTER B WITH STROKE}" !~ m/^<!InLatinExtendedB>.$/, q{Don't match negated <InLatinExtendedB>} );
ok( "\N{LATIN SMALL LETTER B WITH STROKE}" !~ m/^<-InLatinExtendedB>$/, q{Don't match inverted <InLatinExtendedB>} );
ok( "\x{7544}"  !~ m/^<InLatinExtendedB>$/, q{Don't match unrelated <InLatinExtendedB>} );
ok( "\x{7544}"  =~ m/^<!InLatinExtendedB>.$/, q{Match unrelated negated <InLatinExtendedB>} );
ok( "\x{7544}"  =~ m/^<-InLatinExtendedB>$/, q{Match unrelated inverted <InLatinExtendedB>} );
ok( "\x{7544}\N{LATIN SMALL LETTER B WITH STROKE}" =~ m/<InLatinExtendedB>/, q{Match unanchored <InLatinExtendedB>} );

# InLetterlikeSymbols


ok( "\N{ACCOUNT OF}" =~ m/^<InLetterlikeSymbols>$/, q{Match <InLetterlikeSymbols>} );
ok( "\N{ACCOUNT OF}" !~ m/^<!InLetterlikeSymbols>.$/, q{Don't match negated <InLetterlikeSymbols>} );
ok( "\N{ACCOUNT OF}" !~ m/^<-InLetterlikeSymbols>$/, q{Don't match inverted <InLetterlikeSymbols>} );
ok( "\N{LATIN CAPITAL LETTER X WITH DOT ABOVE}"  !~ m/^<InLetterlikeSymbols>$/, q{Don't match unrelated <InLetterlikeSymbols>} );
ok( "\N{LATIN CAPITAL LETTER X WITH DOT ABOVE}"  =~ m/^<!InLetterlikeSymbols>.$/, q{Match unrelated negated <InLetterlikeSymbols>} );
ok( "\N{LATIN CAPITAL LETTER X WITH DOT ABOVE}"  =~ m/^<-InLetterlikeSymbols>$/, q{Match unrelated inverted <InLetterlikeSymbols>} );
ok( "\N{LATIN CAPITAL LETTER X WITH DOT ABOVE}\N{ACCOUNT OF}" =~ m/<InLetterlikeSymbols>/, q{Match unanchored <InLetterlikeSymbols>} );

# InLowSurrogates


ok( "\x{5ECC}"  !~ m/^<InLowSurrogates>$/, q{Don't match unrelated <InLowSurrogates>} );
ok( "\x{5ECC}"  =~ m/^<!InLowSurrogates>.$/, q{Match unrelated negated <InLowSurrogates>} );
ok( "\x{5ECC}"  =~ m/^<-InLowSurrogates>$/, q{Match unrelated inverted <InLowSurrogates>} );

# InMalayalam


ok( "\x{0D00}" =~ m/^<InMalayalam>$/, q{Match <InMalayalam>} );
ok( "\x{0D00}" !~ m/^<!InMalayalam>.$/, q{Don't match negated <InMalayalam>} );
ok( "\x{0D00}" !~ m/^<-InMalayalam>$/, q{Don't match inverted <InMalayalam>} );
ok( "\x{3457}"  !~ m/^<InMalayalam>$/, q{Don't match unrelated <InMalayalam>} );
ok( "\x{3457}"  =~ m/^<!InMalayalam>.$/, q{Match unrelated negated <InMalayalam>} );
ok( "\x{3457}"  =~ m/^<-InMalayalam>$/, q{Match unrelated inverted <InMalayalam>} );
ok( "\x{3457}\x{0D00}" =~ m/<InMalayalam>/, q{Match unanchored <InMalayalam>} );

# InMathematicalAlphanumericSymbols


ok( "\x{6B79}"  !~ m/^<InMathematicalAlphanumericSymbols>$/, q{Don't match unrelated <InMathematicalAlphanumericSymbols>} );
ok( "\x{6B79}"  =~ m/^<!InMathematicalAlphanumericSymbols>.$/, q{Match unrelated negated <InMathematicalAlphanumericSymbols>} );
ok( "\x{6B79}"  =~ m/^<-InMathematicalAlphanumericSymbols>$/, q{Match unrelated inverted <InMathematicalAlphanumericSymbols>} );

# InMathematicalOperators


ok( "\N{FOR ALL}" =~ m/^<InMathematicalOperators>$/, q{Match <InMathematicalOperators>} );
ok( "\N{FOR ALL}" !~ m/^<!InMathematicalOperators>.$/, q{Don't match negated <InMathematicalOperators>} );
ok( "\N{FOR ALL}" !~ m/^<-InMathematicalOperators>$/, q{Don't match inverted <InMathematicalOperators>} );
ok( "\x{BBC6}"  !~ m/^<InMathematicalOperators>$/, q{Don't match unrelated <InMathematicalOperators>} );
ok( "\x{BBC6}"  =~ m/^<!InMathematicalOperators>.$/, q{Match unrelated negated <InMathematicalOperators>} );
ok( "\x{BBC6}"  =~ m/^<-InMathematicalOperators>$/, q{Match unrelated inverted <InMathematicalOperators>} );
ok( "\x{BBC6}\N{FOR ALL}" =~ m/<InMathematicalOperators>/, q{Match unanchored <InMathematicalOperators>} );

# InMiscellaneousMathematicalSymbolsA


ok( "\x{27C0}" =~ m/^<InMiscellaneousMathematicalSymbolsA>$/, q{Match <InMiscellaneousMathematicalSymbolsA>} );
ok( "\x{27C0}" !~ m/^<!InMiscellaneousMathematicalSymbolsA>.$/, q{Don't match negated <InMiscellaneousMathematicalSymbolsA>} );
ok( "\x{27C0}" !~ m/^<-InMiscellaneousMathematicalSymbolsA>$/, q{Don't match inverted <InMiscellaneousMathematicalSymbolsA>} );
ok( "\x{065D}"  !~ m/^<InMiscellaneousMathematicalSymbolsA>$/, q{Don't match unrelated <InMiscellaneousMathematicalSymbolsA>} );
ok( "\x{065D}"  =~ m/^<!InMiscellaneousMathematicalSymbolsA>.$/, q{Match unrelated negated <InMiscellaneousMathematicalSymbolsA>} );
ok( "\x{065D}"  =~ m/^<-InMiscellaneousMathematicalSymbolsA>$/, q{Match unrelated inverted <InMiscellaneousMathematicalSymbolsA>} );
ok( "\x{065D}\x{27C0}" =~ m/<InMiscellaneousMathematicalSymbolsA>/, q{Match unanchored <InMiscellaneousMathematicalSymbolsA>} );

# InMiscellaneousMathematicalSymbolsB


ok( "\N{TRIPLE VERTICAL BAR DELIMITER}" =~ m/^<InMiscellaneousMathematicalSymbolsB>$/, q{Match <InMiscellaneousMathematicalSymbolsB>} );
ok( "\N{TRIPLE VERTICAL BAR DELIMITER}" !~ m/^<!InMiscellaneousMathematicalSymbolsB>.$/, q{Don't match negated <InMiscellaneousMathematicalSymbolsB>} );
ok( "\N{TRIPLE VERTICAL BAR DELIMITER}" !~ m/^<-InMiscellaneousMathematicalSymbolsB>$/, q{Don't match inverted <InMiscellaneousMathematicalSymbolsB>} );
ok( "\x{56A6}"  !~ m/^<InMiscellaneousMathematicalSymbolsB>$/, q{Don't match unrelated <InMiscellaneousMathematicalSymbolsB>} );
ok( "\x{56A6}"  =~ m/^<!InMiscellaneousMathematicalSymbolsB>.$/, q{Match unrelated negated <InMiscellaneousMathematicalSymbolsB>} );
ok( "\x{56A6}"  =~ m/^<-InMiscellaneousMathematicalSymbolsB>$/, q{Match unrelated inverted <InMiscellaneousMathematicalSymbolsB>} );
ok( "\x{56A6}\N{TRIPLE VERTICAL BAR DELIMITER}" =~ m/<InMiscellaneousMathematicalSymbolsB>/, q{Match unanchored <InMiscellaneousMathematicalSymbolsB>} );

# InMiscellaneousSymbols


ok( "\N{BLACK SUN WITH RAYS}" =~ m/^<InMiscellaneousSymbols>$/, q{Match <InMiscellaneousSymbols>} );
ok( "\N{BLACK SUN WITH RAYS}" !~ m/^<!InMiscellaneousSymbols>.$/, q{Don't match negated <InMiscellaneousSymbols>} );
ok( "\N{BLACK SUN WITH RAYS}" !~ m/^<-InMiscellaneousSymbols>$/, q{Don't match inverted <InMiscellaneousSymbols>} );
ok( "\x{3EE7}"  !~ m/^<InMiscellaneousSymbols>$/, q{Don't match unrelated <InMiscellaneousSymbols>} );
ok( "\x{3EE7}"  =~ m/^<!InMiscellaneousSymbols>.$/, q{Match unrelated negated <InMiscellaneousSymbols>} );
ok( "\x{3EE7}"  =~ m/^<-InMiscellaneousSymbols>$/, q{Match unrelated inverted <InMiscellaneousSymbols>} );
ok( "\x{3EE7}\N{BLACK SUN WITH RAYS}" =~ m/<InMiscellaneousSymbols>/, q{Match unanchored <InMiscellaneousSymbols>} );

# InMiscellaneousTechnical


ok( "\N{DIAMETER SIGN}" =~ m/^<InMiscellaneousTechnical>$/, q{Match <InMiscellaneousTechnical>} );
ok( "\N{DIAMETER SIGN}" !~ m/^<!InMiscellaneousTechnical>.$/, q{Don't match negated <InMiscellaneousTechnical>} );
ok( "\N{DIAMETER SIGN}" !~ m/^<-InMiscellaneousTechnical>$/, q{Don't match inverted <InMiscellaneousTechnical>} );
ok( "\x{2EFC}"  !~ m/^<InMiscellaneousTechnical>$/, q{Don't match unrelated <InMiscellaneousTechnical>} );
ok( "\x{2EFC}"  =~ m/^<!InMiscellaneousTechnical>.$/, q{Match unrelated negated <InMiscellaneousTechnical>} );
ok( "\x{2EFC}"  =~ m/^<-InMiscellaneousTechnical>$/, q{Match unrelated inverted <InMiscellaneousTechnical>} );
ok( "\x{2EFC}\N{DIAMETER SIGN}" =~ m/<InMiscellaneousTechnical>/, q{Match unanchored <InMiscellaneousTechnical>} );

# InMongolian


ok( "\N{MONGOLIAN BIRGA}" =~ m/^<InMongolian>$/, q{Match <InMongolian>} );
ok( "\N{MONGOLIAN BIRGA}" !~ m/^<!InMongolian>.$/, q{Don't match negated <InMongolian>} );
ok( "\N{MONGOLIAN BIRGA}" !~ m/^<-InMongolian>$/, q{Don't match inverted <InMongolian>} );
ok( "\x{AFB4}"  !~ m/^<InMongolian>$/, q{Don't match unrelated <InMongolian>} );
ok( "\x{AFB4}"  =~ m/^<!InMongolian>.$/, q{Match unrelated negated <InMongolian>} );
ok( "\x{AFB4}"  =~ m/^<-InMongolian>$/, q{Match unrelated inverted <InMongolian>} );
ok( "\x{AFB4}\N{MONGOLIAN BIRGA}" =~ m/<InMongolian>/, q{Match unanchored <InMongolian>} );

# InMusicalSymbols


ok( "\x{0CE4}"  !~ m/^<InMusicalSymbols>$/, q{Don't match unrelated <InMusicalSymbols>} );
ok( "\x{0CE4}"  =~ m/^<!InMusicalSymbols>.$/, q{Match unrelated negated <InMusicalSymbols>} );
ok( "\x{0CE4}"  =~ m/^<-InMusicalSymbols>$/, q{Match unrelated inverted <InMusicalSymbols>} );

# InMyanmar


ok( "\N{MYANMAR LETTER KA}" =~ m/^<InMyanmar>$/, q{Match <InMyanmar>} );
ok( "\N{MYANMAR LETTER KA}" !~ m/^<!InMyanmar>.$/, q{Don't match negated <InMyanmar>} );
ok( "\N{MYANMAR LETTER KA}" !~ m/^<-InMyanmar>$/, q{Don't match inverted <InMyanmar>} );
ok( "\x{1DDB}"  !~ m/^<InMyanmar>$/, q{Don't match unrelated <InMyanmar>} );
ok( "\x{1DDB}"  =~ m/^<!InMyanmar>.$/, q{Match unrelated negated <InMyanmar>} );
ok( "\x{1DDB}"  =~ m/^<-InMyanmar>$/, q{Match unrelated inverted <InMyanmar>} );
ok( "\x{1DDB}\N{MYANMAR LETTER KA}" =~ m/<InMyanmar>/, q{Match unanchored <InMyanmar>} );

# InNumberForms


ok( "\x{2150}" =~ m/^<InNumberForms>$/, q{Match <InNumberForms>} );
ok( "\x{2150}" !~ m/^<!InNumberForms>.$/, q{Don't match negated <InNumberForms>} );
ok( "\x{2150}" !~ m/^<-InNumberForms>$/, q{Don't match inverted <InNumberForms>} );
ok( "\N{BLACK RIGHT-POINTING SMALL TRIANGLE}"  !~ m/^<InNumberForms>$/, q{Don't match unrelated <InNumberForms>} );
ok( "\N{BLACK RIGHT-POINTING SMALL TRIANGLE}"  =~ m/^<!InNumberForms>.$/, q{Match unrelated negated <InNumberForms>} );
ok( "\N{BLACK RIGHT-POINTING SMALL TRIANGLE}"  =~ m/^<-InNumberForms>$/, q{Match unrelated inverted <InNumberForms>} );
ok( "\N{BLACK RIGHT-POINTING SMALL TRIANGLE}\x{2150}" =~ m/<InNumberForms>/, q{Match unanchored <InNumberForms>} );

# InOgham


ok( "\N{OGHAM SPACE MARK}" =~ m/^<InOgham>$/, q{Match <InOgham>} );
ok( "\N{OGHAM SPACE MARK}" !~ m/^<!InOgham>.$/, q{Don't match negated <InOgham>} );
ok( "\N{OGHAM SPACE MARK}" !~ m/^<-InOgham>$/, q{Don't match inverted <InOgham>} );
ok( "\x{768C}"  !~ m/^<InOgham>$/, q{Don't match unrelated <InOgham>} );
ok( "\x{768C}"  =~ m/^<!InOgham>.$/, q{Match unrelated negated <InOgham>} );
ok( "\x{768C}"  =~ m/^<-InOgham>$/, q{Match unrelated inverted <InOgham>} );
ok( "\x{768C}\N{OGHAM SPACE MARK}" =~ m/<InOgham>/, q{Match unanchored <InOgham>} );

# InOldItalic


ok( "\x{C597}"  !~ m/^<InOldItalic>$/, q{Don't match unrelated <InOldItalic>} );
ok( "\x{C597}"  =~ m/^<!InOldItalic>.$/, q{Match unrelated negated <InOldItalic>} );
ok( "\x{C597}"  =~ m/^<-InOldItalic>$/, q{Match unrelated inverted <InOldItalic>} );

# InOpticalCharacterRecognition


ok( "\N{OCR HOOK}" =~ m/^<InOpticalCharacterRecognition>$/, q{Match <InOpticalCharacterRecognition>} );
ok( "\N{OCR HOOK}" !~ m/^<!InOpticalCharacterRecognition>.$/, q{Don't match negated <InOpticalCharacterRecognition>} );
ok( "\N{OCR HOOK}" !~ m/^<-InOpticalCharacterRecognition>$/, q{Don't match inverted <InOpticalCharacterRecognition>} );
ok( "\x{BE80}"  !~ m/^<InOpticalCharacterRecognition>$/, q{Don't match unrelated <InOpticalCharacterRecognition>} );
ok( "\x{BE80}"  =~ m/^<!InOpticalCharacterRecognition>.$/, q{Match unrelated negated <InOpticalCharacterRecognition>} );
ok( "\x{BE80}"  =~ m/^<-InOpticalCharacterRecognition>$/, q{Match unrelated inverted <InOpticalCharacterRecognition>} );
ok( "\x{BE80}\N{OCR HOOK}" =~ m/<InOpticalCharacterRecognition>/, q{Match unanchored <InOpticalCharacterRecognition>} );

# InOriya


ok( "\x{0B00}" =~ m/^<InOriya>$/, q{Match <InOriya>} );
ok( "\x{0B00}" !~ m/^<!InOriya>.$/, q{Don't match negated <InOriya>} );
ok( "\x{0B00}" !~ m/^<-InOriya>$/, q{Don't match inverted <InOriya>} );
ok( "\N{YI SYLLABLE GGEX}"  !~ m/^<InOriya>$/, q{Don't match unrelated <InOriya>} );
ok( "\N{YI SYLLABLE GGEX}"  =~ m/^<!InOriya>.$/, q{Match unrelated negated <InOriya>} );
ok( "\N{YI SYLLABLE GGEX}"  =~ m/^<-InOriya>$/, q{Match unrelated inverted <InOriya>} );
ok( "\N{YI SYLLABLE GGEX}\x{0B00}" =~ m/<InOriya>/, q{Match unanchored <InOriya>} );

# InPrivateUseArea


ok( "\x{B6B1}"  !~ m/^<InPrivateUseArea>$/, q{Don't match unrelated <InPrivateUseArea>} );
ok( "\x{B6B1}"  =~ m/^<!InPrivateUseArea>.$/, q{Match unrelated negated <InPrivateUseArea>} );
ok( "\x{B6B1}"  =~ m/^<-InPrivateUseArea>$/, q{Match unrelated inverted <InPrivateUseArea>} );

# InRunic


ok( "\N{RUNIC LETTER FEHU FEOH FE F}" =~ m/^<InRunic>$/, q{Match <InRunic>} );
ok( "\N{RUNIC LETTER FEHU FEOH FE F}" !~ m/^<!InRunic>.$/, q{Don't match negated <InRunic>} );
ok( "\N{RUNIC LETTER FEHU FEOH FE F}" !~ m/^<-InRunic>$/, q{Don't match inverted <InRunic>} );
ok( "\N{SINHALA LETTER MAHAAPRAANA KAYANNA}"  !~ m/^<InRunic>$/, q{Don't match unrelated <InRunic>} );
ok( "\N{SINHALA LETTER MAHAAPRAANA KAYANNA}"  =~ m/^<!InRunic>.$/, q{Match unrelated negated <InRunic>} );
ok( "\N{SINHALA LETTER MAHAAPRAANA KAYANNA}"  =~ m/^<-InRunic>$/, q{Match unrelated inverted <InRunic>} );
ok( "\N{SINHALA LETTER MAHAAPRAANA KAYANNA}\N{RUNIC LETTER FEHU FEOH FE F}" =~ m/<InRunic>/, q{Match unanchored <InRunic>} );

# InSinhala


ok( "\x{0D80}" =~ m/^<InSinhala>$/, q{Match <InSinhala>} );
ok( "\x{0D80}" !~ m/^<!InSinhala>.$/, q{Don't match negated <InSinhala>} );
ok( "\x{0D80}" !~ m/^<-InSinhala>$/, q{Don't match inverted <InSinhala>} );
ok( "\x{1060}"  !~ m/^<InSinhala>$/, q{Don't match unrelated <InSinhala>} );
ok( "\x{1060}"  =~ m/^<!InSinhala>.$/, q{Match unrelated negated <InSinhala>} );
ok( "\x{1060}"  =~ m/^<-InSinhala>$/, q{Match unrelated inverted <InSinhala>} );
ok( "\x{1060}\x{0D80}" =~ m/<InSinhala>/, q{Match unanchored <InSinhala>} );

# InSmallFormVariants


ok( "\x{5285}"  !~ m/^<InSmallFormVariants>$/, q{Don't match unrelated <InSmallFormVariants>} );
ok( "\x{5285}"  =~ m/^<!InSmallFormVariants>.$/, q{Match unrelated negated <InSmallFormVariants>} );
ok( "\x{5285}"  =~ m/^<-InSmallFormVariants>$/, q{Match unrelated inverted <InSmallFormVariants>} );

# InSpacingModifierLetters


ok( "\N{MODIFIER LETTER SMALL H}" =~ m/^<InSpacingModifierLetters>$/, q{Match <InSpacingModifierLetters>} );
ok( "\N{MODIFIER LETTER SMALL H}" !~ m/^<!InSpacingModifierLetters>.$/, q{Don't match negated <InSpacingModifierLetters>} );
ok( "\N{MODIFIER LETTER SMALL H}" !~ m/^<-InSpacingModifierLetters>$/, q{Don't match inverted <InSpacingModifierLetters>} );
ok( "\x{5326}"  !~ m/^<InSpacingModifierLetters>$/, q{Don't match unrelated <InSpacingModifierLetters>} );
ok( "\x{5326}"  =~ m/^<!InSpacingModifierLetters>.$/, q{Match unrelated negated <InSpacingModifierLetters>} );
ok( "\x{5326}"  =~ m/^<-InSpacingModifierLetters>$/, q{Match unrelated inverted <InSpacingModifierLetters>} );
ok( "\x{5326}\N{MODIFIER LETTER SMALL H}" =~ m/<InSpacingModifierLetters>/, q{Match unanchored <InSpacingModifierLetters>} );

# InSpecials


ok( "\x{3DF1}"  !~ m/^<InSpecials>$/, q{Don't match unrelated <InSpecials>} );
ok( "\x{3DF1}"  =~ m/^<!InSpecials>.$/, q{Match unrelated negated <InSpecials>} );
ok( "\x{3DF1}"  =~ m/^<-InSpecials>$/, q{Match unrelated inverted <InSpecials>} );

# InSuperscriptsAndSubscripts


ok( "\N{SUPERSCRIPT ZERO}" =~ m/^<InSuperscriptsAndSubscripts>$/, q{Match <InSuperscriptsAndSubscripts>} );
ok( "\N{SUPERSCRIPT ZERO}" !~ m/^<!InSuperscriptsAndSubscripts>.$/, q{Don't match negated <InSuperscriptsAndSubscripts>} );
ok( "\N{SUPERSCRIPT ZERO}" !~ m/^<-InSuperscriptsAndSubscripts>$/, q{Don't match inverted <InSuperscriptsAndSubscripts>} );
ok( "\x{3E71}"  !~ m/^<InSuperscriptsAndSubscripts>$/, q{Don't match unrelated <InSuperscriptsAndSubscripts>} );
ok( "\x{3E71}"  =~ m/^<!InSuperscriptsAndSubscripts>.$/, q{Match unrelated negated <InSuperscriptsAndSubscripts>} );
ok( "\x{3E71}"  =~ m/^<-InSuperscriptsAndSubscripts>$/, q{Match unrelated inverted <InSuperscriptsAndSubscripts>} );
ok( "\x{3E71}\N{SUPERSCRIPT ZERO}" =~ m/<InSuperscriptsAndSubscripts>/, q{Match unanchored <InSuperscriptsAndSubscripts>} );

# InSupplementalArrowsA


ok( "\N{UPWARDS QUADRUPLE ARROW}" =~ m/^<InSupplementalArrowsA>$/, q{Match <InSupplementalArrowsA>} );
ok( "\N{UPWARDS QUADRUPLE ARROW}" !~ m/^<!InSupplementalArrowsA>.$/, q{Don't match negated <InSupplementalArrowsA>} );
ok( "\N{UPWARDS QUADRUPLE ARROW}" !~ m/^<-InSupplementalArrowsA>$/, q{Don't match inverted <InSupplementalArrowsA>} );
ok( "\N{GREEK SMALL LETTER OMICRON WITH TONOS}"  !~ m/^<InSupplementalArrowsA>$/, q{Don't match unrelated <InSupplementalArrowsA>} );
ok( "\N{GREEK SMALL LETTER OMICRON WITH TONOS}"  =~ m/^<!InSupplementalArrowsA>.$/, q{Match unrelated negated <InSupplementalArrowsA>} );
ok( "\N{GREEK SMALL LETTER OMICRON WITH TONOS}"  =~ m/^<-InSupplementalArrowsA>$/, q{Match unrelated inverted <InSupplementalArrowsA>} );
ok( "\N{GREEK SMALL LETTER OMICRON WITH TONOS}\N{UPWARDS QUADRUPLE ARROW}" =~ m/<InSupplementalArrowsA>/, q{Match unanchored <InSupplementalArrowsA>} );

# InSupplementalArrowsB


ok( "\N{RIGHTWARDS TWO-HEADED ARROW WITH VERTICAL STROKE}" =~ m/^<InSupplementalArrowsB>$/, q{Match <InSupplementalArrowsB>} );
ok( "\N{RIGHTWARDS TWO-HEADED ARROW WITH VERTICAL STROKE}" !~ m/^<!InSupplementalArrowsB>.$/, q{Don't match negated <InSupplementalArrowsB>} );
ok( "\N{RIGHTWARDS TWO-HEADED ARROW WITH VERTICAL STROKE}" !~ m/^<-InSupplementalArrowsB>$/, q{Don't match inverted <InSupplementalArrowsB>} );
ok( "\x{C1A9}"  !~ m/^<InSupplementalArrowsB>$/, q{Don't match unrelated <InSupplementalArrowsB>} );
ok( "\x{C1A9}"  =~ m/^<!InSupplementalArrowsB>.$/, q{Match unrelated negated <InSupplementalArrowsB>} );
ok( "\x{C1A9}"  =~ m/^<-InSupplementalArrowsB>$/, q{Match unrelated inverted <InSupplementalArrowsB>} );
ok( "\x{C1A9}\N{RIGHTWARDS TWO-HEADED ARROW WITH VERTICAL STROKE}" =~ m/<InSupplementalArrowsB>/, q{Match unanchored <InSupplementalArrowsB>} );

# InSupplementalMathematicalOperators


ok( "\N{N-ARY CIRCLED DOT OPERATOR}" =~ m/^<InSupplementalMathematicalOperators>$/, q{Match <InSupplementalMathematicalOperators>} );
ok( "\N{N-ARY CIRCLED DOT OPERATOR}" !~ m/^<!InSupplementalMathematicalOperators>.$/, q{Don't match negated <InSupplementalMathematicalOperators>} );
ok( "\N{N-ARY CIRCLED DOT OPERATOR}" !~ m/^<-InSupplementalMathematicalOperators>$/, q{Don't match inverted <InSupplementalMathematicalOperators>} );
ok( "\x{9EBD}"  !~ m/^<InSupplementalMathematicalOperators>$/, q{Don't match unrelated <InSupplementalMathematicalOperators>} );
ok( "\x{9EBD}"  =~ m/^<!InSupplementalMathematicalOperators>.$/, q{Match unrelated negated <InSupplementalMathematicalOperators>} );
ok( "\x{9EBD}"  =~ m/^<-InSupplementalMathematicalOperators>$/, q{Match unrelated inverted <InSupplementalMathematicalOperators>} );
ok( "\x{9EBD}\N{N-ARY CIRCLED DOT OPERATOR}" =~ m/<InSupplementalMathematicalOperators>/, q{Match unanchored <InSupplementalMathematicalOperators>} );

# InSupplementaryPrivateUseAreaA


ok( "\x{07E3}"  !~ m/^<InSupplementaryPrivateUseAreaA>$/, q{Don't match unrelated <InSupplementaryPrivateUseAreaA>} );
ok( "\x{07E3}"  =~ m/^<!InSupplementaryPrivateUseAreaA>.$/, q{Match unrelated negated <InSupplementaryPrivateUseAreaA>} );
ok( "\x{07E3}"  =~ m/^<-InSupplementaryPrivateUseAreaA>$/, q{Match unrelated inverted <InSupplementaryPrivateUseAreaA>} );

# InSupplementaryPrivateUseAreaB


ok( "\x{4C48}"  !~ m/^<InSupplementaryPrivateUseAreaB>$/, q{Don't match unrelated <InSupplementaryPrivateUseAreaB>} );
ok( "\x{4C48}"  =~ m/^<!InSupplementaryPrivateUseAreaB>.$/, q{Match unrelated negated <InSupplementaryPrivateUseAreaB>} );
ok( "\x{4C48}"  =~ m/^<-InSupplementaryPrivateUseAreaB>$/, q{Match unrelated inverted <InSupplementaryPrivateUseAreaB>} );

# InSyriac


ok( "\N{SYRIAC END OF PARAGRAPH}" =~ m/^<InSyriac>$/, q{Match <InSyriac>} );
ok( "\N{SYRIAC END OF PARAGRAPH}" !~ m/^<!InSyriac>.$/, q{Don't match negated <InSyriac>} );
ok( "\N{SYRIAC END OF PARAGRAPH}" !~ m/^<-InSyriac>$/, q{Don't match inverted <InSyriac>} );
ok( "\N{YI SYLLABLE NZIEP}"  !~ m/^<InSyriac>$/, q{Don't match unrelated <InSyriac>} );
ok( "\N{YI SYLLABLE NZIEP}"  =~ m/^<!InSyriac>.$/, q{Match unrelated negated <InSyriac>} );
ok( "\N{YI SYLLABLE NZIEP}"  =~ m/^<-InSyriac>$/, q{Match unrelated inverted <InSyriac>} );
ok( "\N{YI SYLLABLE NZIEP}\N{SYRIAC END OF PARAGRAPH}" =~ m/<InSyriac>/, q{Match unanchored <InSyriac>} );

# InTagalog


ok( "\N{TAGALOG LETTER A}" =~ m/^<InTagalog>$/, q{Match <InTagalog>} );
ok( "\N{TAGALOG LETTER A}" !~ m/^<!InTagalog>.$/, q{Don't match negated <InTagalog>} );
ok( "\N{TAGALOG LETTER A}" !~ m/^<-InTagalog>$/, q{Don't match inverted <InTagalog>} );
ok( "\N{GEORGIAN LETTER BAN}"  !~ m/^<InTagalog>$/, q{Don't match unrelated <InTagalog>} );
ok( "\N{GEORGIAN LETTER BAN}"  =~ m/^<!InTagalog>.$/, q{Match unrelated negated <InTagalog>} );
ok( "\N{GEORGIAN LETTER BAN}"  =~ m/^<-InTagalog>$/, q{Match unrelated inverted <InTagalog>} );
ok( "\N{GEORGIAN LETTER BAN}\N{TAGALOG LETTER A}" =~ m/<InTagalog>/, q{Match unanchored <InTagalog>} );

# InTagbanwa


ok( "\N{TAGBANWA LETTER A}" =~ m/^<InTagbanwa>$/, q{Match <InTagbanwa>} );
ok( "\N{TAGBANWA LETTER A}" !~ m/^<!InTagbanwa>.$/, q{Don't match negated <InTagbanwa>} );
ok( "\N{TAGBANWA LETTER A}" !~ m/^<-InTagbanwa>$/, q{Don't match inverted <InTagbanwa>} );
ok( "\x{5776}"  !~ m/^<InTagbanwa>$/, q{Don't match unrelated <InTagbanwa>} );
ok( "\x{5776}"  =~ m/^<!InTagbanwa>.$/, q{Match unrelated negated <InTagbanwa>} );
ok( "\x{5776}"  =~ m/^<-InTagbanwa>$/, q{Match unrelated inverted <InTagbanwa>} );
ok( "\x{5776}\N{TAGBANWA LETTER A}" =~ m/<InTagbanwa>/, q{Match unanchored <InTagbanwa>} );

# InTags


ok( "\x{3674}"  !~ m/^<InTags>$/, q{Don't match unrelated <InTags>} );
ok( "\x{3674}"  =~ m/^<!InTags>.$/, q{Match unrelated negated <InTags>} );
ok( "\x{3674}"  =~ m/^<-InTags>$/, q{Match unrelated inverted <InTags>} );

# InTamil


ok( "\x{0B80}" =~ m/^<InTamil>$/, q{Match <InTamil>} );
ok( "\x{0B80}" !~ m/^<!InTamil>.$/, q{Don't match negated <InTamil>} );
ok( "\x{0B80}" !~ m/^<-InTamil>$/, q{Don't match inverted <InTamil>} );
ok( "\x{B58F}"  !~ m/^<InTamil>$/, q{Don't match unrelated <InTamil>} );
ok( "\x{B58F}"  =~ m/^<!InTamil>.$/, q{Match unrelated negated <InTamil>} );
ok( "\x{B58F}"  =~ m/^<-InTamil>$/, q{Match unrelated inverted <InTamil>} );
ok( "\x{B58F}\x{0B80}" =~ m/<InTamil>/, q{Match unanchored <InTamil>} );

# InTelugu


ok( "\x{0C00}" =~ m/^<InTelugu>$/, q{Match <InTelugu>} );
ok( "\x{0C00}" !~ m/^<!InTelugu>.$/, q{Don't match negated <InTelugu>} );
ok( "\x{0C00}" !~ m/^<-InTelugu>$/, q{Don't match inverted <InTelugu>} );
ok( "\x{8AC5}"  !~ m/^<InTelugu>$/, q{Don't match unrelated <InTelugu>} );
ok( "\x{8AC5}"  =~ m/^<!InTelugu>.$/, q{Match unrelated negated <InTelugu>} );
ok( "\x{8AC5}"  =~ m/^<-InTelugu>$/, q{Match unrelated inverted <InTelugu>} );
ok( "\x{8AC5}\x{0C00}" =~ m/<InTelugu>/, q{Match unanchored <InTelugu>} );

# InThaana


ok( "\N{THAANA LETTER HAA}" =~ m/^<InThaana>$/, q{Match <InThaana>} );
ok( "\N{THAANA LETTER HAA}" !~ m/^<!InThaana>.$/, q{Don't match negated <InThaana>} );
ok( "\N{THAANA LETTER HAA}" !~ m/^<-InThaana>$/, q{Don't match inverted <InThaana>} );
ok( "\x{BB8F}"  !~ m/^<InThaana>$/, q{Don't match unrelated <InThaana>} );
ok( "\x{BB8F}"  =~ m/^<!InThaana>.$/, q{Match unrelated negated <InThaana>} );
ok( "\x{BB8F}"  =~ m/^<-InThaana>$/, q{Match unrelated inverted <InThaana>} );
ok( "\x{BB8F}\N{THAANA LETTER HAA}" =~ m/<InThaana>/, q{Match unanchored <InThaana>} );

# InThai


ok( "\x{0E00}" =~ m/^<InThai>$/, q{Match <InThai>} );
ok( "\x{0E00}" !~ m/^<!InThai>.$/, q{Don't match negated <InThai>} );
ok( "\x{0E00}" !~ m/^<-InThai>$/, q{Don't match inverted <InThai>} );
ok( "\x{9395}"  !~ m/^<InThai>$/, q{Don't match unrelated <InThai>} );
ok( "\x{9395}"  =~ m/^<!InThai>.$/, q{Match unrelated negated <InThai>} );
ok( "\x{9395}"  =~ m/^<-InThai>$/, q{Match unrelated inverted <InThai>} );
ok( "\x{9395}\x{0E00}" =~ m/<InThai>/, q{Match unanchored <InThai>} );

# InTibetan


ok( "\N{TIBETAN SYLLABLE OM}" =~ m/^<InTibetan>$/, q{Match <InTibetan>} );
ok( "\N{TIBETAN SYLLABLE OM}" !~ m/^<!InTibetan>.$/, q{Don't match negated <InTibetan>} );
ok( "\N{TIBETAN SYLLABLE OM}" !~ m/^<-InTibetan>$/, q{Don't match inverted <InTibetan>} );
ok( "\x{957A}"  !~ m/^<InTibetan>$/, q{Don't match unrelated <InTibetan>} );
ok( "\x{957A}"  =~ m/^<!InTibetan>.$/, q{Match unrelated negated <InTibetan>} );
ok( "\x{957A}"  =~ m/^<-InTibetan>$/, q{Match unrelated inverted <InTibetan>} );
ok( "\x{957A}\N{TIBETAN SYLLABLE OM}" =~ m/<InTibetan>/, q{Match unanchored <InTibetan>} );

# InUnifiedCanadianAboriginalSyllabics


ok( "\x{1400}" =~ m/^<InUnifiedCanadianAboriginalSyllabics>$/, q{Match <InUnifiedCanadianAboriginalSyllabics>} );
ok( "\x{1400}" !~ m/^<!InUnifiedCanadianAboriginalSyllabics>.$/, q{Don't match negated <InUnifiedCanadianAboriginalSyllabics>} );
ok( "\x{1400}" !~ m/^<-InUnifiedCanadianAboriginalSyllabics>$/, q{Don't match inverted <InUnifiedCanadianAboriginalSyllabics>} );
ok( "\x{9470}"  !~ m/^<InUnifiedCanadianAboriginalSyllabics>$/, q{Don't match unrelated <InUnifiedCanadianAboriginalSyllabics>} );
ok( "\x{9470}"  =~ m/^<!InUnifiedCanadianAboriginalSyllabics>.$/, q{Match unrelated negated <InUnifiedCanadianAboriginalSyllabics>} );
ok( "\x{9470}"  =~ m/^<-InUnifiedCanadianAboriginalSyllabics>$/, q{Match unrelated inverted <InUnifiedCanadianAboriginalSyllabics>} );
ok( "\x{9470}\x{1400}" =~ m/<InUnifiedCanadianAboriginalSyllabics>/, q{Match unanchored <InUnifiedCanadianAboriginalSyllabics>} );

# InVariationSelectors


ok( "\x{764D}"  !~ m/^<InVariationSelectors>$/, q{Don't match unrelated <InVariationSelectors>} );
ok( "\x{764D}"  =~ m/^<!InVariationSelectors>.$/, q{Match unrelated negated <InVariationSelectors>} );
ok( "\x{764D}"  =~ m/^<-InVariationSelectors>$/, q{Match unrelated inverted <InVariationSelectors>} );

# InYiRadicals


ok( "\N{YI RADICAL QOT}" =~ m/^<InYiRadicals>$/, q{Match <InYiRadicals>} );
ok( "\N{YI RADICAL QOT}" !~ m/^<!InYiRadicals>.$/, q{Don't match negated <InYiRadicals>} );
ok( "\N{YI RADICAL QOT}" !~ m/^<-InYiRadicals>$/, q{Don't match inverted <InYiRadicals>} );
ok( "\x{3A4E}"  !~ m/^<InYiRadicals>$/, q{Don't match unrelated <InYiRadicals>} );
ok( "\x{3A4E}"  =~ m/^<!InYiRadicals>.$/, q{Match unrelated negated <InYiRadicals>} );
ok( "\x{3A4E}"  =~ m/^<-InYiRadicals>$/, q{Match unrelated inverted <InYiRadicals>} );
ok( "\x{3A4E}\N{YI RADICAL QOT}" =~ m/<InYiRadicals>/, q{Match unanchored <InYiRadicals>} );

# InYiSyllables


ok( "\N{YI SYLLABLE IT}" =~ m/^<InYiSyllables>$/, q{Match <InYiSyllables>} );
ok( "\N{YI SYLLABLE IT}" !~ m/^<!InYiSyllables>.$/, q{Don't match negated <InYiSyllables>} );
ok( "\N{YI SYLLABLE IT}" !~ m/^<-InYiSyllables>$/, q{Don't match inverted <InYiSyllables>} );
ok( "\N{PARALLEL WITH HORIZONTAL STROKE}"  !~ m/^<InYiSyllables>$/, q{Don't match unrelated <InYiSyllables>} );
ok( "\N{PARALLEL WITH HORIZONTAL STROKE}"  =~ m/^<!InYiSyllables>.$/, q{Match unrelated negated <InYiSyllables>} );
ok( "\N{PARALLEL WITH HORIZONTAL STROKE}"  =~ m/^<-InYiSyllables>$/, q{Match unrelated inverted <InYiSyllables>} );
ok( "\N{PARALLEL WITH HORIZONTAL STROKE}\N{YI SYLLABLE IT}" =~ m/<InYiSyllables>/, q{Match unanchored <InYiSyllables>} );
