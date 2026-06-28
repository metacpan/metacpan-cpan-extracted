/*
 * pdfmake_encoding.c - PDF character encoding tables
 *
 * Standard encoding tables mapping character codes (0-255) to Unicode.
 * Used for text rendering when fonts use these encodings.
 *
 * Reference: PDF 32000-1:2008 Annex D
 */

#include "pdfmake_text.h"
#include "pdfmake_font.h"
#include <string.h>

/*
 * 0xFFFF indicates undefined character
 */
#define UNDEF 0xFFFF

/*============================================================================
 * Standard Encoding (Appendix D.1)
 *==========================================================================*/

const uint16_t pdfmake_encoding_standard[256] = {
    /* 0x00-0x0F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0x10-0x1F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0x20-0x2F */
    0x0020, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025, 0x0026, 0x2019,
    0x0028, 0x0029, 0x002A, 0x002B, 0x002C, 0x002D, 0x002E, 0x002F,
    /* 0x30-0x3F */
    0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037,
    0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
    /* 0x40-0x4F */
    0x0040, 0x0041, 0x0042, 0x0043, 0x0044, 0x0045, 0x0046, 0x0047,
    0x0048, 0x0049, 0x004A, 0x004B, 0x004C, 0x004D, 0x004E, 0x004F,
    /* 0x50-0x5F */
    0x0050, 0x0051, 0x0052, 0x0053, 0x0054, 0x0055, 0x0056, 0x0057,
    0x0058, 0x0059, 0x005A, 0x005B, 0x005C, 0x005D, 0x005E, 0x005F,
    /* 0x60-0x6F */
    0x2018, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067,
    0x0068, 0x0069, 0x006A, 0x006B, 0x006C, 0x006D, 0x006E, 0x006F,
    /* 0x70-0x7F */
    0x0070, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077,
    0x0078, 0x0079, 0x007A, 0x007B, 0x007C, 0x007D, 0x007E, UNDEF,
    /* 0x80-0x8F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0x90-0x9F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0xA0-0xAF */
    UNDEF, 0x00A1, 0x00A2, 0x00A3, 0x2044, 0x00A5, 0x0192, 0x00A7,
    0x00A4, 0x0027, 0x201C, 0x00AB, 0x2039, 0x203A, 0xFB01, 0xFB02,
    /* 0xB0-0xBF */
    UNDEF, 0x2013, 0x2020, 0x2021, 0x00B7, UNDEF, 0x00B6, 0x2022,
    0x201A, 0x201E, 0x201D, 0x00BB, 0x2026, 0x2030, UNDEF, 0x00BF,
    /* 0xC0-0xCF */
    UNDEF, 0x0060, 0x00B4, 0x02C6, 0x02DC, 0x00AF, 0x02D8, 0x02D9,
    0x00A8, UNDEF, 0x02DA, 0x00B8, UNDEF, 0x02DD, 0x02DB, 0x02C7,
    /* 0xD0-0xDF */
    0x2014, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0xE0-0xEF */
    UNDEF, 0x00C6, UNDEF, 0x00AA, UNDEF, UNDEF, UNDEF, UNDEF,
    0x0141, 0x00D8, 0x0152, 0x00BA, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0xF0-0xFF */
    UNDEF, 0x00E6, UNDEF, UNDEF, UNDEF, 0x0131, UNDEF, UNDEF,
    0x0142, 0x00F8, 0x0153, 0x00DF, UNDEF, UNDEF, UNDEF, UNDEF,
};

/*============================================================================
 * WinAnsi Encoding (Appendix D.2)
 *==========================================================================*/

