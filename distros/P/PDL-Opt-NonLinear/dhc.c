/*************************************************************************/
/*** DHC.C                                                             ***/
/*** Example code demonstrating the usage of the dynamic hill climbing ***/
/*** algorithm on DeJong's test function Rosenbrock's saddle.	       ***/
/*** Note: compile with 'gcc dhc.c -lm'            		       ***/
/*** Last modified Apr 1, 1997.  (c) Deniz Yuret, deniz@ai.mit.edu     ***/
/*************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <math.h>

/* NDIM and THRESHOLD are the only two parameters to experiment with.  */
/* Try increasing NDIM to see the performance of DHC in higher dims.   */
/* Try making the THRESHOLD smaller to get more accurate results, and  */
/*   observe the performance trade-off.                                */
/* If you make THRESHOLD larger, DHC might fail to find the optimum    */
/*   at all, i.e. you may get a qualitatively different behavior.      */
/* Avoid large magnitude differences between parameters around the     */
/*   solution.  Use multipliers to compensate.                         */
/* If you need boundary conditions, put them in the objective function */
/*   such that the optimizer gets bad values for points out of bounds. */
/* Try multiple restarts by giving the program a command line          */
/*   argument.                                                         */
/* After you have played around enough, you should write your own      */
/*   restart method to take advantage of your specific landscape.      */
/* You should take a look at my thesis for details.  The thesis is at: */
/* ftp:publications.ai.mit.edu/ai-publications/1500-1999/AITR-1569.ps.Z*/
/* Compare your favorite algorithm with the same function/parameters.  */
/*   Send me e-mail if it can beat DHC :)                              */
/* Good luck optimizing.                                               */

// threshold 1e-3		/* Minimum step size */
// init  (example: 1.0)		/* Initial step size */


double dhc(n,x, init, threshold, u, v , xv, f)
     int n;
     double x[];
     double threshold;
     double init;
     double (*f)();
     double u[];
     double v[];
     double xv[];
{
  double fx,fxv;
  int vi,vvec;
  double vr;
  int i,iter,maxiter;

  for(i=0; i<n; i++)
    u[i] = v[i] = 0;
  vi = -1; vvec = 1;
  vr = -init;
  fx = f(n,x);
  fxv = 1e308;

  //printf("%d. %.4f <= ", count, fx);
  //for(i=0; i<n; i++) { printf("%.4f ", x[i]); }; printf("\n");

  while(fabs(vr) >= threshold) {
    maxiter = ((fabs(vr) < 2*threshold) ? 2*n : 2);
    iter = 0;
    while((fxv >= fx) && (iter < maxiter)) {
      if(iter == 0) { for(i=0; i<n; i++) xv[i] = x[i]; }
      else xv[vi] -= vr;
      if(vvec) vvec = 0;
      vr = -vr;
      if(vr > 0) vi = ((vi+1) % n);
      xv[vi] += vr;
      fxv = f(n,xv);
      iter++;
    }
    if(fxv >= fx) {
      fxv = 1e308;
      vr /= 2;
    }
    else{
      fx = fxv; //printf("%d. %.4f <= ", count, fx);
      for(i=0; i<n; i++) { x[i] = xv[i]; /*printf("%.4f ", x[i]); */}
      //printf("\n");
      if(iter == 0) {
	if(vvec) {
	  for(i=0; i<n; i++) {
	    u[i] += v[i]; v[i] *= 2; xv[i] += v[i];
	  }
	  vr *= 2;
	} else {
	  u[vi] += vr; vr *= 2; xv[vi] += vr;
	}
	fxv = f(n,xv);
      } else {
	for(i=0; i<n; i++) xv[i] += u[i];
	xv[vi] += vr;
	fxv = f(n,xv);
	if(fxv >= fx) {
	  for(i=0; i<n; i++) { u[i] = 0; xv[i] = x[i]; }
	  u[vi] = vr; vr *= 2;
	  xv[vi] += vr; fxv = f(n,xv);
	} else {
	  for(i=0; i<n; i++) x[i] = xv[i]; fx = fxv;
	  u[vi] += vr;
	  for(i=0; i<n; i++) v[i] = 2*u[i]; vvec = 1;
	  for(i=0; i<n; i++) xv[i] += v[i]; fxv = f(n,xv);
	  for(vr=0,i=0; i<n; i++) vr += v[i]*v[i];
	  vr = sqrt(vr);
	}
      }
    }
  }
  return(fx);
}
