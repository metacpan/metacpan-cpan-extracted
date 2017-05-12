#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <cluto.h>

#include "const-c.inc"

/****************************/

int* malloc_int(int n)
{
  return ((int*) malloc(sizeof(int) * n));
}

float* malloc_float(int n)
{
  return ((float*) malloc(sizeof(float) * n));
}

/****************************/

float* make_float_array(SV *sv, int num) 
{
  float *data;
  AV *av;
  int i;

  data = (float*) malloc (sizeof(float) * num);

  av = (AV*)SvRV(sv);
  for (i = 0; i < num; i++)  {
    data[i] = (float)SvNV(*av_fetch(av, i , 0));
  }
  return data;        
}

int* make_int_array(SV *sv, int num) 
{
  int *data;
  AV *av;
  int i;

  data = (int*) malloc (sizeof(int) * num);

  av = (AV*)SvRV(sv);
  for (i = 0; i < num; i++)  {
    data[i] = (int)SvNV(*av_fetch(av, i , 0));
  }
  return data;
}

/****************************/

AV* make_av_from_float(float* data, int num) 
{
  AV *av;
  int i;

  av = newAV();
  for (i = 0; i < num; i++) {
    av_push(av, newSVnv((double)data[i]));
  }
  return av;
}

AV* make_av_from_int(int* data, int num) 
{
  AV *av;
  int i;

  av = newAV();
  for (i = 0; i < num; i++) {
    av_push(av, newSVnv((double)data[i]));
  }
  return av;
}

/****************************/

void set_array_from_int(SV* sv, int* data, int num)
{ 
   sv_setsv(sv, newRV_noinc((SV*) make_av_from_int(data, num)));
}

void set_array_from_float(SV* sv, float* data, int num)
{ 
   sv_setsv(sv, newRV_noinc((SV*) make_av_from_float(data, num)));
}

/****************************/

void prepare_sparse_matrix(int nrows, int nnz, SV* rowptr_sv, SV* rowind_sv, SV* rowval_sv, int **rowptr, int **rowind, float **rowval) 
{
  *rowptr = make_int_array(rowptr_sv, nrows + 1);
  *rowind = make_int_array(rowind_sv, nnz);
  *rowval = make_float_array(rowval_sv, nnz);
}

void prepare_dense_matrix(int nrows, int ncols, SV* rowval_sv, int **rowptr, int **rowind, float **rowval)
{
  *rowptr = NULL;
  *rowind = NULL;
  *rowval = make_float_array(rowval_sv, nrows * ncols);
}

void prepare_matrix(int matrix_type, int nrows, int ncols, int nnz, SV* rowptr_sv, SV* rowind_sv, SV* rowval_sv, int **rowptr, int **rowind, float **rowval)
{
  switch (matrix_type) {
  case 1:
    prepare_sparse_matrix(nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, rowptr, rowind, rowval);
    break;
  default:
    prepare_dense_matrix(nrows, ncols, rowval_sv, rowptr, rowind, rowval);
    break;
  }
}

/****************************/


MODULE = Statistics::Cluto		PACKAGE = Statistics::Cluto		

INCLUDE: const-xs.inc


void
_VP_ClusterDirect(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, simfun, crfun, rowmodel, colmodel, colprune, ntrials, niter, seed, dbglvl, nclusters, part_sv)
    int matrix_type
    int nrows
    int ncols
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int simfun
    int crfun
    int rowmodel
    int colmodel
    float colprune
    int ntrials
    int niter
    int seed
    int dbglvl
    int nclusters
    SV* part_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;

    /* prepare internal buffers */
    part = malloc_int(nrows);  

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    /* call API */
    CLUTO_VP_ClusterDirect(nrows, ncols, rowptr, rowind, rowval,
                       simfun, crfun, rowmodel, colmodel, colprune, 
                       ntrials, niter, seed,
                       dbglvl, nclusters, part);

    /* set sv* and free buffers */
    set_array_from_int(part_sv, part, nrows);
    free(part);

    free(rowptr);
    free(rowind);
    free(rowval);
}

