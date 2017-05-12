/*
  KDE wrapper
*/

#ifndef __KDE_WRAP_H
#define __kDE_WRAP_H

/*  Systray support  */
int create(char *icon_path, char *tooltip);
int destroy();
int do_events();
int change_icon(char *icon_path);
int set_tooltip(char *tooltip);
int clear_tooltip();
int release();

#endif
