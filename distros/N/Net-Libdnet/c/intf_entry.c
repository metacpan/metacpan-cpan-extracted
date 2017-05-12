/* $Id: intf_entry.c 57 2012-11-02 16:39:39Z gomor $ */

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
intf_c2sv(IntfEntry *entry)
{
   HV *out     = newHV();
   SV *out_ref = newRV_noinc((SV *)out);
   char *sAddr, *sDstAddr, *sLnkAddr;

   hv_store(out, "intf_len",    8, newSViv(entry->intf_len), 0);
   hv_store(out, "intf_name",   9, newSVpv(entry->intf_name, 0), 0);
   hv_store(out, "intf_type",   9, newSViv(entry->intf_type), 0);
   hv_store(out, "intf_flags", 10, newSViv(entry->intf_flags), 0);
   hv_store(out, "intf_mtu",    8, newSViv(entry->intf_mtu), 0);

   sAddr = addr_ntoa(&(entry->intf_addr));
   if (sAddr == NULL) {
      hv_store(out, "intf_addr", 9, &PL_sv_undef, 0);
   }
   else {
      hv_store(out, "intf_addr", 9, newSVpv(sAddr, 0), 0);
   }
   sDstAddr = addr_ntoa(&(entry->intf_dst_addr));
   if (sDstAddr == NULL) {
      hv_store(out, "intf_dst_addr", 13, &PL_sv_undef, 0);
   }
   else {
      hv_store(out, "intf_dst_addr", 13, newSVpv(sDstAddr, 0), 0);
   }
   sLnkAddr = addr_ntoa(&(entry->intf_link_addr));
   if (sLnkAddr == NULL) {
      hv_store(out, "intf_link_addr", 14, &PL_sv_undef, 0);
   }
   else {
      hv_store(out, "intf_link_addr", 14, newSVpv(sLnkAddr, 0), 0);
   }

   hv_store(out, "intf_alias_num", 14, newSViv(entry->intf_alias_num), 0);
   if (entry->intf_alias_num > 0) {
      int i;
      AV *aliases     = newAV();
      SV *aliases_ref = newRV_noinc((SV *)aliases);
      for (i=0; i<entry->intf_alias_num; i++) {
         char *alias = addr_ntoa(&(entry->intf_alias_addrs[i]));
         if (alias != NULL) {
            av_push(aliases, newSVpv(alias, 0));
         }
      }
      hv_store(out, "intf_alias_addrs", 16, aliases_ref, 0);
   }
   else {
      hv_store(out, "intf_alias_addrs", 16, newRV_noinc((SV *)newAV()), 0);
   }

   return out_ref;
}

static IntfEntry *
intf_sv2c(SV *h, IntfEntry *ref)
{
   if (ref && h && SvROK(h)) {
      HV *hv = (HV *)SvRV(h);
      memset(ref, 0, sizeof(IntfEntry));
      if (hv_exists(hv, "intf_len", 8)) {
         SV **len      = hv_fetch((HV *)SvRV(h), "intf_len", 8, 0);
         ref->intf_len = (SvOK(*len) ? SvIV(*len) : 0);
      }
      if (hv_exists(hv, "intf_name", 9)) {
         SV **name = hv_fetch((HV *)SvRV(h), "intf_name", 9, 0);
         if (SvOK(*name)) {
            memcpy(&(ref->intf_name), SvPV(*name, PL_na),
               sizeof(ref->intf_name));
         }
      }
      if (hv_exists(hv, "intf_type", 9)) {
         SV **type      = hv_fetch((HV *)SvRV(h), "intf_type", 9, 0);
         ref->intf_type = (SvOK(*type) ? SvIV(*type) : 0);
      }
      if (hv_exists(hv, "intf_flags", 10)) {
         SV **flags      = hv_fetch((HV *)SvRV(h), "intf_flags", 10, 0);
         ref->intf_flags = (SvOK(*flags) ? SvIV(*flags) : 0);
      }
      if (hv_exists(hv, "intf_mtu", 8)) {
         SV **mtu      = hv_fetch((HV *)SvRV(h), "intf_mtu", 8, 0);
         ref->intf_mtu = (SvOK(*mtu) ? SvIV(*mtu) : 0);
      }
      if (hv_exists(hv, "intf_addr", 9)) {
         SV **addr = hv_fetch((HV *)SvRV(h), "intf_addr", 9, 0);
         if (SvOK(*addr)) {
            struct addr a;
            if (addr_aton(SvPV(*addr, PL_na), &a) == 0) {
               memcpy(&(ref->intf_addr), &a, sizeof(struct addr));
            }
         }
      }
      if (hv_exists(hv, "intf_dst_addr", 13)) {
         SV **dstAddr = hv_fetch((HV *)SvRV(h), "intf_dst_addr", 13, 0);
         if (SvOK(*dstAddr)) {
            struct addr a;
            if (addr_aton(SvPV(*dstAddr, PL_na), &a) == 0) {
               memcpy(&(ref->intf_dst_addr), &a, sizeof(struct addr));
            }
         }
      }
      if (hv_exists(hv, "intf_link_addr", 14)) {
         SV **lnkAddr = hv_fetch((HV *)SvRV(h), "intf_link_addr", 14, 0);
         if (SvOK(*lnkAddr)) {
            struct addr a;
            if (addr_aton(SvPV(*lnkAddr, PL_na), &a) == 0) {
               memcpy(&(ref->intf_link_addr), &a, sizeof(struct addr));
            }
         }
      }
   }
   else {
      ref = NULL;
   }

   // XXX: put aliases also

   return ref;
}
