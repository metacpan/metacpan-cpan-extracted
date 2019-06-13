package Ouroboros::Spec;
use strict;
use warnings;

our $VERSION = "0.14";

# spec {
our %SPEC = (
  "const" => [
    {
      "c_type" => "U32",
      "name" => "SV_CATBYTES",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "SV_CATUTF8",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "SV_CONST_RETURN",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "SV_COW_DROP_PV",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "SV_FORCE_UTF8_UPGRADE",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "SV_GMAGIC",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "SV_HAS_TRAILING_NUL",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "SV_IMMEDIATE_UNREF",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "SV_NOSTEAL",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "SV_SMAGIC",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "GV_ADD",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "GV_ADDMG",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "GV_ADDMULTI",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "GV_NOADD_NOINIT",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "GV_NOEXPAND",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "GV_NOINIT",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "GV_SUPER",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_arylen",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_arylen_p",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_backref",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_bm",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_checkcall",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_collxfrm",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_dbfile",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_dbline",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_debugvar",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_defelem",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_env",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_envelem",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_ext",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_fm",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_foo",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_hints",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_hintselem",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_isa",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_isaelem",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_lvref",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_nkeys",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_overload_table",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_pos",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_qr",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_regdata",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_regdatum",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_regex_global",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_rhash",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_shared",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_shared_scalar",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_sig",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_sigelem",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_substr",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_sv",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_symtab",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_taint",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_tied",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_tiedelem",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_tiedscalar",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_utf8",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_uvar",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_uvar_elem",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_vec",
      "perl_type" => "UV"
    },
    {
      "c_type" => "U32",
      "name" => "PERL_MAGIC_vstring",
      "perl_type" => "UV"
    }
  ],
  "enum" => [
    {
      "c_type" => "svtype",
      "name" => "SVt_NULL",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_IV",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_NV",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_PV",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_PVIV",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_PVNV",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_PVMG",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_REGEXP",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_PVGV",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_PVLV",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_PVAV",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_PVHV",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_PVCV",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_PVFM",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_PVIO",
      "perl_type" => "IV"
    },
    {
      "c_type" => "svtype",
      "name" => "SVt_LAST",
      "perl_type" => "IV"
    }
  ],
  "fn" => [
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_init(pTHX_ ouroboros_stack_t*);",
      "name" => "ouroboros_stack_init",
      "params" => [
        "ouroboros_stack_t*"
      ],
      "ptr_name" => "ouroboros_stack_init_ptr",
      "tags" => {
        "apidoc" => "Initialize ouroboros_stack_t object. Must be first thing called by a XS-sub. Equivalent to C<dXSARGS> macro automatically inserted by C<xsubpp> into every XS sub."
      },
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC int ouroboros_stack_items(pTHX_ ouroboros_stack_t*);",
      "name" => "ouroboros_stack_items",
      "params" => [
        "ouroboros_stack_t*"
      ],
      "ptr_name" => "ouroboros_stack_items_ptr",
      "tags" => {
        "apidoc" => "Returns number of arguments on Perl stack. Equivalent to C<items> local variable in XS."
      },
      "type" => "int"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_putback(pTHX_ ouroboros_stack_t*);",
      "name" => "ouroboros_stack_putback",
      "params" => [
        "ouroboros_stack_t*"
      ],
      "ptr_name" => "ouroboros_stack_putback_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC SV* ouroboros_stack_fetch(pTHX_ ouroboros_stack_t*, SSize_t);",
      "name" => "ouroboros_stack_fetch",
      "params" => [
        "ouroboros_stack_t*",
        "SSize_t"
      ],
      "ptr_name" => "ouroboros_stack_fetch_ptr",
      "tags" => {
        "apidoc" => "Read a value from the stack. Equivalent of:\n\n    return ST(a);\n\nPerl macro: C<ST(n)>"
      },
      "type" => "SV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_store(pTHX_ ouroboros_stack_t*, SSize_t, SV*);",
      "name" => "ouroboros_stack_store",
      "params" => [
        "ouroboros_stack_t*",
        "SSize_t",
        "SV*"
      ],
      "ptr_name" => "ouroboros_stack_store_ptr",
      "tags" => {
        "apidoc" => "Store a value on the stack. Equivalent of:\n\n    ST(a) = sv;\n\nPerl macro: C<ST>"
      },
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_extend(pTHX_ ouroboros_stack_t*, SSize_t);",
      "name" => "ouroboros_stack_extend",
      "params" => [
        "ouroboros_stack_t*",
        "SSize_t"
      ],
      "ptr_name" => "ouroboros_stack_extend_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_pushmark(pTHX_ ouroboros_stack_t*);",
      "name" => "ouroboros_stack_pushmark",
      "params" => [
        "ouroboros_stack_t*"
      ],
      "ptr_name" => "ouroboros_stack_pushmark_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_spagain(pTHX_ ouroboros_stack_t*);",
      "name" => "ouroboros_stack_spagain",
      "params" => [
        "ouroboros_stack_t*"
      ],
      "ptr_name" => "ouroboros_stack_spagain_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_xpush_sv(pTHX_ ouroboros_stack_t*, SV*);",
      "name" => "ouroboros_stack_xpush_sv",
      "params" => [
        "ouroboros_stack_t*",
        "SV*"
      ],
      "ptr_name" => "ouroboros_stack_xpush_sv_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_xpush_sv_mortal(pTHX_ ouroboros_stack_t*, SV*);",
      "name" => "ouroboros_stack_xpush_sv_mortal",
      "params" => [
        "ouroboros_stack_t*",
        "SV*"
      ],
      "ptr_name" => "ouroboros_stack_xpush_sv_mortal_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_xpush_iv(pTHX_ ouroboros_stack_t*, IV);",
      "name" => "ouroboros_stack_xpush_iv",
      "params" => [
        "ouroboros_stack_t*",
        "IV"
      ],
      "ptr_name" => "ouroboros_stack_xpush_iv_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_xpush_uv(pTHX_ ouroboros_stack_t*, UV);",
      "name" => "ouroboros_stack_xpush_uv",
      "params" => [
        "ouroboros_stack_t*",
        "UV"
      ],
      "ptr_name" => "ouroboros_stack_xpush_uv_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_xpush_nv(pTHX_ ouroboros_stack_t*, NV);",
      "name" => "ouroboros_stack_xpush_nv",
      "params" => [
        "ouroboros_stack_t*",
        "NV"
      ],
      "ptr_name" => "ouroboros_stack_xpush_nv_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_xpush_pv(pTHX_ ouroboros_stack_t*, const char*, STRLEN);",
      "name" => "ouroboros_stack_xpush_pv",
      "params" => [
        "ouroboros_stack_t*",
        "const char*",
        "STRLEN"
      ],
      "ptr_name" => "ouroboros_stack_xpush_pv_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_xpush_mortal(pTHX_ ouroboros_stack_t*);",
      "name" => "ouroboros_stack_xpush_mortal",
      "params" => [
        "ouroboros_stack_t*"
      ],
      "ptr_name" => "ouroboros_stack_xpush_mortal_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_push_sv(pTHX_ ouroboros_stack_t*, SV*);",
      "name" => "ouroboros_stack_push_sv",
      "params" => [
        "ouroboros_stack_t*",
        "SV*"
      ],
      "ptr_name" => "ouroboros_stack_push_sv_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_push_sv_mortal(pTHX_ ouroboros_stack_t*, SV*);",
      "name" => "ouroboros_stack_push_sv_mortal",
      "params" => [
        "ouroboros_stack_t*",
        "SV*"
      ],
      "ptr_name" => "ouroboros_stack_push_sv_mortal_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_push_iv(pTHX_ ouroboros_stack_t*, IV);",
      "name" => "ouroboros_stack_push_iv",
      "params" => [
        "ouroboros_stack_t*",
        "IV"
      ],
      "ptr_name" => "ouroboros_stack_push_iv_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_push_uv(pTHX_ ouroboros_stack_t*, UV);",
      "name" => "ouroboros_stack_push_uv",
      "params" => [
        "ouroboros_stack_t*",
        "UV"
      ],
      "ptr_name" => "ouroboros_stack_push_uv_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_push_nv(pTHX_ ouroboros_stack_t*, NV);",
      "name" => "ouroboros_stack_push_nv",
      "params" => [
        "ouroboros_stack_t*",
        "NV"
      ],
      "ptr_name" => "ouroboros_stack_push_nv_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_push_pv(pTHX_ ouroboros_stack_t*, const char*, STRLEN);",
      "name" => "ouroboros_stack_push_pv",
      "params" => [
        "ouroboros_stack_t*",
        "const char*",
        "STRLEN"
      ],
      "ptr_name" => "ouroboros_stack_push_pv_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_stack_push_mortal(pTHX_ ouroboros_stack_t*);",
      "name" => "ouroboros_stack_push_mortal",
      "params" => [
        "ouroboros_stack_t*"
      ],
      "ptr_name" => "ouroboros_stack_push_mortal_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_upgrade(pTHX_ SV*, svtype);",
      "name" => "ouroboros_sv_upgrade",
      "params" => [
        "SV*",
        "svtype"
      ],
      "ptr_name" => "ouroboros_sv_upgrade_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_niok(pTHX_ SV*);",
      "name" => "ouroboros_sv_niok",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_niok_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_niok_priv(pTHX_ SV*);",
      "name" => "ouroboros_sv_niok_priv",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_niok_priv_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_niok_off(pTHX_ SV*);",
      "name" => "ouroboros_sv_niok_off",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_niok_off_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_ok(pTHX_ SV*);",
      "name" => "ouroboros_sv_ok",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_ok_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_iok_priv(pTHX_ SV*);",
      "name" => "ouroboros_sv_iok_priv",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_iok_priv_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_nok_priv(pTHX_ SV*);",
      "name" => "ouroboros_sv_nok_priv",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_nok_priv_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_pok_priv(pTHX_ SV*);",
      "name" => "ouroboros_sv_pok_priv",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_pok_priv_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_iok(pTHX_ SV*);",
      "name" => "ouroboros_sv_iok",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_iok_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_iok_on(pTHX_ SV*);",
      "name" => "ouroboros_sv_iok_on",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_iok_on_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_iok_off(pTHX_ SV*);",
      "name" => "ouroboros_sv_iok_off",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_iok_off_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_iok_only(pTHX_ SV*);",
      "name" => "ouroboros_sv_iok_only",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_iok_only_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_iok_only_uv(pTHX_ SV*);",
      "name" => "ouroboros_sv_iok_only_uv",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_iok_only_uv_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC bool ouroboros_sv_iok_uv(pTHX_ SV*);",
      "name" => "ouroboros_sv_iok_uv",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_iok_uv_ptr",
      "tags" => {},
      "type" => "bool"
    },
    {
      "c_decl" => "OUROBOROS_STATIC bool ouroboros_sv_uok(pTHX_ SV*);",
      "name" => "ouroboros_sv_uok",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_uok_ptr",
      "tags" => {},
      "type" => "bool"
    },
    {
      "c_decl" => "OUROBOROS_STATIC bool ouroboros_sv_iok_not_uv(pTHX_ SV*);",
      "name" => "ouroboros_sv_iok_not_uv",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_iok_not_uv_ptr",
      "tags" => {},
      "type" => "bool"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_nok(pTHX_ SV*);",
      "name" => "ouroboros_sv_nok",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_nok_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_nok_on(pTHX_ SV*);",
      "name" => "ouroboros_sv_nok_on",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_nok_on_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_nok_off(pTHX_ SV*);",
      "name" => "ouroboros_sv_nok_off",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_nok_off_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_nok_only(pTHX_ SV*);",
      "name" => "ouroboros_sv_nok_only",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_nok_only_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_pok(pTHX_ SV*);",
      "name" => "ouroboros_sv_pok",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_pok_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_pok_on(pTHX_ SV*);",
      "name" => "ouroboros_sv_pok_on",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_pok_on_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_pok_off(pTHX_ SV*);",
      "name" => "ouroboros_sv_pok_off",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_pok_off_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_pok_only(pTHX_ SV*);",
      "name" => "ouroboros_sv_pok_only",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_pok_only_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_pok_only_utf8(pTHX_ SV*);",
      "name" => "ouroboros_sv_pok_only_utf8",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_pok_only_utf8_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC bool ouroboros_sv_vok(pTHX_ SV*);",
      "name" => "ouroboros_sv_vok",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_vok_ptr",
      "tags" => {},
      "type" => "bool"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_ook(pTHX_ SV*);",
      "name" => "ouroboros_sv_ook",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_ook_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_ook_offset(pTHX_ SV*, STRLEN*);",
      "name" => "ouroboros_sv_ook_offset",
      "params" => [
        "SV*",
        "STRLEN*"
      ],
      "ptr_name" => "ouroboros_sv_ook_offset_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_rok(pTHX_ SV*);",
      "name" => "ouroboros_sv_rok",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_rok_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_rok_on(pTHX_ SV*);",
      "name" => "ouroboros_sv_rok_on",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_rok_on_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_rok_off(pTHX_ SV*);",
      "name" => "ouroboros_sv_rok_off",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_rok_off_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC IV ouroboros_sv_iv(pTHX_ SV*);",
      "name" => "ouroboros_sv_iv",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_iv_ptr",
      "tags" => {},
      "type" => "IV"
    },
    {
      "c_decl" => "OUROBOROS_STATIC IV ouroboros_sv_iv_nomg(pTHX_ SV*);",
      "name" => "ouroboros_sv_iv_nomg",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_iv_nomg_ptr",
      "tags" => {},
      "type" => "IV"
    },
    {
      "c_decl" => "OUROBOROS_STATIC IV ouroboros_sv_iv_raw(pTHX_ SV*);",
      "name" => "ouroboros_sv_iv_raw",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_iv_raw_ptr",
      "tags" => {},
      "type" => "IV"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_iv_set(pTHX_ SV*, IV);",
      "name" => "ouroboros_sv_iv_set",
      "params" => [
        "SV*",
        "IV"
      ],
      "ptr_name" => "ouroboros_sv_iv_set_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC UV ouroboros_sv_uv(pTHX_ SV*);",
      "name" => "ouroboros_sv_uv",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_uv_ptr",
      "tags" => {},
      "type" => "UV"
    },
    {
      "c_decl" => "OUROBOROS_STATIC UV ouroboros_sv_uv_nomg(pTHX_ SV*);",
      "name" => "ouroboros_sv_uv_nomg",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_uv_nomg_ptr",
      "tags" => {},
      "type" => "UV"
    },
    {
      "c_decl" => "OUROBOROS_STATIC UV ouroboros_sv_uv_raw(pTHX_ SV*);",
      "name" => "ouroboros_sv_uv_raw",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_uv_raw_ptr",
      "tags" => {},
      "type" => "UV"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_uv_set(pTHX_ SV*, UV);",
      "name" => "ouroboros_sv_uv_set",
      "params" => [
        "SV*",
        "UV"
      ],
      "ptr_name" => "ouroboros_sv_uv_set_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC NV ouroboros_sv_nv(pTHX_ SV*);",
      "name" => "ouroboros_sv_nv",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_nv_ptr",
      "tags" => {},
      "type" => "NV"
    },
    {
      "c_decl" => "OUROBOROS_STATIC NV ouroboros_sv_nv_nomg(pTHX_ SV*);",
      "name" => "ouroboros_sv_nv_nomg",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_nv_nomg_ptr",
      "tags" => {},
      "type" => "NV"
    },
    {
      "c_decl" => "OUROBOROS_STATIC NV ouroboros_sv_nv_raw(pTHX_ SV*);",
      "name" => "ouroboros_sv_nv_raw",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_nv_raw_ptr",
      "tags" => {},
      "type" => "NV"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_nv_set(pTHX_ SV*, NV);",
      "name" => "ouroboros_sv_nv_set",
      "params" => [
        "SV*",
        "NV"
      ],
      "ptr_name" => "ouroboros_sv_nv_set_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC const char* ouroboros_sv_pv(pTHX_ SV*, STRLEN*);",
      "name" => "ouroboros_sv_pv",
      "params" => [
        "SV*",
        "STRLEN*"
      ],
      "ptr_name" => "ouroboros_sv_pv_ptr",
      "tags" => {},
      "type" => "const char*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC const char* ouroboros_sv_pv_nomg(pTHX_ SV*, STRLEN*);",
      "name" => "ouroboros_sv_pv_nomg",
      "params" => [
        "SV*",
        "STRLEN*"
      ],
      "ptr_name" => "ouroboros_sv_pv_nomg_ptr",
      "tags" => {},
      "type" => "const char*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC const char* ouroboros_sv_pv_nolen(pTHX_ SV*);",
      "name" => "ouroboros_sv_pv_nolen",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_pv_nolen_ptr",
      "tags" => {},
      "type" => "const char*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC const char* ouroboros_sv_pv_nomg_nolen(pTHX_ SV*);",
      "name" => "ouroboros_sv_pv_nomg_nolen",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_pv_nomg_nolen_ptr",
      "tags" => {},
      "type" => "const char*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC char* ouroboros_sv_pv_raw(pTHX_ SV*);",
      "name" => "ouroboros_sv_pv_raw",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_pv_raw_ptr",
      "tags" => {},
      "type" => "char*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC STRLEN ouroboros_sv_pv_cur(pTHX_ SV*);",
      "name" => "ouroboros_sv_pv_cur",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_pv_cur_ptr",
      "tags" => {},
      "type" => "STRLEN"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_pv_cur_set(pTHX_ SV*, STRLEN);",
      "name" => "ouroboros_sv_pv_cur_set",
      "params" => [
        "SV*",
        "STRLEN"
      ],
      "ptr_name" => "ouroboros_sv_pv_cur_set_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC STRLEN ouroboros_sv_pv_len(pTHX_ SV*);",
      "name" => "ouroboros_sv_pv_len",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_pv_len_ptr",
      "tags" => {},
      "type" => "STRLEN"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_pv_len_set(pTHX_ SV*, STRLEN);",
      "name" => "ouroboros_sv_pv_len_set",
      "params" => [
        "SV*",
        "STRLEN"
      ],
      "ptr_name" => "ouroboros_sv_pv_len_set_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC char* ouroboros_sv_pv_end(pTHX_ SV*);",
      "name" => "ouroboros_sv_pv_end",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_pv_end_ptr",
      "tags" => {},
      "type" => "char*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC SV* ouroboros_sv_rv(pTHX_ SV*);",
      "name" => "ouroboros_sv_rv",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_rv_ptr",
      "tags" => {},
      "type" => "SV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_rv_set(pTHX_ SV*, SV*);",
      "name" => "ouroboros_sv_rv_set",
      "params" => [
        "SV*",
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_rv_set_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC bool ouroboros_sv_true(pTHX_ SV*);",
      "name" => "ouroboros_sv_true",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_true_ptr",
      "tags" => {},
      "type" => "bool"
    },
    {
      "c_decl" => "OUROBOROS_STATIC bool ouroboros_sv_true_nomg(pTHX_ SV*);",
      "name" => "ouroboros_sv_true_nomg",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_true_nomg_ptr",
      "tags" => {},
      "type" => "bool"
    },
    {
      "c_decl" => "OUROBOROS_STATIC svtype ouroboros_sv_type(pTHX_ SV*);",
      "name" => "ouroboros_sv_type",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_type_ptr",
      "tags" => {},
      "type" => "svtype"
    },
    {
      "c_decl" => "OUROBOROS_STATIC UV ouroboros_sv_flags(pTHX_ SV*);",
      "name" => "ouroboros_sv_flags",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_flags_ptr",
      "tags" => {},
      "type" => "UV"
    },
    {
      "c_decl" => "OUROBOROS_STATIC bool ouroboros_sv_utf8(pTHX_ SV*);",
      "name" => "ouroboros_sv_utf8",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_utf8_ptr",
      "tags" => {},
      "type" => "bool"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_utf8_on(pTHX_ SV*);",
      "name" => "ouroboros_sv_utf8_on",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_utf8_on_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_utf8_off(pTHX_ SV*);",
      "name" => "ouroboros_sv_utf8_off",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_utf8_off_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_is_cow(pTHX_ SV*);",
      "name" => "ouroboros_sv_is_cow",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_is_cow_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC bool ouroboros_sv_is_cow_shared_hash(pTHX_ SV*);",
      "name" => "ouroboros_sv_is_cow_shared_hash",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_is_cow_shared_hash_ptr",
      "tags" => {},
      "type" => "bool"
    },
    {
      "c_decl" => "OUROBOROS_STATIC bool ouroboros_sv_tainted(pTHX_ SV*);",
      "name" => "ouroboros_sv_tainted",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_tainted_ptr",
      "tags" => {},
      "type" => "bool"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_tainted_on(pTHX_ SV*);",
      "name" => "ouroboros_sv_tainted_on",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_tainted_on_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_tainted_off(pTHX_ SV*);",
      "name" => "ouroboros_sv_tainted_off",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_tainted_off_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_taint(pTHX_ SV*);",
      "name" => "ouroboros_sv_taint",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_taint_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_share(pTHX_ SV*);",
      "name" => "ouroboros_sv_share",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_share_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_lock(pTHX_ SV*);",
      "name" => "ouroboros_sv_lock",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_lock_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_unlock(pTHX_ SV*);",
      "name" => "ouroboros_sv_unlock",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_unlock_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_get_a_magic(pTHX_ SV*);",
      "name" => "ouroboros_sv_get_a_magic",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_get_a_magic_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_magic_set(pTHX_ SV*, MAGIC*);",
      "name" => "ouroboros_sv_magic_set",
      "params" => [
        "SV*",
        "MAGIC*"
      ],
      "ptr_name" => "ouroboros_sv_magic_set_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_get_magic(pTHX_ SV*);",
      "name" => "ouroboros_sv_get_magic",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_get_magic_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_set_magic(pTHX_ SV*);",
      "name" => "ouroboros_sv_set_magic",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_set_magic_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC SV* ouroboros_gv_sv(pTHX_ GV*);",
      "name" => "ouroboros_gv_sv",
      "params" => [
        "GV*"
      ],
      "ptr_name" => "ouroboros_gv_sv_ptr",
      "tags" => {},
      "type" => "SV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC AV* ouroboros_gv_av(pTHX_ GV*);",
      "name" => "ouroboros_gv_av",
      "params" => [
        "GV*"
      ],
      "ptr_name" => "ouroboros_gv_av_ptr",
      "tags" => {},
      "type" => "AV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC HV* ouroboros_gv_hv(pTHX_ GV*);",
      "name" => "ouroboros_gv_hv",
      "params" => [
        "GV*"
      ],
      "ptr_name" => "ouroboros_gv_hv_ptr",
      "tags" => {},
      "type" => "HV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC CV* ouroboros_gv_cv(pTHX_ CV*);",
      "name" => "ouroboros_gv_cv",
      "params" => [
        "CV*"
      ],
      "ptr_name" => "ouroboros_gv_cv_ptr",
      "tags" => {},
      "type" => "CV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC HV* ouroboros_sv_stash(pTHX_ SV*);",
      "name" => "ouroboros_sv_stash",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_stash_ptr",
      "tags" => {},
      "type" => "HV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_stash_set(pTHX_ SV*, HV*);",
      "name" => "ouroboros_sv_stash_set",
      "params" => [
        "SV*",
        "HV*"
      ],
      "ptr_name" => "ouroboros_sv_stash_set_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC HV* ouroboros_cv_stash(pTHX_ CV*);",
      "name" => "ouroboros_cv_stash",
      "params" => [
        "CV*"
      ],
      "ptr_name" => "ouroboros_cv_stash_ptr",
      "tags" => {},
      "type" => "HV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC const char* ouroboros_hv_name(pTHX_ HV*);",
      "name" => "ouroboros_hv_name",
      "params" => [
        "HV*"
      ],
      "ptr_name" => "ouroboros_hv_name_ptr",
      "tags" => {},
      "type" => "const char*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC STRLEN ouroboros_hv_name_len(pTHX_ HV*);",
      "name" => "ouroboros_hv_name_len",
      "params" => [
        "HV*"
      ],
      "ptr_name" => "ouroboros_hv_name_len_ptr",
      "tags" => {},
      "type" => "STRLEN"
    },
    {
      "c_decl" => "OUROBOROS_STATIC unsigned char ouroboros_hv_name_utf8(pTHX_ HV*);",
      "name" => "ouroboros_hv_name_utf8",
      "params" => [
        "HV*"
      ],
      "ptr_name" => "ouroboros_hv_name_utf8_ptr",
      "tags" => {},
      "type" => "unsigned char"
    },
    {
      "c_decl" => "OUROBOROS_STATIC const char* ouroboros_hv_ename(pTHX_ HV*);",
      "name" => "ouroboros_hv_ename",
      "params" => [
        "HV*"
      ],
      "ptr_name" => "ouroboros_hv_ename_ptr",
      "tags" => {},
      "type" => "const char*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC STRLEN ouroboros_hv_ename_len(pTHX_ HV*);",
      "name" => "ouroboros_hv_ename_len",
      "params" => [
        "HV*"
      ],
      "ptr_name" => "ouroboros_hv_ename_len_ptr",
      "tags" => {},
      "type" => "STRLEN"
    },
    {
      "c_decl" => "OUROBOROS_STATIC unsigned char ouroboros_hv_ename_utf8(pTHX_ HV*);",
      "name" => "ouroboros_hv_ename_utf8",
      "params" => [
        "HV*"
      ],
      "ptr_name" => "ouroboros_hv_ename_utf8_ptr",
      "tags" => {},
      "type" => "unsigned char"
    },
    {
      "c_decl" => "OUROBOROS_STATIC const char* ouroboros_he_pv(pTHX_ HE*, STRLEN*);",
      "name" => "ouroboros_he_pv",
      "params" => [
        "HE*",
        "STRLEN*"
      ],
      "ptr_name" => "ouroboros_he_pv_ptr",
      "tags" => {},
      "type" => "const char*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC SV* ouroboros_he_val(pTHX_ HE*);",
      "name" => "ouroboros_he_val",
      "params" => [
        "HE*"
      ],
      "ptr_name" => "ouroboros_he_val_ptr",
      "tags" => {},
      "type" => "SV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_he_hash(pTHX_ HE*);",
      "name" => "ouroboros_he_hash",
      "params" => [
        "HE*"
      ],
      "ptr_name" => "ouroboros_he_hash_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC SV* ouroboros_he_svkey(pTHX_ HE*);",
      "name" => "ouroboros_he_svkey",
      "params" => [
        "HE*"
      ],
      "ptr_name" => "ouroboros_he_svkey_ptr",
      "tags" => {},
      "type" => "SV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC SV* ouroboros_he_svkey_force(pTHX_ HE*);",
      "name" => "ouroboros_he_svkey_force",
      "params" => [
        "HE*"
      ],
      "ptr_name" => "ouroboros_he_svkey_force_ptr",
      "tags" => {},
      "type" => "SV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC SV* ouroboros_he_svkey_set(pTHX_ HE*, SV*);",
      "name" => "ouroboros_he_svkey_set",
      "params" => [
        "HE*",
        "SV*"
      ],
      "ptr_name" => "ouroboros_he_svkey_set_ptr",
      "tags" => {},
      "type" => "SV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_perl_hash(pTHX_ U8*, STRLEN);",
      "name" => "ouroboros_perl_hash",
      "params" => [
        "U8*",
        "STRLEN"
      ],
      "ptr_name" => "ouroboros_perl_hash_ptr",
      "tags" => {
        "apidoc" => "Unlike macro, returns hash value instead of assigning it to an argument.\n\nPerl macro: C<PERL_HASH>"
      },
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_sv_refcnt(pTHX_ SV*);",
      "name" => "ouroboros_sv_refcnt",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_refcnt_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC SV* ouroboros_sv_refcnt_inc(pTHX_ SV*);",
      "name" => "ouroboros_sv_refcnt_inc",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_refcnt_inc_ptr",
      "tags" => {},
      "type" => "SV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC SV* ouroboros_sv_refcnt_inc_nn(pTHX_ SV*);",
      "name" => "ouroboros_sv_refcnt_inc_nn",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_refcnt_inc_nn_ptr",
      "tags" => {},
      "type" => "SV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_refcnt_inc_void(pTHX_ SV*);",
      "name" => "ouroboros_sv_refcnt_inc_void",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_refcnt_inc_void_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_refcnt_inc_void_nn(pTHX_ SV*);",
      "name" => "ouroboros_sv_refcnt_inc_void_nn",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_refcnt_inc_void_nn_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_refcnt_dec(pTHX_ SV*);",
      "name" => "ouroboros_sv_refcnt_dec",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_refcnt_dec_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sv_refcnt_dec_nn(pTHX_ SV*);",
      "name" => "ouroboros_sv_refcnt_dec_nn",
      "params" => [
        "SV*"
      ],
      "ptr_name" => "ouroboros_sv_refcnt_dec_nn_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_enter(pTHX);",
      "name" => "ouroboros_enter",
      "params" => [],
      "ptr_name" => "ouroboros_enter_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_leave(pTHX);",
      "name" => "ouroboros_leave",
      "params" => [],
      "ptr_name" => "ouroboros_leave_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_savetmps(pTHX);",
      "name" => "ouroboros_savetmps",
      "params" => [],
      "ptr_name" => "ouroboros_savetmps_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_freetmps(pTHX);",
      "name" => "ouroboros_freetmps",
      "params" => [],
      "ptr_name" => "ouroboros_freetmps_ptr",
      "tags" => {},
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sys_init3(int*, char***, char***);",
      "name" => "ouroboros_sys_init3",
      "params" => [
        "int*",
        "char***",
        "char***"
      ],
      "ptr_name" => "ouroboros_sys_init3_ptr",
      "tags" => {
        "no_pthx" => 1
      },
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_sys_term();",
      "name" => "ouroboros_sys_term",
      "params" => [],
      "ptr_name" => "ouroboros_sys_term_ptr",
      "tags" => {
        "no_pthx" => 1
      },
      "type" => "void"
    },
    {
      "c_decl" => "OUROBOROS_STATIC SV* ouroboros_sv_undef(pTHX);",
      "name" => "ouroboros_sv_undef",
      "params" => [],
      "ptr_name" => "ouroboros_sv_undef_ptr",
      "tags" => {
        "apidoc" => "Return address of C<PL_sv_undef> global."
      },
      "type" => "SV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC SV* ouroboros_sv_no(pTHX);",
      "name" => "ouroboros_sv_no",
      "params" => [],
      "ptr_name" => "ouroboros_sv_no_ptr",
      "tags" => {
        "apidoc" => "Return address of C<PL_sv_no> global."
      },
      "type" => "SV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC SV* ouroboros_sv_yes(pTHX);",
      "name" => "ouroboros_sv_yes",
      "params" => [],
      "ptr_name" => "ouroboros_sv_yes_ptr",
      "tags" => {
        "apidoc" => "Return address of C<PL_sv_yes> global."
      },
      "type" => "SV*"
    },
    {
      "c_decl" => "OUROBOROS_STATIC U32 ouroboros_gimme(pTHX);",
      "name" => "ouroboros_gimme",
      "params" => [],
      "ptr_name" => "ouroboros_gimme_ptr",
      "tags" => {},
      "type" => "U32"
    },
    {
      "c_decl" => "OUROBOROS_STATIC int ouroboros_xcpt_try(pTHX_ ouroboros_xcpt_callback_t, void*);",
      "name" => "ouroboros_xcpt_try",
      "params" => [
        "ouroboros_xcpt_callback_t",
        "void*"
      ],
      "ptr_name" => "ouroboros_xcpt_try_ptr",
      "tags" => {
        "apidoc" => "Execute callback once while capturing Perl exceptions. Second argument is passed to the callback as is and can be NULL.\n\nThis is equivalent of C<XCPT_TRY_START> and C<XCPT_TRY_END> macros, see L<perlguts/Exception Handling>.\n\nReturns zero if callback was executed successfully and no Perl exceptions were thrown.\n\nReturns non-zero if Perl exception was thrown while executing callback. After doing cleanups, this value must be passed to L</ouroboros_xcpt_rethrow>.\n\nPerl macro: C<XCPT_TRY_START> and C<XCPT_TRY_END>"
      },
      "type" => "int"
    },
    {
      "c_decl" => "OUROBOROS_STATIC void ouroboros_xcpt_rethrow(pTHX_ int);",
      "name" => "ouroboros_xcpt_rethrow",
      "params" => [
        "int"
      ],
      "ptr_name" => "ouroboros_xcpt_rethrow_ptr",
      "tags" => {
        "apidoc" => "Continue exception unwinding after unsuccessful call to L</ouroboros_xcpt_try>.\n\nPerl macro: C<XCPT_RETHROW>"
      },
      "type" => "void"
    }
  ],
  "sizeof" => [
    {
      "type" => "bool"
    },
    {
      "type" => "svtype"
    },
    {
      "type" => "PADOFFSET"
    },
    {
      "type" => "Optype"
    },
    {
      "type" => "ouroboros_stack_t"
    },
    {
      "type" => "MAGIC"
    },
    {
      "type" => "MGVTBL"
    }
  ]
);

