/* sound.c */

/* TODO: make this thread-safe by wrapping locks around the header/data base references */

#if defined(HAVE_CONFIG_H)
  #include "config.h"
#endif

#include <math.h>
#include <stdio.h>
#if (!defined(HAVE_CONFIG_H)) || (defined(HAVE_FCNTL_H))
  #include <fcntl.h>
#endif
#include <signal.h>
#if (!defined(HAVE_CONFIG_H)) || (defined(HAVE_LIMITS_H))
  #include <limits.h>
#endif
#include <errno.h>
#include <stdlib.h>

#if (defined(NEXT) || (defined(HAVE_LIBC_H) && (!defined(HAVE_UNISTD_H))))
  #include <libc.h>
#else
  #if (!(defined(_MSC_VER))) && (!(defined(MPW_C)))
    #include <unistd.h>
  #endif
  #if (!defined(HAVE_CONFIG_H)) || (defined(HAVE_STRING_H))
    #include <string.h>
  #endif
#endif

#include <ctype.h>
#include <stddef.h>

#include "sndlib.h"

#if MACOS
  #if (!defined(MPW_C))
    #include <time.h>
    #include <stat.h>
  #endif
#else
  #include <sys/types.h>
  #include <sys/stat.h>
#endif

#include <stdarg.h>

static int mus_error_tag = MUS_INITIAL_ERROR_TAG;
int mus_make_error_tag(void) {return(mus_error_tag++);}
static void (*mus_error_handler)(int err_type, char *err_msg);
void mus_set_error_handler(void (*new_error_handler)(int err_type, char *err_msg)) {mus_error_handler = new_error_handler;}
static char *mus_error_buffer = NULL;

void mus_error(int error, char *format, ...)
{
  va_list ap;
  va_start(ap,format);
  vsprintf(mus_error_buffer,format,ap);
  va_end(ap);
  if (mus_error_handler)
    (*mus_error_handler)(error,mus_error_buffer);
  else fprintf(stderr,mus_error_buffer);
}

void mus_fwrite(int fd, char *format, ...)
{
  va_list ap;
  va_start(ap,format);
  vsprintf(mus_error_buffer,format,ap);
  va_end(ap);
  write(fd,mus_error_buffer,strlen(mus_error_buffer));
}

static char *s_copy_string (char *str)
{
  char *newstr = NULL;
  if ((str) && (*str))
    {
      newstr = (char *)CALLOC(strlen(str)+1,sizeof(char));
      strcpy(newstr,str);
    }
  return(newstr);
}
      
	  
#ifndef MPW_C
static time_t file_write_date(char *filename)
{
  struct stat statbuf;
  int err;
  err = stat(filename,&statbuf);
  if (err < 0) return(err);
  return((time_t)(statbuf.st_mtime));
}
#else
#include <Files.h>
static int file_write_date(char *filename)
{
#if 0
  /* this isn't right... */
  HParamBlockRec pb;
  FSSpec fs;
  FSMakeFSSpec(0,0,(unsigned char *)filename,&fs);
  pb.fileParam.ioVRefNum = fs.vRefNum;
  pb.fileParam.ioDirID = fs.parID;
  pb.fileParam.ioNamePtr = fs.name;
  PBHGetFInfo(&pb,FALSE);
mus_error(0,"%s date: %d ",filename,pb.fileParam.ioFlMdDat);
  return(pb.fileParam.ioFlMdDat);
#else
  return(1);
#endif
}
#endif

static int sndlib_initialized = 0;

int initialize_sndlib(void)
{
  int err = 0;
  if (!sndlib_initialized)
    {
      sndlib_initialized = 1;
      mus_error_buffer = (char *)CALLOC(256,sizeof(char));
      if (mus_error_buffer == NULL) return(-1);
      err = mus_create_header_buffer();
      if (err == 0)
	{
	  err = mus_create_descriptors();
	  if (err == 0) err = initialize_audio();
	}
      if (err == -1) {FREE(mus_error_buffer); return(-1);}
    }
  return(0);
}

typedef struct {
  char *file_name;  /* full path -- everything is keyed to this name */
  int table_pos;
  int *aux_comment_start,*aux_comment_end;
  int *loop_modes,*loop_starts,*loop_ends;
  int markers;
  int *marker_ids,*marker_positions;
  int samples, datum_size, data_location, srate, chans, header_type, data_format, original_sound_format, true_file_length;
  int comment_start, comment_end, header_distributed, type_specifier, bits_per_sample, fact_samples, block_align;
  int write_date;
  int *max_amps;
} sound_file;