const uint16_t pdfmake_encoding_winansi[256] = {
    /* 0x00-0x0F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0x10-0x1F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0x20-0x2F */
    0x0020, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025, 0x0026, 0x0027,
    0x0028, 0x0029, 0x002A, 0x002B, 0x002C, 0x002D, 0x002E, 0x002F,
    /* 0x30-0x3F */
    0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037,
    0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
    /* 0x40-0x4F */
    0x0040, 0x0041, 0x0042, 0x0043, 0x0044, 0x0045, 0x0046, 0x0047,
    0x0048, 0x0049, 0x004A, 0x004B, 0x004C, 0x004D, 0x004E, 0x004F,
    /* 0x50-0x5F */
    0x0050, 0x0051, 0x0052, 0x0053, 0x0054, 0x0055, 0x0056, 0x0057,
    0x0058, 0x0059, 0x005A, 0x005B, 0x005C, 0x005D, 0x005E, 0x005F,
    /* 0x60-0x6F */
    0x0060, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067,
    0x0068, 0x0069, 0x006A, 0x006B, 0x006C, 0x006D, 0x006E, 0x006F,
    /* 0x70-0x7F */
    0x0070, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077,
    0x0078, 0x0079, 0x007A, 0x007B, 0x007C, 0x007D, 0x007E, 0x2022,
    /* 0x80-0x8F */
    0x20AC, 0x2022, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021,
    0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x2022, 0x017D, 0x2022,
    /* 0x90-0x9F */
    0x2022, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
    0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x2022, 0x017E, 0x0178,
    /* 0xA0-0xAF */
    0x00A0, 0x00A1, 0x00A2, 0x00A3, 0x00A4, 0x00A5, 0x00A6, 0x00A7,
    0x00A8, 0x00A9, 0x00AA, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x00AF,
    /* 0xB0-0xBF */
    0x00B0, 0x00B1, 0x00B2, 0x00B3, 0x00B4, 0x00B5, 0x00B6, 0x00B7,
    0x00B8, 0x00B9, 0x00BA, 0x00BB, 0x00BC, 0x00BD, 0x00BE, 0x00BF,
    /* 0xC0-0xCF */
    0x00C0, 0x00C1, 0x00C2, 0x00C3, 0x00C4, 0x00C5, 0x00C6, 0x00C7,
    0x00C8, 0x00C9, 0x00CA, 0x00CB, 0x00CC, 0x00CD, 0x00CE, 0x00CF,
    /* 0xD0-0xDF */
    0x00D0, 0x00D1, 0x00D2, 0x00D3, 0x00D4, 0x00D5, 0x00D6, 0x00D7,
    0x00D8, 0x00D9, 0x00DA, 0x00DB, 0x00DC, 0x00DD, 0x00DE, 0x00DF,
    /* 0xE0-0xEF */
    0x00E0, 0x00E1, 0x00E2, 0x00E3, 0x00E4, 0x00E5, 0x00E6, 0x00E7,
    0x00E8, 0x00E9, 0x00EA, 0x00EB, 0x00EC, 0x00ED, 0x00EE, 0x00EF,
    /* 0xF0-0xFF */
    0x00F0, 0x00F1, 0x00F2, 0x00F3, 0x00F4, 0x00F5, 0x00F6, 0x00F7,
    0x00F8, 0x00F9, 0x00FA, 0x00FB, 0x00FC, 0x00FD, 0x00FE, 0x00FF,
};

/*============================================================================
 * MacRoman Encoding (Appendix D.3)
 *==========================================================================*/