void
_VP_ClusterRB(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, simfun, crfun, rowmodel, colmodel, colprune, ntrials, niter, seed, cstype, kwayrefine, dbglvl, nclusters, part_sv)
    int matrix_type
    int nrows
    int ncols
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int simfun
    int crfun
    int rowmodel
    int colmodel
    float colprune
    int ntrials
    int niter
    int seed
    int cstype
    int kwayrefine
    int dbglvl
    int nclusters
    SV* part_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;

    /* prepare internal buffers */
    part = malloc_int(nrows);  

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    /* call API */
    CLUTO_VP_ClusterRB(nrows, ncols, rowptr, rowind, rowval,
                       simfun, crfun, rowmodel, colmodel, colprune, 
                       ntrials, niter, seed, cstype, kwayrefine,
                       dbglvl, nclusters, part);

    /* set sv* and free buffers */
    set_array_from_int(part_sv, part, nrows);
    free(part);

    free(rowptr);
    free(rowind);
    free(rowval);
}

int
_VP_GraphClusterRB(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, simfun, rowmodel, colmodel, colprune, grmodel, nnbrs, edgeprune, vtxprune, mincmp, ntrials, seed, cstype, dbglvl, nclusters, part_sv, crvalue_sv)
    int matrix_type
    int nrows
    int ncols
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int simfun
    int rowmodel
    int colmodel
    float colprune
    int grmodel
    int nnbrs
    float edgeprune
    float vtxprune
    int mincmp
    int ntrials
    int seed
    int cstype
    int dbglvl
    int nclusters
    SV* part_sv
    SV* crvalue_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;
    float crvalue;

    /* prepare internal buffers */
    part = malloc_int(nrows);

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    /* call API */
    RETVAL = CLUTO_VP_GraphClusterRB(nrows, ncols, rowptr, rowind, rowval,
                       simfun, rowmodel, colmodel, colprune, grmodel,
                       nnbrs, edgeprune, vtxprune, mincmp,
                       ntrials, seed, cstype, 
                       dbglvl, nclusters, part, &crvalue);

    /* set sv* and free buffers */
    set_array_from_int(part_sv, part, nrows);
    free(part);
    sv_setnv(crvalue_sv, (double)crvalue);

    free(rowptr);
    free(rowind);
    free(rowval);
}
OUTPUT:
    RETVAL

void
_VA_Cluster(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, simfun, crfun, rowmodel, colmodel, colprune, dbglvl, nclusters, part_sv, ptree_sv, tsims_sv, gains_sv)
    int matrix_type
    int nrows
    int ncols
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int simfun
    int crfun
    int rowmodel
    int colmodel
    float colprune
    int dbglvl
    int nclusters
    SV* part_sv
    SV* ptree_sv
    SV* tsims_sv
    SV* gains_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;
    int *ptree;
    float *tsims;
    float *gains;

    /* prepare internal buffers */
    part = malloc_int(nrows);  
    ptree = malloc_int(2 * nrows);
    tsims = malloc_float(2 * nrows);
    gains = malloc_float(2 * nrows);

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    /* call API */
    CLUTO_VA_Cluster(nrows, ncols, rowptr, rowind, rowval,
                       simfun, crfun, rowmodel, colmodel, colprune, 
                       dbglvl, nclusters, part, ptree, tsims, gains);

    /* set sv* and free buffers */
    set_array_from_int(part_sv, part, nrows);
    free(part);
    set_array_from_int(ptree_sv, ptree, nrows * 2);
    free(ptree);
    set_array_from_float(tsims_sv, tsims, nrows * 2);
    free(tsims);
    set_array_from_float(gains_sv, gains, nrows * 2);
    free(gains);

    free(rowptr);
    free(rowind);
    free(rowval);
}

