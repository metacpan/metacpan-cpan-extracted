/* KDE SysTray handling */

#ifndef __TRAY_H
#define __TRAY_H

#include <ksystemtray.h>
#include <kiconeffect.h>
#include <qpixmap.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qmap.h>

/* Events to be reported in the Perl callback */
#define MB_LEFT_CLICK     1
#define MB_RIGHT_CLICK    2
#define MB_MIDDLE_CLICK   4
#define MB_DOUBLE_CLICK   8

#define KEY_CONTROL       16
#define KEY_ALT           32
#define KEY_SHIFT         64

class QMouseEvent;

class KTray : public KSystemTray
{
  Q_OBJECT
public:
  // constructor
  KTray(QString systray_icon, QString tooltip);
  // destructor
  virtual ~KTray();

  int get_events();
  int change_icon(char *icon_path);
  int set_tooltip(char *tooltip);
  int clear_tooltip();

protected:
  // systray icon - left click
  void mousePressEvent(QMouseEvent *);
  void mouseDoubleClickEvent(QMouseEvent *);
  
protected slots:
  // KPopupMenu signals
  void slotContextMenuActivated(int);
  void slotContextMenuAboutToShow();

private:
  KPopupMenu	*mMenu;
  int tray_event;
};

#endif
