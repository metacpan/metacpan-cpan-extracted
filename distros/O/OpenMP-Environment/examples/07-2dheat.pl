#!/usr/bin/env perl

use strict;
use warnings;
use Alien::OpenMP;
use OpenMP::Environment ();
use Getopt::Long qw/GetOptionsFromArray/;
use Util::H2O qw/h2o/;

# build and load subroutines
use Inline (
    C           => 'DATA',
    with        => qw/Alien::OpenMP/,
    BUILD_NOISY => 1,
);

# init options
my $o = {
    epsilon => 0.1,
    height  => 100,
    method  => q{gauss-seidel},
    t0      => q{550.0}, 
    threads => q{1,2,4,8,16},
    verbose => 0,
    width   => 100,
};

my $ret = GetOptionsFromArray( \@ARGV, $o, qw/width=i height=i method=s t0=s threads=s verbose epsilon=s/ );
h2o $o;

my $m = {
    q{jacobi}       => 1,
    q{gauss-seidel} => 2,
    q{sor}          => 3,
};

my $oenv = OpenMP::Environment->new;
for my $num_threads ( split / *, */, $o->threads ) {
    $oenv->omp_num_threads($num_threads);
    run_2dheat( $o->height, $o->width, $m->{ $o->method }, $o->verbose, $o->t0, $o->epsilon );
}

exit;

__DATA__

__C__
#define _WIDTH   50 
#define _HEIGHT  50 
#define H        1.0   
#define _METHOD  2 
#define ITERMAX  10    
#define ROOT     0

/* Includes */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <unistd.h>
#include <omp.h> 
#include <stdint.h>
#include <sys/time.h>
#include <time.h>

/* declare functions */
int get_start             (int rank);
int get_end               (int rank);
int get_num_rows          (int rank);
void init_domain          (float ** domain_ptr,int rank);
void jacobi               (float ** current_ptr,float ** next_ptr);
void gauss_seidel         (float ** current_ptr,float ** next_ptr);
void sor                  (float ** current_ptr,float ** next_ptr);
float get_val_par         (float * above_ptr,float ** domain_ptr,float * below_ptr,int rank,int i,int j);
void enforce_bc_par       (float ** domain_ptr,int rank,int i,int j);
int global_to_local       (int rank, int row);
float f                   (int i,int j);
float get_convergence_sqd (float ** current_ptr,float ** next_ptr,int rank);

/* declare and set globals */
int WIDTH=_WIDTH;
int HEIGHT=_HEIGHT;
int meth=_METHOD;
int num_threads;
float EPSILON=0.1;
float T_SRC0=550.0;

/* Function pointer to solver method of choice */
void (*method) ();

int _ENV_set_num_threads() {
  char *num;
  num = getenv("OMP_NUM_THREADS");
  omp_set_num_threads(atoi(num));
  return atoi(num);
}