const uint16_t pdfmake_encoding_macroman[256] = {
    /* 0x00-0x0F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0x10-0x1F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0x20-0x2F */
    0x0020, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025, 0x0026, 0x0027,
    0x0028, 0x0029, 0x002A, 0x002B, 0x002C, 0x002D, 0x002E, 0x002F,
    /* 0x30-0x3F */
    0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037,
    0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
    /* 0x40-0x4F */
    0x0040, 0x0041, 0x0042, 0x0043, 0x0044, 0x0045, 0x0046, 0x0047,
    0x0048, 0x0049, 0x004A, 0x004B, 0x004C, 0x004D, 0x004E, 0x004F,
    /* 0x50-0x5F */
    0x0050, 0x0051, 0x0052, 0x0053, 0x0054, 0x0055, 0x0056, 0x0057,
    0x0058, 0x0059, 0x005A, 0x005B, 0x005C, 0x005D, 0x005E, 0x005F,
    /* 0x60-0x6F */
    0x0060, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067,
    0x0068, 0x0069, 0x006A, 0x006B, 0x006C, 0x006D, 0x006E, 0x006F,
    /* 0x70-0x7F */
    0x0070, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077,
    0x0078, 0x0079, 0x007A, 0x007B, 0x007C, 0x007D, 0x007E, UNDEF,
    /* 0x80-0x8F */
    0x00C4, 0x00C5, 0x00C7, 0x00C9, 0x00D1, 0x00D6, 0x00DC, 0x00E1,
    0x00E0, 0x00E2, 0x00E4, 0x00E3, 0x00E5, 0x00E7, 0x00E9, 0x00E8,
    /* 0x90-0x9F */
    0x00EA, 0x00EB, 0x00ED, 0x00EC, 0x00EE, 0x00EF, 0x00F1, 0x00F3,
    0x00F2, 0x00F4, 0x00F6, 0x00F5, 0x00FA, 0x00F9, 0x00FB, 0x00FC,
    /* 0xA0-0xAF */
    0x2020, 0x00B0, 0x00A2, 0x00A3, 0x00A7, 0x2022, 0x00B6, 0x00DF,
    0x00AE, 0x00A9, 0x2122, 0x00B4, 0x00A8, 0x2260, 0x00C6, 0x00D8,
    /* 0xB0-0xBF */
    0x221E, 0x00B1, 0x2264, 0x2265, 0x00A5, 0x00B5, 0x2202, 0x2211,
    0x220F, 0x03C0, 0x222B, 0x00AA, 0x00BA, 0x03A9, 0x00E6, 0x00F8,
    /* 0xC0-0xCF */
    0x00BF, 0x00A1, 0x00AC, 0x221A, 0x0192, 0x2248, 0x2206, 0x00AB,
    0x00BB, 0x2026, 0x00A0, 0x00C0, 0x00C3, 0x00D5, 0x0152, 0x0153,
    /* 0xD0-0xDF */
    0x2013, 0x2014, 0x201C, 0x201D, 0x2018, 0x2019, 0x00F7, 0x25CA,
    0x00FF, 0x0178, 0x2044, 0x20AC, 0x2039, 0x203A, 0xFB01, 0xFB02,
    /* 0xE0-0xEF */
    0x2021, 0x00B7, 0x201A, 0x201E, 0x2030, 0x00C2, 0x00CA, 0x00C1,
    0x00CB, 0x00C8, 0x00CD, 0x00CE, 0x00CF, 0x00CC, 0x00D3, 0x00D4,
    /* 0xF0-0xFF */
    0xF8FF, 0x00D2, 0x00DA, 0x00DB, 0x00D9, 0x0131, 0x02C6, 0x02DC,
    0x00AF, 0x02D8, 0x02D9, 0x02DA, 0x00B8, 0x02DD, 0x02DB, 0x02C7,
};

/*============================================================================
 * Symbol Encoding (Appendix D.5)
 *==========================================================================*/

