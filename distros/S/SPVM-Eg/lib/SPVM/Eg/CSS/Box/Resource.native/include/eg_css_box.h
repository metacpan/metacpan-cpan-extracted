#include <spvm_native.h>

enum {
  HIGHT_AUTO = 1,
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN,
  EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_VALUE,
  EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT,
  EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INITIAL,
  EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_REVERT,
  EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_REVERT_LAYER,
  EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNSET,
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_BOX_SIZING_CONTENT_BOX = 16,
  EG_CSS_BOX_C_VALUE_TYPE_BOX_SIZING_BORDER_BOX
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_BACKGROUND_COLOR_CURRENTCOLOR = 16,
  EG_CSS_BOX_C_VALUE_TYPE_BACKGROUND_COLOR_TRANSPARENT,
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_COLOR_CURRENTCOLOR = 16,
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_LEFT_AUTO = 16,
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_TOP_AUTO = 16,
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_RIGHT_AUTO = 16,
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_BOTTOM_AUTO = 16,
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_WIDTH_AUTO = 16,
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_HEIGHT_AUTO = 16,
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_FONT_WEIGHT_NORMAL = 16,
  EG_CSS_BOX_C_VALUE_TYPE_FONT_WEIGHT_BOLD = 16,
};

struct eg_css_box {
  struct eg_css_box* first_child;
  struct eg_css_box* last_child;
  struct eg_css_box* next_sibling;
  struct eg_css_box* parent_node;
  const char* text;
  int32_t left;
  int32_t top;
  int32_t width;
  int32_t height;
  float color_red;
  float color_green;
  float color_blue;
  float color_alpha;
  float background_color_red;
  float background_color_green;
  float background_color_blue;
  float background_color_alpha;
  float font_size;
  int8_t box_sizing;
  int8_t is_anon_box;
  int8_t left_value_type;
  int8_t top_value_type;
  int8_t width_value_type;
  int8_t height_value_type;
  int8_t color_value_type;
  int8_t background_color_value_type;
  int8_t font_size_value_type;
  int8_t font_weight_value_type;
};
