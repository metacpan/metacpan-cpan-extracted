/* $Id: route_entry.c 57 2012-11-02 16:39:39Z gomor $ */

/*
 * Copyright (c) 2008-2012 Patrice <GomoR> Auffret
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

SV *
route_c2sv(RouteEntry *entry)
{
   HV *out     = newHV();
   SV *out_ref = newRV_noinc((SV *)out);
   char *dst, *gw;
   if (entry != NULL) {
      dst = addr_ntoa(&(entry->route_dst));
      dst == NULL ? hv_store(out, "route_dst", 9, &PL_sv_undef, 0)
                  : hv_store(out, "route_dst", 9, newSVpv(dst, 0), 0);
      gw = addr_ntoa(&(entry->route_gw));
      gw == NULL ? hv_store(out, "route_gw", 8, &PL_sv_undef, 0)
                 : hv_store(out, "route_gw", 8, newSVpv(gw, 0), 0);
   }
   return out_ref;
}

static RouteEntry *
route_sv2c(SV *h, RouteEntry *ref)
{
   if (ref && h && SvROK(h)) {
      HV *hv = (HV *)SvRV(h);
      memset(ref, 0, sizeof(RouteEntry));
      if (hv_exists(hv, "route_dst", 9)) {
         SV **r = hv_fetch(hv, "route_dst", 9, 0);
         if (SvOK(*r)) {
            struct addr a;
            if (addr_aton(SvPV(*r, PL_na), &a) == 0) {
               memcpy(&(ref->route_dst), &a, sizeof(struct addr));
            }
         }
      }
      if (hv_exists(hv, "route_gw", 8)) {
         SV **r = hv_fetch(hv, "route_gw", 8, 0);
         if (SvOK(*r)) {
            struct addr a;
            if (addr_aton(SvPV(*r, PL_na), &a) == 0) {
               memcpy(&(ref->route_gw), &a, sizeof(struct addr));
            }
         }
      }
   }
   else {
      ref = NULL;
   }
   return ref;
}
