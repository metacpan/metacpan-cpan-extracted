// IBAM, the Intelligent Battery Monitor
// Copyright (C) 2001-2003, Sebastian Ritterbusch (IBAM@Ritterbusch.de)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
//

#include <iostream>
#include <sstream>
#include <fstream>
#include <string>
#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <locale.h> // thus I may prevent evil krells to change to others.. 

#include <sys/stat.h>  // for mkdir
#include <sys/types.h> // for mkdir

#define PMU_PWR_AC_PRESENT 0x00000001

/* Arguments, with symbols from linux/apm_bios.h.  Information is
+          from the Get Power Status (0x0a) call unless otherwise noted.
+
+          0) Linux driver version (this will change if format changes)
+          1) APM BIOS Version.  Usually 1.0 or 1.1.
+          2) APM flags from APM Installation Check (0x00):
+             bit 0: APM_16_BIT_SUPPORT
+             bit 1: APM_32_BIT_SUPPORT
+             bit 2: APM_IDLE_SLOWS_CLOCK
+             bit 3: APM_BIOS_DISABLED
+             bit 4: APM_BIOS_DISENGAGED
+          3) AC line status
+             0x00: Off-line
+             0x01: On-line
+             0x02: On backup power (APM BIOS 1.1 only)
+             0xff: Unknown
+          4) Battery status
+             0x00: High
+             0x01: Low
+             0x02: Critical
+             0x03: Charging
+             0xff: Unknown
+          5) Battery flag
+             bit 0: High
+             bit 1: Low
+             bit 2: Critical
+             bit 3: Charging
+             bit 7: No system battery
+             0xff: Unknown
+          6) Remaining battery life (percentage of charge):
+             0-100: valid
+             -1: Unknown
+          7) Remaining battery life (time units):
+             Number of remaining minutes or seconds
+             -1: Unknown
+          8) min = minutes; sec = seconds */

inline int battery_status::onBattery(void) const { return acLineStatus==0; }
inline int battery_status::charging(void)  const { return chargeStatus; }
inline int battery_status::percent(void)   const { return remainingBatteryPercent; }
inline int battery_status::seconds(void)   const { return remainingBatteryLifeSeconds; } 

inline battery_status::battery_status(string path)
{
	Path = path;
}

inline battery_status::~battery_status(void) { }

inline void battery_status::update(void)
{
	cout << "battery_status::update() called. This should never happen!" << endl;
}

inline apm_status::apm_status(string path) : battery_status(path)
{
	update();
}

inline pmu_status::pmu_status(string path) : battery_status(path)
{
	update();
}

inline acpi_status::acpi_status(string path) : battery_status(path)
{
	update();
}

inline void apm_status::update(void)
{
   ifstream in;
   int i;  
   in.open(Path.c_str());
   for(i=0;i<10 && in.fail();i++)
      in.open(Path.c_str());
   if(in.fail())
   {
      acLineStatus=0;
      batteryStatus=0;
      remainingBatteryPercent=-1;
      remainingBatteryLifeSeconds=-1;
      return; 
   }
   string driverVersion, biosVersion;
   int apmFlags, batteryFlag;
   char c,d;
   in >> driverVersion;
   in >> biosVersion;
   in >> c >> d; // 0x
   in >> c >> d; 
   apmFlags=(c>'9'?c-'a'+10:c-'0')*16+(d>'9'?d-'a'+10:d-'0');
   in >> c >> d; // 0x
   in >> c >> d; 
   acLineStatus=(c>'9'?c-'a'+10:c-'0')*16+(d>'9'?d-'a'+10:d-'0');
   in >> c >> d; // 0x
   in >> c >> d; 
   batteryStatus=(c>'9'?c-'a'+10:c-'0')*16+(d>'9'?d-'a'+10:d-'0');
   in >> c >> d; // 0x
   in >> c >> d; 
   batteryFlag=(c>'9'?c-'a'+10:c-'0')*16+(d>'9'?d-'a'+10:d-'0');
   chargeStatus = (batteryStatus&8)!=0;
   in >> remainingBatteryPercent >> c; // % 
   string minsec; 
   in >> remainingBatteryLifeSeconds >> minsec; 
   if(minsec=="min") remainingBatteryLifeSeconds*=60;
#ifdef DEBUG
   cout << "Driver Version:    " << driverVersion << endl;
   cout << "Bios Version:      " << biosVersion << endl;
   cout << "APM Flags:         " << apmFlags << endl;
   cout << "AC Line Status:    " << acLineStatus << endl;
   cout << "Battery Status:    " << batteryStatus << endl;
   cout << "Battery Flag:      " << batteryFlag << endl;
   cout << "Remaining Percent: " << remainingBatteryPercent << endl;
   cout << "Remaining Seconds: " << remainingBatteryLifeSeconds << endl;
#endif
}