const uint16_t pdfmake_encoding_symbol[256] = {
    /* 0x00-0x0F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0x10-0x1F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0x20-0x2F */
    0x0020, 0x0021, 0x2200, 0x0023, 0x2203, 0x0025, 0x0026, 0x220B,
    0x0028, 0x0029, 0x2217, 0x002B, 0x002C, 0x2212, 0x002E, 0x002F,
    /* 0x30-0x3F */
    0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037,
    0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
    /* 0x40-0x4F */
    0x2245, 0x0391, 0x0392, 0x03A7, 0x0394, 0x0395, 0x03A6, 0x0393,
    0x0397, 0x0399, 0x03D1, 0x039A, 0x039B, 0x039C, 0x039D, 0x039F,
    /* 0x50-0x5F */
    0x03A0, 0x0398, 0x03A1, 0x03A3, 0x03A4, 0x03A5, 0x03C2, 0x03A9,
    0x039E, 0x03A8, 0x0396, 0x005B, 0x2234, 0x005D, 0x22A5, 0x005F,
    /* 0x60-0x6F */
    0xF8E5, 0x03B1, 0x03B2, 0x03C7, 0x03B4, 0x03B5, 0x03C6, 0x03B3,
    0x03B7, 0x03B9, 0x03D5, 0x03BA, 0x03BB, 0x03BC, 0x03BD, 0x03BF,
    /* 0x70-0x7F */
    0x03C0, 0x03B8, 0x03C1, 0x03C3, 0x03C4, 0x03C5, 0x03D6, 0x03C9,
    0x03BE, 0x03C8, 0x03B6, 0x007B, 0x007C, 0x007D, 0x223C, UNDEF,
    /* 0x80-0x8F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0x90-0x9F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0xA0-0xAF */
    0x20AC, 0x03D2, 0x2032, 0x2264, 0x2044, 0x221E, 0x0192, 0x2663,
    0x2666, 0x2665, 0x2660, 0x2194, 0x2190, 0x2191, 0x2192, 0x2193,
    /* 0xB0-0xBF */
    0x00B0, 0x00B1, 0x2033, 0x2265, 0x00D7, 0x221D, 0x2202, 0x2022,
    0x00F7, 0x2260, 0x2261, 0x2248, 0x2026, 0xF8E6, 0xF8E7, 0x21B5,
    /* 0xC0-0xCF */
    0x2135, 0x2111, 0x211C, 0x2118, 0x2297, 0x2295, 0x2205, 0x2229,
    0x222A, 0x2283, 0x2287, 0x2284, 0x2282, 0x2286, 0x2208, 0x2209,
    /* 0xD0-0xDF */
    0x2220, 0x2207, 0xF6DA, 0xF6D9, 0xF6DB, 0x220F, 0x221A, 0x22C5,
    0x00AC, 0x2227, 0x2228, 0x21D4, 0x21D0, 0x21D1, 0x21D2, 0x21D3,
    /* 0xE0-0xEF */
    0x25CA, 0x2329, 0xF8E8, 0xF8E9, 0xF8EA, 0x2211, 0xF8EB, 0xF8EC,
    0xF8ED, 0xF8EE, 0xF8EF, 0xF8F0, 0xF8F1, 0xF8F2, 0xF8F3, 0xF8F4,
    /* 0xF0-0xFF */
    UNDEF, 0x232A, 0x222B, 0x2320, 0xF8F5, 0x2321, 0xF8F6, 0xF8F7,
    0xF8F8, 0xF8F9, 0xF8FA, 0xF8FB, 0xF8FC, 0xF8FD, 0xF8FE, UNDEF,
};

/*============================================================================
 * ZapfDingbats Encoding (Appendix D.6)
 *==========================================================================*/

