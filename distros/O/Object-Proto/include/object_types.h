/*
 * object_types.h - Type registration API for external XS modules
 *
 * Include this header in your XS module to register optimized C-level
 * type checks that bypass Perl callback overhead entirely.
 *
 * Usage in your .xs file:
 *
 *   #include "object_types.h"
 *
 *   static bool check_positive_int(pTHX_ SV *val) {
 *       if (!SvIOK(val) && !looks_like_number(val)) return false;
 *       return SvIV(val) > 0;
 *   }
 *
 *   static bool check_email(pTHX_ SV *val) {
 *       if (SvROK(val)) return false;
 *       STRLEN len;
 *       const char *pv = SvPV(val, len);
 *       return memchr(pv, '@', len) != NULL;
 *   }
 *
 *   MODULE = MyTypes  PACKAGE = MyTypes
 *
 *   BOOT:
 *       object_register_type_xs(aTHX_ "PositiveInt", check_positive_int, NULL);
 *       object_register_type_xs(aTHX_ "Email", check_email, NULL);
 *
 * Then in Perl:
 *
 *   use MyTypes;  # Registers types in BOOT
 *   use object;
 *
 *   Object::Proto::define('User',
 *       'age:PositiveInt',    # Uses C function directly - ~5 cycles
 *       'email:Email',        # Uses C function directly - ~5 cycles
 *   );
 *
 * Performance comparison:
 *   - Built-in types (Str, Int):  ~0 cycles (inline switch)
 *   - Registered C functions:     ~5 cycles (function pointer call)
 *   - Perl callbacks:             ~100 cycles (call_sv overhead)
 */

#ifndef OBJECT_TYPES_H
#define OBJECT_TYPES_H

#include "EXTERN.h"
#include "perl.h"

/*
 * Type check function signature.
 * Return true if value passes the type check, false otherwise.
 * The function receives the value to check.
 */
typedef bool (*ObjectTypeCheckFunc)(pTHX_ SV *val);

/*
 * Type coercion function signature.
 * Return the coerced value (may be the same SV or a new mortal).
 * Return NULL if coercion is not possible.
 */
typedef SV* (*ObjectTypeCoerceFunc)(pTHX_ SV *val);

/*
 * Register a type with C-level check and coerce functions.
 * Call this from your BOOT section.
 *
 * Parameters:
 *   name   - Type name (e.g., "PositiveInt", "Email")
 *   check  - C function to validate values (required)
 *   coerce - C function to coerce values (optional, pass NULL if not needed)
 *
 * The type name can then be used in Object::Proto::define() slot specifications.
 * Type checks and coercions run as direct C function calls with no Perl overhead.
 */
extern void object_register_type_xs(pTHX_ const char *name,
                                    ObjectTypeCheckFunc check,
                                    ObjectTypeCoerceFunc coerce);

/*
 * Look up a registered type by name.
 * Returns NULL if type is not registered.
 * Useful for introspection or chaining type checks.
 */
typedef struct {
    char *name;
    ObjectTypeCheckFunc check;
    ObjectTypeCoerceFunc coerce;
    SV *perl_check;
    SV *perl_coerce;
} RegisteredType;

extern RegisteredType* object_get_registered_type(pTHX_ const char *name);

#endif /* OBJECT_TYPES_H */
