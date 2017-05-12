/* KDE SysTray handling */

#include <cstdlib>

#include <kapplication.h>
#include <kiconloader.h>
#include <klocale.h>
#include <kpopupmenu.h>
#include <kconfig.h>
#include <kdebug.h>
#include <qtooltip.h>
#include <qtimer.h>

#include "tray.h"
//#include "config.h"

// systray menu actions
#define CONTEXT_EXIT 100

// double click time
#define DOUBLE_CLICK_TIME 300

KTray::KTray(QString systray_icon, QString tooltip = "")
  : KSystemTray()
{
  // initialise the menu
  //mMenu = contextMenu();
  
  // connect signals - inherited from QPopupMenu
  //connect(mMenu, SIGNAL(activated(int)), SLOT(slotContextMenuActivated(int)));
  //connect(mMenu, SIGNAL(aboutToShow()), SLOT(slotContextMenuAboutToShow()));
  
  // load icon (if specified)
  //debug("Loading systray icon from %s", (const char *) systray_icon);
  this->setPixmap(this->loadIcon(systray_icon));
  
  // set tooltip if available
  //debug("Setting tooltip %s", (const char *) tooltip);
  if (!tooltip.isEmpty()) QToolTip::add(this, tooltip);
  //QToolTip::add(this, i18n("aaaa"));
  
  tray_event = 0;
}

KTray::~KTray()
{
  QToolTip::remove(this);
}

/*
  Menu functions
*/

void KTray::slotContextMenuAboutToShow()
{
  mMenu->clear();
  mMenu->insertItem(i18n("&Exit..."), CONTEXT_EXIT);
}

void KTray::slotContextMenuActivated(int n)
{
  switch(n) {
    case CONTEXT_EXIT:
      emit quitSelected();
      kapp->quit();
      break;
  }
}

void KTray::mousePressEvent(QMouseEvent *ev)
{
  if (ev->button() == QMouseEvent::LeftButton)
    tray_event |= MB_LEFT_CLICK;
    
  if (ev->button() == QMouseEvent::RightButton)
    tray_event |= MB_RIGHT_CLICK;

  if (ev->button() == QMouseEvent::MidButton)
    tray_event |= MB_MIDDLE_CLICK;

  if (ev->state() & QMouseEvent::ShiftButton)
    tray_event |= KEY_SHIFT;
    
  if (ev->state() & QMouseEvent::ControlButton)
    tray_event |= KEY_CONTROL;
    
  if (ev->state() & QMouseEvent::AltButton)
    tray_event |= KEY_ALT;
  
  if (ev->state() & QEvent::MouseButtonDblClick)
    tray_event |= MB_DOUBLE_CLICK;
}

void KTray::mouseDoubleClickEvent(QMouseEvent *ev)
{
  mousePressEvent(ev);
  tray_event |= MB_DOUBLE_CLICK;
}


int KTray::get_events()
{
  int tev = tray_event;
  tray_event = 0;
  return tev;
}

/*
  Tray icon - related functions
*/

int KTray::change_icon(char *icon_path)
{
  setPixmap(KSystemTray::loadIcon(icon_path));
}

int KTray::set_tooltip(char *tooltip)
{
  QToolTip::remove(this);
  QToolTip::add(this, tooltip);
}

int KTray::clear_tooltip()
{
  QToolTip::remove(this);
}
