void*
ouroboros_stack_init_ptr()
CODE:
	RETVAL = ouroboros_stack_init;
OUTPUT:
	RETVAL

void*
ouroboros_stack_items_ptr()
CODE:
	RETVAL = ouroboros_stack_items;
OUTPUT:
	RETVAL

void*
ouroboros_stack_putback_ptr()
CODE:
	RETVAL = ouroboros_stack_putback;
OUTPUT:
	RETVAL

void*
ouroboros_stack_fetch_ptr()
CODE:
	RETVAL = ouroboros_stack_fetch;
OUTPUT:
	RETVAL

void*
ouroboros_stack_store_ptr()
CODE:
	RETVAL = ouroboros_stack_store;
OUTPUT:
	RETVAL

void*
ouroboros_stack_extend_ptr()
CODE:
	RETVAL = ouroboros_stack_extend;
OUTPUT:
	RETVAL

void*
ouroboros_stack_pushmark_ptr()
CODE:
	RETVAL = ouroboros_stack_pushmark;
OUTPUT:
	RETVAL

void*
ouroboros_stack_spagain_ptr()
CODE:
	RETVAL = ouroboros_stack_spagain;
OUTPUT:
	RETVAL

void*
ouroboros_stack_xpush_sv_ptr()
CODE:
	RETVAL = ouroboros_stack_xpush_sv;
OUTPUT:
	RETVAL

void*
ouroboros_stack_xpush_sv_mortal_ptr()
CODE:
	RETVAL = ouroboros_stack_xpush_sv_mortal;
OUTPUT:
	RETVAL

void*
ouroboros_stack_xpush_iv_ptr()
CODE:
	RETVAL = ouroboros_stack_xpush_iv;
OUTPUT:
	RETVAL

void*
ouroboros_stack_xpush_uv_ptr()
CODE:
	RETVAL = ouroboros_stack_xpush_uv;
OUTPUT:
	RETVAL

void*
ouroboros_stack_xpush_nv_ptr()
CODE:
	RETVAL = ouroboros_stack_xpush_nv;
OUTPUT:
	RETVAL

void*
ouroboros_stack_xpush_pv_ptr()
CODE:
	RETVAL = ouroboros_stack_xpush_pv;
OUTPUT:
	RETVAL

void*
ouroboros_stack_xpush_mortal_ptr()
CODE:
	RETVAL = ouroboros_stack_xpush_mortal;
OUTPUT:
	RETVAL

void*
ouroboros_stack_push_sv_ptr()
CODE:
	RETVAL = ouroboros_stack_push_sv;
OUTPUT:
	RETVAL

void*
ouroboros_stack_push_sv_mortal_ptr()
CODE:
	RETVAL = ouroboros_stack_push_sv_mortal;
OUTPUT:
	RETVAL

void*
ouroboros_stack_push_iv_ptr()
CODE:
	RETVAL = ouroboros_stack_push_iv;
OUTPUT:
	RETVAL

void*
ouroboros_stack_push_uv_ptr()
CODE:
	RETVAL = ouroboros_stack_push_uv;
OUTPUT:
	RETVAL

void*
ouroboros_stack_push_nv_ptr()
CODE:
	RETVAL = ouroboros_stack_push_nv;
OUTPUT:
	RETVAL

void*
ouroboros_stack_push_pv_ptr()
CODE:
	RETVAL = ouroboros_stack_push_pv;
OUTPUT:
	RETVAL

void*
ouroboros_stack_push_mortal_ptr()
CODE:
	RETVAL = ouroboros_stack_push_mortal;
OUTPUT:
	RETVAL

void*
ouroboros_sv_upgrade_ptr()
CODE:
	RETVAL = ouroboros_sv_upgrade;
OUTPUT:
	RETVAL

void*
ouroboros_sv_niok_ptr()
CODE:
	RETVAL = ouroboros_sv_niok;
OUTPUT:
	RETVAL

void*
ouroboros_sv_niok_priv_ptr()
CODE:
	RETVAL = ouroboros_sv_niok_priv;
OUTPUT:
	RETVAL

void*
ouroboros_sv_niok_off_ptr()
CODE:
	RETVAL = ouroboros_sv_niok_off;
