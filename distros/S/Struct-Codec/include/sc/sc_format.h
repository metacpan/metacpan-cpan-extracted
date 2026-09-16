#ifndef SC_FORMAT_H
#define SC_FORMAT_H

/* sc_format.h - what the bytes mean. Normative: the plan records what was
 * decided, this file records why.
 *
 * ---- one tag byte per value, and nothing cleverer ---------------------------
 *
 * The value being encoded is small, and every byte of framing is a byte the
 * decoder has to branch on. One tag with the common cases folded into it - a
 * small integer, a short string - means a hash of short strings costs one tag
 * per key and one per value and nothing else. A hash KEY takes no tag at all:
 * it is one varint of (length << 1 | utf8) and the bytes, which is most of the
 * difference between this and Storable on the values a cache holds.
 *
 * ---- the header --------------------------------------------------------------
 *
 * Three bytes: 'S', the format version as a DIGIT so a hex dump reads, and the
 * float encoding, which is always 8: every NV is written as an IEEE-754 double
 * in little-endian byte order whatever the machine. The decoder refuses a
 * version or a float encoding it does not know before it reads anything else.
 *
 * ---- the bytes are portable ------------------------------------------------------
 *
 * Nothing in the stream depends on the machine that wrote it. Integers are
 * LEB128 varints, strings are bytes with a flag, offsets are varints, and a
 * float is byte-swapped into little-endian on a big-endian host. So a stream
 * can be written to disk or sent to another machine and read there, with one
 * caveat of Storable's nfreeze left: a 32-bit perl refuses an integer wider
 * than 32 bits rather than truncating it.
 *
 * The other nfreeze caveat is not taken. A perl built -Duselongdouble or
 * -Dusequadmath has more mantissa than a double, and narrowing to the 8-byte
 * form would hand back a number that is not the one that went in. Those are the
 * perls where it matters most: Shared::Arena returns a structure to the same
 * process that stored it, so an NV that changed in transit is a bug and not a
 * documented trade. A value a double cannot hold exactly is written as its
 * DECIMAL DIGITS instead, under SC_T_NV_STR - see sc_codec.h for why decimal
 * and not the native bytes. A perl whose NV is a double never writes that tag,
 * so its streams are byte-for-byte what they always were.
 *
 * ---- TRACK ---------------------------------------------------------------------
 *
 * Bit 0x80 on any tag says the value is referenced again later, so the decoder
 * must remember where this tag was. The encoder does not know that when it
 * writes the tag - it finds out when the second reference turns up - so it
 * remembers the offset and ORs the bit in afterwards. That is why the encoder
 * keeps the whole stream in a buffer until it is finished.
 *
 * Only a value that CAN be referenced twice is ever tracked: one whose
 * refcount is above one. A plain tree carries no TRACK bits and the decoder's
 * offset table stays empty.
 *
 * ---- REFP and ALIAS are two different things -----------------------------------
 *
 * Two references to one hash are REF the first time and REFP the second: a new
 * reference to the same referent. Two array slots holding the SAME scalar are
 * an ALIAS: the same SV in two places, which perl allows and which a decoder
 * must reproduce with the same SV or a write through one slot stops showing
 * through the other. An ALIAS may only name a scalar, because an HV or an AV
 * in a slot that expects an SV corrupts the interpreter silently; the decoder
 * checks the kind and refuses.
 *
 * ---- the kinds that are not data ---------------------------------------------------
 *
 * A regexp is its pattern and its flag letters, and is compiled again on the
 * way out. A tied hash, array or scalar is the OBJECT behind the tie and nothing
 * else: the contents are whatever that object answers, as they were before. A
 * named sub, a glob and a format are their fully-qualified NAME, looked up on
 * the way out and refused if nothing is there; an anonymous sub is its source
 * as B::Deparse writes it, and building one from that runs code out of the
 * stream, which $Struct::Codec::Eval = 0 refuses (it is 1 by default). A
 * filehandle with no name is its file descriptor and mode, reopened by dup on
 * the way out, which means something in the process that wrote it or a child
 * that inherited the descriptor and nothing anywhere else.
 *
 * Every one of these is a REFERENT: it follows a REF or OBJECT tag, is tracked
 * under that tag when shared, and is refused where a value belongs. The two
 * exceptions are a tied scalar and a glob, which perl can put in a slot
 * directly, so those two tags are legal in either position.
 *
 * ---- what is NOT in the format --------------------------------------------------
 *
 * No compression: a cache entry is small by
 * construction. No weak references: they come back strong. No dualvars: the
 * string wins. No closures: a sub that captured a lexical is refused, because
 * its source without the lexical is a different sub that would run without
 * complaint. No wire compatibility with Sereal or CBOR: this exists to be
 * fast to build Perl data from, not to be read by another language. Each of
 * those is a decision in plan_struct_codec/00-overview.md, not an oversight.
 */

