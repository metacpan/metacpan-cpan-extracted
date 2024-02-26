#ifndef GLPK_AIO_H
#define GLPK_AIO_H 1

typedef struct control_params
{
  int msglev;
  int dual;
  int price;
  int itlim;
  int outfrq;
  int branch;
  int btrack;
  int presol;
  int rtest;
  int tmlim;
  int outdly;
  double tolbnd;
  double toldj;
  double tolpiv;
  double objll;
  double objul;
  double tolint;
  double tolobj;
  int scale;
  int lpsolver;
  int save_pb;
  const char *save_fn;
} control_params;

#endif
