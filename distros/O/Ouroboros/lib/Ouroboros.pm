package Ouroboros;

use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    ouroboros_stack_init_ptr
    ouroboros_stack_items_ptr
    ouroboros_stack_putback_ptr
    ouroboros_stack_fetch_ptr
    ouroboros_stack_store_ptr
    ouroboros_stack_extend_ptr
    ouroboros_stack_pushmark_ptr
    ouroboros_stack_spagain_ptr
    ouroboros_stack_xpush_sv_ptr
    ouroboros_stack_xpush_sv_mortal_ptr
    ouroboros_stack_xpush_iv_ptr
    ouroboros_stack_xpush_uv_ptr
    ouroboros_stack_xpush_nv_ptr
    ouroboros_stack_xpush_pv_ptr
    ouroboros_stack_xpush_mortal_ptr
    ouroboros_stack_push_sv_ptr
    ouroboros_stack_push_sv_mortal_ptr
    ouroboros_stack_push_iv_ptr
    ouroboros_stack_push_uv_ptr
    ouroboros_stack_push_nv_ptr
    ouroboros_stack_push_pv_ptr
    ouroboros_stack_push_mortal_ptr
    ouroboros_sv_upgrade_ptr
    ouroboros_sv_niok_ptr
    ouroboros_sv_niok_priv_ptr
    ouroboros_sv_niok_off_ptr
    ouroboros_sv_ok_ptr
    ouroboros_sv_iok_priv_ptr
    ouroboros_sv_nok_priv_ptr
    ouroboros_sv_pok_priv_ptr
    ouroboros_sv_iok_ptr
    ouroboros_sv_iok_on_ptr
    ouroboros_sv_iok_off_ptr
    ouroboros_sv_iok_only_ptr
    ouroboros_sv_iok_only_uv_ptr
    ouroboros_sv_iok_uv_ptr
    ouroboros_sv_uok_ptr
    ouroboros_sv_iok_not_uv_ptr
    ouroboros_sv_nok_ptr
    ouroboros_sv_nok_on_ptr
    ouroboros_sv_nok_off_ptr
    ouroboros_sv_nok_only_ptr
    ouroboros_sv_pok_ptr
    ouroboros_sv_pok_on_ptr
    ouroboros_sv_pok_off_ptr
    ouroboros_sv_pok_only_ptr
    ouroboros_sv_pok_only_utf8_ptr
    ouroboros_sv_vok_ptr
    ouroboros_sv_ook_ptr
    ouroboros_sv_ook_offset_ptr
    ouroboros_sv_rok_ptr
    ouroboros_sv_rok_on_ptr
    ouroboros_sv_rok_off_ptr
    ouroboros_sv_iv_ptr
    ouroboros_sv_iv_nomg_ptr
    ouroboros_sv_iv_raw_ptr
    ouroboros_sv_iv_set_ptr
    ouroboros_sv_uv_ptr
    ouroboros_sv_uv_nomg_ptr
    ouroboros_sv_uv_raw_ptr
    ouroboros_sv_uv_set_ptr
    ouroboros_sv_nv_ptr
    ouroboros_sv_nv_nomg_ptr
    ouroboros_sv_nv_raw_ptr
    ouroboros_sv_nv_set_ptr
    ouroboros_sv_pv_ptr
    ouroboros_sv_pv_nomg_ptr
    ouroboros_sv_pv_nolen_ptr
    ouroboros_sv_pv_nomg_nolen_ptr
    ouroboros_sv_pv_raw_ptr
    ouroboros_sv_pv_cur_ptr
    ouroboros_sv_pv_cur_set_ptr
    ouroboros_sv_pv_len_ptr
    ouroboros_sv_pv_len_set_ptr
    ouroboros_sv_pv_end_ptr
    ouroboros_sv_rv_ptr
    ouroboros_sv_rv_set_ptr
    ouroboros_sv_true_ptr
    ouroboros_sv_true_nomg_ptr
    ouroboros_sv_type_ptr
    ouroboros_sv_flags_ptr
    ouroboros_sv_utf8_ptr
    ouroboros_sv_utf8_on_ptr
    ouroboros_sv_utf8_off_ptr
    ouroboros_sv_is_cow_ptr
    ouroboros_sv_is_cow_shared_hash_ptr
    ouroboros_sv_tainted_ptr
    ouroboros_sv_tainted_on_ptr
    ouroboros_sv_tainted_off_ptr
    ouroboros_sv_taint_ptr
    ouroboros_sv_share_ptr
    ouroboros_sv_lock_ptr
    ouroboros_sv_unlock_ptr
    ouroboros_sv_get_a_magic_ptr
    ouroboros_sv_magic_set_ptr
    ouroboros_sv_get_magic_ptr
    ouroboros_sv_set_magic_ptr
    ouroboros_gv_sv_ptr
    ouroboros_gv_av_ptr
    ouroboros_gv_hv_ptr
    ouroboros_gv_cv_ptr
    ouroboros_sv_stash_ptr
    ouroboros_sv_stash_set_ptr
    ouroboros_cv_stash_ptr
    ouroboros_hv_name_ptr
    ouroboros_hv_name_len_ptr
    ouroboros_hv_name_utf8_ptr
    ouroboros_hv_ename_ptr
    ouroboros_hv_ename_len_ptr
    ouroboros_hv_ename_utf8_ptr
    ouroboros_he_pv_ptr
    ouroboros_he_val_ptr
    ouroboros_he_hash_ptr
    ouroboros_he_svkey_ptr
    ouroboros_he_svkey_force_ptr
    ouroboros_he_svkey_set_ptr
    ouroboros_perl_hash_ptr
    ouroboros_sv_refcnt_ptr
    ouroboros_sv_refcnt_inc_ptr
    ouroboros_sv_refcnt_inc_nn_ptr
    ouroboros_sv_refcnt_inc_void_ptr
    ouroboros_sv_refcnt_inc_void_nn_ptr
    ouroboros_sv_refcnt_dec_ptr
    ouroboros_sv_refcnt_dec_nn_ptr
    ouroboros_enter_ptr
    ouroboros_leave_ptr
    ouroboros_savetmps_ptr
    ouroboros_freetmps_ptr
    ouroboros_sys_init3_ptr
    ouroboros_sys_term_ptr
    ouroboros_sv_undef_ptr
    ouroboros_sv_no_ptr
    ouroboros_sv_yes_ptr
    ouroboros_gimme_ptr
    ouroboros_xcpt_try_ptr
    ouroboros_xcpt_rethrow_ptr
);

