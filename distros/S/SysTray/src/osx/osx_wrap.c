#import <Cocoa/Cocoa.h>
#import "TrayMenu.h"

TrayMenu          *menu;
NSAutoreleasePool *pool;

int               pool_live        = 0;
int               finish_launching = 0;
int               not_initialized  = 1;
int               has_icon         = 1;

/* initialize */
int initialize()
{
  pool_live        = 0;
  finish_launching = 0;
  not_initialized  = 0;
  pool = [[NSAutoreleasePool alloc] init];
  [NSApplication sharedApplication];
  menu = [[TrayMenu alloc] init];
  [NSApp setDelegate:menu];
}


/* create */
int create(char *icon_path, char *tooltip) 
{
  if(not_initialized) {
    initialize();
  } else {
    return 0;
  } 
  
  // we're using setPath because at this stage our NSStatusItem is not created yet
  [menu setInitialIcon:[[NSString alloc] initWithCString:icon_path]]; 
  [menu setToolTip:[[NSString alloc] initWithCString:tooltip]];
}

/* destroy */
int destroy()
{
  [menu removeIcon];
  has_icon = 0;
}


/* change status bar icon after have been created */
int change_icon(char *icon_path)
{
 if(!finish_launching || not_initialized) {
   return 0;
 }
 [menu changeIcon:[[NSString alloc] initWithCString:icon_path]];
}

/* set tooltip */
int set_tooltip(char *tooltip)
{
  if(!finish_launching || not_initialized) {
    return 0;
  }
  [menu setToolTip:[[NSString alloc] initWithCString:tooltip]];
}


/* clear any text in tool tip */
int clear_tooltip()
{
  if(!finish_launching || not_initialized) {
    return 0;
  }
  [menu setToolTip:@""];  
}

/* interate just once through the event loop */
int do_events()
{
   NSEvent		*event;
   int                  click;

   click = 0;
   pool_live += 1;

   if(!finish_launching) {
     [NSApp finishLaunching];
     finish_launching = 1;
   }

   event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate distantPast] inMode:NSDefaultRunLoopMode dequeue:YES];
   if (event) {
      [NSApp sendEvent:event];
   }

   if(pool_live > 10) { // re-initiate the memory pool
     [pool release];
     pool = [[NSAutoreleasePool alloc] init];
   }

   if([menu isClicked]) {
     click = [menu isClicked];
     [menu invalidateClick];
   }

   return click;
}

/* exec */
int exec()
{
/*
  if(pool == nil) {
    pool = [[NSAutoreleasePool alloc] init];
  }
  [NSApp run];
  [pool release];
*/
}

int release()
{
}
