// Combined test/benchmark program for XOR routines

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>

#include "this_machine.h"
#include "xor.h"

// constant array sizes

#define SIZE_POW_2    12	/* 4,096 entries */
#define SIZE_IN_WORDS (1<<SIZE_POW_2)
#define SIZE_IN_BYTES ((sizeof(native_register_t)) * SIZE_IN_WORDS)

// use static arrays rather than faffing around with malloc
char __attribute__((aligned(__BIGGEST_ALIGNMENT__))) src[SIZE_IN_BYTES];
char __attribute__((aligned(__BIGGEST_ALIGNMENT__))) dst[SIZE_IN_BYTES];

// list all test and check types
typedef enum {
  // which xor routine to call:
  NONE,
  BYTE_XOR,
  WORD_XOR,
  // what do we expect each address range to contain after test(s)?
  IS_SRC,
  IS_ZERO,
  // end of test marker
  END_OF_TESTS,
} test_type;

// give names to each of the above enums so we can print them
char *check_name[END_OF_TESTS] = {
  "NONE", "BYTE_XOR", "WORD_XOR", "IS_SRC", "IS_ZERO",
};

typedef struct {
  // we call up to two xors per test
  test_type      test_a;
  unsigned long  a_start;
  unsigned long  a_bytes;
  unsigned       test_b;
  unsigned long  b_start;
  unsigned long  b_bytes;
  // Since we can have different, overlapping ranges for each test, we
  // can have three distinct regions. To avoid dealing with too many
  // cases, assume |test b| <= |test a| and:
  //   test_a_start <=  test_b_start, test_a_end >= test_b_end
  // See actual test code for details
  unsigned       check_a;	// test_a_start <= i < test_b_start
  unsigned       check_b;	// test_b_start <= i < test_b_end
  unsigned       check_c;	// test_b_end   <= i < test_a_end
  char          *desc;
}  test_entry_t;

