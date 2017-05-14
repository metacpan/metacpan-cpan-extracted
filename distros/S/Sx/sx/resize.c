#include <stdio.h>
#include "libsx.h"


void cb1(w, junk)
Widget w;
void *junk;
{
  printf("Inside callback #1\n");
}

void cb2(w, junk)
Widget w;
void *junk;
{
  printf("Inside callback #2\n");
}

void cb3(w, junk)
Widget w;
void *junk;
{
  printf("Inside callback #3\n");
}

void quit(w, junk)
Widget w;
void *junk;
{
  exit(0);
}

main()
{
  Widget w1, w2, w3, w4;

  w1 = MakeButton("Button 1", cb1,  NULL);
  w2 = MakeButton("Button 2", cb2,  NULL);
  w3 = MakeButton("Button 3", cb3,  NULL);
  w4 = MakeButton("Quit",     quit, NULL);

  SetWidgetPos(w2, PLACE_RIGHT,  w1,   NO_CARE,     NULL);
  SetWidgetPos(w3, PLACE_RIGHT,  w2,   NO_CARE,     NULL);
  SetWidgetPos(w4, PLACE_RIGHT,  w3,   NO_CARE,     NULL);

  MainLoop();
}
