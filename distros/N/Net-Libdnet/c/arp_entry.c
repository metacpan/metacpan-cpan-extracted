/* $Id: arp_entry.c 57 2012-11-02 16:39:39Z gomor $ */

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
arp_c2sv(ArpEntry *entry)
{
   HV *out     = newHV();
   SV *out_ref = newRV_noinc((SV *)out);
   char *pa, *ha;

   pa = addr_ntoa(&(entry->arp_pa));
   if (pa == NULL) {
      hv_store(out, "arp_pa", 6, &PL_sv_undef, 0);
   }
   else {
      hv_store(out, "arp_pa", 6, newSVpv(pa, 0), 0);
   }
   ha = addr_ntoa(&(entry->arp_ha));
   if (ha == NULL) {
      hv_store(out, "arp_ha", 6, &PL_sv_undef, 0);
   }
   else {
      hv_store(out, "arp_ha", 6, newSVpv(ha, 0), 0);
   }

   return out_ref;
}

static ArpEntry *
arp_sv2c(SV *h, ArpEntry *ref)
{
   if (ref && h && SvROK(h)) {
      HV *hv = (HV *)SvRV(h);
      memset(ref, 0, sizeof(ArpEntry));
      if (hv_exists(hv, "arp_pa", 6)) {
         SV **pa = hv_fetch(hv, "arp_pa", 6, 0);
         if (SvOK(*pa)) {
            struct addr a;
            if (addr_aton(SvPV(*pa, PL_na), &a) == 0) {
               memcpy(&(ref->arp_pa), &a, sizeof(struct addr));
            }
         }
      }
      if (hv_exists(hv, "arp_ha", 6)) {
         SV **ha = hv_fetch(hv, "arp_ha", 6, 0);
         if (SvOK(*ha)) {
            struct addr a;
            if (addr_aton(SvPV(*ha, PL_na), &a) == 0) {
               memcpy(&(ref->arp_ha), &a, sizeof(struct addr));
            }
         }
      }
   }
   return ref;
}
