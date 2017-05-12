#ifndef SNDLIB_H
#define SNDLIB_H


/* taken from libtool's demo/foo.h to try to protect us from C++ and ancient C's */
#undef __BEGIN_DECLS
#undef __END_DECLS
#ifdef __cplusplus
# define __BEGIN_DECLS extern "C" {
# define __END_DECLS }
#else
# define __BEGIN_DECLS /* empty */
# define __END_DECLS /* empty */
#endif

#undef __P
#if defined (__STDC__) || defined (_AIX) || (defined (__mips) && defined (_SYSTYPE_SVR4)) || defined(WIN32) || defined(__cplusplus)
# define __P(protos) protos
#else
# define __P(protos) ()
#endif


#define SNDLIB_VERSION 8
#define SNDLIB_REVISION 2
#define SNDLIB_DATE "6-Dec-99"

/* 1: Oct-98
 * 2: Oct-98: removed header override functions
 * 3: Dec-98: removed output_scaler
 * 4: Jan-99: Sun-related word-alignment changes, C++ fixups
 * 5: Mar-99: changed float_sound to omit the scaling by SNDLIB_SNDFLT
 *            removed perror calls
 *            added sndlib2scm.c, sndlib-strings.h
 *            8: fixed windoze audio_output bug
 *            9: fixed Mac p2cstr potential bug
 * 6: Jun-99: moved clm-specific code out of sndlib files 
 *            changed many names to use "mus" prefix, or "SNDLIB" (and upper case)
 *            added sound_frames
 *            added clm.c, clm.h, vct.c, vct.h, clm2scm.c
 *            added reopen_sound_output (arg order changed rev 6), mus_seek_frame, sound_seek_frame
 *    Jul-99: added sound_max_amp, mus_error
 *    Aug-99: old-sndlib.h for backwards compatibility, added mus_fwrite
 *    Sep-99: added mus_set_raw_header_defaults, mus_probe_file
 * 7: Sep-99: ALSA port thanks to Paul Barton-Davis
 *            fixed 2 bugs related to Sonorus Studio support
 *            several clm.c/clm2scm.c bugs and oversights repaired.
 *            added list2vct, mus_file2array, mus_array2file, dsp_devices.
 *            7: added configure files, README.sndlib, changed tar file to use sndlib directory
 *            8: added -1 as error return from various functions (void->int change in io.c and headers.c)
 *               added mus_header_writable, mus_header_aiff_p, sound_aiff_p
 *            9: much more of sndlib tied into sndlib2scm
 *            10: tried to get SGI new AL default devices to work right
 *            11: USE_BYTESWAP in io.c (if you want to use the GLibC macros).
 *            14: added forget_sound to remove entry from sound data base.
 *            18: added more vct funcs, formant-bank, oscil-bank, etc.
 * 8: Nov-99: decided to make a non-compatible change: AIFF_sound file is now AIFC_sound_file,
 *              and old_style_AIFF_sound_file is now AIFF_sound_file.
 */

#ifndef HAVE_SNDLIB
  #define HAVE_SNDLIB 1
#endif

/* try to figure out what type of machine (and in worst case, what OS) we're running on */
/* gcc has various compile-time macros like #cpu, but we're hoping to run in Metroworks C, Watcom C, MSC, CodeWarrior, MPW, etc */

#if defined(HAVE_CONFIG_H)
  #include "config.h"
  #if (!defined(WORDS_BIGENDIAN))
     #define SNDLIB_LITTLE_ENDIAN 1
  #endif
  #if (SIZEOF_INT_P != SIZEOF_INT)
     #define LONG_INT_P 1
  #else 
     #define LONG_INT_P 0
  #endif
#else
  #if defined(ALPHA) || defined(__alpha__)
     #define LONG_INT_P 1
  #else 
     #define LONG_INT_P 0
  #endif
  #define RETSIGTYPE void
  #ifdef __LITTLE_ENDIAN__
    /* NeXTStep on Intel */
    #define SNDLIB_LITTLE_ENDIAN 1
  #else
    #ifdef BYTE_ORDER
      #if (BYTE_ORDER == LITTLE_ENDIAN)
        /* SGI possibility (/usr/include/sys/endian.h), and Linux (/usr/include/bytesex.h and endian.h) */
        /* Alpha is apparently /usr/include/alpha/endian.h */
        #define SNDLIB_LITTLE_ENDIAN 1
      #endif
    #endif
  #endif