void
_VA_ClusterBiased(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, simfun, crfun, rowmodel, colmodel, colprune, dbglvl, npclusters, nclusters, part_sv, ptree_sv, tsims_sv, gains_sv)
    int matrix_type
    int nrows
    int ncols
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int simfun
    int crfun
    int rowmodel
    int colmodel
    float colprune
    int dbglvl
    int npclusters
    int nclusters
    SV* part_sv
    SV* ptree_sv
    SV* tsims_sv
    SV* gains_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;
    int *ptree;
    float *tsims;
    float *gains;

    /* prepare internal buffers */
    part = malloc_int(nrows);  
    ptree = malloc_int(2 * nrows);
    tsims = malloc_float(2 * nrows);
    gains = malloc_float(2 * nrows);

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    /* call API */
    CLUTO_VA_ClusterBiased(nrows, ncols, rowptr, rowind, rowval,
                       simfun, crfun, rowmodel, colmodel, colprune, 
                       dbglvl, npclusters, nclusters, part, ptree, tsims, gains);

    /* set sv* and free buffers */
    set_array_from_int(part_sv, part, nrows);
    free(part);
    set_array_from_int(ptree_sv, ptree, nrows * 2);
    free(ptree);
    set_array_from_float(tsims_sv, tsims, nrows * 2);
    free(tsims);
    set_array_from_float(gains_sv, gains, nrows * 2);
    free(gains);

    free(rowptr);
    free(rowind);
    free(rowval);
}

void
_SP_ClusterDirect(matrix_type, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, crfun, ntrials, niter, seed, dbglvl, nclusters, part_sv)
    int matrix_type
    int nrows
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int crfun
    int ntrials
    int niter
    int seed
    int dbglvl
    int nclusters
    SV* part_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;

    /* prepare internal buffers */
    part = malloc_int(nrows);  

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    /* call API */
    CLUTO_SP_ClusterDirect(nrows, rowptr, rowind, rowval, crfun,
                       ntrials, niter, seed, dbglvl, nclusters, part);

    /* set sv* and free buffers */
    set_array_from_int(part_sv, part, nrows);
    free(part);

    free(rowptr);
    free(rowind);
    free(rowval);
}

void
_SP_ClusterRB(matrix_type, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, crfun, ntrials, niter, seed, cstype, kwayrefine, dbglvl, nclusters, part_sv)
    int matrix_type
    int nrows
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int crfun
    int ntrials
    int niter
    int seed
    int cstype
    int kwayrefine
    int dbglvl
    int nclusters
    SV* part_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;

    /* prepare internal buffers */
    part = malloc_int(nrows);  

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    /* call API */
    CLUTO_SP_ClusterRB(nrows, rowptr, rowind, rowval, crfun,
                       ntrials, niter, seed, cstype, kwayrefine,
                       dbglvl, nclusters, part);

    /* set sv* and free buffers */
    set_array_from_int(part_sv, part, nrows);
    free(part);

    free(rowptr);
    free(rowind);
    free(rowval);
}

int
_SP_GraphClusterRB(matrix_type, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, nnbrs, edgeprune, vtxprune, mincmp, ntrials, seed, cstype, dbglvl, nclusters, part_sv, crvalue_sv)
    int matrix_type
    int nrows
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int nnbrs
    float edgeprune
    float vtxprune
    int mincmp
    int ntrials
    int seed
    int cstype
    int dbglvl
    int nclusters
    SV* part_sv
    SV* crvalue_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;
    float crvalue;

    /* prepare internal buffers */
    part = malloc_int(nrows);

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    /* call API */
    RETVAL = CLUTO_SP_GraphClusterRB(nrows, rowptr, rowind, rowval,
                       nnbrs, edgeprune, vtxprune, mincmp,
                       ntrials, seed, cstype, 
                       dbglvl, nclusters, part, &crvalue);

    /* set sv* and free buffers */
    set_array_from_int(part_sv, part, nrows);
    free(part);
    sv_setnv(crvalue_sv, (double)crvalue);

    free(rowptr);
    free(rowind);
    free(rowval);
}
OUTPUT:
    RETVAL

