/*
  KDE wrapper
*/

#include <kapplication.h>
#include <kaboutdata.h>
#include <kcmdlineargs.h>
#include <qtimer.h>
#include "kde_wrap.h"
#include "mainwnd.h"
#include "tray.h"

#include <sys/types.h>
#include <unistd.h>

/* Internal variables */

// KDE application object - will only by instantiated once
KApplication *kde_app;
// KDE Sys Tray support
KTray *kde_tray;
// Sys Tray Application Window
MainWindow *kde_wnd;

// Process execution path
char exec_path[512];

/* get_exec_path */
// Workaround to get the absolute path of this executable file
// Used to build the absolute icon path when a relative path is given
int get_exec_path()
{
  char buf[2048]; int size = sizeof(buf);
  char linkname[64]; /* /proc/<pid>/exe */
  pid_t pid;
  int ret;

  /* Initialize empty path */
  strcpy(exec_path, "");

  /* Get our PID and build the name of the link in /proc */
  pid = getpid();

  /* Get proces link */
  if (snprintf(linkname, sizeof(linkname), "/proc/%i/exe", pid) < 0) return 0;

  /* Read the symbolic link */
  ret = readlink(linkname, buf, size);
  if (ret == -1) return 0;

  /* Ensure proper NULL termination */
  buf[ret] = 0;

  /* Get path */
  char *last_sl;
  if ((last_sl = strrchr(buf, '/')) != NULL) {
    buf[last_sl - buf] = 0;
  }
  if (strlen(buf) == 0) strcpy(buf, "/");
  
  strcpy(exec_path, buf);
}


/* initialize */
// The KDE Application object need at initialization the parameters passed by the operating system
// to the main(...) function, but since we are creating the object on the fly we'll need to fake
// them
int initialize()
{
  int argc = 1;
  //char *argv[1];  argv[0] = "SysTray_APP";

  KAboutData *about = new KAboutData("SysTray Application", "SysTray", "0.10");
  
  //debug("cmd args");
  //KCmdLineArgs::init(argc, argv, "SysTray Application", "SysTray", "SysTray Application", "0.10", false);
  KCmdLineArgs::init(about);

  kde_app = new KApplication();
  kde_wnd = new MainWindow();
  kde_app->setMainWidget(kde_wnd);
  
  get_exec_path();
}


/* create */
// Creates a new Sys Tray iecon. icon_path must hold the full qualified path to the icon image
// In a future release if the icon path is a relative path then the path will be built using
// the application path
int create(char *icon_path, char *tooltip)
{
  if (kde_tray != NULL) return 0;
  if (kde_app == NULL) initialize();

  QString ic(icon_path);

  kde_tray = new KTray(ic, tooltip);
  kde_tray->show();
  
  return 1;
}


/* destroy */
// Frees resources allocated for the KDE object
int destroy()
{
  if (kde_tray != NULL) {
    kde_tray->hide();
    delete kde_tray;
  }
}


/* do_events */
// Dispatches messages accumulated in the KDE application event loop
int do_events()
{
  if (kde_app != NULL) kde_app->processEvents(0);
    
  int ktev = 0; int kaev = 0;
  if (kde_tray != NULL) ktev = kde_tray->get_events();
  if (kde_wnd != NULL) kaev = kde_wnd->get_events();
  
  if (kaev) {  // MainWindow received close signal
    release();
  }
  
  return ktev | kaev;
}


int change_icon(char *icon_path)
{
  kde_tray->change_icon(icon_path);
}

int set_tooltip(char *tooltip)
{
  kde_tray->set_tooltip(tooltip);
}

int clear_tooltip()
{
  kde_tray->clear_tooltip();
}

int release()
{
  QTimer::singleShot( 0, kde_app, SLOT(quit()) );
  kde_app->exec();
  
  kde_tray = 0;
  kde_wnd = 0;
  kde_app = 0;
}
