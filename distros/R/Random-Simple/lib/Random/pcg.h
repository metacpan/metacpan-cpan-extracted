#include <stdint.h>
#include <time.h>

// additional c code goes here
typedef struct { uint64_t state;  uint64_t inc; } pcg32_random_t;

pcg32_random_t xxx;

void pcg32_seed(uint64_t seed1, uint64_t seed2) {
	xxx.state = seed1;
	xxx.inc   = seed2;

	//printf("Seed: %lu / %lu\n", seed1, seed2);
}

uint32_t pcg32_random_r(pcg32_random_t* rng) {
    uint64_t oldstate = rng->state;
    // Advance internal state
    rng->state = oldstate * 6364136223846793005ULL + (rng->inc|1);
    // Calculate output function (XSH RR), uses old state for max ILP
    uint32_t xorshifted = ((oldstate >> 18u) ^ oldstate) >> 27u;
    uint32_t rot = oldstate >> 59u;
    return (xorshifted >> rot) | (xorshifted << ((-rot) & 31));
}

uint64_t rand64() {
	uint64_t high = pcg32_random_r(&xxx);
	uint32_t low  = pcg32_random_r(&xxx);

	uint64_t ret = (high << 32) | low;

	/*printf("R: %lu %lu %lu\n", ret, high, low);*/

	return ret;
}

uint32_t rand32() {
	uint32_t ret = pcg32_random_r(&xxx);

	return ret;
}

