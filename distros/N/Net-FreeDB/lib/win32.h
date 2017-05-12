/********************************
FILE: win32.h
Created On: 08/04/2001
Creadted By: David Shultz
********************************/

#ifndef WIN32_H
#define WIN32_H

#include <windows.h>
#include <stdio.h>
#include <stddef.h>
#include <conio.h>
#include "toctool.h"
#include "scsidefs.h"

// Variable inits
BOOL bInit;
INTERFACE interfaces[NUM_INTERFACE];
int iActiveInterface;
int iOSVer;
DWORD (*GetASPI32SupportInfo)(void);
DWORD (*SendASPI32Command)(LPSRB);

int numDrives;
TOC toc;
DRIVELIST driveList;

HINSTANCE hDll;

struct discdata {
	unsigned long discid;
	int num_of_trks;
	int track_offsets[100];
	int seconds;
};

// Function defs
unsigned long CDDBSum(unsigned long);
static int getNumAdapters(void);
static int aspiGetNumDrives(void);
static int ntGetNumDrives(void);
int aspiReadTOC(int, TOC*);
void* genCddbQuery(TOC*);

// Funcs
unsigned long genCddbId(TOC *toc) {
  unsigned long t, n;
  TOCTRACK *t1, *t2;
  int i, numTracks;
  
  if (!toc)
    return 0;
  
  t = n = 0;
  numTracks = (int)(toc->lastTrack - toc->firstTrack + 1);
  for(i = 0; i < numTracks; i++) {
    t1 = &(toc->tracks[i]);
    n += CDDBSum(60 * t1->addr[1] + t1->addr[2]);
  }
  
  t2 = &(toc->tracks[numTracks]);
  t = 60 * t2->addr[1] + t2->addr[2];
  t2 = &(toc->tracks[0]);
  t -= (60 * t2->addr[1] + t2->addr[2]);
  
  return (unsigned long)( ((n % 0xFF) << 24) | 
                             (t << 8) | 
                             ((unsigned long)numTracks));
}

unsigned long CDDBSum(unsigned long n) {
  unsigned long retVal = 0;

  while(n > 0) {
      retVal += (n % 10);
      n /= 10;
    }

  return retVal;
}

void* genCddbQuery(TOC* toc) {
  struct discdata* cd = (struct discdata*)malloc(sizeof(struct discdata));
  int numTracks, i, ofs;
  TOCTRACK *t1;
  
  if (!toc)
    return cd;
  
  numTracks = (int)(toc->lastTrack - toc->firstTrack + 1);

  // cddbid
  cd->discid = genCddbId(toc);
  // number of tracks
  cd->num_of_trks = numTracks;

  // track offsets (not including lead-out)
  for(i = 0; i < numTracks; i++) {
    t1 = &(toc->tracks[i]);
    ofs = (((t1->addr[1] * 60) + t1->addr[2]) * 75) + t1->addr[3];
	cd->track_offsets[i] = ofs;
  }
  
  // disc length
  t1 = &toc->tracks[i];
  ofs = t1->addr[1]*60 + t1->addr[2];
  cd->seconds = ofs;

	return (void*)cd;
}

int getNumDrives(void) {
  if (!bInit)
    return 0;

	return aspiGetNumDrives();
}

void getDriveDesc(int driveNo, char *szBuf, int bufLen) {
  if (!szBuf)
    return;
  
  ZeroMemory(szBuf, bufLen);
  
  if (!bInit)
    return;
  
  if (driveNo > driveList.num)
    return;

	lstrcpyn(szBuf, driveList.drive[driveNo].a.desc, bufLen);
}

static int aspiGetNumDrives( void )
{
  SRB_HAInquiry sh;
  SRB_GDEVBlock sd;
  BYTE numAdapters, maxTgt;
  BYTE i, j, k;
  int idx = 0;
  
  // initialize the drive list;
  ZeroMemory( &driveList, sizeof(driveList) );
  numAdapters = (BYTE)getNumAdapters();
  if ( numAdapters == 0 )
    return 0;
  
  for( i = 0; i < numAdapters; i++ )
  {
    ZeroMemory( &sh, sizeof(sh) );
    sh.SRB_Cmd = SC_HA_INQUIRY;
    sh.SRB_HaID = i;
    SendASPI32Command( (LPSRB)&sh );

    // in case of error, skip to next adapter
    if ( sh.SRB_Status != SS_COMP )
      continue;
    
    // determine the max target number for the adapter from offset 3
    // if it's zero, then assume the max is 8
    maxTgt = sh.HA_Unique[3];
    if ( maxTgt == 0 )
      maxTgt = 8;

    for( j = 0; j < maxTgt; j++ )
    {
      // try all 8 values for LUN
      for( k = 0; k < 8; k++ )
      {
        ZeroMemory( &sd, sizeof(sd) );
        sd.SRB_Cmd   = SC_GET_DEV_TYPE;
        sd.SRB_HaID  = i;
        sd.SRB_Target = j;
        sd.SRB_Lun   = k;
        SendASPI32Command( (LPSRB)&sd );
        if ( sd.SRB_Status == SS_COMP )
        {
          if ( sd.SRB_DeviceType == DTYPE_CDROM && driveList.num <= MAX_DRIVE_LIST )
          {
            idx = driveList.num++;
            driveList.drive[idx].a.ha = i;
            driveList.drive[idx].a.tgt = j;
            driveList.drive[idx].a.lun = k;
            wsprintf( driveList.drive[idx].a.desc, "ASPI[%d:%d:%d]", i, j, k );
          }
        }
      }
    }
  }
  
  return driveList.num;
}