our @CONSTS;

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    const => \@CONSTS,
);

our @EXPORT = qw();

our $VERSION = "0.14";

require XSLoader;
XSLoader::load('Ouroboros', $VERSION);

# XS bootstrap pushes to @CONSTS, this must come after XSLoader::load().  While
# ExtUtils::Constant generates code to check if constant exists or not at
# compile time, it still pushes them into the array for some reason.
# Here, we only need constants that are actually available.
@CONSTS = grep defined eval "$_", @CONSTS;

push @EXPORT_OK, @CONSTS;

1;
__END__

=head1 NAME

Ouroboros - Perl XS macros re-exported as C functions

=head1 DESCRIPTION

libouroboros is a library of C functions wrapping XS macros. This package
provides pointers to these functions, so Perl programs can have access to
internal Perl methods (e.g. SvIV) at run-time. In combination with a JIT-
compiler it allows Perl programs to build XS-like subroutines completely at
run-time, without the need for a C compiler or a build environment.

=head2 Thread context

All wrappers accept thread context as a first argument, as defined by pTHX XS
macro, even if pTHX is not part of the wrapped macro definition.

Two exceptions to this are C<ouroboros_sys_init3> and C<ouroboros_sys_term>,
since they are called in embedded Perl scenario at times when Perl interpreter
object does not exist.

=head2 The stack

C<libouroboros> encapsulates local stack state kept by XS inside the stack
object: C<ouroboros_stack_t> type and a number of method functions. Storage
can be allocated on caller's stack or in heap, and should be initialized first
by calling C<ouroboros_stack_init()>.

Minimum storage size for C<ouroboros_stack_t> is available as
C<$Ouroboros::SIZE_OF{ouroboros_stack_t}>. Exact layout is intentionally
unspecified, user program should treat this type as an opaque object and only
use provided methods to manipulate it.

=head2 Type sizes

Sizes for most primitive data types used by Perl are available via L<Config>
and supplemented by C<%Ouroboros::SIZE_OF> hash.

=head2 Exception handling

See L</ouroboros_xcpt_try> and L</ouroboros_xcpt_rethrow>.

=head1 EXPORTS

Nothing is exported by default.

C<:all> tag exports all methods and constants.

C<:consts> tag exports constants only.

=head1 METHODS

Every sub listed here returns a pointer to a C function with a signature as
provided.

=over

=item ouroboros_stack_init_ptr

    OUROBOROS_STATIC void ouroboros_stack_init(pTHX_ ouroboros_stack_t*);

Initialize ouroboros_stack_t object. Must be first thing called by a XS-sub. Equivalent to C<dXSARGS> macro automatically inserted by C<xsubpp> into every XS sub.

=item ouroboros_stack_items_ptr

    OUROBOROS_STATIC int ouroboros_stack_items(pTHX_ ouroboros_stack_t*);

Returns number of arguments on Perl stack. Equivalent to C<items> local variable in XS.

=item ouroboros_stack_putback_ptr

    OUROBOROS_STATIC void ouroboros_stack_putback(pTHX_ ouroboros_stack_t*);

Perl macro: C<PUTBACK>

=item ouroboros_stack_fetch_ptr

    OUROBOROS_STATIC SV* ouroboros_stack_fetch(pTHX_ ouroboros_stack_t*, SSize_t);

Read a value from the stack. Equivalent of:

    return ST(a);

Perl macro: C<ST(n)>

