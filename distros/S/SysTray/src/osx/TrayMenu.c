#import "TrayMenu.h"

@implementation TrayMenu

- (void) setInitialIcon:(NSString *)s 
{
  [_path release];
  _path = [s retain];
}

- (void) setInitialTooltip:(NSString *)s
{
  [_tooltip release];
  _tooltip = [s retain];
}


- (void) changeIcon:(NSString *)s 
{
  [_path release];
  _path = [s retain];
  [_statusItem setImage:[[[NSImage alloc] initWithContentsOfFile: _path] retain]];
}

- (void)setToolTip: (NSString *)s
{
  [_tooltip release];
  _tooltip = [s retain];
  [_statusItem setToolTip:_tooltip];
}

- (void)removeIcon
{
  [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
  [_statusItem release];
}

- (void)createIcon
{
  [_statusItem release];
  _statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
  [_statusItem setHighlightMode:YES];
  [_statusItem setToolTip:_tooltip];
  [_statusItem setImage:[[[NSImage alloc] initWithContentsOfFile: _path] retain]];
  [_statusItem setAction:@selector(onClick:)];
  [_statusItem setEnabled:YES];
  _isClick = NO;
}

- (void) onClick:(id)sender 
{
  NSEvent *currentEvent = [NSApp currentEvent];
  int shiftKeyDown     = ([[NSApp currentEvent] modifierFlags] & (NSShiftKeyMask | NSAlphaShiftKeyMask)) != 0 ? 64 : 0;
  int commandKeyDown   = ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) != 0     ? 32  : 0;
  int controlKeyDown   = ([[NSApp currentEvent] modifierFlags] & NSControlKeyMask) != 0     ? 16  : 0;
  int functionKeyDown  = ([[NSApp currentEvent] modifierFlags] & NSFunctionKeyMask) != 0    ? 128 : 0;
  int leftClick        = ([[NSApp currentEvent] modifierFlags] & NSLeftMouseDownMask) != 0  ? 1   : 0;
  int rightClick       = ([[NSApp currentEvent] modifierFlags] & NSRightMouseDownMask) != 0 ? 2   : 0;
  int otherClick       = ([[NSApp currentEvent] modifierFlags] & NSOtherMouseDownMask) != 0 ? 4   : 0;

  switch ([currentEvent type]) {
    case NSLeftMouseDown:
        leftClick = 1;
        break;
    case NSRightMouseDown:
        rightClick = 2;
        break;
    case NSOtherMouseDown:
        otherClick = 4;
        break;
  }
  _isClick = shiftKeyDown | commandKeyDown | controlKeyDown | functionKeyDown | leftClick | rightClick | otherClick;
}

- (void) onDoubleClick:(id)sender 
{
  NSEvent *currentEvent = [NSApp currentEvent];
  int shiftKeyDown     = ([[NSApp currentEvent] modifierFlags] & (NSShiftKeyMask | NSAlphaShiftKeyMask)) != 0 ? 64 : 0;
  int commandKeyDown   = ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) != 0     ? 32  : 0;
  int controlKeyDown   = ([[NSApp currentEvent] modifierFlags] & NSControlKeyMask) != 0     ? 16  : 0;
  int functionKeyDown  = ([[NSApp currentEvent] modifierFlags] & NSFunctionKeyMask) != 0    ? 128 : 0;
  int leftClick        = ([[NSApp currentEvent] modifierFlags] & NSLeftMouseDownMask) != 0  ? 8   : 0;

  switch ([currentEvent type]) {
    case NSLeftMouseDown:
        leftClick = 8;
        break;
  }
  _isClick = shiftKeyDown | commandKeyDown | controlKeyDown | functionKeyDown | leftClick ;
}

- (int)isClicked 
{
  if(_isClick != 0) {
    return _isClick;
  }
  return 0;
}

- (void)invalidateClick 
{
  _isClick = 0;
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification {

  _statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
  [_statusItem setHighlightMode:YES];
  [_statusItem setToolTip:_tooltip];
  [_statusItem setImage:[[[NSImage alloc] initWithContentsOfFile: _path] retain]];
  [_statusItem sendActionOn:NSLeftMouseDownMask|NSRightMouseDownMask|NSOtherMouseDownMask];
  [_statusItem setAction:@selector(onClick:)];
  [_statusItem setDoubleAction:@selector(onDoubleClick:)];
  [_statusItem setEnabled:YES];
  _isClick = NO;
}

@end 