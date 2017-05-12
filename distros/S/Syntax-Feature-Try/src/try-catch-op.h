#ifndef __TRY_CATCH_OPTREE__
#define __TRY_CATCH_OPTREE__

#include <perl.h>

#define build_const_sv_op(sv)  newSVOP(OP_CONST, 0, (sv))

#define build_block_content_op(orig_content_op) \
        my_build_block_content_op(aTHX_ orig_content_op)
static OP* my_build_block_content_op(pTHX_ OP* orig_content_op);

#define call_sub_op(name, args_op)  my_call_sub_op(aTHX_ name, args_op)
static OP* my_call_sub_op(pTHX_ char *, OP*);

#define build_catch_args_optree(block_op, class_name_sv) \
        my_build_catch_args_optree(aTHX_ block_op, class_name_sv)
static OP* my_build_catch_args_optree(pTHX_ OP* block_op, SV* class_name_sv);

#define build_statement_optree(try_block_op, catch_list_op, finally_block_op) \
        my_build_statement_optree(aTHX_ try_block_op, catch_list_op, finally_block_op)
static OP *my_build_statement_optree(pTHX_
            OP *try_block_op, OP* catch_list_op, OP* finally_block_op
);

#endif /* __TRY_CATCH_OPTREE__ */
