#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <mongoc/mongoc.h>
#include <bson/bson.h>
#define XS_BOTHVERSION_SETXSUBFN_POPMARK_BOOTCHECK 1

MODULE = Pongo::Client PACKAGE=Pongo::Client

BOOT:
mongoc_init();

TYPEMAP : <<HERE

mongoc_client_t* T_PTROBJ
mongoc_database_t* T_PTROBJ
const bson_t* T_PTROBJ
mongoc_auto_encryption_opts_t* T_PTROBJ
mongoc_client_pool_t* T_PTROBJ
mongoc_kms_credentials_provider_callback_fn T_PTROBJ
mongoc_tls_opts_t* T_PTROBJ
mongoc_bulkwrite_insertoneopts_t* T_PTROBJ
mongoc_bulkwrite_t* T_PTROBJ
const mongoc_bulkwrite_insertoneopts_t* T_PTROBJ
bson_error_t* T_PTROBJ
mongoc_bulkwrite_updateoneopts_t* T_PTROBJ
const mongoc_bulkwrite_updateoneopts_t* T_PTROBJ
mongoc_bulkwrite_updatemanyopts_t* T_PTROBJ
const bson_value_t* T_PTROBJ
const mongoc_bulkwrite_updatemanyopts_t* T_PTROBJ
mongoc_bulkwrite_replaceoneopts_t* T_PTROBJ
const mongoc_bulkwrite_replaceoneopts_t * T_PTROBJ
mongoc_bulkwrite_deleteoneopts_t* T_PTROBJ
const mongoc_bulkwrite_deleteoneopts_t* T_PTROBJ
mongoc_bulkwrite_deletemanyopts_t* T_PTROBJ
const mongoc_bulkwrite_deletemanyopts_t* T_PTROBJ
mongoc_bulkwritereturn_t T_PTROBJ
const mongoc_bulkwriteopts_t* T_PTROBJ
mongoc_bulkwriteresult_t* T_PTROBJ
mongoc_bulkwriteexception_t* T_PTROBJ
mongoc_client_session_t* T_PTROBJ
mongoc_bulkwriteopts_t* T_PTROBJ
const mongoc_write_concern_t * T_PTROBJ
uint32_t T_PTROBJ
int64_t T_PTROBJ
int32_t T_PTROBJ
const mongoc_bulkwriteresult_t* T_PTROBJ
const mongoc_bulkwriteexception_t * T_PTROBJ
mongoc_bulk_operation_t * T_PTROBJ
bson_t * T_PTROBJ
const mongoc_bulk_operation_t * T_PTROBJ
mongoc_change_stream_t * T_PTROBJ
const mongoc_collection_t * T_PTROBJ
const bson_t ** T_PTROBJ
mongoc_client_encryption_t * T_PTROBJ
mongoc_client_encryption_opts_t * T_PTROBJ
const mongoc_client_encryption_datakey_opts_t * T_PTROBJ
bson_value_t * T_PTROBJ
mongoc_collection_t * T_PTROBJ
mongoc_client_encryption_rewrap_many_datakey_result_t * T_PTROBJ
const mongoc_client_encryption_t * T_PTROBJ
size_t * T_PTROBJ
mongoc_cursor_t * T_PTROBJ
mongoc_client_encryption_encrypt_opts_t * T_PTROBJ
mongoc_client_encryption_datakey_opts_t * T_PTROBJ
const uint8_t * T_PTROBJ
const mongoc_client_encryption_encrypt_range_opts_t * T_PTROBJ
mongoc_client_encryption_encrypt_range_opts_t * T_PTROBJ
const mongoc_uri_t * T_PTROBJ
mongoc_apm_callbacks_t * T_PTROBJ
const mongoc_server_api_t * T_PTROBJ
const mongoc_ssl_opt_t * T_PTROBJ
const mongoc_transaction_opt_t * T_PTROBJ
const mongoc_client_session_t * T_PTROBJ
mongoc_transaction_state_t T_PTROBJ
mongoc_client_session_with_transaction_cb_t T_PTROBJ
const mongoc_session_opt_t * T_PTROBJ
mongoc_server_description_t ** T_PTROBJ
uint32_t * T_PTROBJ
const mongoc_read_prefs_t * T_PTROBJ
mongoc_query_flags_t T_PTROBJ
const mongoc_client_t * T_PTROBJ
char ** T_PTROBJ
mongoc_gridfs_t * T_PTROBJ
mongoc_server_description_t * T_PTROBJ
mongoc_read_prefs_t * T_PTROBJ
const mongoc_read_concern_t * T_PTROBJ
mongoc_session_opt_t * T_PTROBJ
mongoc_stream_initiator_t T_PTROBJ
mongoc_index_model_t * T_PTROBJ
const mongoc_index_opt_t * T_PTROBJ
mongoc_index_model_t ** T_PTROBJ
mongoc_delete_flags_t T_PTROBJ
const mongoc_find_and_modify_opts_t * T_PTROBJ
mongoc_insert_flags_t T_PTROBJ
mongoc_remove_flags_t T_PTROBJ
mongoc_update_flags_t T_PTROBJ
mongoc_host_list_t * T_PTROBJ
const mongoc_cursor_t * T_PTROBJ
const mongoc_database_t * T_PTROBJ
mongoc_find_and_modify_opts_t * T_PTROBJ
mongoc_find_and_modify_flags_t T_PTROBJ
const mongoc_find_and_modify_flags_t T_PTROBJ
mongoc_gridfs_file_list_t * T_PTROBJ
mongoc_gridfs_file_t * T_PTROBJ
mongoc_gridfs_file_opt_t T_PTROBJ
mongoc_iovec_t * T_PTROBJ
const mongoc_iovec_t * T_PTROBJ
uint64_t T_PTROBJ
mongoc_index_opt_geo_t T_PTROBJ
mongoc_stream_t * T_PTROBJ
mongoc_gridfs_bucket_t * T_PTROBJ
mongoc_gridfs_file_opt_t * T_PTROBJ
const mongoc_index_opt_wt_t * T_PTROBJ
const mongoc_optional_t * T_PTROBJ
mongoc_optional_t * T_PTROBJ
const void * T_PTROBJ
mongoc_index_opt_wt_t * T_PTROBJ
mongoc_read_concern_t * T_PTROBJ
mongoc_read_mode_t T_PTROBJ
mongoc_reply_flags_t T_PTROBJ
mongoc_stream_buffered_t T_PTROBJ
mongoc_stream_file_t T_PTROBJ
mongoc_stream_tls_t T_PTROBJ
mongoc_server_api_t * T_PTROBJ
mongoc_server_api_version_t T_PTROBJ
mongoc_server_api_version_t * T_PTROBJ
mongoc_stream_file_t * T_PTROBJ
mongoc_stream_socket_t * T_PTROBJ
mongoc_socket_t * T_PTROBJ
const mongoc_server_description_t * T_PTROBJ
const struct sockaddr * T_PTROBJ
mongoc_socklen_t T_PTROBJ
mongoc_socklen_t * T_PTROBJ
struct sockaddr * T_PTROBJ
mongoc_transaction_opt_t * T_PTROBJ
mongoc_topology_description_t * T_PTROBJ
const mongoc_topology_description_t * T_PTROBJ
const mongoc_index_opt_geo_t * T_PTROBJ
mongoc_index_opt_geo_t * T_PTROBJ
mongoc_index_opt_t * T_PTROBJ
mongoc_uri_t * T_PTROBJ
mongoc_write_concern_t * T_PTROBJ
const mongoc_host_list_t * T_PTROBJ
uint16_t T_PTROBJ

HERE

PROTOTYPES: DISABLE

bool
error_has_label(reply, label)
    const bson_t* reply;
    const char* label;
    CODE:
        // Returns true if reply contains the error label
        RETVAL = mongoc_error_has_label(reply, label);
    OUTPUT:
        RETVAL

mongoc_auto_encryption_opts_t*
auto_encryption_opts_new()
    CODE:
        // Create a new auto-encryption options object
        RETVAL = mongoc_auto_encryption_opts_new();
    OUTPUT:
        RETVAL

void
auto_encryption_opts_destroy(opts)
    mongoc_auto_encryption_opts_t* opts;
    CODE:
        // Destroy the auto-encryption options object
        mongoc_auto_encryption_opts_destroy(opts);

void
auto_encryption_opts_set_keyvault_client(opts, client)
    mongoc_auto_encryption_opts_t* opts;
    mongoc_client_t* client;
    CODE:
        // Set the key vault client for the auto-encryption options
        mongoc_auto_encryption_opts_set_keyvault_client(opts, client);

void
auto_encryption_opts_set_keyvault_client_pool(opts, pool)
    mongoc_auto_encryption_opts_t* opts;
    mongoc_client_pool_t* pool;
    CODE:
        // Set the key vault client pool for the auto-encryption options
        mongoc_auto_encryption_opts_set_keyvault_client_pool(opts, pool);

void
auto_encryption_opts_set_keyvault_namespace(opts, db, coll)
    mongoc_auto_encryption_opts_t* opts;
    const char* db;
    const char* coll;
    CODE:
    // Set the key vault namespace for the auto-encryption options
    mongoc_auto_encryption_opts_set_keyvault_namespace(opts, db, coll);

void
auto_encryption_opts_set_kms_providers(opts, kms_providers)
    mongoc_auto_encryption_opts_t* opts;
    const bson_t* kms_providers;
    CODE:
        // Set the KMS providers for the auto-encryption options
        mongoc_auto_encryption_opts_set_kms_providers(opts, kms_providers);

void
auto_encryption_opts_set_kms_credential_provider_callback(opts, fn, userdata)
    mongoc_auto_encryption_opts_t* opts;
    mongoc_kms_credentials_provider_callback_fn fn;
    void* userdata;
    CODE:
        // Set the KMS credential provider callback for the auto-encryption options
        mongoc_auto_encryption_opts_set_kms_credential_provider_callback(opts, fn, userdata);

void
auto_encryption_opts_set_schema_map(opts, schema_map)
    mongoc_auto_encryption_opts_t* opts;
    const bson_t* schema_map;
    CODE:
        // Set the schema map for the auto-encryption options
        mongoc_auto_encryption_opts_set_schema_map(opts, schema_map);

void
mongoc_auto_encryption_opts_set_bypass_auto_encryption (opts, bypass_auto_encryption);
    mongoc_auto_encryption_opts_t* opts;
    bool bypass_auto_encryption;
    CODE:
        // Set the bypass auto-encryption option for the auto-encryption options
        mongoc_auto_encryption_opts_set_bypass_auto_encryption(opts, bypass_auto_encryption);


void
mongoc_auto_encryption_opts_set_extra(opts, extra)
    mongoc_auto_encryption_opts_t* opts;
    const bson_t* extra;
    CODE:
        // Set the extra options for the auto-encryption options
        mongoc_auto_encryption_opts_set_extra(opts, extra);

void
mongoc_auto_encryption_opts_set_tls_opts(opts, tls_opts)
    mongoc_auto_encryption_opts_t* opts;
    const bson_t* tls_opts;
    CODE:
        // Set the TLS options for the auto-encryption options
        mongoc_auto_encryption_opts_set_tls_opts(opts, tls_opts);

void
mongoc_auto_encryption_opts_set_encrypted_fields_map(opts, encrypted_fields_map)
    mongoc_auto_encryption_opts_t* opts;
    const bson_t* encrypted_fields_map;
    CODE:
        // Set the encrypted fields map for the auto-encryption options
        mongoc_auto_encryption_opts_set_encrypted_fields_map(opts, encrypted_fields_map);

void
mongoc_auto_encryption_opts_set_bypass_query_analysis(opts, bypass_query_analysis)
    mongoc_auto_encryption_opts_t* opts;
    bool bypass_query_analysis;
    CODE:
        // Set the bypass query analysis option for the auto-encryption options
        mongoc_auto_encryption_opts_set_bypass_query_analysis(opts, bypass_query_analysis);

mongoc_bulkwrite_insertoneopts_t*
bulkwrite_insertoneopts_new()
    CODE:
        // Create a new bulk write insert one options object
        RETVAL = mongoc_bulkwrite_insertoneopts_new();
    OUTPUT:
        RETVAL

void
bulkwrite_insertoneopts_destroy(self)
    mongoc_bulkwrite_insertoneopts_t* self;
    CODE:
        // Destroy the bulk write insert one options object
        mongoc_bulkwrite_insertoneopts_destroy(self);

bool
bulkwrite_append_insertone(self, ns, document, opts, error)
    mongoc_bulkwrite_t* self;
    const char* ns;
    const bson_t* document;
    const mongoc_bulkwrite_insertoneopts_t* opts;
    bson_error_t* error;
    CODE:
        if (!self || !ns || !document || !opts) {
            if (error) {
                bson_set_error(error, MONGOC_ERROR_CLIENT, 0, "Invalid arguments provided.");
            }
            RETVAL = false;
        } else {
            // Append an insert one operation to the bulk write object
            RETVAL = mongoc_bulkwrite_append_insertone(self, ns, document, opts, error);
        }
    OUTPUT:
        RETVAL

mongoc_bulkwrite_updateoneopts_t*
bulkwrite_updateoneopts_new()
    CODE:
        // Create a new bulk write update one options object
        RETVAL = mongoc_bulkwrite_updateoneopts_new();
    OUTPUT:
        RETVAL

void
bulkwrite_updateoneopts_set_arrayfilters(self, arrayfilters)
    mongoc_bulkwrite_updateoneopts_t* self;
    const bson_t* arrayfilters;
    CODE:
        // Set the array filters for the bulk write update one options
        mongoc_bulkwrite_updateoneopts_set_arrayfilters(self, arrayfilters);

void
bulkwrite_updateoneopts_set_collation(self, collation)
    mongoc_bulkwrite_updateoneopts_t* self;
    const bson_t* collation;
    CODE:
        // Set the collation for the bulk write update one options
        mongoc_bulkwrite_updateoneopts_set_collation(self, collation);

void
mongoc_bulkwrite_updateoneopts_set_hint(self, hint)
    mongoc_bulkwrite_updateoneopts_t* self;
    const bson_value_t* hint;
    CODE:
        // Set the hint for the bulk write update one options
        mongoc_bulkwrite_updateoneopts_set_hint(self, hint);

void
bulkwrite_updateoneopts_set_upsert(self, upsert)
    mongoc_bulkwrite_updateoneopts_t* self;
    bool upsert;
    CODE:
        // Set the upsert flag for the bulk write update one options
        mongoc_bulkwrite_updateoneopts_set_upsert(self, upsert);

void
bulkwrite_updateoneopts_destroy(self)
    mongoc_bulkwrite_updateoneopts_t* self;
    CODE:
        // Destroy the bulk write update one options object
        mongoc_bulkwrite_updateoneopts_destroy(self);

bool
bulkwrite_append_updateone(self, ns, filter, update, opts, error)
    mongoc_bulkwrite_t* self;
    const char* ns;
    const bson_t* filter;
    const bson_t* update;
    const mongoc_bulkwrite_updateoneopts_t* opts;
    bson_error_t* error;
    CODE:
        if (!self || !ns || !filter || !update || !opts) {
            if (error) {
                bson_set_error(error, MONGOC_ERROR_CLIENT, 0, "Invalid arguments provided.");
            }
            RETVAL = false;
        } else {
            RETVAL = mongoc_bulkwrite_append_updateone(self, ns, filter, update, opts, error);
        }

mongoc_bulkwrite_updatemanyopts_t*
bulkwrite_updatemanyopts_new()
    CODE:
        RETVAL = mongoc_bulkwrite_updatemanyopts_new();
    OUTPUT:
        RETVAL

void
bulkwrite_updatemanyopts_set_arrayfilters(self, arrayfilters)
    mongoc_bulkwrite_updatemanyopts_t* self;
    const bson_t* arrayfilters;
    CODE:
        // Set the array filters for the bulk write update many options
        mongoc_bulkwrite_updatemanyopts_set_arrayfilters(self, arrayfilters);

void
bulkwrite_updatemanyopts_set_collation(self, collation)
    mongoc_bulkwrite_updatemanyopts_t* self;
    const bson_t* collation;
    CODE:
        // Set the collation for the bulk write update many options
        mongoc_bulkwrite_updatemanyopts_set_collation(self, collation);

void
bulkwrite_updatemanyopts_set_hint(self, hint)
    mongoc_bulkwrite_updatemanyopts_t* self;
    const bson_value_t* hint;
    CODE:
        // Set the hint for the bulk write update many options
        mongoc_bulkwrite_updatemanyopts_set_hint(self, hint);

void
bulkwrite_updatemanyopts_set_upsert (self, upsert)
    mongoc_bulkwrite_updatemanyopts_t* self;
    bool upsert;
    CODE:
        mongoc_bulkwrite_updatemanyopts_set_upsert(self, upsert);

void
bulkwrite_updatemanyopts_destroy(self)
    mongoc_bulkwrite_updatemanyopts_t* self;
    CODE:
        mongoc_bulkwrite_updatemanyopts_destroy(self);

bool
bulkwrite_append_updatemany(self, ns, filter, update, opts, error)
    mongoc_bulkwrite_t* self;
    const char* ns;
    const bson_t* filter;
    const bson_t* update;
    const mongoc_bulkwrite_updatemanyopts_t* opts;
    bson_error_t* error;
    CODE:
        if (!self || !ns || !filter || !update || !opts) {
            if (error) {
                bson_set_error(error ,MONGOC_ERROR_CLIENT,0, "Invalid arguments provided.");
            }
            RETVAL = false;
        } else {
            RETVAL = mongoc_bulkwrite_append_updatemany(self, ns, filter, update, opts, error);
        }
    OUTPUT:
        RETVAL

mongoc_bulkwrite_replaceoneopts_t*
bulkwrite_replaceoneopts_new()
    CODE:
        RETVAL = mongoc_bulkwrite_replaceoneopts_new();
    OUTPUT:
        RETVAL

void
bulkwrite_replaceoneopts_set_collation(self, collation)
    mongoc_bulkwrite_replaceoneopts_t* self;
    const bson_t* collation;
    CODE:
        mongoc_bulkwrite_replaceoneopts_set_collation(self, collation);

void
bulkwrite_replaceoneopts_set_hint(self, hint)
    mongoc_bulkwrite_replaceoneopts_t* self;
    const bson_value_t* hint;
    CODE:
        mongoc_bulkwrite_replaceoneopts_set_hint(self, hint);

void
bulkwrite_replaceoneopts_set_upsert(self, upsert)
    mongoc_bulkwrite_replaceoneopts_t *self;
    bool upsert;
    CODE:
        mongoc_bulkwrite_replaceoneopts_set_upsert(self, upsert);