=item ouroboros_stack_store_ptr

    OUROBOROS_STATIC void ouroboros_stack_store(pTHX_ ouroboros_stack_t*, SSize_t, SV*);

Store a value on the stack. Equivalent of:

    ST(a) = sv;

Perl macro: C<ST>

=item ouroboros_stack_extend_ptr

    OUROBOROS_STATIC void ouroboros_stack_extend(pTHX_ ouroboros_stack_t*, SSize_t);

Perl macro: C<EXTEND>

=item ouroboros_stack_pushmark_ptr

    OUROBOROS_STATIC void ouroboros_stack_pushmark(pTHX_ ouroboros_stack_t*);

Perl macro: C<PUSHMARK>

=item ouroboros_stack_spagain_ptr

    OUROBOROS_STATIC void ouroboros_stack_spagain(pTHX_ ouroboros_stack_t*);

Perl macro: C<SPAGAIN>

=item ouroboros_stack_xpush_sv_ptr

    OUROBOROS_STATIC void ouroboros_stack_xpush_sv(pTHX_ ouroboros_stack_t*, SV*);

Perl macro: C<XPUSHs>

=item ouroboros_stack_xpush_sv_mortal_ptr

    OUROBOROS_STATIC void ouroboros_stack_xpush_sv_mortal(pTHX_ ouroboros_stack_t*, SV*);

Perl macro: C<mXPUSHs>

=item ouroboros_stack_xpush_iv_ptr

    OUROBOROS_STATIC void ouroboros_stack_xpush_iv(pTHX_ ouroboros_stack_t*, IV);

Perl macro: C<mXPUSHi>

=item ouroboros_stack_xpush_uv_ptr

    OUROBOROS_STATIC void ouroboros_stack_xpush_uv(pTHX_ ouroboros_stack_t*, UV);

Perl macro: C<mXPUSHu>

=item ouroboros_stack_xpush_nv_ptr

    OUROBOROS_STATIC void ouroboros_stack_xpush_nv(pTHX_ ouroboros_stack_t*, NV);

Perl macro: C<mXPUSHn>

=item ouroboros_stack_xpush_pv_ptr

    OUROBOROS_STATIC void ouroboros_stack_xpush_pv(pTHX_ ouroboros_stack_t*, const char*, STRLEN);

Perl macro: C<mXPUSHp>

=item ouroboros_stack_xpush_mortal_ptr

    OUROBOROS_STATIC void ouroboros_stack_xpush_mortal(pTHX_ ouroboros_stack_t*);

Perl macro: C<XPUSHmortal>

=item ouroboros_stack_push_sv_ptr

    OUROBOROS_STATIC void ouroboros_stack_push_sv(pTHX_ ouroboros_stack_t*, SV*);

Perl macro: C<PUSHs>

=item ouroboros_stack_push_sv_mortal_ptr

    OUROBOROS_STATIC void ouroboros_stack_push_sv_mortal(pTHX_ ouroboros_stack_t*, SV*);

Perl macro: C<mPUSHs>

=item ouroboros_stack_push_iv_ptr

    OUROBOROS_STATIC void ouroboros_stack_push_iv(pTHX_ ouroboros_stack_t*, IV);

Perl macro: C<mPUSHi>

=item ouroboros_stack_push_uv_ptr

    OUROBOROS_STATIC void ouroboros_stack_push_uv(pTHX_ ouroboros_stack_t*, UV);

Perl macro: C<mPUSHu>

=item ouroboros_stack_push_nv_ptr

    OUROBOROS_STATIC void ouroboros_stack_push_nv(pTHX_ ouroboros_stack_t*, NV);

Perl macro: C<mPUSHn>

=item ouroboros_stack_push_pv_ptr

    OUROBOROS_STATIC void ouroboros_stack_push_pv(pTHX_ ouroboros_stack_t*, const char*, STRLEN);

Perl macro: C<mPUSHp>

=item ouroboros_stack_push_mortal_ptr

    OUROBOROS_STATIC void ouroboros_stack_push_mortal(pTHX_ ouroboros_stack_t*);

Perl macro: C<PUSHmortal>

=item ouroboros_sv_upgrade_ptr

    OUROBOROS_STATIC void ouroboros_sv_upgrade(pTHX_ SV*, svtype);

Perl macro: C<SvUPGRADE>

=item ouroboros_sv_niok_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_niok(pTHX_ SV*);

Perl macro: C<SvNIOK>

=item ouroboros_sv_niok_priv_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_niok_priv(pTHX_ SV*);

Perl macro: C<SvNIOKp>

=item ouroboros_sv_niok_off_ptr

    OUROBOROS_STATIC void ouroboros_sv_niok_off(pTHX_ SV*);

Perl macro: C<SvNIOK_off>

=item ouroboros_sv_ok_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_ok(pTHX_ SV*);

Perl macro: C<SvOK>

=item ouroboros_sv_iok_priv_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_iok_priv(pTHX_ SV*);

Perl macro: C<SvIOKp>

=item ouroboros_sv_nok_priv_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_nok_priv(pTHX_ SV*);

