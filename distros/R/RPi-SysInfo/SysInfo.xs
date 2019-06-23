#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "stdlib.h"
#include "string.h"
#include "sys/types.h"
#include "sys/sysinfo.h"
#include <stdio.h>

double cpuPercent (){

  static unsigned long long lastTotalUser, lastTotalUserLow, lastTotalSys, lastTotalIdle;
  double percent;

  FILE* file;
  unsigned long long totalUser, totalUserLow, totalSys, totalIdle, total;

  file = fopen("/proc/stat", "r");
  fscanf(file, "cpu %llu %llu %llu %llu", &totalUser, &totalUserLow,
         &totalSys, &totalIdle);
  fclose(file);

  if (totalUser < lastTotalUser || totalUserLow < lastTotalUserLow ||
      totalSys < lastTotalSys || totalIdle < lastTotalIdle){
    //Overflow detection. Just skip this value.
    percent = -1.0;
  }
  else{
    total = (totalUser - lastTotalUser) + (totalUserLow - lastTotalUserLow) +
            (totalSys - lastTotalSys);
    percent = total;
    total += (totalIdle - lastTotalIdle);
    percent /= total;
    percent *= 100;
  }

  lastTotalUser = totalUser;
  lastTotalUserLow = totalUserLow;
  lastTotalSys = totalSys;
  lastTotalIdle = totalIdle;

  return percent;
}

double memPercent (){
  struct sysinfo memInfo;

  sysinfo (&memInfo);

  long long totalPhysMem = memInfo.totalram;
  totalPhysMem *= memInfo.mem_unit;

  long long physMemUsed = memInfo.totalram - memInfo.freeram;
  physMemUsed *= memInfo.mem_unit;

  long long physMemFree = totalPhysMem - physMemUsed;

  double percent = 100.0 * physMemUsed / totalPhysMem;

  return percent;
}

MODULE = RPi::SysInfo  PACKAGE = RPi::SysInfo

PROTOTYPES: DISABLE


double
cpuPercent ()

double
memPercent ()

