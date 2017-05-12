/*
 * wumanber_impl.h -- data structures and API for wumanber_impl.c
 *
 * Copyright (C) 2010, Juergen Weigert, Novell inc.
 * Distribute,modify under GPLv2 or GPLv3, or perl license.
 */

#define N_SYMB     256		// characters per byte
#define SHIFT_SZ   4096		// sizeof shift_min
#define PAT_HASH_SZ 8192	// =(1<<13), must be a power of two
#define W_DELIM	   128		// magic, unused
#define L_DELIM    10 		// must be '\n', unused

struct pat_list 
{
  int index;
  struct pat_list *next;
};

struct WuManber
{
  unsigned int n_pat;		// number of patterns;
  unsigned char **patt;		// list of patterns;
  unsigned int *pat_len;	// length array of patterns;

  unsigned char tr[N_SYMB];
  unsigned char tr1[N_SYMB];

  int use_bs3;
  int use_bs1;
  int p_size;
  unsigned char shift_min[SHIFT_SZ];
  struct pat_list *pat_hash[PAT_HASH_SZ];

  int n_matches;
#if 0
  int match_word_boundaries;
  int match_whole_line;
#endif
  int nocase;
  int one_match_per_line;	// report all patterns that match in a line. (unlike agrep)
  int one_match_per_offset;	// report all patterns that would match at an offset. (unlike agrep)

  void (*cb)(unsigned int idx, unsigned long off, void *data);
  void *cb_data;
  char  *progname; 
};

void prep_pat(struct WuManber *wm, int n_pat, unsigned char **pat_p, int nocase);
void search_init(struct WuManber *wm, char *name);
unsigned int search_text(struct WuManber *wm, unsigned char *text, int end);

