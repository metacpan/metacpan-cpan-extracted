/*
 * Copyright (C) 2003  Sam Horrocks
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

typedef struct _OptRect {
    const char * const	name;
    void		*value;
    const char		letter;
    const char		type;
    char		flags;
    const unsigned char	name_len;
} OptRec;

/* For the flags field above */
#define PERPERL_OPTFL_CHANGED	0x01 /* No longer default */
#define PERPERL_OPTFL_MUST_FREE	0x02 /* value must be freed */

#define INT_OPTVAL(r) (((int*)((r)->value))[0])
#define STR_OPTVAL(r) ((const char*)((r)->value))

void perperl_opt_init(const char * const *argv, const char * const *envp);
void perperl_opt_read_shbang(void);
int perperl_opt_set(OptRec *optrec, const char *value);
int perperl_opt_set_byname(const char *optname, const char *value);
const char *perperl_opt_get(OptRec *optrec);
void perperl_opt_set_script_argv(const char * const *argv);
const char * const *perperl_opt_script_argv(void);
char **perperl_opt_perl_argv(const char *script_name);
const char * const *perperl_opt_exec_argv(void);
const char * const *perperl_opt_exec_envp(void);
const char * const *perperl_opt_orig_argv(void);
PERPERL_INLINE const char *perperl_opt_script_fname(void);
void perperl_opt_save(void);
void perperl_opt_restore(void);