static int sound_table_size = 0;
static sound_file **sound_table = NULL;

static void free_sound_file(sound_file *sf)
{
  if (sf)
    {
      sound_table[sf->table_pos] = NULL;
      if (sf->aux_comment_start) FREE(sf->aux_comment_start);
      if (sf->aux_comment_end) FREE(sf->aux_comment_end);
      if (sf->file_name) FREE(sf->file_name);
      if (sf->loop_modes) FREE(sf->loop_modes);
      if (sf->loop_starts) FREE(sf->loop_starts);
      if (sf->loop_ends) FREE(sf->loop_ends);
      if (sf->marker_ids) FREE(sf->marker_ids);
      if (sf->marker_positions) FREE(sf->marker_positions);
      if (sf->max_amps) FREE(sf->max_amps);
      FREE(sf);
    }
}

static sound_file *add_to_sound_table(void)
{
  int i,pos;
#ifdef MACOS
  sound_file **ptr;
#endif
  pos = -1;
  for (i=0;i<sound_table_size;i++)
    if (sound_table[i] == NULL) 
      {
	pos = i;
	break;
      }
  if (pos == -1)
    {
      pos = sound_table_size;
      sound_table_size += 16;
      if (sound_table == NULL)
	sound_table = (sound_file **)CALLOC(sound_table_size,sizeof(sound_file *));
      else 
	{
#ifdef MACOS
	  ptr = (sound_file **)CALLOC(sound_table_size,sizeof(sound_file *));
	  for (i=0;i<pos;i++) ptr[i] = sound_table[i];
	  FREE(sound_table);
	  sound_table = ptr;
#else
	  sound_table = (sound_file **)REALLOC(sound_table,sound_table_size * sizeof(sound_file *));
#endif
	  for (i=pos;i<sound_table_size;i++) sound_table[i] = NULL;
	}
    }
  sound_table[pos] = (sound_file *)CALLOC(1,sizeof(sound_file));
  sound_table[pos]->table_pos = pos;
  return(sound_table[pos]);
}

static void re_read_raw_header(sound_file *sf)
{
  int chan,data_size;
  chan = mus_open_read(sf->file_name);
  data_size = lseek(chan,0L,SEEK_END);
  sf->true_file_length = data_size;
  sf->samples = mus_bytes2samples(sf->data_format,data_size);
  close(chan);  
}

int forget_sound(char *name)
{
  int i;
  for (i=0;i<sound_table_size;i++)
    {
      if (sound_table[i])
	{
	  if (strcmp(name,sound_table[i]->file_name) == 0)
	    {
	      free_sound_file(sound_table[i]);
	      return(0);
	    }
	}
    }
  return(-1);
}

static sound_file *find_sound_file(char *name)
{
  int i,date;
  sound_file *sf;
  for (i=0;i<sound_table_size;i++)
    {
      if (sound_table[i])
	{
	  if (strcmp(name,sound_table[i]->file_name) == 0)
	    {
	      sf = sound_table[i];
	      date = file_write_date(name);
	      if (date == sf->write_date)
		return(sf);
	      else 
		{
		  if (sf->header_type == raw_sound_file)
		    {
		      /* sound has changed since we last read it, but it has no header, so
		       * the only sensible thing to check is the new length (i.e. caller
		       * has set other fields by hand)
		       */
		      sf->write_date = date;
		      re_read_raw_header(sf);
		      return(sf);
		    }
		  free_sound_file(sf);
 		  return(NULL);
		}
	    }
	}
    }
  return(NULL);
}

static void fill_sf_record(sound_file *sf)
{
  sf->data_location = mus_header_data_location();
  sf->samples = mus_header_samples();
  sf->data_format = mus_header_format();
  sf->srate = mus_header_srate();
  sf->chans = mus_header_chans();
  sf->datum_size = mus_header_format2bytes();
  sf->header_type = mus_header_type();
  sf->original_sound_format = mus_header_original_format();
  sf->true_file_length = mus_true_file_length();
  sf->comment_start = mus_header_comment_start();
  sf->comment_end = mus_header_comment_end();
  sf->header_distributed = mus_header_distributed();
  sf->type_specifier = mus_header_type_specifier();
  sf->bits_per_sample = mus_header_bits_per_sample();
  sf->fact_samples = mus_header_fact_samples();
  sf->block_align = mus_header_block_align();
  sf->write_date = file_write_date(sf->file_name);
  /* loop points and aux comments */
}

