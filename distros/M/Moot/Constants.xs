#/*-*- Mode: C -*- */

MODULE = Moot		PACKAGE = Moot   PREFIX = moot_

##=====================================================================
## Constants
##=====================================================================

##-- disable perl prototypes
PROTOTYPES: DISABLE

##--------------------------------------------------------------
## mootConfig.h
const char *
library_version()
 CODE:
   RETVAL=moot_version_string;
 OUTPUT:
   RETVAL

##--------------------------------------------------------------
## mootToken.h: mootTokenTypeE

mootTokenType
TokTypeUnknown()
CODE:
 RETVAL=moot::TokTypeUnknown;
OUTPUT:
 RETVAL

mootTokenType
TokTypeVanilla()
CODE:
 RETVAL=moot::TokTypeVanilla;
OUTPUT:
 RETVAL

mootTokenType
TokTypeLibXML()
CODE:
 RETVAL=moot::TokTypeLibXML;
OUTPUT:
 RETVAL

mootTokenType
TokTypeXMLRaw()
CODE:
 RETVAL=moot::TokTypeXMLRaw;
OUTPUT:
 RETVAL

mootTokenType
TokTypeComment()
CODE:
 RETVAL=moot::TokTypeComment;
OUTPUT:
 RETVAL

mootTokenType
TokTypeEOS()
CODE:
 RETVAL=moot::TokTypeEOS;
OUTPUT:
 RETVAL

mootTokenType
TokTypeEOF()
CODE:
 RETVAL=moot::TokTypeEOF;
OUTPUT:
 RETVAL

mootTokenType
TokTypeWB()
CODE:
 RETVAL=moot::TokTypeWB;
OUTPUT:
 RETVAL

mootTokenType
TokTypeSB()
CODE:
 RETVAL=moot::TokTypeSB;
OUTPUT:
 RETVAL

mootTokenType
TokTypeUser()
CODE:
 RETVAL=moot::TokTypeUser;
OUTPUT:
 RETVAL


##--------------------------------------------------------------
## mootHMM.h : mootHMM::verbosityLevel

UV
vlSilent()
CODE:
 RETVAL = moot::vlSilent;
OUTPUT:
 RETVAL

UV
vlErrors()
CODE:
 RETVAL = moot::vlErrors;
OUTPUT:
 RETVAL

UV
vlWarnings()
CODE:
 RETVAL = moot::vlWarnings;
OUTPUT:
 RETVAL

UV
vlProgress()
CODE:
 RETVAL = moot::vlProgress;
OUTPUT:
 RETVAL

UV
vlEverything()
CODE:
 RETVAL = moot::vlEverything;
OUTPUT:
 RETVAL


##--------------------------------------------------------------
## mootTokenIO.h : TokenIOFormat

TokenIOFormatMask
tiofNone()
CODE:
  RETVAL = tiofNone;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofUnknown()
CODE:
  RETVAL = tiofUnknown;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofNull()
CODE:
  RETVAL = tiofNull;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofUser()
CODE:
  RETVAL = tiofUser;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofNative()
CODE:
  RETVAL = tiofNative;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofXML()
CODE:
  RETVAL = tiofXML;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofConserve()
CODE:
  RETVAL = tiofConserve;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofPretty()
CODE:
  RETVAL = tiofPretty;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofText()
CODE:
  RETVAL = tiofText;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofAnalyzed()
CODE:
  RETVAL = tiofAnalyzed;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofTagged()
CODE:
  RETVAL = tiofTagged;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofPruned()
CODE:
  RETVAL = tiofPruned;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofLocation()
CODE:
  RETVAL = tiofLocation;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofCost()
CODE:
  RETVAL = tiofCost;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofTrace()
CODE:
  RETVAL = tiofTrace;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofRare()
CODE:
  RETVAL = tiofRare;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofMediumRare()
CODE:
  RETVAL = tiofMediumRare;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofMedium()
CODE:
  RETVAL = tiofMedium;
OUTPUT:
  RETVAL

TokenIOFormatMask
tiofWellDone()
CODE:
  RETVAL = tiofWellDone;
OUTPUT:
  RETVAL

