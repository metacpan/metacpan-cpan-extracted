
#ifndef __MAINWINDOW_H
#define __MAINWINDOW_H

#include <kmainwindow.h>

/* Events to be reported in the Perl callback */
#define MSG_LOGOFF     256
#define MSG_SHUTDOWN   512

class MainWindow : public KMainWindow
{
  Q_OBJECT

public:
  MainWindow();
  ~MainWindow();
  int get_events();

protected slots:
  bool queryClose();
  bool queryExit();

private:
  int wnd_event;
};

#endif
