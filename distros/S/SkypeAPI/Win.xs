#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <windows.h>
#include <stdlib.h>    

HWND g_hWndSkype;       // window handle received in SkypeControlAPIAttach message
HWND g_hWndClient;      // our window handle
int g_nAvailable = 0;   // set by not-available msg from skype
bool is_quit = FALSE;

UINT SkypeControlAPIDiscover;
UINT SkypeControlAPIAttach;
enum {
SKYPECONTROLAPI_ATTACH_SUCCESS=0,
SKYPECONTROLAPI_ATTACH_PENDING_AUTHORIZATION,
SKYPECONTROLAPI_ATTACH_REFUSED,
SKYPECONTROLAPI_ATTACH_NOT_AVAILABLE,
SKYPECONTROLAPI_ATTACH_API_AVAILABLE= 0x8001,
};

static SV* callback_copydata;

void HandleSkypeMessage(HWND hWndSkype, COPYDATASTRUCT* cds)
{
    printf("[msg]%s\n", (char*)cds->lpData);   
    
    if (callback_copydata != NULL){ 
        dSP;
        ENTER;
        SAVETMPS;              
        
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv((char*)cds->lpData, 0)));
        //XPUSHs(sv_2mortal(newSViv(hWndSkype)));
        PUTBACK;
        call_sv(callback_copydata, G_DISCARD);
        FREETMPS;
        LEAVE;
    }
}


BOOL SkypeRegisterMessages()
{
    SkypeControlAPIDiscover =RegisterWindowMessage("SkypeControlAPIDiscover");
    if (SkypeControlAPIDiscover==0) {
         printf("[win]RegisterWindowMessage error\n");
        return FALSE;
    }
     printf("[win]SkypeControlAPIDiscover=%04x\n", SkypeControlAPIDiscover);

    SkypeControlAPIAttach   =RegisterWindowMessage("SkypeControlAPIAttach");
    if (SkypeControlAPIAttach==0) {
        printf("[win]RegisterWindowMessage error\n");
        return FALSE;
    }
        
    printf("[win]SkypeControlAPIAttach=%04x\n", SkypeControlAPIAttach);
    return TRUE;
}


// initiate connnection with skype.
BOOL  SkypeDiscover(HWND hWnd)
{
    LRESULT res;
    if (g_nAvailable == -1)
        return FALSE;
    g_hWndSkype= NULL;

    res= SendMessage(HWND_BROADCAST, SkypeControlAPIDiscover, (WPARAM)hWnd, 0);
    printf("[win]discover result=%08lx\n", res);
    return TRUE;
}

void HandleSkypeAttach(LPARAM lParam, WPARAM wParam)
{
    switch(lParam) {
    case SKYPECONTROLAPI_ATTACH_SUCCESS:
        g_hWndSkype= (HWND)wParam;
        printf("[win]success: skypewnd= %08lx\n", g_hWndSkype);
        g_nAvailable= 1;
        break;
    case SKYPECONTROLAPI_ATTACH_PENDING_AUTHORIZATION:
        printf("[win]pending authorization\n");
        break;
    case SKYPECONTROLAPI_ATTACH_REFUSED:
        printf("[win]attach refused\n");
        g_hWndSkype= NULL;
        g_nAvailable= -1;
        break;
    case SKYPECONTROLAPI_ATTACH_NOT_AVAILABLE:
        printf("[win]skype api not available\n");
        g_nAvailable= -1;
        break;
    case SKYPECONTROLAPI_ATTACH_API_AVAILABLE:
        printf("[win]skype api available\n");
        g_nAvailable= 1;
        SkypeDiscover(g_hWndClient);
        break;
    default:
         printf("[win]UNKNOWN SKYPEMSG %08lx: %08lx\n", lParam, wParam);
    }
}

