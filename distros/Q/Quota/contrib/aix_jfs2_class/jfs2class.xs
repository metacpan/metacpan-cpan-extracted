/*
 * Perl interface to quota classes on JFS2 (AIX 5.3)
 *
 * This code is untested by me and reportedly not functional yet.
 * It's just provided as possible basis for further development.
 *
 * Copyright (C) 2007 Tom Zoerner.
 *
 * This program is free software: you can redistribute it and/or modify
 * it either under the terms of the Perl Artistic License or the GNU
 * General Public License as published by the Free Software Foundation.
 * (Either version 2 of the GPL, or any later version.)
 * For a copy of these licenses see <http://www.opensource.org/licenses/>.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * Perl Artistic License or GNU General Public License for more details.
 */

MODULE = Quota  PACKAGE = Quota::JFS2CLASS

void
jfs2_getlimit(dev,class)
	char *	dev
	int	class
	PPCODE:
#if defined(HAVE_JFS2)
        if (strncmp(dev, "(JFS2)", 6) == 0) {
          j2qlimit_t j2q;
          int retval;

          memset(&j2q, 0, sizeof(j2q));
          retval = quotactl (dev + 6, Q_J2GETLIMIT, class, (caddr_t)&j2q);
          if (retval == 0) {
            EXTEND(sp, 8);
            PUSHs(sv_2mortal(newSViv(j2q.ql_bsoft)));
            PUSHs(sv_2mortal(newSViv(j2q.ql_bhard)));
            PUSHs(sv_2mortal(newSViv(j2q.ql_btime)));

            PUSHs(sv_2mortal(newSViv(j2q.ql_isoft)));
            PUSHs(sv_2mortal(newSViv(j2q.ql_ihard)));
            PUSHs(sv_2mortal(newSViv(j2q.ql_itime)));
          }
        } else
#endif /* HAVE_JFS2 */
        {
          errno = ENOENT;
        }

int
jfs2_putlimit(dev,class,bs,bh,bt,fs,fh,ft)
	char *	dev
	int	class
	int	bs
	int	bh
	int	bt
	int	fs
	int	fh
	int	ft
	CODE:
#if defined(HAVE_JFS2)
        if (strncmp(dev, "(JFS2)", 6) == 0) {
          j2qlimit_t j2q;
          memset(&j2q, 0, sizeof(j2q));
          j2q.ql_bsoft = bs;
          j2q.ql_bhard = bh;
          j2q.ql_btime = bt;

          j2q.ql_isoft = fs;
          j2q.ql_ihard = fh;
          j2q.ql_itime = ft;
          RETVAL = quotactl (dev + 6, Q_J2PUTLIMIT, class, (caddr_t)&j2q);
        } else
#endif /* HAVE_JFS2 */
        {
          RETVAL = -1;
          errno = ENOENT;
        }
        OUTPUT:
        RETVAL

void
jfs2_newlimit(dev,bs,bh,bt,fs,fh,ft)
	char *	dev
	int	bs
	int	bh
	int	bt
	int	fs
	int	fh
	int	ft
	PPCODE:
#if defined(HAVE_JFS2)
        if (strncmp(dev, "(JFS2)", 6) == 0) {
          j2qlimit_t j2q;
          uid_t class;
          int retval;

          memset(&j2q, 0, sizeof(j2q));
          j2q.ql_bsoft = bs;
          j2q.ql_bhard = bh;
          j2q.ql_btime = bt;

          j2q.ql_isoft = fs;
          j2q.ql_ihard = fh;
          j2q.ql_itime = ft;

          retval = quotactl (dev + 6, Q_J2NEWLIMIT, 0, (caddr_t)&j2q);
          if (retval == 0) {
            EXTEND(sp, 1);
            class = *( (uid_t*) &j2q );
            PUSHs(sv_2mortal(newSViv(class)));
          }
        } else
#endif /* HAVE_JFS2 */
        {
          errno = ENOENT;
        }

int
jfs2_rmvlimit(dev,class)
	char *	dev
	int	class
	CODE:
#if defined(HAVE_JFS2)
        if (strncmp(dev, "(JFS2)", 6) == 0) {
          RETVAL = quotactl (dev + 6, Q_J2RMVLIMIT, class, NULL);
        } else
#endif /* HAVE_JFS2 */
        {
          RETVAL = -1;
          errno = ENOENT;
        }
        OUTPUT:
        RETVAL

int
jfs2_deflimit(dev,class)
	char *	dev
	int	class
	CODE:
#if defined(HAVE_JFS2)
        if (strncmp(dev, "(JFS2)", 6) == 0) {
          RETVAL = quotactl (dev + 6, Q_J2DEFLIMIT, class, NULL);
        } else
#endif /* HAVE_JFS2 */
        {
          RETVAL = -1;
          errno = ENOENT;
        }
        OUTPUT:
        RETVAL

int
jfs2_uselimit(dev,class,uid=getuid(),kind=0)
	char *	dev
	int	class
        int     uid
        int     kind
	CODE:
#if defined(HAVE_JFS2)
        if (strncmp(dev, "(JFS2)", 6) == 0) {
          uid_t id_buf = uid;
          RETVAL = quotactl (dev + 6, QCMD(Q_J2USELIMIT, ((kind != 0) ? GRPQUOTA : USRQUOTA)), class, (caddr_t)&id_buf);
        } else
#endif /* HAVE_JFS2 */
        {
          RETVAL = -1;
          errno = ENOENT;
        }
        OUTPUT:
        RETVAL

void
jfs2_getnextq(dev,class)
	char *	dev
	int	class
	PPCODE:
#if defined(HAVE_JFS2)
        if (strncmp(dev, "(JFS2)", 6) == 0) {
          uid_t id_buf = 0;
          int retval;

          //retval = quotactl (dev + 6, QCMD(Q_J2GETNEXTQ,USRQUOTA), class, (caddr_t) &id_buf);
          retval = quotactl (dev + 6, Q_J2GETNEXTQ, class, (caddr_t) &id_buf);
          printf("Q_J2GETNEXTQ(%s,%d)=%d ID=%d\n",dev+6,class,retval,id_buf);
          if (retval == 0) {
            EXTEND(sp, 1);
            PUSHs(sv_2mortal(newSViv(id_buf)));
          }
        } else
#endif /* HAVE_JFS2 */
        {
          errno = ENOENT;
        }

