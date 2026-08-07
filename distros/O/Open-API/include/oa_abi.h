#ifndef OA_ABI_H
#define OA_ABI_H

/* Shared C ABI between Open::API (the provider) and consumers such as Punk,
 * whose C dispatcher routes and validates an API operation without a Perl
 * frame between the socket and the controller. It is resolved at RUNTIME via
 * Open::API::_abi_ptr - a DBI-style function-pointer table - so there is no
 * link-time symbol coupling and each dist builds and upgrades independently.
 * A consumer reaches the header through ExtUtils::Depends, or vendors a copy
 * pinned at OA_ABI_VERSION, and checks abi_version at boot; a mismatch means
 * "fall back to the Perl-visible match/validate_request", never a crash.
 *
 * The table only ever grows at the end; OA_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version == the version it was written against
 * (or >=, treating later tables as a superset it uses a prefix of).
 *
 * Perl headers (EXTERN.h / perl.h / XSUB.h) must be included before this file
 * so SV, AV, HV, STRLEN and pTHX are defined. */

#define OA_ABI_VERSION 1

typedef struct oa_abi {
    int abi_version;                     /* == OA_ABI_VERSION */

    /* Resolve the opaque API handle from a blessed Open::API SV (what
     * Open::API->new returns). Returns NULL when the SV is not a reference -
     * never croaks, so it is safe to call on the fall-back path. The handle
     * stays valid for the life of the SV; the caller does not free it. */
    void *(*api_of)(pTHX_ SV *api_sv);

    /* Route one request. method and path are given with explicit lengths
     * (path is the request path only, already prefix-stripped by the caller).
     * On a match returns the opaque operation handle and fills `caps` with the
     * raw captured path segments (name => borrowed value SV); on a 405 - the
     * path exists but not for this method - returns NULL and fills `allow`
     * with the upper-case method names (an AV of SVs); on a 404 returns NULL
     * and leaves `allow` empty. `caps` and `allow` are caller-owned and must
     * be empty on entry; either may be NULL to discard that output. */
    void *(*route)(pTHX_ void *api, const char *method, STRLEN mlen,
                   const char *path, STRLEN plen, HV *caps, AV *allow);

    /* Look an operation up by its operationId, for a consumer that dispatches
     * by name rather than by path. Returns the opaque operation handle, or
     * NULL when the id is unknown. */
    void *(*op_by_id)(pTHX_ void *api, SV *op_id);

    /* Validate the raw inputs for a routed operation. `raw` is the hash
     * Open::API/validate_request documents:
     *   { path   => \%captures,          # e.g. the caps from route()
     *     query  => $query_string | \%hash,
     *     header => \%lowercased_headers, # cookies ride the "cookie" header
     *     body   => $raw_bytes | $decoded_ref }
     * On success fills `typed` with the validated, coerced, percent-decoded
     * parameters (the path/query/header/cookie hashes and body, the same shape
     * validate_request returns) and returns 1; on failure pushes error
     * hashrefs into `errors` and returns 0. Both containers are caller-owned
     * and should be empty on entry; either may be NULL to discard it (pass a
     * NULL `typed` to validate without materialising the params). */
    int (*validate)(pTHX_ void *api, void *op, HV *raw, HV *typed, AV *errors);

    /* The operationId SV of a routed operation (borrowed - do not free; copy
     * it if you need to outlive the API object). */
    SV *(*op_id)(pTHX_ void *op);
} oa_abi;

#endif /* OA_ABI_H */
