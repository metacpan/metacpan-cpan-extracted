MODULE = Punk        PACKAGE = Punk::Model::DBIx::Loop

PROTOTYPES: DISABLE

# The async model backend, in C (punk_dbil.h). The same six-method contract
# as Punk::Model::DBI, but every method returns a Punk::Future: the statement
# runs on DBIx::Loop over the worker's own loop, reached through its C ABI,
# and one C continuation settles the future when the rows land.
# Punk::Model::DBIx::Loop.pm is the documentation.

SV *
new(class, ...)
        SV *class
    CODE:
        RETVAL = pdbi_build_self(aTHX_ class, &ST(0), items, PDL_CLS);
    OUTPUT:
        RETVAL

# The per-worker DBIx::Loop connection for this backend's dsn, built on the
# first statement and shared with every other backend on the same one.
SV *
db(self)
        SV *self
    CODE:
    {
        SV *v = pdbi_get(aTHX_ pdl_handle(aTHX_ self), "db");
        RETVAL = v ? newSVsv(v) : newSV(0);
    }
    OUTPUT:
        RETVAL

# The parent DBI handle (DBIx::Loop's own), for parity with the DBI
# backend's reach-through; statements do NOT run on it.
SV *
dbh(self)
        SV *self
    CODE:
    {
        SV *v = pdbi_get(aTHX_ pdl_handle(aTHX_ self), "dbh");
        RETVAL = v ? newSVsv(v) : newSV(0);
    }
    OUTPUT:
        RETVAL

# The DBIx::Loop loop adapter this connection runs on.
SV *
adapter(self)
        SV *self
    CODE:
    {
        SV *v = pdbi_get(aTHX_ pdl_handle(aTHX_ self), "adapter");
        RETVAL = v ? newSVsv(v) : newSV(0);
    }
    OUTPUT:
        RETVAL

IV
_returning(self)
        SV *self
    CODE:
    {
        SV *r = pdbi_get(aTHX_ pdl_handle(aTHX_ self), "returning");
        RETVAL = r ? SvIV(r) : 0;
    }
    OUTPUT:
        RETVAL

# Is DBIx::Loop's C ABI resolvable and new enough? The guard test's probe.
IV
_abi_ok(class)
        SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = punk_dbil_try(aTHX) ? 1 : 0;
    OUTPUT:
        RETVAL

# ---- the contract: everything returns a Punk::Future ------------------------

SV *
get(self, ...)
        SV *self
    CODE:
        RETVAL = pdl_get(aTHX_ self, &ST(0), items);
    OUTPUT:
        RETVAL

SV *
search(self, filter = &PL_sv_undef, opts = &PL_sv_undef)
        SV *self
        SV *filter
        SV *opts
    CODE:
        RETVAL = pdl_search(aTHX_ self, filter, opts);
    OUTPUT:
        RETVAL

SV *
all(self)
        SV *self
    CODE:
        RETVAL = pdl_search(aTHX_ self, &PL_sv_undef, &PL_sv_undef);
    OUTPUT:
        RETVAL

SV *
create(self, data)
        SV *self
        SV *data
    CODE:
        RETVAL = pdl_create(aTHX_ self, data);
    OUTPUT:
        RETVAL

SV *
update(self, data)
        SV *self
        SV *data
    CODE:
        RETVAL = pdl_update(aTHX_ self, data);
    OUTPUT:
        RETVAL

SV *
delete(self, ...)
        SV *self
    CODE:
        RETVAL = pdl_delete(aTHX_ self, &ST(0), items);
    OUTPUT:
        RETVAL

# future($dbil_future): bridge a raw DBIx::Loop::Future - from a custom
# query on $backend->db - into a Punk::Future carrying the same values.
SV *
future(self, f)
        SV *self
        SV *f
    CODE:
        RETVAL = pdl_wrap(aTHX_ self, f);
    OUTPUT:
        RETVAL

# await($future): resolve one of this backend's futures outside a worker, by
# pumping the adapter's own loop. Inside a worker $c->await already does this
# against the worker's loop. Returns the settled values (croaks on failure),
# exactly as Punk::Future->get does.
void
await(self, f)
        SV *self
        SV *f
    PPCODE:
    {
        pdl_await(aTHX_ self, f);
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(f);
        PUTBACK;
        call_method("get", GIMME_V);
        SPAGAIN;
        return;   /* the values get() left on the stack */
    }

# ---- the opaque keyset token (the SHARED codec - see punk_dbi.h) -----------

SV *
_encode_token(self, val)
        SV *self
        SV *val
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = pdbi_encode_token(aTHX_ val);
    OUTPUT:
        RETVAL

SV *
_decode_token(self, tok)
        SV *self
        SV *tok
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = pdbi_decode_token(aTHX_ tok, PDL_CLS);
    OUTPUT:
        RETVAL
