#include "perlbolt.h"
#include "ingyINLINE.h"

#include <string.h>
#include <stdio.h>
#include "connection.h"

static uint_fast8_t LOG_LEVEL = NEO4J_LOG_TRACE+1;
static uint_fast32_t LOGGER_FLAGS = 0;

void new_cxn_obj(cxn_obj_t **cxn_obj) {
  Newx(*cxn_obj, 1, cxn_obj_t);
  (*cxn_obj)->connection = (neo4j_connection_t *)NULL;
  (*cxn_obj)->connected = 0;
  (*cxn_obj)->errnum = 0;
  int major_version = 0;
  int minor_version = 0;
  (*cxn_obj)->strerror = savepvs("");
}		 

int set_log_level( const char* classname, const char* lvl )
{
    if(strcmp(lvl,"NONE")==0)
    {
	LOG_LEVEL = NEO4J_LOG_TRACE+1;
    }
    if(strcmp(lvl,"ERROR")==0)
    {
	LOG_LEVEL = NEO4J_LOG_ERROR;
    }
    if(strcmp(lvl,"WARN")==0)
    {
	LOG_LEVEL = NEO4J_LOG_WARN;
    }
    if(strcmp(lvl,"INFO")==0)
    {
	LOG_LEVEL = NEO4J_LOG_INFO;
    }
    if(strcmp(lvl,"DEBUG")==0)
    {
	LOG_LEVEL = NEO4J_LOG_DEBUG;
    }
    if(strcmp(lvl,"TRACE")==0)
    {
	LOG_LEVEL = NEO4J_LOG_TRACE;
    }
    return (int) LOG_LEVEL;
}
    
SV* connect_ ( const char* classname, const char* neo4j_url,
               int timeout, bool encrypt,
               const char* tls_ca_dir, const char* tls_ca_file,
               const char* tls_pk_file, const char* tls_pk_pass )
{
  SV *cxn;
  SV *cxn_ref;
  cxn_obj_t *cxn_obj;
  char climsg[BUFLEN];
  neo4j_config_t *config;
  new_cxn_obj(&cxn_obj);
  neo4j_client_init();
  config = neo4j_new_config();
  config->connect_timeout = (time_t) timeout;
  if (strlen(tls_ca_dir)) {
      ignore_unused_result(neo4j_config_set_TLS_ca_dir(config, tls_ca_dir));
  }
  if (strlen(tls_ca_file)) {
      ignore_unused_result(neo4j_config_set_TLS_ca_file(config, tls_ca_file));
  }
  if (strlen(tls_pk_file)) {
      ignore_unused_result(neo4j_config_set_TLS_private_key(config, tls_pk_file));
  }
  if (strlen(tls_pk_pass)) {
      ignore_unused_result(neo4j_config_set_TLS_private_key_password(config, tls_pk_pass));
  }
  if (LOG_LEVEL <= NEO4J_LOG_TRACE)
  {
      neo4j_config_set_logger_provider(config, neo4j_std_logger_provider(stderr, LOG_LEVEL, LOGGER_FLAGS));
  }
  cxn_obj->connection = neo4j_connect( neo4j_url, config,
                                       encrypt ? 0 : NEO4J_INSECURE );
  if (cxn_obj->connection == NULL) {
    cxn_obj->errnum = errno;
    cxn_obj->connected = false;
    Safefree(cxn_obj->strerror);
    cxn_obj->strerror = savepv( neo4j_strerror(errno, climsg, sizeof(climsg)) );
  } else {
    if ( encrypt && ! neo4j_connection_is_secure(cxn_obj->connection) ) {
      warn("Bolt connection not secure!");
    }
    cxn_obj->major_version = cxn_obj->connection->version;
    cxn_obj->minor_version = cxn_obj->connection->minor_version;
    cxn_obj->connected = true;
  }
  cxn = newSViv((IV) cxn_obj);
  cxn_ref = newRV_noinc(cxn);
  sv_bless(cxn_ref, gv_stashpv(CXNCLASS, GV_ADD));
  SvREADONLY_on(cxn);
  return cxn_ref;
}

static const char * _check_neo4j_omni_version (int major, int minor, int patch)
{
  int min_version = (major << 20) | (minor << 12) | (patch << 4);
  return 0 < min_version && min_version <= NEO4J_VERSION_NUMBER
    ? NULL : NEO4J_VERSION;
}


MODULE = Neo4j::Bolt  PACKAGE = Neo4j::Bolt  

PROTOTYPES: DISABLE


SV *
connect_ (classname, neo4j_url, timeout, encrypt, tls_ca_dir, tls_ca_file, tls_pk_file, tls_pk_pass)
	const char *	classname
	const char *	neo4j_url
	int	timeout
	bool	encrypt
	const char *	tls_ca_dir
	const char *	tls_ca_file
	const char *	tls_pk_file
	const char *	tls_pk_pass

int
set_log_level (classname, lvl)
        const char* classname
        const char* lvl

const char *
_check_neo4j_omni_version (major, minor, patch)
        int major
        int minor
        int patch