/************************************************************************
 * ASPI layer
 ************************************************************************/
static int getNumAdapters( void )
{
  DWORD d;
  BYTE bCount, bStatus;

  d = GetASPI32SupportInfo();
  bCount = LOBYTE(LOWORD(d));
  bStatus = HIBYTE(LOWORD(d));
  
  if ( bStatus != SS_COMP && bStatus != SS_NO_ADAPTERS )
    return -1;
  
  return (int)bCount;
}

int readTOC(int driveNo, TOC* t) {
	if (!bInit || (driveNo > driveList.num))
		return -1;

	return aspiReadTOC(driveNo, t);
}

int aspiReadTOC(int driveNo, TOC* t) {
	HANDLE hEvent;
	SRB_ExecSCSICmd s;
	DWORD dwStatus;

	if (driveNo > driveList.num)
		return -2;

	hEvent = CreateEvent(NULL, TRUE, FALSE, NULL);

	ZeroMemory(&s, sizeof(s));

	s.SRB_Cmd = SC_EXEC_SCSI_CMD;
	s.SRB_HaID = driveList.drive[driveNo].a.ha;
	s.SRB_Target = driveList.drive[driveNo].a.tgt;
	s.SRB_Lun = driveList.drive[driveNo].a.lun;
	s.SRB_Flags = SRB_DIR_IN | SRB_EVENT_NOTIFY;
	s.SRB_BufLen = 0x324;
	s.SRB_BufPointer = (BYTE FAR*)t;
	s.SRB_SenseLen = 0x0E;
	s.SRB_CDBLen = 0x0A;
	s.SRB_PostProc = (LPVOID)hEvent;
	s.CDBByte[0] = 0x43;
	s.CDBByte[1] = 0x02;
	s.CDBByte[7] = 0x03;
	s.CDBByte[8] = 0x24;

	ResetEvent(hEvent);

	dwStatus = SendASPI32Command((LPSRB)&s);

	if (dwStatus == SS_PENDING)
		WaitForSingleObject(hEvent, 10000); // wait up to 10 secs.

	CloseHandle(hEvent);

	if (s.SRB_Status != SS_COMP)
		return -3;

	return 0;
}

/*
 * Initialize functions according to whether we're using ASPI (Win95/98)
 * or the CDROM ioctls (NT/2000);
 */
int initTool(void) {
  
  if (bInit)
    return 0;
  
  ZeroMemory(interfaces, sizeof(interfaces));
  lstrcpy(interfaces[INTERFACE_ASPI].name, "ASPI");
  
  iOSVer = getOsVersion();
  if (iOSVer == OS_UNKNOWN)
    return -1;

  // check if aspi is available
  hDll = LoadLibrary("WNASPI32.DLL");
  GetASPI32SupportInfo = 
    (DWORD(*)(void))GetProcAddress(hDll, "GetASPI32SupportInfo");
  SendASPI32Command = 
    (DWORD(*)(LPSRB))GetProcAddress(hDll, "SendASPI32Command");

  // make sure that we've got both function addresses
  if (GetASPI32SupportInfo && SendASPI32Command) {
    interfaces[INTERFACE_ASPI].avail = TRUE;
  }
  
  bInit = TRUE;
  return 0;
}

/*
 * Returns the current OS system, one of OS_WIN95, OS_WIN98,
 * OS_WINNT35, OS_WINNT4, OS_WIN2K, or if an error occurs,
 * OS_UNKNOWN
 */
int getOsVersion(void) {
  OSVERSIONINFO os;
  
  ZeroMemory(&os, sizeof(os));
  os.dwOSVersionInfoSize = sizeof(os);
  GetVersionEx(&os);

  if (os.dwPlatformId == VER_PLATFORM_WIN32_NT) {
    if (os.dwMajorVersion == 3 && os.dwMinorVersion >= 50)
      return OS_WINNT35;
    else if (os.dwMajorVersion == 4)
      return OS_WINNT4;
    else if (os.dwMajorVersion == 5)
      return OS_WIN2K;
  }
  else if (os.dwPlatformId == VER_PLATFORM_WIN32_WINDOWS) {
    if (os.dwMinorVersion == 0)
      return OS_WIN95;
    else
      return OS_WIN98;
  }
  
  return OS_UNKNOWN;  
}

unsigned long discid(int drive) {
	struct discdata* cd;
	int i, numTracks;
	unsigned long id;

	i = initTool();
	getNumDrives();
	ZeroMemory(&toc, sizeof(toc));
	readTOC(drive, &toc);

	if (!toc.firstTrack && !toc.lastTrack)
		numTracks = 0;
	else
		numTracks = (int)(toc.lastTrack - toc.firstTrack + 1);
  
	if (numTracks > 0) {
		// calculate the cddbId
		cd = genCddbQuery(&toc);
		id = cd->discid;
		free(cd);
	}
	return id;
}

struct discdata get_disc_id(int drive) {
	struct discdata* cd;
	struct discdata data;
	int i, numTracks;
	unsigned long id;

	i = initTool();
	getNumDrives();
	ZeroMemory(&toc, sizeof(toc));
	readTOC(drive, &toc);
	if (!toc.firstTrack && !toc.lastTrack) {
		static char foo[2048];
		numTracks = 0;
	}
	else
		numTracks = (int)(toc.lastTrack - toc.firstTrack + 1);
  
	if (numTracks > 0) {
		// calculate the cddbId
		cd = genCddbQuery(&toc);
	}

	free(cd);
	data = *cd;

	return data;
}

#endif //WIN32_H












