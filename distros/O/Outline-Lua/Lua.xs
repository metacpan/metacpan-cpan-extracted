#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct lua_Object {
  lua_State * L;
  AV        * dec_these_refs;
} lua_Object;
typedef lua_Object * Outline__Lua;

SV* perl_from_lua_val(lua_Object *, int, int);
SV* table_to_ref(lua_Object *, int, int);
void lua_push_perl_var(lua_Object *, SV *);
void lua_push_perl_ref(lua_Object *, SV *);
void lua_push_perl_hash(lua_Object *, HV *);
void lua_push_perl_array(lua_Object *, AV *);

int strtoflags(const char const *);

SV* perl_from_lua_val(lua_Object *self, int i, int wantarray) {
  lua_State *L  = self->L;
  SV *retval;

  switch (lua_type(L, i)) {
    case LUA_TNIL:
      return &PL_sv_undef;

    case LUA_TBOOLEAN:
      return lua_toboolean(L, i) ? get_sv("Outline::Lua::TRUE", FALSE) : get_sv("Outline::Lua::FALSE", FALSE);

    case LUA_TNUMBER:
      return newSVnv(lua_tonumber(L, i));

    case LUA_TSTRING:
      return newSVpvn(lua_tostring(L, i), lua_strlen(L, i));

    case LUA_TTABLE:
      retval = table_to_ref(self, i, wantarray);
      return retval;
    /* TODO
    case LUA_TFUNCTION:
      *dopop = 0;
      return func_ref(L);
    */
    default:
	    abort();
  }
}

SV* table_to_ref(lua_Object *self, int i, int wantarray) {
  /* Table is stored at location i in the stack. */
  lua_State *L = self->L;
  int count, x = 0;
  SV *retval;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  lua_pushnil(L);

  XPUSHs(sv_2mortal( (SV*)( wantarray ? &PL_sv_yes : &PL_sv_no ) ));

  while (lua_next(L, i) != 0) {
    /* push each key-val pair onto the perl stack, then
     * call the function to make it either an array or hash
     * ref
     */
    XPUSHs(sv_2mortal(perl_from_lua_val(self, -2, wantarray)));
    XPUSHs(sv_2mortal(perl_from_lua_val(self, -1, wantarray)));
    lua_pop(L, 1);
  }
  PUTBACK;

  count =  /* better damn well return just one */
    call_pv("Outline::Lua::_table_to_ref_p", G_SCALAR);

  SPAGAIN;

  if (count != 1)
    croak("Outline::Lua::_table_to_ref_p did not return exactly 1 var");

  retval = POPs;

  /* I have to increment this or it's GC'd by the time it reaches the caller.
   * I don't know why, but I never have to decrement it again. Presumably once
   * Perl has a hold of it its refcount is still 1, and that's Perl's. */
  SvREFCNT_inc(retval);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return retval;
}

void lua_push_perl_var(lua_Object *self, SV *var) {
  lua_State *L = self->L;

  /* Now we make a Best Guess at what sort of var it is.
   * We start with the 'unique' values - undef, true and false
   */
  if (!var || var == &PL_sv_undef || !SvOK(var)) {
    lua_pushnil(L);
    return;
  }


  /* Now we know it's none of those we can do normal magic. */
  switch (SvTYPE(var)) {
    case SVt_RV:
      lua_push_perl_ref(self, SvRV(var));
      return;
    case SVt_IV: 
      lua_pushnumber(L, (lua_Number)SvIV(var));
      return;
    case SVt_NV:
      lua_pushnumber(L, (lua_Number)SvNV(var));
      return;
    case SVt_PV: case SVt_PVIV: 
    case SVt_PVNV: case SVt_PVMG:
    {
      STRLEN len;
      char *cval = SvPV(var, len);
      lua_pushlstring(L, cval, len);
      return;
    }
  }
}

void lua_push_perl_array(lua_Object *self, AV *arr) {
  lua_State *L = self->L;
  register int i;
  lua_newtable(L);

  /* Note that the indices in Lua will be 1 greater than in Perl. */
  for (i = 0; i <= av_len(arr); i++) {
    SV **ptr = av_fetch(arr, i, FALSE);
    lua_pushnumber(L, (lua_Number)i+1);
    if (ptr) 
	    lua_push_perl_var(self, *ptr);
    else
	    lua_pushnil(L);
    lua_settable(L, -3);
  }
}