void
bulkwrite_replaceoneopts_destroy(self)
    mongoc_bulkwrite_replaceoneopts_t* self;
    CODE:
        mongoc_bulkwrite_replaceoneopts_destroy(self);

bool
bulkwrite_append_replaceone(self, ns, filter, replacement, opts, error)
    mongoc_bulkwrite_t* self;
    const char *ns;
    const bson_t *filter;
    const bson_t *replacement;
    const mongoc_bulkwrite_replaceoneopts_t *opts;
    bson_error_t *error;
    CODE:
        if (!self || !ns || !filter || !replacement || !opts) {
            if (error) {
                bson_set_error(error, MONGOC_ERROR_CLIENT, 0, "Invalid arguments provided.");
            }
            RETVAL = false;
        } else {
            RETVAL = mongoc_bulkwrite_append_replaceone(self, ns, filter, replacement, opts, error);
        }
    OUTPUT:
        RETVAL

mongoc_bulkwrite_deleteoneopts_t*
bulkwrite_deleteoneopts_new()
    CODE:
        RETVAL = mongoc_bulkwrite_deleteoneopts_new();
    OUTPUT:
        RETVAL

void
bulkwrite_deleteoneopts_destroy(self)
    mongoc_bulkwrite_deleteoneopts_t* self;
    CODE:
        mongoc_bulkwrite_deleteoneopts_destroy(self);

void
bulkwrite_deleteoneopts_set_collation(self, collation)
    mongoc_bulkwrite_deleteoneopts_t* self;
    const bson_t* collation;
    CODE:
        mongoc_bulkwrite_deleteoneopts_set_collation(self, collation);

void
bulkwrite_deleteoneopts_set_hint(self, hint)
    mongoc_bulkwrite_deleteoneopts_t *self;
    const bson_value_t* hint;
    CODE:
        mongoc_bulkwrite_deleteoneopts_set_hint(self, hint);

bool
bulkwrite_append_deleteone(self, ns, filter, opts, error)
    mongoc_bulkwrite_t *self;
    const char* ns;
    const bson_t* filter;
    const mongoc_bulkwrite_deleteoneopts_t *opts;
    bson_error_t *error;
    CODE:
        if (!self || !ns || !filter || !opts) {
            if (error) {
                bson_set_error(error, MONGOC_ERROR_CLIENT, 0, "Invalid arguments provided.");
                RETVAL = false;
            }
        } else {
            RETVAL = mongoc_bulkwrite_append_deleteone(self, ns, filter, opts, error);
        }
    OUTPUT:
        RETVAL

mongoc_bulkwrite_deletemanyopts_t*
bulkwrite_deletemanyopts_new()
    CODE:
        RETVAL = mongoc_bulkwrite_deletemanyopts_new();
    OUTPUT:
        RETVAL

void
bulkwrite_deletemanyopts_destroy (self)
    mongoc_bulkwrite_deletemanyopts_t* self;
    CODE:
        mongoc_bulkwrite_deletemanyopts_destroy(self);

void
bulkwrite_deletemanyopts_set_collation(self, collation)
    mongoc_bulkwrite_deletemanyopts_t* self;
    const bson_t *collation;
    CODE:
        mongoc_bulkwrite_deletemanyopts_set_collation(self, collation);

void
bulkwrite_deletemanyopts_set_hint(self, hint)
    mongoc_bulkwrite_deletemanyopts_t* self;
    const bson_value_t* hint;
    CODE:
        mongoc_bulkwrite_deletemanyopts_set_hint(self, hint);

bool
bulkwrite_append_deletemany(self, ns, filter, opts, error)
    mongoc_bulkwrite_t *self;
    const char *ns;
    const bson_t *filter;
    const mongoc_bulkwrite_deletemanyopts_t *opts;
    bson_error_t *error;
    CODE:
        if (!self || !ns || !filter || !opts) {
            if (error) {
                bson_set_error(error, MONGOC_ERROR_CLIENT, 0, "Invalid arguments provided.");
            }
            RETVAL = false;
        } else {
            RETVAL = mongoc_bulkwrite_append_deletemany(self, ns, filter, opts, error);
        }
    OUTPUT:
        RETVAL

void
bulkwriteresult_destroy(self)
    mongoc_bulkwriteresult_t* self;
    CODE:
        mongoc_bulkwriteresult_destroy(self);

void
bulkwriteexception_destroy(self)
    mongoc_bulkwriteexception_t* self;
    CODE:
        mongoc_bulkwriteexception_destroy(self);

void
bulkwrite_set_session(self, session)
    mongoc_bulkwrite_t* self;
    mongoc_client_session_t* session;
    CODE:
        mongoc_bulkwrite_set_session(self, session);

void
bulkwrite_destroy(self)
    mongoc_bulkwrite_t* self;
    CODE:
        mongoc_bulkwrite_destroy(self);

mongoc_bulkwriteopts_t*
bulkwriteopts_new()
    CODE:
        RETVAL = mongoc_bulkwriteopts_new();
    OUTPUT:
        RETVAL

void
bulkwriteopts_set_ordered(self, ordered)
    mongoc_bulkwriteopts_t *self;
    bool ordered;
    CODE:
        mongoc_bulkwriteopts_set_ordered(self, ordered);

void
bulkwriteopts_set_bypassdocumentvalidation(self, bypassdocumentvalidation)
    mongoc_bulkwriteopts_t *self;
    bool bypassdocumentvalidation;
    CODE:
        mongoc_bulkwriteopts_set_bypassdocumentvalidation(self, bypassdocumentvalidation);

void
bulkwriteopts_set_let(self, let)
    mongoc_bulkwriteopts_t* self;
    const bson_t* let;
    CODE:
        mongoc_bulkwriteopts_set_let(self, let);

void
bulkwriteopts_set_writeconcern(self, writeconcern)
    mongoc_bulkwriteopts_t* self;
    const mongoc_write_concern_t *writeconcern;
    CODE:
        mongoc_bulkwriteopts_set_writeconcern(self, writeconcern);

void
bulkwriteopts_set_comment(self, comment)
    mongoc_bulkwriteopts_t *self;
    const bson_value_t *comment;
    CODE:
        mongoc_bulkwriteopts_set_comment(self, comment);

void
bulkwriteopts_set_verboseresults(self, verboseresults)
    mongoc_bulkwriteopts_t *self;
    bool verboseresults;
    CODE:
        mongoc_bulkwriteopts_set_verboseresults(self, verboseresults);

void
bulkwriteopts_set_extra(self, extra)
    mongoc_bulkwriteopts_t *self;
    const bson_t *extra;
    CODE:
        mongoc_bulkwriteopts_set_extra(self, extra);

void
bulkwriteopts_set_serverid(self, serverid)
    mongoc_bulkwriteopts_t *self;
    uint32_t serverid;
    CODE:
        mongoc_bulkwriteopts_set_serverid(self, serverid);

void
bulkwriteopts_destroy(self)
    mongoc_bulkwriteopts_t *self;
    CODE:
        mongoc_bulkwriteopts_destroy(self);

int64_t
bulkwriteresult_insertedcount(self)
    const mongoc_bulkwriteresult_t* self;
    CODE:
        RETVAL = mongoc_bulkwriteresult_insertedcount(self);
    OUTPUT:
        RETVAL

int64_t
bulkwriteresult_upsertedcount(self)
    const mongoc_bulkwriteresult_t* self;
    CODE:
        RETVAL = mongoc_bulkwriteresult_upsertedcount(self);
    OUTPUT:
        RETVAL

int64_t
bulkwriteresult_matchedcount(self)
    const mongoc_bulkwriteresult_t* self;
    CODE:
        RETVAL = mongoc_bulkwriteresult_matchedcount(self);
    OUTPUT:
        RETVAL

int64_t
bulkwriteresult_modifiedcount(self)
    const mongoc_bulkwriteresult_t* self;
    CODE:
        RETVAL = mongoc_bulkwriteresult_modifiedcount(self);
    OUTPUT:
        RETVAL

int64_t
bulkwriteresult_deletedcount(self)
    const mongoc_bulkwriteresult_t* self;
    CODE:
        RETVAL = mongoc_bulkwriteresult_deletedcount(self);
    OUTPUT:
        RETVAL

const bson_t *
bulkwriteresult_insertresults(self)
    const mongoc_bulkwriteresult_t* self;
    CODE:
        RETVAL = mongoc_bulkwriteresult_insertresults(self);
    OUTPUT:
        RETVAL

const bson_t *
bulkwriteresult_updateresults(self)
    const mongoc_bulkwriteresult_t* self;
    CODE:
        RETVAL = mongoc_bulkwriteresult_updateresults(self);
    OUTPUT:
        RETVAL

const bson_t *
bulkwriteresult_deleteresults(self)
    const mongoc_bulkwriteresult_t* self;
    CODE:
        RETVAL = mongoc_bulkwriteresult_deleteresults(self);
    OUTPUT:
        RETVAL

uint32_t
bulkwriteresult_serverid(self)
    const mongoc_bulkwriteresult_t *self;
    CODE:
        RETVAL = mongoc_bulkwriteresult_serverid(self);
    OUTPUT:
        RETVAL

bool
bulkwriteexception_error(self, error)
    const mongoc_bulkwriteexception_t *self;
    bson_error_t* error;
    CODE:
        mongoc_bulkwriteexception_error(self, error);

const bson_t *
bulkwriteexception_writeerrors(self)
    const mongoc_bulkwriteexception_t *self;
    CODE:
        RETVAL = mongoc_bulkwriteexception_writeerrors(self);
    OUTPUT:
        RETVAL

const bson_t *
bulkwriteexception_writeconcernerrors(self)
    const mongoc_bulkwriteexception_t * self;
    CODE:
        RETVAL = mongoc_bulkwriteexception_writeconcernerrors(self);
    OUTPUT:
        RETVAL

const bson_t *
bulkwriteexception_errorreply(self)
    const mongoc_bulkwriteexception_t *self;
    CODE:
        RETVAL = mongoc_bulkwriteexception_errorreply(self);
    OUTPUT:
        RETVAL

void
bulk_operation_delete(bulk, selector)
    mongoc_bulk_operation_t *bulk;
    const bson_t *selector;
    CODE:
        mongoc_bulk_operation_delete(bulk, selector);

void
bulk_operation_delete_one(bulk, selector)
    mongoc_bulk_operation_t *bulk;
    const bson_t *selector;
    CODE:
        mongoc_bulk_operation_delete_one(bulk, selector);

void
bulk_operation_destroy(bulk)
    mongoc_bulk_operation_t *bulk;
    CODE:
        mongoc_bulk_operation_destroy(bulk);

uint32_t
bulk_operation_execute(bulk, reply, error)
    mongoc_bulk_operation_t *bulk;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_bulk_operation_execute(bulk, reply, error);
    OUTPUT:
        RETVAL

uint32_t
bulk_operation_get_hint(bulk)
    const mongoc_bulk_operation_t *bulk;
    CODE:
        RETVAL = mongoc_bulk_operation_get_hint(bulk);
    OUTPUT:
        RETVAL

uint32_t
bulk_operation_get_server_id(bulk)
    const mongoc_bulk_operation_t *bulk;
    CODE:
        RETVAL = mongoc_bulk_operation_get_server_id(bulk);
    OUTPUT:
        RETVAL

const mongoc_write_concern_t*
bulk_operation_get_write_concern(bulk)
    const mongoc_bulk_operation_t *bulk;
    CODE:
        RETVAL = mongoc_bulk_operation_get_write_concern(bulk);
    OUTPUT:
        RETVAL

void
bulk_operation_insert(bulk, document)
    mongoc_bulk_operation_t *bulk;
    const bson_t *document;
    CODE:
        mongoc_bulk_operation_insert(bulk, document);

bool
bulk_operation_insert_with_opts(bulk, document, opts, error)
    mongoc_bulk_operation_t *bulk;
    const bson_t *document;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_bulk_operation_insert_with_opts(bulk, document, opts, error);
    OUTPUT:
        RETVAL

void
bulk_operation_remove(bulk, selector)
    mongoc_bulk_operation_t *bulk;
    const bson_t *selector;
    CODE:
        mongoc_bulk_operation_remove(bulk, selector);

bool
bulk_operation_remove_many_with_opts(bulk, selector, opts, error)
    mongoc_bulk_operation_t *bulk;
    const bson_t *selector;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_bulk_operation_remove_many_with_opts(bulk, selector, opts, error);
    OUTPUT:
        RETVAL

void
bulk_operation_remove_one(bulk, selector)
    mongoc_bulk_operation_t *bulk;
    const bson_t *selector;
    CODE:
        mongoc_bulk_operation_remove_one(bulk, selector);

bool
bulk_operation_remove_one_with_opts(bulk, selector, opts, error)
    mongoc_bulk_operation_t *bulk;
    const bson_t *selector;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_bulk_operation_remove_one_with_opts(bulk, selector, opts, error);
    OUTPUT:
        RETVAL

void
bulk_operation_replace_one(bulk, selector, document, upsert)
    mongoc_bulk_operation_t *bulk;
    const bson_t *selector;
    const bson_t *document;
    bool upsert;
    CODE:
        mongoc_bulk_operation_replace_one(bulk, selector, document, upsert);

bool
bulk_operation_replace_one_with_opts(bulk, selector, document, opts, error)
    mongoc_bulk_operation_t *bulk;
    const bson_t *selector;
    const bson_t *document;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_bulk_operation_replace_one_with_opts(bulk, selector, document, opts, error);
    OUTPUT:
        RETVAL

void
bulk_operation_set_bypass_document_validation(bulk, bypass)
    mongoc_bulk_operation_t *bulk;
    bool bypass;
    CODE:
        mongoc_bulk_operation_set_bypass_document_validation(bulk, bypass);

void
bulk_operation_set_client_session(bulk, client_session)
    mongoc_bulk_operation_t *bulk;
    mongoc_client_session_t* client_session;
    CODE:
        mongoc_bulk_operation_set_client_session(bulk, client_session);

void
bulk_operation_set_comment(bulk, comment)
    mongoc_bulk_operation_t *bulk;
    const bson_value_t *comment;
    CODE:
        mongoc_bulk_operation_set_comment(bulk, comment);

void
bulk_operation_set_hint(bulk, server_id)
    mongoc_bulk_operation_t *bulk;
    uint32_t server_id;
    CODE:
        mongoc_bulk_operation_set_hint(bulk, server_id);

void
bulk_operation_set_server_id(bulk, server_id)
    mongoc_bulk_operation_t *bulk;
    uint32_t server_id;
    CODE:
        mongoc_bulk_operation_set_server_id(bulk, server_id);

void
bulk_operation_set_let(bulk, let)
    mongoc_bulk_operation_t *bulk;
    const bson_t *let;
    CODE:
        mongoc_bulk_operation_set_let(bulk, let);

void
bulk_operation_update(bulk, selector, document, upsert)
    mongoc_bulk_operation_t *bulk;
    const bson_t *selector;
    const bson_t *document;
    bool upsert;
    CODE:
        mongoc_bulk_operation_update(bulk, selector, document, upsert);

bool
bulk_operation_update_many_with_opts(bulk, selector, document, opts, error)
    mongoc_bulk_operation_t *bulk;
    const bson_t *selector;
    const bson_t *document;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_bulk_operation_update_many_with_opts(bulk, selector, document, opts, error);
    OUTPUT:
        RETVAL

void
bulk_operation_update_one(bulk, selector, document, upsert)
    mongoc_bulk_operation_t *bulk;
    const bson_t *selector;
    const bson_t *document;
    bool upsert;
    CODE:
        mongoc_bulk_operation_update_one(bulk, selector, document, upsert);

bool
bulk_operation_update_one_with_opts(bulk, selector, document, opt, error)
    mongoc_bulk_operation_t *bulk;
    const bson_t *selector;
    const bson_t *document;
    const bson_t *opt;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_bulk_operation_update_one_with_opts(bulk, selector, document, opt, error);
    OUTPUT:
        RETVAL

mongoc_change_stream_t *
client_watch(client, pipeline, opts)
    mongoc_client_t *client;
    const bson_t *pipeline;
    const bson_t *opts;
    CODE:
        RETVAL = mongoc_client_watch(client, pipeline, opts);
    OUTPUT:
        RETVAL

mongoc_change_stream_t *
database_watch(db, pipeline, opts)
    mongoc_database_t *db;
    const bson_t *pipeline;
    const bson_t *opts;
    CODE:
        RETVAL = mongoc_database_watch(db, pipeline, opts);
    OUTPUT:
        RETVAL

mongoc_change_stream_t *
collection_watch(coll, pipeline, opts)
    const mongoc_collection_t *coll;
    const bson_t *pipeline;
    const bson_t *opts;
    CODE:
        RETVAL = mongoc_collection_watch(coll, pipeline, opts);
    OUTPUT:
        RETVAL

bool
change_stream_next(stream, bson)
    mongoc_change_stream_t *stream;
    const bson_t **bson;
    CODE:
        RETVAL = mongoc_change_stream_next(stream, bson);
    OUTPUT:
        RETVAL

const bson_t *
change_stream_get_resume_token(stream)
    mongoc_change_stream_t * stream;
    CODE:
        RETVAL = mongoc_change_stream_get_resume_token(stream);
    OUTPUT:
        RETVAL

bool
change_stream_error_document(stream, err, reply)
    mongoc_change_stream_t *stream;
    bson_error_t *err;
    const bson_t **reply;
    CODE:
        RETVAL = mongoc_change_stream_error_document(stream, err, reply);
    OUTPUT:
        RETVAL

void
change_stream_destroy(stream)
    mongoc_change_stream_t * stream;
    CODE:
        mongoc_change_stream_destroy(stream);

mongoc_client_encryption_t *
client_encryption_new(opts, error)
    mongoc_client_encryption_opts_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_encryption_new(opts, error);
    OUTPUT:
        RETVAL

void
client_encryption_destroy(client_encryption)
    mongoc_client_encryption_t *client_encryption;
    CODE:
        mongoc_client_encryption_destroy(client_encryption);

bool
client_encryption_create_datakey(client_encryption, kms_provider, opts, keyid, error)
    mongoc_client_encryption_t *client_encryption;
    const char *kms_provider;
    const mongoc_client_encryption_datakey_opts_t *opts;
    bson_value_t *keyid;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_encryption_create_datakey(client_encryption, kms_provider, opts, keyid, error);
    OUTPUT:
        RETVAL