static sound_file *read_sound_file_header_with_fd(int fd, char *arg)
{
  int err=0;
  sound_file *sf = NULL;
  initialize_sndlib();
  err = mus_read_header_with_fd(fd);
  if (err == -1) return(NULL);
  sf = add_to_sound_table();
  sf->file_name = s_copy_string(arg);
  fill_sf_record(sf);
  return(sf);
}

static sound_file *read_sound_file_header_with_name(char *name)
{
  sound_file *sf = NULL;
  initialize_sndlib();
  if (mus_read_header(name) != -1)
    {
      sf = add_to_sound_table();
      sf->file_name = s_copy_string(name);
      fill_sf_record(sf);
    }
  return(sf);
}

static sound_file *getsf(char *arg) 
{
  sound_file *sf = NULL;
  if ((sf = find_sound_file(arg)) == NULL)
    {
      sf = read_sound_file_header_with_name(arg);
      if (sf == NULL) set_audio_error(SNDLIB_CANT_OPEN);
    }
  return(sf);
}

int sound_samples (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->samples); else return(-1);}
int sound_frames (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->samples / sf->chans); else return(-1);}
int sound_datum_size (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->datum_size); else return(-1);}
int sound_data_location (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->data_location); else return(-1);}
int sound_chans (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->chans); else return(-1);}
int sound_srate (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->srate); else return(-1);}
int sound_header_type (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->header_type); else return(-1);}
int sound_data_format (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->data_format); else return(-1);}
int sound_original_format (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->original_sound_format); else return(-1);}
int sound_comment_start (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->comment_start); else return(-1);}
int sound_comment_end (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->comment_end); else return(-1);}
int sound_length (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->true_file_length); else return(-1);}
int sound_fact_samples (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->fact_samples); else return(-1);}
int sound_distributed (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->header_distributed); else return(-1);}
int sound_write_date (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->write_date); else return(-1);}
int sound_type_specifier (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->type_specifier); else return(-1);}
int sound_align (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->block_align); else return(-1);}
int sound_bits_per_sample (char *arg) {sound_file *sf; sf = getsf(arg); if (sf) return(sf->bits_per_sample); else return(-1);}
float sound_duration(char *arg) {return((float)sound_frames(arg) / (float)sound_srate(arg));}

int sound_aiff_p(char *arg) 
{
  return(sound_header_type(arg) == AIFF_sound_file);
}

char *sound_comment(char *name)
{
  int start,end,fd,len;
  char *sc = NULL;
  start = sound_comment_start(name);
  end = sound_comment_end(name);
  if (end == 0) return(NULL);
  len = end-start+1;
  if (len>0)
    {
      /* open and get the comment */
      sc = (char *)CALLOC(len+1,sizeof(char)); /* len+1 calloc'd => we'll always have a trailing null */
#if MACOS
      fd = open(name,O_RDONLY);
#else
  #ifdef WINDOZE
      fd = open(name,O_RDONLY | O_BINARY);
  #else
      fd = open(name,O_RDONLY,0);
  #endif
#endif
      lseek(fd,start,SEEK_SET);
      read(fd,sc,len);
      close(fd);
      return(sc);
    }
  else return(NULL);
}

char *sound_type_name(int type)
{
  return(mus_header_type2string(type));
}

char *sound_format_name(int format)
{
  return(mus_header_data_format2string(format));
}

int sound_bytes_per_sample(int format) {return(mus_format2bytes(format));}

typedef struct {
  int fd;
  char *name;
} output_info;

static output_info **header_names = NULL;
static int header_names_size = 0;

static void save_header_name(int fd, char *arg)
{
  int i,loc;
#ifdef MACOS
  output_info **ptr;
#endif
  loc = -1;
  for (i=0;i<header_names_size;i++)
    {
      if (header_names[i] == NULL)
	{
	  loc = i;
	  break;
	}
    }
  if (loc == -1)
    {
      loc = header_names_size;
      header_names_size += 4;
      if (header_names == NULL)
	header_names = (output_info **)CALLOC(header_names_size,sizeof(output_info *));
      else 
	{
#ifdef MACOS
	  ptr = (output_info **)CALLOC(header_names_size,sizeof(output_info *));
	  for (i=0;i<loc;i++) ptr[i] = header_names[i];
	  FREE(header_names);
	  header_names = ptr;
#else
	  header_names = (output_info **)REALLOC(header_names,header_names_size * sizeof(output_info *));
#endif
	  for (i=loc;i<header_names_size;i++) header_names[i] = NULL;
	}
    }
  header_names[loc] = (output_info *)CALLOC(1,sizeof(output_info));
  header_names[loc]->fd = fd;
  header_names[loc]->name = s_copy_string(arg);
}

