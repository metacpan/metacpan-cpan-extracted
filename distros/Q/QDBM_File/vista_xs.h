/*************************************************************************************************
 * The advanced API of QDBM
 *                                                      Copyright (C) 2000-2006 Mikio Hirabayashi
 * This file is part of QDBM, Quick Database Manager.
 * QDBM is free software; you can redistribute it and/or modify it under the terms of the GNU
 * Lesser General Public License as published by the Free Software Foundation; either version
 * 2.1 of the License or any later version.  QDBM is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 * You should have received a copy of the GNU Lesser General Public License along with QDBM; if
 * not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
 * 02111-1307 USA.
 *************************************************************************************************/

/* vista.h for perl XS */

#ifndef _VISTA_XS_H
#define _VISTA_XS_H

#if defined(__cplusplus)
extern "C" {
#endif

#include <depot.h>
#include <curia.h>
#include <villa.h>
#include <cabin.h>
#include <stdlib.h>
#include <time.h>


#if defined(_MSC_VER) && !defined(QDBM_INTERNAL) && !defined(QDBM_STATIC)
#define MYEXTERN extern __declspec(dllimport)
#else
#define MYEXTERN extern
#endif



/*************************************************************************************************
 * API
 *************************************************************************************************/


#define VST_LEVELMAX 64                  /* max level of B+ tree */

typedef struct {                         /* type of structure for a record */
  CBDATUM *key;                          /* datum of the key */
  CBDATUM *first;                        /* datum of the first value */
  CBLIST *rest;                          /* list of the rest values */
} VSTREC;

typedef struct {                         /* type of structure for index of a page */
  int pid;                               /* ID number of the referring page */
  CBDATUM *key;                          /* threshold key of the page */
} VSTIDX;

typedef struct {                         /* type of structure for a leaf page */
  int id;                                /* ID number of the leaf */
  int dirty;                             /* whether to be written back */
  CBLIST *recs;                          /* list of records */
  int prev;                              /* ID number of the previous leaf */
  int next;                              /* ID number of the next leaf */
} VSTLEAF;

typedef struct {                         /* type of structure for a node page */
  int id;                                /* ID number of the node */
  int dirty;                             /* whether to be written back */
  int heir;                              /* ID of the child before the first index */
  CBLIST *idxs;                          /* list of indexes */
} VSTNODE;

/* type of the pointer to a comparing function.
   `aptr' specifies the pointer to the region of one key.
   `asiz' specifies the size of the region of one key.
   `bptr' specifies the pointer to the region of the other key.
   `bsiz' specifies the size of the region of the other key.
   The return value is positive if the former is big, negative if the latter is big, 0 if both
   are equivalent. */
typedef int (*VSTCFUNC)(const char *aptr, int asiz, const char *bptr, int bsiz);
MYEXTERN VSTCFUNC VST_CMPLEX;              /* lexical comparing function */
MYEXTERN VSTCFUNC VST_CMPINT;              /* native integer comparing function */
MYEXTERN VSTCFUNC VST_CMPNUM;              /* big endian number comparing function */
MYEXTERN VSTCFUNC VST_CMPDEC;              /* decimal string comparing function */

typedef struct {                         /* type of structure for a database handle */
  DEPOT *depot;                          /* internal database handle */
  VSTCFUNC cmp;                           /* pointer to the comparing function */
  int wmode;                             /* whether to be writable */
  int cmode;                             /* compression mode for leaves */
  int root;                              /* ID number of the root page */
  int last;                              /* ID number of the last leaf */
  int lnum;                              /* number of leaves */
  int nnum;                              /* number of nodes */
  int rnum;                              /* number of records */
  CBMAP *leafc;                          /* cache for leaves */
  CBMAP *nodec;                          /* cache for nodes */
  int hist[VST_LEVELMAX];                 /* array history of visited nodes */
  int hnum;                              /* number of elements of the history */
  int hleaf;                             /* ID number of the leaf referred by the history */
  int lleaf;                             /* ID number of the last visited leaf */
  int curleaf;                           /* ID number of the leaf where the cursor is */
  int curknum;                           /* index of the key where the cursor is */
  int curvnum;                           /* index of the value where the cursor is */
  int leafrecmax;                        /* max number of records in a leaf */
  int nodeidxmax;                        /* max number of indexes in a node */
  int leafcnum;                          /* max number of caching leaves */
  int nodecnum;                          /* max number of caching nodes */
  int avglsiz;                           /* average size of each leave */
  int avgnsiz;                           /* average size of each node */
  int tran;                              /* whether in the transaction */
  int rbroot;                            /* root for rollback */
  int rblast;                            /* last for rollback */
  int rblnum;                            /* lnum for rollback */
  int rbnnum;                            /* nnum for rollback */
  int rbrnum;                            /* rnum for rollback */
} VISTA;

/*
typedef struct {
  VILLA *villa;
  int curleaf;
  int curknum;
  int curvnum;
} VLMULCUR;
*/

enum {                                   /* enumeration for open modes */
  VST_OREADER = 1 << 0,                   /* open as a reader */
  VST_OWRITER = 1 << 1,                   /* open as a writer */
  VST_OCREAT = 1 << 2,                    /* a writer creating */
  VST_OTRUNC = 1 << 3,                    /* a writer truncating */
  VST_ONOLCK = 1 << 4,                    /* open without locking */
  VST_OLCKNB = 1 << 5,                    /* lock without blocking */
  VST_OZCOMP = 1 << 6,                    /* compress leaves with ZLIB */
  VST_OYCOMP = 1 << 7,                    /* compress leaves with LZO */
  VST_OXCOMP = 1 << 8                     /* compress leaves with BZIP2 */
};

enum {                                   /* enumeration for write modes */
  VST_DOVER,                              /* overwrite the existing value */
  VST_DKEEP,                              /* keep the existing value */
  VST_DCAT,                               /* concatenate values */
  VST_DDUP,                               /* allow duplication of keys */
  VST_DDUPR                               /* allow duplication with reverse order */
};

enum {                                   /* enumeration for jump modes */
  VST_JFORWARD,                           /* step forward */
  VST_JBACKWARD                           /* step backward */
};

/*
enum {
  VL_CPCURRENT,
  VL_CPBEFORE,
  VL_CPAFTER
};
*/


/* Get a database handle.
   `name' specifies the name of a database file.
   `omode' specifies the connection mode: `VL_OWRITER' as a writer, `VL_OREADER' as a reader.
   If the mode is `VL_OWRITER', the following may be added by bitwise or: `VL_OCREAT', which
   means it creates a new database if not exist, `VL_OTRUNC', which means it creates a new
   database regardless if one exists, `VL_OZCOMP', which means leaves in the database are
   compressed with ZLIB, `VL_OYCOMP', which means leaves in the database are compressed with LZO,
   `VL_OXCOMP', which means leaves in the database are compressed with BZIP2.  Both of
   `VL_OREADER' and `VL_OWRITER' can be added to by bitwise or: `VL_ONOLCK', which means it opens
   a database file without file locking, or `VL_OLCKNB', which means locking is performed without
   blocking.
   `cmp' specifies a comparing function: `VL_CMPLEX' comparing keys in lexical order,
   `VL_CMPINT' comparing keys as objects of `int' in native byte order, `VL_CMPNUM' comparing
   keys as numbers of big endian, `VL_CMPDEC' comparing keys as decimal strings.  Any function
   based on the declaration of the type `VLCFUNC' can be assigned to the comparing function.
   The comparing function should be kept same in  the life of a database.
   The return value is the database handle or `NULL' if it is not successful.
   While connecting as a writer, an exclusive lock is invoked to the database file.
   While connecting as a reader, a shared lock is invoked to the database file.  The thread
   blocks until the lock is achieved.  `VL_OZCOMP', `VL_OYCOMP', and `VL_OXCOMP' are available
   only if QDBM was built each with ZLIB, LZO, and BZIP2 enabled.  If `VL_ONOLCK' is used, the
   application is responsible for exclusion control. */
VISTA *vstopen(const char *name, int omode, VSTCFUNC cmp);


/* Close a database handle.
   `villa' specifies a database handle.
   If successful, the return value is true, else, it is false.
   Because the region of a closed handle is released, it becomes impossible to use the handle.
   Updating a database is assured to be written when the handle is closed.  If a writer opens
   a database but does not close it appropriately, the database will be broken.  If the
   transaction is activated and not committed, it is aborted. */
int vstclose(VISTA *villa);


/* Store a record.
   `villa' specifies a database handle connected as a writer.
   `kbuf' specifies the pointer to the region of a key.
   `ksiz' specifies the size of the region of the key.  If it is negative, the size is assigned
   with `strlen(kbuf)'.
   `vbuf' specifies the pointer to the region of a value.
   `vsiz' specifies the size of the region of the value.  If it is negative, the size is
   assigned with `strlen(vbuf)'.
   `dmode' specifies behavior when the key overlaps, by the following values: `VL_DOVER',
   which means the specified value overwrites the existing one, `VL_DKEEP', which means the
   existing value is kept, `VL_DCAT', which means the specified value is concatenated at the
   end of the existing value, `VL_DDUP', which means duplication of keys is allowed and the
   specified value is added as the last one, `VL_DDUPR', which means duplication of keys is
   allowed and the specified value is added as the first one.
   If successful, the return value is true, else, it is false.
   The cursor becomes unavailable due to updating database. */
int vstput(VISTA *villa, const char *kbuf, int ksiz, const char *vbuf, int vsiz, int dmode);


/* Delete a record.
   `villa' specifies a database handle connected as a writer.
   `kbuf' specifies the pointer to the region of a key.
   `ksiz' specifies the size of the region of the key.  If it is negative, the size is assigned
   with `strlen(kbuf)'.
   If successful, the return value is true, else, it is false.  False is returned when no
   record corresponds to the specified key.
   When the key of duplicated records is specified, the first record of the same key is deleted.
   The cursor becomes unavailable due to updating database. */
int vstout(VISTA *villa, const char *kbuf, int ksiz);


/* Retrieve a record.
   `villa' specifies a database handle.
   `kbuf' specifies the pointer to the region of a key.
   `ksiz' specifies the size of the region of the key.  If it is negative, the size is assigned
   with `strlen(kbuf)'.
   `sp' specifies the pointer to a variable to which the size of the region of the return
   value is assigned.  If it is `NULL', it is not used.
   If successful, the return value is the pointer to the region of the value of the
   corresponding record, else, it is `NULL'.  `NULL' is returned when no record corresponds to
   the specified key.
   When the key of duplicated records is specified, the value of the first record of the same
   key is selected.  Because an additional zero code is appended at the end of the region of the
   return value, the return value can be treated as a character string.  Because the region of
   the return value is allocated with the `malloc' call, it should be released with the `free'
   call if it is no longer in use. */
char *vstget(VISTA *villa, const char *kbuf, int ksiz, int *sp);


/* Get the size of the value of a record.
   `villa' specifies a database handle.
   `kbuf' specifies the pointer to the region of a key.
   `ksiz' specifies the size of the region of the key.  If it is negative, the size is assigned
   with `strlen(kbuf)'.
   If successful, the return value is the size of the value of the corresponding record, else,
   it is -1.  If multiple records correspond, the size of the first is returned. */
int vstvsiz(VISTA *villa, const char *kbuf, int ksiz);


/* Get the number of records corresponding a key.
   `villa' specifies a database handle.
   `kbuf' specifies the pointer to the region of a key.
   `ksiz' specifies the size of the region of the key.  If it is negative, the size is assigned
   with `strlen(kbuf)'.
   The return value is the number of corresponding records.  If no record corresponds, 0 is
   returned. */
int vstvnum(VISTA *villa, const char *kbuf, int ksiz);


/* Store plural records corresponding a key.
   `villa' specifies a database handle connected as a writer.
   `kbuf' specifies the pointer to the region of a key.
   `ksiz' specifies the size of the region of the key.  If it is negative, the size is assigned
   with `strlen(kbuf)'.
   `vals' specifies a list handle of values.  The list should not be empty.
   If successful, the return value is true, else, it is false.
   The cursor becomes unavailable due to updating database. */
int vstputlist(VISTA *villa, const char *kbuf, int ksiz, const CBLIST *vals);


/* Delete all records corresponding a key.
   `villa' specifies a database handle connected as a writer.
   `kbuf' specifies the pointer to the region of a key.
   `ksiz' specifies the size of the region of the key.  If it is negative, the size is assigned
   with `strlen(kbuf)'.
   If successful, the return value is true, else, it is false.  False is returned when no
   record corresponds to the specified key.
   The cursor becomes unavailable due to updating database. */
int vstoutlist(VISTA *villa, const char *kbuf, int ksiz);


/* Retrieve values of all records corresponding a key.
   `villa' specifies a database handle.
   `kbuf' specifies the pointer to the region of a key.
   `ksiz' specifies the size of the region of the key.  If it is negative, the size is assigned
   with `strlen(kbuf)'.
   If successful, the return value is a list handle of the values of the corresponding records,
   else, it is `NULL'.  `NULL' is returned when no record corresponds to the specified key.
   Because the handle of the return value is opened with the function `cblistopen', it should
   be closed with the function `cblistclose' if it is no longer in use. */
CBLIST *vstgetlist(VISTA *villa, const char *kbuf, int ksiz);


/* Retrieve concatenated values of all records corresponding a key.
   `villa' specifies a database handle.
   `kbuf' specifies the pointer to the region of a key.
   `ksiz' specifies the size of the region of the key.  If it is negative, the size is assigned
   with `strlen(kbuf)'.
   `sp' specifies the pointer to a variable to which the size of the region of the return
   value is assigned.  If it is `NULL', it is not used.
   If successful, the return value is the pointer to the region of the concatenated values of
   the corresponding record, else, it is `NULL'.  `NULL' is returned when no record corresponds
   to the specified key.  Because an additional zero code is appended at the end of the region of
   the return value, the return value can be treated as a character string.  Because the region
   of the return value is allocated with the `malloc' call, it should be released with the `free'
   call if it is no longer in use. */
char *vstgetcat(VISTA *villa, const char *kbuf, int ksiz, int *sp);


/* Move the cursor to the first record.
   `villa' specifies a database handle.
   If successful, the return value is true, else, it is false.  False is returned if there is
   no record in the database. */
int vstcurfirst(VISTA *villa);


/* Move the cursor to the last record.
   `villa' specifies a database handle.
   If successful, the return value is true, else, it is false.  False is returned if there is
   no record in the database. */
int vstcurlast(VISTA *villa);


/* Move the cursor to the previous record.
   `villa' specifies a database handle.
   If successful, the return value is true, else, it is false.  False is returned if there is
   no previous record. */
int vstcurprev(VISTA *villa);


/* Move the cursor to the next record.
   `villa' specifies a database handle.
   If successful, the return value is true, else, it is false.  False is returned if there is
   no next record. */
int vstcurnext(VISTA *villa);


/* Move the cursor to a position around a record.
   `villa' specifies a database handle.
   `kbuf' specifies the pointer to the region of a key.
   `ksiz' specifies the size of the region of the key.  If it is negative, the size is assigned
   with `strlen(kbuf)'.
   `jmode' specifies detail adjustment: `VL_JFORWARD', which means that the cursor is set to
   the first record of the same key and that the cursor is set to the next substitute if
   completely matching record does not exist, `VL_JBACKWARD', which means that the cursor is
   set to the last record of the same key and that the cursor is set to the previous substitute
   if completely matching record does not exist.
   If successful, the return value is true, else, it is false.  False is returned if there is
   no record corresponding the condition. */
int vstcurjump(VISTA *villa, const char *kbuf, int ksiz, int jmode);


/* Get the key of the record where the cursor is.
   `villa' specifies a database handle.
   `sp' specifies the pointer to a variable to which the size of the region of the return
   value is assigned.  If it is `NULL', it is not used.
   If successful, the return value is the pointer to the region of the key of the corresponding
   record, else, it is `NULL'.  `NULL' is returned when no record corresponds to the cursor.
   Because an additional zero code is appended at the end of the region of the
   return value, the return value can be treated as a character string.  Because the region of
   the return value is allocated with the `malloc' call, it should be released with the `free'
   call if it is no longer in use. */
char *vstcurkey(VISTA *villa, int *sp);


/* Get the value of the record where the cursor is.
   `villa' specifies a database handle.
   `sp' specifies the pointer to a variable to which the size of the region of the return
   value is assigned.  If it is `NULL', it is not used.
   If successful, the return value is the pointer to the region of the value of the
   corresponding record, else, it is `NULL'.  `NULL' is returned when no record corresponds to
   the cursor.
   Because an additional zero code is appended at the end of the region of the
   return value, the return value can be treated as a character string.  Because the region of
   the return value is allocated with the `malloc' call, it should be released with the `free'
   call if it is no longer in use. */
char *vstcurval(VISTA *villa, int *sp);


/* Insert a record around the cursor.
   `villa' specifies a database handle connected as a writer.
   `vbuf' specifies the pointer to the region of a value.
   `vsiz' specifies the size of the region of the value.  If it is negative, the size is
   assigned with `strlen(vbuf)'.
   `cpmode' specifies detail adjustment: `VL_CPCURRENT', which means that the value of the
   current record is overwritten, `VL_CPBEFORE', which means that a new record is inserted before
   the current record, `VL_CPAFTER', which means that a new record is inserted after the current
   record.
   If successful, the return value is true, else, it is false.  False is returned when no record
   corresponds to the cursor.
   After insertion, the cursor is moved to the inserted record. */
int vstcurput(VISTA *villa, const char *vbuf, int vsiz, int cpmode);


/* Delete the record where the cursor is.
   `villa' specifies a database handle connected as a writer.
   If successful, the return value is true, else, it is false.  False is returned when no record
   corresponds to the cursor.
   After deletion, the cursor is moved to the next record if possible. */
int vstcurout(VISTA *villa);


/* Set the tuning parameters for performance.
   `villa' specifies a database handle.
   `lrecmax' specifies the max number of records in a leaf node of B+ tree.  If it is not more
   than 0, the default value is specified.
   `nidxmax' specifies the max number of indexes in a non-leaf node of B+ tree.  If it is not
   more than 0, the default value is specified.
   `lcnum' specifies the max number of caching leaf nodes.  If it is not more than 0, the
   default value is specified.
   `ncnum' specifies the max number of caching non-leaf nodes.  If it is not more than 0, the
   default value is specified.
   The default setting is equivalent to `vlsettuning(49, 192, 1024, 512)'.  Because tuning
   parameters are not saved in a database, you should specify them every opening a database. */
void vstsettuning(VISTA *villa, int lrecmax, int nidxmax, int lcnum, int ncnum);


/* Set the size of the free block pool of a database handle.
   `villa' specifies a database handle connected as a writer.
   `size' specifies the size of the free block pool of a database.
   If successful, the return value is true, else, it is false.
   The default size of the free block pool is 256.  If the size is greater, the space efficiency
   of overwriting values is improved with the time efficiency sacrificed. */
int vstsetfbpsiz(VISTA *villa, int size);


/* Synchronize updating contents with the file and the device.
   `villa' specifies a database handle connected as a writer.
   If successful, the return value is true, else, it is false.
   This function is useful when another process uses the connected database file.  This function
   should not be used while the transaction is activated. */
int vstsync(VISTA *villa);


/* Optimize a database.
   `villa' specifies a database handle connected as a writer.
   If successful, the return value is true, else, it is false.
   In an alternating succession of deleting and storing with overwrite or concatenate,
   dispensable regions accumulate.  This function is useful to do away with them.  This function
   should not be used while the transaction is activated. */
int vstoptimize(VISTA *villa);


/* Get the name of a database.
   `villa' specifies a database handle.
   If successful, the return value is the pointer to the region of the name of the database,
   else, it is `NULL'.
   Because the region of the return value is allocated with the `malloc' call, it should be
   released with the `free' call if it is no longer in use. */
char *vstname(VISTA *villa);


/* Get the size of a database file.
   `villa' specifies a database handle.
   If successful, the return value is the size of the database file, else, it is -1.
   Because of the I/O buffer, the return value may be less than the hard size. */
int vstfsiz(VISTA *villa);


/* Get the number of the leaf nodes of B+ tree.
   `villa' specifies a database handle.
   If successful, the return value is the number of the leaf nodes, else, it is -1. */
int vstlnum(VISTA *villa);


/* Get the number of the non-leaf nodes of B+ tree.
   `villa' specifies a database handle.
   If successful, the return value is the number of the non-leaf nodes, else, it is -1. */
int vstnnum(VISTA *villa);


/* Get the number of the records stored in a database.
   `villa' specifies a database handle.
   If successful, the return value is the number of the records stored in the database, else,
   it is -1. */
int vstrnum(VISTA *villa);


/* Check whether a database handle is a writer or not.
   `villa' specifies a database handle.
   The return value is true if the handle is a writer, false if not. */
int vstwritable(VISTA *villa);


/* Check whether a database has a fatal error or not.
   `villa' specifies a database handle.
   The return value is true if the database has a fatal error, false if not. */
int vstfatalerror(VISTA *villa);


/* Get the inode number of a database file.
   `villa' specifies a database handle.
   The return value is the inode number of the database file. */
int vstinode(VISTA *villa);


/* Get the last modified time of a database.
   `villa' specifies a database handle.
   The return value is the last modified time of the database. */
time_t vstmtime(VISTA *villa);


/* Begin the transaction.
   `villa' specifies a database handle connected as a writer.
   If successful, the return value is true, else, it is false.
   Because this function does not perform mutual exclusion control in multi-thread, the
   application is responsible for it.  Only one transaction can be activated with a database
   handle at the same time. */
int vsttranbegin(VISTA *villa);


/* Commit the transaction.
   `villa' specifies a database handle connected as a writer.
   If successful, the return value is true, else, it is false.
   Updating a database in the transaction is fixed when it is committed successfully. */
int vsttrancommit(VISTA *villa);


/* Abort the transaction.
   `villa' specifies a database handle connected as a writer.
   If successful, the return value is true, else, it is false.
   Updating a database in the transaction is discarded when it is aborted.  The state of the
   database is rollbacked to before transaction. */
int vsttranabort(VISTA *villa);


/* Remove a database file.
   `name' specifies the name of a database file.
   If successful, the return value is true, else, it is false. */
int vstremove(const char *name);


/* Repair a broken database file.
   `name' specifies the name of a database file.
   `cmp' specifies the comparing function of the database file.
   If successful, the return value is true, else, it is false.
   There is no guarantee that all records in a repaired database file correspond to the original
   or expected state. */
int vstrepair(const char *name, VSTCFUNC cmp);


/* Dump all records as endian independent data.
   `villa' specifies a database handle.
   `name' specifies the name of an output file.
   If successful, the return value is true, else, it is false. */
int vstexportdb(VISTA *villa, const char *name);


/* Load all records from endian independent data.
   `villa' specifies a database handle connected as a writer.  The database of the handle must
   be empty.
   `name' specifies the name of an input file.
   If successful, the return value is true, else, it is false. */
int vstimportdb(VISTA *villa, const char *name);



/*************************************************************************************************
 * features for experts
 *************************************************************************************************/


/* Number of division of the database for Vista. */
/* #define vlcrdnum       (*vlcrdnumptr()) */


/* Get the pointer of the variable of the number of division of the database for Vista.
   The return value is the pointer of the variable. */
int *vstcrdnumptr(void);


/* Synchronize updating contents on memory.
   `villa' specifies a database handle connected as a writer.
   If successful, the return value is true, else, it is false. */
int vstmemsync(VISTA *villa);


/* Synchronize updating contents on memory, not physically.
   `villa' specifies a database handle connected as a writer.
   If successful, the return value is true, else, it is false. */
int vstmemflush(VISTA *villa);


/* Refer to volatile cache of a value of a record.
   `villa' specifies a database handle.
   `kbuf' specifies the pointer to the region of a key.
   `ksiz' specifies the size of the region of the key.  If it is negative, the size is assigned
   with `strlen(kbuf)'.
   `sp' specifies the pointer to a variable to which the size of the region of the return
   value is assigned.  If it is `NULL', it is not used.
   If successful, the return value is the pointer to the region of the value of the
   corresponding record, else, it is `NULL'.  `NULL' is returned when no record corresponds to
   the specified key.
   Because the region of the return value is volatile and it may be spoiled by another operation
   of the database, the data should be copied into another involatile buffer immediately. */
const char *vstgetcache(VISTA *villa, const char *kbuf, int ksiz, int *sp);


/* Refer to volatile cache of the key of the record where the cursor is.
   `villa' specifies a database handle.
   `sp' specifies the pointer to a variable to which the size of the region of the return
   value is assigned.  If it is `NULL', it is not used.
   If successful, the return value is the pointer to the region of the key of the corresponding
   record, else, it is `NULL'.  `NULL' is returned when no record corresponds to the cursor.
   Because the region of the return value is volatile and it may be spoiled by another operation
   of the database, the data should be copied into another involatile buffer immediately. */
const char *vstcurkeycache(VISTA *villa, int *sp);


/* Refer to volatile cache of the value of the record where the cursor is.
   `villa' specifies a database handle.
   `sp' specifies the pointer to a variable to which the size of the region of the return
   value is assigned.  If it is `NULL', it is not used.
   If successful, the return value is the pointer to the region of the value of the
   corresponding record, else, it is `NULL'.  `NULL' is returned when no record corresponds to
   the cursor.
   Because an additional zero code is appended at the end of the region of the
   return value, the return value can be treated as a character string.  Because the region of
   the return value is allocated with the `malloc' call, it should be released with the `free'
   call if it is no longer in use. */
const char *vstcurvalcache(VISTA *villa, int *sp);


/* Get a multiple cursor handle.
   `villa' specifies a database handle connected as a reader.
   The return value is a multiple cursor handle or `NULL' if it is not successful.
   The returned object is should be closed before the database handle is closed.  Even if plural
   cursors are fetched out of a database handle, they does not share the locations with each
   other.  Note that this function can be used only if the database handle is connected as a
   reader. */
VLMULCUR *vstmulcuropen(VISTA *villa);


/* Close a multiple cursor handle.
   `mulcur' specifies a multiple cursor handle. */
void vstmulcurclose(VLMULCUR *mulcur);


/* Move a multiple cursor to the first record.
   `mulcur' specifies a multiple cursor handle.
   If successful, the return value is true, else, it is false.  False is returned if there is
   no record in the database. */
int vstmulcurfirst(VLMULCUR *mulcur);


/* Move a multiple cursor to the last record.
   `mulcur' specifies a multiple cursor handle.
   If successful, the return value is true, else, it is false.  False is returned if there is
   no record in the database. */
int vstmulcurlast(VLMULCUR *mulcur);


/* Move a multiple cursor to the previous record.
   `mulcur' specifies a multiple cursor handle.
   If successful, the return value is true, else, it is false.  False is returned if there is
   no previous record. */
int vstmulcurprev(VLMULCUR *mulcur);


/* Move a multiple cursor to the next record.
   `mulcur' specifies a multiple cursor handle.
   If successful, the return value is true, else, it is false.  False is returned if there is
   no next record. */
int vstmulcurnext(VLMULCUR *mulcur);


/* Move a multiple cursor to a position around a record.
   `mulcur' specifies a multiple cursor handle.
   `kbuf' specifies the pointer to the region of a key.
   `ksiz' specifies the size of the region of the key.  If it is negative, the size is assigned
   with `strlen(kbuf)'.
   `jmode' specifies detail adjustment: `VL_JFORWARD', which means that the cursor is set to
   the first record of the same key and that the cursor is set to the next substitute if
   completely matching record does not exist, `VL_JBACKWARD', which means that the cursor is
   set to the last record of the same key and that the cursor is set to the previous substitute
   if completely matching record does not exist.
   If successful, the return value is true, else, it is false.  False is returned if there is
   no record corresponding the condition. */
int vstmulcurjump(VLMULCUR *mulcur, const char *kbuf, int ksiz, int jmode);


/* Get the key of the record where a multiple cursor is.
   `mulcur' specifies a multiple cursor handle.
   `sp' specifies the pointer to a variable to which the size of the region of the return
   value is assigned.  If it is `NULL', it is not used.
   If successful, the return value is the pointer to the region of the key of the corresponding
   record, else, it is `NULL'.  `NULL' is returned when no record corresponds to the cursor.
   Because an additional zero code is appended at the end of the region of the
   return value, the return value can be treated as a character string.  Because the region of
   the return value is allocated with the `malloc' call, it should be released with the `free'
   call if it is no longer in use. */
char *vstmulcurkey(VLMULCUR *mulcur, int *sp);


/* Get the value of the record where a multiple cursor is.
   `mulcur' specifies a multiple cursor handle.
   `sp' specifies the pointer to a variable to which the size of the region of the return
   value is assigned.  If it is `NULL', it is not used.
   If successful, the return value is the pointer to the region of the value of the
   corresponding record, else, it is `NULL'.  `NULL' is returned when no record corresponds to
   the cursor.
   Because an additional zero code is appended at the end of the region of the
   return value, the return value can be treated as a character string.  Because the region of
   the return value is allocated with the `malloc' call, it should be released with the `free'
   call if it is no longer in use. */
char *vstmulcurval(VLMULCUR *mulcur, int *sp);


/* Refer to volatile cache of the key of the record where a multiple cursor is.
   `mulcur' specifies a multiple cursor handle.
   `sp' specifies the pointer to a variable to which the size of the region of the return
   value is assigned.  If it is `NULL', it is not used.
   If successful, the return value is the pointer to the region of the key of the corresponding
   record, else, it is `NULL'.  `NULL' is returned when no record corresponds to the cursor.
   Because the region of the return value is volatile and it may be spoiled by another operation
   of the database, the data should be copied into another involatile buffer immediately. */
const char *vstmulcurkeycache(VLMULCUR *mulcur, int *sp);


/* Refer to volatile cache of the value of the record where a multiple cursor is.
   `mulcur' specifies a multiple cursor handle.
   `sp' specifies the pointer to a variable to which the size of the region of the return
   value is assigned.  If it is `NULL', it is not used.
   If successful, the return value is the pointer to the region of the value of the
   corresponding record, else, it is `NULL'.  `NULL' is returned when no record corresponds to
   the cursor.
   Because an additional zero code is appended at the end of the region of the
   return value, the return value can be treated as a character string.  Because the region of
   the return value is allocated with the `malloc' call, it should be released with the `free'
   call if it is no longer in use. */
const char *vstmulcurvalcache(VLMULCUR *mulcur, int *sp);


/* Get flags of a database.
   `villa' specifies a database handle.
   The return value is the flags of a database. */
int vstgetflags(VISTA *villa);


/* Set flags of a database.
   `villa' specifies a database handle connected as a writer.
   `flags' specifies flags to set.  Least ten bits are reserved for internal use.
   If successful, the return value is true, else, it is false. */
int vstsetflags(VISTA *villa, int flags);



#undef MYEXTERN

#if defined(__cplusplus)                 /* export for C++ */
}
#endif

#endif                                   /* duplication check */


/* END OF FILE */
