/* $Id: ACEdb.xs,v 1.5 1999/01/07 19:21:37 carrigad Exp $ */

/* Copyright (C), 1998, 1999 Enbridge Inc. */

#include <adminapi.h>

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

static char messageBuf[MAX_RESULT_MSG_SIZE];

MODULE = SecurID::ACEdb		PACKAGE = SecurID::ACEdb		PREFIX = Sd_

PROTOTYPES: ENABLE

char *
Sd_Result()
	CODE:
	RETVAL = messageBuf;
	OUTPUT:
	RETVAL

int
Sd__ApiInit(servDb="", logDb="", commitFlag)
	char *	servDb
	char *	logDb
	int	commitFlag

	CODE:
	{
		char *cf = commitFlag? "1" : "0";
		char *sdb, *ldb;

		sdb = strlen(servDb)? servDb : pszSDFileGetServDB();
		ldb = strlen(logDb)? logDb : pszSDFileGetLogDB();
		RETVAL = Sd_ApiInit(sdb, ldb, cf, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

int
Sd_Commit()
	CODE:
	{
		RETVAL = Sd_Commit(messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

int
Sd_Rollback()
	CODE:
	{
		RETVAL = Sd_Rollback(messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

int
Sd_ApiEnd()
	CODE:
	{
		RETVAL = Sd_ApiEnd(messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

SV *
Sd_ApiRev()
	CODE:
	{
		if (Sd_ApiRev(messageBuf, MAX_RESULT_MSG_SIZE) == API_OK) {
			RETVAL = newSVpv(messageBuf, 0);
		} else {
			RETVAL = &sv_undef;
		}
	}
	OUTPUT:
	RETVAL

int
Sd_AssignToken(last, first, login, shell, tokenSerialNumber)
     char *last;
     char *first;
     char *login;
     char *shell;
     char * tokenSerialNumber;
     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  RETVAL = Sd_AssignToken(last, first, login, shell, sn, 
				  messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

int
Sd_SetUser(last, first, login, shell, tokenSerialNumber)
     char *last;
     char *first;
     char *login;
     char *shell;
     char * tokenSerialNumber;
     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  RETVAL = Sd_SetUser(last, first, login, shell, sn, 
			      messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

SV *
Sd__ListUserInfo(tokenSerialNumber)
     char * tokenSerialNumber;

     CODE:
	{
	  char sn[13] = "000000000000";
	  char *delim = "\r";
	  if (strcmp(tokenSerialNumber, "help") == 0) {
	    strcpy(sn, "help");
	  } else {
	    if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	    strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  }
	  if (Sd_ListUserInfo(sn, delim, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK) {
	    RETVAL = newSVpv(messageBuf, 0);
	  } else {
	    RETVAL = &sv_undef;
	  }
	}
	OUTPUT:
	RETVAL

int
Sd_UnassignToken(tokenSerialNumber)
     char * tokenSerialNumber;

     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  RETVAL = Sd_UnassignToken(sn, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

int
Sd_SetCreatePin(createPinState, tokenSerialNumber)
     char *createPinState;
     char * tokenSerialNumber;

     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  RETVAL = Sd_SetCreatePin(createPinState, sn, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

int
Sd_AddUserExtension(key, data, tokenSerialNumber)
     char *key;
     char *data;
     char * tokenSerialNumber

     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  RETVAL = Sd_AddUserExtension(key, data, sn, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

int
Sd_DelUserExtension(key, tokenSerialNumber)
     char *key;
     char * tokenSerialNumber;

     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  RETVAL = Sd_DelUserExtension(key, sn, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

SV *
Sd_ListUserExtension(key, tokenSerialNumber)
     char *key;
     char * tokenSerialNumber;

     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  if (Sd_ListUserExtension(key, sn, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK) {
	    RETVAL = newSVpv(messageBuf, 0);
	  } else {
	    RETVAL = &sv_undef;
	  }
	}
	OUTPUT:
	RETVAL

int
Sd_SetUserExtension(key, data, tokenSerialNumber)
     char *key;
     char *data;
     char * tokenSerialNumber;

     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  RETVAL = Sd_SetUserExtension(key, data, sn, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

int
Sd_DisableToken(tokenSerialNumber)
     char * tokenSerialNumber;

     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  RETVAL = Sd_DisableToken(sn, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

int
Sd_EnableToken(tokenSerialNumber)
     char * tokenSerialNumber

     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  RETVAL = Sd_EnableToken(sn, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

SV *
Sd_ListTokens()

     PPCODE:
	{
	  if (Sd_ListTokens(messageBuf, MAX_RESULT_MSG_SIZE) == API_OK) {
	    while (strcmp(messageBuf, "Done") != 0) {
	      EXTEND(sp, 1);
	      PUSHs(sv_2mortal(newSVpv(messageBuf, 0)));
	      if (Sd_ListTokens(messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
		strcpy(messageBuf, "Done");
	      }
	    }
	  }
	}

SV *
Sd__ListTokenInfo(tokenSerialNumber)
     char * tokenSerialNumber

     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strcmp(tokenSerialNumber, "help") == 0) {
	    strcpy(sn, "help");
	  } else {
	    if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	    strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  } 
	  if (Sd_ListTokenInfo(sn, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK) {
	    RETVAL = newSVpv(messageBuf, 0);
	  } else {
	    RETVAL = &sv_undef;
	  }
	}
	OUTPUT:
	RETVAL

int
Sd_ResetToken(tokenSerialNumber)
     char * tokenSerialNumber;

     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  RETVAL = Sd_ResetToken(sn, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

int
Sd_NewPin(tokenSerialNumber)
     char * tokenSerialNumber;

     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  RETVAL = Sd_NewPin(sn, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

int
Sd_AddLoginToGroup(login, groupName, shell, tokenSerialNumber)
     char *login;
     char *groupName;
     char *shell;
     char * tokenSerialNumber;

     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  RETVAL = Sd_AddLoginToGroup(login, groupName, shell, sn, 
				      messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

int
Sd_DelLoginFromGroup(login, groupName)
     char * login;
     char * groupName;

     CODE:
	{
	  RETVAL = Sd_DelLoginFromGroup(login, groupName,
					messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

SV *
Sd__ListGroupMembership(tokenSerialNumber)
     char * tokenSerialNumber

	PPCODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  if (Sd_ListGroupMembership(sn, messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
	    EXTEND(sp, 1);
	    PUSHs(&sv_undef);
	  } else {
	    EXTEND(sp, 1);
	    PUSHs(sv_2mortal(newSViv(1)));
	    while (strcmp(messageBuf, "Done") != 0) {
	      EXTEND(sp, 1);
	      PUSHs(sv_2mortal(newSVpv(messageBuf, 0)));
	      if (Sd_ListGroupMembership(sn, messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
		strcpy(messageBuf, "Done");
	      }
	    }
	  }
	}

SV *
Sd__ListGroups()
	PPCODE:
	{
	  if (Sd_ListGroups(messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
	    EXTEND(sp, 1);
	    PUSHs(&sv_undef);
	  } else {
	    EXTEND(sp, 1);
	    PUSHs(sv_2mortal(newSViv(1)));
	    while (strcmp(messageBuf, "Done") != 0) {
	      EXTEND(sp, 1);
	      PUSHs(sv_2mortal(newSVpv(messageBuf, 0)));
	      if (Sd_ListGroups(messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
		strcpy(messageBuf, "Done");
	      }
	    }
	  }
	}

int
Sd_EnableLoginOnClient(login, clientName, shell, tokenSerialNumber)
     char * login;
     char * clientName;
     char * shell;
     char * tokenSerialNumber;

     CODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  RETVAL = Sd_EnableLoginOnClient(login, clientName, shell, 
					  sn, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

int
Sd_DelLoginFromClient(login, clientName)
     char * login;
     char * clientName;
     CODE:
	{
	  RETVAL = Sd_DelLoginFromClient(login, clientName, 
					 messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

SV *
Sd__ListClientActivations(tokenSerialNumber)
     char * tokenSerialNumber;

	PPCODE:
	{
	  char sn[13] = "000000000000";
	  if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	  strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  if (Sd_ListClientActivations(sn, messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
	    EXTEND(sp, 1);
	    PUSHs(&sv_undef);
	  } else {
	    EXTEND(sp, 1);
	    PUSHs(sv_2mortal(newSViv(1)));
	    while (strcmp(messageBuf, "Done") != 0) {
	      EXTEND(sp, 1);
	      PUSHs(sv_2mortal(newSVpv(messageBuf, 0)));
	      if (Sd_ListClientActivations(sn, messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
		strcpy(messageBuf, "Done");
	      }
	    }
	  }
	}

SV *
Sd__ListClientsForGroup(group)
     char *group;

	PPCODE:
	{
	  if (Sd_ListClientsForGroup(group, messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
	    EXTEND(sp, 1);
	    PUSHs(&sv_undef);
	  } else {
	    EXTEND(sp, 1);
	    PUSHs(sv_2mortal(newSViv(1)));
	    while (strcmp(messageBuf, "Done") != 0) {
	      EXTEND(sp, 1);
	      PUSHs(sv_2mortal(newSVpv(messageBuf, 0)));
	      if (Sd_ListClientsForGroup(group, messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
		strcpy(messageBuf, "Done");
	      }
	    }
	  }
	}

SV *
Sd__ListClients()
	PPCODE:
	{
	  if (Sd_ListClients(messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
	    EXTEND(sp, 1);
	    PUSHs(&sv_undef);
	  } else {
	    EXTEND(sp, 1);
	    PUSHs(sv_2mortal(newSViv(1)));
	    while (strcmp(messageBuf, "Done") != 0) {
	      EXTEND(sp, 1);
	      PUSHs(sv_2mortal(newSVpv(messageBuf, 0)));
	      if (Sd_ListClients(messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
		strcpy(messageBuf, "Done");
	      }
	    }
	  }
	}

SV *
Sd__ListSerialByLogin(login, count="1")
     char * login;
     char * count;

     CODE:
	{
	  if (Sd_ListSerialByLogin(login, count, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK) {
	    RETVAL = newSVpv(messageBuf, 0);
	  } else {
	    RETVAL = &sv_undef;
	  }
	}
	OUTPUT:
	RETVAL

SV *
Sd__ListHistory(days, tokenSerialNumber, filterOpt)
     char * days;
     char * tokenSerialNumber;
     char * filterOpt;

     PPCODE:
	{
	  char sn[13] = "000000000000";
	  if (strcmp(tokenSerialNumber, "help") == 0) {
	    strcpy(sn, "help");
	  } else {
	    if (strlen(tokenSerialNumber) > 12) tokenSerialNumber[12] = 0;
	    strcpy(sn+12-strlen(tokenSerialNumber), tokenSerialNumber);
	  } 
	  if (Sd_ListHistory(days, sn, "", filterOpt, 
			     messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
	    EXTEND(sp, 1);
	    PUSHs(&sv_undef);
	  } else {
	    EXTEND(sp, 1);
	    PUSHs(sv_2mortal(newSViv(1)));
	    while (strcmp(messageBuf, "Done") != 0) {
	      EXTEND(sp, 1);
	      PUSHs(sv_2mortal(newSVpv(messageBuf, 0)));
	      if (Sd_ListHistory(days, sn, "", filterOpt, 
				 messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
		strcpy(messageBuf, "Done");
	      }
	      if (strcmp(tokenSerialNumber, "help") == 0) {
		strcpy(messageBuf, "Done");
	      }
	    }
	  }
	}

SV *
Sd__MonitorHistory(outfile, dashC)
     char *outfile;
     char *dashC;

     PPCODE:
	{
	  if (Sd_MonitorHistory(outfile, dashC,
			     messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
	    EXTEND(sp, 1);
	    PUSHs(&sv_undef);
	  } else {
	    EXTEND(sp, 1);
	    PUSHs(sv_2mortal(newSViv(1)));
	    while (strcmp(messageBuf, "Done") != 0) {
	      EXTEND(sp, 1);
	      PUSHs(sv_2mortal(newSVpv(messageBuf, 0)));
	      if (Sd_MonitorHistory(outfile, dashC,
				    messageBuf, MAX_RESULT_MSG_SIZE) != API_OK) {
		strcpy(messageBuf, "Done");
	      }
	    }
	  }
	}

int
Sd_DumpHistory(month, day, year, daysHistory=0, filename="", dashT=0)
     int month;
     int day;
     int year;
     int daysHistory;
     char * filename;
     int dashT;

     CODE:
	{
	  RETVAL = Sd_DumpHistory(month, day, year, daysHistory, filename, 
				  dashT, 100, messageBuf, MAX_RESULT_MSG_SIZE) == API_OK;
	}
	OUTPUT:
	RETVAL

