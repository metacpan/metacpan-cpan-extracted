#include "../helper.c"

#include <errno.h>
#include <irman.h>

static int
if_init (int argc, char *argv[])
{
  char *portname;
  int fd;

  if (argc < 1)
    tx_abort ("irman: portname expected");

  portname = argv[0];

  if (ir_init_commands (0, 0))
    tx_abort ("irman: ir_init_commands failed");

  if ((fd = ir_init (portname[0] ? portname : ir_default_portname ())) < 0)
    tx_abort (ir_strerror (errno));

  return fd;
}

static void
if_exit (int fd)
{
  /* ir_finish (); */
  /* ir_free_commands (); */
}

static void
if_parse (int fd)
{
  static unsigned char *last_code;
  unsigned char *code = ir_get_code ();

  /* irman is badly designed */
  if (!code && errno == IR_EDUPCODE)
    code = last_code;

  if (code)
    {
      char *text = ir_code_to_text (code);
      last_code = code;

      tx_code (text, ir_text_to_name (text));
    }
}



