/*
 * wumanber_impl.c -- an efficient WuManber implementation. 
 *
 * Copyright (C) 2010, Juergen Weigert, Novell inc.
 * Distribute,modify under GPLv2 or GPLv3, or perl license.
 *
 * Loosly based on 
 * ftp://ftp.cs.arizona.edu/agrep/agrep-2.04.tar:mgrep.c
 * which is timestamped 1992-04-11
 *
 * The content of the COPYRIGHT file from the above package is included here
 -------------------------------------------------------------------
This material was developed by Sun Wu and Udi Manber
at the University of Arizona, Department of Computer Science.
Permission is granted to copy this software, to redistribute it
on a nonprofit basis, and to use it for any purpose, subject to
the following restrictions and understandings.

1. Any copy made of this software must include this copyright notice
in full.

2. All materials developed as a consequence of the use of this
software shall duly acknowledge such use, in accordance with the usual
standards of acknowledging credit in academic research.

3. The authors have made no warranty or representation that the
operation of this software will be error-free or suitable for any
application, and they are under under no obligation to provide any
services, by way of maintenance, update, or otherwise.  The software
is an experimental prototype offered on an as-is basis.

4. Redistribution for profit requires the express, written permission
of the authors.

 -------------------------------------------------------------------
 *
 * NOTE: modern agrep from libtre5 does not have the -f option and no
 * comparable multi pattern search capability. Therefore I am transporting this
 * code 18 years into the future. Are we really that old?
 *
 * My version of this code reworks the API and the behaviour when a match is
 * found.
 * - made -Wall silent
 * - made run standalone
 * - do not skip to end of line, when a match is found.
 * - allow multiple matches on the same location.
 * - memory based, no longer slurp in chunks of a file.
 * - clean API, call prep_pat() with a list of patterns, then
 *   call search_init() and search_text() with the text string.
 * - allow for a dynamic wm object, no more global statics.
 * - removed most arbitrary size limits. Used calloc.
 *
 * 2010-01-10, jw@suse.de
 *
 * TODO: find out, why not all possible matches are found in wm_bs3()/wm_bs1()
 * maybe, a loop is aborted, during hash lookup?
 */

/* Copyright (c) 1991 Sun Wu and Udi Manber.  All Rights Reserved. */
/* multipattern matcher */
#include <stdio.h>
#include <ctype.h>
#include <string.h>	// strlen() and friends.
#include <stdlib.h>	// exit()
#include <unistd.h>	// read()
#include <sys/types.h>	// O_RDONLY
#include <sys/stat.h>	// O_RDONLY
#include <fcntl.h>	// open()
#include <errno.h>	// errno, strerror()
#include "wumanber_impl.h"	// assert correct prototypes

#ifndef STANDALONE
# define STANDALONE 1	// use own main() below.
#endif

static void f_prep(struct WuManber *wm, int pat_index, unsigned char *Pattern);
static void wm_bs1(struct WuManber *wm, unsigned char *text, int end);
static void wm_bs3(struct WuManber *wm, unsigned char *text, int end);

// search_init() must be called after prep_pat() but before search_text()
void search_init(struct WuManber *wm, char *name)
{
  // match_word_boundaries, match_whole_line, nocase are initialized in prep_pat()

  wm->one_match_per_line = 0;
  wm->one_match_per_offset = 0;
  wm->cb = NULL;

}

/*
 * pat_p[0]=NULL; pat_p[n_pat+1]=NULL recommended, 
 * pat_p[1]...pat_p[n_pat] are valid entries
 */
