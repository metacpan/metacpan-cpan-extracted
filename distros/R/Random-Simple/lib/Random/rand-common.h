// Borrowed from https://www.pcg-random.org/posts/bounded-rands.html
static uint32_t _bounded_rand(uint32_t range) {
	uint32_t x = _rand32();
	uint64_t m = (uint64_t)x * (uint64_t)range;
	uint32_t l = (uint32_t)m;

	if (l < range) {
		uint32_t t = -range;
		if (t >= range) {
			t -= range;
			if (t >= range)
				t %= range;
		}
		while (l < t) {
			x = _rand32();
			m = (uint64_t)x * (uint64_t)range;
			l = (uint32_t)m;
		}
	}

	return m >> 32;
}
