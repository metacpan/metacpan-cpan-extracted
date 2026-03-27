#ifndef SLUG_UNICODE_H
#define SLUG_UNICODE_H

/*
 * slug_unicode.h — Unicode to ASCII transliteration tables
 *
 * Pure C, no Perl dependencies.
 * Two-tier lookup: block index (cp >> 8) -> block table -> replacement string.
 * Returns NULL for "drop this codepoint", pointer to "" for "keep as-is".
 */

#include <stdint.h>
#include <stddef.h>

/* ── Latin-1 Supplement U+00C0..U+00FF ────────────────────────── */
static const char *slug_block_00[256] = {
    /* 0x00-0xBF: NULL (ASCII handled separately, control chars dropped) */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 00-07 */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 08-0F */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 10-17 */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 18-1F */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 20-27 */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 28-2F */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 30-37 */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 38-3F */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 40-47 */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 48-4F */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 50-57 */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 58-5F */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 60-67 */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 68-6F */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 70-77 */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 78-7F */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 80-87 */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 88-8F */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 90-97 */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 98-9F */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* A0-A7 */
    NULL, "c",  NULL, NULL, NULL, NULL, "r",  NULL,  /* A8-AF: A9=©→c, AE=®→r */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* B0-B7 */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* B8-BF */
    /* 0xC0-0xFF: Latin-1 Supplement letters */
    "A",  "A",  "A",  "A",  "Ae", "A",  "AE", "C",  /* C0: À Á Â Ã Ä Å Æ Ç */
    "E",  "E",  "E",  "E",  "I",  "I",  "I",  "I",  /* C8: È É Ê Ë Ì Í Î Ï */
    "D",  "N",  "O",  "O",  "O",  "O",  "Oe", NULL, /* D0: Ð Ñ Ò Ó Ô Õ Ö × */
    "O",  "U",  "U",  "U",  "Ue", "Y",  "Th", "ss", /* D8: Ø Ù Ú Û Ü Ý Þ ß */
    "a",  "a",  "a",  "a",  "ae", "a",  "ae", "c",  /* E0: à á â ã ä å æ ç */
    "e",  "e",  "e",  "e",  "i",  "i",  "i",  "i",  /* E8: è é ê ë ì í î ï */
    "d",  "n",  "o",  "o",  "o",  "o",  "oe", NULL, /* F0: ð ñ ò ó ô õ ö ÷ */
    "o",  "u",  "u",  "u",  "ue", "y",  "th", "y",  /* F8: ø ù ú û ü ý þ ÿ */
};

