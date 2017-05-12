/* 
 * $Id: Lorcon2.xs 31 2015-02-17 07:04:36Z gomor $
 *
 * Copyright (c) 2010-2015 Patrice <GomoR> Auffret
 *
 * LICENSE
 *
 * This program is free software. You can redistribute it and/or modify it
 * under the following terms:
 * - the Perl Artistic License (in the file LICENSE.Artistic)
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <lorcon2/lorcon.h>
#include <lorcon2/lorcon_packet.h>

typedef lorcon_t         NetLorcon;
typedef lorcon_driver_t  NetLorconDriver;
typedef lorcon_packet_t  NetLorconPacket;

#include "c/lorcon_driver_t.c"

MODULE = Net::Lorcon2   PACKAGE = Net::Lorcon2
PROTOTYPES: DISABLE

const char *
lorcon_get_error(context)
      NetLorcon *context

AV *
lorcon_list_drivers()
   INIT:
      lorcon_driver_t *list = lorcon_list_drivers();
      lorcon_driver_t *cur = NULL;
      AV *av = newAV();
   CODE:
      for (cur = list; cur != NULL; cur = cur->next) {
         SV *this = lorcon_driver_t_c2sv(cur);
         av_push(av, this);
      }
      lorcon_free_driver_list(list);
      RETVAL = av;
   OUTPUT:
      RETVAL

NetLorconDriver *
lorcon_find_driver(driver)
      const char *driver

NetLorconDriver *
lorcon_auto_driver(interface)
      const char *interface

void
lorcon_free_driver_list(list)
      NetLorconDriver *list

NetLorcon *
lorcon_create(interface, driver)
      const char *interface
      NetLorconDriver *driver

void
lorcon_free(context)
      NetLorcon *context

void
lorcon_set_timeout(context, timeout)
      NetLorcon *context
      int timeout

int
lorcon_get_timeout(context)
      NetLorcon *context

int
lorcon_open_inject(context)
      NetLorcon *context

int
lorcon_open_monitor(context)
      NetLorcon *context

int
lorcon_open_injmon(context)
      NetLorcon *context

void
lorcon_set_vap(context, vap)
      NetLorcon *context
      const char *vap

const char *
lorcon_get_vap(context)
      NetLorcon *context

const char *
lorcon_get_capiface(context)
      NetLorcon *context

const char *
lorcon_get_driver_name(context)
      NetLorcon *context

void
lorcon_close(context)
      NetLorcon *context

#int
#lorcon_get_datalink(context)
      #NetLorcon *context

#int
#lorcon_set_datalink(context, dlt)
      #NetLorcon *context
      #int dlt

int
lorcon_set_channel(context, channel)
      NetLorcon *context
      int channel

int
lorcon_get_channel(context)
      NetLorcon *context

#int
#lorcon_get_hwmac(context, mac)
      #NetLorcon *context
      #uint8_t **mac

#int
#lorcon_set_hwmac(context, mac_len, mac)
      #NetLorcon *context
      #int mac_len
      #uint8_t *mac

#pcap_t *
#lorcon_get_pcap(context)
#      NetLorcon *context

int
lorcon_get_selectable_fd(context)
      NetLorcon *context

#int
#lorcon_next_ex(context, packet)
      #NetLorcon *context
      #NetLorconPacket **packet

int
lorcon_set_filter(context, filter)
      NetLorcon *context
      const char *filter

#int
#lorcon_set_compiled_filter(context, filter)
      #NetLorcon *context
      #struct bpf_program *filter

#int lorcon_loop(lorcon_t *context, int count, lorcon_handler callback, u_char *user);
#int lorcon_dispatch(lorcon_t *context, int count, lorcon_handler callback, u_char *user);
#void lorcon_breakloop(lorcon_t *context);

int
lorcon_inject(context, packet)
      NetLorcon *context
      NetLorconPacket *packet

int
lorcon_send_bytes(context, length, bytes)
      NetLorcon *context
      int length
      u_char *bytes

unsigned long int
lorcon_get_version()

int
lorcon_add_wepkey(context, bssid, key, length)
      NetLorcon *context
      u_char *bssid
      u_char *key
      int length
