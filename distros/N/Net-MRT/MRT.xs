/*
 * MRT.xs
 * $Id$
 *
 * Copyright (C) 2013 MaxiM Basunov <maxim.basunov@gmail.com>
 * All rights reserved.
 *
 * This program is free software; you may redistribute it and/or
 * modify it under the same terms as Perl itself.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
// #include "poll.h"
#ifdef I_UNISTD
#  include <unistd.h>
#endif
#if defined(I_FCNTL) || defined(HAS_FCNTL)
#  include <fcntl.h>
#endif

//#include "ppport.h"
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <arpa/inet.h>
#include "mrttypes.h"

// Windows XP workaround for inet_ntop
// TODO: Windows Vista/7 can use InetNtop
// TODO: http://vinsworldcom.blogspot.com/2012/08/ipv6-in-perl-on-windows_20.html
#ifdef WIN32
    #include "inet_ntop.c"
#endif

// String buffer size
#define SBUFF 200

// Global variables
SV* USE_RFC4760;

// Function to decode single MRT message and compose HV contents
void mrt_decode(HV* const rt, Off_t const msgpos, MRT_MESSAGE* const mh)
{
    char sbuff[SBUFF] = {}; // Char buffer for SNPRINTF
    char* pPos = (char*)&mh->message; // Current read position
    int AF = 0; // Address family from message
    uint32_t iSeq; // Sequence number from MRT
    struct sockaddr_in6 sa6;
    memset(&sa6, 0, sizeof(sa6));
    char cIpAddress[INET6_ADDRSTRLEN]; // Buffer for INET_PTON
    int iRemainingLen = mh->length; // Self-check for buffer remaining length

    // Some temporary variables
    AV* avTmpAv;
    uint8_t iTmpU8;
    uint16_t iTmpU16;
    uint32_t iTmpU32;

#   ifdef _DEBUG_
    printf("mrt_decode_single(): Input type: %d subtype %d data len: %d\n", mh->type, mh->subtype, mh->length);
#   endif
    switch (mh->type) {
        case MT_TABLE_DUMP_V2:
            switch (mh->subtype) {
                case MST_TD2_PEER_INDEX_TABLE:
//PEER_INDEX_TABLE
//4 Collector BGP ID - ID of this collector
//2 view name length (can be =0)
//V View Name (optional)
//2 Peer count
//V Peers (index start with 0)
//
//PEER:
//1 PEer type 000000AI. A=2 - AS 32 bit; IP=1 - IPv6
//4 Peer BGP ID
//IP Peer IP address
//AS Peer AS number
                    // Decode Collector BGP ID
                    memset(&sa6, 0, sizeof(sa6));
                    mrt_copy_next(&pPos, &sa6, 4, &iRemainingLen);
                    inet_ntop(AF_INET, &sa6, cIpAddress, INET6_ADDRSTRLEN);
                    hv_stores(rt, "collector_bgp_id", newSVpv(cIpAddress, 0));

                    // Decode View name
                    mrt_copy_next(&pPos, &iTmpU16, 2, &iRemainingLen);
                    iTmpU16 = ntohs(iTmpU16);
                    if (iTmpU16 > 0) {
                        SV* svViewName = newSVpv(pPos, iTmpU16);
                        SvUTF8_on(svViewName);
                        hv_stores(rt, "view_name", svViewName);
                        pPos += iTmpU16;
                        iRemainingLen -= iTmpU16;
                    } else {
                        hv_stores(rt, "view_name", &PL_sv_undef);
                    }

                    // Decode amount of peers
                    uint16_t iPeerCount;
                    mrt_copy_next(&pPos, &iPeerCount, 2, &iRemainingLen);
                    iPeerCount = htons(iPeerCount);

                    // Store peers container
                    avTmpAv = newAV();
                    hv_stores(rt, "peers", newRV_noinc((SV *)avTmpAv));

                    // Decode peers
                    while (iPeerCount > 0)
                    {
                        iPeerCount--;
                        // Append new onePeer container
                        HV* hvOnePeer = newHV();
                        av_push(avTmpAv, newRV_noinc((SV *)hvOnePeer));

                        // Decode Peer's Type
                        PEER_TYPE ptPT;
                        mrt_copy_next(&pPos, &ptPT, 1, &iRemainingLen);

                        // Decode Peer's BGP ID
                        memset(&sa6, 0, sizeof(sa6));
                        mrt_copy_next(&pPos, &sa6, 4, &iRemainingLen);
                        inet_ntop(AF_INET, &sa6, cIpAddress, INET6_ADDRSTRLEN);
                        hv_stores(hvOnePeer, "bgp_id", newSVpv(cIpAddress, 0));

                        // Decode Peer's IP address
                        memset(&sa6, 0, sizeof(sa6));
                        mrt_copy_next(&pPos, &sa6, (!ptPT.ipv6 ? 4 : 16), &iRemainingLen);
                        inet_ntop((!ptPT.ipv6 ? AF_INET : AF_INET6), &sa6, cIpAddress, INET6_ADDRSTRLEN);
                        hv_stores(hvOnePeer, "peer_ip", newSVpv(cIpAddress, 0));

                        // Decode Peer's AS number
                        if (!ptPT.as32)
                        {
                            mrt_copy_next(&pPos, &iTmpU16, 2, &iRemainingLen);
                            iTmpU16 = ntohs(iTmpU16);
                            hv_stores(hvOnePeer, "as", newSVuv(iTmpU16));
                        } else {
                            mrt_copy_next(&pPos, &iTmpU32, 4, &iRemainingLen);
                            iTmpU32 = ntohl(iTmpU32);
                            hv_stores(hvOnePeer, "as", newSVuv(iTmpU32));
                        }
                    } // while (iPeerCount > 0)
                    break; // MST_TD2_PEER_INDEX_TABLE
                // Try to decode MULTICAST/ANYCAST
                //case MST_TD2_RIB_IPV6_MULTICAST:
                case MST_TD2_RIB_IPV6_UNICAST:
                    AF = AF_INET6;
                //case MST_TD2_RIB_IPV4_MULTICAST:
                case MST_TD2_RIB_IPV4_UNICAST:
                    if (AF == 0) AF = AF_INET; // Address Family also set for IPV6 messages

                    // Decode Sequence
                    mrt_copy_next(&pPos, &iSeq, 4, &iRemainingLen);
                    iSeq = ntohl(iSeq);
                    hv_stores(rt, "sequence", newSVuv(iSeq));

                    // Decode Prefix Bits
                    uint8_t iPrefixBits;
                    mrt_copy_next(&pPos, &iPrefixBits, 1, &iRemainingLen);
                    hv_stores(rt, "bits", newSVuv(iPrefixBits));

                    // Decode Prefix
                    memset(&sa6, 0, sizeof(sa6));
                    if (iPrefixBits > 0)
                        mrt_copy_next(&pPos, &sa6, (int)ceil((double)iPrefixBits/8), &iRemainingLen);
                    inet_ntop(AF, &sa6, cIpAddress, INET6_ADDRSTRLEN);
                    hv_stores(rt, "prefix", newSVpv(cIpAddress, 0));

                    // Decode count of entries
                    uint16_t iEntries;
                    mrt_copy_next(&pPos, &iEntries, 2, &iRemainingLen);
                    iEntries = ntohs(iEntries);
#                   ifdef _DEBUG_
                    printf("mrt_decode_single(): Decoded prefix %s/%d\n", cIpAddress, iPrefixBits);
                    printf("mrt_decode_single(): Decode have %d entries\n", iEntries);
#                   endif

                    // Prepare entres
                    AV* avEntries = newAV();
                    hv_stores(rt, "entries", newRV_noinc((SV *)avEntries));
                    // Loop each entry

                    while (iEntries > 0)
                    {
                        iEntries--;
                        AV* avNextHop = NULL; // NEXT_HOP container
                        AV* avAsPath  = NULL; // AS_PATH container

#                       ifdef _DEBUG_
                        printf("mrt_decode_single(): %d entries remaining\n", iEntries);
#                       endif
                        // Prepare Entry HashRef

                        HV* hvEntry = newHV();
                        av_push(avEntries, newRV_noinc((SV *)hvEntry));

                        // Decode one entry
                        uint16_t iPeer;
                        mrt_copy_next(&pPos, &iPeer, 2, &iRemainingLen);
                        iPeer = ntohs(iPeer);
                        hv_stores(hvEntry, "peer_index", newSVuv(iPeer));

                        // Decode Originated Time
                        int32_t orig_time;
                        mrt_copy_next(&pPos, &orig_time, 4, &iRemainingLen);
                        orig_time = ntohl(orig_time);
                        hv_stores(hvEntry, "originated_time", newSViv(orig_time));

                        // Store length of BGP attributes
                        uint16_t iBgpAttributesLen;
                        int iBgpAttributesRemainLen;
                        mrt_copy_next(&pPos, &iBgpAttributesLen, 2, &iRemainingLen);
                        iBgpAttributesRemainLen = iBgpAttributesLen = ntohs(iBgpAttributesLen);

                        // Store pointer to BGP attributes
                        char* pBgpAttributes = pPos;
                        if (iRemainingLen < iBgpAttributesLen)
                            croak("Attempt to read %d bytes while buffer contain only %d", iBgpAttributesLen, iRemainingLen);
                        pPos = pPos + iBgpAttributesLen; // Skip pPos to next entry
                        iRemainingLen -= iBgpAttributesLen; // Decrease main remaining length

                        // Scan each BGP attribute
                        while (iBgpAttributesRemainLen > 0) // pPos points to next entry
                        {
                            // Parse each attribute
                            uint8_t attribute_flags;
                            mrt_copy_next(&pBgpAttributes, &attribute_flags, 1, &iBgpAttributesRemainLen);
                            uint8_t attribute_code;
                            mrt_copy_next(&pBgpAttributes, &attribute_code, 1, &iBgpAttributesRemainLen);
                            // Check for Extended Length and read length
                            uint16_t iAttributeLen = 0;
                            int iAttributeRemainLen;
                            if (attribute_flags & 0x10) {
                                mrt_copy_next(&pBgpAttributes, &iAttributeLen, 2, &iBgpAttributesRemainLen);
                                iAttributeLen = ntohs(iAttributeLen);
                            } else {
                                uint8_t att_len_8;
                                mrt_copy_next(&pBgpAttributes, &att_len_8, 1, &iBgpAttributesRemainLen);
                                iAttributeLen = att_len_8;
                            }
                            iAttributeRemainLen = iAttributeLen;
#                           ifdef _DEBUG_
                            printf("mrt_decode_single(): Decoding attribute code %d (len %d)\n", attribute_code, iAttributeLen);
#                           endif

                            // Decode attributes
                            switch (attribute_code)
                            {
                                // 1	ORIGIN	[RFC4271]
                                case 1:
                                    mrt_copy_next(&pBgpAttributes, &iTmpU8, 1, &iBgpAttributesRemainLen);
                                    hv_stores(hvEntry, "ORIGIN", newSVuv(iTmpU8));
                                    break;
                                // 2	AS_PATH	[RFC4271]
                                case 2:
                                    // Check for absent NEXT_HOP array and create it
                                    if (avAsPath == NULL)
                                    {
                                        avAsPath = newAV();
                                        hv_stores(hvEntry, "AS_PATH", newRV_noinc((SV *)avAsPath));
                                    }
                                    while (iAttributeRemainLen > 0)
                                    {
                                        // Read next AS_PATH subtype
                                        iAttributeRemainLen -= 2;
                                        uint8_t iPathType;
                                        uint8_t iPathCount;
                                        mrt_copy_next(&pBgpAttributes, &iPathType, 1, &iBgpAttributesRemainLen);
                                        mrt_copy_next(&pBgpAttributes, &iPathCount, 1, &iBgpAttributesRemainLen);

                                        uint32_t iAsPathEntry;
                                        // Decode AS_SET & AS_SEQUENCE
                                        AV* avTmpAv2 = NULL;
                                        if (iPathType == 1) // Compose subarray in case of AS_SET
                                        {
                                            avTmpAv2 = newAV();
                                            av_push(avAsPath, newRV_noinc((SV *)avTmpAv2));
                                        }
                                        while (iPathCount > 0) {
                                            iPathCount--;
                                            iAttributeRemainLen -= 4; // NOTE: RIPE RIS hold 4-byte ASn in AS_PATH
                                            mrt_copy_next(&pBgpAttributes, &iAsPathEntry, 4, &iBgpAttributesRemainLen);
                                            iAsPathEntry = ntohl(iAsPathEntry);
                                            av_push(((iPathType == 1)? avTmpAv2 : avAsPath), newSVuv(iAsPathEntry));
                                        }
                                    } // end while (iAttributeRemainLen > 0)
                                    break; // 2	AS_PATH	[RFC4271]
                                // 3	NEXT_HOP	[RFC4271]
                                case 3:
                                    // Check for absent NEXT_HOP array and create it
                                    if (avNextHop == NULL)
                                    {
                                        avNextHop = newAV();
                                        hv_stores(hvEntry, "NEXT_HOP", newRV_noinc((SV *)avNextHop));
                                    }

                                    mrt_copy_next(&pBgpAttributes, &iTmpU32, 4, &iBgpAttributesRemainLen);
                                    inet_ntop(AF_INET, &iTmpU32, cIpAddress, INET6_ADDRSTRLEN);
                                    av_push(avNextHop, newSVpv(cIpAddress, 0));
                                    break;// 3	NEXT_HOP	[RFC4271]
                                // 4	MULTI_EXIT_DISC	[RFC4271]
                                case 4:
                                    mrt_copy_next(&pBgpAttributes, &iTmpU32, 4, &iBgpAttributesRemainLen);
                                    iTmpU32 = ntohl(iTmpU32);
                                    hv_stores(hvEntry, "MULTI_EXIT_DISC", newSVuv(iTmpU32));
                                    break;// 4	MULTI_EXIT_DISC	[RFC4271]
                                // 5	LOCAL_PREF	[RFC4271]
                                case 5:
                                    mrt_copy_next(&pBgpAttributes, &iTmpU32, 4, &iBgpAttributesRemainLen);
                                    iTmpU32 = ntohl(iTmpU32);
                                    hv_stores(hvEntry, "LOCAL_PREF", newSVuv(iTmpU32));
                                    break;// 5	LOCAL_PREF	[RFC4271]
                                // 6	ATOMIC_AGGREGATE	[RFC4271]
                                case 6:
                                    hv_stores(hvEntry, "ATOMIC_AGGREGATE", &PL_sv_undef);
                                    break;// 6	ATOMIC_AGGREGATE	[RFC4271]
                                // 7	AGGREGATOR	[RFC4271]
                                case 7:
                                    mrt_copy_next(&pBgpAttributes, &iTmpU32, 4, &iBgpAttributesRemainLen);
                                    iTmpU32 = ntohl(iTmpU32);
                                    hv_stores(hvEntry, "AGGREGATOR_AS", newSVuv(iTmpU32));
                                    mrt_copy_next(&pBgpAttributes, &iTmpU32, 4, &iBgpAttributesRemainLen);
                                    inet_ntop(AF_INET, &iTmpU32, cIpAddress, INET6_ADDRSTRLEN);
                                    hv_stores(hvEntry, "AGGREGATOR_BGPID", newSVpv(cIpAddress, 0));
                                    break;// 7	AGGREGATOR	[RFC4271]
                                // 8	COMMUNITY	[RFC1997]
                                case 8:
                                    avTmpAv = (AV *)sv_2mortal((SV *)newAV());
                                    hv_stores(hvEntry, "COMMUNITY", newRV_inc((SV *)avTmpAv));

                                    while (iAttributeRemainLen > 0)
                                    {
                                        // Read and decode community
                                        iAttributeRemainLen -= 4;
                                        uint16_t c1, c2;
                                        mrt_copy_next(&pBgpAttributes, &c1, 2, &iBgpAttributesRemainLen);
                                        c1 = ntohs(c1);
                                        mrt_copy_next(&pBgpAttributes, &c2, 2, &iBgpAttributesRemainLen);
                                        c2 = ntohs(c2);
                                        snprintf(sbuff, SBUFF, "%d:%d", c1, c2);
                                        av_push(avTmpAv, newSVpv(sbuff, 0));
                                    } // end while (iAttributeRemainLen > 0)
                                    break;
                                // 14	MP_REACH_NLRI   http://tools.ietf.org/html/rfc6396#section-4.3.4
                                case 14:
                                    // Check for absent NEXT_HOP array and create it
                                    if (avNextHop == NULL)
                                    {
                                        avNextHop = newAV();
                                        hv_stores(hvEntry, "NEXT_HOP", newRV_noinc((SV *)avNextHop));
                                    }
                                    if (SvOK(USE_RFC4760) && SvIV(USE_RFC4760) == 1)
                                    {
                                        // read AFI
                                        uint16_t AFI;
                                        mrt_copy_next(&pBgpAttributes, &iTmpU16, 2, &iBgpAttributesRemainLen);
                                        AFI = ntohs(iTmpU16);
                                        // read/skip SAFI
                                        mrt_copy_next(&pBgpAttributes, &iTmpU8, 1, &iBgpAttributesRemainLen);
                                        // read LEN
                                        mrt_copy_next(&pBgpAttributes, &iTmpU8, 1, &iBgpAttributesRemainLen);
                                        iAttributeRemainLen -= 4;
                                        // validate LEN & decode IP
                                        bool bSkip = false;
                                        if (AFI == 1 && iTmpU8 == 4)
                                        {
                                            // Read and decode IPv4
                                            memset(&sa6, 0, sizeof(sa6));
                                            mrt_copy_next(&pBgpAttributes, &sa6, iTmpU8, &iBgpAttributesRemainLen);
                                            iAttributeRemainLen -= iTmpU8;
                                            inet_ntop(AF_INET, &sa6, cIpAddress, INET6_ADDRSTRLEN);
                                            av_push(avNextHop, newSVpv(cIpAddress, 0));
                                        } else if (AFI == 2 && (iTmpU8 == 16 || iTmpU8 == 32)) // AFI=IPv6
                                        {
                                            // Read and decode IPv6
                                            memset(&sa6, 0, sizeof(sa6));
                                            mrt_copy_next(&pBgpAttributes, &sa6, 16, &iBgpAttributesRemainLen);
                                            iAttributeRemainLen -= 16;
                                            inet_ntop(AF_INET6, &sa6, cIpAddress, INET6_ADDRSTRLEN);
                                            av_push(avNextHop, newSVpv(cIpAddress, 0));
                                            if (iTmpU8 == 32) // Case for combined Global and Link Local IPv6
                                            {
                                                memset(&sa6, 0, sizeof(sa6));
                                                mrt_copy_next(&pBgpAttributes, &sa6, 16, &iBgpAttributesRemainLen);
                                                iAttributeRemainLen -= 16;
                                                inet_ntop(AF_INET6, &sa6, cIpAddress, INET6_ADDRSTRLEN);
                                                av_push(avNextHop, newSVpv(cIpAddress, 0));
                                            }
                                        } else {
                                            snprintf(sbuff, SBUFF, "Unsupported/invalid AFI %d len %d", AFI, iTmpU8);
                                            hv_stores(hvEntry, "MP_REACH_NLRI", newSVpv(sbuff, 0));
                                            // Skip to end of attribute
                                            bSkip = true;
                                        }
                                        if (!bSkip) {
                                            // Process MP_REACH_NLRI
                                            mrt_copy_next(&pBgpAttributes, &iTmpU8, 1, &iBgpAttributesRemainLen); // Skip reserved byte
                                            iAttributeRemainLen--;

                                            avTmpAv = (AV *)sv_2mortal((SV *)newAV());
                                            hv_stores(hvEntry, "MP_REACH_NLRI", newRV_inc((SV *)avTmpAv));

                                            while (iAttributeRemainLen > 0)
                                            {
                                                // Read and decode NLRI
                                                // Decode Prefix Bits
                                                uint8_t iBits;
                                                mrt_copy_next(&pBgpAttributes, &iBits, 1, &iBgpAttributesRemainLen);
                                                iAttributeRemainLen--;
                                                hv_stores(rt, "bits", newSVuv(iPrefixBits));

                                                // Decode Prefix
                                                memset(&sa6, 0, sizeof(sa6));
                                                if (iPrefixBits > 0) {
                                                    mrt_copy_next(&pBgpAttributes, &sa6, (int)ceil((double)iBits/8), &iBgpAttributesRemainLen);
                                                    iAttributeRemainLen -= (int)ceil((double)iBits/8);
                                                }
                                                inet_ntop((AFI == 1 ? AF_INET : AF_INET6), &sa6, cIpAddress, INET6_ADDRSTRLEN);

                                                snprintf(sbuff, SBUFF, "%s/%d", cIpAddress, iBits);
                                                av_push(avTmpAv, newSVpv(sbuff, 0));
                                            } // end while (iAttributeRemainLen > 0)
                                        }
                                        pBgpAttributes += iAttributeRemainLen;
                                        iBgpAttributesRemainLen -= iAttributeRemainLen;
                                    } else if (SvOK(USE_RFC4760) && SvIV(USE_RFC4760) == -1) {
                                        pBgpAttributes += iAttributeLen;
                                        iBgpAttributesRemainLen -= iAttributeLen;
                                    } else {
                                        // Use RFC 6396
                                        iTmpU8 = (AF == AF_INET ? 4 : 16); // Store size of IP address for AF
                                        // Read size of MRT MP_REACH_NLRI
                                        mrt_copy_next(&pBgpAttributes, &iAttributeRemainLen, 1, &iBgpAttributesRemainLen);
#                                       ifdef _DEBUG_
                                        printf("mrt_decode_single(): Attribute 14 have %u bytes for AF. Remain %d bytes\n", iTmpU8, iAttributeRemainLen);
#                                       endif
                                        while (iAttributeRemainLen > 0)
                                        {
                                            iAttributeRemainLen -= iTmpU8;
                                            memset(&sa6, 0, sizeof(sa6));
                                            mrt_copy_next(&pBgpAttributes, &sa6, iTmpU8, &iBgpAttributesRemainLen);
                                            inet_ntop(AF, &sa6, cIpAddress, INET6_ADDRSTRLEN);
                                            av_push(avNextHop, newSVpv(cIpAddress, 0));
                                        }
                                    } // end else if RFC4760
                                    break;// 14	MP_REACH_NLRI	[RFC4760]
                                default:
                                    hv_store(hvEntry, sbuff, strlen(sbuff), &PL_sv_undef, 0);
                                    pBgpAttributes += iAttributeLen;
                                    iBgpAttributesRemainLen -= iAttributeLen;
                            } // switch (attribute_code)
                        } // iBgpAttributesRemainLen > 0
                    } // while (iEntries > 0)

                    break; // subtype = IPv4/6 UNICAST/MULTICAST
                default:
                    snprintf(sbuff, SBUFF, "Unsupported MRT type %d subtype %d in message at %lli", mh->type, mh->subtype, (intmax_t)msgpos);
                    hv_stores(rt, "error", newSVpv(sbuff, 0));
            } // switch subtype
            break; // MT_TABLE_DUMP_V2
        default:
            snprintf(sbuff, SBUFF, "Unsupported MRT type %d in message at %lli", mh->type, (intmax_t)msgpos);
            hv_stores(rt, "error", newSVpv(sbuff, 0));
    } // switch message type
    return;
}

MODULE = Net::MRT		PACKAGE = Net::MRT

void
mrt_read_next(f)
PerlIO * f;
    PROTOTYPE: *
    PPCODE:
        # Definitions
        Off_t msgpos = PerlIO_tell(f); // Store message position & check for proper handle
        int sz;
        MRT_MESSAGE mh;
        char sbuff[SBUFF] = {};
        HV* rt;

        if (msgpos == -1)
            croak("Invalid filehandle passed to mrt_read_next");
        sz = PerlIO_read(f, &mh, 12);
        if (sz == 0)
        {
            # No data to read
            ST(0) = &PL_sv_undef;
            XSRETURN(1);
        } else {
            # Network to host for MH
            mh.timestamp = ntohl(mh.timestamp);
            mh.type      = ntohs(mh.type);
            mh.subtype   = ntohs(mh.subtype);
            mh.length    = ntohl(mh.length);

            # Create resulting HASHREF
            rt = newHV();
            hv_stores(rt, "timestamp",  newSVuv(mh.timestamp));
            hv_stores(rt, "type",       newSVuv(mh.type));
            hv_stores(rt, "subtype",    newSVuv(mh.subtype));

            # Decode header
            # Check for length to be less than buffer
            if (mh.length > BUFFER_SIZE)
            {
                snprintf(sbuff, SBUFF, "Message length too big at %lli", (intmax_t)msgpos);
                hv_stores(rt, "error", newSVpv(sbuff, 0));
                while (mh.length > 0) {
                    auto remainder = (BUFFER_SIZE < mh.length ? BUFFER_SIZE : mh.length);
                    printf("remaining: %d to do: %d %d\n", mh.length, remainder, BUFFER_SIZE); fflush(stdout);
                    sz = PerlIO_read(f, &mh.message, remainder);
                    mh.length -= remainder;
                }
            } else {
                # Try to read message
                if (mh.length > 0)
                    sz = PerlIO_read(f, &mh.message, mh.length);
                if ((mh.length > 0) && (sz != mh.length))
                    croak("Unable to read %d bytes in message at pos %lli", mh.length, (intmax_t)msgpos);

                # Try to decode
                mrt_decode(rt, msgpos, &mh);
            }
            ST(0) = sv_2mortal((SV*)newRV_noinc((SV*)rt));
            XSRETURN(1);
        }

void
mrt_get_next(f)
PerlIO * f;
    PROTOTYPE: *
    PPCODE:
        # Definitions
        Off_t msgpos = PerlIO_tell(f); // Store message position & check for proper handle
        int sz;
        MRT_MESSAGE mh;
        char sbuff[SBUFF] = {};
        HV* rt;

        if (msgpos == -1)
            croak("Invalid filehandle passed to mrt_read_next");
        sz = PerlIO_read(f, &mh, 12);
        if (sz == 0)
        {
            # No data to read
            ST(0) = &PL_sv_undef;
            XSRETURN(1);
        } else {
            # Network to host for MH
            mh.timestamp = ntohl(mh.timestamp);
            mh.type      = ntohs(mh.type);
            mh.subtype   = ntohs(mh.subtype);
            mh.length    = ntohl(mh.length);

            # Decode header
            # Check for length to be less than buffer
            ST(0) = newSVuv(mh.type);
            ST(1) = newSVuv(mh.subtype);
            if (mh.length > BUFFER_SIZE)
            {
                snprintf(sbuff, SBUFF, "Message length too big at %lli", (intmax_t)msgpos);
                while (mh.length > 0) {
                    auto remainder = (BUFFER_SIZE < mh.length ? BUFFER_SIZE : mh.length);
                    printf("remaining: %d to do: %d %d\n", mh.length, remainder, BUFFER_SIZE); fflush(stdout);
                    sz = PerlIO_read(f, &mh.message, remainder);
                    mh.length -= remainder;
                }
                ST(2) = newSVuv(-1);
                ST(3) = newSVpv(sbuff, strlen(sbuff));
            } else {
                # Try to read message
                if (mh.length > 0)
                    sz = PerlIO_read(f, &mh.message, mh.length);
                if ((mh.length > 0) && (sz != mh.length))
                    croak("Unable to read %d bytes in message at pos %lli", mh.length, (intmax_t)msgpos);

                ST(2) = newSVuv(mh.length);
                ST(3) = newSVpv(mh.message, mh.length);
            }
            XSRETURN(4);
        }

HV*
mrt_decode_single(type, subtype, message)
uint16_t type;
uint16_t subtype;
SV*      message;
    CODE:
        MRT_MESSAGE mh;
        char* msg;

        // Prepare returning variable(s)
        RETVAL = newHV();

        // Prepare intermediate variables
        mh.timestamp    = 0;
        mh.type         = type;
        mh.subtype      = subtype;
        msg = (char*)SvPV(message, mh.length);
        memcpy(&mh.message, msg, mh.length);

        // Perform checks
        if (mh.length == 0)
            croak("I don't know how to decode a message without contents");
        if (mh.length > BUFFER_SIZE)
            croak("Unable to process message larger than %d bytes", BUFFER_SIZE);

        mrt_decode(RETVAL, 0, &mh);
        sv_2mortal((SV*)newRV_noinc((SV*)RETVAL));
    OUTPUT:
        RETVAL

# void mrt_decode(HV* const rt, Off_t const msgpos, MRT_MESSAGE* const mh)

BOOT:
    USE_RFC4760 = get_sv("Net::MRT::USE_RFC4760", GV_ADDMULTI);
    //sv_setiv(USE_RFC4760, 1); // Change default behavior
