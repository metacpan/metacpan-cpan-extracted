#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <./cidr-compare/cidr-compare.h>

#include "const-c.inc"

MODULE = Net::CIDR::Compare		PACKAGE = Net::CIDR::Compare

INCLUDE: const-xs.inc

void
free_tree(n)
  NODE * n

void
add_to_node(init, np, a, bit, end)
  INIT * init
  NODE ** np
  unsigned long int a
  int bit
  int end

void
dump_tree(n, v, bit)
  NODE * n
  unsigned long int v
  int bit

char *
dump_next_intersection_output (init)
  INIT * init
  OUTPUT:
    RETVAL

IPLIST *
dump_intersection_output(init)
  INIT * init
  OUTPUT:
    RETVAL

void
dump_intersection(init, list, v, bit)
  INIT * init
  LIST * list
  unsigned long int v
  int bit
  
void
dump_all_lists(init)
  INIT * init

void
save_one_addr(init, a)
  INIT * init
  unsigned long int a

LIST *
save_cidr(list, a, n)
  LIST * list 
  unsigned long int a
  int n
  OUTPUT:
    RETVAL

void
read_input(init, read_fh)
  INIT * init
  FILE * read_fh

void
dump_output(init)
  INIT * init

INIT *
start_new()
  OUTPUT:
    RETVAL

LIST *
setup_new_list(init)
  INIT *init
  OUTPUT:
    RETVAL

void
save_range(init, a1, a2)
  INIT *init
  unsigned long int a1
  unsigned long int a2

void
delete_list(init, list)
  INIT *init
  LIST *list
