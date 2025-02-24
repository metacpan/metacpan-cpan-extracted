#include <stdint.h>

static inline uint64_t rotl(const uint64_t x, int k) {
	return (x << k) | (x >> (64 - k));
}

static uint64_t s[2];

static uint64_t _rand64(void) {
	const uint64_t s0 = s[0];
	uint64_t s1 = s[1];
	const uint64_t result = s0 + s1;

	s1 ^= s0;
	s[0] = rotl(s0, 24) ^ s1 ^ (s1 << 16); // a, b
	s[1] = rotl(s1, 37); // c

	return result;
}

static uint32_t _rand32(void) {
	const uint32_t ret = _rand64() >> 32;

	return ret;
}

static void _seed(uint64_t seed1, uint64_t seed2) {
	s[0] = seed1;
	s[1] = seed2;

	//printf("XorSeed: %lu / %lu\n", seed1, seed2);
}
