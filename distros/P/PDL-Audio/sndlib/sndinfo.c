/* sndinfo describes sounds */

#if defined(HAVE_CONFIG_H)
  #include "config.h"
#endif

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#if (defined(NEXT) || (defined(HAVE_LIBC_H) && (!defined(HAVE_UNISTD_H))))
  #include <libc.h>
#else
  #if (!(defined(_MSC_VER))) && (!(defined(MPW_C)))
    #include <unistd.h>
  #endif
  #include <string.h>
#endif
#include <errno.h>

#include "sndlib.h"

  #include <time.h>

#if MACOS
  #include <console.h>
#endif

/* try to give some info on data formats that aren't supported by sndlib */
static char *decode_format(int format, int type)
{
  char *f4;
  switch (type)
    {
    case NeXT_sound_file:
      switch (format)
	{
	case 0: return("unspecified"); break; case 8: return("indirect"); break; case 9: return("nested"); break;
	case 10: return("dsp_core"); break; case 11: return("dsp_data_8"); break; case 12: return("dsp_data_16"); break;
	case 13: return("dsp_data_24"); break; case 14: return("dsp_data_32"); break; case 16: return("display"); break;
	case 17: return("mulaw_squelch"); break; case 18: return("emphasized"); break; case 19: return("compressed"); break;
	case 20: return("compressed_emphasized"); break; case 21: return("dsp_commands"); break; case 22: return("dsp_commands_samples"); break;
	case 23: return("adpcm_g721"); break; case 24: return("adpcm_g722"); break; case 25: return("adpcm_g723"); break;
	case 26: return("adpcm_g723_5"); break; case 28: return("aes"); break; case 29: return("delat_mulaw_8"); break;
	}
      break;
    case AIFC_sound_file:
      if (format)
	{
	  f4 = (char *)calloc(5,sizeof(char));
#ifdef SNDLIB_LITTLE_ENDIAN
	  sprintf(f4,"%c%c%c%c",format&0xff,(format>>8)&0xff,(format>>16)&0xff,(format>>24)&0xff);
#else
	  sprintf(f4,"%c%c%c%c",(format>>24)&0xff,(format>>16)&0xff,(format>>8)&0xff,format&0xff);
#endif	
	  return(f4);
	}
      break;
    case RIFF_sound_file:
      switch (format)
	{
	case 2: return("ADPCM"); break; case 4: return("VSELP"); break; case 5: return("IBM_CVSD"); break;
	case 0x10: return("OKI_ADPCM"); break; case 0x11: return("DVI_ADPCM"); break; case 0x12: return("MediaSpace_ADPCM"); break;
	case 0x13: return("Sierra_ADPCM"); break; case 0x14: return("G723_ADPCM"); break; case 0x15: return("DIGISTD"); break;
	case 0x16: return("DIGIFIX"); break; case 0x17: return("Dialogic ADPCM"); break; case 0x18: return("Mediavision ADPCM"); break;
	case 0x19: return("HP cu codec"); break; case 0x20: return("Yamaha_ADPCM"); break; case 0x21: return("SONARC"); break;
	case 0x22: return("DSPGroup_TrueSpeech"); break; case 0x23: return("EchoSC1"); break; case 0x24: return("AudioFile_AF36"); break;
	case 0x25: return("APTX"); break; case 0x26: return("AudioFile_AF10"); break; case 0x27: return("prosody 1612"); break;
	case 0x28: return("lrc"); break; case 0x30: return("Dolby_Ac2"); break; case 0x31: return("GSM610"); break;
	case 0x32: return("MSN audio codec"); break; case 0x33: return("Antext_ADPCM"); break; case 0x34: return("Control_res_vqlpc"); break;
	case 0x35: return("DIGIREAL"); break; case 0x36: return("DIGIADPCM"); break; case 0x37: return("Control_res_cr10"); break;
	case 0x38: return("NMS_VBXADPCM"); break; case 0x39: return("oland rdac"); break; case 0x3a: return("echo sc3"); break;
	case 0x3b: return("Rockwell adpcm"); break; case 0x3c: return("Rockwell digitalk codec"); break; case 0x3d: return("Xebec"); break;
	case 0x40: return("G721_ADPCM"); break; case 0x41: return("G728 CELP"); break; case 0x42: return("MS G723"); break;
	case 0x50: return("MPEG"); break; case 0x52: return("RT24"); break; case 0x53: return("PAC"); break;
	case 0x55: return("Mpeg layer 3"); break; case 0x59: return("Lucent G723"); break; case 0x60: return("Cirrus"); break;
	case 0x61: return("ESS Tech pcm"); break; case 0x62: return("voxware "); break; case 0x63: return("canopus atrac"); break;
	case 0x64: return("G726"); break; case 0x65: return("G722"); break; case 0x66: return("DSAT"); break;
	case 0x67: return("DSAT display"); break; case 0x69: return("voxware "); break; case 0x70: return("voxware ac8 "); break;
	case 0x71: return("voxware ac10 "); break; case 0x72: return("voxware ac16"); break; case 0x73: return("voxware ac20"); break;
	case 0x74: return("voxware rt24"); break; case 0x75: return("voxware rt29"); break; case 0x76: return("voxware rt29hw"); break;
	case 0x77: return("voxware vr12 "); break; case 0x78: return("voxware vr18"); break; case 0x79: return("voxware tq40"); break;
	case 0x80: return("softsound"); break; case 0x81: return("voxware tq60 "); break; case 0x82: return("MS RT24"); break;
	case 0x83: return("G729A"); break; case 0x84: return("MVI_MVI2"); break; case 0x85: return("DF G726"); break;
	case 0x86: return("DF GSM610"); break; case 0x88: return("isaudio"); break; case 0x89: return("onlive"); break;
	case 0x91: return("sbc24"); break; case 0x92: return("dolby ac3 spdif"); break; case 0x97: return("zyxel adpcm"); break;
	case 0x98: return("philips lpcbb"); break; case 0x99: return("packed"); break; case 0x100: return("rhetorex adpcm"); break;
	case 0x101: return("Irat"); break; case 0x102: return("IBM_alaw?"); break; case 0x103: return("IBM_ADPCM?"); break;
	case 0x111: return("vivo G723"); break; case 0x112: return("vivo siren"); break; case 0x123: return("digital g273"); break;
	case 0x200: return("Creative_ADPCM"); break; case 0x202: return("Creative fastspeech 8"); break; 
	case 0x203: return("Creative fastspeech 10"); break;
	case 0x220: return("quarterdeck"); break; case 0x300: return("FM_TOWNS_SND"); break; case 0x400: return("BTV digital"); break;
	case 0x680: return("VME vmpcm"); break; case 0x1000: return("OLIGSM"); break; case 0x1001: return("OLIADPCM"); break;
	case 0x1002: return("OLICELP"); break; case 0x1003: return("OLISBC"); break; case 0x1004: return("OLIOPR"); break;
	case 0x1100: return("LH codec"); break; case 0x1400: return("Norris"); break; case 0x1401: return("isaudio"); break;
	case 0x1500: return("Soundspace musicompression"); break; case 0x2000: return("DVM"); break; 
	}
      break;
    }
  return(NULL);
}