const uint16_t pdfmake_encoding_zapfdingbats[256] = {
    /* 0x00-0x0F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0x10-0x1F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0x20-0x2F */
    0x0020, 0x2701, 0x2702, 0x2703, 0x2704, 0x260E, 0x2706, 0x2707,
    0x2708, 0x2709, 0x261B, 0x261E, 0x270C, 0x270D, 0x270E, 0x270F,
    /* 0x30-0x3F */
    0x2710, 0x2711, 0x2712, 0x2713, 0x2714, 0x2715, 0x2716, 0x2717,
    0x2718, 0x2719, 0x271A, 0x271B, 0x271C, 0x271D, 0x271E, 0x271F,
    /* 0x40-0x4F */
    0x2720, 0x2721, 0x2722, 0x2723, 0x2724, 0x2725, 0x2726, 0x2727,
    0x2605, 0x2729, 0x272A, 0x272B, 0x272C, 0x272D, 0x272E, 0x272F,
    /* 0x50-0x5F */
    0x2730, 0x2731, 0x2732, 0x2733, 0x2734, 0x2735, 0x2736, 0x2737,
    0x2738, 0x2739, 0x273A, 0x273B, 0x273C, 0x273D, 0x273E, 0x273F,
    /* 0x60-0x6F */
    0x2740, 0x2741, 0x2742, 0x2743, 0x2744, 0x2745, 0x2746, 0x2747,
    0x2748, 0x2749, 0x274A, 0x274B, 0x25CF, 0x274D, 0x25A0, 0x274F,
    /* 0x70-0x7F */
    0x2750, 0x2751, 0x2752, 0x25B2, 0x25BC, 0x25C6, 0x2756, 0x25D7,
    0x2758, 0x2759, 0x275A, 0x275B, 0x275C, 0x275D, 0x275E, UNDEF,
    /* 0x80-0x8F */
    0xF8D7, 0xF8D8, 0xF8D9, 0xF8DA, 0xF8DB, 0xF8DC, 0xF8DD, 0xF8DE,
    0xF8DF, 0xF8E0, 0xF8E1, 0xF8E2, 0xF8E3, 0xF8E4, UNDEF, UNDEF,
    /* 0x90-0x9F */
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF, UNDEF,
    /* 0xA0-0xAF */
    UNDEF, 0x2761, 0x2762, 0x2763, 0x2764, 0x2765, 0x2766, 0x2767,
    0x2663, 0x2666, 0x2665, 0x2660, 0x2460, 0x2461, 0x2462, 0x2463,
    /* 0xB0-0xBF */
    0x2464, 0x2465, 0x2466, 0x2467, 0x2468, 0x2469, 0x2776, 0x2777,
    0x2778, 0x2779, 0x277A, 0x277B, 0x277C, 0x277D, 0x277E, 0x277F,
    /* 0xC0-0xCF */
    0x2780, 0x2781, 0x2782, 0x2783, 0x2784, 0x2785, 0x2786, 0x2787,
    0x2788, 0x2789, 0x278A, 0x278B, 0x278C, 0x278D, 0x278E, 0x278F,
    /* 0xD0-0xDF */
    0x2790, 0x2791, 0x2792, 0x2793, 0x2794, 0x2192, 0x2194, 0x2195,
    0x2798, 0x2799, 0x279A, 0x279B, 0x279C, 0x279D, 0x279E, 0x279F,
    /* 0xE0-0xEF */
    0x27A0, 0x27A1, 0x27A2, 0x27A3, 0x27A4, 0x27A5, 0x27A6, 0x27A7,
    0x27A8, 0x27A9, 0x27AA, 0x27AB, 0x27AC, 0x27AD, 0x27AE, 0x27AF,
    /* 0xF0-0xFF */
    UNDEF, 0x27B1, 0x27B2, 0x27B3, 0x27B4, 0x27B5, 0x27B6, 0x27B7,
    0x27B8, 0x27B9, 0x27BA, 0x27BB, 0x27BC, 0x27BD, 0x27BE, UNDEF,
};

/*============================================================================
 * Encoding Lookup
 *==========================================================================*/

const uint16_t *pdfmake_encoding_get(const char *name)
{
    if (!name) return NULL;
    
    if (strcmp(name, "StandardEncoding") == 0 ||
        strcmp(name, "Standard") == 0) {
        return pdfmake_encoding_standard;
    }
    if (strcmp(name, "WinAnsiEncoding") == 0 ||
        strcmp(name, "WinAnsi") == 0) {
        return pdfmake_encoding_winansi;
    }
    if (strcmp(name, "MacRomanEncoding") == 0 ||
        strcmp(name, "MacRoman") == 0) {
        return pdfmake_encoding_macroman;
    }
    if (strcmp(name, "SymbolEncoding") == 0 ||
        strcmp(name, "Symbol") == 0) {
        return pdfmake_encoding_symbol;
    }
    if (strcmp(name, "ZapfDingbatsEncoding") == 0 ||
        strcmp(name, "ZapfDingbats") == 0) {
        return pdfmake_encoding_zapfdingbats;
    }
    
    return NULL;
}

