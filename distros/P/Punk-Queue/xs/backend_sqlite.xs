MODULE = Punk::Queue        PACKAGE = Punk::Queue::Backend::SQLite

# The SQLite divergences. Everything else this class answers to comes from
# Punk::Queue::Backend, which it inherits.

SV *
dequeue(self, worker_id = 0, queues = NULL, tasks = NULL)
    SV *self
    IV worker_id
    SV *queues
    SV *tasks
    PREINIT:
        AV *q, *t;
        SV *row;
    CODE:
    {
        q = pq_sql_list(aTHX_ queues);
        if (av_len(q) < 0) av_push(q, newSVpvs("default"));
        t = pq_sql_list(aTHX_ tasks);

        row = pq_sqlite_dequeue(aTHX_ self, worker_id, q, t);
        if (!row) XSRETURN_UNDEF;
        RETVAL = row;
    }
    OUTPUT:
        RETVAL

# Transaction control, exposed so the conformance suite (phase 2) can drive
# it directly rather than only through the operations that use it.

void
begin_immediate(self)
    SV *self
    CODE:
        pq_sqlite_begin_exclusive(aTHX_ self);

void
commit(self)
    SV *self
    CODE:
        pq_sqlite_commit(aTHX_ self);

void
rollback(self)
    SV *self
    CODE:
        pq_sqlite_rollback(aTHX_ self);
