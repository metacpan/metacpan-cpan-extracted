/* ********************************************************************	*
 *	inet_aton.c							*
 *									*
 *     COPYRIGHT 2006-2009 Michael Robinton <michael@bizsystems.com>	*
 *									*
 * This program is free software; you can redistribute it and/or modify	*
 * it under the terms of either:					*
 *									*
 *  a) the GNU General Public License as published by the Free		*
 *  Software Foundation; either version 2, or (at your option) any	*
 *  later version, or							*
 *									*
 *  b) the "Artistic License" which comes with this distribution.	*
 *									*
 * This program is distributed in the hope that it will be useful,	*
 * but WITHOUT ANY WARRANTY; without even the implied warranty of	*
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either	*
 * the GNU General Public License or the Artistic License for more 	*
 * details.								*
 *									*
 * You should have received a copy of the Artistic License with this	*
 * distribution, in the file named "Artistic".  If not, I'll be glad 	*
 * to provide one.							*
 *									*
 * You should also have received a copy of the GNU General Public 	*
 * License along with this program in the file named "Copying". If not, *
 * write to the 							*
 *									*
 *	Free Software Foundation, Inc.					*
 *	59 Temple Place, Suite 330					*
 *	Boston, MA  02111-1307, USA					*
 *									*
 * or visit their web page on the internet at:				*
 *									*
 *	http://www.gnu.org/copyleft/gpl.html.				*
 * ********************************************************************	*/

#ifndef HAVE_INET_ATON

int
my_inet_aton(const char *cp, struct in_addr *inp)
{
# ifdef HAVE_INET_PTON
  return inet_pton(AF_INET,cp,inp);
# else
#  ifdef HAVE_INET_ADDR
  inp->s_addr = inet_addr(cp);
  if (inp->s_addr == -1) {
    if (strncmp("255.255.255.255",cp,15))
      return 0;
    else
      return 1;
  }
  return 1;
#  else
# error inet_aton, inet_pton, inet_addr not defined on this platform
#  endif
# endif
}
#define inet_aton my_inet_aton
#endif