Perl macro: C<SvNOKp>

=item ouroboros_sv_pok_priv_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_pok_priv(pTHX_ SV*);

Perl macro: C<SvPOKp>

=item ouroboros_sv_iok_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_iok(pTHX_ SV*);

Perl macro: C<SvIOK>

=item ouroboros_sv_iok_on_ptr

    OUROBOROS_STATIC void ouroboros_sv_iok_on(pTHX_ SV*);

Perl macro: C<SvIOK_on>

=item ouroboros_sv_iok_off_ptr

    OUROBOROS_STATIC void ouroboros_sv_iok_off(pTHX_ SV*);

Perl macro: C<SvIOK_off>

=item ouroboros_sv_iok_only_ptr

    OUROBOROS_STATIC void ouroboros_sv_iok_only(pTHX_ SV*);

Perl macro: C<SvIOK_only>

=item ouroboros_sv_iok_only_uv_ptr

    OUROBOROS_STATIC void ouroboros_sv_iok_only_uv(pTHX_ SV*);

Perl macro: C<SvIOK_only_UV>

=item ouroboros_sv_iok_uv_ptr

    OUROBOROS_STATIC bool ouroboros_sv_iok_uv(pTHX_ SV*);

Perl macro: C<SvIOK_UV>

=item ouroboros_sv_uok_ptr

    OUROBOROS_STATIC bool ouroboros_sv_uok(pTHX_ SV*);

Perl macro: C<SvUOK>

=item ouroboros_sv_iok_not_uv_ptr

    OUROBOROS_STATIC bool ouroboros_sv_iok_not_uv(pTHX_ SV*);

Perl macro: C<SvIOK_notUV>

=item ouroboros_sv_nok_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_nok(pTHX_ SV*);

Perl macro: C<SvNOK>

=item ouroboros_sv_nok_on_ptr

    OUROBOROS_STATIC void ouroboros_sv_nok_on(pTHX_ SV*);

Perl macro: C<SvNOK_on>

=item ouroboros_sv_nok_off_ptr

    OUROBOROS_STATIC void ouroboros_sv_nok_off(pTHX_ SV*);

Perl macro: C<SvNOK_off>

=item ouroboros_sv_nok_only_ptr

    OUROBOROS_STATIC void ouroboros_sv_nok_only(pTHX_ SV*);

Perl macro: C<SvNOK_only>

=item ouroboros_sv_pok_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_pok(pTHX_ SV*);

Perl macro: C<SvPOK>

=item ouroboros_sv_pok_on_ptr

    OUROBOROS_STATIC void ouroboros_sv_pok_on(pTHX_ SV*);

Perl macro: C<SvPOK_on>

=item ouroboros_sv_pok_off_ptr

    OUROBOROS_STATIC void ouroboros_sv_pok_off(pTHX_ SV*);

Perl macro: C<SvPOK_off>

=item ouroboros_sv_pok_only_ptr

    OUROBOROS_STATIC void ouroboros_sv_pok_only(pTHX_ SV*);

Perl macro: C<SvPOK_only>

=item ouroboros_sv_pok_only_utf8_ptr

    OUROBOROS_STATIC void ouroboros_sv_pok_only_utf8(pTHX_ SV*);

Perl macro: C<SvPOK_only_UTF8>

=item ouroboros_sv_vok_ptr

    OUROBOROS_STATIC bool ouroboros_sv_vok(pTHX_ SV*);

Perl macro: C<SvVOK>

=item ouroboros_sv_ook_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_ook(pTHX_ SV*);

Perl macro: C<SvOOK>

=item ouroboros_sv_ook_offset_ptr

    OUROBOROS_STATIC void ouroboros_sv_ook_offset(pTHX_ SV*, STRLEN*);

Perl macro: C<SvOOK_offset>

=item ouroboros_sv_rok_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_rok(pTHX_ SV*);

Perl macro: C<SvROK>

=item ouroboros_sv_rok_on_ptr

    OUROBOROS_STATIC void ouroboros_sv_rok_on(pTHX_ SV*);

Perl macro: C<SvROK_on>

=item ouroboros_sv_rok_off_ptr

    OUROBOROS_STATIC void ouroboros_sv_rok_off(pTHX_ SV*);

Perl macro: C<SvROK_off>

=item ouroboros_sv_iv_ptr

    OUROBOROS_STATIC IV ouroboros_sv_iv(pTHX_ SV*);

Perl macro: C<SvIV>

=item ouroboros_sv_iv_nomg_ptr

    OUROBOROS_STATIC IV ouroboros_sv_iv_nomg(pTHX_ SV*);

Perl macro: C<SvIV_nomg>

=item ouroboros_sv_iv_raw_ptr

    OUROBOROS_STATIC IV ouroboros_sv_iv_raw(pTHX_ SV*);

Perl macro: C<SvIVX>

=item ouroboros_sv_iv_set_ptr

    OUROBOROS_STATIC void ouroboros_sv_iv_set(pTHX_ SV*, IV);

Perl macro: C<SvIV_set>

