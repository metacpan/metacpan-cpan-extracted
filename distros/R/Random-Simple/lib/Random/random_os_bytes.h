#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

// We define two functions here: _get_os_random_bytes() and _get_os_rand64()
//
// These functions fetch random data from the OS CSRNG that is suitable for using
// as seeds for our PRNGs.
//
// Using ifdefs these functions operate differently on Windows vs other operating
// systems. On Windows we use the BCryptGenRandom function available starting in
// Windows Vista. If you are on something older than that you are out of luck
//
// Linux/Mac/BSD read from /dev/urandom

///////////
// Win32 //
///////////

#ifdef _WIN32
#include <windows.h>
#include <bcrypt.h>

// Link with bcrypt.lib
#pragma comment(lib, "bcrypt.lib")

// Fill a buffer with random bytes
int32_t _get_os_random_bytes(uint8_t* buf, uint16_t num) {
	// Init buffer to all zeros
	memset(buf, '\0', num);

	// Use BCryptGenRandom on Windows
	int status = BCryptGenRandom(NULL, (PUCHAR)buf, num, BCRYPT_USE_SYSTEM_PREFERRED_RNG);

	if (status != 0) {
		return -1;
	}

	return num;
}

// Build an 8 byte uint64_t
uint64_t _get_os_rand64() {
	uint64_t randomValue = 0;

	// Use BCryptGenRandom on Windows
	int status = BCryptGenRandom(NULL, (PUCHAR)&randomValue, sizeof(randomValue), BCRYPT_USE_SYSTEM_PREFERRED_RNG);
	if (status != 0) {
		printf("Error: status of BCryptGenRandom is non-zero");
		return 0;
	}

	return randomValue;
}

#else

//////////////////////////////////////////////
// Linux/BSD/Mac anything with /dev/urandom //
//////////////////////////////////////////////

/*#include <fcntl.h>*/
/*#include <unistd.h>*/

int32_t _get_os_random_bytes(uint8_t* buffer, uint16_t num) {
	// printf("Reading %i bytes from /dev/urandom\n", num);

	// If num is 0 or buffer is NULL, return an error code
	if (num == 0 || buffer == NULL) {
		return -1;
	}

	// Open /dev/urandom
	FILE *urandom = fopen("/dev/urandom", "rb");
	if (!urandom) {
		return -2; // Return an error code if /dev/urandom is not readable
	}

	// Read num bytes from /dev/urandom
	size_t bytesRead = fread(buffer, 1, num, urandom);
	fclose(urandom);

	// If we couldn't read the requested number of bytes, return an error code
	if (bytesRead != num) {
		return -3;
	}

	return num; // Success
}

uint64_t _get_os_rand64() {
	uint64_t randomValue = 0;

	// Open /dev/urandom
	int fd = open("/dev/urandom", O_RDONLY);
	if (fd < 0) {
		printf("Error: could not open /dev/urandom");
		exit(1);
	}

	// Read 8 bytes
	ssize_t result = read(fd, &randomValue, sizeof(randomValue));
	if (result != sizeof(randomValue)) {
		printf("Error: could not read enough bytes from /dev/urandom");
		exit(2);
	}

	close(fd);
	return randomValue;
}

#endif