OUTPUT:
	RETVAL

void*
ouroboros_sv_ok_ptr()
CODE:
	RETVAL = ouroboros_sv_ok;
OUTPUT:
	RETVAL

void*
ouroboros_sv_iok_priv_ptr()
CODE:
	RETVAL = ouroboros_sv_iok_priv;
OUTPUT:
	RETVAL

void*
ouroboros_sv_nok_priv_ptr()
CODE:
	RETVAL = ouroboros_sv_nok_priv;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pok_priv_ptr()
CODE:
	RETVAL = ouroboros_sv_pok_priv;
OUTPUT:
	RETVAL

void*
ouroboros_sv_iok_ptr()
CODE:
	RETVAL = ouroboros_sv_iok;
OUTPUT:
	RETVAL

void*
ouroboros_sv_iok_on_ptr()
CODE:
	RETVAL = ouroboros_sv_iok_on;
OUTPUT:
	RETVAL

void*
ouroboros_sv_iok_off_ptr()
CODE:
	RETVAL = ouroboros_sv_iok_off;
OUTPUT:
	RETVAL

void*
ouroboros_sv_iok_only_ptr()
CODE:
	RETVAL = ouroboros_sv_iok_only;
OUTPUT:
	RETVAL

void*
ouroboros_sv_iok_only_uv_ptr()
CODE:
	RETVAL = ouroboros_sv_iok_only_uv;
OUTPUT:
	RETVAL

void*
ouroboros_sv_iok_uv_ptr()
CODE:
	RETVAL = ouroboros_sv_iok_uv;
OUTPUT:
	RETVAL

void*
ouroboros_sv_uok_ptr()
CODE:
	RETVAL = ouroboros_sv_uok;
OUTPUT:
	RETVAL

void*
ouroboros_sv_iok_not_uv_ptr()
CODE:
	RETVAL = ouroboros_sv_iok_not_uv;
OUTPUT:
	RETVAL

void*
ouroboros_sv_nok_ptr()
CODE:
	RETVAL = ouroboros_sv_nok;
OUTPUT:
	RETVAL

void*
ouroboros_sv_nok_on_ptr()
CODE:
	RETVAL = ouroboros_sv_nok_on;
OUTPUT:
	RETVAL

void*
ouroboros_sv_nok_off_ptr()
CODE:
	RETVAL = ouroboros_sv_nok_off;
OUTPUT:
	RETVAL

void*
ouroboros_sv_nok_only_ptr()
CODE:
	RETVAL = ouroboros_sv_nok_only;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pok_ptr()
CODE:
	RETVAL = ouroboros_sv_pok;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pok_on_ptr()
CODE:
	RETVAL = ouroboros_sv_pok_on;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pok_off_ptr()
CODE:
	RETVAL = ouroboros_sv_pok_off;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pok_only_ptr()
CODE:
	RETVAL = ouroboros_sv_pok_only;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pok_only_utf8_ptr()
CODE:
	RETVAL = ouroboros_sv_pok_only_utf8;
OUTPUT:
	RETVAL

void*
ouroboros_sv_vok_ptr()
CODE:
	RETVAL = ouroboros_sv_vok;
OUTPUT:
	RETVAL

void*
ouroboros_sv_ook_ptr()
CODE:
	RETVAL = ouroboros_sv_ook;
OUTPUT:
	RETVAL

void*
ouroboros_sv_ook_offset_ptr()
CODE:
	RETVAL = ouroboros_sv_ook_offset;
OUTPUT:
	RETVAL

void*
ouroboros_sv_rok_ptr()
CODE:
	RETVAL = ouroboros_sv_rok;
OUTPUT:
	RETVAL

void*
ouroboros_sv_rok_on_ptr()
CODE:
	RETVAL = ouroboros_sv_rok_on;
OUTPUT:
	RETVAL

void*
ouroboros_sv_rok_off_ptr()
CODE:
	RETVAL = ouroboros_sv_rok_off;
OUTPUT:
	RETVAL

void*
ouroboros_sv_iv_ptr()
CODE:
	RETVAL = ouroboros_sv_iv;
OUTPUT:
	RETVAL

