#define ROSD 105.0

/* Rosenbrock function, global minimum at (1, 1) */
void ros(FLOAT *p, FLOAT *x, int m, int n, void *data)
{
register int i;

  for(i=0; i<n; ++i)
    x[i]=((1.0-p[0])*(1.0-p[0]) + ROSD*(p[1]-p[0]*p[0])*(p[1]-p[0]*p[0]));
}

void jacros(FLOAT *p, FLOAT *jac, int m, int n, void *data)
{
register int i, j;

  for(i=j=0; i<n; ++i){
    jac[j++]=(-2 + 2*p[0]-4*ROSD*(p[1]-p[0]*p[0])*p[0]);
    jac[j++]=(2*ROSD*(p[1]-p[0]*p[0]));
  }
}