inline void pmu_status::update(void)
{
	ifstream in;
	int i;
	in.open((Path+"/info").c_str());
	for (i = 0; i < 10 && in.fail(); i++)
		in.open((Path+"/info").c_str());
	if (in.fail())
	{
		acLineStatus = 0;
		chargeStatus = 0;
		remainingBatteryLifeSeconds = -1;
		remainingBatteryPercent = -1;
		return;
	}

	stringbuf buf;
	char c;
	int d, cur_charge = 0, max_charge = 0;
	for (i = 0; i < 4; i++) {
		in.get(buf, ':');
		in >> c >> d;
		if (i == 2)
			acLineStatus = d;
	}
	in.close();
	in.open((Path+"/battery_0").c_str());
	for (i = 0; i < 10 && in.fail(); i++)
		in.open((Path+"/battery_0").c_str());
	if (in.fail()) {
		acLineStatus = 0;
		chargeStatus = 0;
		remainingBatteryLifeSeconds = -1;
		remainingBatteryPercent = -1;
		return;
	}

	for (i = 0; i < 6; i++) {
		in.get(buf, ':');
		in >> c >> d;
		if (i == 0)
			chargeStatus = (d&PMU_PWR_AC_PRESENT)==0;
		if (i == 1)
			cur_charge = d;
		if (i == 2)
			max_charge = d;
		if (i == 5)
			remainingBatteryLifeSeconds = d;
	}

	remainingBatteryPercent = (int)(cur_charge*100/max_charge);
}

inline void acpi_status::update(void)
{

}

inline void percent_data::size_to(int newpercents)
{
   if(newpercents>=maxpercents)
   {
      newpercents++;
      double *time_for=new double[newpercents];
      double *time_deriv=new double[newpercents];
      int    *samples=new int[newpercents];
      int i;
      for(i=0;i<maxpercents;i++)
      {
         time_for[i]=time_for_percent[i];
         time_deriv[i]=time_deriv_for_percent[i];
         samples[i]=time_samples[i];
      }
      for(;i<newpercents;i++)
         time_for[i]=time_deriv[i]=samples[i]=0;
      
      delete [] time_for_percent;
      delete [] time_deriv_for_percent;
      delete [] time_samples;
      time_for_percent=time_for;
      time_deriv_for_percent=time_deriv;
      time_samples=samples;
      maxpercents=newpercents;
   }
}   
   
