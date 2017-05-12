#include "ibam.hpp"

extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "proto.h"

#include "ppport.h"
}

SV*
new_ibam_object(ibam* i, char* CLASS)
{
	SV* obj;
	SV* sv;
	HV* stash;
	obj = (SV*)newHV();
	sv_magic(obj, 0, PERL_MAGIC_ext, (const char*)i, 0);
	sv = newRV_inc(obj);
	stash = gv_stashpv(CLASS, 1);
	sv_bless(sv, stash);

	return sv;
}

ibam*
get_ibam_object(SV* sv)
{
	MAGIC *mg;

	if (!sv || !SvOK(sv) || !SvROK(sv) || !(mg = mg_find(SvRV(sv), PERL_MAGIC_ext)))
		return NULL;
	return (ibam*)mg->mg_ptr;
}

bool
get_do_second_correction(SV* sv)
{
	if (!sv || !SvOK(sv) || !SvROK(sv))
		return FALSE;
	return SvTRUE(*hv_fetch((HV*)SvRV(sv), "do_second_correction", 20, 0));
}

MODULE = Sys::Ibam		PACKAGE = Sys::Ibam		

PROTOTYPES: ENABLE

void
ibam::new(do_second_correction=TRUE)
		int do_second_correction
	PPCODE:
		ST(0) = new_ibam_object(new ibam(), CLASS);
		HV* hv = (HV*)SvRV(ST(0));
		hv_store(hv, "do_second_correction", 20, newSViv(do_second_correction), 0);
		sv_2mortal(ST(0));
		XSRETURN(1);

void
ibam::DESTROY()

void
ibam::import_old_data()
	CODE:
		THIS->import();

void
ibam::update_statistics()

void
ibam::ignore_statistics()

void
ibam::save()

const char*
ibam::profile_filename(n, type)
		int n
		char* type
	PREINIT:
		int profile_type;
		string filename;
	CODE:
		if (strcmp(type, "full") == 0)
			profile_type = 0;
		else if (strcmp(type, "battery") == 0)
			profile_type = 1;
		else if (strcmp(type, "charge") == 0)
			profile_type = 2;
		else if (strcmp(type, "") == 0)
			profile_type = 3;
		else
			XSRETURN_UNDEF;

		filename = THIS->profile_filename(n, profile_type);
		RETVAL = filename.c_str();
	OUTPUT:
		RETVAL

int
ibam::current_profile_number()

char*
ibam::current_profile_type()
	PREINIT:
		char* types[4] = {"full", "battery", "charge", ""};
	CODE:
		RETVAL = types[(THIS->current_profile_type() & 3)];
	OUTPUT:
		RETVAL

void
ibam::set_profile_logging(n)
		SV* n
	CODE:
		THIS->set_profile_logging(SvTRUE(n) ? 1 : 0);

int
ibam::profile_logging_setting()

int
ibam::seconds_left_battery_bios()

int
ibam::seconds_left_battery()
	CODE:
		RETVAL = THIS->seconds_left_battery();
		if (get_do_second_correction(ST(0)))
			RETVAL += THIS->seconds_battery_correction();
	OUTPUT:
		RETVAL

int
ibam::seconds_left_battery_adaptive()
	CODE:
		RETVAL = THIS->seconds_left_battery_adaptive();
		if (get_do_second_correction(ST(0)))
			RETVAL += THIS->seconds_battery_correction();
	OUTPUT:
		RETVAL

int
ibam::percent_battery_bios()

int
ibam::percent_battery()

int
ibam::seconds_left_charge()
	CODE:
		RETVAL = THIS->seconds_left_charge();
		if (get_do_second_correction(ST(0)))
			RETVAL += THIS->seconds_charge_correction();
	OUTPUT:
		RETVAL

int
ibam::seconds_left_charge_adaptive()
	CODE:
		RETVAL = THIS->seconds_left_charge_adaptive();
		if (get_do_second_correction(ST(0)))
			RETVAL += THIS->seconds_charge_correction();
	OUTPUT:
		RETVAL

int
ibam::percent_charge()

int
ibam::seconds_battery_total()

int
ibam::seconds_battery_total_adaptive()

int
ibam::seconds_charge_total()

int
ibam::seconds_charge_total_adaptive()

int
ibam::seconds_battery_correction()

int
ibam::seconds_charge_correction()

int
ibam::on_battery()
	CODE:
		RETVAL = THIS->onBattery();
	OUTPUT:
		RETVAL

int
ibam::charging()

int
ibam::valid()

void
ibam::update()