void
_SA_Cluster(matrix_type, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, crfun, dbglvl, nclusters, part_sv, ptree_sv, tsims_sv, gains_sv)
    int matrix_type
    int nrows
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int crfun
    int dbglvl
    int nclusters
    SV* part_sv
    SV* ptree_sv
    SV* tsims_sv
    SV* gains_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;
    int *ptree;
    float *tsims;
    float *gains;

    /* prepare internal buffers */
    part = malloc_int(nrows);  
    ptree = malloc_int(2 * nrows);
    tsims = malloc_float(2 * nrows);
    gains = malloc_float(2 * nrows);

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    /* call API */
    CLUTO_SA_Cluster(nrows, rowptr, rowind, rowval, crfun,
                       dbglvl, nclusters, part, ptree, tsims, gains);

    /* set sv* and free buffers */
    set_array_from_int(part_sv, part, nrows);
    free(part);
    set_array_from_int(ptree_sv, ptree, nrows * 2);
    free(ptree);
    set_array_from_float(tsims_sv, tsims, nrows * 2);
    free(tsims);
    set_array_from_float(gains_sv, gains, nrows * 2);
    free(gains);

    free(rowptr);
    free(rowind);
    free(rowval);
}

void
_V_BuildTree(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, simfun, crfun, rowmodel, colmodel, colprune, treetype, dbglvl, nclusters, part_sv, ptree_sv, tsims_sv, gains_sv)
    int matrix_type
    int nrows
    int ncols
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int simfun
    int crfun
    int rowmodel
    int colmodel
    float colprune
    int treetype    
    int dbglvl
    int nclusters
    SV* part_sv
    SV* ptree_sv
    SV* tsims_sv
    SV* gains_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;
    int *ptree;
    float *tsims;
    float *gains;

    /* prepare internal buffers */
    ptree = malloc_int((treetype == CLUTO_TREE_TOP ? 2 * nclusters : 2 * nrows));
    tsims = malloc_float((treetype == CLUTO_TREE_TOP ? 2 * nclusters : 2 * nrows));
    gains = malloc_float((treetype == CLUTO_TREE_TOP ? 2 * nclusters : 2 * nrows));

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    part = make_int_array(part_sv, nrows);

    /* call API */
    CLUTO_V_BuildTree(nrows, ncols, rowptr, rowind, rowval, simfun, 
                      crfun, rowmodel, colmodel, colprune, treetype,
                      dbglvl, nclusters, part, ptree, tsims, gains);

    /* set sv* and free buffers */
    set_array_from_int(ptree_sv, ptree, (treetype == CLUTO_TREE_TOP ? 2 * nclusters : 2 * nrows));
    free(ptree);
    set_array_from_float(tsims_sv, tsims, (treetype == CLUTO_TREE_TOP ? 2 * nclusters : 2 * nrows));
    free(tsims);
    set_array_from_float(gains_sv, gains, (treetype == CLUTO_TREE_TOP ? 2 * nclusters : 2 * nrows));
    free(gains);

    free(rowptr);
    free(rowind);
    free(rowval);
    free(part);
}

void
_S_BuildTree(matrix_type, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, crfun, treetype, dbglvl, nclusters, part_sv, ptree_sv, tsims_sv, gains_sv)
    int matrix_type
    int nrows
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int crfun
    int treetype    
    int dbglvl
    int nclusters
    SV* part_sv
    SV* ptree_sv
    SV* tsims_sv
    SV* gains_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;
    int *ptree;
    float *tsims;
    float *gains;

    /* prepare internal buffers */
    ptree = malloc_int((treetype == CLUTO_TREE_TOP ? 2 * nclusters : 2 * nrows));
    tsims = malloc_float((treetype == CLUTO_TREE_TOP ? 2 * nclusters : 2 * nrows));
    gains = malloc_float((treetype == CLUTO_TREE_TOP ? 2 * nclusters : 2 * nrows));

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    part = make_int_array(part_sv, nrows);

    /* call API */
    CLUTO_S_BuildTree(nrows, rowptr, rowind, rowval, crfun, treetype,
                      dbglvl, nclusters, part, ptree, tsims, gains);

    /* set sv* and free buffers */
    set_array_from_int(ptree_sv, ptree, (treetype == CLUTO_TREE_TOP ? 2 * nclusters : 2 * nrows));
    free(ptree);
    set_array_from_float(tsims_sv, tsims, (treetype == CLUTO_TREE_TOP ? 2 * nclusters : 2 * nrows));
    free(tsims);
    set_array_from_float(gains_sv, gains, (treetype == CLUTO_TREE_TOP ? 2 * nclusters : 2 * nrows));
    free(gains);

    free(rowptr);
    free(rowind);
    free(rowval);
    free(part);
}