inline percent_data::percent_data(void) : maxpercents(101), 
                  time_for_percent(new double[maxpercents]),
                  time_deriv_for_percent(new double[maxpercents]),
                  time_samples(new int[maxpercents])
{
   int i;
   for(i=0;i<maxpercents;i++)
      time_for_percent[i]=time_deriv_for_percent[i]=time_samples[i]=0;
}
inline percent_data::~percent_data(void)
{
   delete [] time_for_percent;
   delete [] time_deriv_for_percent;
   delete [] time_samples;
}
inline ostream & operator <<(ostream & o,const percent_data & a)
{
   int i;
   setlocale(LC_ALL,"en_US");
   for(i=a.maxpercents-1;i>=0;i--)
      if(a.time_samples[i])
      {
         if(a.time_deriv_for_percent[i]<0)
            a.time_deriv_for_percent[i]=0;
         o << i << '\t' << a.time_for_percent[i] << '\t' << sqrt(a.time_deriv_for_percent[i]) << '\t' << a.time_samples[i] << endl;
      }
   return o;
}
inline double percent_data::add_data(int percent,double time_for,int samples)
{
   if(percent<0)
      return 0;
   size_to(percent);
   double ratio;
   if(time_samples[percent])
      ratio=time_for/time_for_percent[percent];
   else
      ratio=time_for/(IBAM_ASSUME_DEFAULT_BATTERY_MIN*60./100.);
      
   double old_time_for_percent=time_for_percent[percent];
      
   time_for_percent[percent]=
    (time_for_percent[percent]*time_samples[percent]
    +time_for*samples
    )/(samples+time_samples[percent]);
    
   time_deriv_for_percent[percent]=
    ( (time_deriv_for_percent[percent]+old_time_for_percent*old_time_for_percent)*time_samples[percent]
    +time_for*time_for*samples
    )/(samples+time_samples[percent])-time_for_percent[percent]*time_for_percent[percent];
    
   time_samples[percent]+=samples;
   return ratio;
}
inline double percent_data::average(int a,int b) // average from a to b
{
   if(a>b) { int c=a;a=b;b=c; }
   if(a<0)
   {
      a=0;
      if(b<0)
         b=0;
   }
   if(b>=maxpercents)
   {
      b=maxpercents-1;
      if(a>=maxpercents)
         a=b;
   }
   int i;
   double su(0);
   int    co(0);
   for(i=a;i<=b;i++)
   {
      if(time_samples[i])
      {
         su+=time_for_percent[i]*time_samples[i];
         co+=time_samples[i];
      }
   }
   if(co)
      return (su/co);
   int gotdata=0;
   for(a--,b++;(a>0 || b<maxpercents-1) && gotdata<2;a--,b++)
   {
      if(a<0)
         a=0;
      if(b>=maxpercents)
         b=maxpercents-1;
      su+=time_for_percent[a]*time_samples[a]
          +time_for_percent[b]*time_samples[b];
      co+=time_samples[a]+time_samples[b];
      if(time_samples[a] || time_samples[b])
         gotdata++;
   }
   if(co)
      return (su/co);

   return (IBAM_ASSUME_DEFAULT_BATTERY_MIN*60/100);
}

inline double percent_data::add_data(int percent,double time_for,double time_deriv_for,int samples)
{
   if(percent<0)
      return 0;
   size_to(percent);
   double ratio;
   if(time_samples[percent])
      ratio=time_for/time_for_percent[percent];
   else
      ratio=time_for/average(percent,percent);
      
   double old_time_for_percent=time_for_percent[percent];
      
   time_for_percent[percent]=
    (time_for_percent[percent]*time_samples[percent]
    +time_for*samples
    )/(samples+time_samples[percent]);
    
   time_deriv_for_percent[percent]=
    ( (time_deriv_for_percent[percent]+old_time_for_percent*old_time_for_percent)*time_samples[percent]
    + (time_deriv_for+time_for*time_for)*samples
    )/(samples+time_samples[percent])-time_for_percent[percent]*time_for_percent[percent];
    
   time_samples[percent]+=samples;
   return ratio;
}
inline istream & operator >>(istream & i,percent_data &a)
{
   setlocale(LC_ALL,"en_US");

   while(!i.fail() && !i.eof())
   {
      int percent;
      double time_for(-1);
      double time_deriv_for(-1);
      int samples;
      i >> percent >> time_for >> time_deriv_for>> samples;
      if(time_for>=0)
         a.add_data(percent,time_for,time_deriv_for*time_deriv_for,samples);
   }
   return i;
}
inline istream & percent_data::import(istream & i)
{
   setlocale(LC_ALL,"en_US");

   percent_data & a(*this);
   double maxval=0;
   while(!i.fail() && !i.eof())
   {
      int val;
      double time_for(-1);
      int samples;
      i >> val >> time_for >> samples;
      if(val>maxval)
         maxval=val;
      if(time_for>=0)
         a.add_data(int(double(val)/maxval*100+.5),time_for*maxval/100,samples/10+1);
   }
   return i;
}
inline double percent_data::remain(int percent)
{
   double r=0;
   size_to(percent);
   int i;
   for(i=percent;i>0;i--)
   {
      if(time_samples[i])
         r+=time_for_percent[i];
      else
      {
         int down=i-15;
         int up=i+15;
         if(down<0)
            down=0;
         if(up>=maxpercents)
            up=maxpercents-1;
         r+=average(down,up);
      }
   }
   return r;
}
inline double percent_data::inverted_remain(int percent)
{
   double r=0;
   size_to(percent);
   int i;
   for(i=percent+1;i<maxpercents;i++)
   {
      if(time_samples[i])
         r+=time_for_percent[i];
      else
      {
         int down=i-15;
         int up=i+15;
         if(down<0)
            down=0;
         if(up>=maxpercents)
            up=maxpercents-1;
         r+=average(down,up);
      }
   }
   return r;
}
inline double percent_data::total(void)
{
   double r=0;
   int i;
   for(i=maxpercents-1;i>0;i--)
   {
      if(time_samples[i])
         r+=time_for_percent[i];
      else
      {
         int down=i-15;
         int up=i+15;
         if(down<0)
            down=0;
         if(up>=maxpercents)
            up=maxpercents-1;
         r+=average(down,up);
      }
   }
   return r;
}

