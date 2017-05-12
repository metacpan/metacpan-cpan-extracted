#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int runops_switch(pTHX)
{
    while (PL_op) {
	switch (PL_op->op_type) {
	    case OP_NULL:
	    case OP_SCALAR:
	    case OP_SCOPE:
	    case OP_LINESEQ:
	    case OP_REGCMAYBE:
		PL_op = NORMAL; break;
	    case OP_STUB:
		{
		    dSP;
		    if (GIMME_V == G_SCALAR)
			XPUSHs(&PL_sv_undef);
		    PUTBACK;
		    PL_op = NORMAL;
		}
		break;
	    case OP_PUSHMARK:
		PUSHMARK(PL_stack_sp);
		PL_op = NORMAL;
		break;
	    case OP_WANTARRAY:
		PL_op = Perl_pp_wantarray(aTHX); break;
	    case OP_CONST:
		{ dSP; XPUSHs(cSVOP_sv); PUTBACK; PL_op = NORMAL; }
		break;
	    case OP_GVSV:
		PL_op = Perl_pp_gvsv(aTHX); break;
	    case OP_GV:
		{
		    dSP;
		    XPUSHs((SV*)cGVOP_gv);
		    PUTBACK;
		    PL_op = NORMAL;
		}
		break;
	    case OP_GELEM:
		PL_op = Perl_pp_gelem(aTHX); break;
	    case OP_PADSV:
		PL_op = Perl_pp_padsv(aTHX); break;
	    case OP_PADAV:
		PL_op = Perl_pp_padav(aTHX); break;
	    case OP_PADHV:
		PL_op = Perl_pp_padhv(aTHX); break;
	    case OP_PADANY:
		PL_op = Perl_pp_padany(aTHX); break;
	    case OP_PUSHRE:
		PL_op = Perl_pp_pushre(aTHX); break;
	    case OP_RV2GV:
		PL_op = Perl_pp_rv2gv(aTHX); break;
	    case OP_RV2SV:
		PL_op = Perl_pp_rv2sv(aTHX); break;
	    case OP_AV2ARYLEN:
		PL_op = Perl_pp_av2arylen(aTHX); break;
	    case OP_RV2CV:
		PL_op = Perl_pp_rv2cv(aTHX); break;
	    case OP_ANONCODE:
		PL_op = Perl_pp_anoncode(aTHX); break;
	    case OP_PROTOTYPE:
		PL_op = Perl_pp_prototype(aTHX); break;
	    case OP_REFGEN:
		PL_op = Perl_pp_refgen(aTHX); break;
	    case OP_SREFGEN:
		PL_op = Perl_pp_srefgen(aTHX); break;
	    case OP_REF:
		PL_op = Perl_pp_ref(aTHX); break;
	    case OP_BLESS:
		PL_op = Perl_pp_bless(aTHX); break;
	    case OP_BACKTICK:
		PL_op = Perl_pp_backtick(aTHX); break;
	    case OP_GLOB:
		PL_op = Perl_pp_glob(aTHX); break;
	    case OP_READLINE:
		PL_op = Perl_pp_readline(aTHX); break;
	    case OP_RCATLINE:
		PL_op = Perl_pp_rcatline(aTHX); break;
	    case OP_REGCRESET:
		PL_op = Perl_pp_regcreset(aTHX); break;
	    case OP_REGCOMP:
		PL_op = Perl_pp_regcomp(aTHX); break;
	    case OP_MATCH:
		PL_op = Perl_pp_match(aTHX); break;
	    case OP_QR:
		PL_op = Perl_pp_qr(aTHX); break;
	    case OP_SUBST:
		PL_op = Perl_pp_subst(aTHX); break;
	    case OP_SUBSTCONT:
		PL_op = Perl_pp_substcont(aTHX); break;
	    case OP_TRANS:
		PL_op = Perl_pp_trans(aTHX); break;
	    case OP_SASSIGN:
		PL_op = Perl_pp_sassign(aTHX); break;
	    case OP_AASSIGN:
		PL_op = Perl_pp_aassign(aTHX); break;
	    case OP_CHOP:
		PL_op = Perl_pp_chop(aTHX); break;
	    case OP_SCHOP:
		PL_op = Perl_pp_schop(aTHX); break;
	    case OP_CHOMP:
		PL_op = Perl_pp_chomp(aTHX); break;
	    case OP_SCHOMP:
		PL_op = Perl_pp_schomp(aTHX); break;
	    case OP_DEFINED:
		PL_op = Perl_pp_defined(aTHX); break;
	    case OP_UNDEF:
		PL_op = Perl_pp_undef(aTHX); break;
	    case OP_STUDY:
		PL_op = Perl_pp_study(aTHX); break;
	    case OP_POS:
		PL_op = Perl_pp_pos(aTHX); break;
	    case OP_PREINC:
		PL_op = Perl_pp_preinc(aTHX); break;
	    case OP_I_PREINC:
		PL_op = Perl_pp_i_preinc(aTHX); break;
	    case OP_PREDEC:
		PL_op = Perl_pp_predec(aTHX); break;
	    case OP_I_PREDEC:
		PL_op = Perl_pp_i_predec(aTHX); break;
	    case OP_POSTINC:
		PL_op = Perl_pp_postinc(aTHX); break;
	    case OP_I_POSTINC:
		PL_op = Perl_pp_i_postinc(aTHX); break;
	    case OP_POSTDEC:
		PL_op = Perl_pp_postdec(aTHX); break;
	    case OP_I_POSTDEC:
		PL_op = Perl_pp_i_postdec(aTHX); break;
	    case OP_POW:
		PL_op = Perl_pp_pow(aTHX); break;
	    case OP_MULTIPLY:
		PL_op = Perl_pp_multiply(aTHX); break;
	    case OP_I_MULTIPLY:
		PL_op = Perl_pp_i_multiply(aTHX); break;
	    case OP_DIVIDE:
		PL_op = Perl_pp_divide(aTHX); break;
	    case OP_I_DIVIDE:
		PL_op = Perl_pp_i_divide(aTHX); break;
	    case OP_MODULO:
		PL_op = Perl_pp_modulo(aTHX); break;
	    case OP_I_MODULO:
		PL_op = Perl_pp_i_modulo(aTHX); break;
	    case OP_REPEAT:
		PL_op = Perl_pp_repeat(aTHX); break;
	    case OP_ADD:
		PL_op = Perl_pp_add(aTHX); break;
	    case OP_I_ADD:
		PL_op = Perl_pp_i_add(aTHX); break;
	    case OP_SUBTRACT:
		PL_op = Perl_pp_subtract(aTHX); break;
	    case OP_I_SUBTRACT:
		PL_op = Perl_pp_i_subtract(aTHX); break;
	    case OP_CONCAT:
		PL_op = Perl_pp_concat(aTHX); break;
	    case OP_STRINGIFY:
		{
		    dSP; dTARGET;
		    sv_copypv(TARG,TOPs);
		    SETTARG;
		    PUTBACK;
		    PL_op = NORMAL;
		}
		break;
	    case OP_LEFT_SHIFT:
		PL_op = Perl_pp_left_shift(aTHX); break;
	    case OP_RIGHT_SHIFT:
		PL_op = Perl_pp_right_shift(aTHX); break;
	    case OP_LT:
		PL_op = Perl_pp_lt(aTHX); break;
	    case OP_I_LT:
		PL_op = Perl_pp_i_lt(aTHX); break;
	    case OP_GT:
		PL_op = Perl_pp_gt(aTHX); break;
	    case OP_I_GT:
		PL_op = Perl_pp_i_gt(aTHX); break;
	    case OP_LE:
		PL_op = Perl_pp_le(aTHX); break;
	    case OP_I_LE:
		PL_op = Perl_pp_i_le(aTHX); break;
	    case OP_GE:
		PL_op = Perl_pp_ge(aTHX); break;
	    case OP_I_GE:
		PL_op = Perl_pp_i_ge(aTHX); break;
	    case OP_EQ:
		PL_op = Perl_pp_eq(aTHX); break;
	    case OP_I_EQ:
		PL_op = Perl_pp_i_eq(aTHX); break;
	    case OP_NE:
		PL_op = Perl_pp_ne(aTHX); break;
	    case OP_I_NE:
		PL_op = Perl_pp_i_ne(aTHX); break;
	    case OP_NCMP:
		PL_op = Perl_pp_ncmp(aTHX); break;
	    case OP_I_NCMP:
		PL_op = Perl_pp_i_ncmp(aTHX); break;
	    case OP_SLT:
		PL_op = Perl_pp_slt(aTHX); break;
	    case OP_SGT:
		PL_op = Perl_pp_sgt(aTHX); break;
	    case OP_SLE:
		PL_op = Perl_pp_sle(aTHX); break;
	    case OP_SGE:
		PL_op = Perl_pp_sge(aTHX); break;
	    case OP_SEQ:
		PL_op = Perl_pp_seq(aTHX); break;
	    case OP_SNE:
		PL_op = Perl_pp_sne(aTHX); break;
	    case OP_SCMP:
		PL_op = Perl_pp_scmp(aTHX); break;
	    case OP_BIT_AND:
		PL_op = Perl_pp_bit_and(aTHX); break;
	    case OP_BIT_XOR:
		PL_op = Perl_pp_bit_xor(aTHX); break;
	    case OP_BIT_OR:
		PL_op = Perl_pp_bit_or(aTHX); break;
	    case OP_NEGATE:
		PL_op = Perl_pp_negate(aTHX); break;
	    case OP_I_NEGATE:
		PL_op = Perl_pp_i_negate(aTHX); break;
	    case OP_NOT:
		PL_op = Perl_pp_not(aTHX); break;
	    case OP_COMPLEMENT:
		PL_op = Perl_pp_complement(aTHX); break;
	    case OP_ATAN2:
		PL_op = Perl_pp_atan2(aTHX); break;
	    case OP_SIN:
		PL_op = Perl_pp_sin(aTHX); break;
	    case OP_COS:
		PL_op = Perl_pp_cos(aTHX); break;
	    case OP_RAND:
		PL_op = Perl_pp_rand(aTHX); break;
	    case OP_SRAND:
		PL_op = Perl_pp_srand(aTHX); break;
	    case OP_EXP:
		PL_op = Perl_pp_exp(aTHX); break;
	    case OP_LOG:
		PL_op = Perl_pp_log(aTHX); break;
	    case OP_SQRT:
		PL_op = Perl_pp_sqrt(aTHX); break;
	    case OP_INT:
		PL_op = Perl_pp_int(aTHX); break;
	    case OP_HEX:
		PL_op = Perl_pp_hex(aTHX); break;
	    case OP_OCT:
		PL_op = Perl_pp_oct(aTHX); break;
	    case OP_ABS:
		PL_op = Perl_pp_abs(aTHX); break;
	    case OP_LENGTH:
		PL_op = Perl_pp_length(aTHX); break;
	    case OP_SUBSTR:
		PL_op = Perl_pp_substr(aTHX); break;
	    case OP_VEC:
		PL_op = Perl_pp_vec(aTHX); break;
	    case OP_INDEX:
		PL_op = Perl_pp_index(aTHX); break;
	    case OP_RINDEX:
		PL_op = Perl_pp_rindex(aTHX); break;
	    case OP_SPRINTF:
		PL_op = Perl_pp_sprintf(aTHX); break;
	    case OP_FORMLINE:
		PL_op = Perl_pp_formline(aTHX); break;
	    case OP_ORD:
		PL_op = Perl_pp_ord(aTHX); break;
	    case OP_CHR:
		PL_op = Perl_pp_chr(aTHX); break;
	    case OP_CRYPT:
		PL_op = Perl_pp_crypt(aTHX); break;
	    case OP_UCFIRST:
		PL_op = Perl_pp_ucfirst(aTHX); break;
	    case OP_LCFIRST:
		PL_op = Perl_pp_lcfirst(aTHX); break;
	    case OP_UC:
		PL_op = Perl_pp_uc(aTHX); break;
	    case OP_LC:
		PL_op = Perl_pp_lc(aTHX); break;
	    case OP_QUOTEMETA:
		PL_op = Perl_pp_quotemeta(aTHX); break;
	    case OP_RV2AV:
		PL_op = Perl_pp_rv2av(aTHX); break;
	    case OP_AELEMFAST:
		PL_op = Perl_pp_aelemfast(aTHX); break;
	    case OP_AELEM:
		PL_op = Perl_pp_aelem(aTHX); break;
	    case OP_ASLICE:
		PL_op = Perl_pp_aslice(aTHX); break;
	    case OP_EACH:
		PL_op = Perl_pp_each(aTHX); break;
	    case OP_VALUES:
		PL_op = Perl_pp_values(aTHX); break;
	    case OP_KEYS:
		PL_op = Perl_pp_keys(aTHX); break;
	    case OP_DELETE:
		PL_op = Perl_pp_delete(aTHX); break;
	    case OP_EXISTS:
		PL_op = Perl_pp_exists(aTHX); break;
	    case OP_RV2HV:
		PL_op = Perl_pp_rv2hv(aTHX); break;
	    case OP_HELEM:
		PL_op = Perl_pp_helem(aTHX); break;
	    case OP_HSLICE:
		PL_op = Perl_pp_hslice(aTHX); break;
	    case OP_UNPACK:
		PL_op = Perl_pp_unpack(aTHX); break;
	    case OP_PACK:
		PL_op = Perl_pp_pack(aTHX); break;
	    case OP_SPLIT:
		PL_op = Perl_pp_split(aTHX); break;
	    case OP_JOIN:
		PL_op = Perl_pp_join(aTHX); break;
	    case OP_LIST:
		PL_op = Perl_pp_list(aTHX); break;
	    case OP_LSLICE:
		PL_op = Perl_pp_lslice(aTHX); break;
	    case OP_ANONLIST:
		PL_op = Perl_pp_anonlist(aTHX); break;
	    case OP_ANONHASH:
		PL_op = Perl_pp_anonhash(aTHX); break;
	    case OP_SPLICE:
		PL_op = Perl_pp_splice(aTHX); break;
	    case OP_PUSH:
		PL_op = Perl_pp_push(aTHX); break;
	    case OP_POP:
		PL_op = Perl_pp_pop(aTHX); break;
	    case OP_SHIFT:
		PL_op = Perl_pp_shift(aTHX); break;
	    case OP_UNSHIFT:
		PL_op = Perl_pp_unshift(aTHX); break;
	    case OP_SORT:
		PL_op = Perl_pp_sort(aTHX); break;
	    case OP_REVERSE:
		PL_op = Perl_pp_reverse(aTHX); break;
	    case OP_GREPSTART:
	    case OP_MAPSTART: /* pp_mapstart isn't used */
		PL_op = Perl_pp_grepstart(aTHX); break;
	    case OP_GREPWHILE:
		PL_op = Perl_pp_grepwhile(aTHX); break;
	    case OP_MAPWHILE:
		PL_op = Perl_pp_mapwhile(aTHX); break;
	    case OP_RANGE:
		PL_op = Perl_pp_range(aTHX); break;
	    case OP_FLIP:
		PL_op = Perl_pp_flip(aTHX); break;
	    case OP_FLOP:
		PL_op = Perl_pp_flop(aTHX); break;
	    case OP_AND:
		{
		    dSP;
		    if (!SvTRUE(TOPs)) {
			PUTBACK;
			PL_op = NORMAL;
		    }
		    else {
			--SP;
			PUTBACK;
			PL_op = cLOGOP->op_other;
		    }
		}
		break;
	    case OP_OR:
		{
		    dSP;
		    if (SvTRUE(TOPs)) {
			PUTBACK;
			PL_op = NORMAL;
		    }
		    else {
			--SP;
			PUTBACK;
			PL_op = cLOGOP->op_other;
		    }
		}
		break;
	    case OP_XOR:
		PL_op = Perl_pp_xor(aTHX); break;
	    case OP_COND_EXPR:
		{
		    dSP;
		    if (SvTRUEx(POPs))
			PUTBACK, PL_op = cLOGOP->op_other;
		    else
			PUTBACK, PL_op = cLOGOP->op_next;
		}
		break;
	    case OP_ANDASSIGN:
		PL_op = Perl_pp_andassign(aTHX); break;
	    case OP_ORASSIGN:
		PL_op = Perl_pp_orassign(aTHX); break;
	    case OP_METHOD:
		PL_op = Perl_pp_method(aTHX); break;
	    case OP_ENTERSUB:
		PL_op = Perl_pp_entersub(aTHX); break;
	    case OP_LEAVESUB:
		PL_op = Perl_pp_leavesub(aTHX); break;
	    case OP_LEAVESUBLV:
		PL_op = Perl_pp_leavesublv(aTHX); break;
	    case OP_CALLER:
		PL_op = Perl_pp_caller(aTHX); break;
	    case OP_WARN:
		PL_op = Perl_pp_warn(aTHX); break;
	    case OP_DIE:
		PL_op = Perl_pp_die(aTHX); break;
	    case OP_RESET:
		PL_op = Perl_pp_reset(aTHX); break;
	    case OP_NEXTSTATE:
		PL_curcop = (COP*)PL_op;
		TAINT_NOT;		/* Each statement is presumed innocent */
		PL_stack_sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp;
		FREETMPS;
		PL_op = NORMAL;
		break;
	    case OP_DBSTATE:
		PL_op = Perl_pp_dbstate(aTHX); break;
	    case OP_UNSTACK:
		{
		    I32 oldsave;
		    TAINT_NOT;		/* Each statement is presumed innocent */
		    PL_stack_sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp;
		    FREETMPS;
		    oldsave = PL_scopestack[PL_scopestack_ix - 1];
		    LEAVE_SCOPE(oldsave);
		    PL_op = NORMAL;
		}
		break;
	    case OP_ENTER:
		PL_op = Perl_pp_enter(aTHX); break;
	    case OP_LEAVE:
		PL_op = Perl_pp_leave(aTHX); break;
	    case OP_ENTERITER:
		PL_op = Perl_pp_enteriter(aTHX); break;
	    case OP_ITER:
		PL_op = Perl_pp_iter(aTHX); break;
	    case OP_ENTERLOOP:
		PL_op = Perl_pp_enterloop(aTHX); break;
	    case OP_LEAVELOOP:
		PL_op = Perl_pp_leaveloop(aTHX); break;
	    case OP_RETURN:
		PL_op = Perl_pp_return(aTHX); break;
	    case OP_LAST:
		PL_op = Perl_pp_last(aTHX); break;
	    case OP_NEXT:
		PL_op = Perl_pp_next(aTHX); break;
	    case OP_REDO:
		PL_op = Perl_pp_redo(aTHX); break;
	    case OP_DUMP:
		PL_op = Perl_pp_dump(aTHX); break;
	    case OP_GOTO:
		PL_op = Perl_pp_goto(aTHX); break;
	    case OP_EXIT:
		PL_op = Perl_pp_exit(aTHX); break;
	    case OP_OPEN:
		PL_op = Perl_pp_open(aTHX); break;
	    case OP_CLOSE:
		PL_op = Perl_pp_close(aTHX); break;
	    case OP_PIPE_OP:
		PL_op = Perl_pp_pipe_op(aTHX); break;
	    case OP_FILENO:
		PL_op = Perl_pp_fileno(aTHX); break;
	    case OP_UMASK:
		PL_op = Perl_pp_umask(aTHX); break;
	    case OP_BINMODE:
		PL_op = Perl_pp_binmode(aTHX); break;
	    case OP_TIE:
		PL_op = Perl_pp_tie(aTHX); break;
	    case OP_UNTIE:
		PL_op = Perl_pp_untie(aTHX); break;
	    case OP_TIED:
		PL_op = Perl_pp_tied(aTHX); break;
	    case OP_DBMOPEN:
		PL_op = Perl_pp_dbmopen(aTHX); break;
	    case OP_DBMCLOSE:
		PL_op = Perl_pp_dbmclose(aTHX); break;
	    case OP_SSELECT:
		PL_op = Perl_pp_sselect(aTHX); break;
	    case OP_SELECT:
		PL_op = Perl_pp_select(aTHX); break;
	    case OP_GETC:
		PL_op = Perl_pp_getc(aTHX); break;
	    case OP_READ:
		PL_op = Perl_pp_read(aTHX); break;
	    case OP_ENTERWRITE:
		PL_op = Perl_pp_enterwrite(aTHX); break;
	    case OP_LEAVEWRITE:
		PL_op = Perl_pp_leavewrite(aTHX); break;
	    case OP_PRTF:
		PL_op = Perl_pp_prtf(aTHX); break;
	    case OP_PRINT:
#if PERL_VERSION >= 10
	    case OP_SAY:
#endif
		PL_op = Perl_pp_print(aTHX); break;
	    case OP_SYSOPEN:
		PL_op = Perl_pp_sysopen(aTHX); break;
	    case OP_SYSSEEK:
		PL_op = Perl_pp_sysseek(aTHX); break;
	    case OP_SYSREAD:
		PL_op = Perl_pp_sysread(aTHX); break;
	    case OP_SYSWRITE:
		PL_op = Perl_pp_syswrite(aTHX); break;
	    case OP_SEND:
		PL_op = Perl_pp_send(aTHX); break;
	    case OP_RECV:
		PL_op = Perl_pp_recv(aTHX); break;
	    case OP_EOF:
		PL_op = Perl_pp_eof(aTHX); break;
	    case OP_TELL:
		PL_op = Perl_pp_tell(aTHX); break;
	    case OP_SEEK:
		PL_op = Perl_pp_seek(aTHX); break;
	    case OP_TRUNCATE:
		PL_op = Perl_pp_truncate(aTHX); break;
	    case OP_FCNTL:
		PL_op = Perl_pp_fcntl(aTHX); break;
	    case OP_IOCTL:
		PL_op = Perl_pp_ioctl(aTHX); break;
	    case OP_FLOCK:
		PL_op = Perl_pp_flock(aTHX); break;
	    case OP_SOCKET:
		PL_op = Perl_pp_socket(aTHX); break;
	    case OP_SOCKPAIR:
		PL_op = Perl_pp_sockpair(aTHX); break;
	    case OP_BIND:
		PL_op = Perl_pp_bind(aTHX); break;
	    case OP_CONNECT:
		PL_op = Perl_pp_connect(aTHX); break;
	    case OP_LISTEN:
		PL_op = Perl_pp_listen(aTHX); break;
	    case OP_ACCEPT:
		PL_op = Perl_pp_accept(aTHX); break;
	    case OP_SHUTDOWN:
		PL_op = Perl_pp_shutdown(aTHX); break;
	    case OP_GSOCKOPT:
		PL_op = Perl_pp_gsockopt(aTHX); break;
	    case OP_SSOCKOPT:
		PL_op = Perl_pp_ssockopt(aTHX); break;
	    case OP_GETSOCKNAME:
		PL_op = Perl_pp_getsockname(aTHX); break;
	    case OP_GETPEERNAME:
		PL_op = Perl_pp_getpeername(aTHX); break;
	    case OP_LSTAT:
		PL_op = Perl_pp_lstat(aTHX); break;
	    case OP_STAT:
		PL_op = Perl_pp_stat(aTHX); break;
	    case OP_FTRREAD:
		PL_op = Perl_pp_ftrread(aTHX); break;
	    case OP_FTRWRITE:
		PL_op = Perl_pp_ftrwrite(aTHX); break;
	    case OP_FTREXEC:
		PL_op = Perl_pp_ftrexec(aTHX); break;
	    case OP_FTEREAD:
		PL_op = Perl_pp_fteread(aTHX); break;
	    case OP_FTEWRITE:
		PL_op = Perl_pp_ftewrite(aTHX); break;
	    case OP_FTEEXEC:
		PL_op = Perl_pp_fteexec(aTHX); break;
	    case OP_FTIS:
		PL_op = Perl_pp_ftis(aTHX); break;
	    case OP_FTEOWNED:
		PL_op = Perl_pp_fteowned(aTHX); break;
	    case OP_FTROWNED:
		PL_op = Perl_pp_ftrowned(aTHX); break;
	    case OP_FTZERO:
		PL_op = Perl_pp_ftzero(aTHX); break;
	    case OP_FTSIZE:
		PL_op = Perl_pp_ftsize(aTHX); break;
	    case OP_FTMTIME:
		PL_op = Perl_pp_ftmtime(aTHX); break;
	    case OP_FTATIME:
		PL_op = Perl_pp_ftatime(aTHX); break;
	    case OP_FTCTIME:
		PL_op = Perl_pp_ftctime(aTHX); break;
	    case OP_FTSOCK:
		PL_op = Perl_pp_ftsock(aTHX); break;
	    case OP_FTCHR:
		PL_op = Perl_pp_ftchr(aTHX); break;
	    case OP_FTBLK:
		PL_op = Perl_pp_ftblk(aTHX); break;
	    case OP_FTFILE:
		PL_op = Perl_pp_ftfile(aTHX); break;
	    case OP_FTDIR:
		PL_op = Perl_pp_ftdir(aTHX); break;
	    case OP_FTPIPE:
		PL_op = Perl_pp_ftpipe(aTHX); break;
	    case OP_FTLINK:
		PL_op = Perl_pp_ftlink(aTHX); break;
	    case OP_FTSUID:
		PL_op = Perl_pp_ftsuid(aTHX); break;
	    case OP_FTSGID:
		PL_op = Perl_pp_ftsgid(aTHX); break;
	    case OP_FTSVTX:
		PL_op = Perl_pp_ftsvtx(aTHX); break;
	    case OP_FTTTY:
		PL_op = Perl_pp_fttty(aTHX); break;
	    case OP_FTTEXT:
		PL_op = Perl_pp_fttext(aTHX); break;
	    case OP_FTBINARY:
		PL_op = Perl_pp_ftbinary(aTHX); break;
	    case OP_CHDIR:
		PL_op = Perl_pp_chdir(aTHX); break;
	    case OP_CHOWN:
		PL_op = Perl_pp_chown(aTHX); break;
	    case OP_CHROOT:
		PL_op = Perl_pp_chroot(aTHX); break;
	    case OP_UNLINK:
		PL_op = Perl_pp_unlink(aTHX); break;
	    case OP_CHMOD:
		PL_op = Perl_pp_chmod(aTHX); break;
	    case OP_UTIME:
		PL_op = Perl_pp_utime(aTHX); break;
	    case OP_RENAME:
		PL_op = Perl_pp_rename(aTHX); break;
	    case OP_LINK:
		PL_op = Perl_pp_link(aTHX); break;
	    case OP_SYMLINK:
		PL_op = Perl_pp_symlink(aTHX); break;
	    case OP_READLINK:
		PL_op = Perl_pp_readlink(aTHX); break;
	    case OP_MKDIR:
		PL_op = Perl_pp_mkdir(aTHX); break;
	    case OP_RMDIR:
		PL_op = Perl_pp_rmdir(aTHX); break;
	    case OP_OPEN_DIR:
		PL_op = Perl_pp_open_dir(aTHX); break;
	    case OP_READDIR:
		PL_op = Perl_pp_readdir(aTHX); break;
	    case OP_TELLDIR:
		PL_op = Perl_pp_telldir(aTHX); break;
	    case OP_SEEKDIR:
		PL_op = Perl_pp_seekdir(aTHX); break;
	    case OP_REWINDDIR:
		PL_op = Perl_pp_rewinddir(aTHX); break;
	    case OP_CLOSEDIR:
		PL_op = Perl_pp_closedir(aTHX); break;
	    case OP_FORK:
		PL_op = Perl_pp_fork(aTHX); break;
	    case OP_WAIT:
		PL_op = Perl_pp_wait(aTHX); break;
	    case OP_WAITPID:
		PL_op = Perl_pp_waitpid(aTHX); break;
	    case OP_SYSTEM:
		PL_op = Perl_pp_system(aTHX); break;
	    case OP_EXEC:
		PL_op = Perl_pp_exec(aTHX); break;
	    case OP_KILL:
		PL_op = Perl_pp_kill(aTHX); break;
	    case OP_GETPPID:
		PL_op = Perl_pp_getppid(aTHX); break;
	    case OP_GETPGRP:
		PL_op = Perl_pp_getpgrp(aTHX); break;
	    case OP_SETPGRP:
		PL_op = Perl_pp_setpgrp(aTHX); break;
	    case OP_GETPRIORITY:
		PL_op = Perl_pp_getpriority(aTHX); break;
	    case OP_SETPRIORITY:
		PL_op = Perl_pp_setpriority(aTHX); break;
	    case OP_TIME:
		PL_op = Perl_pp_time(aTHX); break;
	    case OP_TMS:
		PL_op = Perl_pp_tms(aTHX); break;
	    case OP_LOCALTIME:
		PL_op = Perl_pp_localtime(aTHX); break;
	    case OP_GMTIME:
		PL_op = Perl_pp_gmtime(aTHX); break;
	    case OP_ALARM:
		PL_op = Perl_pp_alarm(aTHX); break;
	    case OP_SLEEP:
		PL_op = Perl_pp_sleep(aTHX); break;
	    case OP_SHMGET:
		PL_op = Perl_pp_shmget(aTHX); break;
	    case OP_SHMCTL:
		PL_op = Perl_pp_shmctl(aTHX); break;
	    case OP_SHMREAD:
		PL_op = Perl_pp_shmread(aTHX); break;
	    case OP_SHMWRITE:
		PL_op = Perl_pp_shmwrite(aTHX); break;
	    case OP_MSGGET:
		PL_op = Perl_pp_msgget(aTHX); break;
	    case OP_MSGCTL:
		PL_op = Perl_pp_msgctl(aTHX); break;
	    case OP_MSGSND:
		PL_op = Perl_pp_msgsnd(aTHX); break;
	    case OP_MSGRCV:
		PL_op = Perl_pp_msgrcv(aTHX); break;
	    case OP_SEMGET:
		PL_op = Perl_pp_semget(aTHX); break;
	    case OP_SEMCTL:
		PL_op = Perl_pp_semctl(aTHX); break;
	    case OP_SEMOP:
		PL_op = Perl_pp_semop(aTHX); break;
	    case OP_REQUIRE:
	    case OP_DOFILE:
		PL_op = Perl_pp_require(aTHX); break;
	    case OP_ENTEREVAL:
		PL_op = Perl_pp_entereval(aTHX); break;
	    case OP_LEAVEEVAL:
		PL_op = Perl_pp_leaveeval(aTHX); break;
	    case OP_ENTERTRY:
		PL_op = Perl_pp_entertry(aTHX); break;
	    case OP_LEAVETRY:
		PL_op = Perl_pp_leavetry(aTHX); break;
	    case OP_GHBYNAME:
		PL_op = Perl_pp_ghbyname(aTHX); break;
	    case OP_GHBYADDR:
		PL_op = Perl_pp_ghbyaddr(aTHX); break;
	    case OP_GHOSTENT:
		PL_op = Perl_pp_ghostent(aTHX); break;
	    case OP_GNBYNAME:
		PL_op = Perl_pp_gnbyname(aTHX); break;
	    case OP_GNBYADDR:
		PL_op = Perl_pp_gnbyaddr(aTHX); break;
	    case OP_GNETENT:
		PL_op = Perl_pp_gnetent(aTHX); break;
	    case OP_GPBYNAME:
		PL_op = Perl_pp_gpbyname(aTHX); break;
	    case OP_GPBYNUMBER:
		PL_op = Perl_pp_gpbynumber(aTHX); break;
	    case OP_GPROTOENT:
		PL_op = Perl_pp_gprotoent(aTHX); break;
	    case OP_GSBYNAME:
		PL_op = Perl_pp_gsbyname(aTHX); break;
	    case OP_GSBYPORT:
		PL_op = Perl_pp_gsbyport(aTHX); break;
	    case OP_GSERVENT:
		PL_op = Perl_pp_gservent(aTHX); break;
	    case OP_SHOSTENT:
		PL_op = Perl_pp_shostent(aTHX); break;
	    case OP_SNETENT:
		PL_op = Perl_pp_snetent(aTHX); break;
	    case OP_SPROTOENT:
		PL_op = Perl_pp_sprotoent(aTHX); break;
	    case OP_SSERVENT:
		PL_op = Perl_pp_sservent(aTHX); break;
	    case OP_EHOSTENT:
		PL_op = Perl_pp_ehostent(aTHX); break;
	    case OP_ENETENT:
		PL_op = Perl_pp_enetent(aTHX); break;
	    case OP_EPROTOENT:
		PL_op = Perl_pp_eprotoent(aTHX); break;
	    case OP_ESERVENT:
		PL_op = Perl_pp_eservent(aTHX); break;
	    case OP_GPWNAM:
		PL_op = Perl_pp_gpwnam(aTHX); break;
	    case OP_GPWUID:
		PL_op = Perl_pp_gpwuid(aTHX); break;
	    case OP_GPWENT:
		PL_op = Perl_pp_gpwent(aTHX); break;
	    case OP_SPWENT:
		PL_op = Perl_pp_spwent(aTHX); break;
	    case OP_EPWENT:
		PL_op = Perl_pp_epwent(aTHX); break;
	    case OP_GGRNAM:
		PL_op = Perl_pp_ggrnam(aTHX); break;
	    case OP_GGRGID:
		PL_op = Perl_pp_ggrgid(aTHX); break;
	    case OP_GGRENT:
		PL_op = Perl_pp_ggrent(aTHX); break;
	    case OP_SGRENT:
		PL_op = Perl_pp_sgrent(aTHX); break;
	    case OP_EGRENT:
		PL_op = Perl_pp_egrent(aTHX); break;
	    case OP_GETLOGIN:
		PL_op = Perl_pp_getlogin(aTHX); break;
	    case OP_SYSCALL:
		PL_op = Perl_pp_syscall(aTHX); break;
	    case OP_LOCK:
		PL_op = Perl_pp_lock(aTHX); break;
#if PERL_VERSION < 10
	    case OP_THREADSV:
		PL_op = Perl_pp_threadsv(aTHX); break;
#endif
	    case OP_SETSTATE:
		PL_curcop = (COP*)PL_op;
		PL_op = NORMAL;
		break;
	    case OP_METHOD_NAMED:
		PL_op = Perl_pp_method_named(aTHX); break;
#if PERL_VERSION >= 9
	    case OP_DOR:
		PL_op = Perl_pp_dor(aTHX); break;
	    case OP_DORASSIGN:
		PL_op = Perl_pp_dorassign(aTHX); break;
#endif
#if PERL_VERSION >= 10
	    case OP_ENTERGIVEN:
		PL_op = Perl_pp_entergiven(aTHX); break;
	    case OP_LEAVEGIVEN:
		PL_op = Perl_pp_leavegiven(aTHX); break;
	    case OP_ENTERWHEN:
		PL_op = Perl_pp_enterwhen(aTHX); break;
	    case OP_LEAVEWHEN:
		PL_op = Perl_pp_leavewhen(aTHX); break;
	    case OP_BREAK:
		PL_op = Perl_pp_break(aTHX); break;
	    case OP_CONTINUE:
		PL_op = Perl_pp_continue(aTHX); break;
	    case OP_SMARTMATCH:
		PL_op = Perl_pp_smartmatch(aTHX); break;
	    case OP_ONCE:
		PL_op = Perl_pp_once(aTHX); break;
#endif
	    case OP_CUSTOM:
		PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX); break;
	    default:
		Perl_croak(aTHX_ "Invalid opcode '%s'\n", OP_NAME(PL_op));
	}
	PERL_ASYNC_CHECK();
    }
    TAINT_NOT;
    return 0;
}

MODULE = Runops::Switch PACKAGE = Runops::Switch

BOOT:
    PL_runops = runops_switch;
