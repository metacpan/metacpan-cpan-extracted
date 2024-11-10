#include <stdint.h>
#include <time.h>

// additional c code goes here
typedef struct { uint64_t state;  uint64_t inc; } pcg32_random_t;

///////////////////////////////////////////////////////////////////////////
// Private methods
///////////////////////////////////////////////////////////////////////////

static uint32_t pcg32_random_r(pcg32_random_t* rng) {
    uint64_t oldstate = rng->state;
    // Advance internal state
    rng->state = oldstate * 6364136223846793005ULL + (rng->inc|1);
    // Calculate output function (XSH RR), uses old state for max ILP
    uint32_t xorshifted = ((oldstate >> 18u) ^ oldstate) >> 27u;
    uint32_t rot = oldstate >> 59u;
    return (xorshifted >> rot) | (xorshifted << ((-rot) & 31));
}


///////////////////////////////////////////////////////////////////////////
// Public methods
///////////////////////////////////////////////////////////////////////////

pcg32_random_t prng;

static void _seed(uint64_t seed1, uint64_t seed2) {
	prng.state = seed1;
	prng.inc   = seed2;

	//printf("Seed: %lu / %lu\n", seed1, seed2);
}

static uint64_t _rand64() {
	uint64_t high = pcg32_random_r(&prng);
	uint32_t low  = pcg32_random_r(&prng);

	uint64_t ret = (high << 32) | low;

	/*printf("R: %lu %lu %lu\n", ret, high, low);*/

	return ret;
}

static uint32_t _rand32() {
	uint32_t ret = pcg32_random_r(&prng);

	return ret;
}
