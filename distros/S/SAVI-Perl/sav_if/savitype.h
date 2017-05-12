/*
 * savitype.h (04-MAY-2000)
 *
 * This file is a part of the Sophos Anti-Virus Interface (SAVI)(tm).
 *
 * Copyright (C) 2002 Sophos Plc, Oxford, England.
 * All rights reserved.
 *
 * This source code is only intended as a supplement to the
 * SAVI(tm) Reference and related documentation for the library.
 *
 * Cross platform type definitions.
 */

#ifndef __SAVITYPE_DOT_H__
#define __SAVITYPE_DOT_H__

#include "compute.h"

/* 
 * Ensure consistent packing for the interface
 * between elements of the service...
 */
#ifdef __SOPHOS_MS__
# pragma pack(push, pack_header__SAVITYPE_DOT_H__, 4)
#endif

#include "sophtype.h"
#include "savichar.h"

#ifdef __SOPHOS_WIN32__
#  define WIN32_LEAN_AND_MEAN
#  include <objbase.h>    /* For HRESULT. */
#  define SOPHOS_BOOL      BOOL
#  define SOPHOS_ULONG     ULONG
#else  /* __SOPHOS_WIN32__ */
   /*
    * Date structure (same format as the Win32 SYSTEMTIME structure).
    */
   typedef struct _SYSTEMTIME
   {
      U16 wYear;              /* Full-four digit representation [eg 1998]      */
      U16 wMonth;             /*   1 ->  12 [January == 1, February == 2, etc] */
      U16 wDayOfWeek;         /*   0 ->   6 [Sunday  == 0, Monday   == 1, etc] */
      U16 wDay;               /*  01 ->  31                                    */
      U16 wHour;              /*  00 ->  23                                    */
      U16 wMinute;            /*  00 ->  59                                    */
      U16 wSecond;            /*  00 ->  59                                    */
      U16 wMilliseconds;      /* 000 -> 999                                    */
   } SYSTEMTIME;

   /* Define some types analogous to Windows COM types: */
   typedef U32   SOPHOS_ULONG;
   typedef S32   HRESULT;
   typedef U32   SOPHOS_BOOL;

#endif /* __SOPHOS_WIN32__ */
#define SOPHOS_BOOL_DEFINED

#define SOPHOS_STDCALL_PUBLIC     SOPHOS_STDCALL SOPHOS_PUBLIC
#define SOPHOS_STDCALL_PUBLIC_PTR SOPHOS_STDCALL SOPHOS_PUBLIC_PTR

/*
 * ISweepResults codes valid for SOPHOS_IID_SAVI interface only.
 */
#define SOPHOS_NO_VIRUS                 0          /* No virus found   */
#define SOPHOS_VIRUS_IDENTITY           1          /* Strong detection */
#define SOPHOS_VIRUS_PATTERN            2          /* Weaker detection */
#define SOPHOS_VIRUS_MACINTOSH          3          /* Macintosh virus  */
#define SOPHOS_VIRUS                    0xFFFFFFFF /* Generic result   */

/*
 * Type definitions for version checksum objects.
 */
#define SOPHOS_TYPE_VDATA  0
#define SOPHOS_TYPE_BINARY 1

/*
 * Error severity definitions as used by ISeverityNotify.
 */
#define SOPHOS_ERROR_SEVERITY_SUCCESS               0
#define SOPHOS_ERROR_SEVERITY_TRANSIENT             1
#define SOPHOS_ERROR_SEVERITY_UNKNOWN               2
#define SOPHOS_ERROR_SEVERITY_SUSPEND_ACTIVITY      3
#define SOPHOS_ERROR_SEVERITY_REINIT_SAVI           4
#define SOPHOS_ERROR_SEVERITY_REINSTALL_SAV         5
#define SOPHOS_ERROR_SEVERITY_CRITICAL              6

/*
 * Engine specific settings.
 */
#define SOPHOS_DOS_FILES                1
#define SOPHOS_MAC_FILES                2
#define SOPHOS_DOS_AND_MAC_FILES        (SOPHOS_DOS_FILES | SOPHOS_MAC_FILES)

/*
 * Loaded IDE codes.
 */
#define SOPHOS_IDE_VDL_SUCCESS          0
#define SOPHOS_IDE_VDL_FAILED           1
#define SOPHOS_IDE_VDL_OLD_WARNING      2
#define SOPHOS_IDE_VDL_INVALID_VERSION  3

/*
 * External virus information source type codes.
 */