void
_V_GetGraph(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, simfun, rowmodel, colmodel, colprune, grmodel, nnbrs, dbglvl, growptr_sv, growind_sv, growval_sv)
    int matrix_type
    int nrows
    int ncols
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int simfun
    int rowmodel
    int colmodel
    float colprune
    int grmodel
    int nnbrs
    int dbglvl
    SV* growptr_sv
    SV* growind_sv
    SV* growval_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *growptr;
    int *growind;
    float *growval;
    int n_growvals;

    /* prepare internal buffers */
    /* memory for growptr, growind, growval are allocated by the library */

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    /* call API */
    CLUTO_V_GetGraph(nrows, ncols, rowptr, rowind, rowval,
                     simfun, rowmodel, colmodel, colprune, grmodel,
                     nnbrs, dbglvl, &growptr, &growind, &growval);

    /* set sv* and free buffers */
    n_growvals = growptr[nrows];   
    /*** Darwin complains about double free(). shouldn't free them ?? ***/
    set_array_from_int(growptr_sv, growptr, nrows + 1);
    /* free(growptr); */
    set_array_from_int(growind_sv, growind, n_growvals);
    /* free(growind); */
    set_array_from_float(growval_sv, growval, n_growvals);
    /* free(growval); */
}

void
_S_GetGraph(matrix_type, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, grmodel, nnbrs, dbglvl, growptr_sv, growind_sv, growval_sv)
    int matrix_type
    int nrows
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int grmodel
    int nnbrs
    int dbglvl
    SV* growptr_sv
    SV* growind_sv
    SV* growval_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *growptr;
    int *growind;
    float *growval;
    int n_growvals;

    /* prepare internal buffers */
    /* memory for growptr, growind, growval are allocated by the library */

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    /* call API */
    CLUTO_S_GetGraph(nrows, rowptr, rowind, rowval, grmodel,
                     nnbrs, dbglvl, &growptr, &growind, &growval);

    /* set sv* and free buffers */
    n_growvals = growptr[nrows];
    /*** Darwin complains about double free(). shouldn't free them ?? ***/
    set_array_from_int(growptr_sv, growptr, nrows + 1);
    /* free(growptr);*/
    set_array_from_int(growind_sv, growind, n_growvals);
    /* free(growind);*/
    set_array_from_float(growval_sv, growval, n_growvals);
    /* free(growval);*/
}

float
_V_GetSolutionQuality(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, simfun, crfun, rowmodel, colmodel, colprune, nclusters, part_sv)
    int matrix_type
    int nrows
    int ncols
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int simfun
    int crfun
    int rowmodel
    int colmodel
    float colprune
    int nclusters
    SV* part_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;

    /* prepare internal buffers */

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    part = make_int_array(part_sv, nrows);

    /* call API */
    RETVAL =CLUTO_V_GetSolutionQuality(nrows, ncols, rowptr, rowind, rowval,
                               simfun, crfun, rowmodel, colmodel, colprune, 
                               nclusters, part);

    /* set sv* and free buffers */
    set_array_from_int(part_sv, part, nrows);
    free(part);

    free(rowptr);
    free(rowind);
    free(rowval);
}
OUTPUT:
    RETVAL

float
_S_GetSolutionQuality(matrix_type, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, crfun, nclusters, part_sv)
    int matrix_type
    int nrows
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int crfun
    int nclusters
    SV* part_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;

    /* prepare internal buffers */

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    part = make_int_array(part_sv, nrows);

    /* call API */
    RETVAL = CLUTO_S_GetSolutionQuality(nrows, rowptr, rowind, rowval, crfun,
                               nclusters, part);

    /* set sv* and free buffers */
    free(rowptr);
    free(rowind);
    free(rowval);
    free(part);
}
OUTPUT:
    RETVAL

