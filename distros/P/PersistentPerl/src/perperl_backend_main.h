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

/* Glue */

#define perperl_memcpy(d,s,n)	Copy(s,d,n,char)
#define perperl_memmove(d,s,n)	Move(s,d,n,char)
#define perperl_bzero(s,n)	Zero(s,n,char)
#define perperl_execvp(f,a)	execvp(f,(char * const *)a)

#ifdef PERPERL_EFENCE

void * efence_malloc (size_t size);
void   efence_free (void *ptr);
void * efence_realloc (void *ptr, size_t size);

#define perperl_new(s,n,t)	\
    do { (s) = (t*)efence_malloc((n)*sizeof(t)); } while (0)
#define perperl_renew(s,n,t)	\
    do { (s) = (t*)efence_realloc((s),(n)*sizeof(t)); } while (0)
#define perperl_free		efence_free

#else

#define perperl_new(s,n,t)	New(123,s,n,t)
#define perperl_renew		Renew
#define perperl_free		Safefree

#endif

void perperl_abort(const char *s);
