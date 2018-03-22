/* $Id: Ed25519.h 1649 2018-03-12 15:39:47Z willem $
 *
 *	How To Include Support for Ed25519
 *	==================================
 *
 *	Unfortunately, the Edwards curve cryptography implementation
 *	in the OpenSSL libcrypto library is not directly accessible.
 *
 *	In order to overcome this obstacle, it is necessary to link
 *	the object code directly into the Net::DNS::SEC XS component.
 *
 *	Proceed as follows:
 *
 *	1) Create empty subdirectory
 *		cd /tmp/Net-DNS-SEC-1.??
 *		mkdir curve25519
 *
 *	2) Build OpenSSL from source
 *		cd /tmp
 *		tar xvzf openssl-1.1.1?.tar.gz
 *		cd openssl-1.1.1?
 *		./config shared
 *		make
 *
 *	3) Copy compiled object
 *		cd crypto/ec
 *		cp curve25519.o /tmp/Net-DNS-SEC-1.??/curve25519
 *
 *	4) Build Net::DNS::SEC
 *		cd /tmp/Net-DNS-SEC-1.??
 *		perl MakeFile.PL
 *		make
 *		make test
 *
 *	Note: The entire process is VERY architecture-sensitive.
 */

int ED25519_sign(uint8_t *out_sig, const uint8_t *message, size_t message_len,
		const uint8_t public_key[32], const uint8_t private_key[32]);

int ED25519_verify(const uint8_t *message, size_t message_len,
		const uint8_t signature[64], const uint8_t public_key[32]);

void ED25519_public_from_private(uint8_t out_public_key[32],
				const uint8_t private_key[32]);

