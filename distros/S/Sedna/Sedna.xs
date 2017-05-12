#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libsedna.h>
#include <string.h>
#include "const-c.inc"

#define BUFFER_LENGTH 512

typedef struct SednaConnection SednaConnection;

MODULE = Sedna		PACKAGE = Sedna	 PREFIX = sedna_xs_

INCLUDE: const-xs.inc


SednaConnection*
sedna_xs_connect(class, url, db_name, login, password)
     char* class
     char* url
     char* db_name
     char* login
     char* password
     CODE:
         struct SednaConnection* conn = malloc(sizeof(struct SednaConnection));
         int ret = SEconnect(conn, url, db_name, login, password);
         if (ret == SEDNA_SESSION_OPEN) {
            RETVAL = conn;
         } else if (ret == SEDNA_AUTHENTICATION_FAILED) {
            croak("SEDNA_AUTHENTICATION_FAILED: %s", SEgetLastErrorMsg(conn));
         } else if (ret == SEDNA_OPEN_SESSION_FAILED) {
            croak("SEDNA_OPEN_SESSION_FAILED: %s", SEgetLastErrorMsg(conn));
         } else if (ret == SEDNA_ERROR) {
            croak("SEDNA_ERROR: %s", SEgetLastErrorMsg(conn));
         } else {
            croak("unknown error at SEconnect: %s", SEgetLastErrorMsg(conn));
         }
     OUTPUT:
         RETVAL


void
sedna_xs_setConnectionAttr_AUTOCOMMIT(conn, onoff)
     SednaConnection* conn
     int onoff
     CODE:
         int ret = SEsetConnectionAttr(conn, SEDNA_ATTR_AUTOCOMMIT, &onoff, sizeof(int));
         if (ret != SEDNA_SET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEsetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }


void
sedna_xs_setConnectionAttr_SESSION_DIRECTORY(conn, dir)
     SednaConnection* conn
     char* dir
     CODE:
         int ret = SEsetConnectionAttr(conn, SEDNA_ATTR_SESSION_DIRECTORY, &dir, strlen(dir));
         if (ret != SEDNA_SET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEsetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }

void
sedna_xs_setConnectionAttr_DEBUG(conn, onoff)
     SednaConnection* conn
     int onoff
     CODE:
         int ret = SEsetConnectionAttr(conn, SEDNA_ATTR_DEBUG, &onoff, sizeof(int));
         if (ret != SEDNA_SET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEsetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }

void
sedna_xs_setConnectionAttr_CONCURRENCY_TYPE(conn, type)
     SednaConnection* conn
     int type
     CODE:
         int ret = SEsetConnectionAttr(conn, SEDNA_ATTR_CONCURRENCY_TYPE, &type, sizeof(int));
         if (ret != SEDNA_SET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEsetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }

void
sedna_xs_setConnectionAttr_QUERY_EXEC_TIMEOUT(conn, timeout)
     SednaConnection* conn
     int timeout
     CODE:
         int ret = SEsetConnectionAttr(conn, SEDNA_ATTR_QUERY_EXEC_TIMEOUT, &timeout, sizeof(int));
         if (ret != SEDNA_SET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEsetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }

void
sedna_xs_setConnectionAttr_MAX_RESULT_SIZE(conn, size)
     SednaConnection* conn
     int size
     CODE:
         int ret = SEsetConnectionAttr(conn, SEDNA_ATTR_MAX_RESULT_SIZE, &size, sizeof(int));
         if (ret != SEDNA_SET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEsetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }


void
sedna_xs_setConnectionAttr_LOG_AMMOUNT(conn, ammount)
     SednaConnection* conn
     int ammount
     CODE:
         int ret = SEsetConnectionAttr(conn, SEDNA_ATTR_MAX_RESULT_SIZE, &ammount, sizeof(int));
         if (ret != SEDNA_SET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEsetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }


int
sedna_xs_getConnectionAttr_AUTOCOMMIT(conn)
     SednaConnection* conn
     CODE:
         int onoff = 0;
         int rsize = 0;
         int ret = SEgetConnectionAttr(conn, SEDNA_ATTR_AUTOCOMMIT, &onoff, &rsize);
         if (ret != SEDNA_GET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEgetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }
         RETVAL = onoff;
     OUTPUT:
         RETVAL

char*
sedna_xs_getConnectionAttr_SESSION_DIRECTORY(conn)
     SednaConnection* conn
     CODE:
         char* dir = NULL;
         int rsize = 0;
         int ret = SEgetConnectionAttr(conn, SEDNA_ATTR_SESSION_DIRECTORY, &dir, &rsize);
         if (ret != SEDNA_GET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEgetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }
         RETVAL = dir;
     OUTPUT:
         RETVAL

