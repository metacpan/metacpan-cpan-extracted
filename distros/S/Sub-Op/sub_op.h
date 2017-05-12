/* This file is part of the Sub::Op Perl module.
 * See http://search.cpan.org/dist/Sub-Op/ */

#ifndef SUB_OP_H
#define SUB_OP_H 1

typedef OP *(*sub_op_check_t)(pTHX_ OP *, void *);

typedef struct {
 const char    *name;
 STRLEN         namelen;
 Perl_ppaddr_t  pp;
 sub_op_check_t check;
 void          *ud;
} sub_op_config_t;

void sub_op_register(pTHX_ const sub_op_config_t *c);

#endif /* SUB_OP_H */