#endif

#ifndef __GNUC__
  #ifndef __FUNCTION__
    #define __FUNCTION__ ""
  #endif
#endif

#if defined(ALPHA) || defined(WINDOZE) || defined(__alpha__)
  #define SNDLIB_LITTLE_ENDIAN 1
#endif

#if (!(defined(MACOS))) && (defined(MPW_C) || defined(macintosh) || defined(__MRC__))
  #define MACOS 1
#endif

/* due to project builder stupidity, we can't always depend on -D flags here (maybe we need a SNDLIB_OS macro?) */
/* these wouldn't work with autoconf anyway, so we'll do it by hand */

#if (!defined(SGI)) && (!defined(NEXT)) && (!defined(LINUX)) && (!defined(MACOS)) && (!defined(BEOS)) && (!defined(SUN)) && (!defined(UW2)) && (!defined(SCO5)) && (!defined(ALPHA)) && (!defined(WINDOZE))
  #if defined(__dest_os)
    /* we're in Metrowerks Land */
    #if (__dest_os == __be_os)
      #define BEOS 1
    #else
      #if (__dest_os == __mac_os)
        #define MACOS 1
      #endif
    #endif
  #else
    #if macintosh
      #define MACOS 1
    #else
      #if (__WINDOWS__) || (__NT__) || (_WIN32) || (__CYGWIN__)
        #define WINDOZE 1
        #define SNDLIB_LITTLE_ENDIAN 1
      #else
        #ifdef __alpha__
          #define ALPHA 1
          #define SNDLIB_LITTLE_ENDIAN 1
        #endif
      #endif
    #endif
  #endif
#endif  

/* others apparently are __QNX__ __bsdi__ __FreeBSD__ */

#if defined(LINUX) && defined(PPC) && (!(defined(MKLINUX)))
  #define MKLINUX 1
#endif

#ifndef HAVE_ALSA
  #if defined(MKLINUX) || defined(LINUX) || defined(SCO5) || defined(UW2) || defined(HAVE_SOUNDCARD_H) || defined(HAVE_SYS_SOUNDCARD_H) || defined(HAVE_MACHINE_SOUNDCARD_H)
    #define HAVE_OSS 1
  #else
    #define HAVE_OSS 0
  #endif
#else
  #define HAVE_OSS 0
#endif

#if (!defined(M_PI))
  #define M_PI 3.14159265358979323846264338327
  #define M_PI_2 (M_PI/2.0)
#endif

#define TWO_PI (2.0*M_PI)

#ifndef SEEK_SET
  #define SEEK_SET 0
#endif

#ifndef SEEK_CUR
  #define SEEK_CUR 1
#endif

#ifndef SEEK_END
  #define SEEK_END 2
#endif

#define SNDLIB_DAC_CHANNEL 252525
#define SNDLIB_DAC_REVERB 252520
#define SNDLIB_SNDFIX 32768.0
#define SNDLIB_SNDFLT 0.000030517578