void prep_pat(struct WuManber *wm, int n_pat, unsigned char **pat_p, int nocase)
{
#if HAVE_WORDBOUND_OR_WHOLELINE
  wm->match_word_boundaries = 0;
#endif
  wm->nocase = nocase;
  wm->patt = pat_p;
  wm->n_pat = n_pat;
  wm->use_bs3  = 0;
  wm->use_bs1 = 0;

# if HAVE_WORDBOUND_OR_WHOLELINE
  i = 0; p=1;
  while(i<length) {
      patt[p] = pat_ptr;
      if(wm->match_word_boundaries) *pat_ptr++ = W_DELIM;
      if(wm->match_whole_line) *pat_ptr++ = L_DELIM;
      while((*pat_ptr = buf[i++]) != '\n') pat_ptr++;
      if(wm->match_word_boundaries) *pat_ptr++ = W_DELIM;
      if(wm->match_whole_line) *pat_ptr++ = L_DELIM;           /* Can't be both on */
      *pat_ptr++ = 0;
      p++;  
  }
#endif

  unsigned Mask = 15;
  int i;
  for(i=0; i< N_SYMB; i++) wm->tr[i] = i;
  if(wm->nocase) {
      for(i='A'; i<= 'Z'; i++) wm->tr[i] = i + 'a' - 'A';
  }
#if HAVE_WORDBOUND_OR_WHOLELINE
  if(wm->match_word_boundaries) {
      for(i=0; i<128; i++) if(!isalnum(i)) wm->tr[i] = W_DELIM;
  }
#endif
  for(i=0; i< N_SYMB; i++) wm->tr1[i] = wm->tr[i]&Mask;

  wm->pat_len = (unsigned int *)calloc(n_pat+2, sizeof(unsigned int));

  wm->p_size = 255;		// max that fits in shift_min[] entries.
  for(i=1 ; i <= wm->n_pat; i++) 
    {
      int l = strlen((char *)wm->patt[i]);
      wm->pat_len[i] = l;
      if (l!=0 && l < wm->p_size) wm->p_size = l;
    }
  if (wm->p_size == 0) 
    {
      fprintf(stderr, "%s: the pattern file is empty\n", wm->progname);
      exit(2);
    }
  if (n_pat > 100 && wm->p_size > 2) wm->use_bs3 = 1;
  if (wm->p_size == 1) wm->use_bs1 = 1;
  for (i=0; i<SHIFT_SZ; i++) wm->shift_min[i] = wm->p_size - 2;
  for (i=0; i<PAT_HASH_SZ; i++) wm->pat_hash[i] = 0;
  for (i=1; i<= n_pat; i++) f_prep(wm, i, wm->patt[i]);
}


#if 0
void mgrep(struct WuManber *wm, int fd)
{ 
#define MAXLINE 1024
#define BLOCKSIZE  8192		
    char r_newline = '\n';
    unsigned char text[2*BLOCKSIZE+MAXLINE]; 
    int buf_end, num_read, start, end, residue = 0;

    text[MAXLINE-1] = '\n';  /* initial case */
    start = MAXLINE-1;

    while( (num_read = read(fd, text+MAXLINE, BLOCKSIZE)) > 0) 
    {
       buf_end = end = MAXLINE + num_read -1 ;
       while(text[end]  != r_newline && end > MAXLINE) end--;
       residue = buf_end - end  + 1 ;
       text[start-1] = r_newline;
       if(use_bs1) wm_bs1(wm, text, start, end);
       else        wm_bs3(wm, text, start, end);
       start = MAXLINE - residue;
       if(start < 0) {
            start = 1; 
       }
       strncpy((char *)text+start, (char *)text+end, residue);
    } /* end of while(num_read = ... */
    text[MAXLINE] = '\n';
    text[start-1] = '\n';
    if(residue > 1) {
        if(use_bs1) wm_bs1(wm, text, start, end);
        else        wm_bs3(wm, text, start, end);
    }
    return;
} /* end mgrep */
#endif

