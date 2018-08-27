package Term::Choose::LineFold::CharWidthAmbiguousWide;

use warnings;
use strict;
use 5.008003;

our $VERSION = '1.627';

use Exporter qw( import );

our @EXPORT_OK = qw( table_char_width );

# *) filtered away with: $s =~ s/\p{Space}/ /; $s =~ s/\p{C}//;
# else range commented out default to 1
# test with gnome-terminal - ambiguous characters set to wide


sub table_char_width { [
#[0x00000, 0x0001f, 0], #*) C0 Controls and Basic Latin             Range: 0000–007F
#[0x0007f, 0x0007f, 0], #*)
#[0x00080, 0x0009f, 0], #*) C1 Controls and Latin-1 Supplement      Range: 0080–00FF
 [0x000a1, 0x000a1, 2],
 [0x000a4, 0x000a4, 2],
 [0x000a7, 0x000a8, 2],
 [0x000aa, 0x000aa, 2],
#[0x000ad, 0x000ad, 0], #*)
 [0x000ae, 0x000ae, 2],
 [0x000b0, 0x000b4, 2],
 [0x000b6, 0x000ba, 2],
 [0x000bc, 0x000bf, 2],
 [0x000c6, 0x000c6, 2],
 [0x000d0, 0x000d0, 2],
 [0x000d7, 0x000d8, 2],
 [0x000de, 0x000e1, 2],
 [0x000e6, 0x000e6, 2],
 [0x000e8, 0x000ea, 2],
 [0x000ec, 0x000ed, 2],
 [0x000f0, 0x000f0, 2],
 [0x000f2, 0x000f3, 2],
 [0x000f7, 0x000fa, 2],
 [0x000fc, 0x000fc, 2],
 [0x000fe, 0x000fe, 2],
 [0x00101, 0x00101, 2], #   Latin Extended-A                        Range: 0100–017F
 [0x00111, 0x00111, 2],
 [0x00113, 0x00113, 2],
 [0x0011b, 0x0011b, 2],
 [0x00126, 0x00127, 2],
 [0x0012b, 0x0012b, 2],
 [0x00131, 0x00133, 2],
 [0x00138, 0x00138, 2],
 [0x0013f, 0x00142, 2],
 [0x00144, 0x00144, 2],
 [0x00148, 0x0014b, 2],
 [0x0014d, 0x0014d, 2],
 [0x00152, 0x00153, 2],
 [0x00166, 0x00167, 2],
 [0x0016b, 0x0016b, 2],
 [0x001ce, 0x001ce, 2], #   Latin Extended-B                        Range: 0180–024F
 [0x001d0, 0x001d0, 2],
 [0x001d2, 0x001d2, 2],
 [0x001d4, 0x001d4, 2],
 [0x001d6, 0x001d6, 2],
 [0x001d8, 0x001d8, 2],
 [0x001da, 0x001da, 2],
 [0x001dc, 0x001dc, 2],
 [0x00251, 0x00251, 2], #   IPA Extensions                          Range: 0250–02AF
 [0x00261, 0x00261, 2],
 [0x002c4, 0x002c4, 2], #   Spacing Modifier Letters                Range: 02B0–02FF
 [0x002c7, 0x002c7, 2],
 [0x002c9, 0x002cb, 2],
 [0x002cd, 0x002cd, 2],
 [0x002d0, 0x002d0, 2],
 [0x002d8, 0x002db, 2],
 [0x002dd, 0x002dd, 2],
 [0x002df, 0x002df, 2],
 [0x00300, 0x0036f, 0], #   Combining Diacritical Marks             Range: 0300–036F
 [0x00391, 0x003a1, 2], #   Greek and Coptic                        Range: 0370–03FF
 [0x003a3, 0x003a9, 2],
 [0x003b1, 0x003c1, 2],
 [0x003c3, 0x003c9, 2],
 [0x00401, 0x00401, 2], #   Cyrillic                                Range: 0400–04FF
 [0x00410, 0x0044f, 2],
 [0x00451, 0x00451, 2],
 [0x00483, 0x00489, 0],
                        #   Cyrillic Supplement                     Range: 0500–052F
                        #   Armenian                                Range: 0530–058F
 [0x00591, 0x005bd, 0], #   Hebrew                                  Range: 0590–05FF
 [0x005bf, 0x005bf, 0],
 [0x005c1, 0x005c2, 0],
 [0x005c4, 0x005c5, 0],
 [0x005c7, 0x005c7, 0],
#[0x00600, 0x00605, 0], #*) Arabic                                  Range: 0600–06FF
 [0x00610, 0x0061a, 0],
#[0x0061c, 0x0061c, 0], #*)
 [0x0064b, 0x0065f, 0],
 [0x00670, 0x00670, 0],
 [0x006d6, 0x006dd, 0],
 [0x006df, 0x006e4, 0],
 [0x006e7, 0x006e8, 0],
 [0x006ea, 0x006ed, 0],
#[0x0070f, 0x0070f, 0], #*) Syriac                                  Range: 0700–074F
 [0x00711, 0x00711, 0],
 [0x00730, 0x0074a, 0],
                        #   Arabic Supplement                       Range: 0750–077F
 [0x007a6, 0x007b0, 0], #   Thaana                                  Range: 0780–07BF
 [0x007eb, 0x007f3, 0], #   NKo                                     Range: 07C0–07FF
 [0x00816, 0x00819, 0], #   Samaritan                               Range: 0800–083F
 [0x0081b, 0x00823, 0],
 [0x00825, 0x00827, 0],
 [0x00829, 0x0082d, 0],
 [0x00859, 0x0085b, 0], #   Mandaic                                 Range: 0840–085F
                        #   Syriac Supplement                       Range: 0860–086F
                        #                                           Range: 0870–089F    not_assigned
 [0x008d4, 0x00902, 0], #   Arabic Extended-A                       Range: 08A0–08FF
 [0x0093a, 0x0093a, 0], #   Devanagari                              Range: 0900–097F
 [0x0093c, 0x0093c, 0],
 [0x00941, 0x00948, 0],
 [0x0094d, 0x0094d, 0],
 [0x00951, 0x00957, 0],
 [0x00962, 0x00963, 0],
 [0x00981, 0x00981, 0], #   Bengali                                 Range: 0980–09FF
 [0x009bc, 0x009bc, 0],
 [0x009c1, 0x009c4, 0],
 [0x009cd, 0x009cd, 0],
 [0x009e2, 0x009e3, 0],
 [0x00a01, 0x00a02, 0], #   Gurmukhi                                Range: 0A00–0A7F
 [0x00a3c, 0x00a3c, 0],
 [0x00a41, 0x00a42, 0],
 [0x00a47, 0x00a48, 0],
 [0x00a4b, 0x00a4d, 0],
 [0x00a51, 0x00a51, 0],
 [0x00a70, 0x00a71, 0],
 [0x00a75, 0x00a75, 0],
 [0x00a81, 0x00a82, 0], #   Gujarati                                Range: 0A80–0AFF
 [0x00abc, 0x00abc, 0],
 [0x00ac1, 0x00ac5, 0],
 [0x00ac7, 0x00ac8, 0],
 [0x00acd, 0x00acd, 0],
 [0x00ae2, 0x00ae3, 0],
 [0x00afa, 0x00aff, 0],
 [0x00b01, 0x00b01, 0], #   Oriya                                   Range: 0B00–0B7F
 [0x00b3c, 0x00b3c, 0],
 [0x00b3f, 0x00b3f, 0],
 [0x00b41, 0x00b44, 0],
 [0x00b4d, 0x00b4d, 0],
 [0x00b56, 0x00b56, 0],
 [0x00b62, 0x00b63, 0],
 [0x00b82, 0x00b82, 0], #   Tamil                                   Range: 0B80–0BFF
 [0x00bc0, 0x00bc0, 0],
 [0x00bcd, 0x00bcd, 0],
 [0x00c00, 0x00c00, 0], #   Telugu                                  Range: 0C00–0C7F
 [0x00c3e, 0x00c40, 0],
 [0x00c46, 0x00c48, 0],
 [0x00c4a, 0x00c4d, 0],
 [0x00c55, 0x00c56, 0],
 [0x00c62, 0x00c63, 0],
 [0x00c81, 0x00c81, 0], #   Kannada                                 Range: 0C80–0CFF
 [0x00cbc, 0x00cbc, 0],
 [0x00cbf, 0x00cbf, 0],
 [0x00cc6, 0x00cc6, 0],
 [0x00ccc, 0x00ccd, 0],
 [0x00ce2, 0x00ce3, 0],
 [0x00d00, 0x00d01, 0], #   Malayalam                               Range: 0D00–0D7F
 [0x00d3b, 0x00d3c, 0],
 [0x00d41, 0x00d44, 0],
 [0x00d4d, 0x00d4d, 0],
 [0x00d62, 0x00d63, 0],
 [0x00dca, 0x00dca, 0], #   Sinhala                                 Range: 0D80–0DFF
 [0x00dd2, 0x00dd4, 0],
 [0x00dd6, 0x00dd6, 0],
 [0x00e31, 0x00e31, 0], #   Thai                                    Range: 0E00–0E7F
 [0x00e34, 0x00e3a, 0],
 [0x00e47, 0x00e4e, 0],
 [0x00eb1, 0x00eb1, 0], #   Lao                                     Range: 0E80–0EFF
 [0x00eb4, 0x00eb9, 0],
 [0x00ebb, 0x00ebc, 0],
 [0x00ec8, 0x00ecd, 0],
 [0x00f18, 0x00f19, 0], #   Tibetan                                 Range: 0F00–0FFF
 [0x00f35, 0x00f35, 0],
 [0x00f37, 0x00f37, 0],
 [0x00f39, 0x00f39, 0],
 [0x00f71, 0x00f7e, 0],
 [0x00f80, 0x00f84, 0],
 [0x00f86, 0x00f87, 0],
 [0x00f8d, 0x00f97, 0],
 [0x00f99, 0x00fbc, 0],
 [0x00fc6, 0x00fc6, 0],
 [0x0102d, 0x01030, 0], #   Myanmar                                 Range: 1000–109F
 [0x01032, 0x01037, 0],
 [0x01039, 0x0103a, 0],
 [0x0103d, 0x0103e, 0],
 [0x01058, 0x01059, 0],
 [0x0105e, 0x01060, 0],
 [0x01071, 0x01074, 0],
 [0x01082, 0x01082, 0],
 [0x01085, 0x01086, 0],
 [0x0108d, 0x0108d, 0],
 [0x0109d, 0x0109d, 0],
                        #   Georgian                                Range: 10A0–10FF
 [0x01100, 0x0115f, 2], #   Hangul Jamo                             Range: 1100–11FF
 [0x01160, 0x011ff, 0], #
 [0x0135d, 0x0135f, 0], #   Ethiopic                                Range: 1200–137F
                        #   Ethiopic Supplement                     Range: 1380–139F
                        #   Cherokee                                Range: 13A0–13FF
                        #   Unified Canadian Aboriginal Syllabics   Range: 1400–167F
                        #   Ogham                                   Range: 1680–169F
                        #   Runic                                   Range: 16A0–16FF
 [0x01712, 0x01714, 0], #   Tagalog                                 Range: 1700–171F
 [0x01732, 0x01734, 0], #   Hanunoo                                 Range: 1720–173F
 [0x01752, 0x01753, 0], #   Buhid                                   Range: 1740–175F
 [0x01772, 0x01773, 0], #   Tagbanwa                                Range: 1760–177F
 [0x017b4, 0x017b5, 0], #   Khmer                                   Range: 1780–17FF
 [0x017b7, 0x017bd, 0],
 [0x017c6, 0x017c6, 0],
 [0x017c9, 0x017d3, 0],
 [0x017dd, 0x017dd, 0],
 [0x0180b, 0x0180e, 0], #   Mongolian                               Range: 1800–18AF
 [0x01885, 0x01886, 0],
 [0x018a9, 0x018a9, 0],
                        #   Unified Canadian Aboriginal Syllabics Extended  Range: 18B0–18FF
 [0x01920, 0x01922, 0], #   Limbu                                   Range: 1900–194F
 [0x01927, 0x01928, 0],
 [0x01932, 0x01932, 0],
 [0x01939, 0x0193b, 0],
                        #   Tai Le                                  Range: 1950–197F
                        #   New Tai Lue                             Range: 1980–19DF
                        #   Khmer Symbols                           Range: 19E0–19FF
 [0x01a17, 0x01a18, 0], #   Buginese                                Range: 1A00–1A1F
 [0x01a1b, 0x01a1b, 0],
 [0x01a56, 0x01a56, 0], #   Tai Tham                                Range: 1A20–1AAF
 [0x01a58, 0x01a5e, 0],
 [0x01a60, 0x01a60, 0],
 [0x01a62, 0x01a62, 0],
 [0x01a65, 0x01a6c, 0],
 [0x01a73, 0x01a7c, 0],
 [0x01a7f, 0x01a7f, 0],
 [0x01ab0, 0x01abe, 0], #   Combining Diacritical Marks Extended    Range: 1AB0–1AFF
 [0x01b00, 0x01b03, 0], #   Balinese                                Range: 1B00–1B7F
 [0x01b34, 0x01b34, 0],
 [0x01b36, 0x01b3a, 0],
 [0x01b3c, 0x01b3c, 0],
 [0x01b42, 0x01b42, 0],
 [0x01b6b, 0x01b73, 0],
 [0x01b80, 0x01b81, 0], #   Sundanese                               Range: 1B80–1BBF
 [0x01ba2, 0x01ba5, 0],
 [0x01ba8, 0x01ba9, 0],
 [0x01bab, 0x01bad, 0],
 [0x01be6, 0x01be6, 0], #   Batak                                   Range: 1BC0–1BFF
 [0x01be8, 0x01be9, 0],
 [0x01bed, 0x01bed, 0],
 [0x01bef, 0x01bf1, 0],
 [0x01c2c, 0x01c33, 0], #   Lepcha                                  Range: 1C00–1C4F
 [0x01c36, 0x01c37, 0],
                        #   Ol Chiki                                Range: 1C50–1C7F
                        #   Cyrillic Extended-C                     Range: 1C80–1C8F
                        #   Georgian Extended                       Range: 1C90–1CBF
                        #   Sundanese Supplement                    Range: 1CC0–1CCF
 [0x01cd0, 0x01cd2, 0], #   Vedic Extensions                        Range: 1CD0–1CFF
 [0x01cd4, 0x01ce0, 0],
 [0x01ce2, 0x01ce8, 0],
 [0x01ced, 0x01ced, 0],
 [0x01cf4, 0x01cf4, 0],
 [0x01cf8, 0x01cf9, 0],
 [0x01dc0, 0x01df9, 0], #   Phonetic Extensions                     Range: 1D00–1D7F
                        #   Phonetic Extensions Supplement          Range: 1D80–1DBF
 [0x01dfb, 0x01dff, 0], #   Combining Diacritical Marks Supplement  Range: 1DC0–1DFF
                        #   Latin Extended Additional               Range: 1E00–1EFF
                        #   Greek Extended                          Range: 1F00–1FFF
#[0x0200b, 0x0200f, 0], #*) General Punctuation                     Range: 2000–206F
 [0x02010, 0x02010, 2],
 [0x02013, 0x02016, 2],
 [0x02018, 0x02019, 2],
 [0x0201c, 0x0201d, 2],
 [0x02020, 0x02022, 2],
 [0x02024, 0x02027, 2],
#[0x02028, 0x02029, 0], #*)
#[0x0202a, 0x0202e, 0], #*)
 [0x02030, 0x02030, 2],
 [0x02032, 0x02033, 2],
 [0x02035, 0x02035, 2],
 [0x0203b, 0x0203b, 2],
 [0x0203e, 0x0203e, 2],
#[0x0206a, 0x0206f, 0], #*)
 [0x02074, 0x02074, 2], #   Superscripts and Subscripts             Range: 2070–209F
 [0x0207f, 0x0207f, 2],
 [0x02081, 0x02084, 2],
 [0x020ac, 0x020ac, 2], #   Currency Symbols                        Range: 20A0–20CF
 [0x020d0, 0x020f0, 0], #   Combining Diacritical Marks for Symbols Range: 20D0–20FF
 [0x02103, 0x02103, 2], #   Letterlike Symbols                      Range: 2100–214F
 [0x02105, 0x02105, 2],
 [0x02109, 0x02109, 2],
 [0x02113, 0x02113, 2],
 [0x02116, 0x02116, 2],
 [0x02121, 0x02122, 2],
 [0x02126, 0x02126, 2],
 [0x0212b, 0x0212b, 2],
 [0x02153, 0x02154, 2], #   Number Forms                            Range: 2150–218F
 [0x0215b, 0x0215e, 2],
 [0x02160, 0x0216b, 2],
 [0x02170, 0x02179, 2],
 [0x02189, 0x02189, 2],
 [0x02190, 0x02199, 2],#   Arrows                                  Range: 2190–21FF
 [0x021b8, 0x021b9, 2],
 [0x021d2, 0x021d2, 2],
 [0x021d4, 0x021d4, 2],
 [0x021e7, 0x021e7, 2],
 [0x02200, 0x02200, 2], #   Mathematical Operators                  Range: 2200–22FF
 [0x02202, 0x02203, 2],
 [0x02207, 0x02208, 2],
 [0x0220b, 0x0220b, 2],
 [0x0220f, 0x0220f, 2],
 [0x02211, 0x02211, 2],
 [0x02215, 0x02215, 2],
 [0x0221a, 0x0221a, 2],
 [0x0221d, 0x02220, 2],
 [0x02223, 0x02223, 2],
 [0x02225, 0x02225, 2],
 [0x02227, 0x0222c, 2],
 [0x0222e, 0x0222e, 2],
 [0x02234, 0x02237, 2],
 [0x0223c, 0x0223d, 2],
 [0x02248, 0x02248, 2],
 [0x0224c, 0x0224c, 2],
 [0x02252, 0x02252, 2],
 [0x02260, 0x02261, 2],
 [0x02264, 0x02267, 2],
 [0x0226a, 0x0226b, 2],
 [0x0226e, 0x0226f, 2],
 [0x02282, 0x02283, 2],
 [0x02286, 0x02287, 2],
 [0x02295, 0x02295, 2],
 [0x02299, 0x02299, 2],
 [0x022a5, 0x022a5, 2],
 [0x022bf, 0x022bf, 2],
 [0x02312, 0x02312, 2], #   Miscellaneous Technical                 Range: 2300–23FF
 [0x0231a, 0x0231b, 2],
 [0x02329, 0x0232a, 2],
 [0x023e9, 0x023ec, 2],
 [0x023f0, 0x023f0, 2],
 [0x023f3, 0x023f3, 2],
                        #   Control Pictures                        Range: 2400–243F
                        #   Optical Character Recognition           Range: 2440–245F
 [0x02460, 0x024e9, 2], #   Enclosed Alphanumerics                  Range: 2460–24FF
 [0x024eb, 0x0254b, 2],
 [0x02550, 0x02573, 2], #   Box Drawing                             Range: 2500–257F
 [0x02580, 0x0258f, 2], #   Block Elements                          Range: 2580–259F
 [0x02592, 0x02595, 2],
 [0x025a0, 0x025a1, 2], #   Geometric Shapes                        Range: 25A0–25FF
 [0x025a3, 0x025a9, 2],
 [0x025b2, 0x025b3, 2],
 [0x025b6, 0x025b7, 2],
 [0x025bc, 0x025bd, 2],
 [0x025c0, 0x025c1, 2],
 [0x025c6, 0x025c8, 2],
 [0x025cb, 0x025cb, 2],
 [0x025ce, 0x025d1, 2],
 [0x025e2, 0x025e5, 2],
 [0x025ef, 0x025ef, 2],
 [0x025fd, 0x025fe, 2],
 [0x02605, 0x02606, 2], #   Miscellaneous Symbols                   Range: 2600–26FF
 [0x02609, 0x02609, 2],
 [0x0260e, 0x0260f, 2],
 [0x02614, 0x02615, 2],
 [0x0261c, 0x0261c, 2],
 [0x0261e, 0x0261e, 2],
 [0x02640, 0x02640, 2],
 [0x02642, 0x02642, 2],
 [0x02648, 0x02653, 2],
 [0x02660, 0x02661, 2],
 [0x02663, 0x02665, 2],
 [0x02667, 0x0266a, 2],
 [0x0266c, 0x0266d, 2],
 [0x0266f, 0x0266f, 2],
 [0x0267f, 0x0267f, 2],
 [0x02693, 0x02693, 2],
 [0x0269e, 0x0269f, 2],
 [0x026a1, 0x026a1, 2],
 [0x026aa, 0x026ab, 2],
 [0x026bd, 0x026bf, 2],
 [0x026c4, 0x026e1, 2],
 [0x026e3, 0x026e3, 2],
 [0x026e8, 0x026ff, 2],
 [0x02705, 0x02705, 2], #   Dingbats                                Range: 2700–27BF
 [0x0270a, 0x0270b, 2],
 [0x02728, 0x02728, 2],
 [0x0273d, 0x0273d, 2],
 [0x0274c, 0x0274c, 2],
 [0x0274e, 0x0274e, 2],
 [0x02753, 0x02755, 2],
 [0x02757, 0x02757, 2],
 [0x02776, 0x0277f, 2],
 [0x02795, 0x02797, 2],
 [0x027b0, 0x027b0, 2],
 [0x027bf, 0x027bf, 2],
                        #   Miscellaneous Mathematical Symbols-A    Range: 27C0–27EF
                        #   Supplemental Arrows-A                   Range: 27F0–27FF
                        #   Braille Patterns                        Range: 2800–28FF
                        #   Supplemental Arrows-B                   Range: 2900–297F
                        #   Miscellaneous Mathematical Symbols-B    Range: 2980–29FF
                        #   Supplemental Mathematical Operators     Range: 2A00–2AFF
 [0x02b1b, 0x02b1c, 2], #   Miscellaneous Symbols and Arrows        Range: 2B00–2BFF
 [0x02b50, 0x02b50, 2],
 [0x02b55, 0x02b59, 2],
                        #   Glagolitic                              Range: 2C00–2C5F
                        #   Latin Extended-C                        Range: 2C60–2C7F
 [0x02cef, 0x02cf1, 0], #   Coptic                                  Range: 2C80–2CFF
                        #   Georgian Supplement                     Range: 2D00–2D2F
 [0x02d7f, 0x02d7f, 0], #   Tifinagh                                Range: 2D30–2D7F
                        #   Ethiopic Extended                       Range: 2D80–2DDF
 [0x02de0, 0x02dff, 0], #   Cyrillic Extended-A                     Range: 2DE0–2DFF
                        #   Supplemental Punctuation                Range: 2E00–2E7F
 [0x02e80, 0x02fdf, 2], #   CJK Radicals Supplemen                  Range: 2E80–2EFF
                        #   Kangxi Radicals                         Range: 2F00–2FDF
                        #                                           Range: 2FE0-2FEF    not_assigned
 [0x02ff0, 0x03029, 2], #   Ideographic Description Character       Range: 2FF0–2FFF
                        #   CJK Symbols and Punctuation             Range: 3000–303F
 [0x0302a, 0x0302d, 0], #
 [0x0302e, 0x0303e, 2],
 [0x03040, 0x03096, 2], #   Hiragana                                Range: 3040–309F
 [0x03099, 0x0309a, 0], #
 [0x0309b, 0x04db5, 2],
                        #   Katakana                                Range: 30A0–30FF
                        #   Bopomofo                                Range: 3100–312F
                        #   Hangul Compatibility Jamo               Range: 3130–318F
                        #   Kanbun                                  Range: 3190–319F
                        #   Bopomofo Extended                       Range: 31A0–31BF
                        #   CJK Strokes                             Range: 31C0–31EF
                        #   Katakana Phonetic Extensions            Range: 31F0–31FF
                        #   Enclosed CJK Letters and Months         Range: 3200–32FF
                        #   CJK Compatibility                       Range: 3300–33FF
                        #   CJK Unified Ideographs Extension A      Range: 3400–4DB5
                        #                                           Range: 4DB6-4DBF    not_assigned
                        #   Yijing Hexagram Symbols                 Range: 4DC0–4DFF
 [0x04e00, 0x09fef, 2], #   CJK Unified Ideographs                  Range: 4E00–9FEF
                        #                                           Range: 9FF0-9FFF    not_assigned
 [0x0a000, 0x0a4cf, 2], #   Yi Syllables                            Range: A000–A48F
                        #   Yi Radicals                             Range: A490–A4CF
                        #   Lisu                                    Range: A4D0–A4FF
                        #   Vai                                     Range: A500–A63F
 [0x0a66f, 0x0a672, 0], #   Cyrillic Extended-B                     Range: A640–A69F
 [0x0a674, 0x0a67d, 0],
 [0x0a69e, 0x0a69f, 0],
 [0x0a6f0, 0x0a6f1, 0], #   Bamum                                   Range: A6A0–A6FF
                        #   Modifier Tone Letters                   Range: A700–A71F
                        #   Latin Extended-D                        Range: A720–A7FF
 [0x0a802, 0x0a802, 0], #   Syloti Nagri                            Range: A800–A82F
 [0x0a806, 0x0a806, 0],
 [0x0a80b, 0x0a80b, 0],
 [0x0a825, 0x0a826, 0],
                        #   Common Indic Number Forms               Range: A830–A83F
                        #   Phags-pa                                Range: A840–A87F
 [0x0a8c4, 0x0a8c5, 0], #   Saurashtra                              Range: A880–A8DF
 [0x0a8e0, 0x0a8f1, 0], #   Devanagari Extended                     Range: A8E0–A8FF
 [0x0a926, 0x0a92d, 0], #   Kayah Li                                Range: A900–A92F
 [0x0a947, 0x0a951, 0], #   Rejang                                  Range: A930–A95F
 [0x0a960, 0x0a97f, 2], #   Hangul Jamo Extended-A                  Range: A960–A97F
 [0x0a980, 0x0a982, 0], #   Javanese                                Range: A980–A9DF
 [0x0a9b3, 0x0a9b3, 0],
 [0x0a9b6, 0x0a9b9, 0],
 [0x0a9bc, 0x0a9bc, 0],
 [0x0a9e5, 0x0a9e5, 0], #   Myanmar Extended-B                      Range: A9E0–A9FF
 [0x0aa29, 0x0aa2e, 0], #   Cham                                    Range: AA00–AA5F
 [0x0aa31, 0x0aa32, 0],
 [0x0aa35, 0x0aa36, 0],
 [0x0aa43, 0x0aa43, 0],
 [0x0aa4c, 0x0aa4c, 0],
 [0x0aa7c, 0x0aa7c, 0], #   Myanmar Extended-A                      Range: AA60–AA7F
 [0x0aab0, 0x0aab0, 0], #   Tai Viet                                Range: AA80–AADF
 [0x0aab2, 0x0aab4, 0],
 [0x0aab7, 0x0aab8, 0],
 [0x0aabe, 0x0aabf, 0],
 [0x0aac1, 0x0aac1, 0],
 [0x0aaec, 0x0aaed, 0], #   Meetei Mayek Extensions                 Range: AAE0–AAFF
 [0x0aaf6, 0x0aaf6, 0],
                        #   Ethiopic Extended-A                     Range: AB00–AB2F
                        #   Latin Extended-E                        Range: AB30–AB6F
                        #   Cherokee Supplement                     Range: AB70–ABBF
 [0x0abe5, 0x0abe5, 0], #   Meetei Mayek                            Range: ABC0–ABFF
 [0x0abe8, 0x0abe8, 0],
 [0x0abed, 0x0abed, 0],
 [0x0ac00, 0x0d7af, 2], #   Hangul Syllables                        Range: AC00–D7AF
#[0x0d7b0, 0x0d7ff, 1], #   Hangul Jamo Extended-B                  Range: D7B0–D7FF
#[0x0d800, 0x0dbff, 0], #*) High Surrogate Area                     Range: D800-DBFF    non_print
#[0x0dc00, 0x0dfff, 0], #*) Low Surrogate Area                      Range: DC00-DFFF    non_print
                        #   Private Use Area                        Range: E000-F8FF    private

 [0x0e000, 0x0faff, 2],
                        #   CJK Compatibility Ideographs            Range: F900–FAFF
 [0x0fb1e, 0x0fb1e, 0], #   Alphabetic Presentation Forms           Range: FB00–FB4F
                        #   Arabic Presentation Forms-A             Range: FB50–FDFF
 [0x0fe00, 0x0fe0f, 0], #   Variation Selectors                     Range: FE00–FE0F
 [0x0fe10, 0x0fe1f, 2], #   Vertical Forms                          Range: FE10–FE1F
 [0x0fe20, 0x0fe2f, 0], #   Combining Half Marks                    Range: FE20–FE2F
 [0x0fe30, 0x0fe6f, 2], #   CJK Compatibility Forms                 Range: FE30–FE4F
                        #   Small Form Variants                     Range: FE50–FE6F
#[0x0feff, 0x0feff, 0], #*) Arabic Presentation Forms-B             Range: FE70–FEFF
 [0x0ff00, 0x0ff60, 2], #   Halfwidth and Fullwidth Forms           Range: FF00–FFEF
 [0x0ffe0, 0x0ffe6, 2],
#[0x0fff0, 0x0fffb, 0], #*) Specials                                Range: FFF0–FFFF    not_assigned
 [0x0fffd, 0x0fffd, 2],
#[0x0fffe, 0x0ffff, 0], #*)
                        #   Linear B Syllabary                      Range: 10000–1007F
                        #   Linear B Ideograms                      Range: 10080–100FF
                        #   Aegean Numbers                          Range: 10100–1013F
                        #   Ancient Greek Numbers                   Range: 10140–1018F
                        #   Ancient Symbols                         Range: 10190–101CF
 [0x101fd, 0x101fd, 0], #   Phaistos Disc                           Range: 101D0–101FF
                        #                                           Range: 10200-1027F  not_assigned
                        #   Lycian                                  Range: 10280–1029F
                        #   Carian                                  Range: 102A0–102DF
 [0x102e0, 0x102e0, 0], #   Coptic Epact Numbers                    Range: 102E0–102FF
                        #   Old Italic                              Range: 10300–1032F
                        #   Gothic                                  Range: 10330–1034F
 [0x10376, 0x1037a, 0], #   Old Permic                              Range: 10350–1037F
                        #   Ugaritic                                Range: 10380–1039F
                        #   Old Persian                             Range: 103A0–103DF
                        #                                           Range: 103E0-103FF  not_assigned
                        #   Deseret                                 Range: 10400–1044F
                        #   Shavian                                 Range: 10450–1047F
                        #   Osmanya                                 Range: 10480–104AF
                        #   Osage                                   Range: 104B0–104FF
                        #   Elbasan                                 Range: 10500–1052F
                        #   Caucasian Albanian                      Range: 10530–1056F
                        #                                           Range: 10570-105FF  not_assigned
                        #   Linear A                                Range: 10600–1077F
                        #                                           Range: 10780-107FF  not_assigned
                        #   Cypriot Syllabary                       Range: 10800–1083F
                        #   Imperial Aramaic                        Range: 10840–1085F
                        #   Palmyrene                               Range: 10860–1087F
                        #   Nabataean                               Range: 10880–108AF
                        #                                           Range: 108B0-108DF  not_assigned
                        #   Hatran                                  Range: 108E0–108FF
                        #   Phoenician                              Range: 10900–1091F
                        #   Lydian                                  Range: 10920–1093F
                        #                                           Range: 10940-1097F  not_assigned
                        #   Meroitic Hieroglyphs                    Range: 10980–1099F
                        #   Meroitic Cursive                        Range: 109A0–109FF
 [0x10a01, 0x10a0f, 0], #   Kharoshthi                              Range: 10A00–10A5F
 [0x10a38, 0x10a3f, 0],
                        #   Old South Arabian                       Range: 10A60–10A7F
                        #   Old North Arabian                       Range: 10A80–10A9F
                        #                                           Range: 10AA0-10ABF  not_assigned
 [0x10ae5, 0x10ae6, 0], #   Manichaean                              Range: 10AC0–10AFF
                        #   Avestan                                 Range: 10B00–10B3F
                        #   Inscriptional Parthian                  Range: 10B40–10B5F
                        #   Inscriptional Pahlavi                   Range: 10B60–10B7F
                        #   Psalter Pahlavi                         Range: 10B80–10BAF
                        #                                           Range: 10BB0-10BFF  not_assigned
                        #   Old Turkic                              Range: 10C00–10C4F
                        #                                           Range: 10C50-10C7F  not_assigned
                        #   Old Hungarian                           Range: 10C80–10CFF
                        #   Hanifi Rohingya                         Range: 10D00–10D3F
                        #                                           Range: 10D40-10E5F  not_assigned
                        #   Rumi Numeral Symbols                    Range: 10E60–10E7F
                        #                                           Range: 10E80-10FFF  not_assigned
 [0x11001, 0x11001, 0], #   Brahmi                                  Range: 11000–1107F
 [0x11038, 0x11046, 0],
 [0x1107f, 0x11081, 0],
 [0x110b3, 0x110b6, 0], #   Kaithi                                  Range: 11080–110CF
 [0x110b9, 0x110ba, 0],
#[0x110bd, 0x110bd, 0], #*)
#[0x110cd, 0x110cd, 0], #*)
                        #   Sora Sompeng                            Range: 110D0–110FF
 [0x11100, 0x11102, 0], #   Chakma                                  Range: 11100–1114F
 [0x11127, 0x1112b, 0],
 [0x1112d, 0x11134, 0],
 [0x11173, 0x11173, 0], #   Mahajani                                Range: 11150–1117F
 [0x11180, 0x11181, 0], #   Sharada                                 Range: 11180–111DF
 [0x111b6, 0x111be, 0],
 [0x111ca, 0x111cc, 0],
                        #   Sinhala Archaic Numbers                 Range: 111E0–111FF
 [0x1122f, 0x11231, 0], #   Khojki                                  Range: 11200–1124F
 [0x11234, 0x11234, 0],
 [0x11236, 0x11237, 0],
 [0x1123e, 0x1123e, 0],
                        #                                           Range: 11250-1127F  not_assigned
                        #   Multani                                 Range: 11280–112AF
 [0x112df, 0x112df, 0], #   Khudawadi                               Range: 112B0–112FF
 [0x112e3, 0x112ea, 0],
 [0x11300, 0x11301, 0], #   Grantha                                 Range: 11300–1137F
 [0x1133c, 0x1133c, 0],
 [0x11340, 0x11340, 0],
 [0x11366, 0x1136c, 0],
 [0x11370, 0x11374, 0],
                        #                                           Range: 11380-113FF  not_assigned
 [0x11438, 0x1143f, 0], #   Newa                                    Range: 11400–1147F
 [0x11442, 0x11444, 0],
 [0x11446, 0x11446, 0],
 [0x114b3, 0x114b8, 0], #   Tirhuta                                 Range: 11480–114DF
 [0x114ba, 0x114ba, 0],
 [0x114bf, 0x114c0, 0],
 [0x114c2, 0x114c3, 0],
                        #                                           Range: 114E0-1157F  not_assigned
 [0x115b2, 0x115b5, 0], #   Siddham                                 Range: 11580–115FF
 [0x115bc, 0x115bd, 0],
 [0x115bf, 0x115c0, 0],
 [0x115dc, 0x115dd, 0],
 [0x11633, 0x1163a, 0], #   Modi                                    Range: 11600–1165F
 [0x1163d, 0x1163d, 0],
 [0x1163f, 0x11640, 0],
                        #   Mongolian Supplement                    Range: 11660–1167F
 [0x116ab, 0x116ab, 0], #   Takri                                   Range: 11680–116CF
 [0x116ad, 0x116ad, 0],
 [0x116b0, 0x116b5, 0],
 [0x116b7, 0x116b7, 0],
                        #                                           Range: 116D0-116FF  not_assigned
 [0x1171d, 0x1171f, 0], #   Ahom                                    Range: 11700–1173F
 [0x11722, 0x11725, 0],
 [0x11727, 0x1172b, 0],
                        #                                           Range: 11740-1189F  not_assigned
                        #   Warang Citi                             Range: 118A0–118FF
                        #                                           Range: 11900-119FF  not_assigned
 [0x11a01, 0x11a06, 0], #   Zanabazar Square                        Range: 11A00–11A4F
 [0x11a09, 0x11a0a, 0],
 [0x11a33, 0x11a38, 0],
 [0x11a3b, 0x11a3e, 0],
 [0x11a47, 0x11a47, 0],
 [0x11a51, 0x11a56, 0], #   Soyombo                                 Range: 11A50–11AAF
 [0x11a59, 0x11a5b, 0],
 [0x11a8a, 0x11a96, 0],
 [0x11a98, 0x11a99, 0],
                        #                                           Range: 11AB0-11ABF  not_assigned
                        #   Pau Cin Hau                             Range: 11AC0–11AFF
                        #                                           Range: 11B00-11BFF  not_assigned
 [0x11c30, 0x11c36, 0], #   Bhaiksuki                               Range: 11C00–11C6F
 [0x11c38, 0x11c3d, 0],
 [0x11c3f, 0x11c3f, 0], #
 [0x11c92, 0x11ca7, 0], #   Marchen                                 Range: 11C70–11CBF
 [0x11caa, 0x11cb0, 0],
 [0x11cb2, 0x11cb3, 0],
 [0x11cb5, 0x11cb6, 0],
                        #                                           Range: 11CC0-11CFF  not_assigned
 [0x11d31, 0x11d45, 0], #   Masaram Gondi                           Range: 11D00–11D5F
 [0x11d47, 0x11d47, 0],
                        #                                           Range: 11D60-11FFF  not_assigned
                        #   Cuneiform                               Range: 12000–123FF
                        #   Cuneiform Numbers and Punctuation       Range: 12400–1247F
                        #   Early Dynastic Cuneiform                Range: 12480–1254F
                        #                                           Range: 12550-12FFF  not_assigned
                        #   Egyptian Hieroglyphs                    Range: 13000–1342F
                        #                                           Range: 13430-143FF  not_assigned
                        #   Anatolian Hieroglyphs                   Range: 14400–1467F
                        #                                           Range: 14680-167FF  not_assigned
                        #   Bamum Supplement                        Range: 16800–16A3F
                        #   Mro                                     Range: 16A40–16A6F
                        #                                           Range: 16A70-16ACF  not_assigned
 [0x16af0, 0x16af4, 0], #   Bassa Vah                               Range: 16AD0–16AFF
 [0x16b30, 0x16b36, 0], #   Pahawh Hmong                            Range: 16B00–16B8F
                        #                                           Range: 16B90-16EFF  not_assigned
 [0x16f8f, 0x16f92, 0], #   Miao                                    Range: 16F00–16F9F
                        #                                           Range: 16FA0-16FDF  not_assigned
 [0x16fe0, 0x16fe1, 2], #   Ideographic Symbols and Punctuatio      Range: 16FE0–16FFF
 [0x17000, 0x187ef, 2], #   Tangut                                  Range: 17000–187F1
                        #                                           Range: 187F2-187FF  not_assigned
 [0x18800, 0x18af2, 2], #   Tangut Components                       Range: 18800–18AFF
                        #                                           Range: 18B00-1AFFF  not_assigned
 [0x1b000, 0x1b11e, 2], #   Kana Supplement                         Range: 1B000–1B0FF
                        #   Kana Extended-A                         Range: 1B100–1B12F
                        #                                           Range: 1B130-1B16F  not_assigned
 [0x1b170, 0x1b2fb, 2], #   Nushu                                   Range: 1B170–1B2FF
                        #                                           Range: 1B300-1BBFF  not_assigned
 [0x1bc9d, 0x1bc9e, 0], #   Duployan                                Range: 1BC00–1BC9F
#[0x1bca0, 0x1bcaf, 0], #*) Shorthand Format Controls               Range: 1BCA0–1BCAF
                        #                                           Range: 1BCB0-1CFFF  not_assigned
                        #   Byzantine Musical Symbols               Range: 1D000–1D0FF
 [0x1d167, 0x1d169, 0], #   Musical Symbols                         Range: 1D100–1D1FF
 [0x1d17b, 0x1d182, 0],
 [0x1d185, 0x1d18b, 0],
 [0x1d1aa, 0x1d1ad, 0],
 [0x1d242, 0x1d244, 0], #   Ancient Greek Musical Notation          Range: 1D200–1D24F
                        #                                           Range: 1D250-1D2FF  not_assigned
                        #   Tai Xuan Jing Symbols                   Range: 1D300–1D35F
                        #   Counting Rod Numerals                   Range: 1D360–1D37F
                        #                                           Range: 1D380-1D3FF  not_assigned
                        #   Mathematical Alphanumeric Symbols       Range: 1D400–1D7FF
 [0x1da00, 0x1da36, 0], #   Sutton SignWriting                      Range: 1D800–1DAAF
 [0x1da3b, 0x1da6c, 0],
 [0x1da75, 0x1da75, 0],
 [0x1da84, 0x1da84, 0],
 [0x1da9b, 0x1daaf, 0],
                        #                                           Range: 1DAB0-1DFFF  not_assigned
 [0x1e000, 0x1e02f, 0], #   Glagolitic Supplement                   Range: 1E000–1E02F
                        #                                           Range: 1E030-1E7FF  not_assigned
 [0x1e8d0, 0x1e8d6, 0], #   Mende Kikakui                           Range: 1E800–1E8DF
                        #                                           Range: 1E8E0-1E8FF  not_assigned
 [0x1e944, 0x1e94a, 0], #   Adlam                                   Range: 1E900–1E95F
                        #                                           Range: 1E960-1EDFF  not_assigned
                        #   Arabic Mathematical Alphabetic Symbols  Range: 1EE00–1EEFF
                        #                                           Range: 1EF00-1EFFF  not_assigned
 [0x1f004, 0x1f004, 2], #   Mahjong Tiles                           Range: 1F000–1F02F
                        #   Domino Tiles                            Range: 1F030–1F09F
 [0x1f0cf, 0x1f0cf, 2], #   Playing Cards                           Range: 1F0A0–1F0FF

 [0x1f100, 0x1f10a, 2], #   Enclosed Alphanumeric Supplement        Range: 1F100–1F1FF
 [0x1f110, 0x1f12d, 2],
 [0x1f130, 0x1f169, 2],
 [0x1f170, 0x1f1ac, 2],
 [0x1f200, 0x1f320, 2], #   Enclosed Ideographic Supplemet          Range: 1F200–1F2FF
                        #   Miscellaneous Symbols and Pictograph    Range: 1F300–1F5FF
 [0x1f32d, 0x1f335, 2],
 [0x1f337, 0x1f37c, 2],
 [0x1f37e, 0x1f393, 2],
 [0x1f3a0, 0x1f3ca, 2],
 [0x1f3cf, 0x1f3d3, 2],
 [0x1f3e0, 0x1f3f0, 2],
 [0x1f3f4, 0x1f3f4, 2],
 [0x1f3f8, 0x1f43e, 2],
 [0x1f440, 0x1f440, 2],
 [0x1f442, 0x1f4fc, 2],
 [0x1f4ff, 0x1f53d, 2],
 [0x1f54b, 0x1f54e, 2],
 [0x1f550, 0x1f567, 2],
 [0x1f57a, 0x1f57a, 2],
 [0x1f595, 0x1f596, 2],
 [0x1f5a4, 0x1f5a4, 2],
 [0x1f5fb, 0x1f64f, 2],
                        #   Emoticons                               Range: 1F600–1F64F
                        #   Ornamental Dingbats                     Range: 1F650–1F67F
 [0x1f680, 0x1f6c5, 2], #   Transport and Map Symbol                Range: 1F680–1F6FF
 [0x1f6cc, 0x1f6cc, 2],
 [0x1f6d0, 0x1f6d2, 2],
 [0x1f6eb, 0x1f6ec, 2],
 [0x1f6f4, 0x1f6f8, 2],
                        #   Alchemical Symbol                       Range: 1F700–1F77F
                        #   Geometric Shapes Extende                Range: 1F780–1F7FF
                        #   Supplemental Arrows-C                   Range: 1F800–1F8FF
 [0x1f910, 0x1f96b, 2], #   Supplemental Symbols and Pictograph     Range: 1F900–1F9FF
 [0x1f980, 0x1f997, 2],
 [0x1f9c0, 0x1f9c0, 2],
 [0x1f9d0, 0x1f9e6, 2],
                        #   Chess Symbols                           Range: 1FA00–1FA6F  not_assigned
                        #                                           Range: 1FA70-1FFFF  not_assigned
 [0x20000, 0x2a6d6, 2], #   CJK Unified Ideographs Extension B      Range: 20000–2A6D6
                        #                                           Range: 2A6D7-2A6FF  not_assigned
 [0x2a700, 0x2b734, 2], #   CJK Unified Ideographs Extension C      Range: 2A700–2B734
                        #                                           Range: 2B735-2B73F  not_assigned
 [0x2b740, 0x2b81d, 2], #   CJK Unified Ideographs Extension D      Range: 2B740–2B81D
                        #                                           Range: 2B81E-2B81F  not_assigned
 [0x2b820, 0x2cea1, 2], #   CJK Unified Ideographs Extension E      Range: 2B820–2CEA1
                        #                                           Range: 2CEA2-2CEAF  not_assigned
 [0x2ceb0, 0x2ebe0, 2], #   CJK Unified Ideographs Extension F      Range: 2CEB0–2EBE0
                        #                                           Range: 2EBE1-2F7FF  not_assigned
 [0x2f800, 0x2fa1f, 2], #   CJK Compatibility Ideographs Supplement Range: 2F800–2FA1F
                        #                                           Range: 2FA20-2FFFF  not_assigned
#[0x30000, 0x3fffd, 2], #*) not_assigned                            Range: 30000-3FFFD  not_assigned
                        #                                           Range: 3FFFE-DFFFF  not_assigned
#[0xe0001, 0xe0001, 0], #*)  Tags                                   Range: E0000–E007F
#[0xe0020, 0xe007f, 0], #*)
                        #                                           Range: E0080-E00FF
 [0xe0100, 0xe01ef, 0], #   Variation Selectors Supplement          Range: E0100–E01EF
                        #                                           Range: E01F0–EFF7F  not_assigned
                        #                                           Range: EFF80–EFFFF  not_assigned
#[0xf0000, 0xffffd, 2], #*)   Supplementary Private Use Area-A      Range: F0000-FFFFF
#[0x100000, 0x10fffd, 2], #*) Supplementary Private Use Area-B      Range: 100000-10FFFD
];
}


1;
