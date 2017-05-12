/* $Id: fw_rule.c 57 2012-11-02 16:39:39Z gomor $ */

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
fw_c2sv(FwRule *rule)
{
   HV *out     = newHV();
   SV *out_ref = newRV_noinc((SV *)out);
   AV *sport, *dport;
   char *src, *dst;
   int i;

   hv_store(out, "fw_device", 9, newSVpv(rule->fw_device, 0), 0);
   hv_store(out, "fw_op", 5, newSViv(rule->fw_op), 0);
   hv_store(out, "fw_dir", 6, newSViv(rule->fw_dir), 0);
   hv_store(out, "fw_proto", 8, newSViv(rule->fw_proto), 0);
   src = addr_ntoa(&(rule->fw_src));
   if (src == NULL) {
      hv_store(out, "fw_src", 6, &PL_sv_undef, 0);
   }
   else {
      hv_store(out, "fw_src", 6, newSVpv(src, 0), 0);
   }
   dst = addr_ntoa(&(rule->fw_dst));
   if (dst == NULL) {
      hv_store(out, "fw_dst", 6, &PL_sv_undef, 0);
   }
   else {
      hv_store(out, "fw_dst", 6, newSVpv(dst, 0), 0);
   }
   sport = newAV();
   dport = newAV();
   for (i=0; i<2; i++) {
      av_push(sport, newSViv(rule->fw_sport[i]));
      av_push(dport, newSViv(rule->fw_dport[i]));
   }
   hv_store(out, "fw_sport", 8, newRV_noinc((SV *)sport), 0);
   hv_store(out, "fw_dport", 8, newRV_noinc((SV *)dport), 0);

   return out_ref;
}

static FwRule *
fw_sv2c(SV *h, FwRule *ref)
{
   if (ref && h && SvROK(h)) {
      HV *hv = (HV *)SvRV(h);
      memset(ref, 0, sizeof(FwRule));
      if (hv_exists(hv, "fw_device", 9)) {
         SV **r = hv_fetch(hv, "fw_device", 9, 0);
         if (SvOK(*r)) {
            memcpy(&(ref->fw_device), SvPV(*r, PL_na), sizeof(ref->fw_device));
         }
      }
      if (hv_exists(hv, "fw_op", 5)) {
         SV **r = hv_fetch(hv, "fw_op", 5, 0);
         ref->fw_op = (SvOK(*r) ? SvIV(*r) : 0);
      }
      if (hv_exists(hv, "fw_dir", 6)) {
         SV **r = hv_fetch(hv, "fw_dir", 6, 0);
         ref->fw_dir = (SvOK(*r) ? SvIV(*r) : 0);
      }
      if (hv_exists(hv, "fw_proto", 8)) {
         SV **r = hv_fetch(hv, "fw_proto", 8, 0);
         ref->fw_proto = (SvOK(*r) ? SvIV(*r) : 0);
      }
      if (hv_exists(hv, "fw_src", 6)) {
         SV **r = hv_fetch(hv, "fw_src", 6, 0);
         if (SvOK(*r)) {
            struct addr a;
            if (addr_aton(SvPV(*r, PL_na), &a) == 0) {
               memcpy(&(ref->fw_src), &a, sizeof(struct addr));
            }
         }
      }
      if (hv_exists(hv, "fw_dst", 6)) {
         SV **r = hv_fetch(hv, "fw_dst", 6, 0);
         if (SvOK(*r)) {
            struct addr a;
            if (addr_aton(SvPV(*r, PL_na), &a) == 0) {
               memcpy(&(ref->fw_dst), &a, sizeof(struct addr));
            }
         }
      }
      if (hv_exists(hv, "fw_sport", 8)) {
         SV **r = hv_fetch(hv, "fw_sport", 8, 0);
         if (SvOK(*r)) {
            AV *a = (AV *)SvRV(*r);
            SV *p1 = av_shift(a);
            SV *p2 = av_shift(a);
            ref->fw_sport[0] = (SvOK(p1) ? SvIV(p1) : 0);
            ref->fw_sport[1] = (SvOK(p2) ? SvIV(p2) : 0);
         }
      }
      if (hv_exists(hv, "fw_dport", 8)) {
         SV **r = hv_fetch(hv, "fw_dport", 8, 0);
         if (SvOK(*r)) {
            AV *a = (AV *)SvRV(*r);
            SV *p1 = av_shift(a);
            SV *p2 = av_shift(a);
            ref->fw_dport[0] = (SvOK(p1) ? SvIV(p1) : 0);
            ref->fw_dport[1] = (SvOK(p2) ? SvIV(p2) : 0);
         }
      }
   }
   else {
      ref = NULL;
   }

   return ref;
}