void
_V_GetClusterStats(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, simfun, rowmodel, colmodel, colprune, nclusters, part_sv, pwgts_sv, cintsim_sv, cintsdev_sv, izscores_sv, cextsim_sv, cextsdev_sv, ezscores_sv)
    int matrix_type
    int nrows
    int ncols
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int simfun
    int rowmodel
    int colmodel
    float colprune
    int nclusters
    SV* part_sv
    SV* pwgts_sv
    SV* cintsim_sv
    SV* cintsdev_sv
    SV* izscores_sv
    SV* cextsim_sv
    SV* cextsdev_sv
    SV* ezscores_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;
    int *pwgts;
    float *cintsim;
    float *cintsdev;
    float *izscores;
    float *cextsim;
    float *cextsdev;
    float *ezscores;

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    part = make_int_array(part_sv, nrows);

    /* prepare internal buffers */
    pwgts = malloc_int(nclusters);
    cintsim = malloc_float(nclusters);
    cintsdev = malloc_float(nclusters);
    izscores = malloc_float(nrows);
    cextsim = malloc_float(nclusters);
    cextsdev = malloc_float(nclusters);
    ezscores = malloc_float(nrows);

    /* call API */
    CLUTO_V_GetClusterStats(nrows, ncols, rowptr, rowind, rowval,
                            simfun, rowmodel, colmodel, colprune, nclusters, 
                            part, pwgts, cintsim, cintsdev, izscores, 
                            cextsim, cextsdev, ezscores);

    /* set sv* and free buffers */
    set_array_from_int(pwgts_sv, pwgts, nclusters);
    free(pwgts);
    set_array_from_float(cintsim_sv, cintsim, nclusters);
    free(cintsim);
    set_array_from_float(cintsdev_sv, cintsdev, nclusters);
    free(cintsdev);
    set_array_from_float(izscores_sv, izscores, nrows);
    free(izscores);
    set_array_from_float(cextsim_sv, cextsim, nclusters);
    free(cextsim);
    set_array_from_float(cextsdev_sv, cextsdev, nclusters);
    free(cextsdev);
    set_array_from_float(ezscores_sv, ezscores, nrows);
    free(ezscores);

    free(rowptr);
    free(rowind);
    free(rowval);
    free(part);
}

void
_S_GetClusterStats(matrix_type, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, nclusters, part_sv, pwgts_sv, cintsim_sv, cintsdev_sv, izscores_sv, cextsim_sv, cextsdev_sv, ezscores_sv)
    int matrix_type
    int nrows
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int nclusters
    SV* part_sv
    SV* pwgts_sv
    SV* cintsim_sv
    SV* cintsdev_sv
    SV* izscores_sv
    SV* cextsim_sv
    SV* cextsdev_sv
    SV* ezscores_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;
    int *pwgts;
    float *cintsim;
    float *cintsdev;
    float *izscores;
    float *cextsim;
    float *cextsdev;
    float *ezscores;

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, nrows, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    part = make_int_array(part_sv, nrows);

    /* prepare internal buffers */
    pwgts = malloc_int(nclusters);
    cintsim = malloc_float(nclusters);
    cintsdev = malloc_float(nclusters);
    izscores = malloc_float(nrows);
    cextsim = malloc_float(nclusters);
    cextsdev = malloc_float(nclusters);
    ezscores = malloc_float(nrows);

    /* call API */
    CLUTO_S_GetClusterStats(nrows, rowptr, rowind, rowval, nclusters,
                            part, pwgts, cintsim, cintsdev, izscores, 
                            cextsim, cextsdev, ezscores);

    /* set sv* and free buffers */
    set_array_from_int(pwgts_sv, pwgts, nclusters);
    free(pwgts);
    set_array_from_float(cintsim_sv, cintsim, nclusters);
    free(cintsim);
    set_array_from_float(cintsdev_sv, cintsdev, nclusters);
    free(cintsdev);
    set_array_from_float(izscores_sv, izscores, nrows);
    free(izscores);
    set_array_from_float(cextsim_sv, cextsim, nclusters);
    free(cextsim);
    set_array_from_float(cextsdev_sv, cextsdev, nclusters);
    free(cextsdev);
    set_array_from_float(ezscores_sv, ezscores, nrows);
    free(ezscores);

    free(rowptr);
    free(rowind);
    free(rowval);
    free(part);
}

