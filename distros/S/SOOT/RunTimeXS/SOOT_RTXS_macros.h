/* This is all based on Class::XSAccessor code */

#ifndef _SOOT_RTXS_macros_h_
#define _SOOT_RTXS_macros_h_

#define SOOT_RTXS_SUBNAME(name) XS_SOOT__RTXS_ ## name

/* Install a new XSUB under 'name' and automatically set the file name */
#define INSTALL_NEW_CV(name, xsub)                                            \
STMT_START {                                                                  \
  if (newXS(name, xsub, (char*)__FILE__) == NULL)                             \
    croak("ARG! Something went really wrong while installing a new XSUB!");   \
} STMT_END

/* Install a new XSUB under 'name' and set the function index attribute
 * Requires a previous declaration of a CV* cv!
 **/
#define INSTALL_NEW_CV_WITH_INDEX(name, xsub, function_index)               \
STMT_START {                                                                \
  CV* cv = newXS(name, xsub, (char*)__FILE__);                              \
  if (cv == NULL)                                                           \
    croak("ARG! Something went really wrong while installing a new XSUB!"); \
  XSANY.any_i32 = function_index;                                           \
} STMT_END

/* Install a new XSUB under 'name' and set the function index attribute
 * for array-based objects. Requires a previous declaration of a CV* cv!
 **/
#define INSTALL_NEW_CV_ARRAY_OBJ(name, xsub, obj_array_index)                \
STMT_START {                                                                 \
  const U32 function_index = get_internal_array_index((I32)obj_array_index); \
  INSTALL_NEW_CV_WITH_INDEX(name, xsub, function_index);                     \
  SOOT_RTXS_arrayindices[function_index] = obj_array_index;                  \
} STMT_END


/* Install a new XSUB under 'name' and set the function index attribute
 * for hash-based objects. Requires a previous declaration of a CV* cv!
 **/
// FIXME in principle, we would prefer an array of structs here over an array!
#define INSTALL_NEW_CV_HASH_OBJ(name, namelen, xsub, offset, maxIndex)       \
STMT_START {                                                                 \
  soot_rtxs_hashkey hashkey;                                                 \
  const U32 function_index = get_hashkey_index(aTHX_ name, namelen);         \
  INSTALL_NEW_CV_WITH_INDEX(name, xsub, function_index);                     \
  hashkey.offset = offset;                                                   \
  hashkey.maxIndex = maxIndex;                                               \
  SOOT_RTXS_hashkeys[function_index] = hashkey;                              \
} STMT_END

#define SOOT_RTXS_INIT                                             \
    void* dataAddr;                                                \
    const I32 offset = SOOT_RTXS_arrayindices[ix];

#define SOOT_RTXS_INIT_ARRAY                                       \
    void* dataAddr;                                                \
    const soot_rtxs_hashkey idxdata = SOOT_RTXS_hashkeys[ix];

#define SOOT_RTXS_CALCADDRESS                                      \
    dataAddr = INT2PTR(void*,                                      \
      PTR2UV( (void*)SOOT::LobotomizeObject(aTHX_ self) )          \
      + offset                                                     \
    );

#define SOOT_RTXS_CALCADDRESS_ARRAY                                \
    dataAddr = INT2PTR(void*,                                      \
      PTR2UV( (void*)SOOT::LobotomizeObject(aTHX_ self) )          \
      + idxdata.offset                                             \
    );

#define SOOT_RTXS_ASSERT_ARRAY_ARGUMENT                            \
    if (!SvROK(src) || (SvTYPE(SvRV(src)) != SVt_PVAV))            \
      croak("Need reference to an array as argument");


#endif