mongoc_collection_t *
client_encryption_create_encrypted_collection(enc, database, name, in_options, out_options, kms_provider, opt_masterkey, error)
    mongoc_client_encryption_t *enc;
    mongoc_database_t *database;
    const char *name;
    const bson_t *in_options;
    bson_t *out_options;
    const char *kms_provider;
    const bson_t *opt_masterkey;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_encryption_create_encrypted_collection(enc, database, name, in_options, out_options, kms_provider, opt_masterkey, error);
    OUTPUT:
        RETVAL

bool
client_encryption_rewrap_many_datakey(client_encryption, filter, provider, master_key, result, error)
    mongoc_client_encryption_t *client_encryption;
    const bson_t *filter;
    const char *provider;
    const bson_t *master_key;
    mongoc_client_encryption_rewrap_many_datakey_result_t *result;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_encryption_rewrap_many_datakey(client_encryption, filter, provider, master_key, result, error);
    OUTPUT:
        RETVAL

bool
client_encryption_delete_key(client_encryption, keyid, reply, error)
    mongoc_client_encryption_t *client_encryption;
    const bson_value_t* keyid;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_encryption_delete_key(client_encryption, keyid, reply, error);
    OUTPUT:
        RETVAL

const char *
client_encryption_get_crypt_shared_version(enc)
    const mongoc_client_encryption_t *enc;
    CODE:
        RETVAL = mongoc_client_encryption_get_crypt_shared_version(enc);
    OUTPUT:
        RETVAL

bool
client_encryption_get_key(client_encryption, keyid, key_doc, error)
    mongoc_client_encryption_t *client_encryption;
    const bson_value_t* keyid;
    bson_t *key_doc;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_encryption_get_key(client_encryption, keyid, key_doc, error);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
client_encryption_get_keys(client_encryption, error)
    mongoc_client_encryption_t *client_encryption;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_encryption_get_keys(client_encryption, error);
    OUTPUT:
        RETVAL

bool
client_encryption_add_key_alt_name(client_encryption, keyid, keyaltname, key_doc, error)
    mongoc_client_encryption_t *client_encryption;
    const bson_value_t* keyid;
    const char *keyaltname;
    bson_t *key_doc;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_encryption_add_key_alt_name(client_encryption, keyid, keyaltname, key_doc, error);
    OUTPUT:
        RETVAL

bool
client_encryption_remove_key_alt_name(client_encryption, keyid, keyaltname, key_doc, error)
    mongoc_client_encryption_t *client_encryption;
    const bson_value_t* keyid;
    const char *keyaltname;
    bson_t *key_doc;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_encryption_remove_key_alt_name(client_encryption, keyid, keyaltname, key_doc, error);
    OUTPUT:
        RETVAL

bool
client_encryption_get_key_by_alt_name(client_encryption, keyaltname, key_doc, error)
    mongoc_client_encryption_t *client_encryption;
    const char *keyaltname;
    bson_value_t *key_doc;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_encryption_get_key_by_alt_name(client_encryption, keyaltname, key_doc, error);
    OUTPUT:
        RETVAL

bool
client_encryption_encrypt_expression(client_encryption, expr, opts, expr_out, error)
    mongoc_client_encryption_t *client_encryption;
    const bson_t *expr;
    mongoc_client_encryption_encrypt_opts_t *opts;
    bson_t *expr_out;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_encryption_encrypt_expression(client_encryption, expr, opts, expr_out, error);
    OUTPUT:
        RETVAL

bool
client_encryption_decrypt(client_encryption, ciphertext, value, error)
    mongoc_client_encryption_t *client_encryption;
    const bson_value_t *ciphertext;
    bson_value_t *value;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_encryption_decrypt(client_encryption, ciphertext, value, error);
    OUTPUT:
        RETVAL

mongoc_client_encryption_datakey_opts_t *
client_encryption_datakey_opts_new();
    CODE:
        RETVAL = mongoc_client_encryption_datakey_opts_new();
    OUTPUT:
        RETVAL

void
client_encryption_datakey_opts_destroy(opts)
    mongoc_client_encryption_datakey_opts_t *opts;
    CODE:
        mongoc_client_encryption_datakey_opts_destroy(opts);

void
client_encryption_datakey_opts_set_masterkey(opts, masterkey)
    mongoc_client_encryption_datakey_opts_t *opts;
    const bson_t *masterkey;
    CODE:
        mongoc_client_encryption_datakey_opts_set_masterkey(opts, masterkey);

mongoc_client_encryption_rewrap_many_datakey_result_t *
client_encryption_rewrap_many_datakey_result_new();
    CODE:
        RETVAL = mongoc_client_encryption_rewrap_many_datakey_result_new();
    OUTPUT:
        RETVAL

void
client_encryption_rewrap_many_datakey_result_destroy(result)
    mongoc_client_encryption_rewrap_many_datakey_result_t *result;
    CODE:
        mongoc_client_encryption_rewrap_many_datakey_result_destroy(result);

const bson_t *
client_encryption_rewrap_many_datakey_result_get_bulk_write_result(result)
    mongoc_client_encryption_rewrap_many_datakey_result_t *result;
    CODE:
        RETVAL = mongoc_client_encryption_rewrap_many_datakey_result_get_bulk_write_result(result);
    OUTPUT:
        RETVAL

mongoc_client_encryption_encrypt_opts_t *
client_encryption_encrypt_opts_new()
    CODE:
        RETVAL = mongoc_client_encryption_encrypt_opts_new();
    OUTPUT:
        RETVAL

void
client_encryption_encrypt_opts_destroy(opts)
    mongoc_client_encryption_encrypt_opts_t *opts;
    CODE:
        mongoc_client_encryption_encrypt_opts_destroy(opts);

void
client_encryption_encrypt_opts_set_keyid(opts, keyid)
    mongoc_client_encryption_encrypt_opts_t *opts;
    const bson_value_t *keyid;
    CODE:
        mongoc_client_encryption_encrypt_opts_set_keyid(opts, keyid);

void
client_encryption_encrypt_opts_set_keyaltname(opts, keyaltname)
    mongoc_client_encryption_encrypt_opts_t *opts;
    const char *keyaltname;
    CODE:
        mongoc_client_encryption_encrypt_opts_set_keyaltname(opts, keyaltname);

void
client_encryption_encrypt_opts_set_algorithm(opts, algorithm)
    mongoc_client_encryption_encrypt_opts_t *opts;
    const char *algorithm;
    CODE:
        mongoc_client_encryption_encrypt_opts_set_algorithm(opts, algorithm);

void
client_encryption_encrypt_opts_set_contention_factor(opts, contention_factor)
    mongoc_client_encryption_encrypt_opts_t *opts;
    int64_t contention_factor;
    CODE:
        mongoc_client_encryption_encrypt_opts_set_contention_factor(opts, contention_factor);

void
client_encryption_encrypt_opts_set_query_type(opts, query_type)
    mongoc_client_encryption_encrypt_opts_t *opts;
    const char *query_type;
    CODE:
        mongoc_client_encryption_encrypt_opts_set_query_type(opts, query_type);

void
client_encryption_encrypt_opts_set_range_opts(opts, range_opts)
    mongoc_client_encryption_encrypt_opts_t *opts;
    const mongoc_client_encryption_encrypt_range_opts_t *range_opts;
    CODE:
        mongoc_client_encryption_encrypt_opts_set_range_opts(opts, range_opts);

mongoc_client_encryption_encrypt_range_opts_t *
client_encryption_encrypt_range_opts_new()
    CODE:
        RETVAL = mongoc_client_encryption_encrypt_range_opts_new();
    OUTPUT:
        RETVAL

void
client_encryption_encrypt_range_opts_destroy(range_opts)
    mongoc_client_encryption_encrypt_range_opts_t *range_opts;
    CODE:
        mongoc_client_encryption_encrypt_range_opts_destroy(range_opts);

void
client_encryption_encrypt_range_opts_set_trim_factor(range_opts, trim_factor)
    mongoc_client_encryption_encrypt_range_opts_t *range_opts;
    int32_t trim_factor;
    CODE:
        mongoc_client_encryption_encrypt_range_opts_set_trim_factor(range_opts, trim_factor);

void
client_encryption_encrypt_range_opts_set_sparsity(range_opts, sparsity)
    mongoc_client_encryption_encrypt_range_opts_t *range_opts;
    int64_t sparsity;
    CODE:
        mongoc_client_encryption_encrypt_range_opts_set_sparsity(range_opts, sparsity);

void
client_encryption_encrypt_range_opts_set_min(range_opts, min)
    mongoc_client_encryption_encrypt_range_opts_t *range_opts;
    const bson_value_t *min;
    CODE:
        mongoc_client_encryption_encrypt_range_opts_set_min(range_opts, min);

void
client_encryption_encrypt_range_opts_set_max(range_opts, max)
    mongoc_client_encryption_encrypt_range_opts_t *range_opts;
    const bson_value_t *max;
    CODE:
        mongoc_client_encryption_encrypt_range_opts_set_max(range_opts, max);

void
client_encryption_encrypt_range_opts_set_precision(range_opts, precision)
    mongoc_client_encryption_encrypt_range_opts_t *range_opts;
    int32_t precision;
    CODE:
        mongoc_client_encryption_encrypt_range_opts_set_precision(range_opts, precision);

mongoc_client_encryption_opts_t *
client_encryption_opts_new()
    CODE:
        RETVAL = mongoc_client_encryption_opts_new();
    OUTPUT:
        RETVAL

void
client_encryption_opts_destroy(opts)
    mongoc_client_encryption_opts_t *opts;
    CODE:
        mongoc_client_encryption_opts_destroy(opts);

void
client_encryption_opts_set_keyvault_client(opts, keyvault_client)
    mongoc_client_encryption_opts_t *opts;
    mongoc_client_t *keyvault_client;
    CODE:
        mongoc_client_encryption_opts_set_keyvault_client(opts, keyvault_client);

void
client_encryption_opts_set_keyvault_namespace(opts, db, coll)
    mongoc_client_encryption_opts_t *opts;
    const char *db;
    const char *coll;
    CODE:
        mongoc_client_encryption_opts_set_keyvault_namespace(opts, db, coll);

void
client_encryption_opts_set_kms_credential_provider_callback(opts, fn, userdata)
    mongoc_client_encryption_opts_t *opts;
    mongoc_kms_credentials_provider_callback_fn fn;
    void *userdata;
    CODE:
        mongoc_client_encryption_opts_set_kms_credential_provider_callback(opts, fn, userdata);

void
client_encryption_opts_set_kms_providers(opts, kms_providers)
    mongoc_client_encryption_opts_t *opts;
    const bson_t *kms_providers;
    CODE:
        mongoc_client_encryption_opts_set_kms_providers(opts, kms_providers);

void
client_encryption_opts_set_tls_opts(opts, tls_opts)
    mongoc_client_encryption_opts_t *opts;
    const bson_t *tls_opts;
    CODE:
        mongoc_client_encryption_opts_set_tls_opts(opts, tls_opts);

void
client_pool_destroy(pool)
    mongoc_client_pool_t *pool;
    CODE:
        mongoc_client_pool_destroy(pool);

bool
client_pool_enable_auto_encryption(pool, opts, error)
    mongoc_client_pool_t *pool;
    mongoc_auto_encryption_opts_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_pool_enable_auto_encryption(pool, opts, error);
    OUTPUT:
        RETVAL

void
client_pool_max_size(pool, max_pool_size)
    mongoc_client_pool_t *pool;
    uint32_t max_pool_size;
    CODE:
        mongoc_client_pool_max_size(pool, max_pool_size);

void
client_pool_min_size(pool, min_pool_size)
    mongoc_client_pool_t *pool;
    uint32_t min_pool_size;
    CODE:
        mongoc_client_pool_min_size(pool, min_pool_size);