#define unsupported_sound_file -1
#define NeXT_sound_file 0
#define AIFC_sound_file 1
#define RIFF_sound_file 2
#define BICSF_sound_file 3
#define NIST_sound_file 4
#define INRS_sound_file 5
#define ESPS_sound_file 6
#define SVX_sound_file 7
#define VOC_sound_file 8
#define SNDT_sound_file 9
#define raw_sound_file 10
#define SMP_sound_file 11
#define SD2_sound_file 12
#define AVR_sound_file 13
#define IRCAM_sound_file 14
#define SD1_sound_file 15
#define SPPACK_sound_file 16
#define MUS10_sound_file 17
#define HCOM_sound_file 18
#define PSION_sound_file 19
#define MAUD_sound_file 20
#define IEEE_sound_file 21
#define DeskMate_sound_file 22
#define DeskMate_2500_sound_file 23
#define Matlab_sound_file 24
#define ADC_sound_file 25
#define SoundEdit_sound_file 26
#define SoundEdit_16_sound_file 27
#define DVSM_sound_file 28
#define MIDI_file 29
#define Esignal_file 30
#define soundfont_sound_file 31
#define gravis_sound_file 32
#define comdisco_sound_file 33
#define goldwave_sound_file 34
#define srfs_sound_file 35
#define MIDI_sample_dump 36
#define DiamondWare_sound_file 37
#define RealAudio_sound_file 38
#define ADF_sound_file 39
#define SBStudioII_sound_file 40
#define Delusion_sound_file 41
#define Farandole_sound_file 42
#define Sample_dump_sound_file 43
#define Ultratracker_sound_file 44
#define Yamaha_SY85_sound_file 45
#define Yamaha_TX16_sound_file 46
#define digiplayer_sound_file 47
#define Covox_sound_file 48
#define SPL_sound_file 49
#define AVI_sound_file 50
#define OMF_sound_file 51
#define Quicktime_sound_file 52
#define asf_sound_file 53
#define Yamaha_SY99_sound_file 54
#define Kurzweil_2000_sound_file 55
#define AIFF_sound_file 56


#define SNDLIB_UNSUPPORTED -1
#define SNDLIB_NO_SND 0
#define SNDLIB_16_LINEAR 1
#define SNDLIB_8_MULAW 2
#define SNDLIB_8_LINEAR 3
#define SNDLIB_32_FLOAT 4
#define SNDLIB_32_LINEAR 5
#define SNDLIB_8_ALAW 6
#define SNDLIB_8_UNSIGNED 7
#define SNDLIB_24_LINEAR 8
#define SNDLIB_64_DOUBLE 9
#define SNDLIB_16_LINEAR_LITTLE_ENDIAN 10
#define SNDLIB_32_LINEAR_LITTLE_ENDIAN 11
#define SNDLIB_32_FLOAT_LITTLE_ENDIAN 12
#define SNDLIB_64_DOUBLE_LITTLE_ENDIAN 13
#define SNDLIB_16_UNSIGNED 14
#define SNDLIB_16_UNSIGNED_LITTLE_ENDIAN 15
#define SNDLIB_24_LINEAR_LITTLE_ENDIAN 16
#define SNDLIB_32_VAX_FLOAT 17
#define SNDLIB_12_LINEAR 18
#define SNDLIB_12_LINEAR_LITTLE_ENDIAN 19
#define SNDLIB_12_UNSIGNED 20
#define SNDLIB_12_UNSIGNED_LITTLE_ENDIAN 21
/* 64-bit ints apparently can occur in ESPS files */

#ifdef SNDLIB_LITTLE_ENDIAN
  #define SNDLIB_COMPATIBLE_FORMAT SNDLIB_16_LINEAR_LITTLE_ENDIAN
#else
  #define SNDLIB_COMPATIBLE_FORMAT SNDLIB_16_LINEAR
#endif

#define SNDLIB_NIST_shortpack 2
#define SNDLIB_AIFF_IMA_ADPCM 99

#define SNDLIB_DEFAULT_DEVICE 0
#define SNDLIB_READ_WRITE_DEVICE 1
#define SNDLIB_ADAT_IN_DEVICE 2
#define SNDLIB_AES_IN_DEVICE 3
#define SNDLIB_LINE_OUT_DEVICE 4
#define SNDLIB_LINE_IN_DEVICE 5
#define SNDLIB_MICROPHONE_DEVICE 6
#define SNDLIB_SPEAKERS_DEVICE 7
#define SNDLIB_DIGITAL_IN_DEVICE 8
#define SNDLIB_DIGITAL_OUT_DEVICE 9
#define SNDLIB_DAC_OUT_DEVICE 10
#define SNDLIB_ADAT_OUT_DEVICE 11
#define SNDLIB_AES_OUT_DEVICE 12
#define SNDLIB_DAC_FILTER_DEVICE 13
#define SNDLIB_MIXER_DEVICE 14
#define SNDLIB_LINE1_DEVICE 15
#define SNDLIB_LINE2_DEVICE 16
#define SNDLIB_LINE3_DEVICE 17
#define SNDLIB_AUX_INPUT_DEVICE 18
#define SNDLIB_CD_IN_DEVICE 19
#define SNDLIB_AUX_OUTPUT_DEVICE 20
#define SNDLIB_SPDIF_IN_DEVICE 21
#define SNDLIB_SPDIF_OUT_DEVICE 22

