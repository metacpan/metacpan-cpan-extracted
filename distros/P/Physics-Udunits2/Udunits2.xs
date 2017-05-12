#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include "ppport.h"

#include "udunits2.h"

#define UDDEBUG 0 /* set to 0 for production */

typedef struct ut_system uu2System;
typedef union ut_unit uu2Unit;
typedef union cv_converter uu2Converter;

char errMsg[1000] = "";
int ut_perl_message_handler(const char* fmt, va_list args)
{
    int size;
    size = vsnprintf(errMsg, 999, fmt, args);
    if (size > 0 && UDDEBUG) fprintf(stderr, "%s\n", errMsg);
    return size;
}

MODULE = Physics::Udunits2		PACKAGE = Physics::Udunits2		

void
installCroakHandler()
  CODE:
    ut_set_error_message_handler(&ut_perl_message_handler);

uu2System *
new_system_from_path(path)
    char *path
  CODE:
    /* ignore warnings while reading xml-file */
    ut_set_error_message_handler(&ut_ignore);
    RETVAL = ut_read_xml(path);
    ut_set_error_message_handler(&ut_perl_message_handler);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2System *
new_system()
  CODE:
    /* ignore warnings while reading xml-file */
    ut_set_error_message_handler(&ut_ignore);
    RETVAL = ut_read_xml(NULL);
    ut_set_error_message_handler(&ut_perl_message_handler);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);    
  OUTPUT:
    RETVAL

# TIME HANDLING

double
encodeTime(year, month, day, hour, minute, second)
    int year
    int month
    int day
    int hour
    int minute
    double second
  CODE:
    RETVAL = ut_encode_time(year, month, day, hour, minute, second);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);    
  OUTPUT:
    RETVAL
    
double
encodeDate(year, month, day)
    int year
    int month
    int day
  CODE:
    RETVAL = ut_encode_date(year, month, day);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);    
  OUTPUT:
    RETVAL

double
encodeClock(hour, minute, second)
    int hour
    int minute
    double second
  CODE:
    RETVAL = ut_encode_clock(hour, minute, second);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);    
  OUTPUT:
    RETVAL

void
decodeTime_(time, year, month, day, hour, minute, second, resolution)
    double time
    int year
    int month
    int day
    int hour
    int minute
    double second
    double resolution
  CODE:
    ut_decode_time(time, &year, &month, &day, &hour, &minute, &second, &resolution);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    year
    month
    day
    hour
    minute
    second
    resolution
    


MODULE = Physics::Udunits2  PACKAGE = Physics::Udunits2::System  PREFIX = uu2_

void
uu2_DESTROY(system)
    uu2System *system
  CODE:
    if (UDDEBUG) fprintf(stderr, "Physics::Udunits2::System::DESTROY\n");
    ut_free_system(system);

uu2Unit *
uu2_getUnit(system, name)
    uu2System *system
    char *name
  CODE:
    ut_trim(name, UT_UTF8); 
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
    RETVAL = ut_parse(system, name, UT_UTF8);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL


uu2Unit *
uu2_getUnitByName(system, name)
    uu2System *system
    char *name
  CODE:
    RETVAL = ut_get_unit_by_name(system, name);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Unit *
uu2_getUnitBySymbol(system, name)
    uu2System *system
    char *name
  CODE:
    RETVAL = ut_get_unit_by_symbol(system, name);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Unit *
uu2_getDimensionlessUnit1(system)
    uu2System *system
  CODE:
    RETVAL = ut_get_dimensionless_unit_one(system);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Unit *
uu2_newBaseUnit(system)
    uu2System *system
  CODE:
    RETVAL = ut_new_base_unit(system);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Unit *
uu2_newDimensionlessUnit(system)
    uu2System *system
  CODE:
    RETVAL = ut_new_dimensionless_unit(system);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

void
uu2_addNamePrefix(system, name, val)
    uu2System *system
    const char * name
    double val
  CODE:
    ut_add_name_prefix(system, name, val);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);