#define SOPHOS_TYPE_IDE                 0
#define SOPHOS_TYPE_UPD                 1
#define SOPHOS_TYPE_VDL                 2
#define SOPHOS_TYPE_MAIN_VIRUS_DATA     3
#define SOPHOS_TYPE_UNKNOWN             0xFFFFFFFF

/*
 * Values for the "Activity" parameter passed to OkToContinue().
 */
#define SOPHOS_ACTVTY_CLASSIF           1
#define SOPHOS_ACTVTY_NEXTFILE          2
#define SOPHOS_ACTVTY_DECOMPR           3

/*
 * SaviStream seek origin definitions.
 */
#define SAVISTREAM_SEEK_SET             (U32)0x00000000 /* Seek relative to start of stream */
#define SAVISTREAM_SEEK_CUR             (U32)0x00000001 /* Seek relative to current postion */  
#define SAVISTREAM_SEEK_END             (U32)0x00000002 /* Seek relative to end of stream */

/*
 * Configuration option types.
 */
#define SOPHOS_TYPE_INVALID             0
#define SOPHOS_TYPE_U08                 1
#define SOPHOS_TYPE_U16                 2
#define SOPHOS_TYPE_U32                 3
#define SOPHOS_TYPE_S08                 4
#define SOPHOS_TYPE_S16                 5
#define SOPHOS_TYPE_S32                 6
#define SOPHOS_TYPE_BOOLEAN             7   
#define SOPHOS_TYPE_BYTESTREAM          8 
#define SOPHOS_TYPE_OPTION_GROUP        9 
#define SOPHOS_TYPE_STRING             10 

/*
 * Configuration option names.
 */
#define SOPHOS_NAMESPACE_SUPPORT        SOPHOS_COMSTR("NamespaceSupport")
#define SOPHOS_DO_FULL_SWEEP            SOPHOS_COMSTR("FullSweep")
#define SOPHOS_DYNAMIC_DECOMPRESSION    SOPHOS_COMSTR("DynamicDecompression")
#define SOPHOS_FULL_MACRO_SWEEP         SOPHOS_COMSTR("FullMacroSweep")
#define SOPHOS_OLE2_HANDLING            SOPHOS_COMSTR("OLE2Handling")
#define SOPHOS_IGNORE_TEMPLATE_BIT      SOPHOS_COMSTR("IgnoreTemplateBit")
#define SOPHOS_VBA3_HANDLING            SOPHOS_COMSTR("VBA3Handling")
#define SOPHOS_VBA5_HANDLING            SOPHOS_COMSTR("VBA5Handling")
#define SOPHOS_OF95_DECRYPT_HANDLING    SOPHOS_COMSTR("OF95DecryptHandling")
#define SOPHOS_HELP_HANDLING            SOPHOS_COMSTR("HelpHandling")
#define SOPHOS_DECOMPRESS_VBA5          SOPHOS_COMSTR("DecompressVBA5")
#define SOPHOS_DO_EMULATION             SOPHOS_COMSTR("Emulation")
#define SOPHOS_PE_HANDLING              SOPHOS_COMSTR("PEHandling")
#define SOPHOS_XF_HANDLING              SOPHOS_COMSTR("ExcelFormulaHandling")
#define SOPHOS_PM97_HANDLING            SOPHOS_COMSTR("PowerPointMacroHandling")
#define SOPHOS_PPT_EMBD_HANDLING        SOPHOS_COMSTR("PowerPointEmbeddedHandling")
#define SOPHOS_PROJECT_HANDLING         SOPHOS_COMSTR("ProjectHandling")
#define SOPHOS_ZIP_DECOMPRESSION        SOPHOS_COMSTR("ZipDecompression")
#define SOPHOS_ARJ_DECOMPRESSION        SOPHOS_COMSTR("ArjDecompression")
#define SOPHOS_RAR_DECOMPRESSION        SOPHOS_COMSTR("RarDecompression")
#define SOPHOS_UUE_DECOMPRESSION        SOPHOS_COMSTR("UueDecompression")
#define SOPHOS_GZIP_DECOMPRESSION       SOPHOS_COMSTR("GZipDecompression")
#define SOPHOS_TAR_DECOMPRESSION        SOPHOS_COMSTR("TarDecompression")
#define SOPHOS_CMZ_DECOMPRESSION        SOPHOS_COMSTR("CmzDecompression")
#define SOPHOS_HQX_DECOMPRESSION        SOPHOS_COMSTR("HqxDecompression")
#define SOPHOS_MBIN_DECOMPRESSION       SOPHOS_COMSTR("MbinDecompression")
#define SOPHOS_LOOPBACK_ENABLED         SOPHOS_COMSTR("LoopBackEnabled")
#define SOPHOS_MAX_RECURSION_DEPTH      SOPHOS_COMSTR("MaxRecursionDepth")