int run_2dheat(int height, int width, int _meth, int verbose, float t_src0, float epsilon) {
  int p,my_rank,time;

  T_SRC0 = t_src0;
  EPSILON = epsilon;

  /* this call and function is *critical* for the "program"
     to respect OMP_NUM_ */
  int env_num_threads = _ENV_set_num_threads();

  HEIGHT = height;
  WIDTH = width;
  meth = _meth;

  /* arrays used to contain each PE's rows - specify cols, no need to spec rows */
  float **U_Curr;    
  float **U_Next;
  /* helper variables */
  float convergence,convergence_sqd,local_convergence_sqd;
  /* available iterator  */
  int i,j,k,m,n; 
  int per_proc,remainder,my_start_row,my_end_row,my_num_rows;
  int show_time = 0;
  /* for timings */
  struct timeval tv;
  struct timezone tz;
  struct tm *tm;
  
  /* artifacts of original serialization from MPI version */
  p = 1;
  my_rank = 0;

  switch (meth) {
    case 1:
      method = &jacobi;
    break;
    case 2:
      method = &gauss_seidel;
    break;
    case 3:
      method = &sor;
    break;
  }  
   
  /* let each processor decide what rows(s) it owns */
  my_start_row = get_start(my_rank);
  my_end_row = get_end(my_rank);
  my_num_rows = get_num_rows(my_rank);

  if ( verbose > 0 ) {
    printf("proc %d contains (%d) rows %d to %d\n",my_rank,my_num_rows,my_start_row,my_end_row);
    fflush(stdout);  
  }

  /* allocate 2d array */
  U_Curr = (float**)malloc(sizeof(float*)*my_num_rows);
  U_Curr[0] = (float*)malloc(sizeof(float)*my_num_rows*(int)floor(WIDTH/H));
  for (i=1;i<my_num_rows;i++) {
    U_Curr[i] = U_Curr[i-1]+(int)floor(WIDTH/H);
  }

  /* allocate 2d array */
  U_Next = (float**)malloc(sizeof(float*)*my_num_rows);
  U_Next[0] = (float*)malloc(sizeof(float)*my_num_rows*(int)floor(WIDTH/H));
  for (i=1;i<my_num_rows;i++) {
    U_Next[i] = U_Next[i-1]+(int)floor(WIDTH/H);
  }
  
  /* initialize global grid */
  init_domain(U_Curr,my_rank);
  init_domain(U_Next,my_rank);
  
  /* iterate for solution */
  if (my_rank == ROOT) {
    gettimeofday(&tv, &tz);
    tm=localtime(&tv.tv_sec);
    time = 1000000*(tm->tm_hour * 3600 + tm->tm_min * 60 + tm->tm_sec) + tv.tv_usec; 
  }
  k = 1;

  num_threads = 0;    
  for(;;) {
    method(U_Curr,U_Next);

    local_convergence_sqd = get_convergence_sqd(U_Curr,U_Next,my_rank);
    convergence_sqd = local_convergence_sqd;
    if (my_rank == ROOT) {
      convergence = sqrt(convergence_sqd);
      if (verbose > 0) {
        printf("L2 = %f\n",convergence);
        fflush(stdout);
      }
    } 

    /* broadcast method to use */
    if (convergence <= EPSILON) {
      break;      
    }
    
    /* copy U_Next to U_Curr */
    for (j=my_start_row;j<=my_end_row;j++) {
      for (i=0;i<(int)floor(WIDTH/H);i++) {
        U_Curr[j-my_start_row][i] = U_Next[j-my_start_row][i];
      }
    }
    k++;
  }   

  /* say something at the end */
  if (my_rank == ROOT) {
    gettimeofday(&tv, &tz);
    tm=localtime(&tv.tv_sec);
    time = 1000000*(tm->tm_hour * 3600 + tm->tm_min * 60 + tm->tm_sec) + tv.tv_usec - time; 
    printf("convergence in %d iterations using %d processors on a %dx%d grid is %d microseconds\n",k,env_num_threads,(int)floor(WIDTH/H),(int)floor(HEIGHT/H),time);
  }
}

 /* used by each PE to compute the sum of the squared diffs between current iteration and previous */

 float get_convergence_sqd (float ** current_ptr,float ** next_ptr,int rank) {
    int i,j,my_start,my_end,my_num_rows;
    float sum;
    
    my_start = get_start(rank);
    my_end = get_end(rank);
    my_num_rows = get_num_rows(rank);
 
    sum = 0.0;
    for (j=my_start;j<=my_end;j++) {
      for (i=0;i<(int)floor(WIDTH/H);i++) {
        sum += pow(next_ptr[global_to_local(rank,j)][i]-current_ptr[global_to_local(rank,j)][i],2);
      }
    }
    return sum;   
 }

 /* implements parallel jacobi methods */

 void jacobi (float ** current_ptr,float ** next_ptr) {
    int i,j,p,my_rank,my_start,my_end,my_num_rows;
    float U_Curr_Above[(int)floor(WIDTH/H)];  /* 1d array holding values from bottom row of PE above */
    float U_Curr_Below[(int)floor(WIDTH/H)];  /* 1d array holding values from top row of PE below */

    p = 1;
    my_rank = 0;

    my_start = get_start(my_rank);
    my_end = get_end(my_rank);
    my_num_rows = get_num_rows(my_rank);

#pragma omp parallel default(none) private(i,j) \
  shared(p,my_rank,U_Curr_Above,U_Curr_Below,WIDTH,my_start,my_end,next_ptr,current_ptr)
{
    /* Jacobi method using global addressing */
#pragma omp for schedule(runtime) 
    for (j=my_start;j<=my_end;j++) {
      for (i=0;i<(int)floor(WIDTH/H);i++) {
	next_ptr[j-my_start][i] = .25*(get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i-1,j)
                   + get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i+1,j)
                   + get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i,j-1)
                   + get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i,j+1)
                   - (pow(H,2)*f(i,j)));		   
	enforce_bc_par(next_ptr,my_rank,i,j);	   
      }
    }
} //end omp parallel region 

 }

 /* implements parallel g-s method */

 void gauss_seidel (float ** current_ptr,float ** next_ptr) {
    int i,j,p,my_rank,my_start,my_end,my_num_rows;
    float U_Curr_Above[(int)floor(WIDTH/H)];  /* 1d array holding values from bottom row of PE above */
    float U_Curr_Below[(int)floor(WIDTH/H)];  /* 1d array holding values from top row of PE below */
    float W =  1.0;

    p = 1;
    my_rank = 0;

    my_start = get_start(my_rank);
    my_end = get_end(my_rank);
    my_num_rows = get_num_rows(my_rank);
        
#pragma omp parallel default(none) private(i,j) \
  shared(W,p,my_rank,U_Curr_Above,U_Curr_Below,WIDTH,my_start,my_end,next_ptr,current_ptr)
{
    /* solve next reds (i+j odd) */
#pragma omp for schedule(runtime) 
    for (j=my_start;j<=my_end;j++) {
      for (i=0;i<(int)floor(WIDTH/H);i++) {
        if ((i+j)%2 != 0) {
          next_ptr[j-my_start][i] = get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i,j)
                     + (W/4)*(get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i-1,j)
                     + get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i+1,j)
                     + get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i,j-1)
                     + get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i,j+1)
		     - 4*(get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i,j))
                     - (pow(H,2)*f(i,j))); 
	  enforce_bc_par(next_ptr,my_rank,i,j);	   
        }
      }
    }   
   /* solve next blacks (i+j) even .... using next reds */