static void wm_bs3(struct WuManber *wm, unsigned char *text, int end)
{
  unsigned char *textstart = text;
  unsigned char *textend = text + end;
  unsigned char shift; 

  unsigned int hash, i, m1, j;
  int Long = wm->use_bs3; 
  int pat_index;
  int m = wm->p_size; 
  int MATCHED = 0;
  int ONE_MATCH_PER_LINE = wm->one_match_per_line;
  int ONE_MATCH_PER_OFFSET = wm->one_match_per_offset;
  unsigned char *tr = wm->tr;
  unsigned char *tr1 = wm->tr1;

  unsigned char *qx;
  struct pat_list *p;

  m1 = m - 1;
  text = text + m1;
  while (text <= textend) {
	  hash=tr1[*text];
	  hash=(hash<<4)+(tr1[*(text-1)]);
	  if(Long) hash=(hash<<4)+(tr1[*(text-2)]);
	  shift = wm->shift_min[hash];
	  if(shift == 0) {
	  	  // text points to the m'th char of a candidate pattern
		  hash=0;
		  for(i=0;i<=m1;i++)  {
		      hash=(hash<<4)+(tr1[*(text-i)]);
		  }
		  hash=hash&(PAT_HASH_SZ-1);
		  p = wm->pat_hash[hash];
		  while(p != 0) {
			  pat_index = p->index;
			  p = p->next;
			  qx = text-m1;
#if DANGEROUS_BEANS
			  // This code may read across array bounds.
			  // It performs 10% better in one of my test cases.
			  j = 0;
			  while(tr[wm->patt[pat_index][j]] == tr[*(qx++)]) j++;
			  if (j > m1 ) { 
			     if(wm->pat_len[pat_index] <= j) {
				  if(text > textend) return;
#else
			  if (text > textend) return;
			  int l = wm->pat_len[pat_index];
			  if (qx+l <= textend) 
			  {
			    j = 0;
			    // not checking tr[] when not needed also saves 10%
			    if (wm->nocase
#if HAVE_WORDBOUND_OR_WHOLELINE
			        || wm->match_word_boundaries || wm->match_whole_line
#endif
				)
			      while ((--l>=0) && (tr[wm->patt[pat_index][l]] == tr[qx[l]])) ;
			    else
			      while ((--l>=0) && (   wm->patt[pat_index][l]  ==    qx[l])) ;
			    if (l < 0)
			     {
#endif
				  wm->n_matches++;
				  MATCHED=1;
				  if (wm->cb) wm->cb(pat_index, text-textstart-m1, wm->cb_data);
				  if (ONE_MATCH_PER_LINE) while (*text != '\n') text++;
			     }
			  }
			  if (ONE_MATCH_PER_OFFSET && MATCHED) break;
		  }
		  MATCHED = 0;
		  shift = 1;	// take care of overlapping matches
	  }
	  text = text + shift;
    }
}

static void wm_bs1(struct WuManber *wm, unsigned char *text, int end)
{
  unsigned char *textend = text + end;
  unsigned char *textstart = text;
  int  j; 
  struct pat_list *p;
  int pat_index; 
  int MATCHED=0;
  int ONE_MATCH_PER_LINE = wm->one_match_per_line;
  int ONE_MATCH_PER_OFFSET = wm->one_match_per_offset;
  unsigned char *tr = wm->tr;
  unsigned char *qx;

  text = text - 1;
  while (++text <= textend) {
		  p = wm->pat_hash[*text];
		  while(p != 0) {
			  pat_index = p->index;
			  p = p->next;
			  qx = text;
			  j = 0;
			  while(tr[wm->patt[pat_index][j]] == tr[*(qx++)]) j++;
			  if(wm->pat_len[pat_index] <= j) {
				  if(text >= textend) return;
				  wm->n_matches++;
				  if (wm->cb) wm->cb(pat_index, text-textstart, wm->cb_data);
				  if (ONE_MATCH_PER_LINE) while (*text != '\n') text++;
			  }
			  if (ONE_MATCH_PER_OFFSET && MATCHED) break;
		  }
		  MATCHED = 0;
    } /* while */
}

static void 
f_prep(struct WuManber *wm, int pat_index, unsigned char *Pattern)
{
  int i, m;
  struct pat_list  *pt, *qt;
  unsigned hash, Mask=15;
	  m = wm->p_size;
	  for (i = m-1; i>=(1+wm->use_bs3); i--) {
		  hash = (Pattern[i] & Mask);
		  hash = (hash << 4) + (Pattern[i-1]& Mask);
		  if(wm->use_bs3) hash = (hash << 4) + (Pattern[i-2] & Mask);
		  if(wm->shift_min[hash] >= m-1-i) wm->shift_min[hash] = m-1-i;
	  }
	  if(wm->use_bs1) Mask = 255;  /* 011111111 */
	  hash = 0;
	  for(i = m-1; i>=0; i--)  {
	      hash = (hash << 4) + (wm->tr[Pattern[i]]&Mask);
	  }
	  hash=hash&(PAT_HASH_SZ-1);
	  qt = (struct pat_list *) malloc(sizeof(struct pat_list));
	  qt->index = pat_index;
	  pt = wm->pat_hash[hash];
	  qt->next = pt;
	  wm->pat_hash[hash] = qt;
}

unsigned int search_text(struct WuManber *wm, unsigned char *text, int end)
{
  wm->n_matches = 0;
  if (wm->use_bs1) wm_bs1(wm, text, end);
  else             wm_bs3(wm, text, end);

  // mgrep(wm, text, text_len); 
  return wm->n_matches;
}

#if STANDALONE
static unsigned int pat_count[4*PAT_HASH_SZ];
static int distinct_count;
static void count_em(unsigned int idx, unsigned long offset, void *data)
{
  if (idx < 4*PAT_HASH_SZ && !pat_count[idx]++)
    distinct_count++;
  printf("offset=%ld: idx=%d, '%s'\n", offset, idx, ((unsigned char **)data)[idx]);
}

static unsigned char *
load_file(char *filename, char *progname, int *lenp)
{
  struct stat st;
  int fp;

  if ((fp = open(filename, O_RDONLY)) < 0)
    {
      fprintf(stderr, "%s: Cannot open file %s: %s\n", progname, filename, strerror(errno));
      exit(3);
    }
  fstat(fp, &st);
  unsigned char *buf = (unsigned char *)calloc(st.st_size+2, sizeof(unsigned char));

  int length = 0;
  int num_read;
  while((num_read = read(fp, buf+length, 8192)) > 0) 
    {
      length = length + num_read;
    }
  close(fp);
  buf[length] = '\0';

  if (lenp) *lenp = length;
  return buf;
}

static unsigned char **
load_pat_list(char *filename, char *progname, int *npat)
{
  int length=0, i;
  unsigned char *buf = load_file(filename, progname, &length);
  
  int n_pat = 0;
  for (i = 0; i <= length; i++) if (buf[i] == '\n') n_pat++;

  unsigned char **ppat = (unsigned char **)calloc(n_pat+2, sizeof(char *));
  int p = 0;
  ppat[p++] = buf;
  for (i = 0; i <= length; i++) 
    {
      if (buf[i] == '\n') 
        {
	  buf[i] = '\0';
	  ppat[p++] = buf+i+1;
	}
    }
  ppat[p] = NULL;

  if (p>4*PAT_HASH_SZ) 
    {
      fprintf(stderr, "%s: suggested maximum number of patterns is %d, using %d\n", progname, 4*PAT_HASH_SZ, p); 
    }

  if (npat) *npat = n_pat; 
  return ppat;
}

int main(int argc, char **argv)
{
  struct WuManber wm;

  wm.progname = argv[0];
  wm.nocase = 0;

  if (argc > 2 && !strcmp(argv[1], "-n"))
    {
      wm.nocase = 1;
      argv++; argc--;
    }

  if (argc < 2)
    {
      fprintf(stderr, "Usage: %s patterns_file text_file\n", wm.progname);
      fprintf(stderr, "\n patterns_file is a newline seperated file of exact patterns\n");
      exit(1);
    }

  int n_pat = 0;
  unsigned char **pat_list = load_pat_list(argv[1], wm.progname, &n_pat);

  int text_len = 0;
  unsigned char *text = load_file(argv[2], wm.progname, &text_len);

  prep_pat(&wm, n_pat, --pat_list, wm.nocase);
  search_init(&wm, wm.progname);
  wm.cb = count_em;
  wm.cb_data = (void *)pat_list;
  search_text(&wm, text, text_len);

  printf("words:%d %d\n", distinct_count, wm.n_matches);
  exit(wm.n_matches?0:1);
}
#endif
