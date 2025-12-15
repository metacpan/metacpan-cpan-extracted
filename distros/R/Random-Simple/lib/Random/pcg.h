#include <stdint.h>
#include <time.h>

// additional c code goes here
typedef struct { uint64_t state;  uint64_t inc; } pcg_random_t;

///////////////////////////////////////////////////////////////////////////
// Private methods
///////////////////////////////////////////////////////////////////////////

static uint32_t pcg32_random_r(pcg_random_t* rng) {
    uint64_t oldstate = rng->state;
    // Advance internal state
    rng->state = oldstate * 6364136223846793005ULL + (rng->inc|1);
    // Calculate output function (XSH RR), uses old state for max ILP
    uint32_t xorshifted = ((oldstate >> 18u) ^ oldstate) >> 27u;
    uint32_t rot = oldstate >> 59u;
    return (xorshifted >> rot) | (xorshifted << ((-rot) & 31));
}

// PCG64 RXS-M-XS variant
static inline uint64_t pcg64_random_r(pcg_random_t* rng) {
	//printf("PCG64: %llu / %llu\n", rng->state, rng->inc);

    uint64_t num = ((rng->state >> ((rng->state >> 59) + 5)) ^ rng->state) * 12605985483714917081ull;
    rng->state   = rng->state * 6364136223846793005ull + rng->inc;

    return (num >> 43) ^ num;
}

///////////////////////////////////////////////////////////////////////////
// Public methods
///////////////////////////////////////////////////////////////////////////

pcg_random_t one;

static void _seed(uint64_t seed1, uint64_t seed2) {
	one.state = seed1;
	one.inc   = seed2;

	//printf("One: %lu / %lu\n", one.state, one.inc);
}

static uint64_t _rand64() {
	uint64_t ret = pcg64_random_r(&one);

	return ret;
}

static uint32_t _rand32() {
	uint32_t ret = pcg32_random_r(&one);

	return ret;
}
