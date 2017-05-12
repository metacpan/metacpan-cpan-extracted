#ifndef PIGSYMBOL_H
#define PIGSYMBOL_H

/*
 * Declaration of the functions which implement Pig symbol tables
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

void pig_symbol_exchange(pig_symboltable *pig_export, pig_symboltable *pig_import,
                         const char *pig_class, const char *pig_super = 0);
int pig_count_symbols(struct pig_symboltable *pig_symbols);
struct pig_symboltable **pig_get_symbols(struct pig_symboltable **pig_list, struct pig_symboltable *pig_symbols);
struct pig_symboltable **pig_create_symbol_list(struct pig_symboltable *pig_symbols, SV *pig_sv);
void pig_symbol_import(struct pig_symboltable **pig_import, struct pig_symboltable **pig_export);

#endif  // PIGSYMBOL_H
