/*  <=-*- C -*-=>  */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/types.h>
#include <dirent.h>
#include <stdio.h>

MODULE = ReadDir		PACKAGE = ReadDir		

void
readdir_inode(dirname)
     char*    dirname
INIT:
  struct dirent *ent;
  DIR* dir;
  SV* record[3];
  AV *entry, *ret_val;
PPCODE:
  dir = opendir(dirname);
  if (dir) {
    while ((ent=readdir(dir))) {
      record[0] = newSVpv(ent->d_name, 0);
      record[1] = newSViv((IV)ent->d_ino);
      record[2] = newSViv((IV)ent->d_type);
      XPUSHs(sv_2mortal(newRV_noinc((SV*)av_make(3, record))));
      SvREFCNT_dec(record[0]);
      SvREFCNT_dec(record[1]);
    }
    closedir(dir);
  }


void
readdir_hashref(dirname)
     char* dirname
INIT:
  struct dirent *ent;
  DIR* dir;
  AV *entry, *ret_val;
  HV* hash;
PPCODE:
  dir = opendir(dirname);
  hash = newHV();

  if (dir) {
    while ((ent = readdir(dir))) {
      hv_store(hash, ent->d_name, strlen (ent->d_name),
	       newSViv(ent->d_ino), 0);
    }
    closedir(dir);
  }

  XPUSHs(sv_2mortal(newRV_noinc((SV *) hash)));
