/*
 * Stuff common to both Weasel Reader and makeztxt
 *
 * $Id: weasel_common.h 412 2007-06-21 06:57:30Z foxamemnon $
 *
 */

#ifndef _WEASEL_COMMON_H_
#define _WEASEL_COMMON_H_ 1



//  The default creator is Weasel Reader 'GPlm'
#define GPLM_CREATOR_ID         'GPlm'
#define GPLM_CREATOR_ID_STR     "GPlm"

//  Databases of type 'zTXT'
#define ZTXT_TYPE_ID            'zTXT'
#define ZTXT_TYPE_ID_STR        "zTXT"

//  Size of one database record
#define RECORD_SIZE             8192

//  Allow largest WBIT size for data
#define MAXWBITS                15

//  Max length for a bookmark/annotation title
#define MAX_BMRK_LENGTH         20

//  Current version of the zTXT format (v1.44)
#define ZTXT_VERSION            0x012C



/*****************************************************
 *   This is the zTXT document header (record #0)    *
 *            ----zTXT version 1.44----              *
 *****************************************************/
typedef struct zTXT_record0Type {
  UInt16        version;                // zTXT format version
  UInt16        numRecords;             // Number of data (TEXT) records
  UInt32        size;                   // Size in bytes of uncomp. data
  UInt16        recordSize;             // Size of a single data record
  UInt16        numBookmarks;           // Number of bookmarks in DB
  UInt16        bookmarkRecord;         // Record containing bookmarks
  UInt16        numAnnotations;         // Number of annotation records
  UInt16        annotationRecord;       // Record # of annotation index
  UInt8         flags;                  // Bit flags for file options:
                                        //  0x01 = compressed w/Z_FULL_FLUSH
                                        //  0x02 = non-uniform record lengths
                                        //  .... = reserved
  UInt8         reserved;               // reserved
  UInt32        crc32;                  // 32 bit CRC for data (0 = disabled)
  UInt8         padding[0x20 - 24];     // Pad to a size of 0x20 bytes
} zTXT_record0;


/* Definition of bits in the flags byte of the zTXT header */
typedef enum {
  ZTXT_RANDOMACCESS     = 0x01,
  ZTXT_NONUNIFORM       = 0x02
  // The remaining values are reserved
} zTXT_flag;



#endif
