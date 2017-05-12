/*
  SysTray application window
*/

#include "mainwnd.h"

MainWindow::MainWindow() : KMainWindow (0L, "SysTray Application Window")
{
  wnd_event = 0;
}

MainWindow::~MainWindow()
{
}

bool MainWindow::queryClose()
{
  wnd_event = MSG_LOGOFF | MSG_SHUTDOWN;
  return true;
}

bool MainWindow::queryExit()
{
  wnd_event = MSG_LOGOFF | MSG_SHUTDOWN;
  return true;
}

int MainWindow::get_events()
{
  int wev = wnd_event;
  wnd_event = 0;
  return wev;
}