void
_V_GetClusterFeatures(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, simfun, rowmodel, colmodel, colprune, nclusters, part_sv, nfeatures, internalids_sv, internalwgts_sv, externalids_sv, externalwgts_sv)
    int matrix_type
    int nrows
    int ncols
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int simfun
    int rowmodel
    int colmodel
    float colprune
    int nclusters
    SV* part_sv
    int nfeatures
    SV* internalids_sv
    SV* internalwgts_sv
    SV* externalids_sv
    SV* externalwgts_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;
    int *internalids;
    float *internalwgts;
    int *externalids;
    float *externalwgts;

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    part = make_int_array(part_sv, nrows);
 
    /* prepare internal buffers */
    internalids = malloc_int(nclusters * nfeatures);
    internalwgts = malloc_float(nclusters * nfeatures);
    externalids = malloc_int(nclusters * nfeatures);
    externalwgts = malloc_float(nclusters * nfeatures);

    /* call API */
    CLUTO_V_GetClusterFeatures(nrows, ncols, rowptr, rowind, rowval,
                            simfun, rowmodel, colmodel, colprune, nclusters, 
                            part, nfeatures, internalids, internalwgts,
                            externalids, externalwgts);

    /* set sv* and free buffers */

    set_array_from_int(internalids_sv, internalids, nclusters * nfeatures);
    free(internalids);
    set_array_from_float(internalwgts_sv, internalwgts, nclusters * nfeatures);
    free(internalwgts);
    set_array_from_int(externalids_sv, externalids, nclusters * nfeatures);
    free(externalids);
    set_array_from_float(externalwgts_sv, externalwgts, nclusters * nfeatures);
    free(externalwgts);

    free(rowptr);
    free(rowind);
    free(rowval);
    free(part);
}

void
_V_GetClusterSummaries(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, simfun, rowmodel, colmodel, colprune, nclusters, part_sv, sumtype, nfeatures, r_nsum_sv, r_spid_sv, r_swgt_sv, r_sumptr_sv, r_sumind_sv)
    int matrix_type
    int nrows
    int ncols
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int simfun
    int rowmodel
    int colmodel
    float colprune
    int nclusters
    SV* part_sv
    int sumtype
    int nfeatures
    SV* r_nsum_sv
    SV* r_spid_sv
    SV* r_swgt_sv
    SV* r_sumptr_sv
    SV* r_sumind_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;
    int r_nsum;
    int *r_spid;
    float *r_swgt;
    int *r_sumptr;
    int *r_sumind;

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    part = make_int_array(part_sv, nrows);
 
    /* prepare internal buffers */
    /* memory for r_spid, r_swgt, r_sumptr, r_sumind are allocated by the library */

    /* call API */
    CLUTO_V_GetClusterSummaries(nrows, ncols, rowptr, rowind, rowval,
                                simfun, rowmodel, colmodel, colprune, nclusters, 
                                part, sumtype, nfeatures, &r_nsum, &r_spid,
                                &r_swgt, &r_sumptr, &r_sumind);

    /* set sv* and free buffers */
    sv_setnv(r_nsum_sv, (double)r_nsum);    
    /*** Darwin complains about double free(). shouldn't free them ?? ***/
    set_array_from_int(r_spid_sv, r_spid, r_nsum);
    /* free(r_spid); */
    set_array_from_float(r_swgt_sv, r_swgt, r_nsum);
    /* free(r_swgt); */
    set_array_from_int(r_sumptr_sv, r_sumptr, r_nsum + 1);
    /* free(r_sumptr); */
    set_array_from_int(r_sumind_sv, r_sumind, r_sumptr[r_nsum]);
    /* free(r_sumind); */

    free(rowptr);
    free(rowind);
    free(rowval);
    free(part);
}

