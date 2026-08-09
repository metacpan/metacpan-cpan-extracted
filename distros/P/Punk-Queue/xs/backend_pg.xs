MODULE = Punk::Queue        PACKAGE = Punk::Queue::Backend::Pg

# The PostgreSQL divergences. Everything else this class answers to comes
# from Punk::Queue::Backend, which it inherits.

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

        row = pq_pg_dequeue(aTHX_ self, worker_id, q, t);
        if (!row) XSRETURN_UNDEF;
        RETVAL = row;
    }
    OUTPUT:
        RETVAL

# Emit a wakeup on a queue's channel. The LISTEN side is phase 5; this is
# what enqueue will call once it exists.
void
notify(self, queue, id)
    SV *self
    SV *queue
    IV id
    CODE:
        pq_pg_notify(aTHX_ self, queue, id);

# Transaction control, exposed so the conformance suite can drive it
# directly rather than only through the operations that use it.

void
begin_immediate(self)
    SV *self
    CODE:
        pq_pg_begin_exclusive(aTHX_ self);

void
commit(self)
    SV *self
    CODE:
        pq_pg_commit(aTHX_ self);

void
rollback(self)
    SV *self
    CODE:
        pq_pg_rollback(aTHX_ self);