=item ouroboros_sv_uv_ptr

    OUROBOROS_STATIC UV ouroboros_sv_uv(pTHX_ SV*);

Perl macro: C<SvUV>

=item ouroboros_sv_uv_nomg_ptr

    OUROBOROS_STATIC UV ouroboros_sv_uv_nomg(pTHX_ SV*);

Perl macro: C<SvUV_nomg>

=item ouroboros_sv_uv_raw_ptr

    OUROBOROS_STATIC UV ouroboros_sv_uv_raw(pTHX_ SV*);

Perl macro: C<SvUVX>

=item ouroboros_sv_uv_set_ptr

    OUROBOROS_STATIC void ouroboros_sv_uv_set(pTHX_ SV*, UV);

Perl macro: C<SvUV_set>

=item ouroboros_sv_nv_ptr

    OUROBOROS_STATIC NV ouroboros_sv_nv(pTHX_ SV*);

Perl macro: C<SvNV>

=item ouroboros_sv_nv_nomg_ptr

    OUROBOROS_STATIC NV ouroboros_sv_nv_nomg(pTHX_ SV*);

Perl macro: C<SvNV_nomg>

=item ouroboros_sv_nv_raw_ptr

    OUROBOROS_STATIC NV ouroboros_sv_nv_raw(pTHX_ SV*);

Perl macro: C<SvNVX>

=item ouroboros_sv_nv_set_ptr

    OUROBOROS_STATIC void ouroboros_sv_nv_set(pTHX_ SV*, NV);

Perl macro: C<SvNV_set>

=item ouroboros_sv_pv_ptr

    OUROBOROS_STATIC const char* ouroboros_sv_pv(pTHX_ SV*, STRLEN*);

Perl macro: C<SvPV>

=item ouroboros_sv_pv_nomg_ptr

    OUROBOROS_STATIC const char* ouroboros_sv_pv_nomg(pTHX_ SV*, STRLEN*);

Perl macro: C<SvPV_nomg>

=item ouroboros_sv_pv_nolen_ptr

    OUROBOROS_STATIC const char* ouroboros_sv_pv_nolen(pTHX_ SV*);

Perl macro: C<SvPV_nolen>

=item ouroboros_sv_pv_nomg_nolen_ptr

    OUROBOROS_STATIC const char* ouroboros_sv_pv_nomg_nolen(pTHX_ SV*);

Perl macro: C<SvPV_nomg_nolen>

=item ouroboros_sv_pv_raw_ptr

    OUROBOROS_STATIC char* ouroboros_sv_pv_raw(pTHX_ SV*);

Perl macro: C<SvPVX>

=item ouroboros_sv_pv_cur_ptr

    OUROBOROS_STATIC STRLEN ouroboros_sv_pv_cur(pTHX_ SV*);

Perl macro: C<SvCUR>

=item ouroboros_sv_pv_cur_set_ptr

    OUROBOROS_STATIC void ouroboros_sv_pv_cur_set(pTHX_ SV*, STRLEN);

Perl macro: C<SvCUR_set>

=item ouroboros_sv_pv_len_ptr

    OUROBOROS_STATIC STRLEN ouroboros_sv_pv_len(pTHX_ SV*);

Perl macro: C<SvLEN>

=item ouroboros_sv_pv_len_set_ptr

    OUROBOROS_STATIC void ouroboros_sv_pv_len_set(pTHX_ SV*, STRLEN);

Perl macro: C<SvLEN_set>

=item ouroboros_sv_pv_end_ptr

    OUROBOROS_STATIC char* ouroboros_sv_pv_end(pTHX_ SV*);

Perl macro: C<SvEND>

=item ouroboros_sv_rv_ptr

    OUROBOROS_STATIC SV* ouroboros_sv_rv(pTHX_ SV*);

Perl macro: C<SvRV>

=item ouroboros_sv_rv_set_ptr

    OUROBOROS_STATIC void ouroboros_sv_rv_set(pTHX_ SV*, SV*);

Perl macro: C<SvRV_set>

=item ouroboros_sv_true_ptr

    OUROBOROS_STATIC bool ouroboros_sv_true(pTHX_ SV*);

Perl macro: C<SvTRUE>

=item ouroboros_sv_true_nomg_ptr

    OUROBOROS_STATIC bool ouroboros_sv_true_nomg(pTHX_ SV*);

Perl macro: C<SvTRUE_nomg>

=item ouroboros_sv_type_ptr

    OUROBOROS_STATIC svtype ouroboros_sv_type(pTHX_ SV*);

Perl macro: C<SvTYPE>

=item ouroboros_sv_flags_ptr

    OUROBOROS_STATIC UV ouroboros_sv_flags(pTHX_ SV*);

Perl macro: C<SvFLAGS>

=item ouroboros_sv_utf8_ptr

    OUROBOROS_STATIC bool ouroboros_sv_utf8(pTHX_ SV*);

Perl macro: C<SvUTF8>

