MODULE = Punk        PACKAGE = Punk::Txn

PROTOTYPES: DISABLE

# The transaction object the $c->txn block receives (punk_txn.h).
# lib/Punk/Txn.pm is documentation only.

# model($name): the registered model, bound to this transaction.
SV *
model(self, name)
        SV *self
        SV *name
    CODE:
        RETVAL = ptx_model(aTHX_ self, name);
    OUTPUT:
        RETVAL

# handle: the DBI $dbh on Punk::Model::DBI, the DBIx::Loop::Txn on
# Punk::Model::DBIx::Loop - for the raw statement that has no model.
SV *
handle(self)
        SV *self
    ALIAS:
        name    = 1
        backend = 2
    CODE:
    {
        static const char *const k[] = { "handle", "name", "class" };
        SV *v = pdbi_get(aTHX_ ptx_hv(aTHX_ self), k[ix]);
        RETVAL = v ? newSVsv(v) : newSV(0); /* # uncoverable condition right count:1 class:ignore_covered_err */
    }
    OUTPUT:
        RETVAL

IV
is_active(self)
        SV *self
    CODE:
    {
        SV *v = pdbi_get(aTHX_ ptx_hv(aTHX_ self), "active");
        RETVAL = (v && SvTRUE(v)) ? 1 : 0; /* # uncoverable condition right count:1 class:ignore_covered_err */
    }
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::Model::DBI

# _txn(\%opts, $code, $tx): begin_work, the block, commit - or rollback and
# rethrow. Returns the block's value.
SV *
_txn(class, opts, code, tx)
        SV *class
        SV *opts
        SV *code
        SV *tx
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = ptx_dbi_run(aTHX_ opts, code, tx);
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::Model::DBIx::Loop

# _txn(\%opts, $code, $tx): $db->txn with the bridge. Returns a Punk::Future
# of the block's value, resolved after COMMIT.
SV *
_txn(class, opts, code, tx)
        SV *class
        SV *opts
        SV *code
        SV *tx
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = ptx_loop_run(aTHX_ opts, code, tx);
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::Context

# txn($code) / txn($name => $code): a transaction on the named (or default)
# database; see Punk::Txn.
SV *
txn(self, ...)
        SV *self
    CODE:
    {
        SV *name = &PL_sv_undef, *code = &PL_sv_undef;
        if (items == 2)      code = ST(1);
        # uncoverable branch false
        # uncoverable condition right count:1 class:ignore_covered_err
        else if (items == 3) { name = ST(1); code = ST(2); }
        else croak("Punk::Txn: txn takes a coderef, or a database name and a " /* # uncoverable statement */
                   "coderef");
        RETVAL = ptx_context_txn(aTHX_ self, name, code);
    }
    OUTPUT:
        RETVAL