//
// Test cases
//
test_entry_t tests[] = {

  // First a few self-checks to make sure our dest array is zeroed out
  // at the start and that our check routine works correctly on zeroes
  { NONE, 0, 0, NONE, 0, 0, IS_ZERO, IS_ZERO, IS_ZERO, "*Self-check: IS_ZERO (null)"},
  { NONE, 0, SIZE_IN_BYTES, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_ZERO, "*Self-check: IS_ZERO (all)"},
  { NONE, 0, SIZE_IN_BYTES, NONE, 0, SIZE_IN_BYTES,
    IS_ZERO, IS_ZERO, IS_ZERO, "*Self-check: IS_ZERO (both)"},
  { NONE, 0, SIZE_IN_BYTES>>1, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_ZERO, "*Self-check: IS_ZERO (first half)"},
  { NONE, SIZE_IN_BYTES>>1, SIZE_IN_BYTES>>1, NONE, SIZE_IN_BYTES>>1, 0,
    IS_ZERO, IS_ZERO, IS_ZERO, "*Self-check: IS_ZERO (second half)"},

  // Test bytewise_xor with a single xor pass
  { BYTE_XOR, 0, 0, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_ZERO, "*Self-check: BYTE_XOR (null)"},
  { BYTE_XOR, 0, 1, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "*Self-check: BYTE_XOR (1 byte)"},
  { BYTE_XOR, 0, 2, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "*Self-check: BYTE_XOR (2 bytes)"},
  { BYTE_XOR, 0, 3, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "*Self-check: BYTE_XOR (3 bytes)"},
  { BYTE_XOR, 0, 4, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "*Self-check: BYTE_XOR (4 bytes)"},
  { BYTE_XOR, 0, 5, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "*Self-check: BYTE_XOR (5 bytes)"},
  { BYTE_XOR, 0, SIZE_IN_BYTES, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "*Self-check: BYTE_XOR (full array)"},

  // Test bytewise_xor with a two xor passes
  { BYTE_XOR, 0, 0, BYTE_XOR, 0, 0,
    IS_ZERO, IS_ZERO, IS_ZERO, "*Self-check: BYTE_XOR (null, 2-pass)"},
  { BYTE_XOR, 0, 1, BYTE_XOR, 0, 1, 
    IS_ZERO, IS_ZERO, IS_ZERO, "*Self-check: BYTE_XOR (1 byte, 2-pass)"},
  { BYTE_XOR, 0, 2, BYTE_XOR, 0, 2, 
    IS_ZERO, IS_ZERO, IS_ZERO, "*Self-check: BYTE_XOR (2 bytes, 2-pass)"},
  { BYTE_XOR, 0, 3, BYTE_XOR, 0, 3, 
    IS_ZERO, IS_ZERO, IS_ZERO, "*Self-check: BYTE_XOR (3 bytes, 2-pass)"},
  { BYTE_XOR, 0, 4, BYTE_XOR, 0, 4, 
    IS_ZERO, IS_ZERO, IS_ZERO, "*Self-check: BYTE_XOR (4 bytes, 2-pass)"},
  { BYTE_XOR, 0, 5, BYTE_XOR, 0, 5, 
    IS_ZERO, IS_ZERO, IS_ZERO, "*Self-check: BYTE_XOR (5 bytes, 2-pass)"},
  { BYTE_XOR, 0, SIZE_IN_BYTES, BYTE_XOR, 0, SIZE_IN_BYTES, 
    IS_ZERO, IS_ZERO, IS_ZERO, "*Self-check: BYTE_XOR (full array, 2-pass)"},

  // Test bytewise xor of test b inside test a
  // (makes use of repeated array pattern 1..255,1..255,1..255)
  { BYTE_XOR, 0, 255 * 3, BYTE_XOR, 255, 255, 
    IS_SRC, IS_ZERO, IS_SRC, "*Self-check: BYTE_XOR (inner)"},


  // Test aligned_word_xor with a single xor pass. To test that
  // everything works up to 128-bit register sizes (8 bytes), we need
  // up to 7 + 64 + 7 test cases (7's for misalignment, and up to 7 *
  // 8-byte words). I'm going to make do with just 20 instead, but
  // also repeat the test with everything offset by 1.
  { WORD_XOR, 0, 0, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_ZERO, "WORD_XOR (null)"},
  { WORD_XOR, 0, 1, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (1 byte)"},
  { WORD_XOR, 0, 2, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (2 bytes)"},
  { WORD_XOR, 0, 3, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (3 bytes)"},
  { WORD_XOR, 0, 4, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (4 bytes)"},
  { WORD_XOR, 0, 5, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (5 bytes)"},
  { WORD_XOR, 0, 6, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (6 bytes)"},
  { WORD_XOR, 0, 7, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (7 bytes)"},
  { WORD_XOR, 0, 8, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (8 bytes)"},
  { WORD_XOR, 0, 9, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (9 bytes)"},
  { WORD_XOR, 0, 10, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (10 bytes)"},
  { WORD_XOR, 0, 11, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (11 bytes)"},
  { WORD_XOR, 0, 12, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (12 bytes)"},
  { WORD_XOR, 0, 13, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (13 bytes)"},
  { WORD_XOR, 0, 14, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (14 bytes)"},
  { WORD_XOR, 0, 15, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (15 bytes)"},
  { WORD_XOR, 0, 16, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (16 bytes)"},
  { WORD_XOR, 0, 17, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (17 bytes)"},
  { WORD_XOR, 0, 18, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (18 bytes)"},
  { WORD_XOR, 0, 19, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (19 bytes)"},
  { WORD_XOR, 0, 20, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (20 bytes)"},
  { WORD_XOR, 0, SIZE_IN_WORDS, NONE, 0, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (full array)"},

  // same as above, offset by 1 byte
  { WORD_XOR, 1, 0, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_ZERO, "WORD_XOR (null, +1)"},
  { WORD_XOR, 1, 1, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (1 byte, +1)"},
  { WORD_XOR, 1, 2, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (2 bytes, +1)"},
  { WORD_XOR, 1, 3, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (3 bytes, +1)"},
  { WORD_XOR, 1, 4, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (4 bytes, +1)"},
  { WORD_XOR, 1, 5, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (5 bytes, +1)"},
  { WORD_XOR, 1, 6, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (6 bytes, +1)"},
  { WORD_XOR, 1, 7, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (7 bytes, +1)"},
  { WORD_XOR, 1, 8, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (8 bytes, +1)"},
  { WORD_XOR, 1, 9, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (9 bytes, +1)"},
  { WORD_XOR, 1, 10, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (10 bytes, +1)"},
  { WORD_XOR, 1, 11, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (11 bytes, +1)"},
  { WORD_XOR, 1, 12, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (12 bytes, +1)"},
  { WORD_XOR, 1, 13, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (13 bytes, +1)"},
  { WORD_XOR, 1, 14, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (14 bytes, +1)"},
  { WORD_XOR, 1, 15, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (15 bytes, +1)"},
  { WORD_XOR, 1, 16, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (16 bytes, +1)"},
  { WORD_XOR, 1, 17, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (17 bytes, +1)"},
  { WORD_XOR, 1, 18, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (18 bytes, +1)"},
  { WORD_XOR, 1, 19, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (19 bytes, +1)"},
  { WORD_XOR, 1, 20, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (20 bytes, +1)"},
  { WORD_XOR, 1, SIZE_IN_WORDS-1, NONE, 1, 0,
    IS_ZERO, IS_ZERO, IS_SRC, "WORD_XOR (full array-1, +1)"},


  // aligned_word_xor inner test
  { WORD_XOR, 0, 255 * 3, WORD_XOR, 255, 255, 
    IS_SRC, IS_ZERO, IS_SRC, "WORD_XOR (inner)"},


  { END_OF_TESTS, 0, 0, END_OF_TESTS, 0, 0, NONE, NONE, NONE, "No more tests" },
};


void xor_range(int xor_type, unsigned long start, unsigned long bytes) {

  unsigned long i;

  // sanity check test (catch problems with test specification or test harness)
  assert(start >= 0);
  assert(start + bytes <= SIZE_IN_BYTES);
  assert((xor_type == NONE) || (xor_type == BYTE_XOR) || (xor_type == WORD_XOR));

  if (bytes == 0)       return;
  if (xor_type == NONE) return;

  if (xor_type == BYTE_XOR) {
    bytewise_xor(&dst[start],&src[start],bytes);
  } else {			// must be WORD_XOR
    aligned_word_xor(&dst[start],&src[start],bytes);
  }
}


// return true if given range in dest array satisfies test condition
int test_range(int test_type, unsigned long start, unsigned long bytes) {

  unsigned long i;

  // sanity check test (catch problems with test specification or test harness)
  assert(start >= 0);
  assert(start + bytes <= SIZE_IN_BYTES);
  assert((test_type == NONE) || (test_type == IS_ZERO) || (test_type == IS_SRC));

  if (bytes == 0)        return 1;
  if (test_type == NONE) return 1;

  if (test_type == IS_ZERO) {
    for(i=0; i<bytes; ++i) {
      if (dst[start+i] != '\0') { printf("Wasn't zero\n"); return 0; }
    }
  } else {			// must be IS_SRC
    for(i=0; i<bytes; ++i) {
      if (dst[start+i] != src[start+i]) { printf("Wasn't source\n"); return 0; }
    }
  }
  return 1;
}

unsigned long min_value(unsigned long a, unsigned long b) {
  return (a<b)? a : b;
}

unsigned long max_value(unsigned long a, unsigned long b) {
  return (a<b)? b : a;
}

void init_dest(void) {

  (void) memset(dst,'\0',SIZE_IN_BYTES);
}

void init_arrays(void) {
  
  int i;
  char c;

  init_dest();

  for (c='\001', i=0; i<SIZE_IN_BYTES; ++i, ++c) {
    if (c == '\0') { c='\001'; }
    src[i] = c;
  }
}

int do_test(test_entry_t *tp, int invert) {

  // variables for ranges
  unsigned long r0, b0;		// range before both xor ranges
  unsigned long r1, b1;		// range unique to first test (start)
  unsigned long r2, b2;		// range where tests overlap
  unsigned long r3, b3;		// range unique to first test (end)
  unsigned long r4, b4;		// range after both xor ranges

  int result;

  // sanity check test ranges specified in test case
  assert(tp->a_start <= tp->b_start);
  assert(tp->a_start + tp->a_bytes >= tp->b_start + tp->b_bytes);
  assert(tp->a_start + tp->a_bytes <= SIZE_IN_BYTES);
  assert(tp->b_start + tp->b_bytes <= SIZE_IN_BYTES);

  // check invert variable
  assert(invert == 0 || invert == 1);
  invert ^= 1;			// lets us eliminate logical not later

  // clear destination array
  init_dest();

  printf("Test: %s\n", tp->desc);

  // calculate the bounds of the five ranges
  r0 = 0;
  b0 = tp->a_start;

  r1 = tp->a_start;
  b1 = tp->b_start - r1;

  r2 = tp->b_start;
  b2 = tp->b_bytes;

  r3 = tp->b_start + tp->b_bytes;
  b3 = tp->a_start + tp->a_bytes - r3;

  r4 = tp->a_start + tp->a_bytes;
  b4 = SIZE_IN_BYTES - r4;

  // do the xors
  xor_range(tp->test_a, tp->a_start, tp->a_bytes);
  xor_range(tp->test_b, tp->b_start, tp->b_bytes);

  // do the checks
  result = test_range(IS_ZERO, r0, b0);
  if (result ^ invert) {
    printf("%s: leading range [%ld,+%ld] was not zero\n", tp->desc,r0,b0);
    return 0;			// false value => failure
  }

  result = test_range(tp->check_a, r1, b1);
  if (result ^ invert) {
    printf("%s: leading 'a' range failed %s check\n", tp->desc, check_name[tp->check_a]);
    return 0;
  }

  result = test_range(tp->check_b, r2, b2);
  if (result ^ invert) {
    printf("%s: overlapping range failed %s check\n", tp->desc, check_name[tp->check_b]);
    return 0;
  }

  result = test_range(tp->check_c, r3, b3);
  if (result ^ invert) {
    printf("%s: trailing 'a' range failed %s check\n", tp->desc, check_name[tp->check_c]);
    return 0;
  }

  result = test_range(IS_ZERO, r4, b4);
  if (result ^ invert) {
    printf("%s: trailing range [%ld,+%ld] was not zero\n", tp->desc,r4,b4);
    return 0;
  }

  return 1;
}

// test_harness returns the number of tests passed
int test_harness(void) {

  int passed = 0;
  test_entry_t *tp = tests;
  int is_required, invert, result;
  int rand_trials = 10000;
  unsigned long start,bytes;

  // do all the individual tests from the list
  while(tp->test_a != END_OF_TESTS) {

    is_required = 0; invert = 0;

    // check whether description starts with '*' or '!'
    while ((tp->desc)[0] == '*' || (tp->desc)[0] == '!') {
      if ((tp->desc)[0] == '*') {
	is_required = 1;
      }
      if ((tp->desc)[0] == '!') {
	invert ^= 1;
      }
      ++(tp->desc);
    }

    result = do_test(tp,invert);

    if (result) {
      ++passed;
    } else {
      if (is_required) {
	printf("Failed required test: aborting remaining tests\n");
	return passed;
      }
    }

    ++tp;
  }

  // do random test: first xor with bytewise, then do same xor with
  // aligned_word_xor and check that dest array is zero after each
  // pair.
  srand(1);
  printf("Doing %d random XOR trials\n", rand_trials);
  init_dest();
  while(rand_trials--) {
    start = rand() % SIZE_IN_BYTES;
    bytes = rand() % (SIZE_IN_BYTES - start);
    assert(start + bytes <= SIZE_IN_BYTES);
    bytewise_xor(&dst[start],&src[start],bytes);
    aligned_word_xor(&dst[start],&src[start],bytes);
    result = test_range(IS_ZERO,0,SIZE_IN_BYTES);
    if (!result) {
      printf("Failed random trials\n");
      break;
    }
  }

  if (rand_trials <= 0) {
    printf("Passed random trials\n");
    ++passed; 
  }

  return passed;
}

// simple benchmarks to compare bytewise_xor and aligned_word_xor performance
void do_benchmarks(void) {

  // we need better than the 1s granularity provided by time()
  struct timespec start_time, end_time;

  long long delta_ns;
  int retval;

  long long ns_per_test = 1000000000ll; // 1 second

  int  lengths[] = {1, 4, 8, 16, 32, SIZE_IN_BYTES - sizeof(native_register_t)};
  unsigned long byte_runs[6] = { 0,0,0,0,0,0};
  unsigned long word_runs[6] = { 0,0,0,0,0,0};
  int i,j,offset;
  int batch_size = 250;

  printf("Running benchmarks with batch size of %d\n", batch_size);
  printf("Each test takes %.2fs to run\n", ((float)ns_per_test) / 1000000000.0);
  printf("Lower scores below are better\n\n");

  for (offset = sizeof(native_register_t) - 1; offset >= 0 ; --offset) {

    printf("Testing offset %d\n", offset);

    for (i=0; i < 6; ++i) {

      printf("  String size in bytes: %d\n",lengths[i]);

      // start clock
      retval = clock_gettime(CLOCK_REALTIME,&start_time);
      assert (retval == 0);

      do {
	// do a batch of xors
	for (j=0; j<batch_size; ++j) {
	  bytewise_xor(&dst[offset],&src[offset],lengths[i]);
	}
	byte_runs[i] += batch_size;

	// end clock
	retval = clock_gettime(CLOCK_REALTIME,&end_time);
	assert (retval == 0);
	delta_ns = end_time.tv_nsec - start_time.tv_nsec;
	delta_ns += 1000000000ll * (end_time.tv_sec - start_time.tv_sec);

      } while (delta_ns < ns_per_test);

      printf("    bytewise= %f ns/byte\n",
	     ((float) delta_ns / (lengths[i] * (float) byte_runs[i])));

      // start clock
      retval = clock_gettime(CLOCK_REALTIME,&start_time);
      assert (retval == 0);

      do {
	// do a batch of xors
	for (j=0; j<batch_size; ++j) {
	  aligned_word_xor(&dst[offset],&src[offset],lengths[i]);
	}
	word_runs[i] += batch_size;

	// end clock
	retval = clock_gettime(CLOCK_REALTIME,&end_time);
	assert (retval == 0);
	delta_ns = end_time.tv_nsec - start_time.tv_nsec;
	delta_ns += 1000000000 * (end_time.tv_sec - start_time.tv_sec);

      } while (delta_ns < ns_per_test);

      printf("    wordwise= %f ns/byte\n\n", 
	     ((float) delta_ns / (lengths[i] * (float) word_runs[i])));

    }
  }
}


int main(int ac, char **av) {
  printf("Passed %d of %d tests\n", test_harness(), sizeof(tests)/sizeof(test_entry_t));

  do_benchmarks();

}
  
