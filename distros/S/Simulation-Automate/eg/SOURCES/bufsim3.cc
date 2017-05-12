/* NOTE:
This is not my OPS node simulator,because I can't release that code (yet).
It's just some C++ code that compiles and runs, to allow you to test SynSim.

W. Vanderbauwhede 09/07/2002 

$Id: bufsim3.cc,v 1.2 2002/10/01 14:10:14 wim Exp $
*/
#include <stdlib.h>
#include <iostream>
#include <math.h>
#include <time.h>
#include "bufsim3.h"
#ifdef MERSENNE_TWISTER
#include "../SOURCES/MersenneTwister.h"
#endif
#if KEEP_ORDER == 1
#include <queue>
#endif

//=============================================================================
#ifdef MERSENNE_TWISTER
MTRand mtrand;
MTRand * p_mtrand = &mtrand;
#endif

double myrand (void) {
double r; 
// MTRand mtrand = *p_mtrand;
#ifdef MERSENNE_TWISTER
/* random value in range [0,1[, Mersenne Twister generator */
  r = (*p_mtrand).randExc();
#else
 /* random value in range [0,1] */
 r = ( (double)rand() / (double)(RAND_MAX) );
#endif
return(r);

}

//-----------------------------------------------------------------------------
double pareto (double k,double m) {

// Generate Pareto random numbers
    // k between 1 and 2, closer to 1 means more long periods
    // m is the minimum value for the period, e.g. the number of packets in the burst.
  double y;

  y=m/pow(1-myrand(),1/k); //This is based on F^-1, not f^-1!
  return(y);

}

//-----------------------------------------------------------------------------


int main()
{



int tt=0;
int dropcount=0;
int spacketcount=0;
int packetcount=0;

// wait is a simple array to keep track of the time to wait between packets
int wait[NPORTS];
// buffer is a "plain" 3D array. 
int buffer[NPORTS][NBUFS][6];
// portfree is an array of integers, with dimension NPORTS
//could be bool, of course
int portfree[NPORTS];
#if BLOCKING == 1
int bufmuxfree[NPORTS];
#endif
// empty_buffers is an array with the address of every empty buffer.
// This array should grow or shrink on demand!
// but if this is impossible, just define an "empty" value and a condition
// if C++ is really so fast, shouldn't be a problem
int empty_buffers[NPORTS][NBUFS];
int index_empty[NPORTS];

  int i,j;
#ifdef HISTS
  int prev_tt[NPORTS];
#endif

#if KEEP_ORDER ==1
  queue<int> buffer_stack[NPORTS];
#endif

#ifdef STATS
#ifdef MERSENNE_TWISTER
  mtrand.seed(STATS);
#else 
  srand(STATS);
#endif
#else 
#ifdef MERSENNE_TWISTER
  mtrand.seed(4357U);
#else
  srand(4357U);
#endif
#endif


  //init
  for (i=0;i<NPORTS;i++) {
    wait[i]=-1;
    portfree[i]=1;
#if BLOCKING == 1
    bufmuxfree[i]=1;
#endif
    index_empty[i]=0;
#ifdef HISTS
    prev_tt[i]=0;
#endif
    for (j=0;j<NBUFS;j++) {
      empty_buffers[i][j]=j;
      buffer[i][j][5]=0; // 1 if filled
      int ii;
      for (ii=0;ii<5;ii++) {
	buffer[i][j][ii]=-1;
      }
    }
  }

  time_t starttime,stoptime;
  time(&starttime);

  //==============================================================================
  //main timing loop
  while (packetcount<NPACK) {
    for ( i=0;i<NPORTS;i++) {

if(tt>wait[i]) {
  int length=0;

  int gap=0;


 int dest=0;
 double destrand=myrand();



wait[i]=tt+length+gap;
packetcount++;
#ifdef HISTS
 cout <<"B"<< i<<"\t"<<tt<<"\t"<<gap<<endl;
#endif
#ifdef VERBOSE
    cout <<  "Packet "<<i<<":"<<tt<<" arrived at port "<<i<<" @"<<tt<<"...";
#endif
      // Buffer is full
#ifdef VERBOSE
      cout << " Buffer "<<i<<" is full, drop packet "<<i<<":"<<tt<<" ("<<dropcount<<")\n";
#endif
  } // if a packet arrives 

  int j=0;
  

  } //for
  tt++;
} //while
//=============================================================================
time(&stoptime);
#ifdef VERBOSE
  cout <<  "Packets generated: " << packetcount << endl;
  cout <<  "Packets switched: " << spacketcount << endl;
  cout <<  "Packets dropped: " << dropcount << endl;
  cout <<  "Elapsed time: "<<stoptime-starttime<< endl;
#else
cout << NBUFS<<"\t"<<packetcount <<"\t"<<spacketcount<<"\t"<<dropcount;
for (i=0;i<NPORTS;i++) {
  cout <<"\t"<<index_empty[i];
}
cout<<"\n";

#endif
} // END of main()
//-----------------------------------------------------------------------------