#pragma omp for schedule(runtime) 
    for (j=my_start;j<=my_end;j++) {
      for (i=0;i<(int)floor(WIDTH/H);i++) {
        if ((i+j)%2 == 0) {
          next_ptr[j-my_start][i] = get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i,j)
                     + (W/4)*(get_val_par(U_Curr_Above,next_ptr,U_Curr_Below,my_rank,i-1,j)
                     + get_val_par(U_Curr_Above,next_ptr,U_Curr_Below,my_rank,i+1,j)
                     + get_val_par(U_Curr_Above,next_ptr,U_Curr_Below,my_rank,i,j-1)
                     + get_val_par(U_Curr_Above,next_ptr,U_Curr_Below,my_rank,i,j+1)
                     - 4*(get_val_par(U_Curr_Above,next_ptr,U_Curr_Below,my_rank,i,j))
                     - (pow(H,2)*f(i,j)));
 	  enforce_bc_par(next_ptr,my_rank,i,j);	   
        }
      }
    }     
} //end omp parallel region 
 }
 
 /* implements parallels sor method */
 
 void sor (float ** current_ptr,float ** next_ptr) {
    int i,j,p,my_rank,my_start,my_end,my_num_rows;
    float U_Curr_Above[(int)floor(WIDTH/H)];  /* 1d array holding values from bottom row of PE above */
    float U_Curr_Below[(int)floor(WIDTH/H)];  /* 1d array holding values from top row of PE below */
    float W =  1.5;
    
    p = 1;
    my_rank = 0;

    my_start = get_start(my_rank);
    my_end = get_end(my_rank);
    my_num_rows = get_num_rows(my_rank);
        
#pragma omp parallel default(none) private(i,j) \
  shared(W,p,my_rank,U_Curr_Above,U_Curr_Below,WIDTH,my_start,my_end,next_ptr,current_ptr)
{
#pragma omp for schedule(runtime) 
    /* solve next reds (i+j odd) */
    for (j=my_start;j<=my_end;j++) {
      for (i=0;i<(int)floor(WIDTH/H);i++) {
        if ((i+j)%2 != 0) {
          next_ptr[j-my_start][i] = get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i,j)
                     + (W/4)*(get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i-1,j)
                     + get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i+1,j)
                     + get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i,j-1)
                     + get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i,j+1)
		     - 4*(get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i,j))
                     - (pow(H,2)*f(i,j))); 
 	  enforce_bc_par(next_ptr,my_rank,i,j);	   
        }
      }
    }   
   /* solve next blacks (i+j) even .... using next reds */