/*============================================================================
 * Character to Glyph Mapping
 *==========================================================================*/

uint16_t pdfmake_text_char_to_glyph(pdfmake_font_t *font, uint32_t charcode)
{
    if (!font) return 0;
    
    /* TrueType: use cmap lookup */
    if (font->type == PDFMAKE_FONT_TRUETYPE || 
        font->type == PDFMAKE_FONT_CID_TRUETYPE) {
        if (font->ttf) {
            return pdfmake_ttf_cmap_lookup(font->ttf, charcode);
        }
        return 0;
    }
    
    /* Standard 14: char code is typically the glyph index for WinAnsi */
    if (font->type == PDFMAKE_FONT_TYPE1) {
        /* For Standard 14, char code is glyph ID in WinAnsi encoding */
        if (charcode < 256) {
            return (uint16_t)charcode;
        }
        return 0;
    }
    
    return 0;
}

uint16_t pdfmake_text_unicode_to_glyph(pdfmake_font_t *font, uint32_t unicode)
{
    int i;

    if (!font) return 0;
    
    /* TrueType: use cmap lookup (Unicode cmap) */
    if (font->type == PDFMAKE_FONT_TRUETYPE || 
        font->type == PDFMAKE_FONT_CID_TRUETYPE) {
        if (font->ttf) {
            return pdfmake_ttf_cmap_lookup(font->ttf, unicode);
        }
        return 0;
    }
    
    /* Standard 14: find Unicode in WinAnsi encoding */
    if (font->type == PDFMAKE_FONT_TYPE1) {
        /* Search WinAnsi for matching Unicode */
        for (i = 0; i < 256; i++) {
            if (pdfmake_encoding_winansi[i] == unicode) {
                return (uint16_t)i;
            }
        }
        /* Not found - return .notdef */
        return 0;
    }
    
    return 0;
}

/*============================================================================
 * UTF-8 Decoding Helper
 *==========================================================================*/

/*
 * Decode one UTF-8 character.
 * Returns Unicode codepoint and advances *p.
 * Returns 0xFFFD (replacement char) on error.
 */
static uint32_t utf8_decode(const uint8_t **p, const uint8_t *end)
{
    uint8_t c;
    uint8_t c2;
    uint8_t c3;
    uint8_t c4;

    if (*p >= end) return 0xFFFD;
    
    c = *(*p)++;
    
    if (c < 0x80) {
        return c;
    }
    
    if ((c & 0xE0) == 0xC0) {
        /* 2-byte sequence */
        if (*p >= end) return 0xFFFD;
        c2 = *(*p)++;
        if ((c2 & 0xC0) != 0x80) return 0xFFFD;
        return ((c & 0x1F) << 6) | (c2 & 0x3F);
    }
    
    if ((c & 0xF0) == 0xE0) {
        /* 3-byte sequence */
        if (*p + 1 >= end) return 0xFFFD;
        c2 = *(*p)++;
        c3 = *(*p)++;
        if ((c2 & 0xC0) != 0x80 || (c3 & 0xC0) != 0x80) return 0xFFFD;
        return ((c & 0x0F) << 12) | ((c2 & 0x3F) << 6) | (c3 & 0x3F);
    }
    
    if ((c & 0xF8) == 0xF0) {
        /* 4-byte sequence */
        if (*p + 2 >= end) return 0xFFFD;
        c2 = *(*p)++;
        c3 = *(*p)++;
        c4 = *(*p)++;
        if ((c2 & 0xC0) != 0x80 || (c3 & 0xC0) != 0x80 || 
            (c4 & 0xC0) != 0x80) return 0xFFFD;
        return ((c & 0x07) << 18) | ((c2 & 0x3F) << 12) | 
               ((c3 & 0x3F) << 6) | (c4 & 0x3F);
    }
    
    return 0xFFFD;
}

/*============================================================================
 * Glyph Width Functions
 *==========================================================================*/