=item ouroboros_sv_utf8_on_ptr

    OUROBOROS_STATIC void ouroboros_sv_utf8_on(pTHX_ SV*);

Perl macro: C<SvUTF8_on>

=item ouroboros_sv_utf8_off_ptr

    OUROBOROS_STATIC void ouroboros_sv_utf8_off(pTHX_ SV*);

Perl macro: C<SvUTF8_off>

=item ouroboros_sv_is_cow_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_is_cow(pTHX_ SV*);

Perl macro: C<SvIsCOW>

=item ouroboros_sv_is_cow_shared_hash_ptr

    OUROBOROS_STATIC bool ouroboros_sv_is_cow_shared_hash(pTHX_ SV*);

Perl macro: C<SvIsCOW_shared_hash>

=item ouroboros_sv_tainted_ptr

    OUROBOROS_STATIC bool ouroboros_sv_tainted(pTHX_ SV*);

Perl macro: C<SvTAINTED>

=item ouroboros_sv_tainted_on_ptr

    OUROBOROS_STATIC void ouroboros_sv_tainted_on(pTHX_ SV*);

Perl macro: C<SvTAINTED_on>

=item ouroboros_sv_tainted_off_ptr

    OUROBOROS_STATIC void ouroboros_sv_tainted_off(pTHX_ SV*);

Perl macro: C<SvTAINTED_off>

=item ouroboros_sv_taint_ptr

    OUROBOROS_STATIC void ouroboros_sv_taint(pTHX_ SV*);

Perl macro: C<SvTAINT>

=item ouroboros_sv_share_ptr

    OUROBOROS_STATIC void ouroboros_sv_share(pTHX_ SV*);

Perl macro: C<SvSHARE>

=item ouroboros_sv_lock_ptr

    OUROBOROS_STATIC void ouroboros_sv_lock(pTHX_ SV*);

Perl macro: C<SvLOCK>

=item ouroboros_sv_unlock_ptr

    OUROBOROS_STATIC void ouroboros_sv_unlock(pTHX_ SV*);

Perl macro: C<SvUNLOCK>

=item ouroboros_sv_get_a_magic_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_get_a_magic(pTHX_ SV*);

Perl macro: C<SvGAMAGIC>

=item ouroboros_sv_magic_set_ptr

    OUROBOROS_STATIC void ouroboros_sv_magic_set(pTHX_ SV*, MAGIC*);

Perl macro: C<SvMAGIC_set>

=item ouroboros_sv_get_magic_ptr

    OUROBOROS_STATIC void ouroboros_sv_get_magic(pTHX_ SV*);

Perl macro: C<SvGETMAGIC>

=item ouroboros_sv_set_magic_ptr

    OUROBOROS_STATIC void ouroboros_sv_set_magic(pTHX_ SV*);

Perl macro: C<SvSETMAGIC>

=item ouroboros_gv_sv_ptr

    OUROBOROS_STATIC SV* ouroboros_gv_sv(pTHX_ GV*);

Perl macro: C<GvSV>

=item ouroboros_gv_av_ptr

    OUROBOROS_STATIC AV* ouroboros_gv_av(pTHX_ GV*);

Perl macro: C<GvAV>

=item ouroboros_gv_hv_ptr

    OUROBOROS_STATIC HV* ouroboros_gv_hv(pTHX_ GV*);

Perl macro: C<GvHV>

=item ouroboros_gv_cv_ptr

    OUROBOROS_STATIC CV* ouroboros_gv_cv(pTHX_ CV*);

Perl macro: C<GvCV>

=item ouroboros_sv_stash_ptr

    OUROBOROS_STATIC HV* ouroboros_sv_stash(pTHX_ SV*);

Perl macro: C<SvSTASH>

=item ouroboros_sv_stash_set_ptr

    OUROBOROS_STATIC void ouroboros_sv_stash_set(pTHX_ SV*, HV*);

Perl macro: C<SvSTASH_set>

=item ouroboros_cv_stash_ptr

    OUROBOROS_STATIC HV* ouroboros_cv_stash(pTHX_ CV*);

Perl macro: C<CvSTASH>

=item ouroboros_hv_name_ptr

    OUROBOROS_STATIC const char* ouroboros_hv_name(pTHX_ HV*);

Perl macro: C<HvNAME>

=item ouroboros_hv_name_len_ptr

    OUROBOROS_STATIC STRLEN ouroboros_hv_name_len(pTHX_ HV*);

Perl macro: C<HvNAMELEN>

=item ouroboros_hv_name_utf8_ptr

    OUROBOROS_STATIC unsigned char ouroboros_hv_name_utf8(pTHX_ HV*);

Perl macro: C<HvNAMEUTF8>

=item ouroboros_hv_ename_ptr

    OUROBOROS_STATIC const char* ouroboros_hv_ename(pTHX_ HV*);

Perl macro: C<HvENAME>

=item ouroboros_hv_ename_len_ptr

    OUROBOROS_STATIC STRLEN ouroboros_hv_ename_len(pTHX_ HV*);

Perl macro: C<HvENAMELEN>