/* ── Latin Extended-A U+0100..U+017F ──────────────────────────── */
static const char *slug_block_01[256] = {
    "A",  "a",  "A",  "a",  "A",  "a",  "C",  "c",  /* 00: Ā ā Ă ă Ą ą Ć ć */
    "C",  "c",  "C",  "c",  "C",  "c",  "D",  "d",  /* 08: Ĉ ĉ Ċ ċ Č č Ď ď */
    "D",  "d",  "E",  "e",  "E",  "e",  "E",  "e",  /* 10: Đ đ Ē ē Ĕ ĕ Ė ė */
    "E",  "e",  "E",  "e",  "G",  "g",  "G",  "g",  /* 18: Ę ę Ě ě Ĝ ĝ Ğ ğ */
    "G",  "g",  "G",  "g",  "H",  "h",  "H",  "h",  /* 20: Ġ ġ Ģ ģ Ĥ ĥ Ħ ħ */
    "I",  "i",  "I",  "i",  "I",  "i",  "I",  "i",  /* 28: Ĩ ĩ Ī ī Ĭ ĭ Į į */
    "I",  "i",  "IJ", "ij", "J",  "j",  "K",  "k",  /* 30: İ ı Ĳ ĳ Ĵ ĵ Ķ ķ */
    "k",  "L",  "l",  "L",  "l",  "L",  "l",  "L",  /* 38: ĸ Ĺ ĺ Ļ ļ Ľ ľ Ŀ */
    "l",  "L",  "l",  "N",  "n",  "N",  "n",  "N",  /* 40: ŀ Ł ł Ń ń Ņ ņ Ň */
    "n",  "n",  "N",  "n",  "O",  "o",  "O",  "o",  /* 48: ň ŉ Ŋ ŋ Ō ō Ŏ ŏ */
    "O",  "o",  "OE", "oe", "R",  "r",  "R",  "r",  /* 50: Ő ő Œ œ Ŕ ŕ Ŗ ŗ */
    "R",  "r",  "S",  "s",  "S",  "s",  "S",  "s",  /* 58: Ř ř Ś ś Ŝ ŝ Ş ş */
    "S",  "s",  "T",  "t",  "T",  "t",  "T",  "t",  /* 60: Š š Ţ ţ Ť ť Ŧ ŧ */
    "U",  "u",  "U",  "u",  "U",  "u",  "U",  "u",  /* 68: Ũ ũ Ū ū Ŭ ŭ Ů ů */
    "U",  "u",  "U",  "u",  "W",  "w",  "Y",  "y",  /* 70: Ű ű Ų ų Ŵ ŵ Ŷ ŷ */
    "Y",  "Z",  "z",  "Z",  "z",  "Z",  "z",  "s",  /* 78: Ÿ Ź ź Ż ż Ž ž ſ */
    /* 0x80-0xFF: Latin Extended-B (common ones) */
    "b",  "B",  "B",  "b",  NULL, NULL, "O",  "C",  /* 80-87 */
    "c",  "D",  "D",  "D",  "d",  NULL, NULL, "E",  /* 88-8F */
    "F",  "f",  "G",  NULL, NULL, "hv", "I",  "I",  /* 90-97 */
    "K",  "k",  "l",  "l",  "W",  "N",  "n",  "O",  /* 98-9F */
    "O",  "o",  "OI", "oi", "P",  "p",  NULL, NULL,  /* A0-A7 */
    "R",  NULL, NULL, "t",  "T",  "t",  "T",  "U",  /* A8-AF */
    "u",  "U",  "V",  "Y",  "y",  "Z",  "z",  NULL, /* B0-B7 */
    NULL, NULL, NULL, NULL, "Z",  "z",  NULL, NULL,  /* B8-BF */
    NULL, NULL, NULL, NULL, "DZ", "Dz", "dz", NULL, /* C0-C7 */
    "LJ", "Lj", "lj", "NJ", "Nj", "nj", "A",  "a",  /* C8-CF */
    "I",  "i",  "O",  "o",  "U",  "u",  "U",  "u",  /* D0-D7 */
    "U",  "u",  "U",  "u",  "U",  "u",  NULL, "A",  /* D8-DF */
    "a",  "A",  "a",  "AE", "ae", "G",  "g",  "G",  /* E0-E7 */
    "g",  "K",  "k",  "O",  "o",  "O",  "o",  NULL, /* E8-EF */
    "j",  "DZ", "Dz", "dz", "G",  "g",  NULL, NULL, /* F0-F7 */
    "N",  "n",  "A",  "a",  "AE", "ae", "O",  "o",  /* F8-FF */
};

/* ── Latin Extended-B continued U+0200..U+024F ────────────────── */
static const char *slug_block_02[256] = {
    "A",  "a",  "A",  "a",  "E",  "e",  "E",  "e",  /* 00-07 */
    "I",  "i",  "I",  "i",  "O",  "o",  "O",  "o",  /* 08-0F */
    "R",  "r",  "R",  "r",  "U",  "u",  "U",  "u",  /* 10-17 */
    "S",  "s",  "T",  "t",  NULL, NULL, "H",  "h",  /* 18-1F */
    "N",  "d",  NULL, NULL, "Z",  "z",  "A",  "a",  /* 20-27 */
    "E",  "e",  "O",  "o",  "O",  "o",  "O",  "o",  /* 28-2F */
    "O",  "o",  "Y",  "y",  NULL, NULL, NULL, NULL,  /* 30-37 */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 38-3F */
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,  /* 40-47 */
    NULL, NULL, NULL, "b",  NULL, NULL, NULL, NULL,  /* 48-4F */
    /* 0x50-0xFF: sparse, mostly NULL */
    [0x50] = NULL, [0x51] = NULL, [0x52] = NULL, [0x53] = "e",
    [0x54] = NULL, [0x55] = NULL, [0x56] = NULL, [0x57] = NULL,
    [0x58] = NULL, [0x59] = NULL, [0x5A] = NULL, [0x5B] = NULL,
    [0x5C] = "t",  [0x5D] = NULL, [0x5E] = NULL, [0x5F] = NULL,
};

