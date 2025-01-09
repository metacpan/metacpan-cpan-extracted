#include <time.h> // for clock_gettime()

// Nanoseconds since Unix epoch
uint64_t nanos() {
	struct timespec ts;

	// int8_t ok = clock_gettime(CLOCK_MONOTONIC, &ts); // Uptime
	int8_t ok = clock_gettime(CLOCK_REALTIME, &ts);  // Since epoch

	if (ok != 0) {
		return 0; // Return 0 on failure (you can handle this differently)
	}

	// Calculate nanoseconds
	uint64_t ret = (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;

	return ret;
}