static void flush_header(int fd)
{
  int i,loc,val;
  sound_file *sf;
  loc = -1;
  val = -1;
  for (i=0;i<header_names_size;i++)
    {
      if (header_names[i])
	{
	  if (header_names[i]->fd == fd)
	    {
	      loc = i;
	      break;
	    }
	}
    }
  if (loc != -1)
    {
      if (header_names[loc]->name)
	{ 
	  sf = getsf(header_names[loc]->name);
	  if (sf) sf->write_date = 0; /* force subsequent re-read */
	  FREE(header_names[loc]->name);
	  header_names[loc]->name = NULL;
	}   
      FREE(header_names[loc]);
      header_names[loc] = NULL;
    }
}

int open_sound_input (char *arg) 
{
  int fd;
  sound_file *sf = NULL;
  set_audio_error(SNDLIB_NO_ERROR);
  initialize_sndlib();
  fd = mus_open_read(arg);
  if (fd != -1)
    {
      if ((sf = find_sound_file(arg)) == NULL)
	{
	  sf = read_sound_file_header_with_fd(fd,arg);
	}
    }
  if (sf) 
    {
      mus_set_file_descriptors(fd,sf->data_format,sf->datum_size,sf->data_location,sf->chans,sf->header_type);
      mus_seek(fd,sf->data_location,SEEK_SET);
    }
  else set_audio_error(SNDLIB_CANT_OPEN); 
  return(fd);
}

int open_sound_output (char *arg, int srate, int chans, int data_format, int header_type, char *comment)
{
  int fd = 0,err,comlen = 0;
  if (comment) comlen = strlen(comment);
  set_audio_error(SNDLIB_NO_ERROR);
  initialize_sndlib();
  err = mus_write_header(arg,header_type,srate,chans,0,0,data_format,comment,comlen);
  if (err != -1)
    {
      fd = mus_open_write(arg);
      mus_set_file_descriptors(fd,data_format,mus_format2bytes(data_format),mus_header_data_location(),chans,header_type);
      save_header_name(fd,arg);
    }
  else set_audio_error(SNDLIB_CANT_OPEN); 
  return(fd);
}

int reopen_sound_output(char *arg, int chans, int format, int type, int data_loc)
{
  int fd;
  set_audio_error(SNDLIB_NO_ERROR);
  initialize_sndlib();
  fd = mus_reopen_write(arg);
  mus_set_file_descriptors(fd,format,mus_format2bytes(format),data_loc,chans,type);
  save_header_name(fd,arg);
  return(fd);
}

int close_sound_input (int fd) 
{
  return(mus_close(fd)); /* this closes the clm file descriptors */
}

int close_sound_output (int fd, int bytes_of_data) 
{
  flush_header(fd);
  mus_update_header_with_fd(fd,mus_get_header_type(fd),bytes_of_data);
  return(mus_close(fd));
}

int read_sound (int fd, int beg, int end, int chans, int **bufs) 
{
  return(mus_read(fd,beg,end,chans,bufs));
}

int write_sound (int tfd, int beg, int end, int chans, int **bufs) 
{
  return(mus_write(tfd,beg,end,chans,bufs));
}

int seek_sound (int tfd, long offset, int origin) 
{
  return(mus_seek(tfd,offset,origin));
}

int seek_sound_frame(int tfd, int frame)
{
  return(mus_seek_frame(tfd,frame));
}

int override_sound_header(char *arg, int srate, int chans, int format, int type, int location, int size)
{
  sound_file *sf; 
  /* perhaps once a header has been over-ridden, we should not reset the relevant fields upon re-read? */
  sf = getsf(arg); 
  if (sf)
    {
      if (location != -1) sf->data_location = location;
      if (size != -1) sf->samples = size;
      if (format != -1) 
	{
	  sf->data_format = format;
	  sf->datum_size = mus_format2bytes(format);
	}
      if (srate != -1) sf->srate = srate;
      if (chans != -1) sf->chans = chans;
      if (type != -1) sf->header_type = type;
      return(0);
    }
  else return(-1);
}