#define SC_MAGIC      'S'
#define SC_VERSION    '1'
#define SC_HDR_LEN    3
#define SC_FLOAT      8       /* the third header byte: IEEE double, 8 bytes */
#define SC_NV_BYTES   8

#define SC_TRACK      0x80u
#define SC_KIND(t)    ((unsigned char)((t) & 0x7Fu))

/* small integers: the tag IS the value */
#define SC_T_SMALL_POS   0x00u   /* 0x00..0x0F  ->  0..15   */
#define SC_T_SMALL_NEG   0x10u   /* 0x10..0x1F  -> -16..-1  */
#define SC_SMALL_MAX     15
#define SC_SMALL_MIN     (-16)

#define SC_T_UV          0x20u   /* varint                             */
#define SC_T_NEG         0x21u   /* varint of -(iv + 1): -1 is 0, and IV_MIN fits */
#define SC_T_NV          0x22u   /* 8 bytes: IEEE double, little-endian */
#define SC_T_UNDEF       0x23u
#define SC_T_TRUE        0x24u   /* only written where SvIsBOOL exists; an older */
#define SC_T_FALSE       0x25u   /* perl decodes them as 1 and ""               */
#define SC_T_BYTES       0x26u   /* varint length, bytes               */
#define SC_T_UTF8        0x27u   /* varint length, bytes, SvUTF8 on    */
#define SC_T_REF         0x28u   /* the referent follows               */
#define SC_T_OBJECT      0x29u   /* class as a key (len<<1|utf8, bytes), then the referent */
#define SC_T_HASH        0x2Au   /* varint count, then count * (key, value) */
#define SC_T_ARRAY       0x2Bu   /* varint count, then count values    */
#define SC_T_REFP        0x2Cu   /* varint offset of a TRACKed tag: a NEW reference to it */
#define SC_T_ALIAS       0x2Du   /* varint offset of a TRACKed tag: the SAME SV */

/* referents that are not data; each follows a REF or OBJECT tag */
#define SC_T_REGEXP      0x2Eu   /* pattern as a key (len<<1|utf8), flag letters as a key */
#define SC_T_TIED_SCALAR 0x2Fu   /* the tie object, as a value; legal in a slot too */
#define SC_T_TIED_ARRAY  0x30u   /* the tie object, as a value; contents not stored */
#define SC_T_TIED_HASH   0x31u   /* the tie object, as a value; contents not stored */
#define SC_T_CODE_NAME   0x32u   /* fully-qualified name as a key             */
#define SC_T_CODE_SRC    0x33u   /* B::Deparse body as a key; needs $Struct::Codec::Eval */
#define SC_T_GLOB        0x34u   /* the glob's name as a key; legal in a slot too */
#define SC_T_FD_GLOB     0x35u   /* one byte IoTYPE, varint descriptor; a glob    */
#define SC_T_FD_IO       0x36u   /* the same, coming back as the IO alone        */
#define SC_T_FORMAT      0x37u   /* the format's glob name as a key              */
#define SC_T_NV_STR      0x38u   /* varint length, decimal digits: an NV no double holds */
/* 0x39..0x3F reserved and refused */

/* The longest decimal a wide NV produces is binary128's 36 significant digits
 * plus a sign, a point, 'e', an exponent sign and four exponent digits. Sixty
 * three leaves room and keeps the decoder's stack buffer small; a longer one on
 * the wire is corrupt input and is refused rather than truncated. */
#define SC_NV_STR_MAX    63

/* short strings: the length is in the low five bits */
#define SC_T_SHORT_BYTES 0x40u   /* 0x40..0x5F */
#define SC_T_SHORT_UTF8  0x60u   /* 0x60..0x7F */
#define SC_SHORT_MAX     31
#define SC_SHORT_LEN(t)  ((STRLEN)((t) & 0x1Fu))

/* LEB128, unsigned. Ten bytes carry 70 bits, which is more than a UV; an
 * eleventh byte, or a tenth with bits past the 64th, is corrupt input. */
#define SC_VARINT_MAX    10

/* Deeper than this is a cycle the seen table somehow missed, or a caller's
 * bug; either way it is a croak and not a C stack overflow. Both sides. */
#define SC_DEPTH_MAX     4096

#endif /* SC_FORMAT_H */
