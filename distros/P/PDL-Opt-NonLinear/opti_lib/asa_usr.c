#include "asa_usr_asa.h"
/*

typedef struct {
    long int Limit_Acceptances;
    long int Limit_Generated;
    int Limit_Invalid_Generated_States;
    double Accepted_To_Generated_Ratio;
    double Cost_Precision;
    int Maximum_Cost_Repeat;
    int Number_Cost_Samples;
    double Temperature_Ratio_Scale;
    double Cost_Parameter_Scale_Ratio;
    double Temperature_Anneal_Scale;
    int Include_Integer_Parameters;
    int User_Initial_Parameters;
    long int Sequential_Parameters;
    double Initial_Parameter_Temperature;
    int Acceptance_Frequency_Modulus;
    int Generated_Frequency_Modulus;
    int Reanneal_Cost;
    int Reanneal_Parameters;
    double Delta_X;
    int User_Tangents;
    int Curvature_0;
    double *User_Quench_Param_Scale;
    double *User_Quench_Cost_Scale;
    long int N_Accepted;
    long int N_Generated;
    int Locate_Cost;
    int Immediate_Exit;
    double *Best_Cost;
    double *Best_Parameters;
    double *Last_Cost;
    double *Last_Parameters;
    char *Asa_Out_File;
    long int Queue_Size;
    double *Queue_Resolution;
    double *Coarse_Resolution;
    int Asa_Recursive_Level;
  } USER_DEFINES;

double asa (double (*user_cost_function)
         (double *, double *, double *, double *, double *, long int *,
          int *, int *, int *, USER_DEFINES *),
         double (*user_random_generator) (long int *), long int * rand_seed,
         double *parameter_initial_final, double *parameter_minimum,
         double *parameter_maximum, double *tangents, double *curvature,
         long int * number_parameters, int *parameter_type,
         int *valid_state_generated_flag, int *exit_status,
         USER_DEFINES * OPTIONS);*/


double cost_function (double *cost_parameters,
                             double *parameter_lower_bound,
                             double *parameter_upper_bound,
                             double *cost_tangents,
                             double *cost_curvature,
                             int * parameter_dimension,
                             int *parameter_int_real,
                             int *cost_flag,
                             int *exit_code, USER_DEFINES * USER_OPTIONS);

int initialize_parameters (double *cost_parameters,
                             double *parameter_lower_bound,
                             double *parameter_upper_bound,
                             double *cost_tangents,
                             double *cost_curvature,
                             int * parameter_dimension,
                             int *parameter_int_real,
                             USER_DEFINES * USER_OPTIONS);



int asa_seed (int seed);



double myrand (int * rand_seed);
double randflt (int * rand_seed);
double resettable_randflt (int * rand_seed, int reset);

void Exit_USER (char *statement);
static int *asa_rand_seed;
char user_exit_msg[160];


