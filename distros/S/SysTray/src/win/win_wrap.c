// win_wrap.cpp : Defines the entry point for the application.
//

#include "win_wrap.h"
#include "windows.h"
#include "shellapi.h"
#include "tchar.h"

NOTIFYICONDATA  nid;
HWND            myDialog;
int             clicked          = 0;
int             not_initialized  = 1;
int             has_icon         = 0;

#define WM_NOTIFYICON (WM_APP+2)

//procedure for our main window
LRESULT WINAPI myProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) 
{
	int shiftKeyDown     = GetAsyncKeyState(VK_SHIFT)   ? 64 : 0;
  int altKeyDown       = GetAsyncKeyState(VK_MENU)    ? 32  : 0;
  int controlKeyDown   = GetAsyncKeyState(VK_CONTROL) ? 16  : 0;
  int functionKeyDown  = GetAsyncKeyState(VK_LWIN) || GetAsyncKeyState(VK_RWIN) ? 128 : 0;
	
	clicked = shiftKeyDown | altKeyDown | controlKeyDown | functionKeyDown;
	
  switch(message) {
    case WM_CLOSE:
      DestroyWindow(myDialog);
      break;
    case WM_DESTROY:
      nid.uFlags = 0;
      Shell_NotifyIcon(NIM_DELETE,&nid);
      PostQuitMessage(0);
      break;
    case WM_NOTIFYICON:
      switch(lParam) {
        case WM_LBUTTONDOWN:
          clicked |= 1;
          break;
        case WM_RBUTTONDOWN:
          clicked |= 2;
          break;
        case WM_MBUTTONDOWN:
          clicked |= 4;
          break;
        case WM_LBUTTONDBLCLK:
        case WM_RBUTTONDBLCLK:
        case WM_MBUTTONDBLCLK:
        	clicked |= 8;
        	break;
        default:
                clicked = 0;
      }
      break;
    case WM_ENDSESSION:
    	switch(lParam) {
    		case ENDSESSION_LOGOFF: // logoff
    			clicked |= 256;
    			break;
    		default: // shut down
    			clicked |= 512;
    			break;
    	}
    	break;
    default: 
    	return DefWindowProc(hwnd, message, wParam, lParam);
  }

  return 0;
}

int initialize() {
  //create the main window
  myDialog = CreateWindowEx(
    0,WC_DIALOG,"My Window",WS_OVERLAPPEDWINDOW,
    400,100,200,200,NULL,NULL,NULL,NULL
  );
  
  //now set the procedure 
  SetWindowLong(
    myDialog,   // handle of the window we are attaching procedure to
    DWL_DLGPROC,  // dialog window specific attribute - the dialog procedure
    (long) myProc // name of procedure
  );
  return 0;
}

int create(char *icon_path, char *tooltip) {
  if(not_initialized) {
    initialize();
  } else {
    return 0;
  } 

  ZeroMemory(&nid, sizeof(NOTIFYICONDATA));
  nid.cbSize = sizeof(NOTIFYICONDATA);
  nid.hWnd = myDialog;
  nid.uCallbackMessage = WM_NOTIFYICON;
  nid.uID = 1;
  nid.hIcon = (HICON) LoadImage( NULL, icon_path, IMAGE_ICON, 0, 0, LR_LOADFROMFILE );
  strcpy(nid.szTip, tooltip);
  
  // state which structure members are valid
  nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;

  Shell_NotifyIcon(NIM_ADD, &nid);
  
  has_icon = 1;
  
  return 0;
}

int destroy() {
  nid.uFlags = 0;
  Shell_NotifyIcon(NIM_DELETE,&nid);
  return 0;
}

int change_icon(char *icon_path) {
  nid.hIcon = (HICON) LoadImage( NULL, icon_path, IMAGE_ICON, 0, 0, LR_LOADFROMFILE );
  Shell_NotifyIcon(NIM_MODIFY, &nid);
  return 0;
}

int set_tooltip(char *tooltip) {
  strcpy(nid.szTip, tooltip);
  Shell_NotifyIcon(NIM_MODIFY, &nid);
  return 0;
}

int clear_tooltip() {
  strcpy(nid.szTip, _T(""));
  Shell_NotifyIcon(NIM_MODIFY, &nid);
  return 0;
}

int do_events() {
  MSG msg;
  int ret;
  if(PeekMessage(&msg, myDialog, 0, 0, PM_REMOVE)) {  
    DispatchMessage(&msg);
  }

  if (clicked != 0) {
    ret = clicked;
    clicked = 0;
    return ret;
  }

  return 0;
}

int release()
{
  destroy();
}