/* ── Greek U+0370..U+03FF ─────────────────────────────────────── */
static const char *slug_block_03[256] = {
    [0x86] = "A",  [0x88] = "E",  [0x89] = "I",  [0x8A] = "I",
    [0x8C] = "O",  [0x8E] = "Y",  [0x8F] = "O",
    [0x90] = "i",
    [0x91] = "A",  [0x92] = "B",  [0x93] = "G",  [0x94] = "D",
    [0x95] = "E",  [0x96] = "Z",  [0x97] = "I",  [0x98] = "Th",
    [0x99] = "I",  [0x9A] = "K",  [0x9B] = "L",  [0x9C] = "M",
    [0x9D] = "N",  [0x9E] = "X",  [0x9F] = "O",
    [0xA0] = "P",  [0xA1] = "R",
    [0xA3] = "S",  [0xA4] = "T",  [0xA5] = "Y",  [0xA6] = "F",
    [0xA7] = "Ch", [0xA8] = "Ps", [0xA9] = "O",
    [0xAA] = "I",  [0xAB] = "Y",
    [0xAC] = "a",  [0xAD] = "e",  [0xAE] = "i",  [0xAF] = "i",
    [0xB0] = "y",
    [0xB1] = "a",  [0xB2] = "b",  [0xB3] = "g",  [0xB4] = "d",
    [0xB5] = "e",  [0xB6] = "z",  [0xB7] = "i",  [0xB8] = "th",
    [0xB9] = "i",  [0xBA] = "k",  [0xBB] = "l",  [0xBC] = "m",
    [0xBD] = "n",  [0xBE] = "x",  [0xBF] = "o",
    [0xC0] = "p",  [0xC1] = "r",  [0xC2] = "s",  [0xC3] = "s",
    [0xC4] = "t",  [0xC5] = "y",  [0xC6] = "f",  [0xC7] = "ch",
    [0xC8] = "ps", [0xC9] = "o",
    [0xCA] = "i",  [0xCB] = "y",
    [0xCC] = "o",  [0xCD] = "y",  [0xCE] = "o",
};