inline ibam::ibam(void) : 
             data_changed(0),
             battery_loaded(0),battery_changed(0),
             charge_loaded(0),charge_changed(0),
             profile_changed(0),adaptive_damping_battery(15),
             adaptive_damping_charge(15),
             lasttime(time(NULL)),lastpercent(0),lastratio(1),
             laststatus(-1),
             currenttime(time(NULL)),isvalid(0),profile_logging(1),
             profile_number(0),profile_active(0)
{
   string pmu_path = "/proc/pmu";
   ifstream pmu;
   pmu.open((pmu_path+"/info").c_str());
   if (pmu.is_open()) {
#ifdef DEBUG
	   cout << "using pmu" << endl;
#endif
	   pmu.close();
	   apm = new pmu_status();
   } else {
#ifdef DEBUG
	   cout << "using apm" << endl;
#endif
	   apm = new apm_status();
   }
   home=getenv("HOME");
   if(home!="")
      home+="/";
   mkdir((home+".ibam").c_str(),0755);
   ifstream in((home+".ibam/ibam.rc").c_str());
   string saveversion;
   in >> saveversion;
   if(saveversion==VERSION)
      in >> lasttime >> lastpercent >> lastratio >> laststatus >> adaptive_damping_battery >> adaptive_damping_charge >> profile_logging >> profile_number >> profile_active;
   else
      data_changed=1; // force update
   in.close();
   
   if(adaptive_damping_battery<2)
      adaptive_damping_battery=2;
   if(adaptive_damping_charge<2)
      adaptive_damping_charge=2;
   if(adaptive_damping_battery>200)
      adaptive_damping_battery=200;
   if(adaptive_damping_charge>200)
      adaptive_damping_charge=200;
   
   currentpercent=apm->percent();
   if(currentpercent!=-1)
      isvalid=1;

   currentstatus=apm->onBattery()?1:apm->charging()?2:0;

   if(currentstatus!=laststatus)
      lastratio=1;
}

inline void ibam::update(void)
{
   save();
   apm->update();
   currenttime=time(NULL);
   currentpercent=apm->percent();
   if(currentpercent!=-1)
      isvalid=1;
   else
      isvalid=0;
      
   currentstatus=apm->onBattery()?1:apm->charging()?2:0;

   if(currentstatus!=laststatus)
      lastratio=1;
}

inline int  ibam::valid(void) const { return isvalid; }

inline void ibam::import(void)
{
   {
      ifstream in(".ibam.battery.rc");
      battery.import(in);
      battery_changed=1;
   }
   {
      ifstream in(".ibam.charge.rc");
      charge.import(in);
      charge_changed=1;
   }
}

inline void ibam::load_battery(void)
{
   if(!battery_loaded)
   {
      ifstream in((home+".ibam/battery.rc").c_str());
      in >> battery;
      battery_loaded=1;
   }
}

inline void ibam::load_charge(void)
{
   if(!charge_loaded)
   {
      ifstream in((home+".ibam/charge.rc").c_str());
      in >> charge;
      charge_loaded=1;
   }
}

