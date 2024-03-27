/*

Copyright (C) 2005-2015 Nicolo' Giorgetti
Copyright (C) 2013-2015 Sébastien Villemot <sebastien@debian.org>

This file is part of Octave.

Octave is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

Octave is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License
along with Octave; see the file COPYING.  If not, see
<http://www.gnu.org/licenses/>.

*/

#include <stdio.h>
#include <time.h>
#include <glpk.h>
#include "glpk_aio.h"


/*
 * The following subroutine was copied from
 * octave 4.0.3 at libinterp/dldfcn/__glpk__.cc
 */


int
glpk (int sense, int n, int m, double *c, int nz, int *rn, int *cn,
      double *a, double *b, int *ctype, int *freeLB, double *lb,
      int *freeUB, double *ub, int *vartype, int isMIP,
	  const control_params *par, double *xmin, double *fmin, int *status,
      double *lambda, double *redcosts, double *time,
	  void (*glpk_warn)(const char *,...), int seq)
{
  int errnum = 0;

  clock_t t_start = clock ();

  glp_prob *lp = glp_create_prob ();
  char prob_name[32];
  snprintf(prob_name, 32, "#%d", seq + 1);
  glp_set_prob_name(lp, prob_name);

  //-- Set the sense of optimization
  glp_set_obj_dir (lp, sense);

  glp_add_cols (lp, n);
  for (int i = 0; i < n; i++)
    {
      //-- Define type of the structural variables
      if (! freeLB[i] && ! freeUB[i])
        {
          if (lb[i] != ub[i])
            glp_set_col_bnds (lp, i+1, GLP_DB, lb[i], ub[i]);
          else
            glp_set_col_bnds (lp, i+1, GLP_FX, lb[i], ub[i]);
        }
      else
        {
          if (! freeLB[i] && freeUB[i])
            glp_set_col_bnds (lp, i+1, GLP_LO, lb[i], ub[i]);
          else
            {
              if (freeLB[i] && ! freeUB[i])
                glp_set_col_bnds (lp, i+1, GLP_UP, lb[i], ub[i]);
              else
                glp_set_col_bnds (lp, i+1, GLP_FR, lb[i], ub[i]);
            }
        }

      // -- Set the objective coefficient of the corresponding
      // -- structural variable. No constant term is assumed.
      glp_set_obj_coef(lp,i+1,c[i]);

      if (isMIP)
        glp_set_col_kind (lp, i+1, vartype[i]);
    }

  glp_add_rows (lp, m);

  for (int i = 0; i < m; i++)
    {
      /* If the i-th row has no lower bound (types FR,UP), the
         correspondent parameter will be ignored.
         If the i-th row has no upper bound (types FR,LO), the correspondent
         parameter will be ignored.
         If the i-th row is of FX type, the i-th LB is used, but
         the i-th UB is ignored.
		 If the i-th row is of DB type, both LB and UP are used.
      */

      glp_set_row_bnds (lp, i+1, ctype[i], ctype[i] == GLP_DB ? -b[i] : b[i], b[i]);

    }

  glp_load_matrix (lp, nz, rn, cn, a);

  if (par->save_pb)
    {
	  char buf[FILENAME_MAX];
	  snprintf(buf, FILENAME_MAX, par->save_fn, seq);
      if (glp_write_lp (lp, NULL, buf) != 0)
        {
          glpk_warn("__glpk__: unable to write problem");
        }
    }

  //-- scale the problem data
  if (!par->presol || par->lpsolver != 1)
    glp_scale_prob (lp, par->scale);

  //-- build advanced initial basis (if required)
  if (par->lpsolver == 1 && !par->presol)
    glp_adv_basis (lp, 0);

  /* For MIP problems without a presolver, a first pass with glp_simplex
     is required */
  if ((!isMIP && par->lpsolver == 1)
      || (isMIP && !par->presol))
    {
      glp_smcp smcp;
      glp_init_smcp (&smcp);
      smcp.msg_lev = par->msglev;
      smcp.meth = par->dual;
      smcp.pricing = par->price;
      smcp.r_test = par->rtest;
      smcp.tol_bnd = par->tolbnd;
      smcp.tol_dj = par->toldj;
      smcp.tol_piv = par->tolpiv;
      smcp.obj_ll = par->objll;
      smcp.obj_ul = par->objul;
      smcp.it_lim = par->itlim;
      smcp.tm_lim = par->tmlim;
      smcp.out_frq = par->outfrq;
      smcp.out_dly = par->outdly;
      smcp.presolve = par->presol;
      errnum = glp_simplex (lp, &smcp);
    }

  if (isMIP)
    {
      glp_iocp iocp;
      glp_init_iocp (&iocp);
      iocp.msg_lev = par->msglev;
      iocp.br_tech = par->branch;
      iocp.bt_tech = par->btrack;
      iocp.tol_int = par->tolint;
      iocp.tol_obj = par->tolobj;
      iocp.tm_lim = par->tmlim;
      iocp.out_frq = par->outfrq;
      iocp.out_dly = par->outdly;
      iocp.presolve = par->presol;
      errnum = glp_intopt (lp, &iocp);
    }

  if (!isMIP && par->lpsolver == 2)
    {
      glp_iptcp iptcp;
      glp_init_iptcp (&iptcp);
      iptcp.msg_lev = par->msglev;
      errnum = glp_interior (lp, &iptcp);
    }

  if (errnum == 0)
    {
      if (isMIP)
        {
          *status = glp_mip_status (lp);
          *fmin = glp_mip_obj_val (lp);
        }
      else
        {
          if (par->lpsolver == 1)
            {
              *status = glp_get_status (lp);
              *fmin = glp_get_obj_val (lp);
            }
          else
            {
              *status = glp_ipt_status (lp);
              *fmin = glp_ipt_obj_val (lp);
            }
        }

      if (isMIP)
        {
          for (int i = 0; i < n; i++)
            xmin[i] = glp_mip_col_val (lp, i+1);
        }
      else
        {
          /* Primal values */
          for (int i = 0; i < n; i++)
            {
              if (par->lpsolver == 1)
                xmin[i] = glp_get_col_prim (lp, i+1);
              else
                xmin[i] = glp_ipt_col_prim (lp, i+1);
            }

          /* Dual values */
          for (int i = 0; i < m; i++)
            {
              if (par->lpsolver == 1)
                lambda[i] = glp_get_row_dual (lp, i+1);
              else
                lambda[i] = glp_ipt_row_dual (lp, i+1);
            }

          /* Reduced costs */
          for (int i = 0; i < glp_get_num_cols (lp); i++)
            {
              if (par->lpsolver == 1)
                redcosts[i] = glp_get_col_dual (lp, i+1);
              else
                redcosts[i] = glp_ipt_col_dual (lp, i+1);
            }
        }

      *time = (clock () - t_start) / CLOCKS_PER_SEC;
    }

  glp_delete_prob (lp);

  return errnum;
}
