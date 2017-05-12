/*
 * suggest.h
 *
 * This file contains the various prototypes for the SUGGEST library
 *
 * Started 11/6/99
 * George
 */

int  *SUGGEST_Init(int, int, int, int *, int *, int, int, float); 
int   SUGGEST_TopN(int *, int, int *, int, int *);
void  SUGGEST_Clean(int *);
float SUGGEST_EstimateAlpha(int, int, int, int *, int *, int, int);