int
sedna_xs_getConnectionAttr_DEBUG(conn)
     SednaConnection* conn
     CODE:
         int onoff = 0;
         int rsize = 0;
         int ret = SEgetConnectionAttr(conn, SEDNA_ATTR_DEBUG, &onoff, &rsize);
         if (ret != SEDNA_GET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEgetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }
         RETVAL = onoff;
     OUTPUT:
         RETVAL

int
sedna_xs_getConnectionAttr_CONCURRENCY_TYPE(conn)
     SednaConnection* conn
     CODE:
         int type = 0;
         int rsize = 0;
         int ret = SEgetConnectionAttr(conn, SEDNA_ATTR_CONCURRENCY_TYPE, &type, &rsize);
         if (ret != SEDNA_GET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEgetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }
         RETVAL = type;
     OUTPUT:
         RETVAL
         

int
sedna_xs_getConnectionAttr_QUERY_EXEC_TIMEOUT(conn)
     SednaConnection* conn
     CODE:
         int timeout = 0;
         int rsize = 0;
         int ret = SEgetConnectionAttr(conn, SEDNA_ATTR_QUERY_EXEC_TIMEOUT, &timeout, &rsize);
         if (ret != SEDNA_GET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEgetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }
         RETVAL = timeout;
     OUTPUT:
         RETVAL


int
sedna_xs_getConnectionAttr_MAX_RESULT_SIZE(conn)
     SednaConnection* conn
     CODE:
         int size = 0;
         int rsize = 0;
         int ret = SEgetConnectionAttr(conn, SEDNA_ATTR_MAX_RESULT_SIZE, &size, &rsize);
         if (ret != SEDNA_GET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEsetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }
         RETVAL = size;
     OUTPUT:
         RETVAL


int
sedna_xs_getConnectionAttr_LOG_AMMOUNT(conn)
     SednaConnection* conn
     CODE: 
         int ammount = 0;
         int rsize = 0;
         int ret = SEgetConnectionAttr(conn, SEDNA_ATTR_MAX_RESULT_SIZE, &ammount, &rsize);
         if (ret != SEDNA_GET_ATTRIBUTE_SUCCEEDED) {
           croak("error at SEsetConnectionAttr: %s", SEgetLastErrorMsg(conn));
         }
         RETVAL = ammount;
     OUTPUT:
         RETVAL

void
sedna_xs_begin(conn)
     SednaConnection* conn
     CODE:
         int ret = SEbegin(conn);
         if (ret != SEDNA_BEGIN_TRANSACTION_SUCCEEDED) {
           if (ret == SEDNA_BEGIN_TRANSACTION_FAILED) {
             croak("SEDNA_BEGIN_TRANSACTION_FAILED: %s", SEgetLastErrorMsg(conn));
           } else {
             croak("error at SEbegin: %s", SEgetLastErrorMsg(conn));
           }
         }

void
sedna_xs_commit(conn)
     SednaConnection* conn
     CODE:
         int ret = SEcommit(conn);
         if (ret != SEDNA_COMMIT_TRANSACTION_SUCCEEDED) {
           if (ret == SEDNA_COMMIT_TRANSACTION_FAILED) {
             croak("SEDNA_COMMIT_TRANSACTION_FAILED: %s", SEgetLastErrorMsg(conn));
           } else {
             croak("error at SEcommit: %s", SEgetLastErrorMsg(conn));
           }
         }

void
sedna_xs_rollback(conn)
     SednaConnection* conn
     CODE:
         int ret = SErollback(conn);
         if (ret != SEDNA_ROLLBACK_TRANSACTION_SUCCEEDED) {
           if (ret == SEDNA_ROLLBACK_TRANSACTION_FAILED) {
             croak("SEDNA_ROLLBACK_TRANSACTION_FAILED: %s", SEgetLastErrorMsg(conn));
           } else {
             croak("error at SErollback: %s", SEgetLastErrorMsg(conn));
           }
         }

int
sedna_xs_connectionStatus(conn)
     SednaConnection* conn
     CODE:
         RETVAL = SEconnectionStatus(conn);
     OUTPUT:
         RETVAL

int
sedna_xs_transactionStatus(conn)
     SednaConnection* conn
     CODE:
         RETVAL = SEtransactionStatus(conn);
     OUTPUT:
         RETVAL

void
sedna_xs_execute(conn, svquery)
     SednaConnection* conn
     SV* svquery
     CODE:
         char* query = SvPVutf8_nolen(svquery);
         int ret = SEexecute(conn, query);
         if (ret != SEDNA_QUERY_SUCCEEDED &&
             ret != SEDNA_UPDATE_SUCCEEDED &&
             ret != SEDNA_BULK_LOAD_SUCCEEDED) {
            if (ret == SEDNA_QUERY_FAILED) {
              croak("SEDNA_QUERY_FAILED: %s", SEgetLastErrorMsg(conn));
            } else if (ret == SEDNA_UPDATE_FAILED) {
              croak("SEDNA_UPDATE_FAILED: %s", SEgetLastErrorMsg(conn));
            } else if (ret == SEDNA_BULK_LOAD_FAILED) {
              croak("SEDNA_BULK_LOAD_FAILED: %s", SEgetLastErrorMsg(conn));
            } else {
              croak("error at SEexecute: %s", SEgetLastErrorMsg(conn));
            }
         }