#define SOPHOS_MAIN_VDATA_LOCATION      SOPHOS_COMSTR("VirusDataDir")
#define SOPHOS_VIRUS_DATA_FILE          SOPHOS_COMSTR("VirusDataName")
#define SOPHOS_IDE_LOCATION             SOPHOS_COMSTR("IdeDir")
#define SOPHOS_ALLOW_PARTIAL_VDATA      SOPHOS_COMSTR("AllowPartialVirusData")

#define SOPHOS_AUTO_STOP                SOPHOS_COMSTR("EnableAutoStop")

/*
 * Storage type IDs.
 * NB SAVI clients must be designed to deal with IDs other than
 * the ones defined in the list below.
 */
#define ID_OLE2_STORAGE        0x0020  /* OLE2 file. */

#define ID_SARC_ZIP_STORAGE    0x0030  /* ZIP archive. */
#define ID_SARC_TAR_STORAGE    0x0031  /* TAR archive. */
#define ID_SARC_GZIP_STORAGE   0x0032  /* GZip archive. */
#define ID_SARC_ARJ_STORAGE    0x0033  /* ARJ archive. */
#define ID_SARC_RAR_STORAGE    0x0034  /* RAR archive. */
#define ID_SARC_UUE_STORAGE    0x0035  /* UUE archive. */
#define ID_SARC_CMZ_STORAGE    0x0036  /* CMZ archive. */
#define ID_SARC_PP97_STORAGE   0x0037  /* Compressed PowerPoint 97. */
#define ID_SARC_HQX_STORAGE    0x0038  /* Macintosh Binhex. */
#define ID_SARC_MBIN_STORAGE   0x0039  /* MacBinary file. */
#define ID_SARC_CAB_STORAGE    0x003a  /* MS Cabinet archive. */
#define ID_SARC_TNEF_STORAGE   0x003b  /* ARJ archive. */
#define ID_SARC_LHA_STORAGE    0x003c  /* LHA archive. */
#define ID_SARC_MS_STORAGE     0x003d  /* MsCompress file. */
#define ID_SARC_MSO_STORAGE    0x003e  /* MSO / Active MIME. */
#define ID_SARC_APPLE_STORAGE  0x003f  /* AppleSinge / AppleDouble file. */
#define ID_SARC_PDF_STORAGE    0x0041  /* Adobe PDF file. */
#define ID_SARC_BZIP2_STORAGE  0x0042  /* BZIP2 archive. */
#define ID_SARC_STF5_STORAGE   0x0043  /* Stuffit v.7 archive. */
#define ID_SARC_STF1_STORAGE   0x0044  /* Old format Stuffit archive. */
#define ID_SARC_ICAB_STORAGE   0x0045  /* InstallShield CAB archive. */
#define ID_SARC_ITSS_STORAGE   0x0046  /* MS Compressed Help file. */

#define ID_SEXP_DIET_STORAGE   0x0050  /* DIET self-extracting executable. */
#define ID_SEXP_PKLT_STORAGE   0x0051  /* PKLite self-extracting executable. */
#define ID_SEXP_LZEX_STORAGE   0x0052  /* LZEX self-extracting executable. */
#define ID_SEXP_UPX_STORAGE    0x0053  /* UPX self-extracting executable. */
#define ID_SEXP_PETITE_STORAGE 0x0054  /* Petite self-extracting executable. */
#define ID_SEXP_ASPACK_STORAGE 0x0055  /* ASPack self-extracting executable. */
#define ID_SEXP_FSG_STORAGE    0x0056  /* FSG self-extracting executable. */
#define ID_SEXP_PEC_STORAGE    0x0057  /* PECompact self-extracting executable. */

#define ID_SFX_STORAGE         0x0058  /* Self-extracting archive. */

#define ID_EXEC_STORAGE        0x0060  /* DOS/Windows executable file. */
#define ID_ELF_STORAGE         0x0068  /* Unix/Linux executable file. */
#define ID_MACHO_STORAGE       0x006d  /* MachO executable. */

#define ID_HELP_STORAGE        0x0090  /* MS Windows Help file. */
#define ID_CLEAN_JPEG_STORAGE  0x0091  /* JPEG image file. */
#define ID_CLEAN_BMP_STORAGE   0x0092  /* Bitmap image file. */
#define ID_CLEAN_GIF_STORAGE   0x0093  /* GIF image file. */
#define ID_CLEAN_RIFF_STORAGE  0x0094  /* RIFF media file. */
#define ID_CLEAN_TIFF_STORAGE  0x0095  /* TIFF image file. */
#define ID_CLEAN_PNG_STORAGE   0x0096  /* PNG image file. */
#define ID_MP3_STORAGE         0x0097  /* MP3 file */