inline void ibam::update_statistics(void)
{
   if(currentstatus==laststatus && 
      currenttime-lasttime<IBAM_IGNORE_DATA_AFTER_X_SECONDS)
   {
      switch(currentstatus)
      {
         case 1: // on battery
            if(currentpercent<lastpercent)
            {
               load_battery();
               double sec_per_min=(currenttime-lasttime)/double(lastpercent-currentpercent);
               double last_av=battery.average(currentpercent,lastpercent);
               
               if(fabs(last_av-sec_per_min)<1.01*fabs(last_av*lastratio-sec_per_min))
               {
                  if((lastratio<1 && last_av<sec_per_min)
                  || (lastratio>1 && last_av>sec_per_min))
                     adaptive_damping_battery*=1.01;
                  else
                     adaptive_damping_battery*=.99;
               }
               if(sec_per_min>=IBAM_MINIMAL_SECONDS_PER_PERCENT 
               && sec_per_min<=IBAM_MAXIMAL_SECONDS_PER_PERCENT)
               {
                  int i;
                  last_sec_per_min=sec_per_min;
                  last_sec_per_min_prediction=last_av;
                  profile_changed=1;
                  
                  for(i=currentpercent;i<=lastpercent;i++)
                     lastratio=(lastratio*adaptive_damping_battery+battery.add_data(i,sec_per_min))/(adaptive_damping_battery+1);
                  battery_changed=1;
                  data_changed=1;
               }              
            } else
            if(currentpercent>lastpercent) // strange data
            {
               data_changed=1; // discard
               if(profile_logging && profile_active)
                  profile_number++;
               profile_active=0;
            }
            break;
         case 2: // charging
            if(currentpercent>lastpercent)
            {
               load_charge();
               double sec_per_min;
               sec_per_min=(currenttime-lasttime)/double(currentpercent-lastpercent);
               double last_av=charge.average(lastpercent,currentpercent);
               
               if(fabs(last_av-sec_per_min)<1.01*fabs(last_av/lastratio-sec_per_min))
               {
                  if((lastratio>1 && last_av<sec_per_min)
                  || (lastratio<1 && last_av>sec_per_min))
                     adaptive_damping_charge*=1.01;
                  else
                     adaptive_damping_charge*=.99;
               }
                
               if(sec_per_min<=IBAM_MAXIMAL_SECONDS_PER_PERCENT 
               && sec_per_min>=IBAM_MINIMAL_SECONDS_PER_PERCENT)
               {
                  int i;
                  last_sec_per_min=sec_per_min;
                  last_sec_per_min_prediction=last_av;
                  profile_changed=1;
                  
                  for(i=currentpercent;i>=lastpercent;i--)
                     lastratio=(lastratio*adaptive_damping_charge+1/charge.add_data(i,sec_per_min))/(adaptive_damping_charge+1);
                  charge_changed=1;
                  data_changed=1;
               }
            } else
            if(currentpercent<lastpercent) // strange data
            {
               if(profile_logging && profile_active)
                  profile_number++;
               profile_active=0;

               data_changed=1; // discard
            }
            break;
         default: // full or no battery
            break;
      }
   } else
   {
      if(profile_logging && profile_active)
         profile_number++;
      profile_active=0;
      data_changed=1;
   }
}

inline void ibam::ignore_statistics(void)
{
   data_changed=1;
}

inline string ibam::profile_filename(int n,int type) const
{
   char b[20];
   char *status_text[4]={"full","battery","charge",""};
   sprintf(b,"profile-%03d-%s",n,status_text[(type&3)]);
   return (home+".ibam/")+b;
}

inline int   ibam::current_profile_number(void) const { return profile_number; }
inline int   ibam::current_profile_type(void) const { return currentstatus; }

inline void ibam::save(void)
{
   if(profile_changed && profile_logging)
   {
      profile_number%=IBAM_MAXIMAL_PROFILES;
      string filename=profile_filename(profile_number,currentstatus);
      ofstream out(filename.c_str(),ios::app);
      out << currentpercent << '\t' << last_sec_per_min << '\t' << last_sec_per_min_prediction << endl;
      if(profile_active==0)
         data_changed=1;
      profile_active=1;
      profile_changed=0;
   }
   if(battery_changed)
   {
      ofstream out((home+".ibam/battery.rc").c_str());
      out << battery;
      battery_changed=0;
   }
   if(charge_changed)
   {
      ofstream out((home+".ibam/charge.rc").c_str());
      out << charge;
      charge_changed=0;
   }
   if(data_changed)
   {
      ofstream out((home+".ibam/ibam.rc").c_str());
      out << VERSION << '\t' << currenttime 
          << '\t' << currentpercent << '\t' 
          << lastratio << '\t' << currentstatus 
          << '\t' << adaptive_damping_battery
          << '\t' << adaptive_damping_charge  
          << '\t' << profile_logging 
          << '\t' << profile_number 
          << '\t' << profile_active << endl;
      lasttime=currenttime;
      lastpercent=currentpercent;
      laststatus=currentstatus;
      data_changed=0;
   }
}

