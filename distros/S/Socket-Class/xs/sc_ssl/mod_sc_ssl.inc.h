#ifndef _MOD_SC_SSL_H_
#define _MOD_SC_SSL_H_ 1

#ifndef _MOD_SC_H_
/* include mod_sc.h */
/* !include mod_sc.h */
#endif

/* default ssl key and certificate */
/* !include default_pk */
/* !include default_crt */

typedef struct st_mod_sc_ssl		mod_sc_ssl_t;
typedef struct st_sc_ssl_ctx		sc_ssl_ctx_t;

struct st_mod_sc_ssl {
/* st_mod_sc included by Makefile.PL */
/* !include st_mod_sc */
/* ssl extension starts here */
	const char *sc_ssl_version; /* XS_VERSION */
	int (*sc_ssl_create_server_context) ( sc_t *socket );
	int (*sc_ssl_create_client_context) ( sc_t *socket );
	int (*sc_ssl_set_certificate) ( sc_t *socket, const char *fn );
	int (*sc_ssl_set_private_key) ( sc_t *socket, const char *fn );
	int (*sc_ssl_set_client_ca) ( sc_t *socket, const char *fn );
	int (*sc_ssl_set_verify_locations) (
		sc_t *socket, const char *cafile, const char *capath
	);
	int (*sc_ssl_check_private_key) ( sc_t *socket );
	int (*sc_ssl_enable_compatibility) ( sc_t *socket );
	const char *(*sc_ssl_get_cipher_name) ( sc_t *socket );
	const char *(*sc_ssl_get_cipher_version) ( sc_t *socket );
	/* since version 1.1 */
	const char *(*sc_ssl_get_version) ( sc_t *socket );
	/* since version 1.2, changed in version 1.31 */
	int (*sc_ssl_starttls) ( sc_t *socket, char **args, int argc );
	/* since version 1.3 */
	int (*sc_ssl_set_ssl_method) ( sc_t *socket, const char *name );
	int (*sc_ssl_set_cipher_list) ( sc_t *socket, const char *str );
	/* since version 1.32 */
	int (*sc_ssl_read_packet) (
		sc_t *socket, char *separator, size_t max, char **p_buf, int *p_len
	);
	/* since version 1.4 */
	int (*sc_ssl_ctx_create) (
		char **args, int argc, sc_ssl_ctx_t **p_ctx
	);
	int (*sc_ssl_ctx_destroy) ( sc_ssl_ctx_t *ctx );
	int (*sc_ssl_ctx_create_class) ( sc_ssl_ctx_t *ctx, SV **p_sv );
	sc_ssl_ctx_t *(*sc_ssl_ctx_from_class) ( SV *sv );
	int (*sc_ssl_ctx_set_ssl_method) ( sc_ssl_ctx_t *ctx, const char *name );
	int (*sc_ssl_ctx_set_private_key) ( sc_ssl_ctx_t *ctx, const char *pk );
	int (*sc_ssl_ctx_set_certificate) ( sc_ssl_ctx_t *ctx, const char *crt );
	int (*sc_ssl_ctx_set_client_ca) ( sc_ssl_ctx_t *ctx, const char *str );
	int (*sc_ssl_ctx_set_verify_locations) (
		sc_ssl_ctx_t *ctx, const char *cafile, const char *capath
	);
	int (*sc_ssl_ctx_set_cipher_list) ( sc_ssl_ctx_t *ctx, const char *str );
	int (*sc_ssl_ctx_check_private_key) ( sc_ssl_ctx_t *ctx );
	int (*sc_ssl_ctx_enable_compatibility) ( sc_ssl_ctx_t *ctx );
};

#endif /* _MOD_SC_SSL_H_ */
