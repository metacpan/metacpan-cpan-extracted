/********************************
FILE: toc.h
********************************/

#ifndef __TOC_H_INC
#define __TOC_H_INC

#pragma pack(1)

typedef struct
{
  BYTE      rsvd;
  BYTE      ADR;
  BYTE      trackNumber;
  BYTE      rsvd2;
  BYTE      addr[4];
} TOCTRACK;

typedef struct
{
  WORD      tocLen;
  BYTE      firstTrack;
  BYTE      lastTrack;
  TOCTRACK tracks[100];
} TOC, *PTOC, FAR *LPTOC;

#pragma pack()


#endif