/* ── Cyrillic U+0400..U+04FF ──────────────────────────────────── */
static const char *slug_block_04[256] = {
    [0x00] = "Ie", [0x01] = "Io", [0x02] = "Dj", [0x03] = "Gj",
    [0x04] = "Ie", [0x05] = "Dz", [0x06] = "I",  [0x07] = "Yi",
    [0x08] = "J",  [0x09] = "Lj", [0x0A] = "Nj", [0x0B] = "Tsh",
    [0x0C] = "Kj", [0x0D] = "I",  [0x0E] = "U",  [0x0F] = "Dzh",
    [0x10] = "A",  [0x11] = "B",  [0x12] = "V",  [0x13] = "G",
    [0x14] = "D",  [0x15] = "E",  [0x16] = "Zh", [0x17] = "Z",
    [0x18] = "I",  [0x19] = "J",  [0x1A] = "K",  [0x1B] = "L",
    [0x1C] = "M",  [0x1D] = "N",  [0x1E] = "O",  [0x1F] = "P",
    [0x20] = "R",  [0x21] = "S",  [0x22] = "T",  [0x23] = "U",
    [0x24] = "F",  [0x25] = "Kh", [0x26] = "Ts", [0x27] = "Ch",
    [0x28] = "Sh", [0x29] = "Shch", [0x2A] = "",  [0x2B] = "Y",
    [0x2C] = "",   [0x2D] = "E",  [0x2E] = "Yu", [0x2F] = "Ya",
    [0x30] = "a",  [0x31] = "b",  [0x32] = "v",  [0x33] = "g",
    [0x34] = "d",  [0x35] = "e",  [0x36] = "zh", [0x37] = "z",
    [0x38] = "i",  [0x39] = "j",  [0x3A] = "k",  [0x3B] = "l",
    [0x3C] = "m",  [0x3D] = "n",  [0x3E] = "o",  [0x3F] = "p",
    [0x40] = "r",  [0x41] = "s",  [0x42] = "t",  [0x43] = "u",
    [0x44] = "f",  [0x45] = "kh", [0x46] = "ts", [0x47] = "ch",
    [0x48] = "sh", [0x49] = "shch", [0x4A] = "",  [0x4B] = "y",
    [0x4C] = "",   [0x4D] = "e",  [0x4E] = "yu", [0x4F] = "ya",
    [0x50] = "ie", [0x51] = "io", [0x52] = "dj", [0x53] = "gj",
    [0x54] = "ie", [0x55] = "dz", [0x56] = "i",  [0x57] = "yi",
    [0x58] = "j",  [0x59] = "lj", [0x5A] = "nj", [0x5B] = "tsh",
    [0x5C] = "kj", [0x5D] = "i",  [0x5E] = "u",  [0x5F] = "dzh",
    [0x60] = "O",  [0x61] = "o",  [0x62] = "E",  [0x63] = "e",
    [0x64] = "Ie", [0x65] = "ie",
    [0x90] = "G",  [0x91] = "g",  [0x92] = "G",  [0x93] = "g",
    [0x94] = "G",  [0x95] = "g",  [0x96] = "Zh", [0x97] = "zh",
    [0x98] = "Z",  [0x99] = "z",  [0x9A] = "K",  [0x9B] = "k",
    [0x9C] = "K",  [0x9D] = "k",  [0x9E] = "K",  [0x9F] = "k",
    [0xA0] = "K",  [0xA1] = "k",  [0xA2] = "N",  [0xA3] = "n",
    [0xAE] = "H",  [0xAF] = "h",
    [0xB0] = "H",  [0xB1] = "h",
    [0xD0] = "A",  [0xD1] = "a",  [0xD2] = "AE", [0xD3] = "ae",
    [0xD4] = "Ie", [0xD5] = "ie",
    [0xE8] = "Ch", [0xE9] = "ch",
};

/* ── Vietnamese / Latin Extended Additional U+1E00..U+1EFF ────── */
static const char *slug_block_1e[256] = {
    "A",  "a",  "B",  "b",  "B",  "b",  "B",  "b",  /* 00-07 */
    "C",  "c",  "D",  "d",  "D",  "d",  "D",  "d",  /* 08-0F */
    "D",  "d",  "D",  "d",  "E",  "e",  "E",  "e",  /* 10-17 */
    "E",  "e",  "E",  "e",  "E",  "e",  "F",  "f",  /* 18-1F */
    "G",  "g",  "H",  "h",  "H",  "h",  "H",  "h",  /* 20-27 */
    "H",  "h",  "H",  "h",  "I",  "i",  "I",  "i",  /* 28-2F */
    "K",  "k",  "K",  "k",  "K",  "k",  "L",  "l",  /* 30-37 */
    "L",  "l",  "L",  "l",  "L",  "l",  "M",  "m",  /* 38-3F */
    "M",  "m",  "M",  "m",  "N",  "n",  "N",  "n",  /* 40-47 */
    "N",  "n",  "N",  "n",  "O",  "o",  "O",  "o",  /* 48-4F */
    "O",  "o",  "O",  "o",  "P",  "p",  "P",  "p",  /* 50-57 */
    "R",  "r",  "R",  "r",  "R",  "r",  "R",  "r",  /* 58-5F */
    "S",  "s",  "S",  "s",  "S",  "s",  "S",  "s",  /* 60-67 */
    "S",  "s",  "T",  "t",  "T",  "t",  "T",  "t",  /* 68-6F */
    "T",  "t",  "U",  "u",  "U",  "u",  "U",  "u",  /* 70-77 */
    "U",  "u",  "V",  "v",  "V",  "v",  "W",  "w",  /* 78-7F */
    "W",  "w",  "W",  "w",  "W",  "w",  "W",  "w",  /* 80-87 */
    "X",  "x",  "X",  "x",  "Y",  "y",  "Z",  "z",  /* 88-8F */
    "Z",  "z",  "Z",  "z",  "h",  "t",  "w",  "y",  /* 90-97 */
    "a",  "s",  NULL, NULL, NULL, NULL, NULL, NULL,  /* 98-9F */
    "A",  "a",  "A",  "a",  "A",  "a",  "A",  "a",  /* A0-A7 */
    "A",  "a",  "A",  "a",  "A",  "a",  "A",  "a",  /* A8-AF */
    "A",  "a",  "A",  "a",  "A",  "a",  "A",  "a",  /* B0-B7 */
    "E",  "e",  "E",  "e",  "E",  "e",  "E",  "e",  /* B8-BF */
    "E",  "e",  "E",  "e",  "E",  "e",  "E",  "e",  /* C0-C7 */
    "I",  "i",  "I",  "i",  "O",  "o",  "O",  "o",  /* C8-CF */
    "O",  "o",  "O",  "o",  "O",  "o",  "O",  "o",  /* D0-D7 */
    "O",  "o",  "O",  "o",  "O",  "o",  "O",  "o",  /* D8-DF */
    "O",  "o",  "O",  "o",  "U",  "u",  "U",  "u",  /* E0-E7 */
    "U",  "u",  "U",  "u",  "U",  "u",  "U",  "u",  /* E8-EF */
    "U",  "u",  "Y",  "y",  "Y",  "y",  "Y",  "y",  /* F0-F7 */
    "Y",  "y",  NULL, NULL, NULL, NULL, NULL, NULL,  /* F8-FF */
};