=item ouroboros_hv_ename_utf8_ptr

    OUROBOROS_STATIC unsigned char ouroboros_hv_ename_utf8(pTHX_ HV*);

Perl macro: C<HvENAMEUTF8>

=item ouroboros_he_pv_ptr

    OUROBOROS_STATIC const char* ouroboros_he_pv(pTHX_ HE*, STRLEN*);

Perl macro: C<HePV>

=item ouroboros_he_val_ptr

    OUROBOROS_STATIC SV* ouroboros_he_val(pTHX_ HE*);

Perl macro: C<HeVAL>

=item ouroboros_he_hash_ptr

    OUROBOROS_STATIC U32 ouroboros_he_hash(pTHX_ HE*);

Perl macro: C<HeHASH>

=item ouroboros_he_svkey_ptr

    OUROBOROS_STATIC SV* ouroboros_he_svkey(pTHX_ HE*);

Perl macro: C<HeSVKEY>

=item ouroboros_he_svkey_force_ptr

    OUROBOROS_STATIC SV* ouroboros_he_svkey_force(pTHX_ HE*);

Perl macro: C<HeSVKEY_force>

=item ouroboros_he_svkey_set_ptr

    OUROBOROS_STATIC SV* ouroboros_he_svkey_set(pTHX_ HE*, SV*);

Perl macro: C<HeSVKEY_set>

=item ouroboros_perl_hash_ptr

    OUROBOROS_STATIC U32 ouroboros_perl_hash(pTHX_ U8*, STRLEN);

Unlike macro, returns hash value instead of assigning it to an argument.

Perl macro: C<PERL_HASH>

=item ouroboros_sv_refcnt_ptr

    OUROBOROS_STATIC U32 ouroboros_sv_refcnt(pTHX_ SV*);

Perl macro: C<SvREFCNT>

=item ouroboros_sv_refcnt_inc_ptr

    OUROBOROS_STATIC SV* ouroboros_sv_refcnt_inc(pTHX_ SV*);

Perl macro: C<SvREFCNT_inc_simple>

=item ouroboros_sv_refcnt_inc_nn_ptr

    OUROBOROS_STATIC SV* ouroboros_sv_refcnt_inc_nn(pTHX_ SV*);

Perl macro: C<SvREFCNT_inc_simple_NN>

=item ouroboros_sv_refcnt_inc_void_ptr

    OUROBOROS_STATIC void ouroboros_sv_refcnt_inc_void(pTHX_ SV*);

Perl macro: C<SvREFCNT_inc_simple_void>

=item ouroboros_sv_refcnt_inc_void_nn_ptr

    OUROBOROS_STATIC void ouroboros_sv_refcnt_inc_void_nn(pTHX_ SV*);

Perl macro: C<SvREFCNT_inc_simple_void_NN>

=item ouroboros_sv_refcnt_dec_ptr

    OUROBOROS_STATIC void ouroboros_sv_refcnt_dec(pTHX_ SV*);

Perl macro: C<SvREFCNT_dec>

=item ouroboros_sv_refcnt_dec_nn_ptr

    OUROBOROS_STATIC void ouroboros_sv_refcnt_dec_nn(pTHX_ SV*);

Perl macro: C<SvREFCNT_dec_NN>

=item ouroboros_enter_ptr

    OUROBOROS_STATIC void ouroboros_enter(pTHX);

Perl macro: C<ENTER>

=item ouroboros_leave_ptr

    OUROBOROS_STATIC void ouroboros_leave(pTHX);

Perl macro: C<LEAVE>

=item ouroboros_savetmps_ptr

    OUROBOROS_STATIC void ouroboros_savetmps(pTHX);

Perl macro: C<SAVETMPS>

=item ouroboros_freetmps_ptr

    OUROBOROS_STATIC void ouroboros_freetmps(pTHX);

Perl macro: C<FREETMPS>

=item ouroboros_sys_init3_ptr

    OUROBOROS_STATIC void ouroboros_sys_init3(int*, char***, char***);

Perl macro: C<PERL_SYS_INIT3>

=item ouroboros_sys_term_ptr

    OUROBOROS_STATIC void ouroboros_sys_term();

Perl macro: C<PERL_SYS_TERM>

=item ouroboros_sv_undef_ptr

    OUROBOROS_STATIC SV* ouroboros_sv_undef(pTHX);

Return address of C<PL_sv_undef> global.

=item ouroboros_sv_no_ptr

    OUROBOROS_STATIC SV* ouroboros_sv_no(pTHX);

Return address of C<PL_sv_no> global.

=item ouroboros_sv_yes_ptr

    OUROBOROS_STATIC SV* ouroboros_sv_yes(pTHX);

Return address of C<PL_sv_yes> global.

=item ouroboros_gimme_ptr

    OUROBOROS_STATIC U32 ouroboros_gimme(pTHX);

Perl macro: C<GIMME_V>

=item ouroboros_xcpt_try_ptr

    OUROBOROS_STATIC int ouroboros_xcpt_try(pTHX_ ouroboros_xcpt_callback_t, void*);

