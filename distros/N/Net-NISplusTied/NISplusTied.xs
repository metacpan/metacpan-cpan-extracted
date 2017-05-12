/*
**      Perl Extension for the
**
**      tie() interface for NIS+ tables.
**
**      This module by Ilya Ketris (ilya@gde.to)
**
**	Net::NISplusTied.xs
**
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}



/*
double
constant(name,arg)
	char *		name
	int		arg
*/



#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <rpcsvc/nis.h>


# /*#############################################################*/    

char* strndup (char* str, int n) { /* stolen from Rik Harris */

	char* newstr, *i;

	if (! New (0, newstr, n, char))
		croak ("+++ ""New"" failed in strndup");

	i = newstr;

	if (newstr)
		while (n--) {
			*i++ = *str++;
		}
 
	return newstr;
}

# /*#############################################################*/
nis_object* new_entry (nis_object* Table) {

	nis_object *NOb;

	NOb = nis_clone_object (Table, NULL);
	if (! NOb)
		croak ("+++ ""nis_clone_object"" failed in new_entry");
 
	NOb -> zo_data.zo_type = ENTRY_OBJ;
	NOb -> EN_data.en_cols.en_cols_len = Table -> TA_data.ta_cols.ta_cols_len;
	NOb -> zo_data.objdata_u.en_data.en_type = Table -> TA_data.ta_type;

	if (! New (0, NOb -> EN_data.en_cols.en_cols_val,
		Table -> TA_data.ta_maxcol, entry_col))
			croak ("+++ ""New"" failed in new_entry");

	return NOb;
}

# /*#############################################################*/    

int hash_to_entry (nis_object *table, nis_object* entry, SV* hash, int fill) {

	int i; char* colname; SV** iSV;

 	if (fill) {
		entry -> zo_name = "";
		entry -> zo_domain = "";
	}
 
        for (i = 0; i < table -> TA_data.ta_maxcol; i++) {

                colname = table -> TA_data.ta_cols.ta_cols_val [i] . tc_name;

		iSV = hv_fetch ((HV*) SvRV (hash), colname, strlen (colname), 0);

		if (iSV && SvOK (*iSV)) {
			int length;
			char* c = SvPV (*iSV, length);
			ENTRY_VAL (entry, i) = strndup (c, length + 1);
			ENTRY_LEN (entry, i) = length + 1;
			ENTRY_VAL (entry, i) [length] = 0;

		} else if (fill) {
			ENTRY_VAL (entry, i) = "";
			ENTRY_LEN (entry, i) = 0;
		}
		entry -> EN_data.en_cols.en_cols_val [i].ec_flags
				= EN_MODIFIED;
	}

}
# /*#############################################################*/

MODULE = Net::NISplusTied		PACKAGE = Net::NISplusTied		

# /***************************************************************/

void
nismatch (query, table)
	char* query
	char* table
	PPCODE:

        nis_result *en, *tb;
        nis_object *noTable, *noEntry;
	int i, j;
	HV *hash; AV *array;

	en = nis_list (query, EXPAND_NAME, 0, 0);
	tb = nis_lookup (table, EXPAND_NAME);

	if (! en) croak ("+++ ""nis_list"" failed in nismatch (en)");
	if (! tb) croak ("+++ ""nis_list"" failed in nismatch (tb)");

	noEntry = NIS_RES_OBJECT (en);
	noTable = NIS_RES_OBJECT (tb);

	if (NIS_RES_STATUS (en) != NIS_SUCCESS ||
		en->objects.objects_len == 0) {

			XSRETURN_NO;
	} else {

		array = newAV();	/* we return AV */
		for (j = 0; j < NIS_RES_NUMOBJ (en); j++) {

			hash = newHV();  /* AV of RVs to HVs */
			noEntry = NIS_RES_OBJECT (en) + j;

			for (i = 0; i < noTable -> TA_data.ta_maxcol; i++) {

				char* cpTbName = noTable  ->
					TA_data.ta_cols.ta_cols_val [i] . tc_name;

				if (! hv_store (hash, cpTbName, strlen (cpTbName),
					ENTRY_LEN (noEntry, i)
					? newSVpv (
						ENTRY_VAL (noEntry, i),
						ENTRY_LEN (noEntry, i) - 1)
					: newSVpv ("", 0),
				0))
					croak ("+++ ""hv_store"" failed in nismatch");
 
			}
			av_push (array, newRV ((SV*) hash));

		}
		XPUSHs (sv_2mortal (newRV ((SV*) array)));

	}

	nis_freeresult (en);
	nis_freeresult (tb);

# /*****************************************************************/

void
nismodify (query, table, values)
	char* query
	char* table
	SV* values
	PPCODE:

	nis_result *en, *tb, *rc;
	nis_object *noTable, *noEntry;
	SV *i, *j;  SV** iSV;

	en = nis_list (query, EXPAND_NAME, 0, 0);
	tb = nis_lookup (table, EXPAND_NAME);

	if (! en) croak ("+++ nis_list returned NULL in en");
	if (! tb) croak ("+++ nis_list returned NULL in tb");

	noEntry = NIS_RES_OBJECT (en);
	noTable = NIS_RES_OBJECT (tb);

	if (NIS_RES_STATUS (en) == NIS_NOTFOUND &&
		NIS_RES_NUMOBJ (en) == 0 ||
		NIS_RES_NUMOBJ (en) > 1) { /* multiple or not found, will add */

		nis_object* noNew = new_entry (noTable);
		hash_to_entry (noTable, noNew, values, 1);

		rc = nis_add_entry (table, noNew, ADD_OVERWRITE);

		nis_freeresult (rc);

	} else if (NIS_RES_STATUS (en) != NIS_SUCCESS ||
			NIS_RES_STATUS (tb) != NIS_SUCCESS) {

		XSRETURN_UNDEF;

	} else { /* success, will replace */

		hash_to_entry (noTable, noEntry, values, 0);
		rc = nis_modify_entry (query, noEntry, EXPAND_NAME || MOD_SAMEOBJ);

		XPUSHs (sv_2mortal (newSViv (rc -> status)));
		nis_freeresult (rc);

	}

	nis_freeresult (tb);
	nis_freeresult (en);

# /*****************************************************************/

void
nisremove (q)
	char* q
	PPCODE:

	nis_result *rc;

	rc = nis_remove_entry (q, NULL, REM_MULTIPLE || EXPAND_NAME);

	if (! rc)
		croak ("+++ nis_remove returned NULL in rc");

	XPUSHs (sv_2mortal (newSVpv (nis_sperrno (rc -> status), 0)));

	nis_freeresult (rc);

# /*****************************************************************/