/* ── General Punctuation U+2000..U+206F (spaces, dashes) ──────── */
static const char *slug_block_20[256] = {
    [0x00] = " ", [0x01] = " ", [0x02] = " ", [0x03] = " ",
    [0x04] = " ", [0x05] = " ", [0x06] = " ", [0x07] = " ",
    [0x08] = " ", [0x09] = " ", [0x0A] = " ", [0x0B] = " ",
    [0x10] = "-", [0x11] = "-", [0x12] = "-", [0x13] = "-",
    [0x14] = "-", [0x15] = "-",
    [0x18] = "'", [0x19] = "'", [0x1A] = ",",
    [0x1C] = "\"", [0x1D] = "\"",
    [0x20] = "+", [0x21] = "++",
    [0x22] = ".", [0x26] = "...", [0x27] = ".",
    [0x32] = "'", [0x35] = "`",
    [0x39] = "<", [0x3A] = ">",
    [0x44] = "/",
    [0xAC] = "eur",
};

/* ── Currency Symbols U+20A0..U+20CF ── (handled inside block_20 above) */

/* ── Letterlike Symbols U+2100..U+214F ────────────────────────── */
static const char *slug_block_21[256] = {
    [0x00] = "a/c", [0x01] = "a/s", [0x03] = "C",
    [0x05] = "c/o", [0x06] = "c/u",
    [0x09] = "F",   [0x0A] = "g",
    [0x0B] = "H",   [0x0C] = "H",   [0x0D] = "H",
    [0x0E] = "h",   [0x10] = "I",   [0x11] = "I",
    [0x12] = "L",   [0x13] = "l",
    [0x15] = "N",   [0x16] = "No",
    [0x19] = "P",   [0x1A] = "Q",
    [0x1B] = "R",   [0x1C] = "R",   [0x1D] = "R",
    [0x22] = "TM",  [0x24] = "Z",
    [0x26] = "O",   [0x28] = "Z",
    [0x2A] = "K",   [0x2B] = "A",
    [0x2C] = "B",   [0x2D] = "C",   [0x2E] = "e",
    [0x30] = "E",   [0x31] = "F",
    [0x33] = "M",   [0x34] = "o",
};

/* ── Arrows etc U+2190..U+21FF ── (mostly NULL, arrows to text) */

/* ── Ligatures / Alphabetic Presentation Forms U+FB00..U+FB4F ─ */
static const char *slug_block_fb[256] = {
    [0x00] = "ff",  [0x01] = "fi",  [0x02] = "fl",
    [0x03] = "ffi", [0x04] = "ffl", [0x05] = "st", [0x06] = "st",
};