Execute callback once while capturing Perl exceptions. Second argument is passed to the callback as is and can be NULL.

This is equivalent of C<XCPT_TRY_START> and C<XCPT_TRY_END> macros, see L<perlguts/Exception Handling>.

Returns zero if callback was executed successfully and no Perl exceptions were thrown.

Returns non-zero if Perl exception was thrown while executing callback. After doing cleanups, this value must be passed to L</ouroboros_xcpt_rethrow>.

Perl macro: C<XCPT_TRY_START> and C<XCPT_TRY_END>

=item ouroboros_xcpt_rethrow_ptr

    OUROBOROS_STATIC void ouroboros_xcpt_rethrow(pTHX_ int);

Continue exception unwinding after unsuccessful call to L</ouroboros_xcpt_try>.

Perl macro: C<XCPT_RETHROW>



=back

=head1 CONSTANTS

This package also provides a number of consants from XS API. Some constants may
not be available, depending on the Perl version used.

C<@Ouroboros::CONSTS> contains names of all constants provided by this package.

=over

=item C<SVt_NULL>

=item C<SVt_IV>

=item C<SVt_NV>

=item C<SVt_PV>

=item C<SVt_PVIV>

=item C<SVt_PVNV>

=item C<SVt_PVMG>

=item C<SVt_REGEXP>

=item C<SVt_PVGV>

=item C<SVt_PVLV>

=item C<SVt_PVAV>

=item C<SVt_PVHV>

=item C<SVt_PVCV>

=item C<SVt_PVFM>

=item C<SVt_PVIO>

=item C<SVt_LAST>

=item C<SV_CATBYTES>

=item C<SV_CATUTF8>

=item C<SV_CONST_RETURN>

=item C<SV_COW_DROP_PV>

=item C<SV_FORCE_UTF8_UPGRADE>

=item C<SV_GMAGIC>

=item C<SV_HAS_TRAILING_NUL>

=item C<SV_IMMEDIATE_UNREF>

=item C<SV_NOSTEAL>

=item C<SV_SMAGIC>

=item C<GV_ADD>

=item C<GV_ADDMG>

=item C<GV_ADDMULTI>

=item C<GV_NOADD_NOINIT>

=item C<GV_NOEXPAND>

=item C<GV_NOINIT>

=item C<GV_SUPER>

=item C<PERL_MAGIC_arylen>

=item C<PERL_MAGIC_arylen_p>

=item C<PERL_MAGIC_backref>

=item C<PERL_MAGIC_bm>

=item C<PERL_MAGIC_checkcall>

=item C<PERL_MAGIC_collxfrm>

=item C<PERL_MAGIC_dbfile>

=item C<PERL_MAGIC_dbline>

=item C<PERL_MAGIC_debugvar>

=item C<PERL_MAGIC_defelem>

=item C<PERL_MAGIC_env>

=item C<PERL_MAGIC_envelem>

=item C<PERL_MAGIC_ext>

=item C<PERL_MAGIC_fm>

=item C<PERL_MAGIC_foo>

=item C<PERL_MAGIC_hints>

=item C<PERL_MAGIC_hintselem>

=item C<PERL_MAGIC_isa>

=item C<PERL_MAGIC_isaelem>

=item C<PERL_MAGIC_lvref>

=item C<PERL_MAGIC_nkeys>

=item C<PERL_MAGIC_overload_table>

=item C<PERL_MAGIC_pos>

=item C<PERL_MAGIC_qr>

=item C<PERL_MAGIC_regdata>

=item C<PERL_MAGIC_regdatum>

=item C<PERL_MAGIC_regex_global>

=item C<PERL_MAGIC_rhash>

=item C<PERL_MAGIC_shared>

=item C<PERL_MAGIC_shared_scalar>

=item C<PERL_MAGIC_sig>

=item C<PERL_MAGIC_sigelem>

=item C<PERL_MAGIC_substr>

=item C<PERL_MAGIC_sv>

=item C<PERL_MAGIC_symtab>

=item C<PERL_MAGIC_taint>

=item C<PERL_MAGIC_tied>

=item C<PERL_MAGIC_tiedelem>

=item C<PERL_MAGIC_tiedscalar>

=item C<PERL_MAGIC_utf8>

=item C<PERL_MAGIC_uvar>

=item C<PERL_MAGIC_uvar_elem>

=item C<PERL_MAGIC_vec>

=item C<PERL_MAGIC_vstring>



=back

=head1 THE REST

Most of the XS API consists of normal functions and their addresses can be
discovered via L<DynaLoader> at run-time with little effort. See
L<perlguts/"Internal Functions"> for more information.

=head1 SEE MORE

Perl extensive XS documentation: L<perlxs>, L<perlapi>, L<perlguts>.

JIT-compiler libraries for Perl: L<LibJIT>, L<GCCJIT>.

=head1 AUTHOR

Vickenty Fesunov, E<lt>cpan-ouroboros@setattr.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016 Vickenty Fesunov.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
