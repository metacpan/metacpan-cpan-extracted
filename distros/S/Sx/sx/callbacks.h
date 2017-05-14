/* This file contains prototypes for the functions in callbacks.c.  It is
 * included by main.c so that when you create a new widget, you can tie
 * its callback function to something that has been defined (otherwise the
 * compiler will give you and error.
 *
 * If you add any functions to callbacks.c, you should put a corresponding 
 * function prototype in here.
 */


/* callback protos */
void quit(Widget w, void *data);
void load(Widget w, void *data);
void save(Widget w, void *data);
void list_callback(Widget w, char *str, int index, void *arg);
void threelist_callback(Widget w, char *str, int index, unsigned int event, void *arg);
void string_func(Widget w, char *txt, void *arg);
void scroll_func(Widget w, float val, void *arg);
void color(Widget w, void *data);
void do_stuff(Widget w, void *data);
void more_stuff(Widget w, void *data);
void check_me(Widget w, void *data);

void toggle1(Widget w, void *data);
void toggle2(Widget w, void *data);
void toggle3(Widget w, void *data);
void toggle4(Widget w, void *data);

void other_toggle(Widget w, void *data);

void menu_item1(Widget w, void *data);
void menu_item2(Widget w, void *data);
void menu_item3(Widget w, void *data);
void menu_item4(Widget w, void *data);


void redisplay(Widget w, int new_width, int new_height, void *data);
void button_down(Widget w, int which_button, int x, int y, void *data);
void button_up(Widget w, int which_button, int x, int y, void *data);
void keypress(Widget w, char *input, int up_or_down, void *data);
void motion(Widget w, int x, int y, void *data);