#define SNDLIB_AUDIO_SYSTEM(n) ((n)<<16)
#define SNDLIB_SYSTEM(n) (((n)>>16)&0xffff)
#define SNDLIB_DEVICE(n) ((n)&0xffff)

#define SNDLIB_NO_ERROR 0
#define SNDLIB_CHANNELS_NOT_AVAILABLE 1
#define SNDLIB_SRATE_NOT_AVAILABLE 2
#define SNDLIB_FORMAT_NOT_AVAILABLE 3
#define SNDLIB_NO_INPUT_AVAILABLE 4
#define SNDLIB_NO_OUTPUT_AVAILABLE 5
#define SNDLIB_INPUT_BUSY 6
#define SNDLIB_OUTPUT_BUSY 7
#define SNDLIB_CONFIGURATION_NOT_AVAILABLE 8
#define SNDLIB_INPUT_CLOSED 9
#define SNDLIB_OUTPUT_CLOSED 10
#define SNDLIB_IO_INTERRUPTED 11
#define SNDLIB_NO_LINES_AVAILABLE 12
#define SNDLIB_WRITE_ERROR 13
#define SNDLIB_SIZE_NOT_AVAILABLE 14
#define SNDLIB_DEVICE_NOT_AVAILABLE 15
#define SNDLIB_CANT_CLOSE 16
#define SNDLIB_CANT_OPEN 17
#define SNDLIB_READ_ERROR 18
#define SNDLIB_AMP_NOT_AVAILABLE 19
#define SNDLIB_AUDIO_NO_OP 20
#define SNDLIB_CANT_WRITE 21
#define SNDLIB_CANT_READ 22
#define SNDLIB_NO_READ_PERMISSION 23

#define SNDLIB_AMP_FIELD 0
#define SNDLIB_SRATE_FIELD 1
#define SNDLIB_CHANNEL_FIELD 2
#define SNDLIB_FORMAT_FIELD 3
#define SNDLIB_DEVICE_FIELD 4
#define SNDLIB_IMIX_FIELD 5
#define SNDLIB_IGAIN_FIELD 6
#define SNDLIB_RECLEV_FIELD 7
#define SNDLIB_PCM_FIELD 8
#define SNDLIB_PCM2_FIELD 9
#define SNDLIB_OGAIN_FIELD 10
#define SNDLIB_LINE_FIELD 11
#define SNDLIB_MIC_FIELD 12
#define SNDLIB_LINE1_FIELD 13
#define SNDLIB_LINE2_FIELD 14
#define SNDLIB_LINE3_FIELD 15
#define SNDLIB_SYNTH_FIELD 16
#define SNDLIB_BASS_FIELD 17
#define SNDLIB_TREBLE_FIELD 18
#define SNDLIB_CD_FIELD 19

