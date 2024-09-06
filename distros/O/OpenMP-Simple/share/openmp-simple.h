/**
All setters EXCEPT the LOCK routines,
  as defined at https://gcc.gnu.org/onlinedocs/libgomp/Runtime-Library-Routines.html

   Status                              GCC*     Description
+-------------------------------------------------------------------------------------------+
 - DONE   omp_set_num_threads          8.3.0  – Set upper team size limit
 - DONE   omp_set_schedule             8.3.0  – Set the runtime scheduling method
 - DONE   omp_set_dynamic              8.3.0  – Enable/disable dynamic teams
 - DONE   omp_set_nested               8.3.0  – Enable/disable nested parallel regions
 - DONE   omp_set_max_active_levels    8.3.0  – Limits the number of active parallel regions
 - DONE   omp_set_default_device       8.3.0  – Set the default device for target regions
 - DONE   omp_set_num_teams           12.3.0  – Set upper teams limit for teams construct
 - DONE   omp_set_teams_thread_limit  12.3.0  – Set upper thread limit for teams construct
+-------------------------------------------------------------------------------------------+
**/

/* %ENV Update Macros                                      */

#define PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE             \
    char *num1 = getenv("OMP_DEFAULT_DEVICE");              \
    if (num1 != NULL) {                                     \
      omp_set_default_device(atoi(num1));                   \
    }

#define PerlOMP_UPDATE_WITH_ENV__TEAMS_THREAD_LIMIT         \
    char *num2 = getenv("OMP_TEAMS_THREAD_LIMIT");          \
    if (num2 != NULL) {                                     \
      omp_set_teams_thread_limit(atoi(num2));               \
    }

#define PerlOMP_UPDATE_WITH_ENV__NUM_TEAMS                  \
    char *num3 = getenv("OMP_NUM_TEAMS");                   \
    if (num3 != NULL) {                                     \
      omp_set_num_teams(atoi(num3));                        \
    }

#define PerlOMP_UPDATE_WITH_ENV__MAX_ACTIVE_LEVELS          \
    char *num4 = getenv("OMP_MAX_ACTIVE_LEVELS");           \
    if (num4 != NULL) {                                     \
      omp_set_max_active_levels(atoi(num4));                \
    }

#define PerlOMP_UPDATE_WITH_ENV__NUM_THREADS                \
    char *num5 = getenv("OMP_NUM_THREADS");                 \
    if (num5 != NULL) {                                     \
      omp_set_num_threads(atoi(num5));                      \
    }

#define PerlOMP_UPDATE_WITH_ENV__DYNAMIC                    \
    char *VALUE1 = getenv("OMP_DYNAMIC");                   \
    if (VALUE1 == NULL) {                                   \
      omp_set_dynamic(VALUE1);                              \
    }                                                       \
    else if (strcmp(VALUE1,"TRUE") || strcmp(VALUE1,"true") || strcmp(VALUE1,"1")) { \
      omp_set_dynamic(1);                                   \
    }                                                       \
    else {                                                  \
      omp_set_dynamic(NULL);                                \
    }

#define PerlOMP_UPDATE_WITH_ENV__NESTED                     \
    char *VALUE = getenv("OMP_NESTED");                     \
    if (VALUE == NULL) {                                    \
      omp_set_nested(VALUE);                                \
    }                                                       \
    else if (strcmp(VALUE,"TRUE") || strcmp(VALUE,"true") || strcmp(VALUE,"1")) { \
      omp_set_nested(1);                                    \
    }                                                       \
    else {                                                  \
      omp_set_nested(NULL);                                 \
    };

#define PerlOMP_UPDATE_WITH_ENV__SCHEDULE                   \
    char *str = getenv("OMP_SCHEDULE");                     \
    if (str != NULL) {                                      \
      omp_sched_t SCHEDULE = omp_sched_static;              \
      int CHUNK = 1; char *pt;                              \
      pt = strtok (str,",");                                \
      if (strcmp(pt,"static")) {                            \
        SCHEDULE = omp_sched_static;                        \
      }                                                     \
      else if (strcmp(pt,"dynamic")) {                      \
        SCHEDULE = omp_sched_dynamic;                       \
      }                                                     \
      else if (strcmp(pt,"guided")) {                       \
        SCHEDULE = omp_sched_guided;                        \
      }                                                     \
      else if (strcmp(pt,"auto")) {                         \
        SCHEDULE = omp_sched_auto;                          \
      }                                                     \
      pt = strtok (NULL, ",");                              \
      if (pt != NULL) {                                     \
        CHUNK = atoi(pt);                                   \
      }                                                     \
      omp_set_schedule(SCHEDULE, CHUNK);                    \
    }

/* bundled Macros */
#define PerlOMP_GETENV_BASIC                                \
    PerlOMP_UPDATE_WITH_ENV__NUM_THREADS                    \
    PerlOMP_UPDATE_WITH_ENV__SCHEDULE

#define PerlOMP_GETENV_ALL                                  \
    PerlOMP_UPDATE_WITH_ENV__DEFAULT_DEVICE                 \
    PerlOMP_UPDATE_WITH_ENV__TEAMS_THREAD_LIMIT             \
    PerlOMP_UPDATE_WITH_ENV__NUM_TEAMS                      \
    PerlOMP_UPDATE_WITH_ENV__MAX_ACTIVE_LEVELS              \
    PerlOMP_UPDATE_WITH_ENV__NUM_THREADS                    \
    PerlOMP_UPDATE_WITH_ENV__DYNAMIC                        \
    PerlOMP_UPDATE_WITH_ENV__NESTED                         \
    PerlOMP_UPDATE_WITH_ENV__SCHEDULE

