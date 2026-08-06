/* VM dispatch body - included twice by stencil_render.c:
 *   STENCIL_VM_GOTO=1  -> computed-goto threaded dispatch
 *   STENCIL_VM_GOTO=0  -> portable switch dispatch
 * with STENCIL_VM_NAME set to the function name. The op handlers are
 * written once; only the dispatch glue differs. Returns 1 on SOP_END,
 * 0 after rerror(). */

static int STENCIL_VM_NAME(pTHX_ stencil_rstate *r)
{
    const uint8_t *code = r->code;
    uint32_t pc = 0, at = 0;

#if STENCIL_VM_GOTO
    static const void *const jt[] = {
#define STENCIL_X_LBL(n) &&L_##n,
        STENCIL_OPS(STENCIL_X_LBL)
#undef STENCIL_X_LBL
    };
#  define VM_CASE(n) L_##n:
#  define VM_NEXT    do { at = pc; goto *jt[code[pc++]]; } while (0)
    VM_NEXT;
#else
#  define VM_CASE(n) case n:
#  define VM_NEXT    break
    for (;;) {
        at = pc;
        switch (code[pc++]) {
        default:
            return rfail(r, at, "corrupt bytecode (op %u)",
                          (unsigned)code[pc - 1]);
#endif

    VM_CASE(SOP_END)
    {
        return 1;
    }

    VM_CASE(SOP_LITERAL_SHORT)
    {
        uint8_t l = code[pc++];
        stencil_buf_write(&r->buf, (const char *)code + pc, l);
        pc += l;
    }
    VM_NEXT;

    VM_CASE(SOP_LITERAL_LONG)
    {
        uint32_t off = vm_u32(code, &pc);
        uint32_t len = vm_u32(code, &pc);
        stencil_buf_write(&r->buf, r->pool + off, len);
    }
    VM_NEXT;

    VM_CASE(SOP_PRINT_ESC)
    {
        stencil_val v = r->stack[--r->sp];
        if (STENCIL_LIKELY(v.sv && SvOK(v.sv))) {
            STRLEN      n;
            const char *p = SvPV(v.sv, n);
            if (SvUTF8(v.sv))
                r->buf.utf8 = 1;
            else if (STENCIL_UNLIKELY(has_high_byte(p, n))) {
                p = latin1_upgrade(aTHX_ r, p, &n);
                r->buf.utf8 = 1;
            }
            if (STENCIL_UNLIKELY((v.vflags & STENCIL_VF_ESCAPED)
                                 || (r->flags & STENCIL_RF_NO_ESCAPE)))
                stencil_buf_write(&r->buf, p, n);
            else
                stencil_dispatch.escape(&r->buf, p, n);
        } else if (STENCIL_UNLIKELY(r->flags & STENCIL_RF_STRICT)) {
            val_release(aTHX_ &v);
            return rfail_path(r, at, r->last_path);
        }
        val_release(aTHX_ &v);
    }
    VM_NEXT;

    VM_CASE(SOP_PRINT_RAW)
    {
        stencil_val v = r->stack[--r->sp];
        if (STENCIL_LIKELY(v.sv && SvOK(v.sv))) {
            STRLEN      n;
            const char *p = SvPV(v.sv, n);
            if (SvUTF8(v.sv))
                r->buf.utf8 = 1;
            else if (STENCIL_UNLIKELY(has_high_byte(p, n))) {
                p = latin1_upgrade(aTHX_ r, p, &n);
                r->buf.utf8 = 1;
            }
            stencil_buf_write(&r->buf, p, n);
        } else if (STENCIL_UNLIKELY(r->flags & STENCIL_RF_STRICT)) {
            val_release(aTHX_ &v);
            return rfail_path(r, at, r->last_path);
        }
        val_release(aTHX_ &v);
    }
    VM_NEXT;

    VM_CASE(SOP_PUSH_PATH)
    {
        uint32_t id    = vm_u32(code, &pc);
        int      owned = 0;
        SV      *sv;
        r->last_path = id;
        sv = resolve_path(aTHX_ r, id, &owned);
        if (STENCIL_UNLIKELY(r->failed))
            return rfail_here(r, at);
        r->stack[r->sp].sv    = sv;
        r->stack[r->sp].owned = owned;
        r->stack[r->sp].vflags = 0;
        r->sp++;
    }
    VM_NEXT;

    VM_CASE(SOP_PUSH_LIT_STR)
    {
        uint32_t off = vm_u32(code, &pc);
        uint32_t len = vm_u32(code, &pc);
        SV *sv = newSVpvn(r->pool + off, len);
        if (r->prog->flags & STENCIL_PROG_SRC_UTF8)
            SvUTF8_on(sv);
        r->stack[r->sp].sv    = sv;
        r->stack[r->sp].owned = 1;
        r->stack[r->sp].vflags = 0;
        r->sp++;
    }
    VM_NEXT;

    VM_CASE(SOP_PUSH_LIT_NUM)
    {
        double d;
        memcpy(&d, code + pc, 8);
        pc += 8;
        r->stack[r->sp].sv    = newSVnv((NV)d);
        r->stack[r->sp].owned = 1;
        r->stack[r->sp].vflags = 0;
        r->sp++;
    }
    VM_NEXT;

    VM_CASE(SOP_PUSH_UNDEF)
    {
        r->stack[r->sp].sv    = NULL;
        r->stack[r->sp].owned = 0;
        r->stack[r->sp].vflags = 0;
        r->sp++;
    }
    VM_NEXT;

    VM_CASE(SOP_NOT)
    {
        stencil_val v  = r->stack[--r->sp];
        int         t  = sv_truthy(aTHX_ v.sv);
        val_release(aTHX_ &v);
        r->stack[r->sp].sv    = t ? &PL_sv_no : &PL_sv_yes;
        r->stack[r->sp].owned = 0;
        r->stack[r->sp].vflags = 0;
        r->sp++;
    }
    VM_NEXT;

    VM_CASE(SOP_DEFINED)
    {
        stencil_val v = r->stack[--r->sp];
        int         d = v.sv && SvOK(v.sv);
        val_release(aTHX_ &v);
        r->stack[r->sp].sv    = d ? &PL_sv_yes : &PL_sv_no;
        r->stack[r->sp].owned = 0;
        r->stack[r->sp].vflags = 0;
        r->sp++;
    }
    VM_NEXT;

    VM_CASE(SOP_EQ_NUM) VM_CMP_NUM(==)
    VM_CASE(SOP_NE_NUM) VM_CMP_NUM(!=)
    VM_CASE(SOP_LT_NUM) VM_CMP_NUM(<)
    VM_CASE(SOP_GT_NUM) VM_CMP_NUM(>)
    VM_CASE(SOP_LE_NUM) VM_CMP_NUM(<=)
    VM_CASE(SOP_GE_NUM) VM_CMP_NUM(>=)

    VM_CASE(SOP_EQ_STR) VM_CMP_STR(sv_eq_flags(a, b, 0))
    VM_CASE(SOP_NE_STR) VM_CMP_STR(!sv_eq_flags(a, b, 0))
    VM_CASE(SOP_LT_STR) VM_CMP_STR(sv_cmp_flags(a, b, 0) < 0)
    VM_CASE(SOP_GT_STR) VM_CMP_STR(sv_cmp_flags(a, b, 0) > 0)
    VM_CASE(SOP_LE_STR) VM_CMP_STR(sv_cmp_flags(a, b, 0) <= 0)
    VM_CASE(SOP_GE_STR) VM_CMP_STR(sv_cmp_flags(a, b, 0) >= 0)

    VM_CASE(SOP_TEST_JF)
    {
        uint32_t    t = vm_u32(code, &pc);
        stencil_val v = r->stack[--r->sp];
        if (!sv_truthy(aTHX_ v.sv))
            pc = t;
        val_release(aTHX_ &v);
    }
    VM_NEXT;

    VM_CASE(SOP_TEST_JT)
    {
        uint32_t    t = vm_u32(code, &pc);
        stencil_val v = r->stack[--r->sp];
        if (sv_truthy(aTHX_ v.sv))
            pc = t;
        val_release(aTHX_ &v);
    }
    VM_NEXT;

    VM_CASE(SOP_JF_KEEP)
    {
        uint32_t t = vm_u32(code, &pc);
        if (!sv_truthy(aTHX_ r->stack[r->sp - 1].sv))
            pc = t;
    }
    VM_NEXT;

    VM_CASE(SOP_JT_KEEP)
    {
        uint32_t t = vm_u32(code, &pc);
        if (sv_truthy(aTHX_ r->stack[r->sp - 1].sv))
            pc = t;
    }
    VM_NEXT;

    VM_CASE(SOP_POP)
    {
        stencil_val v = r->stack[--r->sp];
        val_release(aTHX_ &v);
    }
    VM_NEXT;

    VM_CASE(SOP_JUMP)
    {
        pc = vm_u32(code, &pc);
    }
    VM_NEXT;

    VM_CASE(SOP_FOR_ARY)
    {
        uint32_t    name_id = vm_u32(code, &pc);
        uint32_t    end_t   = vm_u32(code, &pc);
        stencil_val v       = r->stack[--r->sp];
        SV         *rv;
        AV         *av;
        SSize_t     size;
        if (!v.sv || !SvOK(v.sv)) {
            val_release(aTHX_ &v);
            pc = end_t;
            VM_NEXT;
        }
        if (!SvROK(v.sv)
            || SvTYPE(rv = SvRV(v.sv)) != SVt_PVAV
            || SvOBJECT(rv)) {
            val_release(aTHX_ &v);
            return rfail(r, at, "'%.*s' is not an array reference",
                          (int)r->paths[r->last_path].full_len,
                          r->pool + r->paths[r->last_path].full_off);
        }
        av   = (AV *)rv;
        size = av_top_index(av) + 1;
        if (size == 0) {
            val_release(aTHX_ &v);
            pc = end_t;
            VM_NEXT;
        }
        {
            stencil_rframe *f = &r->frames[r->nf++];
            SV **svp = av_fetch(av, 0, 0);
            f->is_hash   = 0;
            f->av        = av;
            f->hv        = NULL;
            f->kh        = NULL;
            f->key_sv    = NULL;
            f->i         = 0;
            f->size      = size;
            f->name      = sname_of(r, name_id);
            memset(&f->val, 0, sizeof f->val);
            f->serial    = ++r->serial;
            f->cur       = svp ? *svp : NULL;
            f->cur_val   = NULL;
            f->agg       = v.sv;
            f->agg_owned = v.owned;
        }
    }
    VM_NEXT;

    VM_CASE(SOP_FOR_HASH)
    {
        uint32_t    key_id = vm_u32(code, &pc);
        uint32_t    val_id = vm_u32(code, &pc);
        uint32_t    end_t  = vm_u32(code, &pc);
        stencil_val v      = r->stack[--r->sp];
        SV         *rv;
        HV         *hv;
        SSize_t     size;
        if (!v.sv || !SvOK(v.sv)) {
            val_release(aTHX_ &v);
            pc = end_t;
            VM_NEXT;
        }
        if (!SvROK(v.sv)
            || SvTYPE(rv = SvRV(v.sv)) != SVt_PVHV
            || SvOBJECT(rv)) {
            val_release(aTHX_ &v);
            return rfail(r, at, "'%.*s' is not a hash reference",
                          (int)r->paths[r->last_path].full_len,
                          r->pool + r->paths[r->last_path].full_off);
        }
        hv   = (HV *)rv;
        size = (SSize_t)HvKEYS(hv);
        if (size == 0) {
            val_release(aTHX_ &v);
            pc = end_t;
            VM_NEXT;
        }
        {
            stencil_rframe *f = &r->frames[r->nf++];
            f->is_hash   = 1;
            f->av        = NULL;
            f->hv        = hv;
            f->kh        = kh_collect(aTHX_ hv, size,
                              !(r->flags & STENCIL_RF_NO_SORT_KEYS));
            f->key_sv    = newSV(16);
            f->i         = 0;
            f->size      = size;
            f->name      = sname_of(r, key_id);
            f->val       = sname_of(r, val_id);
            f->serial    = ++r->serial;
            f->agg       = v.sv;
            f->agg_owned = v.owned;
            kh_bind(aTHX_ f, 0);
        }
    }
    VM_NEXT;

    VM_CASE(SOP_FOR_NEXT)
    {
        uint32_t        body_t = vm_u32(code, &pc);
        stencil_rframe *f      = &r->frames[r->nf - 1];
        f->i++;
        if (f->i < f->size) {
            if (f->is_hash) {
                kh_bind(aTHX_ f, f->i);
            } else {
                SV **svp = av_fetch(f->av, f->i, 0);
                f->cur = svp ? *svp : NULL;
            }
            pc = body_t;
        } else {
            frame_release(aTHX_ f);
            r->nf--;
        }
    }
    VM_NEXT;

    VM_CASE(SOP_SET)
    {
        uint32_t    id = vm_u32(code, &pc);
        stencil_val v  = r->stack[--r->sp];
        SV *sv = v.owned ? v.sv
               : v.sv    ? newSVsv(v.sv)
                         : newSV(0);
        r->binds[r->nb].name    = sname_of(r, id);
        r->binds[r->nb].sv      = sv;
        r->binds[r->nb].serial  = ++r->serial;
        r->nb++;
    }
    VM_NEXT;

    VM_CASE(SOP_POP_BINDS)
    {
        uint32_t n = vm_u32(code, &pc);
        while (n--)
            SvREFCNT_dec(r->binds[--r->nb].sv);
    }
    VM_NEXT;

    VM_CASE(SOP_INCLUDE)
    {
        uint32_t id = vm_u32(code, &pc);
        int      ok2;
        if (STENCIL_UNLIKELY(!r->incs))
            return rfail(r, at, "include requires an engine");
        {
            stencil_cache_ent  *child = r->incs[id];
            stencil_program    *sp = r->prog;
            stencil_cache_ent **si = r->incs;
            const char         *sn = r->unit_name;
            set_unit(r, child->prog, child->incs,
                     child->abs_path ? child->abs_path : "<string>");
            ok2 = STENCIL_VM_NAME(aTHX_ r);
            set_unit(r, sp, si, sn);
        }
        if (STENCIL_UNLIKELY(!ok2))
            return 0;
        code = r->code;
    }
    VM_NEXT;

    VM_CASE(SOP_CONTENT)
    {
        int ok2;
        if (STENCIL_UNLIKELY(!r->content_prog))
            return rfail(r, at,
                         "no content template for {%% content %%}");
        if (STENCIL_UNLIKELY(r->content_done))
            return rfail(r, at, "{%% content %%} executed twice");
        r->content_done = 1;
        {
            stencil_program    *sp = r->prog;
            stencil_cache_ent **si = r->incs;
            const char         *sn = r->unit_name;
            set_unit(r, r->content_prog, r->content_incs,
                     r->content_name);
            ok2 = STENCIL_VM_NAME(aTHX_ r);
            set_unit(r, sp, si, sn);
        }
        if (STENCIL_UNLIKELY(!ok2))
            return 0;
        code = r->code;
    }
    VM_NEXT;

    VM_CASE(SOP_FILTER)
    {
        uint32_t idx = vm_u32(code, &pc);
        if (STENCIL_UNLIKELY(!filter_apply(aTHX_ r, idx)))
            return rfail_here(r, at);
    }
    VM_NEXT;

#if !STENCIL_VM_GOTO
        } /* switch */
    } /* for */
#endif

#undef VM_CASE
#undef VM_NEXT
}