# }

1;
__END__

=head1 NAME

Ouroboros::Spec - Ouroboros API specification

=head1 DESCRIPTION

This package contains a single global variable, C<%SPEC> that describes API
provided by the L<Ouroboros> package. Each key in this hash corresponds to a
certain item type described below, and values are all arrayrefs of hashrefs.

=head1 CONTENTS

=head2 Constants

    $SPEC{const} = [ { name => "..." }, ... ];

A list of supported numeric constants.

=head3 Keys

=over

=item name

Constant name.

=item c_type

Actual C type.

=item perl_type

Perl scalar variant used to export the constant value to Perl. One of: "IV" or "UV".

=back

=head2 Enum values

    $SPEC{enum} = [ { name => "..." }, ... ];

A list of supported enum values. This is a separate list due to nuance of
C<ExtUtils::Constant> implementation.

=head3 Keys

=over

=item name

Enum value name.

=item c_type

Actual C name of the enum.

=item perl_type

Perl scalar variant used to export the constant value to Perl. One of: "IV" or "UV".

=back

=head2 Functions

    $SPEC{fn} = [ { name => "...", ... }, ... ];

=head3 Keys

=over

=item name

Name of the C function.

=item ptr_name

Name of the pointer getter in L<Ouroboros> package.

=item c_decl

C header declaration.

=item type

Return type of the function.

=item params

Arrayref containing C types of each of function argument, excluding C<pTHX>
argument present by default (but see C<no_pthx> tag below).

=item tags

Additional metadata about the function.

=over

=item apidoc

POD string containing additional notes about the item.

=item no_pthx

When true, indicates that function does not have pTHX as a first argument.

=back

=back

=head2 Type sizes

    $SPEC{sizeof} => [ { type => "..." }, ... ];

A list of types available via %SIZE_OF hash in L<Ouroboros> package.

=head3 Keys

=over

=item type

Name of the C type.

=back