LRESULT CALLBACK MySkypeWindowProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    if (uMsg==WM_CREATE) {
        if (!SkypeRegisterMessages()) {
            return -1;
        }
        
        if (!SkypeDiscover(hWnd)) {
            return -1;
        }    
        return 0;
    }
    else if (uMsg==WM_DESTROY) {
        return 0;
    }
    else if (uMsg==SkypeControlAPIAttach) {
        HandleSkypeAttach(lParam, wParam);        
        return 0;
    }
    else if (uMsg==SkypeControlAPIDiscover) {
        HWND hWndOther= (HWND)wParam;
        if (hWndOther!=hWnd)
            printf( "[win]detected other skype api client: %08lx\n", hWndOther);
        return 0;
    }
    else if (uMsg==WM_COPYDATA && (HWND)wParam == g_hWndSkype) {
        HandleSkypeMessage((HWND)wParam, (COPYDATASTRUCT*)lParam);
        return TRUE;
    }
    else {
        printf( "[win]wnd %08lx msg %08lx %08lx %08lx\n", hWnd, uMsg ,wParam, lParam);
        return DefWindowProc(hWnd, uMsg, wParam, lParam);
    }
}


HWND MakeWindow() {
	WNDCLASS wndcls;
    HWND hWnd;
    ATOM a;
    memset(&wndcls, 0, sizeof(WNDCLASS));   // start with NULL    
    
    wndcls.style         = 0;
	wndcls.lpfnWndProc = MySkypeWindowProc;
    wndcls.hInstance = GetModuleHandle(NULL);
	wndcls.lpszClassName = "perl skype window";
	a = RegisterClass(&wndcls);
    if (a==0) {
        printf("[win]register class failed\n");
        return 0;
    }
	hWnd= CreateWindowEx(WS_EX_CLIENTEDGE, wndcls.lpszClassName, "perl skype window", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 0, 0, (HWND)NULL, (HMENU)NULL, (HINSTANCE)GetModuleHandle(NULL), NULL);
	if (hWnd==NULL) {
        printf("[win]create windowfailed\n");
        return 0;
    }
    return hWnd;
}

void UnmakeWindow(HWND hWnd)
{
    if (!DestroyWindow(hWnd))
        printf("DestroyWindow\n");
    if (!UnregisterClass("perl skype window", NULL))
        printf("UnregisterClass\n");
}

// sends skype api message to skype 
bool SkypeSendMessage(char *msg)
{
    COPYDATASTRUCT cds;
    cds.dwData= 0;
    cds.lpData= msg;
    cds.cbData= strlen(msg)+1;
    if (!SendMessage(g_hWndSkype, WM_COPYDATA, (WPARAM)g_hWndClient, (LPARAM)&cds)) {
        printf("[send]skypesendmessage failed\n");
        SkypeDiscover(g_hWndClient);
        return FALSE;
    }
    return TRUE;
}


void attach_skype() {
    BOOL bRet;
    MSG msg;
    g_hWndClient= MakeWindow();
    
    do
    {
        if (PeekMessage (&msg, NULL, 0, 0, PM_REMOVE))
        {
            TranslateMessage (&msg) ;
            DispatchMessage (&msg) ;
        }
        if (is_quit)  {
            break;
         }
         Sleep(1000);
    } while (msg.message != WM_QUIT);    

    UnmakeWindow(g_hWndClient);
}
       
   

MODULE = SkypeAPI::Win		PACKAGE = SkypeAPI::Win		


void 
attach(SV* self, SV* option)    
    INIT:
    HV* hvoption;
    if (!SvROK(option) || SvTYPE(SvRV(option)) != SVt_PVHV) {           
        printf("[win]option must be a hashref\n");
        XSRETURN_UNDEF;
    }
    hvoption = (HV *)SvRV(option);
    CODE:     
        if (hv_exists(hvoption, "copy_data", 9)) {            
            SV** refval =  hv_fetch(hvoption,  "copy_data",9, NULL);
            if (refval != NULL) {
                callback_copydata = (SV*)SvRV((*refval));
            }
        }       
        attach_skype();  
    
    
int 
is_available(SV* self)
    CODE:
    RETVAL=g_nAvailable;
    OUTPUT:
    RETVAL
        
bool
send_message(SV*  self, char* msg)
    CODE:
    bool result = SkypeSendMessage(msg);
    RETVAL= result;
    OUTPUT:
    RETVAL

void 
quit(SV*  self)
    CODE:
    is_quit = TRUE;      
    printf("[api]some one call me quit\n");    
    SendMessage(g_hWndClient, WM_QUIT, 0, 0);