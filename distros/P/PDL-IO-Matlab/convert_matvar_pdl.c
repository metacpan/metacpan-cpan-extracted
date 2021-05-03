#include <pdl.h>

static char *matvar_class_type_desc[16] = 
  {"Undefined","Cell Array","Structure",
   "Object","Character Array","Sparse Array","Double Precision Array",
   "Single Precision Array", "8-bit, signed integer array",
   "8-bit, unsigned integer array","16-bit, signed integer array",
   "16-bit, unsigned integer array","32-bit, signed integer array",
   "32-bit, unsigned integer array","64-bit, signed integer array",
   "64-bit, unsigned integer array"
  };


/* enum matio_classes { */
/*     MAT_C_EMPTY    =  0, /\**< @brief Empty array                           *\/ */
/*     MAT_C_CELL     =  1, /\**< @brief Matlab cell array class               *\/ */
/*     MAT_C_STRUCT   =  2, /\**< @brief Matlab structure class                *\/ */
/*     MAT_C_OBJECT   =  3, /\**< @brief Matlab object class                   *\/ */
/*     MAT_C_CHAR     =  4, /\**< @brief Matlab character array class          *\/ */
/*     MAT_C_SPARSE   =  5, /\**< @brief Matlab sparse array class             *\/ */
/*     MAT_C_DOUBLE   =  6, /\**< @brief Matlab double-precision class         *\/ */
/*     MAT_C_SINGLE   =  7, /\**< @brief Matlab single-precision class         *\/ */
/*     MAT_C_INT8     =  8, /\**< @brief Matlab signed 8-bit integer class     *\/ */
/*     MAT_C_UINT8    =  9, /\**< @brief Matlab unsigned 8-bit integer class   *\/ */
/*     MAT_C_INT16    = 10, /\**< @brief Matlab signed 16-bit integer class    *\/ */
/*     MAT_C_UINT16   = 11, /\**< @brief Matlab unsigned 16-bit integer class  *\/ */
/*     MAT_C_INT32    = 12, /\**< @brief Matlab signed 32-bit integer class    *\/ */
/*     MAT_C_UINT32   = 13, /\**< @brief Matlab unsigned 32-bit integer class  *\/ */
/*     MAT_C_INT64    = 14, /\**< @brief Matlab unsigned 32-bit integer class  *\/ */
/*     MAT_C_UINT64   = 15, /\**< @brief Matlab unsigned 32-bit integer class  *\/ */
/*     MAT_C_FUNCTION = 16 /\**< @brief Matlab unsigned 32-bit integer class  *\/ */
/* }; */


static int  matvar_class_to_pdl_type[16] = 
/*      0       1       2       3   */
     { -1,     -1,     -1,     -1,

/*      4       5       6       7   */
       -1,     -1,  PDL_D,  PDL_F,

/*      8       9      10       11   */
    PDL_B,  PDL_B,  PDL_S,  PDL_US,

/*     12      13      14       15   */
    PDL_L,     -1,     -1,      -1
  };


static int  pdl_type_to_matvar_type[] =
  {
    [PDL_B]  = MAT_T_INT8,
    [PDL_S]  = MAT_T_INT16,
    [PDL_US] = MAT_T_UINT16,
    [PDL_L]  = MAT_T_INT32,
    [PDL_LL] = MAT_T_INT32,
    [PDL_F]  = MAT_T_SINGLE,
    [PDL_D]  = MAT_T_DOUBLE,
  };

static int  pdl_type_to_matvar_class[] =
  {
    [PDL_B]  = MAT_C_INT8,
    [PDL_S]  = MAT_C_INT16,
    [PDL_US] = MAT_C_UINT16,
    [PDL_L]  = MAT_C_INT32,
    [PDL_LL] = MAT_C_INT32,
    [PDL_F]  = MAT_C_SINGLE,
    [PDL_D]  = MAT_C_DOUBLE,
  };


static void delete_matvar_to_pdl_data(pdl* p, size_t param)
{
  if (p->data)
    free(p->data);
  p->data = 0;
}