mongoc_client_pool_t *
client_pool_new(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_client_pool_new(uri);
    OUTPUT:
        RETVAL

mongoc_client_pool_t *
client_pool_new_with_error(uri, error)
    const mongoc_uri_t *uri;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_pool_new_with_error(uri, error);
    OUTPUT:
        RETVAL

mongoc_client_t *
client_pool_pop(mongoc_client_pool_t *pool);
    CODE:
        RETVAL = mongoc_client_pool_pop(pool);
    OUTPUT:
        RETVAL

void
client_pool_push(pool, client)
    mongoc_client_pool_t *pool;
    mongoc_client_t *client;
    CODE:
        mongoc_client_pool_push(pool, client);

bool
client_pool_set_apm_callbacks(pool, callbacks, context)
    mongoc_client_pool_t *pool;
    mongoc_apm_callbacks_t *callbacks;
    void *context;
    CODE:
        RETVAL = mongoc_client_pool_set_apm_callbacks(pool, callbacks, context);
    OUTPUT:
        RETVAL

bool
client_pool_set_appname(pool, appname)
    mongoc_client_pool_t *pool;
    const char *appname;
    CODE:
        RETVAL = mongoc_client_pool_set_appname(pool, appname);
    OUTPUT:
        RETVAL

bool
client_pool_set_error_api(client, version)
    mongoc_client_pool_t *client;
    int32_t version;
    CODE:
        RETVAL = mongoc_client_pool_set_error_api(client, version);
    OUTPUT:
        RETVAL

bool
client_pool_set_server_api(pool, api, error)
    mongoc_client_pool_t *pool;
    const mongoc_server_api_t *api;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_pool_set_server_api(pool, api, error);
    OUTPUT:
        RETVAL

void
client_pool_set_ssl_opts(pool, opts)
    mongoc_client_pool_t *pool;
    const mongoc_ssl_opt_t *opts;
    CODE:
        mongoc_client_pool_set_ssl_opts(pool, opts);

mongoc_client_t *
client_pool_try_pop(pool)
    mongoc_client_pool_t *pool;
    CODE:
        RETVAL = mongoc_client_pool_try_pop(pool);
    OUTPUT:
        RETVAL

bool
client_session_start_transaction(session, opts, error)
    mongoc_client_session_t * session;
    const mongoc_transaction_opt_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_session_start_transaction(session, opts, error);
    OUTPUT:
        RETVAL

bool
client_session_in_transaction(session)
    const mongoc_client_session_t *session;
    CODE:
        RETVAL = mongoc_client_session_in_transaction(session);
    OUTPUT:
        RETVAL

mongoc_transaction_state_t
client_session_get_transaction_state(session)
    const mongoc_client_session_t *session;
    CODE:
        RETVAL = mongoc_client_session_get_transaction_state(session);
    OUTPUT:
        RETVAL


bool
client_session_commit_transaction(session, reply, error)
    mongoc_client_session_t *session;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_session_commit_transaction(session, reply, error);
    OUTPUT:
        RETVAL

bool
client_session_abort_transaction(session, error)
    mongoc_client_session_t *session;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_session_abort_transaction(session, error);
    OUTPUT:
        RETVAL

void
client_session_advance_cluster_time(session, cluster_time)
    mongoc_client_session_t *session;
    const bson_t *cluster_time;
    CODE:
        mongoc_client_session_advance_cluster_time(session, cluster_time);

void
client_session_advance_operation_time(session, timestamp, increment)
    mongoc_client_session_t *session;
    uint32_t timestamp;
    uint32_t increment;
    CODE:
        mongoc_client_session_advance_operation_time(session,timestamp, increment);

bool
client_session_with_transaction(session, cb, opts, ctx, reply, error)
    mongoc_client_session_t *session;
    mongoc_client_session_with_transaction_cb_t cb;
    const mongoc_transaction_opt_t *opts;
    void *ctx;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_session_with_transaction(session, cb, opts, ctx, reply, error);
    OUTPUT:
        RETVAL

bool
client_session_append(client_session, opts, error)
    const mongoc_client_session_t * client_session;
    bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_session_append(client_session, opts, error);
    OUTPUT:
        RETVAL

mongoc_client_t *
client_session_get_client(session)
    const mongoc_client_session_t * session;
    CODE:
        RETVAL = mongoc_client_session_get_client(session);
    OUTPUT:
        RETVAL

const bson_t *
client_session_get_cluster_time(session)
    const mongoc_client_session_t *session;
    CODE:
        RETVAL = mongoc_client_session_get_cluster_time(session);
    OUTPUT:
        RETVAL

bool
client_session_get_dirty(session)
    const mongoc_client_session_t *session;
    CODE:
        RETVAL = mongoc_client_session_get_dirty(session);
    OUTPUT:
        RETVAL

void
client_session_get_operation_time(session, timestamp, increment)
    const mongoc_client_session_t *session;
    uint32_t *timestamp;
    uint32_t *increment;
    CODE:
        mongoc_client_session_get_operation_time(session, timestamp, increment);

const mongoc_session_opt_t *
client_session_get_opts(session)
    const mongoc_client_session_t *session;
    CODE:
        RETVAL = mongoc_client_session_get_opts(session);
    OUTPUT:
        RETVAL

const bson_t *
client_session_get_lsid(session)
    mongoc_client_session_t *session;
    CODE:
        RETVAL = mongoc_client_session_get_lsid(session);
    OUTPUT:
        RETVAL

uint32_t
client_session_get_server_id(session)
    const mongoc_client_session_t *session;
    CODE:
        RETVAL = mongoc_client_session_get_server_id(session);
    OUTPUT:
        RETVAL

void
client_session_destroy(session)
    mongoc_client_session_t *session;
    CODE:
        mongoc_client_session_destroy(session);

mongoc_bulkwrite_t *
client_bulkwrite_new(self)
    mongoc_client_t *self;
    CODE:
        RETVAL = mongoc_client_bulkwrite_new(self);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
client_command(client, db_name, flags, skip, limit, batch_size, query, fields, read_prefs)
    mongoc_client_t *client;
    const char *db_name;
    mongoc_query_flags_t flags;
    uint32_t skip;
    uint32_t limit;
    uint32_t batch_size;
    const bson_t *query;
    const bson_t *fields;
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        RETVAL = mongoc_client_command(client, db_name , flags, skip, limit, batch_size, query, fields, read_prefs);
    OUTPUT:
        RETVAL

bool
client_command_simple(client, db_name, command, read_prefs, reply, error)
    mongoc_client_t *client;
    const char *db_name;
    const bson_t *command;
    const mongoc_read_prefs_t *read_prefs;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_command_simple(client, db_name, command, read_prefs, reply, error);
    OUTPUT:
        RETVAL

bool
client_command_simple_with_server_id(client, db_name, command, read_prefs, server_id, reply, error)
    mongoc_client_t * client;
    const char *db_name;
    const bson_t *command;
    const mongoc_read_prefs_t *read_prefs;
    uint32_t server_id;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_command_simple_with_server_id(client, db_name, command, read_prefs, server_id, reply, error);
    OUTPUT:
        RETVAL

bool
client_command_with_opts(client, db_name, command, read_prefs, opts, reply, error)
    mongoc_client_t *client;
    const char *db_name;
    const bson_t *command;
    const mongoc_read_prefs_t *read_prefs;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_command_with_opts(client, db_name, command, read_prefs, opts, reply, error);
    OUTPUT:
        RETVAL

void
client_destroy(client)
    mongoc_client_t *client;
    CODE:
        mongoc_client_destroy(client);

bool
client_enable_auto_encryption(client, opts, error)
    mongoc_client_t *client;
    mongoc_auto_encryption_opts_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_enable_auto_encryption(client, opts, error);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
client_find_databases_with_opts(client, opts)
    mongoc_client_t *client;
    const bson_t *opts;
    CODE:
        RETVAL = mongoc_client_find_databases_with_opts(client, opts);
    OUTPUT:
        RETVAL

mongoc_collection_t *
client_get_collection(client, db, collection)
    mongoc_client_t *client;
    const char *db;
    const char *collection;
    CODE:
        RETVAL = mongoc_client_get_collection(client, db, collection);
    OUTPUT:
        RETVAL

const char *
client_get_crypt_shared_version(client)
    const mongoc_client_t *client;
    CODE:
        RETVAL = mongoc_client_get_crypt_shared_version(client);
    OUTPUT:
        RETVAL

mongoc_database_t *
client_get_database(client, name)
    mongoc_client_t *client;
    const char *name;
    CODE:
        RETVAL = mongoc_client_get_database(client, name);
    OUTPUT:
        RETVAL

char **
client_get_database_names(client, error)
    mongoc_client_t *client;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_get_database_names(client, error);
    OUTPUT:
        RETVAL

char **
client_get_database_names_with_opts(client, opts, error)
    mongoc_client_t  *client;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_get_database_names_with_opts(client, opts, error);
    OUTPUT:
        RETVAL

mongoc_database_t *
client_get_default_database(client)
    mongoc_client_t *client;
    CODE:
        RETVAL = mongoc_client_get_default_database(client);
    OUTPUT:
        RETVAL

mongoc_gridfs_t *
client_get_gridfs(client, db, prefix, error)
    mongoc_client_t *client;
    const char *db;
    const char *prefix;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_get_gridfs(client, db, prefix, error);
    OUTPUT:
        RETVAL

mongoc_server_description_t *
client_get_handshake_description(client, server_id, opts, error)
    mongoc_client_t *client;
    uint32_t server_id;
    bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_get_handshake_description(client, server_id, opts, error);
    OUTPUT:
        RETVAL

const mongoc_read_concern_t *
client_get_read_concern(client)
    const mongoc_client_t *client;
    CODE:
        RETVAL = mongoc_client_get_read_concern(client);
    OUTPUT:
        RETVAL

const mongoc_read_prefs_t *
client_get_read_prefs(client)
    const mongoc_client_t *client;
    CODE:
        RETVAL = mongoc_client_get_read_prefs(client);
    OUTPUT:
        RETVAL

mongoc_server_description_t *
client_get_server_description(client, server_id)
    mongoc_client_t *client;
    uint32_t server_id;
    CODE:
        RETVAL = mongoc_client_get_server_description(client, server_id);
    OUTPUT:
        RETVAL

mongoc_server_description_t **
client_get_server_descriptions(client, n)
    const mongoc_client_t *client;
    size_t *n;
    CODE:
        RETVAL = mongoc_client_get_server_descriptions(client, n);
    OUTPUT:
        RETVAL

bool
client_get_server_status(client, read_prefs, reply, error)
    mongoc_client_t *client;
    mongoc_read_prefs_t *read_prefs;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_get_server_status(client, read_prefs, reply, error);
    OUTPUT:
        RETVAL

const mongoc_uri_t *
client_get_uri(client)
    const mongoc_client_t *client;
    CODE:
        RETVAL = mongoc_client_get_uri(client);
    OUTPUT:
        RETVAL

const mongoc_write_concern_t *
client_get_write_concern(client)
    const mongoc_client_t *client;
    CODE:
        RETVAL = mongoc_client_get_write_concern(client);
    OUTPUT:
        RETVAL

mongoc_client_t *
client_new(uri_string)
    const char *uri_string;
    CODE:
        RETVAL = mongoc_client_new(uri_string);
    OUTPUT:
        RETVAL

mongoc_client_t *
client_new_from_uri(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_client_new_from_uri(uri);
    OUTPUT:
        RETVAL

mongoc_client_t *
client_new_from_uri_with_error(uri, error)
    const mongoc_uri_t *uri;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_new_from_uri_with_error(uri, error);
    OUTPUT:
        RETVAL

bool
client_read_command_with_opts(client, db_name, command, read_prefs, opts, reply, error)
    mongoc_client_t *client;
    const char *db_name;
    const bson_t *command;
    const mongoc_read_prefs_t *read_prefs;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_read_command_with_opts(client, db_name, command, read_prefs, opts, reply, error);
    OUTPUT:
        RETVAL

bool
client_read_write_command_with_opts(client, db_name, command, read_prefs, opts, reply, error)
    mongoc_client_t *client;
    const char *db_name;
    const bson_t *command;
    const mongoc_read_prefs_t *read_prefs;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_read_write_command_with_opts(client, db_name, command, read_prefs, opts, reply, error);
    OUTPUT:
        RETVAL

void
client_reset(client)
    mongoc_client_t *client;
    CODE:
        mongoc_client_reset(client);

mongoc_server_description_t *
client_select_server(client, for_writes, prefs, error)
    mongoc_client_t *client;
    bool for_writes;
    const mongoc_read_prefs_t *prefs;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_select_server(client, for_writes, prefs, error);
    OUTPUT:
        RETVAL

bool
client_set_apm_callbacks(client, callbacks, context)
    mongoc_client_t *client;
    mongoc_apm_callbacks_t *callbacks;
    void *context;
    CODE:
        RETVAL = mongoc_client_set_apm_callbacks(client, callbacks, context);
    OUTPUT:
        RETVAL

bool
client_set_appname(client, appname)
    mongoc_client_t *client;
    const char *appname;
    CODE:
        RETVAL = mongoc_client_set_appname(client, appname);
    OUTPUT:
        RETVAL

bool
client_set_error_api(client, version)
    mongoc_client_t *client;
    int32_t version;
    CODE:
        RETVAL = mongoc_client_set_error_api(client, version);
    OUTPUT:
        RETVAL

void
client_set_read_concern(client, read_concern)
    mongoc_client_t *client;
    const mongoc_read_concern_t *read_concern;
    CODE:
        mongoc_client_set_read_concern(client, read_concern);

void
client_set_read_prefs(client, read_prefs)
    mongoc_client_t *client;
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        mongoc_client_set_read_prefs(client, read_prefs);

bool
client_set_server_api(client, api, error)
    mongoc_client_t *client;
    const mongoc_server_api_t *api;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_set_server_api(client, api, error);
    OUTPUT:
        RETVAL

void
client_set_ssl_opts(client, opts)
    mongoc_client_t *client;
    const mongoc_ssl_opt_t *opts;
    CODE:
        mongoc_client_set_ssl_opts(client, opts);

void
client_set_stream_initiator(client, intiator, user_data)
    mongoc_client_t *client;
    mongoc_stream_initiator_t intiator;
    void *user_data;
    CODE:
        mongoc_client_set_stream_initiator(client, intiator, user_data);

void
client_set_write_concern(client, write_concern)
    mongoc_client_t *client;
    const mongoc_write_concern_t *write_concern;
    CODE:
        mongoc_client_set_write_concern(client, write_concern);

mongoc_client_session_t *
client_start_session(client, opts, error)
    mongoc_client_t *client;
    mongoc_session_opt_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_start_session(client, opts, error);
    OUTPUT:
        RETVAL

bool
client_write_command_with_opts(client, db_name, command, opts, reply ,error)
    mongoc_client_t *client;
    const char *db_name;
    const bson_t *command;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_client_write_command_with_opts(client, db_name, command, opts, reply, error);
    OUTPUT:
        RETVAL

bool
handshake_data_append(driver_name, driver_version, platform)
    const char *driver_name;
    const char *driver_version;
    const char *platform;
    CODE:
        RETVAL = mongoc_handshake_data_append(driver_name, driver_version, platform);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
collection_aggregate(collection, flags, pipeline, opts, read_prefs)
    mongoc_collection_t *collection;
    int flags;
    SV *pipeline;
    SV *opts;
    SV *read_prefs;
    CODE:
        mongoc_query_flags_t flag_value = (mongoc_query_flags_t) flags;
        const bson_t *bson_pipeline = (const bson_t *) SvIV(SvRV(pipeline));
        const bson_t *bson_opts = (const bson_t *) SvIV(SvRV(opts));
        const mongoc_read_prefs_t *read_prefs_value = NULL;
        if (SvOK(read_prefs)) {
            read_prefs_value = (const mongoc_read_prefs_t*) SvIV(SvRV(read_prefs));
        }
        RETVAL = mongoc_collection_aggregate(collection, flag_value, bson_pipeline, bson_opts, read_prefs_value);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
collection_command(collection, flags, skip, limit, batch_size, command, fields, read_prefs)
    mongoc_collection_t *collection;
    mongoc_query_flags_t flags;
    uint32_t skip;
    uint32_t limit;
    uint32_t batch_size;
    const bson_t *command;
    const bson_t *fields;
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        RETVAL = mongoc_collection_command(collection, flags, skip, limit, batch_size, command, fields, read_prefs);
    OUTPUT:
        RETVAL

bool
collection_command_simple(collection, command, read_prefs, reply, error)
    mongoc_collection_t *collection;
    const bson_t *command;
    const mongoc_read_prefs_t *read_prefs;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_command_simple(collection, command, read_prefs, reply, error);
    OUTPUT:
        RETVAL

bool
collection_command_with_opts(collection, command, read_prefs,opts, reply, error)
    mongoc_collection_t *collection;
    const bson_t *command;
    const mongoc_read_prefs_t *read_prefs;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_command_with_opts(collection, command, read_prefs, opts, reply, error);
    OUTPUT:
        RETVAL

mongoc_collection_t *
collection_copy(collection)
    mongoc_collection_t *collection;
    CODE:
        RETVAL = mongoc_collection_copy(collection);
    OUTPUT:
        RETVAL

int64_t
collection_count_documents(collection, filter, opts, read_prefs, reply, error)
    mongoc_collection_t *collection;
    const bson_t *filter;
    const bson_t *opts;
    const mongoc_read_prefs_t *read_prefs;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_count_documents(collection, filter, opts, read_prefs, reply, error);
    OUTPUT:
        RETVAL

int64_t
collection_estimated_document_count(collection, opts, read_prefs, reply, error)
    mongoc_collection_t *collection;
    const bson_t *opts;
    const mongoc_read_prefs_t * read_prefs;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_estimated_document_count(collection, opts, read_prefs, reply, error);
    OUTPUT:
        RETVAL

int
collection_count(collection, flags, query, skip, limit, read_prefs, error)
    mongoc_collection_t *collection;
    int flags;
    SV *query;
    SV *skip;
    SV *limit;
    SV *read_prefs;
    SV *error;
    CODE:
        mongoc_query_flags_t query_flag = (mongoc_query_flags_t) flags;
        const bson_t *bson_query = (const bson_t *) SvIV(SvRV(query));
        int64_t skip_value = SvIV(skip);
        int64_t limit_value = SvIV(limit);
        const mongoc_read_prefs_t *read_prefs_value = NULL;
        if (SvOK(read_prefs)) {
            read_prefs_value = (const mongoc_read_prefs_t*) SvIV(SvRV(read_prefs));
        }
        bson_error_t *bson_error = NULL;
        if (SvOK(error)) {
            bson_error = (bson_error_t*) SvIV(SvRV(error));
        }
        int64_t output = mongoc_collection_count(collection, query_flag, bson_query, skip_value, limit_value, read_prefs_value, bson_error);
        RETVAL = (int) output;
    OUTPUT:
        RETVAL

int64_t
collection_count_with_opts(collection, flags, query,skip, limit, opts, read_prefs, error)
    mongoc_collection_t *collection;
    mongoc_query_flags_t flags;
    const bson_t *query;
    int64_t skip;
    int64_t limit;
    const bson_t *opts;
    const mongoc_read_prefs_t *read_prefs;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_count_with_opts(collection, flags, query, skip, limit, opts, read_prefs, error);
    OUTPUT:
        RETVAL

mongoc_bulk_operation_t *
collection_create_bulk_operation(collection, ordered, write_concern)
    mongoc_collection_t *collection;
    bool ordered;
    const mongoc_write_concern_t *write_concern;
    CODE:
        RETVAL = mongoc_collection_create_bulk_operation(collection, ordered, write_concern);
    OUTPUT:
        RETVAL

mongoc_bulk_operation_t *
collection_create_bulk_operation_with_opts(collection, opts)
    mongoc_collection_t *collection;
    const bson_t *opts;
    CODE:
        RETVAL = mongoc_collection_create_bulk_operation_with_opts(collection, opts);
    OUTPUT:
        RETVAL

bool
collection_create_index(collection, keys, opt, error)
    mongoc_collection_t *collection;
    const bson_t *keys;
    const mongoc_index_opt_t *opt;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_create_index(collection, keys, opt, error);
    OUTPUT:
        RETVAL

bool
collection_create_index_with_opts(collection, keys, index_opts, command_opts, reply, error)
    mongoc_collection_t *collection;
    const bson_t *keys;
    const mongoc_index_opt_t *index_opts;
    const bson_t *command_opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_create_index_with_opts(collection, keys, index_opts, command_opts, reply, error);
    OUTPUT:
        RETVAL

mongoc_index_model_t *
index_model_new(keys, opts)
    const bson_t *keys;
    const bson_t *opts;
    CODE:
        RETVAL = mongoc_index_model_new(keys, opts);
    OUTPUT:
        RETVAL

void
index_model_destroy(model)
    mongoc_index_model_t *model;
    CODE:
        mongoc_index_model_destroy(model);

bool
collection_create_indexes_with_opts(collection, models, n_models, opts, reply, error)
    mongoc_collection_t *collection;
    mongoc_index_model_t **models;
    size_t n_models;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_create_indexes_with_opts(collection, models, n_models, opts, reply, error);
    OUTPUT:
        RETVAL

bool
collection_delete(collection, flags, selector, write_concern, error)
    mongoc_collection_t *collection;
    mongoc_delete_flags_t flags;
    const bson_t *selector;
    const mongoc_write_concern_t *write_concern;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_delete(collection, flags, selector, write_concern, error);
    OUTPUT:
        RETVAL

bool
collection_delete_many(collection, selector, opts, reply, error)
    mongoc_collection_t *collection;
    SV *selector;
    SV *opts;
    SV *reply;
    SV *error;
    CODE:
        const bson_t *bson_selector = (const bson_t*) SvIV(SvRV(selector));
        const bson_t *bson_opts = (opts && SvOK(opts)) ? (const bson_t*) SvIV(SvRV(opts)) : NULL;
        bson_t * bson_reply = (reply && SvOK(reply)) ? (bson_t *) SvIV(SvRV(reply)) : NULL;
        bson_error_t * bson_error = (error && SvOK(error)) ? (bson_error_t*) SvIV(SvRV(error)) : NULL;
        RETVAL = mongoc_collection_delete_many(collection, bson_selector, bson_opts, bson_reply, bson_error);
    OUTPUT:
        RETVAL

bool
collection_delete_one(collection, selector, opts, reply, error)
    mongoc_collection_t *collection;
    SV *selector;
    SV *opts;
    SV *reply;
    SV *error;
    CODE:
        const bson_t *bson_selector = (const bson_t*) SvIV(SvRV(selector));
        const bson_t *bson_opts = (opts && SvOK(opts)) ? (const bson_t*) SvIV(SvRV(opts)) : NULL;
        bson_t * bson_reply = (reply && SvOK(reply)) ? (bson_t *) SvIV(SvRV(reply)) : NULL;
        bson_error_t * bson_error = (error && SvOK(error)) ? (bson_error_t*) SvIV(SvRV(error)) : NULL;
        RETVAL = mongoc_collection_delete_one(collection, bson_selector, bson_opts, bson_reply, bson_error);
    OUTPUT:
        RETVAL

void
collection_destroy(collection)
    mongoc_collection_t *collection;
    CODE:
    mongoc_collection_destroy(collection);

bool
collection_drop(collection, error)
    mongoc_collection_t *collection;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_drop(collection, error);
    OUTPUT:
        RETVAL

bool
collection_drop_index(collection, index_name, error)
    mongoc_collection_t *collection;
    const char *index_name;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_drop_index(collection, index_name, error);
    OUTPUT:
        RETVAL

bool
colletion_drop_index_with_opts(collection, index_name, opts, error)
    mongoc_collection_t *collection;
    const char *index_name;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_drop_index_with_opts(collection, index_name, opts, error);
    OUTPUT:
        RETVAL

bool
collection_drop_with_opts(collection, opts, error)
    mongoc_collection_t *collection;
    bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_drop_with_opts(collection, opts, error);
    OUTPUT:
        RETVAL

bool
collection_ensure_index(collection, keys, opt, error)
    mongoc_collection_t *collection;
    const bson_t *keys;
    const mongoc_index_opt_t  *opt;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_ensure_index(collection, keys, opt, error);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
collection_find(collection, flags, skip, limit, batch_size, query, fields, read_prefs)
    mongoc_collection_t *collection;
    int flags;
    SV *skip;
    SV *limit;
    SV *batch_size;
    SV *query;
    SV *fields;
    SV *read_prefs;
    CODE:
        mongoc_query_flags_t flag_value = (mongoc_query_flags_t)flags;
        uint32_t skip_value = SvUV(skip);
        uint32_t limit_value = SvUV(limit);
        uint32_t batch_size_value = SvUV(batch_size);
        const bson_t *bson_query = NULL;
        if (SvOK(query)) {
            bson_query = (const bson_t *) SvIV(SvRV(query));  // Convert to BSON pointer
        } else {
            warn("Query is invalid or undef");
        }
        const bson_t *bson_fields = NULL;
        if (SvOK(fields)) {
            bson_fields = (const bson_t *) SvIV(SvRV(fields));  // Convert to BSON pointer
        } else {
            warn("Fields are invalid or undef");
        }
        const mongoc_read_prefs_t *read_prefs_value = NULL;
        if (SvOK(read_prefs)) {
            read_prefs_value = (const mongoc_read_prefs_t *) SvIV(SvRV(read_prefs)); // Dereference read_prefs
        }
        RETVAL = mongoc_collection_find(collection, flag_value, skip_value, limit_value, batch_size_value, bson_query, bson_fields, read_prefs_value);
    OUTPUT:
        RETVAL

bool
collection_find_and_modify(collection, query, sort, update, fields, _remove, upsert, _new, reply, error)
    mongoc_collection_t *collection;
    const bson_t *query;
    const bson_t *sort;
    const bson_t *update;
    const bson_t *fields;
    bool _remove;
    bool upsert;
    bool _new;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_find_and_modify(collection, query, sort, update, fields, _remove, upsert, _new, reply, error);
    OUTPUT:
        RETVAL

bool
collection_find_and_modify_with_opts(collection, query, opts, reply, error)
    mongoc_collection_t *collection;
    const bson_t *query;
    const mongoc_find_and_modify_opts_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_find_and_modify_with_opts(collection, query, opts, reply, error);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
collection_find_indexes(collection, error)
    mongoc_collection_t *collection;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_find_indexes(collection, error);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
collection_find_indexes_with_opts(collection, opts)
    mongoc_collection_t *collection;
    const bson_t *opts;
    CODE:
        RETVAL = mongoc_collection_find_indexes_with_opts(collection, opts);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
collection_find_with_opts(collection, filter, opts, read_prefs)
    mongoc_collection_t *collection;
    const bson_t *filter;
    const bson_t *opts;
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        RETVAL = mongoc_collection_find_with_opts(collection, filter, opts, read_prefs);
    OUTPUT:
        RETVAL

const bson_t *
collection_get_last_error(collection)
    const mongoc_collection_t *collection;
    CODE:
        RETVAL = mongoc_collection_get_last_error(collection);
    OUTPUT:
        RETVAL

const char *
collection_get_name(collection)
    mongoc_collection_t *collection;
    CODE:
        RETVAL = mongoc_collection_get_name(collection);
    OUTPUT:
        RETVAL

const mongoc_read_concern_t *
collection_get_read_concern(collection)
    const mongoc_collection_t *collection;
    CODE:
        RETVAL = mongoc_collection_get_read_concern(collection);
    OUTPUT:
        RETVAL

const mongoc_read_prefs_t *
collection_get_read_prefs(collection)
    const mongoc_collection_t *collection;
    CODE:
        RETVAL = mongoc_collection_get_read_prefs(collection);
    OUTPUT:
        RETVAL

const mongoc_write_concern_t *
collection_get_write_concern(collection)
    const mongoc_collection_t *collection;
    CODE:
        RETVAL = mongoc_collection_get_write_concern(collection);
    OUTPUT:
        RETVAL

bool
collection_insert(collection, flags, document, write_concern, error)
    mongoc_collection_t *collection;
    mongoc_insert_flags_t flags;
    const bson_t *document;
    const mongoc_write_concern_t *write_concern;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_insert(collection, flags, document, write_concern, error);
    OUTPUT:
        RETVAL

bool
collection_insert_bulk(collection, flags, documents, n_documents, write_concern, error)
    mongoc_collection_t *collection;
    mongoc_insert_flags_t flags;
    const bson_t **documents;
    uint32_t n_documents;
    const mongoc_write_concern_t *write_concern;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_insert_bulk(collection, flags, documents, n_documents, write_concern, error);
    OUTPUT:
        RETVAL

bool
collection_insert_many(collection, documents, n_documents, opts, reply, error)
    mongoc_collection_t *collection;
    const bson_t **documents;
    size_t n_documents;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_insert_many(collection, documents, n_documents, opts, reply, error);
    OUTPUT:
        RETVAL

bool
collection_insert_one(collection, document, opts ,reply, error)
    mongoc_collection_t *collection;
    SV *document;
    SV *opts;
    SV *reply;
    SV *error;
    CODE:
        const bson_t *bson_document = (const bson_t *) SvIV(SvRV(document));
        const bson_t *bson_opts = (opts && SvOK(opts)) ? (const bson_t*) SvIV(SvRV(opts)) : NULL;
        bson_t *bson_reply = (reply && SvOK(reply)) ? (bson_t*) SvIV(SvRV(reply)) : NULL;
        bson_error_t *bson_error = (error && SvOK(error)) ? (bson_error_t*) SvIV(SvRV(error)) : NULL;
        RETVAL = mongoc_collection_insert_one(collection, bson_document, bson_opts, bson_reply, bson_error);
    OUTPUT:
        RETVAL

char *
collection_keys_to_index_string(keys)
    const bson_t *keys;
    CODE:
        RETVAL = mongoc_collection_keys_to_index_string(keys);
    OUTPUT:
        RETVAL

bool
collection_read_command_with_opts(collection, command, read_prefs, opts, reply, error)
    mongoc_collection_t *collection;
    const bson_t *command;
    const mongoc_read_prefs_t *read_prefs;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_read_command_with_opts(collection, command, read_prefs, opts, reply, error);
    OUTPUT:
        RETVAL

bool
collection_remove(collection, flags, selector, write_concern, error)
    mongoc_collection_t *collection;
    mongoc_remove_flags_t flags;
    const bson_t *selector;
    const mongoc_write_concern_t *write_concern;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_remove(collection, flags, selector, write_concern, error);
    OUTPUT:
        RETVAL

bool
collection_rename(collection, new_db, new_name, drop_target_before_rename, error)
    mongoc_collection_t *collection;
    const char *new_db;
    const char *new_name;
    bool drop_target_before_rename;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_rename(collection, new_db, new_name, drop_target_before_rename, error);
    OUTPUT:
        RETVAL

bool
collection_rename_with_opts(collection, new_db, new_name, drop_target_before_rename, opts, error)
    mongoc_collection_t *collection;
    const char *new_db;
    const char *new_name;
    bool drop_target_before_rename;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_rename_with_opts(collection, new_db, new_name, drop_target_before_rename, opts, error);
    OUTPUT:
        RETVAL

bool
collection_replace_one(collection, selector, replacement, opts, reply, error)
    mongoc_collection_t *collection;
    const bson_t *selector;
    const bson_t *replacement;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_replace_one(collection, selector, replacement, opts, reply, error);
    OUTPUT:
        RETVAL

bool
collection_save(collection, document, write_concern, error)
    mongoc_collection_t *collection;
    const bson_t *document;
    const mongoc_write_concern_t *write_concern;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_save(collection, document, write_concern, error);
    OUTPUT:
        RETVAL

void
collection_set_read_concern(collection, read_concern)
    mongoc_collection_t *collection;
    const mongoc_read_concern_t *read_concern;
    CODE:
        mongoc_collection_set_read_concern(collection, read_concern);

void
collection_set_read_prefs(collection, read_prefs)
    mongoc_collection_t *collection;
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        mongoc_collection_set_read_prefs(collection, read_prefs);

void
collection_set_write_concern(collection, write_concern)
    mongoc_collection_t *collection;
    const mongoc_write_concern_t *write_concern;
    CODE:
        mongoc_collection_set_write_concern(collection, write_concern);

bool
collection_stats(collection, options, reply, error)
    mongoc_collection_t *collection;
    const bson_t *options;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_stats(collection, options, reply, error);
    OUTPUT:
        RETVAL

bool
collection_update(collection, flags, selector, update, write_concern, error)
    mongoc_collection_t *collection;
    mongoc_update_flags_t flags;
    const bson_t *selector;
    const bson_t *update;
    const mongoc_write_concern_t *write_concern;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_update(collection, flags, selector, update, write_concern, error);
    OUTPUT:
        RETVAL

bool
collection_update_one(collection, selector, update, opts, reply, error)
    mongoc_collection_t *collection;
    SV *selector;
    SV *update;
    SV *opts;
    SV *reply;
    SV *error;
    CODE:
        const bson_t *bson_selector = (const bson_t*) SvIV(SvRV(selector));
        const bson_t *bson_update = (const bson_t*) SvIV(SvRV(update));
        const bson_t *bson_opts = (opts && SvOK(opts)) ? (const bson_t*) SvIV(SvRV(opts)) : NULL;
        bson_t *bson_reply = (reply && SvOK(reply)) ? (bson_t*) SvIV(SvRV(reply)) : NULL;
        bson_error_t *bson_error = (error && SvOK(error)) ? (bson_error_t*) SvIV(SvRV(error)) : NULL;
        RETVAL = mongoc_collection_update_one(collection, bson_selector, bson_update, bson_opts, bson_reply, bson_error);
    OUTPUT:
        RETVAL

bool
collection_update_many(collection, selector, update, opts, reply, error)
    mongoc_collection_t *collection;
    const bson_t *selector;
    const bson_t *update;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_update_many(collection, selector, update, opts, reply, error);
    OUTPUT:
        RETVAL

bool
collection_validate(collection, options, reply, error)
    mongoc_collection_t *collection;
    const bson_t *options;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_validate(collection, options, reply, error);
    OUTPUT:
        RETVAL

bool
collection_write_command_with_opts(collection, command, opts, reply, error)
    mongoc_collection_t *collection;
    const bson_t *command;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_collection_write_command_with_opts(collection, command, opts, reply, error);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
cursor_clone(cursor)
    const mongoc_cursor_t * cursor;
    CODE:
        RETVAL = mongoc_cursor_clone(cursor);
    OUTPUT:
        RETVAL

const bson_t *
cursor_current(cursor)
    const mongoc_cursor_t *cursor;
    CODE:
        RETVAL = mongoc_cursor_current(cursor);
    OUTPUT:
        RETVAL

void
cursor_destroy(cursor)
    mongoc_cursor_t *cursor;
    CODE:
        mongoc_cursor_destroy(cursor);

bool
cursor_error(cursor, error)
    mongoc_cursor_t *cursor;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_cursor_error(cursor, error);
    OUTPUT:
        RETVAL

bool
cursor_error_document(cursor, error, reply)
    mongoc_cursor_t *cursor;
    bson_error_t *error;
    const bson_t **reply;
    CODE:
        RETVAL = mongoc_cursor_error_document(cursor, error, reply);
    OUTPUT:
        RETVAL

uint32_t
cursor_get_batch_size(cursor)
    const mongoc_cursor_t *cursor;
    CODE:
        RETVAL = mongoc_cursor_get_batch_size(cursor);
    OUTPUT:
        RETVAL

uint32_t
cursor_get_hint(cursor)
    const mongoc_cursor_t *cursor;
    CODE:
        RETVAL = mongoc_cursor_get_hint(cursor);
    OUTPUT:
        RETVAL

uint32_t
cursor_get_server_id(cursor)
    const mongoc_cursor_t *cursor;
    CODE:
        RETVAL = mongoc_cursor_get_server_id(cursor);
    OUTPUT:
        RETVAL

void
cursor_get_host(cursor, host)
    mongoc_cursor_t *cursor;
    mongoc_host_list_t *host;
    CODE:
        mongoc_cursor_get_host(cursor, host);

int64_t
cursor_get_id(cursor)
    const mongoc_cursor_t *cursor;
    CODE:
        RETVAL = mongoc_cursor_get_id(cursor);
    OUTPUT:
        RETVAL

int64_t
cursor_get_limit(cursor)
    mongoc_cursor_t *cursor;
    CODE:
        RETVAL = mongoc_cursor_get_limit(cursor);
    OUTPUT:
        RETVAL

uint32_t
cursor_get_max_await_time_ms(cursor)
    mongoc_cursor_t *cursor;
    CODE:
        RETVAL = mongoc_cursor_get_max_await_time_ms(cursor);
    OUTPUT:
        RETVAL

bool
cursor_is_alive(cursor)
    const mongoc_cursor_t *cursor;
    CODE:
        RETVAL = mongoc_cursor_is_alive(cursor);
    OUTPUT:
        RETVAL

bool
cursor_more(cursor)
    mongoc_cursor_t *cursor;
    CODE:
        RETVAL = mongoc_cursor_more(cursor);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
cursor_new_from_command_reply(client, reply, server_id)
    mongoc_client_t *client;
    bson_t *reply;
    uint32_t server_id;
    CODE:
        RETVAL = mongoc_cursor_new_from_command_reply(client, reply, server_id);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
cursor_new_from_command_reply_with_opts(client, reply, opts)
    mongoc_client_t *client;
    bson_t *reply;
    const bson_t *opts;
    CODE:
        RETVAL = mongoc_cursor_new_from_command_reply_with_opts(client, reply, opts);
    OUTPUT:
        RETVAL

bool
cursor_next(cursor, bson_ref)
    mongoc_cursor_t *cursor
    AV *bson_ref
    CODE:
        if (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVAV) {
            croak("bson_ref is not an ARRAY reference");
        }
        const bson_t *bson = NULL;
        RETVAL = mongoc_cursor_next(cursor, &bson);
        if (RETVAL) {
            if (bson) {
                char *json_str = bson_as_json(bson, NULL);
                if (json_str) {
                    SV *json_sv = newSVpv(json_str, 0);
                    bson_free(json_str);
                    av_clear(bson_ref);
                    av_push(bson_ref, json_sv);
                }
            }
        }
    OUTPUT:
        RETVAL

void
cursor_set_batch_size(cursor, batch_size)
    mongoc_cursor_t *cursor;
    uint32_t batch_size;
    CODE:
        mongoc_cursor_set_batch_size(cursor, batch_size);

bool
cursor_set_hint(cursor, server_id)
    mongoc_cursor_t *cursor;
    uint32_t server_id;
    CODE:
        RETVAL = mongoc_cursor_set_hint(cursor, server_id);
    OUTPUT:
        RETVAL

bool
cursor_set_server_id(cursor, server_id)
    mongoc_cursor_t *cursor;
    uint32_t server_id;
    CODE:
        RETVAL = mongoc_cursor_set_server_id(cursor, server_id);
    OUTPUT:
        RETVAL

bool
cursor_set_limit(cursor, limit)
    mongoc_cursor_t *cursor;
    int64_t limit;
    CODE:
        RETVAL = mongoc_cursor_set_limit(cursor, limit);
    OUTPUT:
        RETVAL

void
cursor_set_max_await_time_ms(cursor, max_await_time_ms)
    mongoc_cursor_t *cursor;
    uint32_t max_await_time_ms;
    CODE:
        mongoc_cursor_set_max_await_time_ms(cursor, max_await_time_ms);

bool
database_add_user(database, username, password, roles, custom_data, error)
    mongoc_database_t *database;
    const char *username;
    const char *password;
    const bson_t *roles;
    const bson_t *custom_data;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_add_user(database, username, password, roles, custom_data, error);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
database_aggregate(database, pipeline, opts, read_prefs)
    mongoc_database_t *database;
    const bson_t *pipeline;
    const bson_t *opts;
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        RETVAL = mongoc_database_aggregate(database, pipeline, opts, read_prefs);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
database_command(database, flags, skip, limit, batch_size, command, fields, read_prefs)
    mongoc_database_t *database;
    mongoc_query_flags_t flags;
    uint32_t skip;
    uint32_t limit;
    uint32_t batch_size;
    const bson_t *command;
    const bson_t *fields;
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        RETVAL = mongoc_database_command(database, flags, skip, limit, batch_size, command, fields, read_prefs);
    OUTPUT:
        RETVAL

bool
database_command_simple(database, command, read_prefs, reply, error)
    mongoc_database_t *database;
    const bson_t *command;
    const mongoc_read_prefs_t *read_prefs;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_command_simple(database, command, read_prefs, reply, error);
    OUTPUT:
        RETVAL

bool
database_command_with_opts(database, command, read_prefs, opts, reply, error)
    mongoc_database_t *database;
    const bson_t *command;
    const mongoc_read_prefs_t *read_prefs;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_command_with_opts(database, command, read_prefs, opts, reply, error);
    OUTPUT:
        RETVAL

mongoc_database_t *
database_copy(database)
    mongoc_database_t *database;
    CODE:
        RETVAL = mongoc_database_copy(database);
    OUTPUT:
        RETVAL

mongoc_collection_t *
database_create_collection(database, name, opts, error)
    mongoc_database_t *database;
    const char *name;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_create_collection(database, name, opts, error);
    OUTPUT:
        RETVAL

void
database_destroy(database)
    mongoc_database_t *database;
    CODE:
        mongoc_database_destroy(database);

bool
database_drop(database, error)
    mongoc_database_t *database;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_drop(database, error);
    OUTPUT:
        RETVAL

bool
database_drop_with_opts(database, opts, error)
    mongoc_database_t *database;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_drop_with_opts(database, opts, error);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
database_find_collections(database, filter, error)
    mongoc_database_t *database;
    const bson_t *filter;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_find_collections(database, filter, error);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
database_find_collections_with_opts(database, opts)
    mongoc_database_t *database;
    const bson_t *opts;
    CODE:
        RETVAL = mongoc_database_find_collections_with_opts(database, opts);
    OUTPUT:
        RETVAL

mongoc_collection_t *
database_get_collection(database, name)
    mongoc_database_t *database;
    const char *name;
    CODE:
        RETVAL = mongoc_database_get_collection(database, name);
    OUTPUT:
        RETVAL

char **
database_get_collection_names(database, error)
    mongoc_database_t *database;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_get_collection_names(database, error);
    OUTPUT:
        RETVAL

char **
database_get_collection_names_with_opts(database, opts, error)
    mongoc_database_t *database;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_get_collection_names_with_opts(database, opts, error);
    OUTPUT:
        RETVAL

const char *
database_get_name(database)
    mongoc_database_t *database;
    CODE:
        RETVAL = mongoc_database_get_name(database);
    OUTPUT:
        RETVAL

const mongoc_read_concern_t *
database_get_read_concern(database)
    const mongoc_database_t *database;
    CODE:
        RETVAL = mongoc_database_get_read_concern(database);
    OUTPUT:
        RETVAL

const mongoc_read_prefs_t *
database_get_read_prefs(database)
    const mongoc_database_t *database;
    CODE:
        RETVAL = mongoc_database_get_read_prefs(database);
    OUTPUT:
        RETVAL

const mongoc_write_concern_t *
database_get_write_concern(database)
    const mongoc_database_t *database;
    CODE:
        RETVAL = mongoc_database_get_write_concern(database);
    OUTPUT:
        RETVAL

bool
database_has_collection(database, name, error)
    mongoc_database_t *database;
    const char *name;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_has_collection(database, name, error);
    OUTPUT:
        RETVAL

bool
database_read_command_with_opts(database, command, read_prefs, opts, reply, error)
    mongoc_database_t *database;
    const bson_t *command;
    const mongoc_read_prefs_t *read_prefs;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_read_command_with_opts(database, command, read_prefs, opts, reply, error);
    OUTPUT:
        RETVAL

bool
database_read_write_command_with_opts(database, command, read_prefs, opts, reply, error)
    mongoc_database_t *database;
    const bson_t *command;
    const mongoc_read_prefs_t *read_prefs;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_read_write_command_with_opts(database, command, read_prefs, opts, reply, error);
    OUTPUT:
        RETVAL

bool
database_remove_all_users(database, error)
    mongoc_database_t *database;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_remove_all_users(database, error);
    OUTPUT:
        RETVAL

bool
database_remove_user(database, username, error)
    mongoc_database_t *database;
    const char *username;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_remove_user(database, username, error);
    OUTPUT:
        RETVAL

void
database_set_read_concern(database, read_concern)
    mongoc_database_t *database;
    const mongoc_read_concern_t *read_concern;
    CODE:
        mongoc_database_set_read_concern(database, read_concern);

void
database_set_read_prefs(database, read_prefs)
    mongoc_database_t *database;
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        mongoc_database_set_read_prefs(database, read_prefs);

void
database_set_write_concern(database, write_concern)
    mongoc_database_t *database;
    const mongoc_write_concern_t *write_concern;
    CODE:
        mongoc_database_set_write_concern(database, write_concern);

bool
database_write_command_with_opts(database, command, opts, reply, error)
    mongoc_database_t *database;
    const bson_t *command;
    const bson_t *opts;
    bson_t *reply;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_database_write_command_with_opts(database, command, opts, reply, error);
    OUTPUT:
        RETVAL

bool
find_and_modify_opts_append(opts, extra)
    mongoc_find_and_modify_opts_t *opts;
    const bson_t *extra;
    CODE:
        RETVAL = mongoc_find_and_modify_opts_append(opts, extra);
    OUTPUT:
        RETVAL

void
find_and_modify_opts_destroy(find_and_modify_opts)
    mongoc_find_and_modify_opts_t *find_and_modify_opts;
    CODE:
        mongoc_find_and_modify_opts_destroy(find_and_modify_opts);

bool
find_and_modify_opts_get_bypass_document_validation(opts)
    const mongoc_find_and_modify_opts_t *opts;
    CODE:
        RETVAL = mongoc_find_and_modify_opts_get_bypass_document_validation(opts);
    OUTPUT:
        RETVAL

void
find_and_modify_opts_get_fields(opts, fields)
    const mongoc_find_and_modify_opts_t *opts;
    bson_t *fields;
    CODE:
        mongoc_find_and_modify_opts_get_fields(opts, fields);

mongoc_find_and_modify_flags_t
find_and_modify_opts_get_flags(opts)
    const mongoc_find_and_modify_opts_t *opts;
    CODE:
        RETVAL = mongoc_find_and_modify_opts_get_flags(opts);
    OUTPUT:
        RETVAL

uint32_t
find_and_modify_opts_get_max_time_ms(opts)
    const mongoc_find_and_modify_opts_t *opts;
    CODE:
        RETVAL = mongoc_find_and_modify_opts_get_max_time_ms(opts);
    OUTPUT:
        RETVAL

void
find_and_modify_opts_get_sort(opts, sort)
    const mongoc_find_and_modify_opts_t *opts;
    bson_t *sort;
    CODE:
        mongoc_find_and_modify_opts_get_sort(opts, sort);

void
find_and_modify_opts_get_update(opts, update)
    const mongoc_find_and_modify_opts_t *opts;
    bson_t *update;
    CODE:
        mongoc_find_and_modify_opts_get_update(opts, update);

mongoc_find_and_modify_opts_t *
find_and_modify_opts_new()
    CODE:
        RETVAL = mongoc_find_and_modify_opts_new();
    OUTPUT:
        RETVAL

bool
find_and_modify_opts_set_bypass_document_validation(opts, bypass)
    mongoc_find_and_modify_opts_t *opts;
    bool bypass;
    CODE:
        RETVAL = mongoc_find_and_modify_opts_set_bypass_document_validation(opts, bypass);
    OUTPUT:
        RETVAL

bool
find_and_modify_opts_set_fields(opts, fields)
    mongoc_find_and_modify_opts_t *opts;
    const bson_t *fields;
    CODE:
        RETVAL = mongoc_find_and_modify_opts_set_fields(opts, fields);
    OUTPUT:
        RETVAL

bool
find_and_modify_opts_set_flags(opts, flags)
    mongoc_find_and_modify_opts_t *opts;
    mongoc_find_and_modify_flags_t flags;
    CODE:
        RETVAL = mongoc_find_and_modify_opts_set_flags(opts, flags);
    OUTPUT:
        RETVAL

bool
find_and_modify_opts_set_max_time_ms(opts, max_time_ms)
    mongoc_find_and_modify_opts_t *opts;
    uint32_t max_time_ms;
    CODE:
        RETVAL = mongoc_find_and_modify_opts_set_max_time_ms(opts, max_time_ms);
    OUTPUT:
        RETVAL

bool
find_and_modify_opts_set_sort(opts, sort)
    mongoc_find_and_modify_opts_t *opts;
    const bson_t *sort;
    CODE:
        RETVAL = mongoc_find_and_modify_opts_set_sort(opts, sort);
    OUTPUT:
        RETVAL

bool
find_and_modify_opts_set_update(opts, update)
    mongoc_find_and_modify_opts_t *opts;
    const bson_t *update;
    CODE:
        RETVAL = mongoc_find_and_modify_opts_set_update(opts, update);
    OUTPUT:
        RETVAL

void
gridfs_file_list_destroy(list)
    mongoc_gridfs_file_list_t *list;
    CODE:
        mongoc_gridfs_file_list_destroy(list);

bool
gridfs_file_list_error(list, error)
    mongoc_gridfs_file_list_t *list;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_file_list_error(list, error);
    OUTPUT:
        RETVAL

mongoc_gridfs_file_t *
gridfs_file_list_next(list)
    mongoc_gridfs_file_list_t *list;
    CODE:
        RETVAL = mongoc_gridfs_file_list_next(list);
    OUTPUT:
        RETVAL

void
gridfs_file_destroy(file)
    mongoc_gridfs_file_t *file;
    CODE:
        mongoc_gridfs_file_destroy(file);

bool
gridfs_file_error(file, error)
    mongoc_gridfs_file_t *file;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_file_error(file, error);
    OUTPUT:
        RETVAL

const bson_t *
gridfs_file_get_aliases(file)
    mongoc_gridfs_file_t *file;
    CODE:
        RETVAL = mongoc_gridfs_file_get_aliases(file);
    OUTPUT:
        RETVAL

int32_t
gridfs_file_get_chunk_size(file)
    mongoc_gridfs_file_t *file;
    CODE:
        RETVAL = mongoc_gridfs_file_get_chunk_size(file);
    OUTPUT:
        RETVAL

const char *
gridfs_file_get_content_type(file)
    mongoc_gridfs_file_t *file;
    CODE:
        RETVAL = mongoc_gridfs_file_get_content_type(file);
    OUTPUT:
        RETVAL

const char *
gridfs_file_get_filename(file)
    mongoc_gridfs_file_t *file;
    CODE:
        RETVAL = mongoc_gridfs_file_get_filename(file);
    OUTPUT:
        RETVAL

const bson_value_t *
gridfs_file_get_id(file)
    mongoc_gridfs_file_t *file;
    CODE:
        RETVAL = mongoc_gridfs_file_get_id(file);
    OUTPUT:
        RETVAL

int64_t
gridfs_file_get_length(file)
    mongoc_gridfs_file_t *file;
    CODE:
        RETVAL = mongoc_gridfs_file_get_length(file);
    OUTPUT:
        RETVAL

const char *
gridfs_file_get_md5(file)
    mongoc_gridfs_file_t *file;
    CODE:
        RETVAL = mongoc_gridfs_file_get_md5(file);
    OUTPUT:
        RETVAL

const bson_t *
gridfs_file_get_metadata(file)
    mongoc_gridfs_file_t *file;
    CODE:
        RETVAL = mongoc_gridfs_file_get_metadata(file);
    OUTPUT:
        RETVAL

int64_t
gridfs_file_get_upload_date(file)
    mongoc_gridfs_file_t *file;
    CODE:
        RETVAL = mongoc_gridfs_file_get_upload_date(file);
    OUTPUT:
        RETVAL

ssize_t
gridfs_file_readv(file, iov, iovcnt, min_bytes, timeout_msec)
    mongoc_gridfs_file_t *file;
    mongoc_iovec_t *iov;
    size_t iovcnt;
    size_t min_bytes;
    uint32_t timeout_msec;
    CODE:
        RETVAL = mongoc_gridfs_file_readv(file, iov, iovcnt, min_bytes, timeout_msec);
    OUTPUT:
        RETVAL

bool
gridfs_file_remove(file, error)
    mongoc_gridfs_file_t *file;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_file_remove(file, error);
    OUTPUT:
        RETVAL

bool
gridfs_file_save(file)
    mongoc_gridfs_file_t *file;
    CODE:
        RETVAL = mongoc_gridfs_file_save(file);
    OUTPUT:
        RETVAL

int
gridfs_file_seek(file, delta, whence)
    mongoc_gridfs_file_t *file;
    int64_t delta;
    int whence;
    CODE:
        RETVAL = mongoc_gridfs_file_seek(file, delta, whence);
    OUTPUT:
        RETVAL

void
gridfs_file_set_aliases(file, bson)
    mongoc_gridfs_file_t *file;
    const bson_t *bson;
    CODE:
        mongoc_gridfs_file_set_aliases(file, bson);

void
gridfs_file_set_content_type(file, content_type)
    mongoc_gridfs_file_t *file;
    const char *content_type;
    CODE:
        mongoc_gridfs_file_set_content_type(file, content_type);

void
gridfs_file_set_filename(file, filename)
    mongoc_gridfs_file_t *file;
    const char *filename;
    CODE:
        mongoc_gridfs_file_set_filename(file, filename);

bool
gridfs_file_set_id(file, id, error)
    mongoc_gridfs_file_t *file;
    const bson_value_t *id;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_file_set_id(file, id, error);
    OUTPUT:
        RETVAL

void
gridfs_file_set_md5(file, md5)
    mongoc_gridfs_file_t *file;
    const char *md5;
    CODE:
        mongoc_gridfs_file_set_md5(file, md5);

void
gridfs_file_set_metadata(file, metadata)
    mongoc_gridfs_file_t *file;
    const bson_t *metadata;
    CODE:
        mongoc_gridfs_file_set_metadata(file, metadata);

uint64_t
gridfs_file_tell(file)
    mongoc_gridfs_file_t *file;
    CODE:
        RETVAL = mongoc_gridfs_file_tell(file);
    OUTPUT:
        RETVAL

ssize_t
gridfs_file_writev(file, iov, iovcnt, timeout_msec)
    mongoc_gridfs_file_t *file;
    const mongoc_iovec_t *iov;
    size_t iovcnt;
    uint32_t timeout_msec;
    CODE:
        RETVAL = mongoc_gridfs_file_writev(file, iov, iovcnt, timeout_msec);
    OUTPUT:
        RETVAL

mongoc_stream_t *
stream_gridfs_new(file)
    mongoc_gridfs_file_t *file;
    CODE:
        RETVAL = mongoc_stream_gridfs_new(file);
    OUTPUT:
        RETVAL

bool
gridfs_bucket_abort_upload(stream)
    mongoc_stream_t *stream;
    CODE:
        RETVAL = mongoc_gridfs_bucket_abort_upload(stream);
    OUTPUT:
        RETVAL

bool
gridfs_bucket_delete_by_id(bucket, file_id, error)
    mongoc_gridfs_bucket_t *bucket;
    const bson_value_t *file_id;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_bucket_delete_by_id(bucket, file_id, error);
    OUTPUT:
        RETVAL

void
gridfs_bucket_destroy(bucket)
    mongoc_gridfs_bucket_t *bucket;
    CODE:
        mongoc_gridfs_bucket_destroy(bucket);

bool
gridfs_bucket_download_to_stream(bucket, file_id, destination, error)
    mongoc_gridfs_bucket_t *bucket;
    const bson_value_t *file_id;
    mongoc_stream_t *destination;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_bucket_download_to_stream(bucket, file_id, destination, error);
    OUTPUT:
        RETVAL

mongoc_cursor_t *
gridfs_bucket_find(bucket, filter, opts)
    mongoc_gridfs_bucket_t *bucket;
    const bson_t *filter;
    const bson_t *opts;
    CODE:
        RETVAL = mongoc_gridfs_bucket_find(bucket, filter, opts);
    OUTPUT:
        RETVAL

mongoc_gridfs_bucket_t *
gridfs_bucket_new(db, opts, read_prefs, error)
    mongoc_database_t *db;
    const bson_t *opts;
    const mongoc_read_prefs_t *read_prefs;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_bucket_new(db, opts, read_prefs, error);
    OUTPUT:
        RETVAL

mongoc_stream_t *
gridfs_bucket_open_download_stream(bucket, file_id, error)
    mongoc_gridfs_bucket_t *bucket;
    const bson_value_t *file_id;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_bucket_open_download_stream(bucket, file_id, error);
    OUTPUT:
        RETVAL

mongoc_stream_t *
gridfs_bucket_open_upload_stream(bucket, filename, opts, file_id, error)
    mongoc_gridfs_bucket_t *bucket;
    const char *filename;
    const bson_t *opts;
    bson_value_t *file_id;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_bucket_open_upload_stream(bucket, filename, opts, file_id, error);
    OUTPUT:
        RETVAL

mongoc_stream_t *
gridfs_bucket_open_upload_stream_with_id(bucket, file_id, filename, opts, error)
    mongoc_gridfs_bucket_t *bucket;
    const bson_value_t *file_id;
    const char *filename;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_bucket_open_upload_stream_with_id(bucket, file_id, filename, opts, error);
    OUTPUT:
        RETVAL

bool
gridfs_bucket_stream_error(stream, error)
    mongoc_stream_t *stream;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_bucket_stream_error(stream, error);
    OUTPUT:
        RETVAL

bool
gridfs_bucket_upload_from_stream(bucket, filename, source, opts, file_id, error)
    mongoc_gridfs_bucket_t *bucket;
    const char *filename;
    mongoc_stream_t *source;
    const bson_t *opts;
    bson_value_t *file_id;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_bucket_upload_from_stream(bucket, filename, source, opts, file_id, error);
    OUTPUT:
        RETVAL

bool
gridfs_bucket_upload_from_stream_with_id(bucket, file_id, filename, source, opts, error)
    mongoc_gridfs_bucket_t *bucket;
    const bson_value_t *file_id;
    const char *filename;
    mongoc_stream_t *source;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_bucket_upload_from_stream_with_id(bucket, file_id, filename, source, opts, error);
    OUTPUT:
        RETVAL

mongoc_gridfs_file_t *
gridfs_create_file(gridfs, opt)
    mongoc_gridfs_t *gridfs;
    mongoc_gridfs_file_opt_t *opt;
    CODE:
        RETVAL = mongoc_gridfs_create_file(gridfs, opt);
    OUTPUT:
        RETVAL

mongoc_gridfs_file_t *
gridfs_create_file_from_stream(gridfs, stream, opt)
    mongoc_gridfs_t *gridfs;
    mongoc_stream_t *stream;
    mongoc_gridfs_file_opt_t *opt;
    CODE:
        RETVAL = mongoc_gridfs_create_file_from_stream(gridfs, stream, opt);
    OUTPUT:
        RETVAL

void
gridfs_destroy(gridfs)
    mongoc_gridfs_t *gridfs;
    CODE:
        mongoc_gridfs_destroy(gridfs);

bool
gridfs_drop(gridfs, error)
    mongoc_gridfs_t *gridfs;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_drop(gridfs, error);
    OUTPUT:
        RETVAL

mongoc_gridfs_file_list_t *
gridfs_find(gridfs, query)
    mongoc_gridfs_t *gridfs;
    const bson_t *query;
    CODE:
        RETVAL = mongoc_gridfs_find(gridfs, query);
    OUTPUT:
        RETVAL

mongoc_gridfs_file_t *
gridfs_find_one(gridfs, query, error)
    mongoc_gridfs_t *gridfs;
    const bson_t *query;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_find_one(gridfs, query, error);
    OUTPUT:
        RETVAL

mongoc_gridfs_file_t *
gridfs_find_one_by_filename(gridfs, filename, error)
    mongoc_gridfs_t *gridfs;
    const char *filename;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_find_one_by_filename(gridfs, filename, error);
    OUTPUT:
        RETVAL

mongoc_gridfs_file_t *
gridfs_find_one_with_opts(gridfs, filter, opts, error)
    mongoc_gridfs_t *gridfs;
    const bson_t *filter;
    const bson_t *opts;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_find_one_with_opts(gridfs, filter, opts, error);
    OUTPUT:
        RETVAL

mongoc_gridfs_file_list_t *
gridfs_find_with_opts(gridfs, filter, opts)
    mongoc_gridfs_t *gridfs;
    const bson_t *filter;
    const bson_t *opts;
    CODE:
        RETVAL = mongoc_gridfs_find_with_opts(gridfs, filter, opts);
    OUTPUT:
        RETVAL

mongoc_collection_t *
gridfs_get_chunks(gridfs)
    mongoc_gridfs_t *gridfs;
    CODE:
        RETVAL = mongoc_gridfs_get_chunks(gridfs);
    OUTPUT:
        RETVAL

mongoc_collection_t *
gridfs_get_files(gridfs)
    mongoc_gridfs_t *gridfs;
    CODE:
        RETVAL = mongoc_gridfs_get_files(gridfs);
    OUTPUT:
        RETVAL

bool
gridfs_remove_by_filename(gridfs, filename, error)
    mongoc_gridfs_t *gridfs;
    const char *filename;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_gridfs_remove_by_filename(gridfs, filename, error);
    OUTPUT:
        RETVAL

const mongoc_index_opt_wt_t *
index_opt_wt_get_default()
    CODE:
        RETVAL = mongoc_index_opt_wt_get_default();
    OUTPUT:
        RETVAL

void
index_opt_wt_init(opt)
    mongoc_index_opt_wt_t *opt;
    CODE:
        mongoc_index_opt_wt_init(opt);

void
optional_copy(source, copy)
    const mongoc_optional_t *source;
    mongoc_optional_t *copy;
    CODE:
        mongoc_optional_copy(source, copy);

void
optional_init(opt)
    mongoc_optional_t *opt;
    CODE:
        mongoc_optional_init(opt);

bool
optional_is_set(opt)
    const mongoc_optional_t *opt;
    CODE:
        RETVAL = mongoc_optional_is_set(opt);
    OUTPUT:
        RETVAL

void
optional_set_value(opt, val)
    mongoc_optional_t *opt;
    bool val;
    CODE:
        mongoc_optional_set_value(opt, val);

bool
optional_value(opt)
    const mongoc_optional_t *opt;
    CODE:
        RETVAL = mongoc_optional_value(opt);
    OUTPUT:
        RETVAL

void
rand_add(buf, num, entropy)
    const void *buf;
    int num;
    double entropy;
    CODE:
        mongoc_rand_add(buf, num, entropy);

void
rand_seed(buf, num)
    const void *buf;
    int num;
    CODE:
        mongoc_rand_seed(buf, num);

int
rand_status()
    CODE:
        RETVAL = mongoc_rand_status();
    OUTPUT:
        RETVAL

bool
read_concern_append(read_concern, opts)
    mongoc_read_concern_t *read_concern;
    bson_t *opts;
    CODE:
        RETVAL = mongoc_read_concern_append(read_concern, opts);
    OUTPUT:
        RETVAL

mongoc_read_concern_t *
read_concern_copy(read_concern)
    const mongoc_read_concern_t *read_concern;
    CODE:
        RETVAL = mongoc_read_concern_copy(read_concern);
    OUTPUT:
        RETVAL

void
read_concern_destroy(read_concern)
    mongoc_read_concern_t *read_concern;
    CODE:
        mongoc_read_concern_destroy(read_concern);

const char *
read_concern_get_level(read_concern)
    const mongoc_read_concern_t *read_concern;
    CODE:
        RETVAL = mongoc_read_concern_get_level(read_concern);
    OUTPUT:
        RETVAL

bool
read_concern_is_default(read_concern)
    mongoc_read_concern_t *read_concern;
    CODE:
        RETVAL = mongoc_read_concern_is_default(read_concern);
    OUTPUT:
        RETVAL

mongoc_read_concern_t *
read_concern_new(void)
    CODE:
        RETVAL = mongoc_read_concern_new();
    OUTPUT:
        RETVAL

bool
read_concern_set_level(read_concern, level)
    mongoc_read_concern_t *read_concern;
    const char *level;
    CODE:
        RETVAL = mongoc_read_concern_set_level(read_concern, level);
    OUTPUT:
        RETVAL

void
read_prefs_add_tag(read_prefs, tag)
    mongoc_read_prefs_t *read_prefs;
    const bson_t *tag;
    CODE:
        mongoc_read_prefs_add_tag(read_prefs, tag);

mongoc_read_prefs_t *
read_prefs_copy(read_prefs)
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        RETVAL = mongoc_read_prefs_copy(read_prefs);
    OUTPUT:
        RETVAL

void
read_prefs_destroy(read_prefs)
    mongoc_read_prefs_t *read_prefs;
    CODE:
        mongoc_read_prefs_destroy(read_prefs);

const bson_t *
read_prefs_get_hedge(read_prefs)
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        RETVAL = mongoc_read_prefs_get_hedge(read_prefs);
    OUTPUT:
        RETVAL

int64_t
read_prefs_get_max_staleness_seconds(read_prefs)
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        RETVAL = mongoc_read_prefs_get_max_staleness_seconds(read_prefs);
    OUTPUT:
        RETVAL

mongoc_read_mode_t
read_prefs_get_mode(read_prefs)
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        RETVAL = mongoc_read_prefs_get_mode(read_prefs);
    OUTPUT:
        RETVAL

const bson_t *
read_prefs_get_tags(read_prefs)
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        RETVAL = mongoc_read_prefs_get_tags(read_prefs);
    OUTPUT:
        RETVAL

bool
read_prefs_is_valid(read_prefs)
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        RETVAL = mongoc_read_prefs_is_valid(read_prefs);
    OUTPUT:
        RETVAL

mongoc_read_prefs_t *
read_prefs_new(read_mode)
    mongoc_read_mode_t read_mode;
    CODE:
        RETVAL = mongoc_read_prefs_new(read_mode);
    OUTPUT:
        RETVAL

void
read_prefs_set_hedge(read_prefs, hedge)
    mongoc_read_prefs_t *read_prefs;
    const bson_t *hedge;
    CODE:
        mongoc_read_prefs_set_hedge(read_prefs, hedge);

void
read_prefs_set_max_staleness_seconds(read_prefs, max_staleness_seconds)
    mongoc_read_prefs_t *read_prefs;
    int64_t max_staleness_seconds;
    CODE:
        mongoc_read_prefs_set_max_staleness_seconds(read_prefs, max_staleness_seconds);

void
read_prefs_set_mode(read_prefs, mode)
    mongoc_read_prefs_t *read_prefs;
    mongoc_read_mode_t mode;
    CODE:
        mongoc_read_prefs_set_mode(read_prefs, mode);

void
read_prefs_set_tags(read_prefs, tags)
    mongoc_read_prefs_t *read_prefs;
    const bson_t *tags;
    CODE:
        mongoc_read_prefs_set_tags(read_prefs, tags);

mongoc_server_api_t *
server_api_copy(api)
    const mongoc_server_api_t *api;
    CODE:
        RETVAL = mongoc_server_api_copy(api);
    OUTPUT:
        RETVAL

void
server_api_deprecation_errors(api, deprecation_errors)
    mongoc_server_api_t *api;
    bool deprecation_errors;
    CODE:
        mongoc_server_api_deprecation_errors(api, deprecation_errors);

void
server_api_destroy(api)
    mongoc_server_api_t *api;
    CODE:
        mongoc_server_api_destroy(api);

const mongoc_optional_t *
server_api_get_deprecation_errors(api)
    const mongoc_server_api_t *api;
    CODE:
        RETVAL = mongoc_server_api_get_deprecation_errors(api);
    OUTPUT:
        RETVAL

const mongoc_optional_t *
server_api_get_strict(api)
    const mongoc_server_api_t *api;
    CODE:
        RETVAL = mongoc_server_api_get_strict(api);
    OUTPUT:
        RETVAL

mongoc_server_api_version_t
server_api_get_version(api)
    const mongoc_server_api_t *api;
    CODE:
        RETVAL = mongoc_server_api_get_version(api);
    OUTPUT:
        RETVAL

mongoc_server_api_t *
server_api_new(version)
    mongoc_server_api_version_t version;
    CODE:
        RETVAL = mongoc_server_api_new(version);
    OUTPUT:
        RETVAL

void
server_api_strict(api, strict)
    mongoc_server_api_t *api;
    bool strict;
    CODE:
        mongoc_server_api_strict(api, strict);

bool
server_api_version_from_string(version, out)
    const char *version;
    mongoc_server_api_version_t *out;
    CODE:
        RETVAL = mongoc_server_api_version_from_string(version, out);
    OUTPUT:
        RETVAL

const char *
server_api_version_to_string(version)
    mongoc_server_api_version_t version;
    CODE:
        RETVAL = mongoc_server_api_version_to_string(version);
    OUTPUT:
        RETVAL


const mongoc_ssl_opt_t *
ssl_opt_get_default()
    CODE:
        RETVAL = mongoc_ssl_opt_get_default();
    OUTPUT:
        RETVAL

int
stream_file_get_fd(stream)
    mongoc_stream_file_t *stream;
    CODE:
        RETVAL = mongoc_stream_file_get_fd(stream);
    OUTPUT:
        RETVAL

mongoc_stream_t *
stream_file_new(fd)
    int fd;
    CODE:
        RETVAL = mongoc_stream_file_new(fd);
    OUTPUT:
        RETVAL

mongoc_stream_t *
stream_file_new_for_path(path, flags, mode)
    const char *path;
    int flags;
    int mode;
    CODE:
        RETVAL = mongoc_stream_file_new_for_path(path, flags, mode);
    OUTPUT:
        RETVAL

mongoc_socket_t *
stream_socket_get_socket(stream)
    mongoc_stream_socket_t *stream;
    CODE:
        RETVAL = mongoc_stream_socket_get_socket(stream);
    OUTPUT:
        RETVAL

mongoc_stream_t *
stream_socket_new(socket)
    mongoc_socket_t *socket;
    CODE:
        RETVAL = mongoc_stream_socket_new(socket);
    OUTPUT:
        RETVAL

void
server_description_destroy(description)
    mongoc_server_description_t *description;
    CODE:
        mongoc_server_description_destroy(description);

const bson_t *
server_description_hello_response(description)
    const mongoc_server_description_t *description;
    CODE:
        RETVAL = mongoc_server_description_hello_response(description);
    OUTPUT:
        RETVAL

mongoc_host_list_t *
server_description_host(description)
    const mongoc_server_description_t *description;
    CODE:
        RETVAL = mongoc_server_description_host(description);
    OUTPUT:
        RETVAL

uint32_t
server_description_id(description)
    const mongoc_server_description_t *description;
    CODE:
        RETVAL = mongoc_server_description_id(description);
    OUTPUT:
        RETVAL

const bson_t *
server_description_ismaster(description)
    const mongoc_server_description_t *description;
    CODE:
        RETVAL = mongoc_server_description_ismaster(description);
    OUTPUT:
        RETVAL

int64_t
server_description_last_update_time(description)
    const mongoc_server_description_t *description;
    CODE:
        RETVAL = mongoc_server_description_last_update_time(description);
    OUTPUT:
        RETVAL

mongoc_server_description_t *
server_description_new_copy(description)
    const mongoc_server_description_t *description;
    CODE:
        RETVAL = mongoc_server_description_new_copy(description);
    OUTPUT:
        RETVAL

int64_t
server_description_round_trip_time(description)
    const mongoc_server_description_t *description;
    CODE:
        RETVAL = mongoc_server_description_round_trip_time(description);
    OUTPUT:
        RETVAL

const char *
server_description_type(description)
    const mongoc_server_description_t *description;
    CODE:
        RETVAL = mongoc_server_description_type(description);
    OUTPUT:
        RETVAL

void
server_descriptions_destroy_all(sds, n)
    mongoc_server_description_t **sds;
    size_t n;
    CODE:
        mongoc_server_descriptions_destroy_all(sds, n);

mongoc_session_opt_t *
session_opts_new()
    CODE:
        RETVAL = mongoc_session_opts_new();
    OUTPUT:
        RETVAL

bool
session_opts_get_causal_consistency(opts)
    const mongoc_session_opt_t *opts;
    CODE:
        RETVAL = mongoc_session_opts_get_causal_consistency(opts);
    OUTPUT:
        RETVAL

void
session_opts_set_causal_consistency(opts, causal_consistency)
    mongoc_session_opt_t *opts;
    bool causal_consistency;
    CODE:
        mongoc_session_opts_set_causal_consistency(opts, causal_consistency);

const mongoc_transaction_opt_t *
session_opts_get_default_transaction_opts(opts)
    const mongoc_session_opt_t *opts;
    CODE:
        RETVAL = mongoc_session_opts_get_default_transaction_opts(opts);
    OUTPUT:
        RETVAL

void
session_opts_set_default_transaction_opts(opts, txn_opts)
    mongoc_session_opt_t *opts;
    const mongoc_transaction_opt_t *txn_opts;
    CODE:
        mongoc_session_opts_set_default_transaction_opts(opts, txn_opts);

bool
session_opts_get_snapshot(opts)
    const mongoc_session_opt_t *opts;
    CODE:
        RETVAL = mongoc_session_opts_get_snapshot(opts);
    OUTPUT:
        RETVAL

void
session_opts_set_snapshot(opts, snapshot)
    mongoc_session_opt_t *opts;
    bool snapshot;
    CODE:
        mongoc_session_opts_set_snapshot(opts, snapshot);

mongoc_transaction_opt_t *
session_opts_get_transaction_opts(session)
    const mongoc_client_session_t *session;
    CODE:
        RETVAL = mongoc_session_opts_get_transaction_opts(session);
    OUTPUT:
        RETVAL

mongoc_session_opt_t *
session_opts_clone(opts)
    const mongoc_session_opt_t *opts;
    CODE:
        RETVAL = mongoc_session_opts_clone(opts);
    OUTPUT:
        RETVAL

void
session_opts_destroy(opts)
    mongoc_session_opt_t *opts;
    CODE:
        mongoc_session_opts_destroy(opts);

mongoc_socket_t *
socket_accept(sock, expire_at)
    mongoc_socket_t *sock;
    int64_t expire_at;
    CODE:
        RETVAL = mongoc_socket_accept(sock, expire_at);
    OUTPUT:
        RETVAL

int
socket_bind(sock, addr, addrlen)
    mongoc_socket_t *sock;
    const struct sockaddr *addr;
    mongoc_socklen_t addrlen;
    CODE:
        RETVAL = mongoc_socket_bind(sock, addr, addrlen);
    OUTPUT:
        RETVAL

int
socket_close(socket)
    mongoc_socket_t *socket;
    CODE:
        RETVAL = mongoc_socket_close(socket);
    OUTPUT:
        RETVAL

int
socket_connect(sock, addr, addrlen, expire_at)
    mongoc_socket_t *sock;
    const struct sockaddr *addr;
    mongoc_socklen_t addrlen;
    int64_t expire_at;
    CODE:
        RETVAL = mongoc_socket_connect(sock, addr, addrlen, expire_at);
    OUTPUT:
        RETVAL

void
socket_destroy(sock)
    mongoc_socket_t *sock;
    CODE:
        mongoc_socket_destroy(sock);

int
socket_errno(sock)
    mongoc_socket_t *sock;
    CODE:
        RETVAL = mongoc_socket_errno(sock);
    OUTPUT:
        RETVAL

char *
socket_getnameinfo(sock)
    mongoc_socket_t *sock;
    CODE:
        RETVAL = mongoc_socket_getnameinfo(sock);
    OUTPUT:
        RETVAL

int
socket_getsockname(sock, addr, addrlen)
    mongoc_socket_t *sock;
    struct sockaddr *addr;
    mongoc_socklen_t *addrlen;
    CODE:
        RETVAL = mongoc_socket_getsockname(sock, addr, addrlen);
    OUTPUT:
        RETVAL

int
socket_listen(sock, backlog)
    mongoc_socket_t *sock;
    unsigned int backlog;
    CODE:
        RETVAL = mongoc_socket_listen(sock, backlog);
    OUTPUT:
        RETVAL

mongoc_socket_t *
socket_new(domain, type, protocol)
    int domain;
    int type;
    int protocol;
    CODE:
        RETVAL = mongoc_socket_new(domain, type, protocol);
    OUTPUT:
        RETVAL

ssize_t
socket_recv(sock, buf, buflen, flags, expire_at)
    mongoc_socket_t *sock;
    void *buf;
    size_t buflen;
    int flags;
    int64_t expire_at;
    CODE:
        RETVAL = mongoc_socket_recv(sock, buf, buflen, flags, expire_at);
    OUTPUT:
        RETVAL

ssize_t
socket_send(sock, buf, buflen, expire_at)
    mongoc_socket_t *sock;
    const void *buf;
    size_t buflen;
    int64_t expire_at;
    CODE:
        RETVAL = mongoc_socket_send(sock, buf, buflen, expire_at);
    OUTPUT:
        RETVAL

ssize_t
socket_sendv(sock, iov, iovcnt, expire_at)
    mongoc_socket_t *sock;
    mongoc_iovec_t *iov;
    size_t iovcnt;
    int64_t expire_at;
    CODE:
        RETVAL = mongoc_socket_sendv(sock, iov, iovcnt, expire_at);
    OUTPUT:
        RETVAL

int
socket_setsockopt(sock, level, optname, optval, optlen)
    mongoc_socket_t *sock;
    int level;
    int optname;
    const void *optval;
    mongoc_socklen_t optlen;
    CODE:
        RETVAL = mongoc_socket_setsockopt(sock, level, optname, optval, optlen);
    OUTPUT:
        RETVAL

mongoc_stream_t *
stream_buffered_new(base_stream, buffer_size)
    mongoc_stream_t *base_stream;
    size_t buffer_size;
    CODE:
        RETVAL = mongoc_stream_buffered_new(base_stream, buffer_size);
    OUTPUT:
        RETVAL

int
stream_close(stream)
    mongoc_stream_t *stream;
    CODE:
        RETVAL = mongoc_stream_close(stream);
    OUTPUT:
        RETVAL

void
stream_destroy(stream)
    mongoc_stream_t *stream;
    CODE:
        mongoc_stream_destroy(stream);

int
stream_flush(stream)
    mongoc_stream_t *stream;
    CODE:
        RETVAL = mongoc_stream_flush(stream);
    OUTPUT:
        RETVAL

mongoc_stream_t *
stream_get_base_stream(stream)
    mongoc_stream_t *stream;
    CODE:
        RETVAL = mongoc_stream_get_base_stream(stream);
    OUTPUT:
        RETVAL

ssize_t
stream_read(stream, buf, count, min_bytes, timeout_msec)
    mongoc_stream_t *stream;
    void *buf;
    size_t count;
    size_t min_bytes;
    int32_t timeout_msec;
    CODE:
        RETVAL = mongoc_stream_read(stream, buf, count, min_bytes, timeout_msec);
    OUTPUT:
        RETVAL

ssize_t
stream_readv(stream, iov, iovcnt, min_bytes, timeout_msec)
    mongoc_stream_t *stream;
    mongoc_iovec_t *iov;
    size_t iovcnt;
    size_t min_bytes;
    int32_t timeout_msec;
    CODE:
        RETVAL = mongoc_stream_readv(stream, iov, iovcnt, min_bytes, timeout_msec);
    OUTPUT:
        RETVAL

int
stream_setsockopt(stream, level, optname, optval, optlen)
    mongoc_stream_t *stream;
    int level;
    int optname;
    void *optval;
    mongoc_socklen_t optlen;
    CODE:
        RETVAL = mongoc_stream_setsockopt(stream, level, optname, optval, optlen);
    OUTPUT:
        RETVAL

bool
stream_should_retry(stream)
    mongoc_stream_t *stream;
    CODE:
        RETVAL = mongoc_stream_should_retry(stream);
    OUTPUT:
        RETVAL

bool
stream_timed_out(stream)
    mongoc_stream_t *stream;
    CODE:
        RETVAL = mongoc_stream_timed_out(stream);
    OUTPUT:
        RETVAL

ssize_t
stream_write(stream, buf, count, timeout_msec)
    mongoc_stream_t *stream;
    void *buf;
    size_t count;
    int32_t timeout_msec;
    CODE:
        RETVAL = mongoc_stream_write(stream, buf, count, timeout_msec);
    OUTPUT:
        RETVAL

ssize_t
stream_writev(stream, iov, iovcnt, timeout_msec)
    mongoc_stream_t *stream;
    mongoc_iovec_t *iov;
    size_t iovcnt;
    int32_t timeout_msec;
    CODE:
        RETVAL = mongoc_stream_writev(stream, iov, iovcnt, timeout_msec);
    OUTPUT:
        RETVAL

void
topology_description_destroy(description)
    mongoc_topology_description_t *description;
    CODE:
        mongoc_topology_description_destroy(description);

mongoc_server_description_t **
topology_description_get_servers(td, n)
    const mongoc_topology_description_t *td;
    size_t *n;
    CODE:
        RETVAL = mongoc_topology_description_get_servers(td, n);
    OUTPUT:
        RETVAL

bool
topology_description_has_readable_server(td, prefs)
    const mongoc_topology_description_t *td;
    const mongoc_read_prefs_t *prefs;
    CODE:
        RETVAL = mongoc_topology_description_has_readable_server(td, prefs);
    OUTPUT:
        RETVAL

bool
topology_description_has_writable_server(td)
    const mongoc_topology_description_t *td;
    CODE:
        RETVAL = mongoc_topology_description_has_writable_server(td);
    OUTPUT:
        RETVAL

mongoc_topology_description_t *
topology_description_new_copy(description)
    const mongoc_topology_description_t *description;
    CODE:
        RETVAL = mongoc_topology_description_new_copy(description);
    OUTPUT:
        RETVAL

const char *
topology_description_type(td)
    const mongoc_topology_description_t *td;
    CODE:
        RETVAL = mongoc_topology_description_type(td);
    OUTPUT:
        RETVAL

void
transaction_opts_set_read_concern(opts, read_concern)
    mongoc_transaction_opt_t *opts;
    const mongoc_read_concern_t *read_concern;
    CODE:
        mongoc_transaction_opts_set_read_concern(opts, read_concern);

void
transaction_opts_set_write_concern(opts, write_concern)
    mongoc_transaction_opt_t *opts;
    const mongoc_write_concern_t *write_concern;
    CODE:
        mongoc_transaction_opts_set_write_concern(opts, write_concern);

void
transaction_opts_set_read_prefs(opts, read_prefs)
    mongoc_transaction_opt_t *opts;
    const mongoc_read_prefs_t *read_prefs;
    CODE:
        mongoc_transaction_opts_set_read_prefs(opts, read_prefs);

mongoc_transaction_opt_t *
transaction_opts_new()
    CODE:
        RETVAL = mongoc_transaction_opts_new();
    OUTPUT:
        RETVAL

const mongoc_read_concern_t *
transaction_opts_get_read_concern(opts)
    const mongoc_transaction_opt_t *opts;
    CODE:
        RETVAL = mongoc_transaction_opts_get_read_concern(opts);
    OUTPUT:
        RETVAL

const mongoc_write_concern_t *
transaction_opts_get_write_concern(opts)
    const mongoc_transaction_opt_t *opts;
    CODE:
        RETVAL = mongoc_transaction_opts_get_write_concern(opts);
    OUTPUT:
        RETVAL

const mongoc_read_prefs_t *
transaction_opts_get_read_prefs(opts)
    const mongoc_transaction_opt_t *opts;
    CODE:
        RETVAL = mongoc_transaction_opts_get_read_prefs(opts);
    OUTPUT:
        RETVAL

int64_t
transaction_opts_get_max_commit_time_ms(opts)
    const mongoc_transaction_opt_t *opts;
    CODE:
        RETVAL = mongoc_transaction_opts_get_max_commit_time_ms(opts);
    OUTPUT:
        RETVAL

void
transaction_opts_set_max_commit_time_ms(opts, max_commit_time_ms)
    mongoc_transaction_opt_t *opts;
    int64_t max_commit_time_ms;
    CODE:
        mongoc_transaction_opts_set_max_commit_time_ms(opts, max_commit_time_ms);

mongoc_transaction_opt_t *
transaction_opts_clone(opts)
    const mongoc_transaction_opt_t *opts;
    CODE:
        RETVAL = mongoc_transaction_opts_clone(opts);
    OUTPUT:
        RETVAL

void
transaction_opts_destroy(opts)
    mongoc_transaction_opt_t *opts;
    CODE:
        mongoc_transaction_opts_destroy(opts);

const mongoc_index_opt_geo_t *
index_opt_geo_get_default()
    CODE:
        RETVAL = mongoc_index_opt_geo_get_default();
    OUTPUT:
        RETVAL

void
index_opt_geo_init(opt)
    mongoc_index_opt_geo_t *opt;
    CODE:
        mongoc_index_opt_geo_init(opt);

const mongoc_index_opt_t *
index_opt_get_default()
    CODE:
        RETVAL = mongoc_index_opt_get_default();
    OUTPUT:
        RETVAL

void
index_opt_init(opt)
    mongoc_index_opt_t *opt;
    CODE:
        mongoc_index_opt_init(opt);

bool
write_concern_append(write_concern, command)
    mongoc_write_concern_t *write_concern;
    bson_t *command;
    CODE:
        RETVAL = mongoc_write_concern_append(write_concern, command);
    OUTPUT:
        RETVAL

mongoc_write_concern_t *
write_concern_copy(write_concern)
    const mongoc_write_concern_t *write_concern;
    CODE:
        RETVAL = mongoc_write_concern_copy(write_concern);
    OUTPUT:
        RETVAL

void
write_concern_destroy(write_concern)
    mongoc_write_concern_t *write_concern;
    CODE:
        mongoc_write_concern_destroy(write_concern);

bool
write_concern_get_fsync(write_concern)
    const mongoc_write_concern_t *write_concern;
    CODE:
        RETVAL = mongoc_write_concern_get_fsync(write_concern);
    OUTPUT:
        RETVAL

bool
write_concern_get_journal(write_concern)
    const mongoc_write_concern_t *write_concern;
    CODE:
        RETVAL = mongoc_write_concern_get_journal(write_concern);
    OUTPUT:
        RETVAL

int32_t
write_concern_get_w(write_concern)
    const mongoc_write_concern_t *write_concern;
    CODE:
        RETVAL = mongoc_write_concern_get_w(write_concern);
    OUTPUT:
        RETVAL

bool
write_concern_get_wmajority(write_concern)
    const mongoc_write_concern_t *write_concern;
    CODE:
        RETVAL = mongoc_write_concern_get_wmajority(write_concern);
    OUTPUT:
        RETVAL

const char *
write_concern_get_wtag(write_concern)
    const mongoc_write_concern_t *write_concern;
    CODE:
        RETVAL = mongoc_write_concern_get_wtag(write_concern);
    OUTPUT:
        RETVAL

int32_t
write_concern_get_wtimeout(write_concern)
    const mongoc_write_concern_t *write_concern;
    CODE:
        RETVAL = mongoc_write_concern_get_wtimeout(write_concern);
    OUTPUT:
        RETVAL

int64_t
write_concern_get_wtimeout_int64(write_concern)
    const mongoc_write_concern_t *write_concern;
    CODE:
        RETVAL = mongoc_write_concern_get_wtimeout_int64(write_concern);
    OUTPUT:
        RETVAL

bool
write_concern_is_acknowledged(write_concern)
    const mongoc_write_concern_t *write_concern;
    CODE:
        RETVAL = mongoc_write_concern_is_acknowledged(write_concern);
    OUTPUT:
        RETVAL

bool
write_concern_is_default(write_concern)
    mongoc_write_concern_t *write_concern;
    CODE:
        RETVAL = mongoc_write_concern_is_default(write_concern);
    OUTPUT:
        RETVAL

bool
write_concern_is_valid(write_concern)
    const mongoc_write_concern_t *write_concern;
    CODE:
        RETVAL = mongoc_write_concern_is_valid(write_concern);
    OUTPUT:
        RETVAL

bool
write_concern_journal_is_set(write_concern)
    const mongoc_write_concern_t *write_concern;
    CODE:
        RETVAL = mongoc_write_concern_journal_is_set(write_concern);
    OUTPUT:
        RETVAL

mongoc_write_concern_t *
write_concern_new()
    CODE:
        RETVAL = mongoc_write_concern_new();
    OUTPUT:
        RETVAL

void
write_concern_set_fsync(write_concern, fsync_)
    mongoc_write_concern_t *write_concern;
    bool fsync_;
    CODE:
        mongoc_write_concern_set_fsync(write_concern, fsync_);

void
write_concern_set_journal(write_concern, journal)
    mongoc_write_concern_t *write_concern;
    bool journal;
    CODE:
        mongoc_write_concern_set_journal(write_concern, journal);

void
write_concern_set_wmajority(write_concern, wtimeout_msec)
    mongoc_write_concern_t *write_concern;
    int32_t wtimeout_msec;
    CODE:
        mongoc_write_concern_set_wmajority(write_concern, wtimeout_msec);

void
write_concern_set_wtag(write_concern, tag)
    mongoc_write_concern_t *write_concern;
    const char *tag;
    CODE:
        mongoc_write_concern_set_wtag(write_concern, tag);

void
write_concern_set_wtimeout(write_concern, wtimeout_msec)
    mongoc_write_concern_t *write_concern;
    int32_t wtimeout_msec;
    CODE:
        mongoc_write_concern_set_wtimeout(write_concern, wtimeout_msec);

void
write_concern_set_wtimeout_int64(write_concern, wtimeout_msec)
    mongoc_write_concern_t *write_concern;
    int64_t wtimeout_msec;
    CODE:
        mongoc_write_concern_set_wtimeout_int64(write_concern, wtimeout_msec);

void
write_concern_set_w(write_concern, w)
    mongoc_write_concern_t *write_concern;
    int32_t w;
    CODE:
        mongoc_write_concern_set_w(write_concern, w);

mongoc_uri_t *
uri_copy(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_copy(uri);
    OUTPUT:
        RETVAL

void
uri_destroy(uri)
    mongoc_uri_t *uri;
    CODE:
        mongoc_uri_destroy(uri);

const char *
uri_get_auth_mechanism(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_auth_mechanism(uri);
    OUTPUT:
        RETVAL

const char *
uri_get_auth_source(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_auth_source(uri);
    OUTPUT:
        RETVAL

const bson_t *
uri_get_compressors(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_compressors(uri);
    OUTPUT:
        RETVAL

const char *
uri_get_database(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_database(uri);
    OUTPUT:
        RETVAL

const mongoc_host_list_t *
uri_get_hosts(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_hosts(uri);
    OUTPUT:
        RETVAL

bool
uri_get_mechanism_properties(uri, properties)
    const mongoc_uri_t *uri;
    bson_t *properties;
    CODE:
        RETVAL = mongoc_uri_get_mechanism_properties(uri, properties);
    OUTPUT:
        RETVAL

bool
uri_get_option_as_bool(uri, option, fallback)
    const mongoc_uri_t *uri;
    const char *option;
    bool fallback;
    CODE:
        RETVAL = mongoc_uri_get_option_as_bool(uri, option, fallback);
    OUTPUT:
        RETVAL

int32_t
uri_get_option_as_int32(uri, option, fallback)
    const mongoc_uri_t *uri;
    const char *option;
    int32_t fallback;
    CODE:
        RETVAL = mongoc_uri_get_option_as_int32(uri, option, fallback);
    OUTPUT:
        RETVAL

int64_t
uri_get_option_as_int64(uri, option, fallback)
    const mongoc_uri_t *uri;
    const char *option;
    int64_t fallback;
    CODE:
        RETVAL = mongoc_uri_get_option_as_int64(uri, option, fallback);
    OUTPUT:
        RETVAL

const char *
uri_get_option_as_utf8(uri, option, fallback)
    const mongoc_uri_t *uri;
    const char *option;
    const char *fallback;
    CODE:
        RETVAL = mongoc_uri_get_option_as_utf8(uri, option, fallback);
    OUTPUT:
        RETVAL

const bson_t *
uri_get_options(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_options(uri);
    OUTPUT:
        RETVAL

const char *
uri_get_password(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_password(uri);
    OUTPUT:
        RETVAL

const mongoc_read_concern_t *
uri_get_read_concern(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_read_concern(uri);
    OUTPUT:
        RETVAL

const bson_t *
uri_get_read_prefs(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_read_prefs(uri);
    OUTPUT:
        RETVAL

const char *
uri_get_replica_set(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_replica_set(uri);
    OUTPUT:
        RETVAL

const char *
uri_get_server_monitoring_mode(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_server_monitoring_mode(uri);
    OUTPUT:
        RETVAL

const char *
uri_get_service(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_service(uri);
    OUTPUT:
        RETVAL

bool
uri_get_ssl(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_ssl(uri);
    OUTPUT:
        RETVAL

const char *
uri_get_string(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_string(uri);
    OUTPUT:
        RETVAL

const char *
uri_get_srv_hostname(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_srv_hostname(uri);
    OUTPUT:
        RETVAL

const char *
uri_get_srv_service_name(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_srv_service_name(uri);
    OUTPUT:
        RETVAL

bool
uri_get_tls(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_tls(uri);
    OUTPUT:
        RETVAL

const char *
uri_get_username(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_username(uri);
    OUTPUT:
        RETVAL

const mongoc_write_concern_t *
uri_get_write_concern(uri)
    const mongoc_uri_t *uri;
    CODE:
        RETVAL = mongoc_uri_get_write_concern(uri);
    OUTPUT:
        RETVAL

bool
uri_has_option(uri, option)
    const mongoc_uri_t *uri;
    const char *option;
    CODE:
        RETVAL = mongoc_uri_has_option(uri, option);
    OUTPUT:
        RETVAL

mongoc_uri_t *
uri_new(uri_string)
    const char *uri_string;
    CODE:
        RETVAL = mongoc_uri_new(uri_string);
    OUTPUT:
        RETVAL

mongoc_uri_t *
uri_new_for_host_port(hostname, port)
    const char *hostname;
    uint16_t port;
    CODE:
        RETVAL = mongoc_uri_new_for_host_port(hostname, port);
    OUTPUT:
        RETVAL

mongoc_uri_t *
uri_new_with_error(uri_string, error)
    const char *uri_string;
    bson_error_t *error;
    CODE:
        RETVAL = mongoc_uri_new_with_error(uri_string, error);
    OUTPUT:
        RETVAL

bool
uri_option_is_bool(option)
    const char *option;
    CODE:
        RETVAL = mongoc_uri_option_is_bool(option);
    OUTPUT:
        RETVAL

bool
uri_option_is_int32(option)
    const char *option;
    CODE:
        RETVAL = mongoc_uri_option_is_int32(option);
    OUTPUT:
        RETVAL

bool
uri_option_is_int64(option)
    const char *option;
    CODE:
        RETVAL = mongoc_uri_option_is_int64(option);
    OUTPUT:
        RETVAL

bool
uri_option_is_utf8(option)
    const char *option;
    CODE:
        RETVAL = mongoc_uri_option_is_utf8(option);
    OUTPUT:
        RETVAL

bool
uri_set_auth_mechanism(uri, value)
    mongoc_uri_t *uri;
    const char *value;
    CODE:
        RETVAL = mongoc_uri_set_auth_mechanism(uri, value);
    OUTPUT:
        RETVAL

bool
uri_set_auth_source(uri, value)
    mongoc_uri_t *uri;
    const char *value;
    CODE:
        RETVAL = mongoc_uri_set_auth_source(uri, value);
    OUTPUT:
        RETVAL

bool
uri_set_compressors(uri, compressors)
    mongoc_uri_t *uri;
    const char *compressors;
    CODE:
        RETVAL = mongoc_uri_set_compressors(uri, compressors);
    OUTPUT:
        RETVAL

bool
uri_set_database(uri, database)
    mongoc_uri_t *uri;
    const char *database;
    CODE:
        RETVAL = mongoc_uri_set_database(uri, database);
    OUTPUT:
        RETVAL

bool
uri_set_mechanism_properties(uri, properties)
    mongoc_uri_t *uri;
    const bson_t *properties;
    CODE:
        RETVAL = mongoc_uri_set_mechanism_properties(uri, properties);
    OUTPUT:
        RETVAL

bool
uri_set_option_as_bool(uri, option, value)
    const mongoc_uri_t *uri;
    const char *option;
    bool value;
    CODE:
        RETVAL = mongoc_uri_set_option_as_bool(uri, option, value);
    OUTPUT:
        RETVAL

bool
uri_set_option_as_int32(uri, option, value)
    const mongoc_uri_t *uri;
    const char *option;
    int32_t value;
    CODE:
        RETVAL = mongoc_uri_set_option_as_int32(uri, option, value);
    OUTPUT:
        RETVAL

bool
uri_set_option_as_int64(uri, option, value)
    const mongoc_uri_t *uri;
    const char *option;
    int64_t value;
    CODE:
        RETVAL = mongoc_uri_set_option_as_int64(uri, option, value);
    OUTPUT:
        RETVAL

bool
uri_set_option_as_utf8(uri, option, value)
    const mongoc_uri_t *uri;
    const char *option;
    const char *value;
    CODE:
        RETVAL = mongoc_uri_set_option_as_utf8(uri, option, value);
    OUTPUT:
        RETVAL

bool
uri_set_password(uri, password)
    mongoc_uri_t *uri;
    const char *password;
    CODE:
        RETVAL = mongoc_uri_set_password(uri, password);
    OUTPUT:
        RETVAL

void
uri_set_read_concern(uri, rc)
    mongoc_uri_t *uri;
    const mongoc_read_concern_t *rc;
    CODE:
        mongoc_uri_set_read_concern(uri, rc);

void
uri_set_read_prefs(uri, prefs)
    mongoc_uri_t *uri;
    const mongoc_read_prefs_t *prefs;
    CODE:
        mongoc_uri_set_read_prefs_t(uri, prefs);

bool
uri_set_server_monitoring_mode(uri, value)
    mongoc_uri_t *uri;
    const char *value;
    CODE:
        RETVAL = mongoc_uri_set_server_monitoring_mode(uri, value);
    OUTPUT:
        RETVAL

bool
uri_set_username(uri, username)
    mongoc_uri_t *uri;
    const char *username;
    CODE:
        RETVAL = mongoc_uri_set_username(uri, username);
    OUTPUT:
        RETVAL

void
uri_set_write_concern(uri, wc)
    mongoc_uri_t *uri;
    const mongoc_write_concern_t *wc;
    CODE:
        mongoc_uri_set_write_concern(uri, wc);

char *
uri_unescape(escaped_string)
    const char *escaped_string;
    CODE:
        RETVAL = mongoc_uri_unescape(escaped_string);
    OUTPUT:
        RETVAL