double pdfmake_text_glyph_advance(
    pdfmake_font_t *font,
    uint16_t glyph_id,
    double font_size)
{
    int units_per_em = 1000; /* Default */
    int advance_width = 0;

    if (!font) return 0.0;
    
    if (font->type == PDFMAKE_FONT_TRUETYPE || 
        font->type == PDFMAKE_FONT_CID_TRUETYPE) {
        if (font->ttf) {
            units_per_em = font->ttf->units_per_em;
            advance_width = pdfmake_ttf_glyph_advance(font->ttf, glyph_id);
        }
    } else if (font->type == PDFMAKE_FONT_TYPE1) {
        /* Standard 14: widths are already in 1/1000 em */
        advance_width = pdfmake_std14_width(font->std14_id, glyph_id);
        units_per_em = 1000;
    }
    
    return (advance_width * font_size) / units_per_em;
}

double pdfmake_text_string_width(
    pdfmake_text_state_t *ts,
    const uint8_t *text,
    size_t len)
{
    double width;
    const uint8_t *p;
    const uint8_t *end;
    uint32_t unicode;
    uint16_t glyph_id;
    double glyph_width;

    if (!ts || !text || !ts->font) return 0.0;
    
    width = 0.0;
    p = text;
    end = text + len;
    
    while (p < end) {
        unicode = utf8_decode(&p, end);
        if (unicode == 0xFFFD) continue;
        
        glyph_id = pdfmake_text_unicode_to_glyph(ts->font, unicode);
        glyph_width = pdfmake_text_glyph_advance(ts->font, glyph_id, 
                                                 ts->font_size);
        
        width += glyph_width;
        width += ts->char_spacing;
        
        /* Word spacing for ASCII space */
        if (unicode == 0x0020) {
            width += ts->word_spacing;
        }
    }
    
    /* Apply horizontal scaling */
    width *= ts->horiz_scale;
    
    return width;
}

/*============================================================================
 * Font encoding API (Phase 2)
 *
 * Resolves a font's /Encoding to a byte->Unicode map, applying /Differences
 * overlays via the Adobe Glyph List.
 *==========================================================================*/

#include "pdfmake_font_encoding.h"
#include "pdfmake_glyphlist.h"

/* Fill a 256-entry map from a base table (0xFFFF = undefined in the
 * existing tables; translate to 0 for the new API). */
static void fill_from_table(pdfmake_font_encoding_t *enc,
                             const uint16_t *src)
{
    int i;
    uint16_t v;
    for (i = 0; i < 256; i++) {
        v = src[i];
        enc->map[i] = (v == 0xFFFF) ? 0 : v;
    }
}

void pdfmake_font_encoding_init_standard(pdfmake_font_encoding_t *enc) {
    fill_from_table(enc, pdfmake_encoding_standard);
}
void pdfmake_font_encoding_init_winansi(pdfmake_font_encoding_t *enc) {
    fill_from_table(enc, pdfmake_encoding_winansi);
}
void pdfmake_font_encoding_init_macroman(pdfmake_font_encoding_t *enc) {
    fill_from_table(enc, pdfmake_encoding_macroman);
}
void pdfmake_font_encoding_init_macexpert(pdfmake_font_encoding_t *enc) {
    /* MacExpertEncoding has no full table here — approximate with Standard.
     * This is rare in modern PDFs. */
    fill_from_table(enc, pdfmake_encoding_standard);
}
void pdfmake_font_encoding_init_symbol(pdfmake_font_encoding_t *enc) {
    fill_from_table(enc, pdfmake_encoding_symbol);
}
void pdfmake_font_encoding_init_zapfdingbats(pdfmake_font_encoding_t *enc) {
    fill_from_table(enc, pdfmake_encoding_zapfdingbats);
}