typedef void (*DelMagic)(pdl *, size_t param);
static void default_magic(pdl *p, size_t  pa) { p->data = 0; }
static pdl* my_pdl_wrap(void *data, int datatype, PDL_Indx dims[],
                        int ndims, DelMagic delete_magic, int delparam)
{
  pdl* npdl = PDL->pdlnew();
  PDL->setdims(npdl,dims,ndims);
  npdl->datatype = datatype;
  npdl->data = data;
  npdl->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
  if (delete_magic != NULL)
    PDL->add_deletedata_magic(npdl, (void *) delete_magic, delparam);
  else
    PDL->add_deletedata_magic(npdl, default_magic, 0);
  return npdl;
}

static pdl* matvar_to_pdl (matvar_t * matvar, int onedr) {
  int ndims = matvar->rank;
  pdl * piddle;
  int i, pdl_data_type;
  PDL_Indx * dims;
  if ( matvar->isComplex )
    barf("matvar_to_pdl: Complex matlab variables not supported.");
  dims = (PDL_Indx *)malloc(sizeof(PDL_Indx) * ndims);
  //  fprintf(stderr, "ONEDR %d\n", onedr);
  if (ndims == 2 && onedr != 0 ) {
    if (matvar->dims[0] == 1) {
      ndims = 1;
      dims[0] = matvar->dims[1];
    }
    else if (matvar->dims[1] == 1) {
      ndims = 1;
      dims[0] = matvar->dims[0];
    }
    else  for(i=0;i<ndims;i++) dims[i] = matvar->dims[i];
  }
  else for(i=0;i<ndims;i++) dims[i] = matvar->dims[i];
  if ( 0 > (pdl_data_type = matvar_class_to_pdl_type[matvar->class_type] )) {
    fprintf(stderr, "matvar_to_pdl: matlab data class is '%s'\n",matvar_class_type_desc[matvar->class_type]);
    barf("matvar_to_pdl: No pdl data type corresponding to this class type.");}
  piddle = my_pdl_wrap(matvar->data, pdl_data_type, dims, ndims,
                       delete_matvar_to_pdl_data, 0);
  matvar->mem_conserve = 1; // prevent matio freeing memory for data
  free(dims);
  return piddle;
}

pdl * convert_next_matvar_to_pdl (mat_t * matfp,  matvar_t ** matvar, int onedr) {
  *matvar = Mat_VarReadNext(matfp);
  if (*matvar == NULL )
    return NULL;
  return matvar_to_pdl(*matvar,onedr); // calling code must call Mat_VarFree(matvar)
}

/*******************************************************
 *  pdl to matvar
 *******************************************************/

matvar_t * pdl_to_matvar (pdl * piddle, char *varname, int onedw) {
  int ndims = piddle->ndims;
  matvar_t *matvar;
  int i, matvar_class_type, matvar_data_type;
  int opt =  MAT_F_DONT_COPY_DATA;
  size_t * dims;
  int tmp;
  dims = (size_t *)malloc(sizeof(size_t) * (ndims+1));
  for(i=0;i<ndims;i++) dims[i] = piddle->dims[i];
  if (ndims == 1 ) {
    if ( onedw == 1) {
      ndims = 2;
      dims[1] = 1;
    }
    else if ( onedw == 2) {
      ndims = 2;
      tmp = dims[0];
      dims[0] = 1;
      dims[1] = tmp;
     }
  }
  matvar_class_type = pdl_type_to_matvar_class[piddle->datatype];
  matvar_data_type  = pdl_type_to_matvar_type[piddle->datatype];
  matvar = Mat_VarCreate(varname,matvar_class_type, matvar_data_type,
                         ndims, dims, piddle->data, opt);
  free(dims);
  return matvar;
}

int write_pdl_to_matlab_file (mat_t *mat, pdl *piddle, char *varname, int onedw,
                              int compress) {
  matvar_t * matvar;
  matvar = pdl_to_matvar(piddle,varname,onedw);
  int retval;
  if ( compress == 1 ) retval =  Mat_VarWrite(mat, matvar, MAT_COMPRESSION_ZLIB);
  else retval =  Mat_VarWrite(mat, matvar, MAT_COMPRESSION_NONE);
  Mat_VarFree(matvar);
  return retval;
}