void*
ouroboros_sv_iv_nomg_ptr()
CODE:
	RETVAL = ouroboros_sv_iv_nomg;
OUTPUT:
	RETVAL

void*
ouroboros_sv_iv_raw_ptr()
CODE:
	RETVAL = ouroboros_sv_iv_raw;
OUTPUT:
	RETVAL

void*
ouroboros_sv_iv_set_ptr()
CODE:
	RETVAL = ouroboros_sv_iv_set;
OUTPUT:
	RETVAL

void*
ouroboros_sv_uv_ptr()
CODE:
	RETVAL = ouroboros_sv_uv;
OUTPUT:
	RETVAL

void*
ouroboros_sv_uv_nomg_ptr()
CODE:
	RETVAL = ouroboros_sv_uv_nomg;
OUTPUT:
	RETVAL

void*
ouroboros_sv_uv_raw_ptr()
CODE:
	RETVAL = ouroboros_sv_uv_raw;
OUTPUT:
	RETVAL

void*
ouroboros_sv_uv_set_ptr()
CODE:
	RETVAL = ouroboros_sv_uv_set;
OUTPUT:
	RETVAL

void*
ouroboros_sv_nv_ptr()
CODE:
	RETVAL = ouroboros_sv_nv;
OUTPUT:
	RETVAL

void*
ouroboros_sv_nv_nomg_ptr()
CODE:
	RETVAL = ouroboros_sv_nv_nomg;
OUTPUT:
	RETVAL

void*
ouroboros_sv_nv_raw_ptr()
CODE:
	RETVAL = ouroboros_sv_nv_raw;
OUTPUT:
	RETVAL

void*
ouroboros_sv_nv_set_ptr()
CODE:
	RETVAL = ouroboros_sv_nv_set;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pv_ptr()
CODE:
	RETVAL = ouroboros_sv_pv;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pv_nomg_ptr()
CODE:
	RETVAL = ouroboros_sv_pv_nomg;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pv_nolen_ptr()
CODE:
	RETVAL = ouroboros_sv_pv_nolen;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pv_nomg_nolen_ptr()
CODE:
	RETVAL = ouroboros_sv_pv_nomg_nolen;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pv_raw_ptr()
CODE:
	RETVAL = ouroboros_sv_pv_raw;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pv_cur_ptr()
CODE:
	RETVAL = ouroboros_sv_pv_cur;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pv_cur_set_ptr()
CODE:
	RETVAL = ouroboros_sv_pv_cur_set;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pv_len_ptr()
CODE:
	RETVAL = ouroboros_sv_pv_len;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pv_len_set_ptr()
CODE:
	RETVAL = ouroboros_sv_pv_len_set;
OUTPUT:
	RETVAL

void*
ouroboros_sv_pv_end_ptr()
CODE:
	RETVAL = ouroboros_sv_pv_end;
OUTPUT:
	RETVAL

void*
ouroboros_sv_rv_ptr()
CODE:
	RETVAL = ouroboros_sv_rv;
OUTPUT:
	RETVAL

void*
ouroboros_sv_rv_set_ptr()
CODE:
	RETVAL = ouroboros_sv_rv_set;
OUTPUT:
	RETVAL

void*
ouroboros_sv_true_ptr()
CODE:
	RETVAL = ouroboros_sv_true;
OUTPUT:
	RETVAL

void*
ouroboros_sv_true_nomg_ptr()
CODE:
	RETVAL = ouroboros_sv_true_nomg;
OUTPUT:
	RETVAL

void*
ouroboros_sv_type_ptr()
CODE:
	RETVAL = ouroboros_sv_type;
OUTPUT:
	RETVAL

void*
ouroboros_sv_flags_ptr()
CODE:
	RETVAL = ouroboros_sv_flags;
OUTPUT:
	RETVAL

void*
ouroboros_sv_utf8_ptr()
CODE:
	RETVAL = ouroboros_sv_utf8;
OUTPUT:
	RETVAL

void*
ouroboros_sv_utf8_on_ptr()
CODE:
	RETVAL = ouroboros_sv_utf8_on;
OUTPUT:
	RETVAL

void*
ouroboros_sv_utf8_off_ptr()
CODE:
	RETVAL = ouroboros_sv_utf8_off;