void
_V_GetTreeStats(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, simfun, rowmodel, colmodel, colprune, nclusters, part_sv, ptree_sv, pwgts_sv, cintsim_sv, cextsim_sv)
    int matrix_type
    int nrows
    int ncols
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int simfun
    int rowmodel
    int colmodel
    float colprune
    int nclusters
    SV* part_sv
    SV* ptree_sv
    SV* pwgts_sv
    SV* cintsim_sv
    SV* cextsim_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;
    int *ptree;
    int *pwgts;
    float *cintsim;
    float *cextsim;

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    part = make_int_array(part_sv, nrows);
    ptree = make_int_array(ptree_sv, 2 * nclusters);

    /* prepare internal buffers */
    pwgts = malloc_int(2 * nclusters);
    cintsim = malloc_float(2 * nclusters);
    cextsim = malloc_float(2 * nclusters);

    /* call API */
    CLUTO_V_GetTreeStats(nrows, ncols, rowptr, rowind, rowval,
                         simfun, rowmodel, colmodel, colprune, nclusters, 
                         part, ptree, pwgts, cintsim, cextsim);

    /* set sv* and free buffers */
    set_array_from_int(pwgts_sv, pwgts, 2 * nclusters);
    free(pwgts);
    set_array_from_float(cintsim_sv, cintsim, 2 * nclusters);
    free(cintsim);
    set_array_from_float(cextsim_sv, cextsim, 2 * nclusters);
    free(cextsim);

    free(rowptr);
    free(rowind);
    free(rowval);
    free(part);
    free(ptree);
}

void
_V_GetTreeFeatures(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, simfun, rowmodel, colmodel, colprune, nclusters, part_sv, ptree_sv, nfeatures, internalids_sv, internalwgts_sv, externalids_sv, externalwgts_sv)
    int matrix_type
    int nrows
    int ncols
    int nnz
    SV* rowptr_sv
    SV* rowind_sv
    SV* rowval_sv
    int simfun
    int rowmodel
    int colmodel
    float colprune
    int nclusters
    SV* part_sv
    SV* ptree_sv
    int nfeatures
    SV* internalids_sv
    SV* internalwgts_sv
    SV* externalids_sv
    SV* externalwgts_sv
  CODE:
{
    int *rowptr;
    int *rowind;
    float *rowval;
    int *part;
    int *ptree;
    int *internalids;
    float *internalwgts;
    int *externalids;
    float *externalwgts;

    /* set necessary values from sv* */
    prepare_matrix(matrix_type, nrows, ncols, nnz, rowptr_sv, rowind_sv, rowval_sv, 
                   &rowptr, &rowind, &rowval);

    part = make_int_array(part_sv, nrows);
    ptree = make_int_array(ptree_sv, 2 * nclusters);

    /* prepare internal buffers */
    internalids = malloc_int(2 * nclusters * nfeatures);
    internalwgts = malloc_float(2 * nclusters * nfeatures);
    externalids = malloc_int(2 * nclusters * nfeatures);
    externalwgts = malloc_float(2 * nclusters * nfeatures);


    /* call API */
    CLUTO_V_GetTreeFeatures(nrows, ncols, rowptr, rowind, rowval,
                            simfun, rowmodel, colmodel, colprune, nclusters, 
                            part, ptree, nfeatures, internalids, internalwgts,
                            externalids, externalwgts);

    /* set sv* and free buffers */
    set_array_from_int(internalids_sv, internalids, 2 * nclusters * nfeatures);
    free(internalids);
    set_array_from_float(internalwgts_sv, internalwgts, 2 * nclusters * nfeatures);
    free(internalwgts);
    set_array_from_int(externalids_sv, externalids, 2 * nclusters * nfeatures);
    free(externalids);
    set_array_from_float(externalwgts_sv, externalwgts, 2 * nclusters * nfeatures);
    free(externalwgts);

    free(rowptr);
    free(rowind);
    free(rowval);
    free(part);
    free(ptree);
}