int pdfmake_font_encoding_init_by_name(pdfmake_font_encoding_t *enc,
                                        const char *name)
{
    if (!enc) return 0;
    if (!name) {
        pdfmake_font_encoding_init_winansi(enc);
        return 0;
    }
    if (strcmp(name, "StandardEncoding") == 0) {
        pdfmake_font_encoding_init_standard(enc); return 1;
    }
    if (strcmp(name, "WinAnsiEncoding") == 0) {
        pdfmake_font_encoding_init_winansi(enc); return 1;
    }
    if (strcmp(name, "MacRomanEncoding") == 0) {
        pdfmake_font_encoding_init_macroman(enc); return 1;
    }
    if (strcmp(name, "MacExpertEncoding") == 0) {
        pdfmake_font_encoding_init_macexpert(enc); return 1;
    }
    if (strcmp(name, "SymbolEncoding") == 0) {
        pdfmake_font_encoding_init_symbol(enc); return 1;
    }
    if (strcmp(name, "ZapfDingbatsEncoding") == 0) {
        pdfmake_font_encoding_init_zapfdingbats(enc); return 1;
    }
    /* Unknown: fall back to WinAnsi */
    pdfmake_font_encoding_init_winansi(enc);
    return 0;
}

/* Apply a /Differences array to an existing base-filled encoding.
 *
 *   [ 32 /space /exclam /quotedbl  65 /A /B /C ]
 *
 * Each integer sets the "next code"; each name that follows assigns that
 * name to the current code and advances.
 */
static void apply_differences(pdfmake_arena_t *arena,
                               pdfmake_obj_t *diff_arr,
                               pdfmake_font_encoding_t *enc)
{
    size_t n;
    int code;
    size_t i;
    pdfmake_obj_t *item;
    const char *glyph;
    uint32_t cp;

    if (!diff_arr || diff_arr->kind != PDFMAKE_ARRAY) return;

    n = pdfmake_array_len(diff_arr);
    code = 0;
    for (i = 0; i < n; i++) {
        item = pdfmake_array_get(diff_arr, i);
        if (!item) continue;

        if (item->kind == PDFMAKE_INT) {
            code = (int)item->as.i;
            continue;
        }
        if (item->kind != PDFMAKE_NAME) continue;

        glyph = pdfmake_get_name_bytes(arena, item);
        if (!glyph) { code++; continue; }

        if (code >= 0 && code < 256) {
            cp = pdfmake_glyphname_to_unicode(glyph);
            /* If glyph name unknown, leave whatever was there from the base */
            if (cp) enc->map[code] = cp;
        }
        code++;
    }
}

int pdfmake_font_encoding_from_dict(
    pdfmake_arena_t       *arena,
    pdfmake_obj_t         *encoding_obj,
    pdfmake_font_encoding_t *out)
{
    const char *name;
    uint32_t be_key;
    pdfmake_obj_t *be;
    uint32_t diff_key;
    pdfmake_obj_t *diff;

    if (!out) return -1;

    /* Default to StandardEncoding per spec (Type1 default) */
    pdfmake_font_encoding_init_standard(out);

    if (!encoding_obj) return 0;

    if (encoding_obj->kind == PDFMAKE_NAME) {
        name = pdfmake_get_name_bytes(arena, encoding_obj);
        pdfmake_font_encoding_init_by_name(out, name);
        return 0;
    }

    if (encoding_obj->kind == PDFMAKE_DICT) {
        /* /BaseEncoding */
        be_key = pdfmake_arena_intern_name(arena, "BaseEncoding", 12);
        be = pdfmake_dict_get(encoding_obj, be_key);
        if (be && be->kind == PDFMAKE_NAME) {
            name = pdfmake_get_name_bytes(arena, be);
            pdfmake_font_encoding_init_by_name(out, name);
        }
        /* /Differences */
        diff_key = pdfmake_arena_intern_name(arena, "Differences", 11);
        diff = pdfmake_dict_get(encoding_obj, diff_key);
        if (diff) apply_differences(arena, diff, out);
        return 0;
    }

    /* Unknown shape: leave StandardEncoding */
    return -1;
}