int main(int argc, char *argv[])
{
  int chans,srate,samples,format,type;
  float length;
  time_t date;
  char *comment,*header_name;
  char *format_info,*format_name;
  char timestr[64];
#if MACOS
  argc = ccommand(&argv);
#endif
  if (argc == 1) {printf("usage: sndinfo file\n"); exit(0);}
  initialize_sndlib();
  if (mus_probe_file(argv[1])) /* see if it exists */
    {
      date = sound_write_date(argv[1]);
      srate = sound_srate(argv[1]);
      chans = sound_chans(argv[1]);
      samples = sound_samples(argv[1]);
      comment = sound_comment(argv[1]); 
      length = (float)samples / (float)(chans * srate);
      type = sound_header_type(argv[1]);
      header_name = sound_type_name(type);
      format = sound_data_format(argv[1]);
      if (format != SNDLIB_UNSUPPORTED)
	format_info = sound_format_name(format);
      else
	{
	  format_info = (char *)calloc(64,sizeof(char));
	  format = sound_original_format(argv[1]);
	  format_name = decode_format(format,type);
	  if (format_name)
	    sprintf(format_info,"%d (%s)",format,format_name);
	  else sprintf(format_info,"%d",format);
	}
#if (!defined(HAVE_CONFIG_H)) || defined(HAVE_STRFTIME)
      strftime(timestr,64,"%a %d-%b-%Y %H:%M %Z",localtime(&date));
#else
      sprintf(timestr,"who knows?");
#endif
      fprintf(stdout,"%s:\n  srate: %d\n  chans: %d\n  length: %f\n",
	      argv[1],srate,chans,length);
      fprintf(stdout,"  type: %s\n  format: %s\n  written: %s\n  comment: %s\n",
	      header_name,
	      format_info,
	      timestr,(comment) ? comment : "");
    }
  else
    fprintf(stderr,"%s: %s\n",argv[1],strerror(errno));
  return(0);
}
