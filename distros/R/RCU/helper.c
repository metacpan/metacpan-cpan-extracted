#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* return filehandle */
static int if_init (int argc, char *argv[]);
static void if_exit (int fd);
static void if_parse (int fd);

void
tx_error (const char *err)
{
  char buf[512];
  write (1, buf, snprintf (buf, sizeof (buf), "E%s", err) + 1);
}

void
tx_abort (const char *err)
{
  if (err)
    tx_error (err);

  exit (1);
}

void tx_code (const char *raw, const char *cooked)
{
  char buf[512];
  struct timeval tv;

  gettimeofday (&tv, 0);
  write (1, buf, snprintf (buf, sizeof (buf), "=%ld.%06ld\x01%s\x01%s",
                           tv.tv_sec, tv.tv_usec,
                           raw, cooked) + 1);
}

#define USAGE "This program should only be called by the perl RCU module\n"
#define MAX(a,b) ((a) > (b) ? (a) : (b))

int
main (int argc, char *argv[])
{
  int ifd;

  if (argc < 2)
    {
      write (1, USAGE, sizeof USAGE);
      exit (1);
    }

  ifd = if_init (argc - 2, argv + 2);

  if (ifd >= 0)
    {
      write (1, "I", 2); /* I<nul> */

      for(;;)
        {
          fd_set fds;
      
          FD_ZERO (&fds);
          FD_SET (ifd, &fds);
          FD_SET (0, &fds);

          if (select (ifd + 1, &fds, 0, 0, 0) >= 0)
            {
              if (FD_ISSET (0, &fds))
                break;

              if (FD_ISSET (ifd, &fds))
                if_parse (ifd);
            }
        }
    }
  else
    tx_abort ("unable to set-up ir-link");

  if_exit (ifd);

  return 0;
}