/* ── Fullwidth Latin U+FF00..U+FF5E ───────────────────────────── */
static const char *slug_block_ff[256] = {
    [0x01] = "!",  [0x02] = "\"", [0x03] = "#",  [0x04] = "$",
    [0x05] = "%",  [0x06] = "&",  [0x07] = "'",  [0x08] = "(",
    [0x09] = ")",  [0x0A] = "*",  [0x0B] = "+",  [0x0C] = ",",
    [0x0D] = "-",  [0x0E] = ".",  [0x0F] = "/",
    [0x10] = "0",  [0x11] = "1",  [0x12] = "2",  [0x13] = "3",
    [0x14] = "4",  [0x15] = "5",  [0x16] = "6",  [0x17] = "7",
    [0x18] = "8",  [0x19] = "9",  [0x1A] = ":",  [0x1B] = ";",
    [0x1C] = "<",  [0x1D] = "=",  [0x1E] = ">",  [0x1F] = "?",
    [0x20] = "@",
    [0x21] = "A",  [0x22] = "B",  [0x23] = "C",  [0x24] = "D",
    [0x25] = "E",  [0x26] = "F",  [0x27] = "G",  [0x28] = "H",
    [0x29] = "I",  [0x2A] = "J",  [0x2B] = "K",  [0x2C] = "L",
    [0x2D] = "M",  [0x2E] = "N",  [0x2F] = "O",  [0x30] = "P",
    [0x31] = "Q",  [0x32] = "R",  [0x33] = "S",  [0x34] = "T",
    [0x35] = "U",  [0x36] = "V",  [0x37] = "W",  [0x38] = "X",
    [0x39] = "Y",  [0x3A] = "Z",
    [0x3B] = "[",  [0x3C] = "\\", [0x3D] = "]",  [0x3E] = "^",
    [0x3F] = "_",  [0x40] = "`",
    [0x41] = "a",  [0x42] = "b",  [0x43] = "c",  [0x44] = "d",
    [0x45] = "e",  [0x46] = "f",  [0x47] = "g",  [0x48] = "h",
    [0x49] = "i",  [0x4A] = "j",  [0x4B] = "k",  [0x4C] = "l",
    [0x4D] = "m",  [0x4E] = "n",  [0x4F] = "o",  [0x50] = "p",
    [0x51] = "q",  [0x52] = "r",  [0x53] = "s",  [0x54] = "t",
    [0x55] = "u",  [0x56] = "v",  [0x57] = "w",  [0x58] = "x",
    [0x59] = "y",  [0x5A] = "z",
    [0x5B] = "{",  [0x5C] = "|",  [0x5D] = "}",  [0x5E] = "~",
};

/* ── Master block index ───────────────────────────────────────── */
/* Index: codepoint >> 8.  Only populated blocks are non-NULL. */

#define SLUG_BLOCK_COUNT 256

static const char **slug_unicode_blocks[SLUG_BLOCK_COUNT] = {
    [0x00] = slug_block_00,
    [0x01] = slug_block_01,
    [0x02] = slug_block_02,
    [0x03] = slug_block_03,
    [0x04] = slug_block_04,
    [0x1E] = slug_block_1e,
    [0x20] = slug_block_20,
    [0x21] = slug_block_21,
    [0xFB] = slug_block_fb,
    [0xFF] = slug_block_ff,
};

/* Look up the ASCII transliteration for a codepoint.
 * Returns:
 *   non-NULL string  → replacement text (may be multi-char, e.g. "ae")
 *   empty string ""  → codepoint has a mapping but maps to nothing (drop)
 *   NULL             → no mapping (caller decides: drop or keep) */
static inline const char *slug_transliterate(uint32_t cp) {
    unsigned int block_idx, offset;

    /* ASCII passthrough */
    if (cp < 0x80) return NULL;

    /* Beyond our table range */
    if (cp > 0xFFFF) return NULL;

    block_idx = (cp >> 8) & 0xFF;
    offset = cp & 0xFF;

    if (block_idx >= SLUG_BLOCK_COUNT) return NULL;
    if (slug_unicode_blocks[block_idx] == NULL) return NULL;

    return slug_unicode_blocks[block_idx][offset];
}

#endif /* SLUG_UNICODE_H */
