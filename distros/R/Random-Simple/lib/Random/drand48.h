//////////////////////////////////////////////////////////////////////////////
// Internally Perl uses drand48 for it's rand() function. This is a ChatGPT
// recreated version of drand48 and should *NOT* be used. It's here
// strictly as proof of concept. There are much better PRNGs to use in 2024.
//////////////////////////////////////////////////////////////////////////////

#include <stdint.h>
#include <stdio.h>

static uint64_t seed = 0;

// Generates a random floating-point number between [0.0, 1.0)
static double drand48_custom() {
    const uint64_t a = 0x5DEECE66D;
    const uint64_t c = 0xB;
    const uint64_t m = (1ULL << 48);

    // Update the seed with LCG formula
    seed = (a * seed + c) & (m - 1);

    // Return the result as a double in [0.0, 1.0)
    return (double)seed / m;
}

// Initialize the seed
static void _seed(uint64_t seed1, uint64_t seed2) {
    seed = seed1;
	//printf("DRAND_SEED: %ull\n", seed);
}

static uint32_t _rand32() {
	double num = drand48_custom();

	uint32_t ret = num * 4294967295ul; // 2**32 - 1

	return ret;
}

static uint64_t _rand64() {
	double num = drand48_custom();

	uint64_t ret = num * 18446744073709551615ull; // 2**64 - 1

	return ret;
}