OUTPUT:
	RETVAL

void*
ouroboros_sv_is_cow_ptr()
CODE:
	RETVAL = ouroboros_sv_is_cow;
OUTPUT:
	RETVAL

void*
ouroboros_sv_is_cow_shared_hash_ptr()
CODE:
	RETVAL = ouroboros_sv_is_cow_shared_hash;
OUTPUT:
	RETVAL

void*
ouroboros_sv_tainted_ptr()
CODE:
	RETVAL = ouroboros_sv_tainted;
OUTPUT:
	RETVAL

void*
ouroboros_sv_tainted_on_ptr()
CODE:
	RETVAL = ouroboros_sv_tainted_on;
OUTPUT:
	RETVAL

void*
ouroboros_sv_tainted_off_ptr()
CODE:
	RETVAL = ouroboros_sv_tainted_off;
OUTPUT:
	RETVAL

void*
ouroboros_sv_taint_ptr()
CODE:
	RETVAL = ouroboros_sv_taint;
OUTPUT:
	RETVAL

void*
ouroboros_sv_share_ptr()
CODE:
	RETVAL = ouroboros_sv_share;
OUTPUT:
	RETVAL

void*
ouroboros_sv_lock_ptr()
CODE:
	RETVAL = ouroboros_sv_lock;
OUTPUT:
	RETVAL

void*
ouroboros_sv_unlock_ptr()
CODE:
	RETVAL = ouroboros_sv_unlock;
OUTPUT:
	RETVAL

void*
ouroboros_sv_get_a_magic_ptr()
CODE:
	RETVAL = ouroboros_sv_get_a_magic;
OUTPUT:
	RETVAL

void*
ouroboros_sv_magic_set_ptr()
CODE:
	RETVAL = ouroboros_sv_magic_set;
OUTPUT:
	RETVAL

void*
ouroboros_sv_get_magic_ptr()
CODE:
	RETVAL = ouroboros_sv_get_magic;
OUTPUT:
	RETVAL

void*
ouroboros_sv_set_magic_ptr()
CODE:
	RETVAL = ouroboros_sv_set_magic;
OUTPUT:
	RETVAL

void*
ouroboros_gv_sv_ptr()
CODE:
	RETVAL = ouroboros_gv_sv;
OUTPUT:
	RETVAL

void*
ouroboros_gv_av_ptr()
CODE:
	RETVAL = ouroboros_gv_av;
OUTPUT:
	RETVAL

void*
ouroboros_gv_hv_ptr()
CODE:
	RETVAL = ouroboros_gv_hv;
OUTPUT:
	RETVAL

void*
ouroboros_gv_cv_ptr()
CODE:
	RETVAL = ouroboros_gv_cv;
OUTPUT:
	RETVAL

void*
ouroboros_sv_stash_ptr()
CODE:
	RETVAL = ouroboros_sv_stash;
OUTPUT:
	RETVAL

void*
ouroboros_sv_stash_set_ptr()
CODE:
	RETVAL = ouroboros_sv_stash_set;
OUTPUT:
	RETVAL

void*
ouroboros_cv_stash_ptr()
CODE:
	RETVAL = ouroboros_cv_stash;
OUTPUT:
	RETVAL

void*
ouroboros_hv_name_ptr()
CODE:
	RETVAL = ouroboros_hv_name;
OUTPUT:
	RETVAL

void*
ouroboros_hv_name_len_ptr()
CODE:
	RETVAL = ouroboros_hv_name_len;
OUTPUT:
	RETVAL

void*
ouroboros_hv_name_utf8_ptr()
CODE:
	RETVAL = ouroboros_hv_name_utf8;
OUTPUT:
	RETVAL

void*
ouroboros_hv_ename_ptr()
CODE:
	RETVAL = ouroboros_hv_ename;
OUTPUT:
	RETVAL

void*
ouroboros_hv_ename_len_ptr()
CODE:
	RETVAL = ouroboros_hv_ename_len;
OUTPUT:
	RETVAL

void*
ouroboros_hv_ename_utf8_ptr()
CODE:
	RETVAL = ouroboros_hv_ename_utf8;