void lua_push_perl_hash(lua_Object *self, HV *hash) {
  lua_State *L = self->L;
  register HE* he;
  
  lua_newtable(L);
  hv_iterinit(hash);

  while (he = hv_iternext(hash)) {
    I32 len;
    char *key;
    key = hv_iterkey(he, &len);
    lua_pushlstring(L, key, len);
    lua_push_perl_var(self, hv_iterval(hash, he));
    lua_settable(L, -3);
  }
}

void lua_push_perl_ref (lua_Object *self, SV *val) {
  lua_State *L = self->L;

  SV *t = get_sv("Outline::Lua::TRUE", FALSE);
  SV *f = get_sv("Outline::Lua::FALSE", FALSE);

  SvREFCNT_inc(t); SvREFCNT_inc(f);

  if (val == SvRV(t)) {
    lua_pushboolean(L, 1);
    return;
  }

  if (val == SvRV(f)) {
    lua_pushboolean(L, 0);
    return;
  }

  switch (SvTYPE(val)) {
    case SVt_PVAV:
	    lua_push_perl_array(self, (AV*)val);
	    return;
    case SVt_PVHV:
	    lua_push_perl_hash(self, (HV*)val);
	    return;
      /* TODO
    case SVt_PVCV:
	    lua_push_perl_func(L, (CV*)val);
	    return;
    case SVt_PVGV:
	    push_io(L, IoIFP(sv_2io(val)));
	    return;
      */
    default:
	    croak("Attempt to pass unsupported reference type (%s) to Lua", sv_reftype(val, 0));
  }
}

int strtoflags(const char const *str) {
  int flags = 0;

  if(!strcmp(str, "void")) {
    flags = G_VOID;
  }
  else if(!strcmp(str, "list") || !strcmp(str, "array")) {
    flags = G_ARRAY;
  }
  else if(!strcmp(str, "scalar")) {
    flags = G_SCALAR;
  }

  return flags;
}

static int run_perl_func (lua_State *L) {
  lua_Object  *self         = (lua_Object*)lua_touserdata(L, lua_upvalueindex(1));
  SV          *func_params  = (SV*)lua_touserdata(L, lua_upvalueindex(2));
  const char  *func_name    = lua_tostring(L, lua_upvalueindex(3));
  HV          *fp_deref     = (HV*)SvRV(func_params);

  SV  **hashkey;
  int   flags, i, num_ret;
  char *context;

  dSP;

  /* Don't need to know 
   * a) the number of args we expect or
   * b) the number of return values
   * since Lua provisions for variable both, like Perl does.
   */
  hashkey   = hv_fetch(fp_deref, "context",  7, 0);
  if( hashkey )
    context = (char*)SvPV_nolen(*hashkey);
  else
    context = "array";

  hashkey   = NULL;

  flags = strtoflags(context);


  if (lua_gettop(L) == 0) 
    flags |= G_NOARGS;

  if (flags & G_VOID) 
    flags |= G_DISCARD;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  /* Convert the Lua stack into a Perl stack. 
   * The magic happens in perl_from_lua_val.
   */

  for (i = 1; i <= lua_gettop(L); ++i) {
    SV *pval = perl_from_lua_val(self, i, 0);
    XPUSHs(sv_2mortal(pval));
  }

  PUTBACK;
  num_ret = call_pv(func_name, flags);
  /* Prevent processing return values if we don't care about them */
  if (flags & G_DISCARD)
    num_ret = 0;

  SPAGAIN;

  /* If we use POPs, the values get pushed onto the Lua stack
   * in reverse order. This wasn't a problem with the other
   * way because that allowed us to go from 1 upwards.
   * I don't know why this way works and other suggested ways
   * don't (e.g. sp[i] with i=num_ret and --i)
   */
  for(i = 0; i < num_ret; ++i) {
    int offset = num_ret - i - 1;
    SV *val = *(sp - offset);
    SvREFCNT_inc(val);
    lua_push_perl_var(self, val);
  }
  
  sp -= num_ret;

  PUTBACK;

  FREETMPS;
  LEAVE;

	return num_ret;
}

