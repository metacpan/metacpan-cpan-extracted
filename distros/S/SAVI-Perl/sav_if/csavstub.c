/*
 * csavstub.c (26-NOV-1999)
 *
 * Copyright (C) 1999,2000 Sophos Plc, Oxford, England.
 *
 * This module is to be provided to third-parties producing products that are
 * SAVI-compliant.  Because some Unixes do not support run-time shared library
 * loading, it will sometimes be necessary for a manufacturer to use this source
 * to produce a 'stub' library, which they will distribute with their product.
 * These manufacturers must arrange for this library to be installed as
 * libsavi.so.2.0.0, so that it will be successfully overridden by subsequent
 * installations of a non-stub SAVI library.  It is expected that manufacturers
 * will also make symbolic links, in the manner of some ldconfigs, so that (on
 * most Unixes) the resultant directory entries are:
 *
 *     libsavi.so -> libsavi.so.2
 *     libsavi.so.2 -> libsavi.so.2.0.0
 *     libsavi.so.2.0.0
 *
 * Of course, these links should not be made if they already exist, as they will
 * point to a pre-installed, probably non-stub, SAVI library.  In addition,
 * manufacturers should beware of Unixes where the libraries follow a different,
 * and non-standard, naming convention.
 */

#include "savitype.h"
#include "swerror2.h"

/* ----- */

HRESULT SOPHOS_EXPORTC DllGetClassObject(REFCLSID CLSIDObject, REFIID IIDObject, void **ppObject)
{
  if (ppv)
    *ppv = NULL;

  return SOPHOS_SAVI2_ERROR_STUB;
}
/* ----- End ----- */