enum {MUS_NO_ERROR,MUS_NO_FREQUENCY,MUS_NO_PHASE,MUS_NO_GEN,MUS_NO_LENGTH,
      MUS_NO_FREE,MUS_NO_DESCRIBE,MUS_NO_EQUALP,MUS_NO_DATA,MUS_NO_SCALER,
      MUS_MEMORY_ALLOCATION_FAILED,MUS_UNSTABLE_TWO_POLE_ERROR,
      MUS_INVALID_CHANNEL_FOR_FRAME,MUS_CANT_OPEN_FILE,MUS_NO_SAMPLE_INPUT,
      MUS_NO_SAMPLE_OUTPUT,MUS_NO_FRAME_INPUT,MUS_NO_FRAME_OUTPUT,
      MUS_NO_SUCH_CHANNEL,MUS_NO_FILE_NAME_PROVIDED,MUS_NO_LOCATION,MUS_NO_CHANNEL,
      MUS_NO_SUCH_FFT_WINDOW,
      MUS_UNSUPPORTED_DATA_FORMAT,MUS_HEADER_READ_FAILED,MUS_HEADER_TOO_MANY_AUXILIARY_COMMENTS,MUS_UNSUPPORTED_HEADER_TYPE,
      MUS_FILE_DESCRIPTORS_NOT_INITIALIZED,MUS_NOT_A_SOUND_FILE,MUS_FILE_CLOSED,MUS_WRITE_ERROR,
      MUS_BOGUS_FREE,MUS_BUFFER_OVERFLOW,MUS_BUFFER_UNDERFLOW,MUS_FILE_OVERFLOW,MUS_EXPONENT_OVERFLOW,
      MUS_INITIAL_ERROR_TAG};

/* realloc is enough of a mess that I'll handle each case individually */

#ifdef MACOS
  /* C's calloc/free are incompatible with Mac's SndDisposeChannel (which we can't avoid using) */
  #define CALLOC(a,b)  NewPtrClear((a) * (b))
  #define MALLOC(a)    NewPtr((a))
  #define FREE(a)      DisposePtr((Ptr)(a))
#else
  #ifdef DEBUG_MEMORY
    #define CALLOC(a,b)  mem_calloc(a,b,__FUNCTION__,__FILE__,__LINE__)
    #define MALLOC(a)    mem_malloc(a,__FUNCTION__,__FILE__,__LINE__)
    #define FREE(a)      mem_free(a,__FUNCTION__,__FILE__,__LINE__)
    #define REALLOC(a,b) mem_realloc(a,b,__FUNCTION__,__FILE__,__LINE__)
  #else
    #define CALLOC(a,b)  calloc(a,b)
    #define MALLOC(a)    malloc(a)
    #define FREE(a)      free(a)
    #define REALLOC(a,b) realloc(a,b)
  #endif
#endif 

#define SNDLIB_MAX_FILE_NAME 128

__BEGIN_DECLS

#ifdef __GNUC__
  void mus_error(int error, char *format, ...) __attribute__ ((format (printf, 2, 3)));
  void mus_fwrite(int fd, char *format, ...) __attribute__ ((format (printf, 2, 3)));
#else
  void mus_error __P((int error, char *format, ...));
  void mus_fwrite __P((int fd, char *format, ...));
#endif
void mus_set_error_handler(void (*new_error_handler)(int err_type, char *err_msg));
int mus_make_error_tag __P((void));

int sound_samples __P((char *arg));
int sound_frames __P((char *arg));
int sound_datum_size __P((char *arg));
int sound_data_location __P((char *arg));
int sound_chans __P((char *arg));
int sound_srate __P((char *arg));
int sound_header_type __P((char *arg));
int sound_data_format __P((char *arg));
int sound_original_format __P((char *arg));
int sound_comment_start __P((char *arg));
int sound_comment_end __P((char *arg));
int sound_length __P((char *arg));
int sound_fact_samples __P((char *arg));
int sound_distributed __P((char *arg));
int sound_write_date __P((char *arg));
int sound_type_specifier __P((char *arg));
int sound_align __P((char *arg));
int sound_bits_per_sample __P((char *arg));
char *sound_type_name __P((int type));
char *sound_format_name __P((int format));
char *sound_comment __P((char *name));
int sound_bytes_per_sample __P((int format));
float sound_duration __P((char *arg));
int initialize_sndlib __P((void));
int override_sound_header __P((char *arg, int srate, int chans, int format, int type, int location, int size));
int forget_sound __P((char *name));

int open_sound_input __P((char *arg));
int open_sound_output __P((char *arg, int srate, int chans, int data_format, int header_type, char *comment));
int reopen_sound_output __P((char *arg, int chans, int format, int type, int data_loc));
int close_sound_input __P((int fd));
int close_sound_output __P((int fd, int bytes_of_data));
int read_sound __P((int fd, int beg, int end, int chans, int **bufs));
int write_sound __P((int tfd, int beg, int end, int chans, int **bufs));
int seek_sound __P((int tfd, long offset, int origin));
int seek_sound_frame __P((int tfd, int frame));