#define ID_LPBK_STORAGE        0x00a0  /* VMS 'loopback' file. */

#define ID_COMP_WORD_STORAGE   0x00b0  /* MS Word Basic macros. */
#define ID_COMP_VBA3_STORAGE   0x00b1  /* MS 'Excel 95' macros. */
#define ID_COMP_VBA5_STORAGE   0x00b2  /* MS Visual Basic as used in Office 97 & later. */
#define ID_COMP_VB5D_STORAGE   0x00b3  /* Processed .._VBA5_STORAGE type (SAVI internal type). */
#define ID_COMP_XF95_STORAGE   0x00b4  /* MS 'Excel 95' formulae. */
#define ID_COMP_XF97_STORAGE   0x00b5  /* MS 'Excel 97' formulae. */
#define ID_COMP_PP97_STORAGE   0x00b6  /* MS 'PowerPoint 97'. */
#define ID_COMP_SCRP_STORAGE   0x00b8  /* 'Embedded' document in OLE2 file. */
#define ID_COMP_VISIO_STORAGE  0x00b9  /* MS 'Visio' file. */
#define ID_COMP_VB5P_STORAGE   0x00ba  /* Visual Basic p-code. */

#define ID_MIME_STORAGE        0x00d0  /* MIME file. */
#define ID_BASE64_STORAGE      0x00d1  /* Base64 encoding. */
#define ID_RTF_STORAGE         0x00d4  /* Rich Text Format file. */
#define ID_VBE_STORAGE         0x00d8  /* Encoded Visual Basic file. */
#define ID_HTML_STORAGE        0x00d9  /* HTML file. */
#define ID_OEDBX_STORAGE       0x00da  /* MS Outlook Express file. */
#define ID_OEMAC_STORAGE       0x00db  /* MS Outlook Express (Macintosh) file. */
#define ID_UTF16BE_STORAGE     0x00dd  /* Big-endian UTF16 character encoding. */
#define ID_UTF16LE_STORAGE     0x00de  /* Little-endian UTF16 character encoding. */

#define ID_MAC_STORAGE         0x00f0  /* Macintosh data fork. */
#define ID_MAC_RES_STORAGE     0x00f3  /* Macintosh resource fork. */
#define ID_PRC_RES_STORAGE     0x00f4  /* Palm OS resource file. */
#define ID_JAVA_STORAGE        0x00f5  /* Java byte code class file. */
#define ID_ACCESS_STORAGE      0x00f6  /* MS Access database file (MDB format). */

#define ID_UNIXARCHIVE_STORAGE 0x00f7  /* Unix 'ar' or 'cpio' archive. */
#define ID_RPM_STORAGE         0x00f8  /* RedHat Package Manager file. */
#define ID_XML_STORAGE         0x00f9  /* XML. */


/*
 * File handle type definitions for use with Sweep/DisinfectHandle.
 */
#if defined(__SOPHOS_WIN32__) && defined(__SOPHOS_MS__)
#define SOPHOS_FD                       HANDLE
#define SOPHOS_FD_NULL                  INVALID_HANDLE_VALUE
#elif defined(__SOPHOS_OS2__)
#define SOPHOS_FD                       int
#define SOPHOS_FD_NULL                  ((int)-1)
#elif defined(__SOPHOS_UNIX__)
#define SOPHOS_FD                       int
#define SOPHOS_FD_NULL                  ((int)-1)
#elif defined(__SOPHOS_NW__)
#define SOPHOS_FD                       int
#define SOPHOS_FD_NULL                  ((int)-1)
#elif defined(__SOPHOS_MACOS__) && !defined(__SOPHOS_API_OSX_UNIX__)
#define SOPHOS_FD                       short
#define SOPHOS_FD_NULL                  ((int)0)
#elif defined(__SOPHOS_VMS__)
#define SOPHOS_FD                       int
#define SOPHOS_FD_NULL                  ((int)-1)
#elif defined(__SOPHOS_DOS4GW__)
#define SOPHOS_FD                       int
#define SOPHOS_FD_NULL                  ((int)-1)
#else
# error Unsupported SOPHOS build.
#endif

/*
 * End explicit packing.
 */
#ifdef __SOPHOS_MS__
# pragma pack(pop, pack_header__SAVITYPE_DOT_H__)
#endif

#endif /* __SAVITYPE_DOT_H__ */