int
asa_main (int n, double *x, double *fx, double *lower, double *upper, int *parameter_type,
		int rand_seed, int *limit, double *cost_param, double *temperature,
		int *generic, double *resolution,double *coarse_res, double *tangent, 
		double *curvature, double *Quench_Cost,  double *Quench_Param, int print,
	  	double (*user_cost_function)
		(double *, double *, double *, double *, double *, int *,
		int *, int *, int *, USER_DEFINES *))
{
  int exit_code, cost_flag, i;

  double *cost_tangents, *cost_curvature;

  int initialize_parameters_value;


  exit_code = 0;
  cost_flag = 0;
  
  USER_DEFINES *USER_OPTIONS;

  if ((USER_OPTIONS =
       (USER_DEFINES *) calloc (1, sizeof (USER_DEFINES))) == ((void *)0)) {
    strcpy (user_exit_msg, "main()/asa_main(): USER_DEFINES");
    Exit_USER (user_exit_msg);
    return (-2);
  }




  resettable_randflt (&rand_seed, 1);

  USER_OPTIONS->Maximum_Cost_Repeat = limit[0];
  USER_OPTIONS->Number_Cost_Samples = limit[1];
  USER_OPTIONS->Limit_Acceptances = limit[2];
  USER_OPTIONS->Limit_Generated = limit[3];
  USER_OPTIONS->Limit_Invalid_Generated_States = limit[4];

  USER_OPTIONS->Accepted_To_Generated_Ratio = cost_param[0];
  USER_OPTIONS->Cost_Precision = cost_param[1];
  USER_OPTIONS->Cost_Parameter_Scale_Ratio = cost_param[2];
  USER_OPTIONS->Delta_X = cost_param[3];


  USER_OPTIONS->Initial_Parameter_Temperature = temperature[0];
  USER_OPTIONS->Temperature_Ratio_Scale = temperature[1];
  USER_OPTIONS->Temperature_Anneal_Scale = temperature[2];


/*
  USER_OPTIONS->Include_Integer_Parameters = 0;
  USER_OPTIONS->User_Initial_Parameters = 1;
  USER_OPTIONS->Sequential_Parameters = -1;
  USER_OPTIONS->Acceptance_Frequency_Modulus = 100;
  USER_OPTIONS->Generated_Frequency_Modulus = 10000;
  USER_OPTIONS->Reanneal_Cost = 1;
  USER_OPTIONS->Reanneal_Parameters = 1;
  USER_OPTIONS->Queue_Size = 50;
  USER_OPTIONS->User_Tangents = 0;
  USER_OPTIONS->Curvature_0 = 0;
*/

  
  USER_OPTIONS->Include_Integer_Parameters = generic[0];
  USER_OPTIONS->User_Initial_Parameters = generic[1];
  USER_OPTIONS->Sequential_Parameters = generic[2];
  USER_OPTIONS->Acceptance_Frequency_Modulus = generic[3];
  USER_OPTIONS->Generated_Frequency_Modulus = generic[4];
  USER_OPTIONS->Reanneal_Cost = generic[5];
  USER_OPTIONS->Reanneal_Parameters = generic[6];
  USER_OPTIONS->Queue_Size = generic[7];
  USER_OPTIONS->User_Tangents = generic[8];
  USER_OPTIONS->Curvature_0 = generic[9];
  
/////////////////////
  if (print)
	USER_OPTIONS->Asa_Out_File = "STDOUT";
  else
	USER_OPTIONS->Asa_Out_File = "NULL";
/////////////////////







  USER_OPTIONS->Queue_Resolution = resolution;

  USER_OPTIONS->Coarse_Resolution = coarse_res;

  USER_OPTIONS->Asa_Recursive_Level = 0;



////////////////////////
   USER_OPTIONS->User_Quench_Cost_Scale = Quench_Cost;
   USER_OPTIONS->User_Quench_Param_Scale = Quench_Param;
////////////////////////

      *fx = asa (user_cost_function,
             randflt,
             &rand_seed,
             x,
             lower,
             upper,
             tangent,
             curvature,
             &n,
             parameter_type, &cost_flag, &exit_code, USER_OPTIONS);
  


  free (USER_OPTIONS);
  return (exit_code);

}


int
asa_seed (int seed)
{
  static int rand_seed;

  if (fabs (seed) > 0) {
    asa_rand_seed = &rand_seed;
    rand_seed = seed;
  }

  return (rand_seed);
}

double
myrand (int * rand_seed)
{
  *rand_seed = (int) ((((int) 25173) * (*rand_seed) + ((int) 13849)) % ((int) 65536));
  return ((double) (*rand_seed) / ((double) 65536.0));

}






double
randflt (int * rand_seed)
{
  return (resettable_randflt (rand_seed, 0));
}






double
resettable_randflt (int * rand_seed, int reset)
{

  double rranf;
  unsigned kranf;
  int n;
  static int initial_flag = 0;
  int initial_seed;



  static double random_array[256];


  if (*rand_seed < 0)
    *rand_seed = -*rand_seed;

  if ((initial_flag == 0) || reset) {
    initial_seed = *rand_seed;

    for (n = 0; n < 256; ++n)
      random_array[n] = myrand (&initial_seed);

    initial_flag = 1;

    for (n = 0; n < 1000; ++n)
      rranf = randflt (&initial_seed);

    rranf = randflt (rand_seed);

    return (rranf);
  }

  kranf = (unsigned) (myrand (rand_seed) * 256) % 256;
  rranf = *(random_array + kranf);
  *(random_array + kranf) = myrand (rand_seed);

  return (rranf);
}

void
Exit_USER (char *statement)
{

  printf ("\n\n*** EXIT calloc failed *** %s\n\n", statement);

}