void describe_audio_state __P((void));
char *report_audio_state __P((void));
int open_audio_output __P((int dev, int srate, int chans, int format, int size));
int open_audio_input __P((int dev, int srate, int chans, int format, int size));
int write_audio __P((int line, char *buf, int bytes));
int close_audio __P((int line));
int read_audio __P((int line, char *buf, int bytes));
int read_audio_state __P((int dev, int field, int chan, float *val));
int write_audio_state __P((int dev, int field, int chan, float *val));
void save_audio_state __P((void));
void restore_audio_state __P((void));
int audio_error __P((void));
int initialize_audio __P((void));
char *audio_error_name __P((int err));
void set_audio_error __P((int err));
int audio_systems __P((void));
char *audio_system_name __P((int system));
char *audio_moniker __P((void));
#if (HAVE_OSS || HAVE_ALSA)
  void set_dsp_devices __P((int cards, int *dsps, int *mixers));
  void dsp_devices __P((int cards, int *dsps, int *mixers));
  void set_oss_buffers __P((int num,int size));
#endif
void write_mixer_state __P((char *file));
void read_mixer_state __P((char *file));

#ifdef CLM
  void reset_io_c __P((void));
  void reset_headers_c __P((void));
  void reset_audio_c __P((void));
  void set_rt_audio_p __P((int rt));
  int get_shift_24_choice __P((void));
  void set_shift_24_choice __P((int choice));
  int net_mix __P((int fd, int loc, char *buf1, char *buf2, int bytes));
#endif

int mus_open_file_descriptors __P((int tfd, int df, int ds, int dl));
int mus_set_file_descriptors __P((int tfd, int df, int ds, int dl, int dc, int dt));
int mus_close_file_descriptors __P((int tfd));
int mus_cleanup_file_descriptors __P((void));
int mus_open_read __P((char *arg));
int mus_probe_file __P((char *arg));
int mus_open_write __P((char *arg));
int mus_create __P((char *arg));
int mus_reopen_write __P((char *arg));
int mus_close __P((int fd));
long mus_seek __P((int tfd, long offset, int origin));
int mus_seek_frame __P((int tfd, int frame));
int mus_read __P((int fd, int beg, int end, int chans, int **bufs));
int mus_read_chans __P((int fd, int beg, int end, int chans, int **bufs, int *cm));
int mus_write_zeros __P((int tfd, int num));
int mus_write __P((int tfd, int beg, int end, int chans, int **bufs));
int mus_float_sound __P((char *charbuf, int samps, int charbuf_format, float *buffer));
int mus_header_samples __P((void));
int mus_header_data_location __P((void));
int mus_header_chans __P((void));
int mus_header_srate __P((void));
int mus_header_type __P((void));
int mus_header_format __P((void));
int mus_header_distributed __P((void));
int mus_header_comment_start __P((void));
int mus_header_comment_end __P((void));
int mus_header_type_specifier __P((void));
int mus_header_bits_per_sample __P((void));
int mus_header_fact_samples __P((void));
int mus_header_block_align __P((void));
int mus_header_loop_mode __P((int which));
int mus_header_loop_start __P((int which));
int mus_header_loop_end __P((int which));
int mus_header_mark_position __P((int id));
int mus_header_base_note __P((void));
int mus_header_base_detune __P((void));
void mus_set_raw_header_defaults __P((int sr, int chn, int frm));
int mus_true_file_length __P((void));
int mus_header_original_format __P((void));
int mus_format2bytes __P((int format));
int mus_header_format2bytes __P((void));
int mus_samples2bytes __P((int format, int size));
int mus_bytes2samples __P((int format, int size));
int mus_write_next_header __P((int chan, int srate, int chans, int loc, int siz, int format, char *comment, int len));
int mus_read_header_with_fd __P((int chan));
int mus_read_header __P((char *name));
int mus_write_header __P((char *name, int type, int srate, int chans, int loc, int size, int format, char *comment, int len));
int mus_write_header_with_fd __P((int chan, int type, int in_srate, int in_chans, int loc, int size, int format, char *comment, int len));
void mus_set_aifc_header __P((int val));
int mus_update_header_with_fd __P((int chan, int type, int siz));
int mus_update_header __P((char *name, int type, int size, int srate, int format, int chans, int loc));
int mus_header_aux_comment_start __P((int n));
int mus_header_aux_comment_end __P((int n));
int mus_update_header_comment __P((char *name, int loc, char *comment, int len, int typ));
int mus_create_header_buffer __P((void));
int mus_create_descriptors __P((void));
int mus_read_any __P((int tfd, int beg, int chans, int nints, int **bufs, int *cm));
void mus_set_snd_header __P((int in_srate, int in_chans, int in_format));
int mus_unshort_sound __P((short *in_buf, int samps, int new_format, char *out_buf));
int sound_max_amp __P((char *ifile, int *vals));