// ... add all of them from OpenMP::Environment, add unit tests

/* Output Init Macros (needed?) */
#define PerlOMP_RET_ARRAY_REF_ret AV* ret = newAV();sv_2mortal((SV*)ret);

/* Datastructure Introspection Functions*/

/**
 * Returns the number of elements in a 1D array from Perl
 */

int PerlOMP_1D_Array_NUM_ELEMENTS (SV *AVref) {
  return av_count((AV*)SvRV(AVref));
}

/* Datatype Converters (doxygen style comments) */

/**
 * Converts a 1D Perl Array Reference (AV*) into a 1D C array of floats; allocates retArray[numElements] by reference
 * @param[in] *Aref, int numElements, float retArray[numElements]
 * @param[out] void
 */

void PerlOMP_1D_Array_TO_1D_FLOAT_ARRAY(SV *AVref, int numElements, float retArray[numElements]) {
  AV *array    = (AV*)SvRV(AVref);
  SV **element;
  for (int i=0; i<numElements;i++) {
    element = av_fetch(array, i, 0);
    if (!element || !*element || !SvOK(*element))
      croak("Expected value at array[%d]", i);
    retArray[i] = SvNV(*element);
  }
}

/* 1D Array reference to 1D int C array ...
 * Convert a regular M-element Perl array consisting of inting point values, e.g.,
 *
 *   my $Aref = [ 10, 314, 527, 911, 538 ];
 *
 * into a C array of the same dimensions so that it can be used as exepcted with an OpenMP
 * "#pragma omp for" work sharing construct
*/

void PerlOMP_1D_Array_TO_1D_INT_ARRAY(SV *AVref, int numElements, int retArray[numElements]) {
  AV *array    = (AV*)SvRV(AVref);
  SV **element;
  for (int i=0; i<numElements;i++) {
    element = av_fetch(array, i, 0);
    if (!element || !*element || !SvOK(*element))
      croak("Expected value at array[%d]", i);
    retArray[i] = SvIV(*element);
  }
}

/* 2D AoA to 2D float C array ...
 * Convert a regular MxN Perl array of arrays (AoA) consisting of floating point values, e.g.,
 *
 *   my $AoA = [ [qw/1.01 2.02 3.03/], [qw/3.145 2.123 0.892/], [qw/19.17 60.651 20.17/] ];
 *
 * into a C array of the same dimensions so that it can be used as expected with an OpenMP
 * "#pragma omp for" work sharing construct
*/

// contribued by CPAN's NERDVANA - thank you!
void PerlOMP_2D_AoA_TO_2D_FLOAT_ARRAY(SV *AoA, int numRows, int rowSize, float retArray[numRows][rowSize]) {
  SV **AVref;
  if (!SvROK(AoA) || SvTYPE(SvRV(AoA)) != SVt_PVAV)
    croak("Expected Arrayref");
  for (int i=0; i<numRows; i++) {
    AVref = av_fetch((AV*)SvRV(AoA), i, 0);
    if (!AVref || !*AVref || !SvROK(*AVref) || SvTYPE(SvRV(*AVref)) != SVt_PVAV)
      croak("Expected arrayref at array[%d]", i);
    for (int j=0; j<rowSize;j++) {
      SV **element = av_fetch((AV*)SvRV(*AVref), j, 0);
      if (!element || !*element || !SvOK(*element))
        croak("Expected value at array[%d][%d]", i, j);
      retArray[i][j] = SvNV(*element);
    }
  }
}

/* 2D AoA to 2D int C array ...
 * Convert a regular MxN Perl array of arrays (AoA) consisting of inting point values, e.g.,
 *
 *   my $AoA = [ [qw/101 202 303/], [qw/3145 2123 892/], [qw/1917 60.651 2017/] ];
 *
 * into a C array of the same dimensions so that it can be used as expected with an OpenMP
 * "#pragma omp for" work sharing construct
*/

void PerlOMP_2D_AoA_TO_2D_INT_ARRAY(SV *AoA, int numRows, int rowSize, int retArray[numRows][rowSize]) {
  SV **AVref;
  if (!SvROK(AoA) || SvTYPE(SvRV(AoA)) != SVt_PVAV)
    croak("Expected Arrayref");
  for (int i=0; i<numRows; i++) {
    AVref = av_fetch((AV*)SvRV(AoA), i, 0);
    if (!AVref || !*AVref || !SvROK(*AVref) || SvTYPE(SvRV(*AVref)) != SVt_PVAV)
      croak("Expected arrayref at array[%d]", i);
    for (int j=0; j<rowSize;j++) {
      SV **element = av_fetch((AV*)SvRV(*AVref), j, 0);
      if (!element || !*element || !SvOK(*element))
        croak("Expected value at array[%d][%d]", i, j);
      retArray[i][j] = SvNV(*element);
    }
  }
}

/* TODO:
  * add unit tests for conversion functions
  * add some basic matrix operations (transpose for 2D, reverse for 1D)
  * experiment with simple hash ref to C struct
 * ...
*/