MODULE = Outline::Lua		PACKAGE = Outline::Lua

PROTOTYPES: DISABLE

Outline::Lua
new()
  PREINIT:
    lua_Object *self;
    lua_State  *L;
    AV         *dec_these_refs;
  CODE:
    L = lua_open();
    luaopen_base(L);
    luaopen_table(L);
    luaopen_string(L);
    luaopen_math(L);
    dec_these_refs = newAV();

    self = (lua_Object*) malloc(sizeof(lua_Object));
    self->L = L;
    self->dec_these_refs = dec_these_refs;
    RETVAL      = self;
  OUTPUT:
    RETVAL

 # Code receives the struct representing self and
 # the hashref that is the function's parameters,
 # as well as the lua name for the function being
 # called.

int
_run(self, code)
  Outline::Lua self;
  SV *code;
  PREINIT:
    int error;
    STRLEN code_length;
    char *codestr;
    
  CODE:
    # TODO
    #
    # SV *error_func;
    # char *error_func_name;
    # error_func_name = SvPV(error_func_name);
    #
    # If a perl func has been registered with this name, use it as the error func.
    #
    # If this isn't real Lua code then you suck.
    codestr = SvPV(code, code_length);
    if(!code_length) croak("No code!");

    # Give it to Lua
    error = luaL_loadbuffer(self->L, codestr, code_length, "LUA_OBJECT_RUN") ||
            lua_pcall(self->L,0,0,0);
    # See what happens
    RETVAL = error;
    if( error )
      croak("Lua call failed: %s\n", lua_tostring(self->L, -1));

    # self->error = lua_tostring(self->L, -1);

  OUTPUT:
    RETVAL

void 
_add_func(self, lua_name, func_params_ref)
  Outline::Lua self;
  SV *lua_name;
  SV *func_params_ref;
  PREINIT:
    char *lua_name_str;
    char *perl_name_str;
    SV  **hashkey;
  CODE:
    # lol.
    hashkey       = hv_fetch((HV*)SvRV(func_params_ref), "perl_func",  9, 0);
    if( !hashkey )
      croak("Required key 'perl_func' not present in _add_func");

    perl_name_str = (char*)SvPV_nolen(*hashkey);
    lua_name_str  = SvPV_nolen(lua_name);

    # The C closure gets self in 1, the function params in 2,
    # and the perl name for this function at 3. The lua name of
    # the function is only used here for naming the function to
    # Lua, but can be retrieved from the func_params_ref.

    # in some situations, the HV on the end of the ref seems to be GC'd.
    # This line should force it to stick around until the closure is called.
    SvREFCNT_inc(func_params_ref);

    # I wonder whether simply doing this will invalidate the previous step 
    av_push(self->dec_these_refs, func_params_ref);

    lua_pushlightuserdata(self->L, self);
    lua_pushlightuserdata(self->L, func_params_ref);
    lua_pushstring(self->L, perl_name_str);
    lua_pushcclosure(self->L, &run_perl_func, 3);
    lua_setglobal(self->L, lua_name_str);

void 
_add_var(self, lua_name, perl_var)
  Outline::Lua self;
  SV *lua_name;
  SV *perl_var;
  PREINIT:
    char *lua_name_str;
  CODE:
    lua_name_str  = SvPV_nolen(lua_name);
    # sv_dump(perl_var);

    SvREFCNT_inc(perl_var);

    av_push(self->dec_these_refs, perl_var);

    lua_push_perl_var(self, perl_var);
    lua_setglobal(self->L, lua_name_str);

void
DESTROY(self)
  Outline::Lua self
  PREINIT:
    AV *arr;
  CODE:
    lua_close(self->L);
    arr = self->dec_these_refs;
    while(av_len(arr) >= 0) {
      SV *val;
      val = av_pop(arr);
      SvREFCNT_dec(val);
    }
    free(self);

