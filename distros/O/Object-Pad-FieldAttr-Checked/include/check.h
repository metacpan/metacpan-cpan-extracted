/* This file defines a common set of behaviours for use by
 *   Object::Pad::FieldAttr::Checked
 *   Signature::Attribute::Checked
 */

struct CheckData {
  SV *checkobj;
  CV *checkcv;
  SV *assertmess;
};

#define make_checkdata(checker)  Check_make_checkdata(aTHX_ checker)
struct CheckData *Check_make_checkdata(pTHX_ SV *checker);

#define make_assertop(data, argop)  Check_make_assertop(aTHX_ data, argop)
OP *Check_make_assertop(pTHX_ struct CheckData *data, OP *argop);

#define check_value(data, value)  Check_check_value(aTHX_ data, value)
bool Check_check_value(pTHX_ struct CheckData *data, SV *value);

#define assert_value(data, value)  Check_assert_value(aTHX_ data, value)
void Check_assert_value(pTHX_ struct CheckData *data, SV *value);
