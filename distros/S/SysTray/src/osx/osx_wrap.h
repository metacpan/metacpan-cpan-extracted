/*
  Mac wrapper
*/

#ifndef __MAC_WRAP_H
#define __MAC_WRAP_H

int initialize();
int create(char *icon_path, char *tooltip);
int change_icon(char *icon_path);
int set_tooltip(char *tooltip);
int clear_tooltip();
int destroy();
int do_events();
int release();

#endif