int mus_header_aiff_p __P((void));
int sound_aiff_p __P((char *arg));
int mus_header_writable __P((int type, int format));
char *mus_header_type2string __P((int type));
char *mus_header_data_format2string __P((int format));

void mus_set_big_endian_int __P((unsigned char *j, int x));
int mus_big_endian_int __P((unsigned char *inp));
void mus_set_little_endian_int __P((unsigned char *j, int x));
int mus_little_endian_int __P((unsigned char *inp));
int mus_uninterpreted_int __P((unsigned char *inp));
void mus_set_big_endian_float __P((unsigned char *j, float x));
float mus_big_endian_float __P((unsigned char *inp));
void mus_set_little_endian_float __P((unsigned char *j, float x));
float mus_little_endian_float __P((unsigned char *inp));
void mus_set_big_endian_short __P((unsigned char *j, short x));
short mus_big_endian_short __P((unsigned char *inp));
void mus_set_little_endian_short __P((unsigned char *j, short x));
short mus_little_endian_short __P((unsigned char *inp));
void mus_set_big_endian_unsigned_short __P((unsigned char *j, unsigned short x));
unsigned short mus_big_endian_unsigned_short __P((unsigned char *inp));
void mus_set_little_endian_unsigned_short __P((unsigned char *j, unsigned short x));
unsigned short mus_little_endian_unsigned_short __P((unsigned char *inp));
double mus_little_endian_double __P((unsigned char *inp));
double mus_big_endian_double __P((unsigned char *inp));
void mus_set_big_endian_double __P((unsigned char *j, double x));
void mus_set_little_endian_double __P((unsigned char *j, double x));
unsigned int mus_big_endian_unsigned_int __P((unsigned char *inp));
unsigned int mus_little_endian_unsigned_int __P((unsigned char *inp));

#ifdef SUN
void sun_outputs __P((int speakers, int headphones, int line_out));
#endif

#if (defined(HAVE_CONFIG_H)) && (!defined(HAVE_STRERROR))
  char *strerror __P((int errnum));
#endif

void init_sndlib2scm __P((void));
char *mus_complete_filename __P((char *tok));

#if LONG_INT_P
  int *delist_ptr __P((int arr));
  int list_ptr __P((int *arr));
  void freearray __P((int ip_1));
#else
  void freearray __P((int *ip));
#endif

int mus_set_data_clipped __P((int tfd, int clipped));
int mus_set_header_type __P((int tfd, int type));
int mus_get_header_type __P((int tfd));
int mus_set_chans __P((int tfd, int chans));
int mus_file2array __P((char *filename, int chan, int start, int samples, int *array));
int mus_array2file __P((char *filename, int *ddata, int len, int srate, int channels));

#ifdef DEBUG_MEMORY
  void *mem_calloc __P((size_t len, size_t size, char *func, char *file, int line));
  void *mem_malloc __P((size_t len, char *func, char *file, int line));
  void mem_free __P((void *ptr, char *func, char *file, int line));
  void *mem_realloc __P((void *ptr, size_t size, char *func, char *file, int line));
#endif

__END_DECLS

#endif
