#include <spvm_native.h>

#include <windows.h>
#include <d2d1.h>
#include <dwrite.h>
#include <assert.h>
#include <d3d11.h>
#include <d3dcompiler.h>
#include<memory>

#include <iostream>

#include "re2/re2.h"

#include "eg_css_box.h"

static const char* FILE_NAME = "Eg/OS/Windows/API/App.cpp";

extern "C" {

static wchar_t* to_wide_char(const char* str, size_t* len) {
  size_t size = MultiByteToWideChar(CP_UTF8, 0, str, -1, NULL, 0);

  wchar_t* wideStr = new wchar_t[size];

  MultiByteToWideChar(CP_UTF8, 0, str, -1, wideStr, size);

  *len = size;

  return wideStr;
}

static LRESULT CALLBACK window_procedure(HWND window_handle , UINT message , WPARAM wparam , LPARAM lparam);

static int32_t paint_event_handler(SPVM_ENV* env, SPVM_VALUE* stack, void* obj_self);

static void alert(SPVM_ENV* env, SPVM_VALUE* stack, const char* message);

struct Vertex {
  float pos[ 3 ];
  float col[ 4 ];
};

int32_t SPVM__Eg__OS__Windows__API__App__open_main_window_native(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  void* obj_self = stack[0].oval;
  
  int32_t window_left = stack[1].ival;
  
  int32_t window_top = stack[2].ival;
  
  int32_t window_width = stack[3].ival;
  
  int32_t window_height = stack[4].ival;
  
  int32_t error_id = 0;
  
  HINSTANCE instance_handle = GetModuleHandle(NULL);
  
  // Register Window Class
  WNDCLASS winc;
  winc.style = CS_HREDRAW | CS_VREDRAW;
  winc.lpfnWndProc = window_procedure;
  winc.cbClsExtra = winc.cbWndExtra = 0;
  winc.hInstance = instance_handle;
  winc.hIcon = LoadIcon(NULL , IDI_APPLICATION);
  winc.hCursor = LoadCursor(NULL , IDC_ARROW);
  winc.hbrBackground = (HBRUSH)GetStockObject(WHITE_BRUSH);
  winc.lpszMenuName = NULL;
  winc.lpszClassName = TEXT("Window");
  
  if (!RegisterClass(&winc)) {
    return env->die(env, stack, "RegisterClass() failed.", __func__, FILE_NAME, __LINE__);
  };
  
  // Create Main Window
  const int16_t* window_class_name = (const int16_t*)TEXT("Window");
  const int16_t* window_title = NULL;
  DWORD window_style = WS_OVERLAPPEDWINDOW | WS_VISIBLE;
  HWND window_parent_window_handle = NULL;
  HMENU window_id = NULL;
  void** wm_create_args = (void**)calloc(3, sizeof(void*));
  wm_create_args[0] = env;
  wm_create_args[1] = obj_self;
  wm_create_args[2] = stack;
  void* window_wm_create_lparam = (void*)wm_create_args;
  HWND window_handle = CreateWindow(
    (LPCWSTR)window_class_name, (LPCWSTR)window_title,
    window_style,
    window_left, window_top,
    window_width, window_height,
    window_parent_window_handle, window_id, instance_handle, window_wm_create_lparam
  );
  
  void* obj_window_handle = env->new_pointer_object_by_name(env, stack, "Eg::OS::Windows::HWND", window_handle, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_self;
  stack[1].oval = env->new_string_nolen(env, stack, "window_handle");
  stack[2].oval = obj_window_handle;
  env->call_instance_method_by_name(env, stack, "set_data", 3, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  // Renderer
  {
    RECT window_rect;
    GetWindowRect(window_handle, &window_rect);
    
    int window_width = window_rect.right - window_rect.left;
    int window_height = window_rect.bottom - window_rect.top;
    
    // Swap chain descriptor
    DXGI_SWAP_CHAIN_DESC sd;
    ZeroMemory( &sd, sizeof( sd ) );
    sd.BufferCount = 1;
    sd.BufferDesc.Width = window_width;
    sd.BufferDesc.Height = window_height;
    sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate.Numerator = 60;
    sd.BufferDesc.RefreshRate.Denominator = 1;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.OutputWindow = window_handle;
    sd.SampleDesc.Count = 1;
    sd.SampleDesc.Quality = 0;
    sd.Windowed = TRUE;
    
    D3D_FEATURE_LEVEL  FeatureLevelsRequested = D3D_FEATURE_LEVEL_11_0;
    UINT               numFeatureLevelsRequested = 1;
    D3D_FEATURE_LEVEL  FeatureLevelsSupported;
    
    // Create a device and a swap chane
    HRESULT hr;
    IDXGISwapChain* g_pSwapChain;
    ID3D11Device* g_pd3dDevice;
    ID3D11DeviceContext* g_pImmediateContext;
    if( FAILED (hr = D3D11CreateDeviceAndSwapChain( NULL, 
      D3D_DRIVER_TYPE_HARDWARE, 
      NULL, 
      0,
      &FeatureLevelsRequested, 
      numFeatureLevelsRequested, 
      D3D11_SDK_VERSION, 
      &sd, 
      &g_pSwapChain, 
      &g_pd3dDevice, 
      &FeatureLevelsSupported,
      &g_pImmediateContext )))
    {
      return hr;
    }
    
    // Vertex buffer
    ID3D11Buffer*      g_pVertexBuffer;
    
    // Supply the actual vertex data.
    Vertex g_VertexList[] = {
      { { -0.5f,  0.5f, 0.5f }, { 1.0f, 0.0f, 0.0f, 1.0f } },
      { {  0.5f, -0.5f, 0.5f }, { 0.0f, 1.0f, 0.0f, 1.0f } },
      { { -0.5f, -0.5f, 0.5f }, { 0.0f, 0.0f, 1.0f, 1.0f } },
      { {  0.5f,  0.5f, 0.5f }, { 1.0f, 1.0f, 0.0f, 1.0f } }
    };
    
    // Buffer description
    D3D11_BUFFER_DESC bufferDesc;
    bufferDesc.Usage            = D3D11_USAGE_DEFAULT;
    bufferDesc.ByteWidth        = (sizeof( float ) * 3) * 3;
    bufferDesc.BindFlags        = D3D11_BIND_VERTEX_BUFFER;
    bufferDesc.CPUAccessFlags   = 0;
    bufferDesc.MiscFlags        = 0;
    
    // Vertex data
    D3D11_SUBRESOURCE_DATA InitData;
    InitData.pSysMem = g_VertexList;
    InitData.SysMemPitch = 0;
    InitData.SysMemSlicePitch = 0;
    
    // Create vertex buffer
    hr = g_pd3dDevice->CreateBuffer( &bufferDesc, &InitData, &g_pVertexBuffer );
    
    if (FAILED(hr)) {
      return hr;
    }
    
    // Shape of vertex
    D3D11_INPUT_ELEMENT_DESC g_VertexDesc[] {
      { "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT,    0,                            0, D3D11_INPUT_PER_VERTEX_DATA, 0 },
      { "COLOR",    0, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, D3D11_APPEND_ALIGNED_ELEMENT, D3D11_INPUT_PER_VERTEX_DATA, 0 },
    };
  }
  
  return 0;
}

int32_t SPVM__Eg__OS__Windows__API__App__CW_USEDEFAULT(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  stack[0].ival = CW_USEDEFAULT;
  
  return 0;
}

int32_t SPVM__Eg__OS__Windows__API__App__start_event_loop(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  // Get and dispatch message
  MSG message;
  while (1) {
    if (PeekMessage(&message , NULL , 0 , 0, PM_NOREMOVE)) {
      if (GetMessage(&message , NULL , 0 , 0)) {
        TranslateMessage(&message);
        DispatchMessage(&message);
      }
      else {
        break;
      }
    }
  }
  
  return 0;
}

static LRESULT CALLBACK window_procedure(HWND window_handle , UINT message , WPARAM wparam , LPARAM lparam) {
  
  static SPVM_ENV* env;
  static SPVM_VALUE* stack;
  static void* obj_self;
  
  switch (message) {
    case WM_DESTROY: {
      PostQuitMessage(0);
      return 0;
    }
    case WM_CREATE: {
      CREATESTRUCT* create_struct = (CREATESTRUCT*)lparam;
      void** wm_create_args = (void**)create_struct->lpCreateParams;
      env = (SPVM_ENV*)wm_create_args[0];
      obj_self = (void*)wm_create_args[1];
      stack = (SPVM_VALUE*)wm_create_args[2];
      
      return 0;
    }
    case WM_PAINT: {
      int32_t error_id = 0;
      
      error_id = paint_event_handler(env, stack, obj_self);
      
      if (error_id) {
        alert(env, stack, env->get_chars(env, stack, env->get_exception(env, stack)));
        PostQuitMessage(0);
        return 0;
      }
      
      return 0;
    }
  }
  return DefWindowProc(window_handle , message , wparam , lparam);
}

static void alert(SPVM_ENV* env, SPVM_VALUE* stack, const char* message) {
  
  size_t message_wc_length = -1;
  const WCHAR* message_wc = to_wide_char(message, &message_wc_length);
  
  MessageBoxW(NULL, (LPCWSTR)message_wc, TEXT("Alert"), MB_OK);
  
  delete message_wc;
}

static int32_t paint_event_handler(SPVM_ENV* env, SPVM_VALUE* stack, void* obj_self) {
  int32_t error_id = 0;
  
  stack[0].oval = obj_self;
  stack[1].oval = env->new_string_nolen(env, stack, "window_handle");
  env->call_instance_method_by_name(env, stack, "get_data", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_window_handle = stack[0].oval;
  
  HWND window_handle = (HWND)env->get_pointer(env, stack, obj_window_handle);
  
  // Set window text
  {
    stack[0].oval = obj_self;
    env->call_instance_method_by_name(env, stack, "document_title", 1, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    void* obj_document_title = stack[0].oval;
    
    const char* document_title = env->get_chars(env, stack, obj_document_title);
    
    size_t document_title_wc_length = -1;
    const WCHAR* document_title_wc = to_wide_char(document_title, &document_title_wc_length);
    
    SetWindowTextW(window_handle, (LPCWSTR)document_title_wc);
    
    delete document_title_wc;
  }
  
  // Paint nodes
  {
    // Begin paint and get Device context
    PAINTSTRUCT ps;
    HDC hdc = BeginPaint(window_handle, &ps);
    
    // Result for COM. Direct 2D is COM.
    HRESULT hresult = E_FAIL;
    
    // Create Direct2D factory
    ID2D1Factory* renderer_factory = NULL;
    hresult = ::D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &renderer_factory);
    if (FAILED(hresult)) {
      fprintf(stderr, "Fail D2D1CreateFactory\n");
      return 1;
    }
    
    // Viewport rect
    RECT viewport_rect;
    GetClientRect(window_handle, &viewport_rect);
    
    // Viewport size
    D2D1_SIZE_U viewport_size = {(UINT32)(viewport_rect.right + 1), (UINT32)(viewport_rect.bottom + 1)};
    
    // Renderer
    ID2D1HwndRenderTarget* renderer = NULL;
    hresult = renderer_factory->CreateHwndRenderTarget(
      D2D1::RenderTargetProperties(),
      D2D1::HwndRenderTargetProperties(window_handle, viewport_size),
      &renderer
    );
    if (FAILED(hresult) ) {
      fprintf(stderr, "Fail CreateHwndRenderTarget\n");
      return 1;
    }
    
    void* obj_renderer = env->new_pointer_object_by_name(env, stack, "Eg::OS::Windows::ID2D1HwndRenderTarget", renderer, &error_id, __func__, FILE_NAME, __LINE__);
    
    stack[0].oval = obj_self;
    stack[1].oval = env->new_string_nolen(env, stack, "renderer");
    stack[2].oval = obj_renderer;
    env->call_instance_method_by_name(env, stack, "set_data", 3, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    // Start Draw
    renderer->BeginDraw();
    
    // Clear viewport
    D2D1_COLOR_F viewport_init_background_color = { 1.0f, 1.0f, 1.0f, 1.0f };
    renderer->Clear(viewport_init_background_color);
    
    {
      int32_t scope = env->enter_scope(env, stack);
      
      stack[0].oval = obj_self;
      stack[1].oval = NULL;
      env->call_instance_method_by_name(env, stack, "reflow", 2, &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      
      env->leave_scope(env, stack, scope);
    }
    
    {
      int32_t scope = env->enter_scope(env, stack);
      
      stack[0].oval = obj_self;
      stack[1].oval = NULL;
      env->call_instance_method_by_name(env, stack, "repaint", 2, &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      
      env->leave_scope(env, stack, scope);
    }
    
    // End draw
    renderer->EndDraw();
    
    stack[0].oval = obj_self;
    stack[1].oval = env->new_string_nolen(env, stack, "renderer");
    stack[2].oval = NULL;
    env->call_instance_method_by_name(env, stack, "set_data", 3, &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
    
    // End paint
    EndPaint(window_handle , &ps);
  }
  
  return 0;
}

int32_t SPVM__Eg__OS__Windows__API__App__text_metrics_height(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  void* obj_text_node = stack[1].oval;
  
  if (!obj_text_node) {
    return env->die(env, stack, "$text_node must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_box = env->get_field_object_by_name(env, stack, obj_text_node, "box", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  struct eg_css_box* box = (struct eg_css_box*)env->get_pointer(env, stack, obj_box);
  
  const char* text = box->text;
  
  int32_t width = box->width;
  int32_t font_size = box->font_size;
  
  DWRITE_FONT_WEIGHT font_weight_native = DWRITE_FONT_WEIGHT_NORMAL;
  DWRITE_FONT_STYLE font_style_native = DWRITE_FONT_STYLE_NORMAL;
  
  HRESULT hresult = E_FAIL;
  
  IDWriteFactory* direct_write_factory = NULL;
  hresult = DWriteCreateFactory( DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory), reinterpret_cast<IUnknown**>( &direct_write_factory ) );
  
  if (FAILED(hresult)) {
    return env->die(env, stack, "DWriteCreateFactory() failed.", __func__, FILE_NAME, __LINE__);
  }
  
  IDWriteTextFormat* text_format = NULL;
  direct_write_factory->CreateTextFormat(
    L"Meiryo",
    NULL,
    font_weight_native,
    font_style_native,
    DWRITE_FONT_STRETCH_NORMAL,
    font_size,
    L"",
    &text_format
  );
  
  size_t text_wc_length = -1;
  const WCHAR* text_wc = to_wide_char(text, &text_wc_length);
  
  IDWriteTextLayout* text_layout = NULL;
  hresult = direct_write_factory->CreateTextLayout(
    (const WCHAR*)text_wc,
    text_wc_length,
    text_format,
    width,
    0,
    &text_layout
  );
  
  delete text_wc;
  
  if (FAILED(hresult)) {
    return env->die(env, stack, "IDWriteFactory#CreateTextLayout() failed.", __func__, FILE_NAME, __LINE__);
  }
  
  // Get text metrics
  DWRITE_TEXT_METRICS text_metrics;
  text_layout->GetMetrics( &text_metrics );
  
  int32_t height = text_metrics.height;
  
  stack[0].ival = height;
  
  return 0;
}

int32_t SPVM__Eg__OS__Windows__API__App__paint_node(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  
  void* obj_node = stack[1].oval;
  
  if (!obj_node) {
    return env->die(env, stack, "$node must be defined.", __func__, FILE_NAME, __LINE__);
  }
  
  void* obj_box = env->get_field_object_by_name(env, stack, obj_node, "box", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  if (!obj_box) {
    return 0;
  }
  
  struct eg_css_box* box = (struct eg_css_box*)env->get_pointer(env, stack, obj_box);
  
  D2D1_RECT_F box_rect = D2D1::RectF(box->computed_left, box->computed_top, box->computed_left + box->computed_width + 1, box->computed_top + box->computed_height + 1);
  
  // Renderer
  stack[0].oval = obj_self;
  stack[1].oval = env->new_string_nolen(env, stack, "renderer");
  env->call_instance_method_by_name(env, stack, "get_data", 2, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_renderer = stack[0].oval;
  assert(obj_renderer);
  ID2D1HwndRenderTarget* renderer = (ID2D1HwndRenderTarget*)env->get_pointer(env, stack, obj_renderer);
  
  // Draw box
  if (!(box->background_color_alpha == 0)) {
    
    D2D1::ColorF background_color_f = {0};
    
    background_color_f = D2D1::ColorF(box->background_color_red, box->background_color_green, box->background_color_blue, box->background_color_alpha);
    
    
    ID2D1SolidColorBrush* background_brush = NULL;
    renderer->CreateSolidColorBrush(
      background_color_f,
      &background_brush
    );
    assert(background_brush);
    
    renderer->FillRectangle(&box_rect, background_brush);
    
    background_brush->Release();
  }
  
  // Draw text
  const char* text = box->text;
  if (text) {
    
    int32_t font_size = box->font_size;
    
    DWRITE_FONT_WEIGHT font_weight_native = DWRITE_FONT_WEIGHT_NORMAL;
    
    int32_t font_weight = box->font_weight_value_type;
    
    if (box->font_weight_value_type == EG_CSS_BOX_C_VALUE_TYPE_FONT_WEIGHT_BOLD) {
      font_weight_native = DWRITE_FONT_WEIGHT_BOLD;
    }
    
    DWRITE_FONT_STYLE font_style_native = DWRITE_FONT_STYLE_NORMAL;
    
    if (box->font_style_value_type == EG_CSS_BOX_C_VALUE_TYPE_FONT_STYLE_ITALIC) {
      font_style_native = DWRITE_FONT_STYLE_ITALIC;
    }
    
    D2D1::ColorF color_f = {0};
    color_f = D2D1::ColorF(box->color_red, box->color_green, box->color_blue, box->color_alpha);
    
    HRESULT hresult = E_FAIL;
    
    IDWriteFactory* direct_write_factory = NULL;
    hresult = DWriteCreateFactory( DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory), reinterpret_cast<IUnknown**>( &direct_write_factory ) );
    
    if (FAILED(hresult)) {
      return env->die(env, stack, "DWriteCreateFactory() failed.", __func__, FILE_NAME, __LINE__);
    }
    
    IDWriteTextFormat* text_format = NULL;
    direct_write_factory->CreateTextFormat(
      L"Meiryo",
      NULL,
      font_weight_native,
      font_style_native,
      DWRITE_FONT_STRETCH_NORMAL,
      font_size,
      L"",
      &text_format
    );
    
    size_t text_wc_length = -1;
    const WCHAR* text_wc = to_wide_char(text, &text_wc_length);
    
    IDWriteTextLayout* text_layout = NULL;
    hresult = direct_write_factory->CreateTextLayout(
          (const WCHAR*)text_wc
        , text_wc_length
        ,text_format
        , box->width
        , 0
        , &text_layout
    );
    
    delete text_wc;
    
    if (FAILED(hresult)) {
      return env->die(env, stack, "IDWriteFactory#CreateTextLayout() failed.", __func__, FILE_NAME, __LINE__);
    }
    
    ID2D1SolidColorBrush* text_brush = NULL;
    renderer->CreateSolidColorBrush(
      color_f,
      &text_brush
    );
    
    D2D1_POINT_2F point = {.x = (float)box_rect.left, .y = (float)box_rect.top};
    renderer->DrawTextLayout(point, text_layout, text_brush);
  }
  
  return 0;
}


}