#pragma omp for schedule(runtime) 
    for (j=my_start;j<=my_end;j++) {
      for (i=0;i<(int)floor(WIDTH/H);i++) {
        if ((i+j)%2 == 0) {
          next_ptr[j-my_start][i] = get_val_par(U_Curr_Above,current_ptr,U_Curr_Below,my_rank,i,j)
                     + (W/4)*(get_val_par(U_Curr_Above,next_ptr,U_Curr_Below,my_rank,i-1,j)
                     + get_val_par(U_Curr_Above,next_ptr,U_Curr_Below,my_rank,i+1,j)
                     + get_val_par(U_Curr_Above,next_ptr,U_Curr_Below,my_rank,i,j-1)
                     + get_val_par(U_Curr_Above,next_ptr,U_Curr_Below,my_rank,i,j+1)
                     - 4*(get_val_par(U_Curr_Above,next_ptr,U_Curr_Below,my_rank,i,j))
                     - (pow(H,2)*f(i,j)));
 	  enforce_bc_par(next_ptr,my_rank,i,j);	   
        }
      }
    }     
} //end omp parallel region 
 }
 
 /* enforces bcs in in serial and parallel */
 
 void enforce_bc_par (float ** domain_ptr,int rank,int i,int j) {
   /* enforce bc's first */
   if(i == ((int)floor(WIDTH/H/2)-1) && j == 0) {
     /* This is the heat source location */
     domain_ptr[j][i] = T_SRC0;
   } else if (i <= 0 || j <= 0 || i >= ((int)floor(WIDTH/H)-1) || j >= ((int)floor(HEIGHT/H)-1)) {
     /* All edges and beyond are set to 0.0 */
     domain_ptr[global_to_local(rank,j)][i] = 0.0;
   }
 }

 /* returns appropriate values for requested i,j */
 
 float get_val_par (float * above_ptr,float ** domain_ptr,float * below_ptr,int rank,int i,int j) {
   float ret_val;
   int p;
      
   /* artifact from original serialization of MPI version */
   p = 1;

   /* enforce bc's first */
   if(i == ((int)floor(WIDTH/H/2)-1) && j == 0) {
     /* This is the heat source location */
     ret_val = T_SRC0;
   } else if (i <= 0 || j <= 0 || i >= ((int)floor(WIDTH/H)-1) || j >= ((int)floor(HEIGHT/H)-1)) {
     /* All edges and beyond are set to 0.0 */
     ret_val = 0.0;
   } else {
     /* Else, return value for matrix supplied or ghost rows */
     if (j < get_start(rank)) {
       if (rank == ROOT) {
         /* not interested in above ghost row */
         ret_val = 0.0;
       } else { 
         ret_val = above_ptr[i];
         /*
	 printf("%d: Used ghost (%d,%d) row from above = %f\n",rank,i,j,above_ptr[i]);
	 fflush(stdout);
         */
       }
     } else if (j > get_end(rank)) {
       if (rank == (p-1)) {
         /* not interested in below ghost row */
         ret_val = 0.0;
       } else { 
         ret_val = below_ptr[i];
         /*
	 printf("%d: Used ghost (%d,%d) row from below = %f\n",rank,i,j,below_ptr[i]);
	 fflush(stdout);
         */
       }     
     } else {
       /* else, return the value in the domain asked for */
       ret_val = domain_ptr[global_to_local(rank,j)][i];
       /*
       printf("%d: Used real (%d,%d) row from self = %f\n",rank,i,global_to_local(rank,j),domain_ptr[global_to_local(rank,j)][i]);
       fflush(stdout);
       */
     }
   }
   return ret_val;

 }

 /* initialized domain to 0.0 - could be where grid file is read in */

 void init_domain (float ** domain_ptr,int rank) {
   int i,j,start,end,rows;
   start = get_start(rank);
   end = get_end(rank);
   rows = get_num_rows(rank);

   for (j=start;j<end;j++) {
     for (i=0;i<(int)floor(WIDTH/H);i++) {
       domain_ptr[j-start][i] = 0.0;
     }
   }
 }

 /* computes start row for given PE */

 int get_start (int rank) {
   /* computer row divisions to each proc */
   int p,per_proc,start_row,remainder;
   /* artifact of serialization of orignal MPI version */
   p = 1; 
   /* get initial whole divisor */
   per_proc = (int)floor(HEIGHT/H)/p;
   /* get number of remaining */
   remainder = (int)floor(HEIGHT/H)%p;
   /* there is a remainder, then it distribute it to the first "remainder" procs */ 
   if (rank < remainder) {
     start_row = rank * (per_proc + 1);
   } else {
     start_row = rank * (per_proc) + remainder;
   }
   return start_row;
 }

 /* computes end row for given PE */

 int get_end (int rank) {
   /* computer row divisions to each proc */
   int p,per_proc,remainder,end_row;
   /* artifact of serialization of orignal MPI version */
   p = 1; 
   per_proc = (int)floor(HEIGHT/H)/p;
   remainder = (int)floor(HEIGHT/H)%p;
   if (rank < remainder) {
     end_row = get_start(rank) + per_proc;
   } else {
     end_row = get_start(rank) + per_proc - 1;
   }
   return end_row;
 }

 /* calcs number of rows for given PE */
 
 int get_num_rows (int rank) {
   return 1 + get_end(rank) - get_start(rank);
 }

 int global_to_local (int rank, int row) {
   return row - get_start(rank);
 }

  /* 
  * f - function that would be non zero if there was an internal heat source
  */
 
 float f (int i,int j) {
   return 0.0;
 }

