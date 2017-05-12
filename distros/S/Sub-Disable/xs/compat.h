#ifndef __DISABLE_XS_COMPAT_H_
#define __DISABLE_XS_COMPAT_H_

#ifndef OpSIBLING
#define OpSIBLING(o) ((o)->op_sibling)
#endif

#ifndef cMETHOPx_meth
#define cMETHOPx_meth cSVOPx_sv
#endif

#ifndef SvREFCNT_dec_NN
#define SvREFCNT_dec_NN SvREFCNT_dec
#endif

#ifndef gv_init_sv
#define gv_init_sv(gv, stash, sv, flags) gv_init(gv, stash, SvPVX(sv), SvLEN(sv), flags | SvUTF8(sv))
#endif

#ifndef GvCV_set
#define GvCV_set(gv, cv) (GvCV(gv) = cv)
#endif

#ifndef wrap_op_checker
#define COMPAT_OP_CHECKER
#define wrap_op_checker compat_wrap_op_checker
#endif

#endif /* __DISABLE_XS_COMPAT_H_ */
