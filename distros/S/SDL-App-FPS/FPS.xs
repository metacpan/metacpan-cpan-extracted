#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <SDL/SDL.h>

/*
SDL::App::FPS XS code (C) by Tels <http://bloodgate.com/perl/> 
*/

/* our framerate monitor memory */
#define FRAMES_MAX 4096
unsigned int frames[FRAMES_MAX] = { 0 };
/* two pointers into the ringbuffer frames[] */
unsigned int frames_start = 0;
unsigned int frames_end = 0;
unsigned int last = 0;

double max_fps = 0;
double min_fps = 20000000;

unsigned int max_frame_time = 0;
unsigned int min_frame_time = 20000;

/* wake_time: the time we waited to long in this frame, and thus must be awake
   (e.g. not sleep) the next frame to correct for this */
unsigned int wake_time = 0;

MODULE = SDL::App::FPS		PACKAGE = SDL::App::FPS

PROTOTYPES: DISABLE


##############################################################################
# _delay() - if the time between last and this frame was too short, delay the
#            app a bit. Also returns current time corrected by base_ticks.

void
_delay(min_time,base_ticks)
	unsigned int	min_time
	unsigned int	base_ticks
  CODE:
    /*
     min_time  - ms to spent between frames minimum
     wake_time - ms we were late in last frame, so we slee this time shorter
     last      - time in ticks of last frame 
    */
    /* caluclate how long we should sleep */
    unsigned int now, time, frame_cnt, diff;
    int to_sleep;
    double framerate;

    now = SDL_GetTicks() - base_ticks;

    if (min_time > 0)
      {
      to_sleep = min_time - wake_time - (now - last) - 1;

      # sometimes Delay() does not seem to work, so retry until it we sleeped
      # long enough
      while (to_sleep > 2)
        {
        SDL_Delay(to_sleep);
        now = SDL_GetTicks() - base_ticks;
        to_sleep = min_time - (now - last);
        }
      wake_time = 0;

      if (now - last > min_time)
        {
        wake_time = now - last - min_time;
        }
      }
    diff = now - last;
    ST(0) = newSViv(now);
    ST(1) = newSViv(diff);
    last = now;

    /* ******************************************************************** */
    /* monitor the framerate */

    /* add current value to ringbuffer */
    frames[frames_end] = now; frames_end++;
    if (frames_end >= FRAMES_MAX)
      {
      frames_end = 0;
      }
    /* buffer full? if so, remove oldest entry */
    if (frames_end == frames_start)
      {
      frames_start++;
      if (frames_start >= FRAMES_MAX)
        {
        frames_start = 0;
        }
      }
    /* keep only values in the buffer, that are at most 1000 ms old */
    while (now - frames[frames_start] > 1000)
      {
      /* remove value from start */
      frames_start++;
      if (frames_start >= FRAMES_MAX)
        {
        frames_start = 0;
        }
      if (frames_start == frames_end)
        {
        /* buffer empty */
        break;
        }
      }
    framerate = 0;
    if (frames_start != frames_end)
      {
      /* got some frames, so calc. current frame rate */
      time = now - frames[frames_start] + 1;
      /* printf ("time %i start %i (%i) end %i (%i) ",
        time,frames_start,frames[frames_start],frames_end,now); */
      if (frames_start < frames_end)
        {
        frame_cnt = frames_end - frames_start + 1;
        } 
      else
        { 
        frame_cnt = 1024 - (frames_start - frames_end - 1);
        }
      /* does it make sense to calc. fps? */
      if (frame_cnt > 20)
        {
        framerate = (double)(10000 * frame_cnt / time) / 10;
        if (min_fps > framerate) { min_fps = framerate; }
        if (max_fps < framerate) { max_fps = framerate; }
        if (diff > max_frame_time) { max_frame_time = diff; }
        if (diff < min_frame_time && diff > 0) { min_frame_time = diff; }
        }
      /* printf (" frames %i time %i fps %f\n",frame_cnt,time,framerate); 
      printf (" min %f max %f\n",min_fps,max_fps); */
      }

    ST(2) = newSVnv(framerate);
    XSRETURN(3);

SV*
min_fps(myclass)
    CODE:
      RETVAL = newSVnv(min_fps);
    OUTPUT:
      RETVAL

SV*
max_fps(myclass)
    CODE:
      RETVAL = newSVnv(max_fps);
    OUTPUT:
      RETVAL

SV*
max_frame_time(myclass)
    CODE:
      RETVAL = newSViv(max_frame_time);
    OUTPUT:
      RETVAL

SV*
min_frame_time(myclass)
    CODE:
      RETVAL = newSViv(min_frame_time);
    OUTPUT:
      RETVAL

