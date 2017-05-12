#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "ppport.h"

#include "apiuser.h"
#include "api_errors.h"


void
_prefixed_login(char *login, char *pre_login)
{
	strcpy(pre_login, "-");
	strcat(pre_login, login);
}

void
_Sd_ListUsersByField(char *login, int field, int type, char *value)
{
	if (field < 0 || field > 10) field = 0;
	if (type < 0 || type > 11) type = 0;
	Sd_ListUsersByField(field, type, value,"", login, MAX_RESULT_MSG_SIZE);
}

void
_Sd_GetSerialByLogin(char *login, char *token)
{
	Sd_GetSerialByLogin(login, "", token, MAX_RESULT_MSG_SIZE);	
}

SV *
_Sd_ListUserInfoExt(char *pre_login)
{
	char inf[MAX_RESULT_MSG_SIZE] = {0};
	Sd_ListUserInfoExt(pre_login, 0, "|", inf, MAX_RESULT_MSG_SIZE);

	return newSVpv(inf, 0);
}

AV *
_Sd_ListExtensionsForUser(char *pre_login)
{
	char inf_ext[MAX_RESULT_MSG_SIZE] = {0};
	int i;
	AV* av_inf_ext;

	i = 0;
	av_inf_ext = newAV();
	do {
		Sd_ListExtensionsForUser(pre_login, "", inf_ext, MAX_RESULT_MSG_SIZE);
		if (strcmp(inf_ext,"Done") == 0) break;
		av_store(av_inf_ext, i++, newSVpv(inf_ext, 0));
	} while (1);
	
	return av_inf_ext;
}

AV *
_Sd_ListGroupMembership(char *pre_login)
{
	char group[MAX_RESULT_MSG_SIZE] = {0};
	int i;
	AV* av_group;

	i = 0;
	av_group = newAV();
	do {
		Sd_ListGroupMembership(pre_login, "", group, MAX_RESULT_MSG_SIZE);
		if (strcmp(group,"Done") == 0) break;
		av_store(av_group, i++, newSVpv(group, 0));
	} while (1);
	
	return av_group;
}

AV *
_Sd_ListGroups()
{
	char group[MAX_RESULT_MSG_SIZE] = {0};
	int i;
	AV* av_group;

	i = 0;
	av_group = newAV();
	do {
		Sd_ListGroups("", group, MAX_RESULT_MSG_SIZE);
		if (strcmp(group,"Done") == 0) break;
		av_store(av_group, i++, newSVpv(group, 0));
	} while (1);
	
	return av_group;
}

void
_Sd_ListUserByGroup(char *group, char *user)
{
	Sd_ListUserByGroup(group, "-s", "|", "", user, MAX_RESULT_MSG_SIZE);
}

SV *
_fetch_user_raw(char *login)
{
	char pre_login[MAX_RESULT_MSG_SIZE+1] = {0};
	char token[MAX_RESULT_MSG_SIZE] = {0};

	HV* stash;
	SV* object;
	HV* user_hash;

	SV* sv_inf;
	AV* av_inf_ext;
	AV* av_group;

/* The login has at least one token */
	_Sd_GetSerialByLogin(login, token);
	if (strcmp(token,"Done") == 0) return object;
			
/* Get further information */
	_prefixed_login(login, pre_login);
	sv_inf = _Sd_ListUserInfoExt(pre_login);
	av_inf_ext = _Sd_ListExtensionsForUser(pre_login);
	av_group = _Sd_ListGroupMembership(pre_login);
			
	user_hash = newHV();
	hv_store(user_hash, "login", 5, newSVpv(login,0),0);
	hv_store(user_hash, "token", 5, newSVpv(token,0),0);
	hv_store(user_hash, "inf", 3, sv_inf, 0);
	hv_store(user_hash, "inf_ext", 7, newRV_noinc((SV*)av_inf_ext),0);
	hv_store(user_hash, "group", 5, newRV_noinc((SV*)av_group),0);
		
	stash = gv_stashpv("RSA::Toolkit::User", GV_ADDWARN);
	object = newRV_inc((SV*)user_hash);
	sv_bless(object, stash);
		
	return object;
}



MODULE = RSA::Toolkit		PACKAGE = RSA::Toolkit		

void
connect(class)
	PREINIT:
		char msgBuf[MAX_RESULT_MSG_SIZE];
	PPCODE:
		Sd_ApiInit("","","1", msgBuf, MAX_RESULT_MSG_SIZE);

SV *
_fetch_users(class, field, type, value)
		int field
		int type
		char *value
	PREINIT:
		char login[MAX_RESULT_MSG_SIZE] = {0};
		char pre_login[MAX_RESULT_MSG_SIZE+1] = {0};
		char token[MAX_RESULT_MSG_SIZE] = {0};

		HV* stash;
		SV* object;
		HV* user_hash;

		SV* sv_inf;
		AV* av_inf_ext;
		AV* av_group;
	CODE:
		do
		{
			/* Get login list */
			_Sd_ListUsersByField(login, field,type,value);
			if (strcmp(login,"Done") == 0) exit(0);
printf("%s\n", login);

			/* The login has at least one token */
			_Sd_GetSerialByLogin(login, token);
			if (strcmp(token,"Done") == 0) continue;
			
			/* Get further information */
			_prefixed_login(login, pre_login);
			sv_inf = _Sd_ListUserInfoExt(pre_login);
			av_inf_ext = _Sd_ListExtensionsForUser(pre_login);
			av_group = _Sd_ListGroupMembership(pre_login);
			
			if (strcmp(token,"Done") != 0) break;
		} while (1);	

		user_hash = newHV();
		hv_store(user_hash, "login", 5, newSVpv(login,0),0);
		hv_store(user_hash, "token", 5, newSVpv(token,0),0);
		hv_store(user_hash, "inf", 3, sv_inf, 0);
		hv_store(user_hash, "inf_ext", 7, newRV_noinc((SV*)av_inf_ext),0);
		hv_store(user_hash, "group", 5, newRV_noinc((SV*)av_group),0);
		
		stash = gv_stashpv("RSA::Toolkit::User", GV_ADDWARN);
		object = newRV_inc((SV*)user_hash);
		sv_bless(object, stash);
		
		RETVAL = object;
	OUTPUT:
		RETVAL

SV *
_fetch_groups(class)
	CODE:
		RETVAL = newRV_noinc((SV*)_Sd_ListGroups());
	OUTPUT:
		RETVAL

SV *
_fetch_users_by_group(class, group)
		char *group
	PREINIT:
		char user[MAX_RESULT_MSG_SIZE] = {0};
	CODE:
		_Sd_ListUserByGroup(group, user);
		RETVAL = newSVpv(user, 0);
	OUTPUT:
		RETVAL

SV *
_fetch_user(class, login)
		char *login
	CODE:
		RETVAL = _fetch_user_raw(login);
	OUTPUT:
		RETVAL