inline void  ibam::set_profile_logging(int a)          { data_changed=(a!=profile_logging);profile_logging=a; }
inline int   ibam::profile_logging_setting(void) const { return profile_logging; }
      
inline int   ibam::seconds_left_battery_bios(void)     { return apm->seconds(); }
inline int   ibam::seconds_left_battery(void)          { load_battery(); return int(battery.remain(currentpercent)+.5); }
inline int   ibam::seconds_left_battery_adaptive(void) { load_battery(); return int(battery.remain(currentpercent)*lastratio+.5); }

inline int   ibam::percent_battery_bios(void)          { return apm->percent(); }
inline int   ibam::percent_battery(void)               { load_battery(); return int((100.*seconds_left_battery())/battery.total()+.5); }
            
inline int   ibam::seconds_left_charge(void)           { load_charge(); return int(charge.inverted_remain(currentpercent)+.5); }
inline int   ibam::seconds_left_charge_adaptive(void)  { load_charge(); return int(charge.inverted_remain(currentpercent)/lastratio+.5); }

inline int   ibam::percent_charge(void)                { load_charge(); return 100-int((100.*seconds_left_charge())/charge.total()+.5); }

inline int   ibam::seconds_battery_total(void)         { load_battery(); return int(battery.total()+.5); }
inline int   ibam::seconds_battery_total_adaptive(void){ load_battery(); return int(battery.total()*lastratio+.5); }

inline int   ibam::seconds_charge_total(void)          { load_charge(); return int(charge.total()+.5); }
inline int   ibam::seconds_charge_total_adaptive(void) { load_charge(); return int(charge.total()/lastratio+.5); }

inline int   ibam::seconds_battery_correction(void)
{
   if(currentstatus!=laststatus || currentstatus==0
    || lastpercent!=currentpercent)
      return 0;
   if(currentstatus==1)
      return lasttime-currenttime;
   load_battery();
   load_charge();
   return int((currenttime-lasttime)*(battery.average(currentpercent-1,currentpercent+1)/charge.average(currentpercent-1,currentpercent+1))+.5);
}

inline int   ibam::seconds_charge_correction(void)
{
   if(currentstatus!=laststatus || currentstatus==0
    || lastpercent!=currentpercent)
      return 0;
   if(currentstatus==2)
      return lasttime-currenttime;
   load_battery();
   load_charge();
   return int((currenttime-lasttime)/(battery.average(currentpercent-1,currentpercent+1)/charge.average(currentpercent-1,currentpercent+1))+.5);
}

inline int   ibam::onBattery(void) { return apm->onBattery(); }
inline int   ibam::charging(void)  { return apm->charging(); }

inline double percent_data::average_derivation(int a,int b) // average standard derivation from a to b
{
   if(a>b) { int c=a;a=b;b=c; }
   if(a<0)
   {
      a=0;
      if(b<0)
         b=0;
   }
   if(b>=maxpercents)
   {
      b=maxpercents-1;
      if(a>=maxpercents)
         a=b;
   }
   int i;
   double su(0);
   int    co(0);
   for(i=a;i<=b;i++)
   {
      if(time_samples[i])
      {
         if(time_deriv_for_percent[i]>0)
            su+=sqrt(time_deriv_for_percent[i])*time_samples[i];
         co+=time_samples[i];
      }
   }
   if(co)
      return (su/co);
   int gotdata=0;
   for(a--,b++;(a>0 || b<maxpercents-1) && gotdata<2;a--,b++)
   {
      if(a<0)
         a=0;
      if(b>=maxpercents)
         b=maxpercents-1;
      if(time_deriv_for_percent[a]>0 && time_samples[a])
         su+=sqrt(time_deriv_for_percent[a])*time_samples[a];
      if(time_deriv_for_percent[b]>0 && time_samples[b])
         su+=sqrt(time_deriv_for_percent[b])*time_samples[b];
      co+=time_samples[a]+time_samples[b];
      if(time_samples[a] || time_samples[b])
         gotdata++;
   }
   if(co)
      return (su/co);

   return 20;
}