void
uu2_addSymbolPrefix(system, symbol, val)
    uu2System *system
    const char * symbol
    double val
  CODE:
    ut_add_symbol_prefix(system, symbol, val);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);



MODULE = Physics::Udunits2  PACKAGE = Physics::Udunits2::Unit PREFIX = uu2_

int
uu2_isConvertibleTo(unit1, unit2)
    uu2Unit * unit1;
    uu2Unit * unit2
  CODE:
    RETVAL = ut_are_convertible(unit1, unit2);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

int
uu2_isDimensionless(unit)
    uu2Unit * unit;
  CODE:
    RETVAL = ut_is_dimensionless(unit);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Converter *
uu2_getConverterTo(unit1, unit2)
    uu2Unit * unit1
    uu2Unit * unit2
  CODE:
    RETVAL = ut_get_converter(unit1, unit2);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

void
uu2_DESTROY(unit)
    uu2Unit *unit
  CODE:
    if (UDDEBUG) fprintf(stderr, "Physics::Udunits2::Unit::DESTROY\n");
    ut_free(unit);    
    
# UNIT OPERATIONS
uu2Unit *
uu2_scale(unit, factor)
    uu2Unit * unit
    double factor
  CODE:
    RETVAL = ut_scale(factor, unit);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Unit *
uu2_offset(unit, offset)
    uu2Unit * unit
    double offset
  CODE:
    RETVAL = ut_offset(unit, offset);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Unit *
uu2_offsetByTime(unit, origin)
    uu2Unit * unit
    double origin
  CODE:
    RETVAL = ut_offset_by_time(unit, origin);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Unit *
uu2_invert(unit)
    uu2Unit * unit
  CODE:
    RETVAL = ut_invert(unit);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Unit *
uu2_raise(unit, power)
    uu2Unit * unit
    double power
  CODE:
    RETVAL = ut_raise(unit, power);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Unit *
uu2_root(unit, root)
    uu2Unit * unit
    int root
  CODE:
    RETVAL = ut_root(unit, root);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Unit *
uu2_log(unit, base)
    uu2Unit * unit
    double base
  CODE:
    RETVAL = ut_log(base, unit);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

const char*
uu2_getName(unit)
    uu2Unit * unit
  CODE:
    RETVAL = ut_get_name(unit, UT_UTF8);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

const char*
uu2_getSymbol(unit)
    uu2Unit * unit
  CODE:
    RETVAL = ut_get_symbol(unit, UT_UTF8);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2System*
uu2_getSystem(unit)
    uu2Unit * unit
  CODE:
    RETVAL = ut_get_system(unit);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Unit*
uu2_clone(unit)
    uu2Unit * unit
  CODE:
    RETVAL = ut_clone(unit);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Unit*
uu2_multiply(unit1, unit2)
    uu2Unit * unit1
    uu2Unit * unit2
  CODE:
    RETVAL = ut_multiply(unit1, unit2);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

uu2Unit*
uu2_divide(unit1, unit2)
    uu2Unit * unit1
    uu2Unit * unit2
  CODE:
    RETVAL = ut_divide(unit1, unit2);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

int
uu2_compare(unit1, unit2)
    uu2Unit * unit1
    uu2Unit * unit2
  CODE:
    RETVAL = ut_compare(unit1, unit2);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL

int
uu2_sameSystem(unit1, unit2)
    uu2Unit * unit1
    uu2Unit * unit2
  CODE:
    RETVAL = ut_same_system(unit1, unit2);
    if (ut_get_status() != UT_SUCCESS) croak(errMsg);
  OUTPUT:
    RETVAL


MODULE = Physics::Udunits2  PACKAGE = Physics::Udunits2::Converter PREFIX = uu2_

double
uu2_convert(converter, number)
    uu2Converter * converter
    double number
  CODE:
    RETVAL = cv_convert_double(converter, number);
  OUTPUT:
    RETVAL

void
uu2_DESTROY(converter)
    uu2Converter * converter
  CODE:
    if (UDDEBUG) fprintf(stderr, "Physics::Udunits2::Converter::DESTROY\n");
    cv_free(converter);