OUTPUT:
	RETVAL

void*
ouroboros_he_pv_ptr()
CODE:
	RETVAL = ouroboros_he_pv;
OUTPUT:
	RETVAL

void*
ouroboros_he_val_ptr()
CODE:
	RETVAL = ouroboros_he_val;
OUTPUT:
	RETVAL

void*
ouroboros_he_hash_ptr()
CODE:
	RETVAL = ouroboros_he_hash;
OUTPUT:
	RETVAL

void*
ouroboros_he_svkey_ptr()
CODE:
	RETVAL = ouroboros_he_svkey;
OUTPUT:
	RETVAL

void*
ouroboros_he_svkey_force_ptr()
CODE:
	RETVAL = ouroboros_he_svkey_force;
OUTPUT:
	RETVAL

void*
ouroboros_he_svkey_set_ptr()
CODE:
	RETVAL = ouroboros_he_svkey_set;
OUTPUT:
	RETVAL

void*
ouroboros_perl_hash_ptr()
CODE:
	RETVAL = ouroboros_perl_hash;
OUTPUT:
	RETVAL

void*
ouroboros_sv_refcnt_ptr()
CODE:
	RETVAL = ouroboros_sv_refcnt;
OUTPUT:
	RETVAL

void*
ouroboros_sv_refcnt_inc_ptr()
CODE:
	RETVAL = ouroboros_sv_refcnt_inc;
OUTPUT:
	RETVAL

void*
ouroboros_sv_refcnt_inc_nn_ptr()
CODE:
	RETVAL = ouroboros_sv_refcnt_inc_nn;
OUTPUT:
	RETVAL

void*
ouroboros_sv_refcnt_inc_void_ptr()
CODE:
	RETVAL = ouroboros_sv_refcnt_inc_void;
OUTPUT:
	RETVAL

void*
ouroboros_sv_refcnt_inc_void_nn_ptr()
CODE:
	RETVAL = ouroboros_sv_refcnt_inc_void_nn;
OUTPUT:
	RETVAL

void*
ouroboros_sv_refcnt_dec_ptr()
CODE:
	RETVAL = ouroboros_sv_refcnt_dec;
OUTPUT:
	RETVAL

void*
ouroboros_sv_refcnt_dec_nn_ptr()
CODE:
	RETVAL = ouroboros_sv_refcnt_dec_nn;
OUTPUT:
	RETVAL

void*
ouroboros_enter_ptr()
CODE:
	RETVAL = ouroboros_enter;
OUTPUT:
	RETVAL

void*
ouroboros_leave_ptr()
CODE:
	RETVAL = ouroboros_leave;
OUTPUT:
	RETVAL

void*
ouroboros_savetmps_ptr()
CODE:
	RETVAL = ouroboros_savetmps;
OUTPUT:
	RETVAL

void*
ouroboros_freetmps_ptr()
CODE:
	RETVAL = ouroboros_freetmps;
OUTPUT:
	RETVAL

void*
ouroboros_sys_init3_ptr()
CODE:
	RETVAL = ouroboros_sys_init3;
OUTPUT:
	RETVAL

void*
ouroboros_sys_term_ptr()
CODE:
	RETVAL = ouroboros_sys_term;
OUTPUT:
	RETVAL

void*
ouroboros_sv_undef_ptr()
CODE:
	RETVAL = ouroboros_sv_undef;
OUTPUT:
	RETVAL

void*
ouroboros_sv_no_ptr()
CODE:
	RETVAL = ouroboros_sv_no;
OUTPUT:
	RETVAL

void*
ouroboros_sv_yes_ptr()
CODE:
	RETVAL = ouroboros_sv_yes;
OUTPUT:
	RETVAL

void*
ouroboros_gimme_ptr()
CODE:
	RETVAL = ouroboros_gimme;
OUTPUT:
	RETVAL

void*
ouroboros_xcpt_try_ptr()
CODE:
	RETVAL = ouroboros_xcpt_try;
OUTPUT:
	RETVAL

void*
ouroboros_xcpt_rethrow_ptr()
CODE:
	RETVAL = ouroboros_xcpt_rethrow;
OUTPUT:
	RETVAL

