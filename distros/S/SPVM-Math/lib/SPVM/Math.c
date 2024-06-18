// Copyright (c) 2023 Yuki Kimoto
// MIT License

#include "spvm_native.h"

#include <math.h>
#include <fenv.h>
#include <complex.h>

static const char* MFILE = "SPVM/Math.c";

int32_t SPVM__Math__acos(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = acos(stack[0].dval);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__acosf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = acosf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__acosh(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = acosh(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__acoshf(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  float ret = acoshf(stack[0].fval);
  
  stack[0].fval = ret;
  
  return 0;
}

int32_t SPVM__Math__asin(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = asin(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__asinf(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  float ret = asinf(stack[0].fval);
  
  stack[0].fval = ret;
  
  return 0;
}

int32_t SPVM__Math__asinh(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = asinh(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__asinhf(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  float ret = asinhf(stack[0].fval);
  
  stack[0].fval = ret;
  
  return 0;
}

int32_t SPVM__Math__atan(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = atan(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__atan2(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = atan2(stack[0].dval, stack[1].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__atan2f(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = atan2f(stack[0].fval, stack[1].fval);
  
  stack[0].fval = ret;
  
  return 0;
}

int32_t SPVM__Math__atanf(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  float ret = atanf(stack[0].fval);
  
  stack[0].fval = ret;
  
  return 0;
}

int32_t SPVM__Math__atanh(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = atanh(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__atanhf(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  float ret = atanhf(stack[0].fval);
  
  stack[0].fval = ret;
  
  return 0;
}

int32_t SPVM__Math__cabs(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double z_ret = cabs(z);

  stack[0].dval = z_ret;

  return 0;
}

int32_t SPVM__Math__cabsf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float z_ret = cabsf(z);

  stack[0].fval = z_ret;

  return 0;
}

int32_t SPVM__Math__cacos(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = cacos(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__cacosf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = cacosf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__cacosh(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = cacosh(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__cacoshf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = cacoshf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__carg(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double z_ret = carg(z);

  stack[0].dval = creal(z_ret);

  return 0;
}

int32_t SPVM__Math__cargf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float z_ret = cargf(z);

  stack[0].fval = z_ret;

  return 0;
}

int32_t SPVM__Math__casin(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = casin(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__casinf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = casinf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__casinh(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = casinh(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__casinhf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = casinhf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__catan(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = catan(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__catanf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = catanf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__catanh(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = catanh(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__catanhf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = catanhf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__cbrt(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = cbrt(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__cbrtf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = cbrtf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__ccos(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = ccos(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__ccosf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = ccosf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__ccosh(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = ccosh(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__ccoshf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = ccoshf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__ceil(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = ceil(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__ceilf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = ceilf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__cexp(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = cexp(z);
  
  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__cexpf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = cexpf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__clog(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = clog(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__clogf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = clogf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__conj(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = conj(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__conjf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = conjf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}
int32_t SPVM__Math__copysign(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = copysign(stack[0].dval, stack[1].dval);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__copysignf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = copysignf(stack[0].fval, stack[1].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__cos(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = cos(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__cosf(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  float ret = cosf(stack[0].fval);
  
  stack[0].fval = ret;
  
  return 0;
}

int32_t SPVM__Math__cosh(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = cosh(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__coshf(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  float ret = coshf(stack[0].fval);
  
  stack[0].fval = ret;
  
  return 0;
}

int32_t SPVM__Math__cpow(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double x_pow = stack[2].dval;
  double y_pow = stack[3].dval;

  double complex z = re + im * _Complex_I;

  double complex z_pow = x_pow + y_pow * _Complex_I;

  double complex z_ret = cpow(z, z_pow);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__cpowf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float x_pow = stack[2].fval;
  float y_pow = stack[3].fval;

  float complex z = re + im * _Complex_I;

  float complex z_pow = x_pow + y_pow * _Complex_I;

  float complex z_ret = cpowf(z, z_pow);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__csin(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = csin(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__csinf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = csinf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__csinh(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = csinh(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__csinhf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = csinhf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__csqrt(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = csqrt(z);
  
  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__csqrtf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = csqrtf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__ctan(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;

  double complex z_ret = ctan(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__ctanf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  float complex z_ret = ctanf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__ctanh(SPVM_ENV* env, SPVM_VALUE* stack) {

  double re = stack[0].dval;
  double im = stack[1].dval;

  double complex z = re + im * _Complex_I;
  
  // In some mac OS, ctanh can't right ret, so I calcurate from definition
  double complex z_ret = csinh(z) / ccosh(z);

  stack[0].dval = creal(z_ret);
  stack[1].dval = cimag(z_ret);

  return 0;
}

int32_t SPVM__Math__ctanhf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float re = stack[0].fval;
  float im = stack[1].fval;

  float complex z = re + im * _Complex_I;

  // In some mac OS, ctanh can't right ret, so I calcurate from definition
  float complex z_ret = csinhf(z) / ccoshf(z);

  stack[0].fval = crealf(z_ret);
  stack[1].fval = cimagf(z_ret);

  return 0;
}

int32_t SPVM__Math__erf(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = erf(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__erfc(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = erfc(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__erfcf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = erfcf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__erff(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = erff(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__exp(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = exp(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__exp2(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = exp2(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__exp2f(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = exp2f(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__expf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = expf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__expm1(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = expm1(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__expm1f(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = expm1f(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__fabs(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = fabs(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__fabsf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = fabsf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__fdim(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = fdim(stack[0].dval, stack[1].dval);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__fdimf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = fdimf(stack[0].fval, stack[1].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__FE_DOWNWARD(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  stack[0].ival = FE_DOWNWARD;

  return 0;
}

int32_t SPVM__Math__FE_TONEAREST(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  stack[0].ival = FE_TONEAREST;

  return 0;
}

int32_t SPVM__Math__FE_TOWARDZERO(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  stack[0].ival = FE_TOWARDZERO;

  return 0;
}

int32_t SPVM__Math__FE_UPWARD(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  stack[0].ival = FE_UPWARD;

  return 0;
}

int32_t SPVM__Math__fesetround(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  int32_t ival = stack[0].ival;

  stack[0].ival = fesetround(ival);

  return 0;
}

int32_t SPVM__Math__floor(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = floor(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__floorf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = floorf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__fma(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = fma(stack[0].dval, stack[1].dval, stack[2].dval);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__fmaf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = fmaf(stack[0].fval, stack[1].fval, stack[2].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__fmax(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = fmax(stack[0].dval, stack[1].dval);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__fmaxf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = fmaxf(stack[0].fval, stack[1].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__fmin(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = fmin(stack[0].dval, stack[1].dval);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__fminf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = fminf(stack[0].fval, stack[1].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__fmod(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = fmod(stack[0].dval, stack[1].dval);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__fmodf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = fmodf(stack[0].fval, stack[1].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__FP_ILOGB0(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  stack[0].ival = FP_ILOGB0;

  return 0;
}

int32_t SPVM__Math__FP_ILOGBNAN(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  stack[0].ival = FP_ILOGBNAN;

  return 0;
}

int32_t SPVM__Math__FP_INFINITE(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  stack[0].ival = FP_INFINITE;

  return 0;
}

int32_t SPVM__Math__FP_NAN(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  stack[0].ival = FP_NAN;

  return 0;
}

int32_t SPVM__Math__FP_ZERO(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  stack[0].ival = FP_ZERO;

  return 0;
}

int32_t SPVM__Math__fpclassify(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;
  
  double dval = stack[0].dval;
  
  stack[0].ival = fpclassify(dval);
  
  return 0;
}

int32_t SPVM__Math__fpclassifyf(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  float fval = stack[0].fval;

  stack[0].ival = fpclassify(fval);

  return 0;
}

int32_t SPVM__Math__frexp(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = frexp(stack[0].dval, stack[1].iref);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__frexpf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = frexpf(stack[0].fval, stack[1].iref);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__HUGE_VAL(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;
  
  stack[0].dval = (double)HUGE_VAL;
  
  return 0;
}

int32_t SPVM__Math__HUGE_VALF(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;
  
  stack[0].fval = (float)HUGE_VALF;
  
  return 0;
}

int32_t SPVM__Math__hypot(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = hypot(stack[0].dval, stack[1].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__hypotf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = hypotf(stack[0].fval, stack[1].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__ilogb(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = ilogb(stack[0].dval);

  stack[0].ival = ret;

  return 0;
}

int32_t SPVM__Math__ilogbf(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = ilogbf(stack[0].fval);

  stack[0].ival = ret;

  return 0;
}

int32_t SPVM__Math__INFINITY(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  stack[0].dval = (double)INFINITY;

  return 0;
}

int32_t SPVM__Math__INFINITYF(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  stack[0].fval = (float)INFINITY;

  return 0;
}

int32_t SPVM__Math__isfinite(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;

  double dval = stack[0].dval;

  stack[0].ival = isfinite(dval);

  return 0;
}

int32_t SPVM__Math__isfinitef(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;
  
  float fval = stack[0].fval;
  
  stack[0].ival = isfinite(fval);
  
  return 0;
}

int32_t SPVM__Math__isgreater(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = isgreater(stack[0].dval, stack[1].dval);

  stack[0].ival = ret;

  return 0;
}

int32_t SPVM__Math__isgreaterequal(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = isgreaterequal(stack[0].dval, stack[1].dval);

  stack[0].ival = ret;

  return 0;
}

int32_t SPVM__Math__isgreaterequalf(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = isgreaterequal(stack[0].fval, stack[1].fval);

  stack[0].ival = ret;

  return 0;
}

int32_t SPVM__Math__isgreaterf(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = isgreater(stack[0].fval, stack[1].fval);

  stack[0].ival = ret;

  return 0;
}

int32_t SPVM__Math__isinf(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;
  
  double dval = stack[0].dval;
  
  stack[0].ival = isinf(dval);
  
  return 0;
}

int32_t SPVM__Math__isinff(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;
  
  float fval = stack[0].fval;
  
  stack[0].ival = isinf(fval);
  
  return 0;
}

int32_t SPVM__Math__isless(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = isless(stack[0].dval, stack[1].dval);

  stack[0].ival = ret;

  return 0;
}

int32_t SPVM__Math__islessequal(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = islessequal(stack[0].dval, stack[1].dval);

  stack[0].ival = ret;

  return 0;
}

int32_t SPVM__Math__islessequalf(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = islessequal(stack[0].fval, stack[1].fval);

  stack[0].ival = ret;

  return 0;
}

int32_t SPVM__Math__islessf(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = isless(stack[0].fval, stack[1].fval);

  stack[0].ival = ret;

  return 0;
}

int32_t SPVM__Math__islessgreater(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = islessgreater(stack[0].dval, stack[1].dval);

  stack[0].ival = ret;

  return 0;
}

int32_t SPVM__Math__islessgreaterf(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = islessgreater(stack[0].fval, stack[1].fval);

  stack[0].ival = ret;

  return 0;
}

int32_t SPVM__Math__isnan(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;
  
  double dval = stack[0].dval;
  
  stack[0].ival = isnan(dval);
  
  return 0;
}

int32_t SPVM__Math__isnanf(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;
  
  float fval = stack[0].fval;
  
  stack[0].ival = isnan(fval);
  
  return 0;
}

int32_t SPVM__Math__isunordered(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = isunordered(stack[0].dval, stack[1].dval);

  stack[0].ival = ret;

  return 0;
}

int32_t SPVM__Math__isunorderedf(SPVM_ENV* env, SPVM_VALUE* stack) {

  int32_t ret = isunordered(stack[0].fval, stack[1].fval);

  stack[0].ival = ret;

  return 0;
}




int32_t SPVM__Math__ldexp(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = ldexp(stack[0].dval, stack[1].ival);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__ldexpf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = ldexpf(stack[0].fval, stack[1].ival);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__lgamma(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = lgamma(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__lgammaf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = lgammaf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__log(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = log(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__log10(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = log10(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__log10f(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = log10f(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__log1p(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = log1p(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__log1pf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = log1pf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__log2(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = log2(stack[0].dval);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__log2f(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = log2f(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__logb(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = logb(stack[0].dval);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__logbf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = logbf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__logf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = logf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__lround(SPVM_ENV* env, SPVM_VALUE* stack) {

  int64_t ret = llround(stack[0].dval);

  stack[0].lval = ret;

  return 0;
}

int32_t SPVM__Math__lroundf(SPVM_ENV* env, SPVM_VALUE* stack) {

  int64_t ret = llroundf(stack[0].fval);

  stack[0].lval = ret;

  return 0;
}

int32_t SPVM__Math__modf(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = modf(stack[0].dval, stack[1].dref);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__modff(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = modff(stack[0].fval, stack[1].fref);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__nan(SPVM_ENV* env, SPVM_VALUE* stack) {

  void* string = stack[0].oval;
  if (string == NULL) {
    return env->die(env, stack, "String must be defined", __func__, MFILE, __LINE__);
  }

  const char* tagp = env->get_chars(env, stack, string);
  double ret = nan(tagp);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__NAN(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;
  
  stack[0].dval = (double)NAN;
  
  return 0;
}

int32_t SPVM__Math__nanf(SPVM_ENV* env, SPVM_VALUE* stack) {

  void* string = stack[0].oval;
  if (string == NULL) {
    return env->die(env, stack, "String must be defined", __func__, MFILE, __LINE__);
  }

  const char* tagp = env->get_chars(env, stack, string);
  float ret = nanf(tagp);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__NANF(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;
  
  stack[0].fval = (float)NAN;
  
  return 0;
}

int32_t SPVM__Math__nearbyint(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = nearbyint(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__nearbyintf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = nearbyintf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__nextafter(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = nextafter(stack[0].dval, stack[1].dval);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__nextafterf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = nextafterf(stack[0].fval, stack[1].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__nexttoward(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = nexttoward(stack[0].dval, stack[1].dval);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__nexttowardf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = nexttowardf(stack[0].fval, stack[1].dval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__pow(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = pow(stack[0].dval, stack[1].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__powf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = powf(stack[0].fval, stack[1].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__remainder(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = remainder(stack[0].dval, stack[1].dval);

  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__remainderf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = remainderf(stack[0].fval, stack[1].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__remquo(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = remquo(stack[0].dval, stack[1].dval, stack[2].iref);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__remquof(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = remquof(stack[0].fval, stack[1].fval, stack[2].iref);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__round(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = round(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__roundf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = roundf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__scalbln(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = scalbln(stack[0].dval, stack[1].lval);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__scalblnf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = scalblnf(stack[0].fval, stack[1].lval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__scalbn(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = scalbn(stack[0].dval, stack[1].ival);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__scalbnf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = scalbnf(stack[0].fval, stack[1].ival);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__signbit(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;
  
  double dval = stack[0].dval;
  
  stack[0].ival = signbit(dval);
  
  return 0;
}

int32_t SPVM__Math__signbitf(SPVM_ENV* env, SPVM_VALUE* stack) {
  (void)stack;
  
  float fval = stack[0].fval;
  
  stack[0].ival = signbit(fval);
  
  return 0;
}

int32_t SPVM__Math__sin(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = sin(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__sinf(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  float ret = sinf(stack[0].fval);
  
  stack[0].fval = ret;
  
  return 0;
}

int32_t SPVM__Math__sinh(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = sinh(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__sinhf(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  float ret = sinhf(stack[0].fval);
  
  stack[0].fval = ret;
  
  return 0;
}

int32_t SPVM__Math__sqrt(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = sqrt(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__sqrtf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = sqrtf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__tan(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = tan(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__tanf(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  float ret = tanf(stack[0].fval);
  
  stack[0].fval = ret;
  
  return 0;
}

int32_t SPVM__Math__tanh(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = tanh(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__tanhf(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  float ret = tanhf(stack[0].fval);
  
  stack[0].fval = ret;
  
  return 0;
}

int32_t SPVM__Math__tgamma(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  double ret = tgamma(stack[0].dval);
  
  stack[0].dval = ret;
  
  return 0;
}

int32_t SPVM__Math__tgammaf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = tgammaf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}

int32_t SPVM__Math__trunc(SPVM_ENV* env, SPVM_VALUE* stack) {

  double ret = trunc(stack[0].dval);

  stack[0].dval = ret;

  return 0;
}

int32_t SPVM__Math__truncf(SPVM_ENV* env, SPVM_VALUE* stack) {

  float ret = truncf(stack[0].fval);

  stack[0].fval = ret;

  return 0;
}
