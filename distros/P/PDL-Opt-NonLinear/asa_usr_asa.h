#ifndef _ASA_USER_ASA_H_
#define _ASA_USER_ASA_H_
#ifdef __cplusplus
extern "C" {
#endif

/***********************************************************************
* Adaptive Simulated Annealing (ASA)
* Lester Ingber <ingber@ingber.com>
* Copyright (c) 1993-2005 Lester Ingber.  All Rights Reserved.
* The LICENSE file must be included with ASA code.
***********************************************************************/

  /* $Id: asa_usr_asa.h,v 25.27 2005/04/03 17:44:58 ingber Exp ingber $ */

  /* asa_usr_asa.h for Adaptive Simulated Annealing */

#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>             /* misc defs on most machines */
#include <string.h>
/* required if use machine-defined {DBL_EPSILON DBL_MIN DBL_MAX} */
/* #include <float.h> */

/* test for memory leaks */
/* #include "/usr/local/include/leak.h" */

#define	ASATRUE			1
#define	ASAFALSE			0

#define ASAMIN(x,y)	((x) < (y) ? (x) : (y))
#define ASAMAX(x,y)	((x) > (y) ? (x) : (y))

  /* DEFAULT PARAMETERS SETTINGS */

  /* Pre-Compile Options */

  /* Special ASA_TEMPLATEs */

#ifndef MY_TEMPLATE
#define MY_TEMPLATE ASAFALSE
#endif
#if MY_TEMPLATE                 /* MY_TEMPLATE_asa_user */
  /* you can add your own set of #define here */
#endif                          /* MY_TEMPLATE */

#ifndef ASA_TEMPLATE_LIB
#define ASA_TEMPLATE_LIB ASAFALSE
#endif
#if ASA_TEMPLATE_LIB
#define ASA_LIB ASATRUE
#define ASA_TEST ASATRUE
#endif

#ifndef ASA_TEMPLATE_ASA_OUT_PID
#define ASA_TEMPLATE_ASA_OUT_PID ASAFALSE
#endif
#if ASA_TEMPLATE_ASA_OUT_PID
#define USER_ASA_OUT ASATRUE
#endif

#ifndef ASA_TEMPLATE_MULTIPLE
#define ASA_TEMPLATE_MULTIPLE ASAFALSE
#endif
#if ASA_TEMPLATE_MULTIPLE
#define COST_FILE ASAFALSE
#define USER_ASA_OUT ASATRUE
#define ASA_TEST ASATRUE
#define QUENCH_COST ASATRUE
#define QUENCH_PARAMETERS ASATRUE
#define OPTIONS_FILE ASAFALSE
#endif

#ifndef ASA_TEMPLATE_SELFOPT
#define ASA_TEMPLATE_SELFOPT ASAFALSE
#endif
#if ASA_TEMPLATE_SELFOPT
#define COST_FILE ASAFALSE
#define SELF_OPTIMIZE ASATRUE
#define OPTIONAL_DATA_DBL ASATRUE
#define USER_ASA_OUT ASATRUE
#define ASA_TEST ASATRUE
#define OPTIONS_FILE ASAFALSE
#endif

#ifndef ASA_TEMPLATE_SAMPLE
#define ASA_TEMPLATE_SAMPLE ASAFALSE
#endif
#if ASA_TEMPLATE_SAMPLE
#define COST_FILE ASAFALSE
#define ASA_SAMPLE ASATRUE
#define USER_ACCEPTANCE_TEST ASATRUE
#define USER_COST_SCHEDULE ASATRUE
#define OPTIONS_FILE_DATA ASAFALSE
#define USER_ACCEPT_ASYMP_EXP ASATRUE
#endif

#ifndef ASA_TEMPLATE_PARALLEL
#define ASA_TEMPLATE_PARALLEL ASAFALSE
#endif
#if ASA_TEMPLATE_PARALLEL
#define COST_FILE ASAFALSE
#define ASA_TEST ASATRUE
#define ASA_PARALLEL ASATRUE
#endif

#ifndef ASA_TEMPLATE_SAVE
#define ASA_TEMPLATE_SAVE ASAFALSE
#endif
#if ASA_TEMPLATE_SAVE
#define COST_FILE ASAFALSE
#define ASA_TEST ASATRUE
#define ASA_SAVE ASATRUE
#define QUENCH_PARAMETERS ASATRUE
#define QUENCH_COST ASATRUE
#endif

#ifndef ASA_TEMPLATE_QUEUE
#define ASA_TEMPLATE_QUEUE ASAFALSE
#endif
#if ASA_TEMPLATE_QUEUE
#define ASA_QUEUE ASATRUE
#define ASA_RESOLUTION ASAFALSE
#define ASA_TEST ASATRUE
#define COST_FILE ASAFALSE
#define ASA_PRINT_MORE ASATRUE
#endif

#ifndef ASA_TEST_POINT
#define ASA_TEST_POINT ASAFALSE
#endif
#if ASA_TEST_POINT
#define ASA_TEST ASATRUE
#define COST_FILE ASAFALSE
#define SMALL_FLOAT 1.0E-50
#define QUENCH_COST ASATRUE
#endif

  /* Standard Pre-Compile Options */

#ifndef USER_COST_FUNCTION
#define USER_COST_FUNCTION cost_function
#endif

#if SELF_OPTIMIZE
#ifndef RECUR_USER_COST_FUNCTION
#define RECUR_USER_COST_FUNCTION recur_cost_function
#endif
#ifndef INCL_STDOUT
#define INCL_STDOUT ASAFALSE
#endif
#endif

#ifndef INCL_STDOUT
#define INCL_STDOUT ASATRUE
#endif
#if INCL_STDOUT
#ifndef TIME_CALC
#define TIME_CALC ASAFALSE
#endif
#endif

#ifndef OPTIONS_FILE
#define OPTIONS_FILE ASAFALSE
#endif

#if OPTIONS_FILE
#ifndef OPTIONS_FILE_DATA
#define OPTIONS_FILE_DATA ASAFALSE
#endif
#else
#define OPTIONS_FILE_DATA ASAFALSE
#endif

#ifndef RECUR_OPTIONS_FILE
#define RECUR_OPTIONS_FILE ASAFALSE
#endif

#if RECUR_OPTIONS_FILE
#ifndef RECUR_OPTIONS_FILE_DATA
#define RECUR_OPTIONS_FILE_DATA ASAFALSE
#endif
#else
#define RECUR_OPTIONS_FILE_DATA ASAFALSE
#endif

#ifndef COST_FILE
#define COST_FILE ASAFALSE
#endif

#ifndef ASA_LIB
#define ASA_LIB ASATRUE
#endif

#ifndef HAVE_ANSI
#define HAVE_ANSI ASATRUE
#endif

#ifndef IO_PROTOTYPES
#define IO_PROTOTYPES ASAFALSE
#endif

#ifndef TIME_CALC
#define TIME_CALC ASAFALSE
#endif

#ifndef INT_LONG
#define INT_LONG ASAFALSE
#endif

#if INT_LONG
#define LONG_INT long int
#else
#define LONG_INT int
#endif

#ifndef INT_ALLOC
#define INT_ALLOC ASAFALSE
#endif

#if INT_ALLOC
#define ALLOC_INT int
#else
#define ALLOC_INT LONG_INT
#endif

  /* You can define SMALL_FLOAT to better correlate to your machine's
     precision, i.e., as used in asa */
#ifndef SMALL_FLOAT
#define SMALL_FLOAT 1.0E-18
#endif

  /* You can define your machine's maximum and minimum doubles here */
#ifndef MIN_DOUBLE
#define MIN_DOUBLE ((double) SMALL_FLOAT)
#endif

#ifndef MAX_DOUBLE
#define MAX_DOUBLE ((double) 1.0 / (double) SMALL_FLOAT)
#endif

#ifndef EPS_DOUBLE
#define EPS_DOUBLE ((double) SMALL_FLOAT)
#endif

#ifndef CHECK_EXPONENT
#define CHECK_EXPONENT ASAFALSE
#endif

#ifndef ASA_TEST
#define ASA_TEST ASAFALSE
#endif

#ifndef ASA_TEMPLATE
#define ASA_TEMPLATE ASAFALSE
#endif

#ifndef USER_INITIAL_COST_TEMP
#define USER_INITIAL_COST_TEMP ASAFALSE
#endif

#ifndef RATIO_TEMPERATURE_SCALES
#define RATIO_TEMPERATURE_SCALES ASAFALSE
#endif

#ifndef USER_INITIAL_PARAMETERS_TEMPS
#define USER_INITIAL_PARAMETERS_TEMPS ASAFALSE
#endif

#ifndef DELTA_PARAMETERS
#define DELTA_PARAMETERS ASAFALSE
#endif

#ifndef QUENCH_PARAMETERS
#define QUENCH_PARAMETERS ASATRUE
#endif

#ifndef QUENCH_COST
#define QUENCH_COST ASATRUE
#endif

#ifndef QUENCH_PARAMETERS_SCALE
#define QUENCH_PARAMETERS_SCALE ASATRUE
#endif

#ifndef QUENCH_COST_SCALE
#define QUENCH_COST_SCALE ASATRUE
#endif

#ifndef OPTIONAL_DATA_DBL
#define OPTIONAL_DATA_DBL ASAFALSE
#endif

#ifndef OPTIONAL_DATA_INT
#define OPTIONAL_DATA_INT ASAFALSE
#endif

#ifndef OPTIONAL_DATA_PTR
#define OPTIONAL_DATA_PTR ASAFALSE
#endif
#if OPTIONAL_DATA_PTR
/* user must define USER_TYPE; if a struct, it must be declared above */
#ifndef OPTIONAL_PTR_TYPE
#define OPTIONAL_PTR_TYPE USER_TYPE
#endif
#endif                          /* OPTIONAL_DATA_PTR */

#ifndef USER_REANNEAL_COST
#define USER_REANNEAL_COST ASAFALSE
#endif

#ifndef USER_REANNEAL_PARAMETERS
#define USER_REANNEAL_PARAMETERS ASAFALSE
#endif

#ifndef MAXIMUM_REANNEAL_INDEX
#define MAXIMUM_REANNEAL_INDEX 50000
#endif

#ifndef REANNEAL_SCALE
#define REANNEAL_SCALE 10
#endif

#ifndef USER_COST_SCHEDULE
#define USER_COST_SCHEDULE ASAFALSE
#endif

#ifndef USER_ACCEPT_ASYMP_EXP
#define USER_ACCEPT_ASYMP_EXP ASAFALSE
#endif

#ifndef USER_ACCEPT_THRESHOLD
#define USER_ACCEPT_THRESHOLD ASAFALSE
#endif

#ifndef USER_ACCEPTANCE_TEST
#define USER_ACCEPTANCE_TEST ASAFALSE
#endif

#ifndef USER_GENERATING_FUNCTION
#define USER_GENERATING_FUNCTION ASAFALSE
#endif

  /* in asa.c, field-width.precision = G_FIELD.G_PRECISION */
#ifndef G_FIELD
#define G_FIELD 12
#endif
#ifndef G_PRECISION
#define G_PRECISION 16
#endif

#define INTEGER_TYPE		((int) 1)
#define REAL_TYPE		((int) -1)
#define INTEGER_NO_REANNEAL	((int) 2)
#define REAL_NO_REANNEAL	((int) -2)

  /* Set this to ASATRUE to self-optimize the Program Options */
#ifndef SELF_OPTIMIZE
#define SELF_OPTIMIZE ASAFALSE
#endif

#ifndef USER_OUT
#define USER_OUT "asa_usr_out"
#endif

#ifndef USER_ASA_OUT
#define USER_ASA_OUT ASATRUE
#endif

#ifndef ASA_SAMPLE
#define ASA_SAMPLE ASAFALSE
#endif

#ifndef ASA_QUEUE
#define ASA_QUEUE ASATRUE
#endif

#ifndef ASA_RESOLUTION
#define ASA_RESOLUTION ASATRUE
#endif

#ifndef ASA_PARALLEL
#define ASA_PARALLEL ASAFALSE
#endif

#ifndef ASA_SAVE_OPT
#define ASA_SAVE_OPT ASAFALSE
#endif
#if ASA_SAVE_OPT
#define ASA_SAVE ASATRUE
#endif

#ifndef ASA_SAVE_BACKUP
#define ASA_SAVE_BACKUP ASAFALSE
#endif
#if ASA_SAVE_BACKUP
#define ASA_SAVE ASATRUE
#endif

#ifndef ASA_SAVE
#define ASA_SAVE ASAFALSE
#endif

#ifndef ASA_PIPE
#define ASA_PIPE ASAFALSE
#endif

#ifndef ASA_PIPE_FILE
#define ASA_PIPE_FILE ASAFALSE
#endif

#ifndef FDLIBM_POW
#define FDLIBM_POW ASAFALSE
#endif
#if FDLIBM_POW
#define F_POW s_pow
#else
#define F_POW pow
#endif

#ifndef FDLIBM_LOG
#define FDLIBM_LOG ASAFALSE
#endif
#if FDLIBM_LOG
#define F_LOG s_log
#else
#define F_LOG log
#endif

#ifndef FDLIBM_EXP
#define FDLIBM_EXP ASAFALSE
#endif
#if FDLIBM_EXP
#define F_EXP s_exp
#else
#define F_EXP exp
#endif

#ifndef FITLOC
#define FITLOC ASAFALSE
#endif

#ifndef FITLOC_ROUND
#define FITLOC_ROUND ASATRUE
#endif

#ifndef FITLOC_PRINT
#define FITLOC_PRINT ASATRUE
#endif

#ifndef MULTI_MIN
#define MULTI_MIN ASAFALSE
#endif

  /* Program Options */

  typedef struct {
    LONG_INT Limit_Acceptances;
    LONG_INT Limit_Generated;
    int Limit_Invalid_Generated_States;
    double Accepted_To_Generated_Ratio;

    double Cost_Precision;
    int Maximum_Cost_Repeat;
    int Number_Cost_Samples;
    double Temperature_Ratio_Scale;
    double Cost_Parameter_Scale_Ratio;
    double Temperature_Anneal_Scale;
#if USER_INITIAL_COST_TEMP
    double *User_Cost_Temperature;
#endif

    int Include_Integer_Parameters;
    int User_Initial_Parameters;
    ALLOC_INT Sequential_Parameters;
    double Initial_Parameter_Temperature;
#if RATIO_TEMPERATURE_SCALES
    double *User_Temperature_Ratio;
#endif
#if USER_INITIAL_PARAMETERS_TEMPS
    double *User_Parameter_Temperature;
#endif

    int Acceptance_Frequency_Modulus;
    int Generated_Frequency_Modulus;
    int Reanneal_Cost;
    int Reanneal_Parameters;

    double Delta_X;
#if DELTA_PARAMETERS
    double *User_Delta_Parameter;
#endif
    int User_Tangents;
    int Curvature_0;

#if QUENCH_PARAMETERS
    double *User_Quench_Param_Scale;
#endif
#if QUENCH_COST
    double *User_Quench_Cost_Scale;
#endif

    LONG_INT N_Accepted;
    LONG_INT N_Generated;
    int Locate_Cost;
    int Immediate_Exit;

    double *Best_Cost;
    double *Best_Parameters;
    double *Last_Cost;
    double *Last_Parameters;

#if OPTIONAL_DATA_DBL
    ALLOC_INT Asa_Data_Dim_Dbl;
    double *Asa_Data_Dbl;
#endif
#if OPTIONAL_DATA_INT
    ALLOC_INT Asa_Data_Dim_Int;
    LONG_INT *Asa_Data_Int;
#endif
#if OPTIONAL_DATA_PTR
    ALLOC_INT Asa_Data_Dim_Ptr;
    OPTIONAL_PTR_TYPE *Asa_Data_Ptr;
#endif
#if USER_ASA_OUT
    char *Asa_Out_File;
#endif
#if USER_COST_SCHEDULE
    double (*Cost_Schedule) ();
#endif
#if USER_ACCEPT_ASYMP_EXP
    double Asymp_Exp_Param;
#endif
#if USER_ACCEPTANCE_TEST
    void (*Acceptance_Test) ();
    int User_Acceptance_Flag;
    int Cost_Acceptance_Flag;
    double Cost_Temp_Curr;
    double Cost_Temp_Init;
    double Cost_Temp_Scale;
    double Prob_Bias;
    LONG_INT *Random_Seed;
#endif
#if USER_GENERATING_FUNCTION
    double (*Generating_Distrib) ();
#endif
#if USER_REANNEAL_COST
    int (*Reanneal_Cost_Function) ();
#endif
#if USER_REANNEAL_PARAMETERS
    double (*Reanneal_Params_Function) ();
#endif
#if ASA_SAMPLE
    double Bias_Acceptance;
    double *Bias_Generated;
    double Average_Weights;
    double Limit_Weights;
#endif
#if ASA_QUEUE
    ALLOC_INT Queue_Size;
    double *Queue_Resolution;
#endif
#if ASA_RESOLUTION
    double *Coarse_Resolution;
#endif
#if FITLOC
    int Fit_Local;
    int Iter_Max;
    double Penalty;
#endif
#if MULTI_MIN
    int Multi_Number;
    double *Multi_Cost;
    double **Multi_Params;
    double *Multi_Grid;
    int Multi_Specify;
#endif
#if ASA_PARALLEL
    int Gener_Mov_Avr;
    LONG_INT Gener_Block;
    LONG_INT Gener_Block_Max;
#endif
#if ASA_SAVE
    ALLOC_INT Random_Array_Dim;
    double *Random_Array;
#endif
    int Asa_Recursive_Level;
  } USER_DEFINES;

  /* system function prototypes */

#if HAVE_ANSI

/* This block gives trouble under some Ultrix */
#if ASAFALSE
  int fprintf (FILE * fp, const char *string, ...);
  int sprintf (char *s, const char *format, ...);
  FILE *popen (const char *command, const char *mode);
  void exit (int code);
#endif

#if IO_PROTOTYPES
  int fprintf ();
  int sprintf ();
  int fflush (FILE * fp);
  int fclose (FILE * fp);
  void exit ();
  int fread ();
  int fwrite ();
  int pclose ();
#endif

  double
    asa (double (*user_cost_function)

          
         (double *, double *, double *, double *, double *, ALLOC_INT *,
          int *, int *, int *, USER_DEFINES *),
         double (*user_random_generator) (LONG_INT *), LONG_INT * rand_seed,
         double *parameter_initial_final, double *parameter_minimum,
         double *parameter_maximum, double *tangents, double *curvature,
         ALLOC_INT * number_parameters, int *parameter_type,
         int *valid_state_generated_flag, int *exit_status,
         USER_DEFINES * OPTIONS);

#if TIME_CALC
  void print_time (char *message, FILE * ptr_out);
#endif

#if FDLIBM_POW
  double s_pow (double x, double y);
#endif
#if FDLIBM_LOG
  double s_log (double x);
#endif
#if FDLIBM_EXP
  double s_exp (double x);
#endif

#else                           /* HAVE_ANSI */

#if IO_PROTOTYPES
  int fprintf ();
  int sprintf ();
  int fflush ();
  int fclose ();
  int fread ();
  int fwrite ();
  FILE *popen ();
  int pclose ();
#endif

  double asa ();

#if TIME_CALC
  void print_time ();
#endif

#if FDLIBM_POW
  double s_pow ();
#endif
#if FDLIBM_LOG
  double s_log ();
#endif
#if FDLIBM_EXP
  double s_exp ();
#endif

#endif                          /* HAVE_ANSI */

#ifdef __cplusplus
}
#endif
#endif                          /* _ASA_USER_ASA_H_ */