void
sedna_xs_executeLong(conn, file)
     SednaConnection* conn
     char* file
     CODE:
         int ret = SEexecuteLong(conn, file);
         if (ret != SEDNA_QUERY_SUCCEEDED &&
             ret != SEDNA_UPDATE_SUCCEEDED &&
             ret != SEDNA_BULK_LOAD_SUCCEEDED) {
            if (ret == SEDNA_QUERY_FAILED) {
              croak("SEDNA_QUERY_FAILED: %s", SEgetLastErrorMsg(conn));
            } else if (ret == SEDNA_UPDATE_FAILED) {
              croak("SEDNA_UPDATE_FAILED: %s", SEgetLastErrorMsg(conn));
            } else if (ret == SEDNA_BULK_LOAD_FAILED) {
              croak("SEDNA_BULK_LOAD_FAILED: %s", SEgetLastErrorMsg(conn));
            } else {
              croak("error at SEexecuteLong: %s", SEgetLastErrorMsg(conn));
            }
         }

int
sedna_xs_next(conn)
     SednaConnection* conn
     CODE:
         int ret = SEnext(conn);
         if (ret == SEDNA_NEXT_ITEM_SUCCEEDED) {
           RETVAL = 1;
         } else if (ret == SEDNA_RESULT_END) {
           RETVAL = 0;
         } else if (ret == SEDNA_NEXT_ITEM_FAILED) {
           croak("SEDNA_NEXT_ITEM_FAILED: %s", SEgetLastErrorMsg(conn));
         } else if (ret == SEDNA_NO_ITEM) {
           croak("SEDNA_NO_ITEM: %s", SEgetLastErrorMsg(conn));
         } else {
           croak("error at SEnext: %s", SEgetLastErrorMsg(conn));
         }
     OUTPUT:
         RETVAL

SV*
sedna_xs_getItem(conn)
     SednaConnection* conn
     CODE:
         char buffer[BUFFER_LENGTH];
         char* result = NULL;
         int curlen = 0;
         int ret = 0;
         while (ret = SEgetData(conn, buffer, BUFFER_LENGTH)) {
             if (ret < 0) {
                 croak("error at SEgetData: %s", SEgetLastErrorMsg(conn));
             } else if (ret == 0) {
                 break;
             } else {
                 result = realloc(result, curlen + ret);
                 if (!result) {
                    croak("error alocating memory for xml.\n");
                 }
                 memcpy((char*)((uintptr_t)result + curlen), buffer, ret); 
                 curlen += ret;
             }
         }
         if (result) {
             SV* svret = newSVpvn(result, curlen);
             SvUTF8_on(svret);
             RETVAL = svret;
             free(result);
         } else {
             RETVAL = &PL_sv_undef;
         }
     OUTPUT:
         RETVAL

int
sedna_xs_getData(conn, svbuff, reqlen)
     SednaConnection* conn
     SV* svbuff
     int reqlen
     CODE:
         SvUTF8_off(svbuff);
         char* buff = SvGROW(svbuff, reqlen+10);
         int ret = SEgetData(conn, buff, reqlen);
         if (ret < 0) {
           croak("error at SEgetData: %s", SEgetLastErrorMsg(conn));
         } else {
           RETVAL = ret;
         }
     OUTPUT:
         RETVAL

void
sedna_xs_loadData(conn, svbuff, docname, svcolname)
     SednaConnection* conn
     SV* svbuff
     char* docname
     SV* svcolname
     CODE:
         int svlen;
         char* buff = SvPVutf8(svbuff, svlen);
         char* colname = NULL;
         if (SvOK(svcolname)) {
            colname = SvPVutf8_nolen(svcolname);
         }
         int ret = SEloadData(conn, buff, svlen, docname, colname);
         if (ret != SEDNA_DATA_CHUNK_LOADED) {
           croak("error at SEloadData: %s", SEgetLastErrorMsg(conn));
         }

void
sedna_xs_endLoadData(conn)
     SednaConnection* conn
     CODE:
         int ret = SEendLoadData(conn);
         if (ret != SEDNA_BULK_LOAD_SUCCEEDED) {
           if (ret == SEDNA_BULK_LOAD_FAILED) {
             croak("SEDNA_BULK_LOAD_FAILED: %s", SEgetLastErrorMsg(conn));
           } else {
             croak("error at SEloadData: %s", SEgetLastErrorMsg(conn));
           }
         }
