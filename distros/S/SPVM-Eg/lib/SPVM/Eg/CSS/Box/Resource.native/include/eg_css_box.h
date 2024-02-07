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
  EG_CSS_BOX_C_VALUE_TYPE_FONT_WEIGHT_BOLD,
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_FONT_STYLE_NORMAL = 16,
  EG_CSS_BOX_C_VALUE_TYPE_FONT_STYLE_ITALIC,
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_POSITION_STATIC = 16,
  EG_CSS_BOX_C_VALUE_TYPE_POSITION_RELATIVE,
  EG_CSS_BOX_C_VALUE_TYPE_POSITION_ABSOLUTE,
  EG_CSS_BOX_C_VALUE_TYPE_POSITION_FIXED,
  EG_CSS_BOX_C_VALUE_TYPE_POSITION_STICKY,
};

enum {
  EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_BLOCK = 16,
  EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_INLINE,
  EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_INLINE_BLOCK,
  EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_FLEX,
  EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_INLINE_FLEX,
  EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_GRID,
  EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_INLINE_GRID,
  EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_FLOW_ROOT,
  EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_NONE,
  EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_CONTENTS,
  EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_TABLE,
  EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_TABLE_ROW,
  EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_LIST_ITEM,
};

struct eg_css_box {
  struct eg_css_box* first_child;
  struct eg_css_box* last_child;
  struct eg_css_box* next_sibling;
  struct eg_css_box* parent_node;
  const char* text;
  int32_t left;
  int32_t top;
  int32_t right;
  int32_t bottom;
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
  int8_t right_value_type;
  int8_t bottom_value_type;
  int8_t width_value_type;
  int8_t height_value_type;
  int8_t color_value_type;
  int8_t background_color_value_type;
  int8_t font_size_value_type;
  int8_t font_weight_value_type;
  int8_t font_style_value_type;
  int8_t position_value_type;
  int8_t display_value_type;
  int32_t computed_left;
  int32_t computed_top;
  int32_t computed_width;
  int32_t computed_height;
};
