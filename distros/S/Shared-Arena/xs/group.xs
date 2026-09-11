# Shared::Arena::Ring::Group - one record to one member of the pool.
#
# A cursor is process-local, so every reader holding one sees every record.
# A group's cursor is in the mapping, so whoever wins the compare-and-swap owns
# that record and nobody else does. The difference between fanout and a queue
# is WHERE THE CURSOR LIVES, and nothing else.

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Ring    PREFIX = sarrg_

# $ring->group($name, topic => 'jobs', from_start => 1)
SV *
sarrg_group(self, name, ...)
        SV *self
        SV *name
    PREINIT:
        sa_ring *r;
        sa_group *g;
        sa_group_h *gh;
        const char *nm, *tp = NULL;
        STRLEN nlen, tlen = 0;
        int from_start = 0, err = SA_E_OK;
        uint64_t from = 0;
        I32 i;
        SV *obj;
    CODE:
        r = SA_SELF(sa_ring, self);
        if (!r) croak("Shared::Arena::Ring: this ring is released");
        nm = SvPV(name, nlen);
        for (i = 2; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if      (strEQ(o, "topic") && SvOK(ST(i + 1)))
                tp = SvPV(ST(i + 1), tlen);
            else if (strEQ(o, "from_start")) from_start = SvTRUE(ST(i + 1));
        }
#if SA_HAVE_ATOMICS
        if (from_start) {
            uint64_t end = sa_at_load64_acq(&r->hdr->seq);
            from = (end > r->nslots) ? end - r->nslots : 1;
        }
        gh = sa_group_new(r, nm, (uint32_t)nlen, tp, (uint32_t)tlen, from, &err);
        if (!gh) croak("Shared::Arena::Ring: the group '%s' %s",
                       nm, sa_strerror(err));
        PERL_UNUSED_VAR(g);
#else
        croak("Shared::Arena::Ring: groups need atomics this build does not have");
#endif
        obj = newSV(0);
        sv_setref_pv(obj, "Shared::Arena::Ring::Group", (void *)gh);
        sv_magicext(SvRV(obj), SvRV(self), PERL_MAGIC_ext, NULL, NULL, 0);
        SvREFCNT_inc(SvRV(self));
        RETVAL = obj;
    OUTPUT:
        RETVAL

MODULE = Shared::Arena    PACKAGE = Shared::Arena::Ring::Group    PREFIX = sarg_

# Records this worker has claimed, as [topic, payload, sequence] arrayrefs.
# Each one is this process's alone: no other member of the group will be given
# it, and if this process dies before acting on it, nobody will.
void
sarg_claim(self, ...)
        SV *self
    PREINIT:
        sa_group_h *gh;
        IV max = 1;
        I32 i;
    PPCODE:
        gh = SA_SELF(sa_group_h, self);
        if (!gh) croak("Shared::Arena::Ring::Group: this group is released");
        for (i = 1; i + 1 < items; i += 2) {
            const char *o = SvPV_nolen(ST(i));
            if (strEQ(o, "max")) max = SvIV(ST(i + 1));
        }
#if SA_HAVE_ATOMICS
        {
            /* Claiming is proof of life, exactly as draining is: a worker that
             * only ever consumes must still tick, or a publisher's hole check
             * would judge it wedged. */
            sa_peer_join(gh->ring->arena);
            sa_peer_beat(gh->ring->arena);
            while (max <= 0 || (IV)(SP - MARK) < max) {
                uint64_t seq = 0;
                const char *topic = NULL, *data = NULL;
                uint32_t tlen = 0, dlen = 0, flags = 0;
                if (sa_group_claim(gh->ring, gh->g, gh->scratch, &seq,
                                   &topic, &tlen, &data, &dlen, &flags)
                        != SA_READ_OK)
                    break;
                {
                    AV *av = newAV();
                    av_push(av, newSVpvn(topic, tlen));
                    av_push(av, newSVpvn(data, dlen));
                    av_push(av, newSVuv((UV)seq));
                    XPUSHs(sv_2mortal(newRV_noinc((SV *)av)));
                }
                gh->claimed++;
            }
        }
#endif

# The group's shared position: what every member is working from.
UV
sarg_position(self)
        SV *self
    PREINIT:
        sa_group_h *gh;
    CODE:
        gh = SA_SELF(sa_group_h, self);
        if (!gh) croak("Shared::Arena::Ring::Group: this group is released");
#if SA_HAVE_ATOMICS
        RETVAL = (UV)sa_at_load64_acq(&gh->g->cursor);
#else
        RETVAL = 0;
#endif
    OUTPUT:
        RETVAL

SV *
sarg_topic(self)
        SV *self
    PREINIT:
        sa_group_h *gh;
    CODE:
        gh = SA_SELF(sa_group_h, self);
        if (!gh) croak("Shared::Arena::Ring::Group: this group is released");
        RETVAL = gh->g->tlen ? newSVpvn(gh->g->topic, gh->g->tlen)
                             : &PL_sv_undef;
    OUTPUT:
        RETVAL

# name / topic / position / delivered / lapped / skipped / mine
#
# `delivered` is the GROUP's, across every member: the number the pool got
# through. `mine` is this process's share of it, which is the one that says
# whether the work is spread or whether one worker is doing all of it.
void
sarg_stats(self)
        SV *self
    PREINIT:
        sa_group_h *gh;
    PPCODE:
        gh = SA_SELF(sa_group_h, self);
        if (!gh) croak("Shared::Arena::Ring::Group: this group is released");
        EXTEND(SP, 14);
        mPUSHp("name", 4);
        mPUSHp(gh->g->name, strlen(gh->g->name));
        mPUSHp("topic", 5);
        mPUSHp(gh->g->topic, gh->g->tlen);
#if SA_HAVE_ATOMICS
        mPUSHp("position", 8);
        mPUSHu((UV)sa_at_load64_acq(&gh->g->cursor));
        mPUSHp("delivered", 9);
        mPUSHu((UV)sa_at_load64_acq(&gh->g->delivered));
        mPUSHp("lapped", 6);
        mPUSHu((UV)sa_at_load64_acq(&gh->g->lapped));
        mPUSHp("skipped", 7);
        mPUSHu((UV)sa_at_load64_acq(&gh->g->skipped));
#endif
        mPUSHp("mine", 4);
        mPUSHu((UV)gh->claimed);

void
sarg_DESTROY(self)
        SV *self
    PREINIT:
        sa_group_h *gh;
    CODE:
        gh = SA_SELF(sa_group_h, self);
        if (gh) {
            /* The group in the mapping OUTLIVES this handle. Leaving is not
             * releasing: another worker is still claiming from that cursor, and
             * a member that exits must not take the pool's position with it. */
            sa_group_free(gh);
            sv_setiv(SvRV(self), 0);
        }
