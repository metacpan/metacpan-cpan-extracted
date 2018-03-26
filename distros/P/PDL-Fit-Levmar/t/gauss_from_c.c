#include <math.h>
#include <stdio.h>

void gauss_from_c(FLOAT *p, FLOAT *x, int m, int n, void *data)
{
  int i;
  FLOAT *t = (FLOAT *) data;
  for(i=0; i<n; ++i){
   x[i] = p[0] * exp(-(t[i] - p[1])*(t[i] - p[1])*p[2]);
  }
}

   
void jacgauss_from_c(FLOAT *p, FLOAT *jac, int m, int n, void *data)
{
  int i,j;
  FLOAT *t = (FLOAT *) data;
   FLOAT arg, expf;
  for(i=j=0; i<n; ++i){
   arg = t[i] - p[1];
   expf = exp(-arg*arg*p[2]);
   jac[j++] = expf;
   jac[j++] = p[0]*2*arg*p[2]*expf;
   jac[j++] = p[0]*(-arg*arg)*expf;
  }
}