int sound_max_amp(char *ifile, int *vals)
{
  int ifd,ichans,bufnum,n,curframes,i,frames,chn,fc;
  int *buffer,*time,*samp;
  int **ibufs;
  sound_file *sf; 
  sf = getsf(ifile); 
  if ((sf) && (sf->max_amps))
    {
      for (chn=0;chn<sf->chans;chn++)
	{
	  vals[chn*2] = sf->max_amps[chn*2];
	  vals[chn*2+1] = sf->max_amps[chn*2+1];
	}
      return(sf->samples / sf->chans);
    }
  ifd = open_sound_input(ifile);
  sf = getsf(ifile);
  if (ifd == -1) return(-1);
  ichans = sound_chans(ifile);
  frames = sound_frames(ifile);
  if (frames <= 0) {close_sound_input(ifd); return(0);}
  seek_sound_frame(ifd,0);
  ibufs = (int **)CALLOC(ichans,sizeof(int *));
  bufnum = 8192;
  for (i=0;i<ichans;i++) ibufs[i] = (int *)CALLOC(bufnum,sizeof(int));
  time = (int *)CALLOC(ichans,sizeof(int));
  samp = (int *)CALLOC(ichans,sizeof(int));
  for (n=0;n<frames;n+=bufnum)
    {
      if ((n+bufnum)<frames) curframes = bufnum; else curframes = (frames-n);
      read_sound(ifd,0,curframes-1,ichans,ibufs);
      for (chn=0;chn<ichans;chn++)
	{
	  buffer = (int *)(ibufs[chn]);
	  fc=samp[chn];
	  for (i=0;i<curframes;i++) 
	    {
	      if ((buffer[i]>fc) || (fc < -buffer[i])) 
		{
		  time[chn]=i+n; 
		  samp[chn]=buffer[i]; 
		  if (samp[chn]<0) samp[chn] = -samp[chn];
		  fc = samp[chn];
		}
	    }
	}
    }
  close_sound_input(ifd);
  if (sf->max_amps == NULL) sf->max_amps = (int *)CALLOC(ichans*2,sizeof(int));
  for (chn=0,i=0;chn<ichans;chn++,i+=2)
    {
      vals[i]=samp[chn];
      vals[i+1]=time[chn];
      sf->max_amps[i] = vals[i];
      sf->max_amps[i+1] = vals[i+1];
    }
  FREE(time);
  FREE(samp);
  for (i=0;i<ichans;i++) FREE(ibufs[i]);
  FREE(ibufs);
  return(frames);
}


int mus_file2array(char *filename, int chan, int start, int samples, int *array)
{
  int ifd,chans,total_read;
  int **bufs;
  ifd = open_sound_input(filename);
  if (ifd == -1) return(-1);
  chans = sound_chans(filename);
  bufs = (int **)CALLOC(chans,sizeof(int *));
  bufs[chan] = array;
  seek_sound_frame(ifd,start);
  total_read = mus_read_any(ifd,0,chans,samples,bufs,(int *)bufs);
  close_sound_input(ifd);
  FREE(bufs);
  return(total_read);
}

int mus_array2file(char *filename, int *ddata, int len, int srate, int channels)
{
  /* put ddata into a sound file, taking byte order into account */
  /* assume ddata is interleaved already if more than one channel */
  int fd;
#ifdef SNDLIB_LITTLE_ENDIAN
  int i;
  unsigned char *o;
  unsigned char tmp;
#endif
  fd = mus_create(filename);
  if (fd == -1) return(-1);
  mus_write_next_header(fd,srate,channels,28,len*4,SNDLIB_32_LINEAR,NULL,0);
#ifdef SNDLIB_LITTLE_ENDIAN
  o = (unsigned char *)ddata;
  for (i=0;i<len;i++,o+=4)
    {
      tmp = o[0]; o[0]=o[3]; o[3]=tmp; tmp=o[1]; o[1]=o[2]; o[2]=tmp;
    }
#endif
#ifndef MACOS
  write(fd,(unsigned char *)ddata,len*4);
#else
  write(fd,(char *)ddata,len*4);
#endif
  close(fd);
  return(0);
}

