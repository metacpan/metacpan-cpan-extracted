/********************************
FILE: toctool.h
********************************/

#ifndef __TOCTOOL_H_INC
#define __TOCTOOL_H_INC

#include "myaspi32.h"
#include "toc.h"

#define OS_UNKNOWN  -1
#define OS_WIN95    0
#define OS_WIN98    1
#define OS_WINNT35  2
#define OS_WINNT4   3
#define OS_WIN2K    4

#define INTERFACE_ASPI         0
#define NUM_INTERFACE          (1)

typedef struct {
  char name[32];
  BOOL avail;
} INTERFACE;

#ifndef __INIT_C
extern BOOL bInit;
extern INTERFACE interfaces[NUM_INTERFACE];
extern int iActiveInterface;
extern int iOSVer;
extern DWORD (*GetASPI32SupportInfo)(void);
extern DWORD (*SendASPI32Command)(LPSRB);
#endif

typedef struct {
  BYTE ha;
  BYTE tgt;
  BYTE lun;
  char desc[32];
} ASPIDRV;

typedef struct {
  char driveLetter;
  char desc[32];
} NTDRV;

typedef union {
  ASPIDRV  a;
  NTDRV    n;
} DRIVESTRUCT;

#define MAX_DRIVE_LIST  8
typedef struct {
  DRIVESTRUCT drive[MAX_DRIVE_LIST];
  int num;
} DRIVELIST;

#ifndef __DRIVELST_C
extern DRIVELIST driveList;
#endif

#endif
