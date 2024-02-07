#include <spvm_native.h>

#include <assert.h>

#include<memory>
#include <iostream>

#include "re2/re2.h"

#include "eg_css_box.h"

static const char* FILE_NAME = "Eg/CSS/BoxBuilder.cpp";

extern "C" {

static int32_t parse_css_length_value (SPVM_ENV* env, SPVM_VALUE* stack, const char* style_value, int32_t style_value_length, int32_t* style_value_type, double* length) {
  
  int32_t success = 0;
  
  const char* css_length_pattern = "^(\\d+)(px)$";
  
  int32_t css_length_pattern_length = strlen(css_length_pattern);
  
  RE2::Options options;
  options.set_log_errors(false);
  re2::StringPiece stp_css_length_pattern(css_length_pattern, css_length_pattern_length);
  
  std::unique_ptr<RE2> re2(new RE2(stp_css_length_pattern, options));
  
  std::string error = re2->error();
  std::string error_arg = re2->error_arg();
  
  if (!re2->ok()) {
    return success;
  }
  
  int32_t captures_length = re2->NumberOfCapturingGroups();
  int32_t doller0_and_captures_length = captures_length + 1;
  
  int32_t offset = 0;
  
  std::vector<re2::StringPiece> submatch(doller0_and_captures_length);
  int32_t match = re2->Match(style_value, offset, offset + style_value_length, re2::RE2::Anchor::UNANCHORED, submatch.data(), doller0_and_captures_length);
  
  int32_t length_tmp = 0;
  
  if (match) {
    success = 1;
    
    *style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_VALUE;
    
    char* length_string = (char*)env->new_memory_block(env, stack, submatch[1].length() + 1);
    memcpy(length_string, submatch[1].data(), submatch[1].length());
    char* end;
    double length_tmp = strtod(length_string, &end);
    
    char* unit = (char*)env->new_memory_block(env, stack, submatch[2].length() + 1);
    memcpy(unit, submatch[2].data(), submatch[2].length());
    
    if (strcmp(unit, "px") == 0) {
      // Do nothing
    }
    
    env->free_memory_block(env, stack, length_string);
    env->free_memory_block(env, stack, unit);
    
    *length =length_tmp;
  }
  
  return success;
}

static int32_t parse_css_color_value (SPVM_ENV* env, SPVM_VALUE* stack, const char* style_value, int32_t style_value_length, int32_t* style_value_type, float* red, float* green, float* blue, float* alpha) {
  
  int32_t success = 0;
  
  const char* css_color_pattern = "^#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$";
  
  int32_t css_color_pattern_length = strlen(css_color_pattern);
  
  RE2::Options options;
  options.set_log_errors(false);
  re2::StringPiece stp_css_color_pattern(css_color_pattern, css_color_pattern_length);
  
  std::unique_ptr<RE2> re2(new RE2(stp_css_color_pattern, options));
  
  std::string error = re2->error();
  std::string error_arg = re2->error_arg();
  
  if (!re2->ok()) {
    abort();
  }
  
  int32_t captures_length = re2->NumberOfCapturingGroups();
  int32_t doller0_and_captures_length = captures_length + 1;
  
  int32_t offset = 0;
  
  std::vector<re2::StringPiece> submatch(doller0_and_captures_length);
  int32_t match = re2->Match(style_value, offset, offset + style_value_length, re2::RE2::Anchor::UNANCHORED, submatch.data(), doller0_and_captures_length);
  
  if (match) {
    
    success = 1;
    
    *style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_VALUE;
    
    char* red_string = (char*)env->new_memory_block(env, stack, submatch[1].length() + 1);
    memcpy(red_string, submatch[1].data(), submatch[1].length());
    char* red_end;
    *red = strtol(red_string, &red_end, 16);
    *red /= UINT8_MAX;
    env->free_memory_block(env, stack, red_string);
    
    char* green_string = (char*)env->new_memory_block(env, stack, submatch[2].length() + 1);
    memcpy(green_string, submatch[2].data(), submatch[2].length());
    char* green_end;
    *green = strtol(green_string, &green_end, 16);
    *green /= UINT8_MAX;
    env->free_memory_block(env, stack, green_string);
    
    char* blue_string = (char*)env->new_memory_block(env, stack, submatch[3].length() + 1);
    memcpy(blue_string, submatch[3].data(), submatch[3].length());
    char* blue_end;
    *blue = strtol(blue_string, &blue_end, 16);
    *blue /= UINT8_MAX;
    env->free_memory_block(env, stack, blue_string);
    
    *alpha = 1;
  }
  
  return success;
}

int32_t SPVM__Eg__CSS__BoxBuilder__build_box_styles(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  void* obj_node = stack[1].oval;
  
  void* obj_box = env->get_field_object_by_name(env, stack, obj_node, "box", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  assert(obj_box);
  
  struct eg_css_box* box = (struct eg_css_box*)env->get_pointer(env, stack, obj_box);
  
  assert(box);
  
  stack[0].oval = obj_node;
  env->call_instance_method_by_name(env, stack, "style", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_style = stack[0].oval;
  
  stack[0].oval = obj_style;
  env->call_instance_method_by_name(env, stack, "to_pairs", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_style_pairs = stack[0].oval;
  
  int32_t style_pairs_length = env->length(env, stack, obj_style_pairs);
  
  for (int32_t i = 0; i < style_pairs_length; i += 2) {
    void* obj_style_name = env->get_elem_object(env, stack, obj_style_pairs, i);
    void* obj_style_value = env->get_elem_object(env, stack, obj_style_pairs, i + 1);
    
    const char* style_name = env->get_chars(env, stack, obj_style_name);
    const char* style_value = env->get_chars(env, stack, obj_style_value);
    int32_t style_value_length = env->length(env, stack, obj_style_value);
    
    int32_t style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN;
    if (strcmp(style_value, "inherit") == 0) {
      style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    else if (strcmp(style_value, "initial") == 0) {
      style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INITIAL;
    }
    else if (strcmp(style_value, "revert") == 0) {
      style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_REVERT;
    }
    else if (strcmp(style_value, "unset") == 0) {
      style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNSET;
    }
    
    switch (style_name[0]) {
      case 'b' : {
        
        if (strcmp(style_name, "background-color") == 0) {
          
          if (!(style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN)) {
            box->background_color_value_type = style_value_type;
          }
          else {
            if (strcmp(style_value, "currentcolor") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_BACKGROUND_COLOR_CURRENTCOLOR;
            }
            else if (strcmp(style_value, "transparent") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_BACKGROUND_COLOR_TRANSPARENT;
            }
            else {
              int32_t style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN;
              float background_color_red;
              float background_color_green;
              float background_color_blue;
              float background_color_alpha;
              int32_t success = parse_css_color_value(env, stack, style_value, style_value_length, &style_value_type, &background_color_red, &background_color_green, &background_color_blue, &background_color_alpha);
              
              if (success) {
                box->background_color_value_type = style_value_type;
                
                box->background_color_red = background_color_red;
                box->background_color_green = background_color_green;
                box->background_color_blue = background_color_blue;
                box->background_color_alpha = background_color_alpha;
              }
            }
          }
        }
        else if (strcmp(style_name, "bottom") == 0) {
          if (!(style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN)) {
            box->bottom_value_type = style_value_type;
          }
          else {
            if (strcmp(style_value, "auto") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_BOTTOM_AUTO;
            }
            else {
              double bottom;
              int32_t style_value_type = 0;
              int32_t success = parse_css_length_value(env, stack, style_value, style_value_length, &style_value_type, &bottom);
              
              if (success) {
                box->bottom_value_type = style_value_type;
                box->bottom = (int32_t)bottom;
              }
            }
          }
        }
        
        break;
      }
      case 'c' : {
        
        if (strcmp(style_name, "color") == 0) {
          
          if (!(style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN)) {
            box->color_value_type = style_value_type;
          }
          else {
            if (strcmp(style_value, "currentcolor") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_COLOR_CURRENTCOLOR;
            }
            else {
              int32_t style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN;
              float color_red;
              float color_green;
              float color_blue;
              float color_alpha;
              
              int32_t success = parse_css_color_value(env, stack, style_value, style_value_length, &style_value_type, &color_red, &color_green, &color_blue, &color_alpha);
              
              if (success) {
                box->color_value_type = style_value_type;
                
                if (style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_VALUE) {
                  box->color_red = color_red;
                  box->color_green = color_green;
                  box->color_blue = color_blue;
                  box->color_alpha = color_alpha;
                }
              }
            }
          }
        }
        
        break;
      }
      case 'd' : {
        
        if (strcmp(style_name, "display") == 0) {
          if (!(style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN)) {
            box->display_value_type = style_value_type;
          }
          else {
            int32_t style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN;
            
            if (strcmp(style_value, "block") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_BLOCK;
            }
            else if (strcmp(style_value, "inline") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_INLINE;
            }
            else if (strcmp(style_value, "inline-block") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_INLINE_BLOCK;
            }
            else if (strcmp(style_value, "flex") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_FLEX;
            }
            else if (strcmp(style_value, "inline-flex") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_INLINE_FLEX;
            }
            else if (strcmp(style_value, "grid") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_GRID;
            }
            else if (strcmp(style_value, "flow-root") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_FLOW_ROOT;
            }
            else if (strcmp(style_value, "contents") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_CONTENTS;
            }
            else if (strcmp(style_value, "table") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_TABLE;
            }
            else if (strcmp(style_value, "table-row") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_TABLE_ROW;
            }
            else if (strcmp(style_value, "list-item") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_LIST_ITEM;
            }
            
            box->display_value_type = style_value_type;
          }
        }
        
        break;
      }
      case 'f' : {
        
        if (strcmp(style_name, "font-size") == 0) {
          if (!(style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN)) {
            box->font_size_value_type = style_value_type;
          }
          else {
            int32_t style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN;
            double font_size;
            
            int32_t success = parse_css_length_value(env, stack, style_value, style_value_length, &style_value_type, &font_size);
            
            if (success) {
              box->font_size_value_type = style_value_type;
              
              if (style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_VALUE) {
                box->font_size = (float)font_size;
              }
            }
          }
        }
        else if (strcmp(style_name, "font-weight") == 0) {
          if (!(style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN)) {
            box->font_weight_value_type = style_value_type;
          }
          else {
            int32_t style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN;
            
            if (strcmp(style_value, "normal") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_FONT_WEIGHT_NORMAL;
            }
            else if (strcmp(style_value, "bold") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_FONT_WEIGHT_BOLD;
            }
            
            box->font_weight_value_type = style_value_type;
          }
        }
        else if (strcmp(style_name, "font-style") == 0) {
          if (!(style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN)) {
            box->font_style_value_type = style_value_type;
          }
          else {
            int32_t style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN;
            
            if (strcmp(style_value, "normal") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_FONT_STYLE_NORMAL;
            }
            else if (strcmp(style_value, "italic") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_FONT_STYLE_ITALIC;
            }
            
            box->font_style_value_type = style_value_type;
          }
        }
        
        break;
      }
      case 'l' : {
        
        if (strcmp(style_name, "left") == 0) {
          if (!(style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN)) {
            box->left_value_type = style_value_type;
          }
          else {
            if (strcmp(style_value, "auto") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_LEFT_AUTO;
            }
            else {
              double left;
              int32_t style_value_type = 0;
              int32_t success = parse_css_length_value(env, stack, style_value, style_value_length, &style_value_type, &left);
              
              if (success) {
                box->left_value_type = style_value_type;
                box->left = (int32_t)left;
              }
            }
          }
        }
        
        break;
      }
      case 'p' : {
        
        if (strcmp(style_name, "position") == 0) {
          if (!(style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN)) {
            box->position_value_type = style_value_type;
          }
          else {
            int32_t style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN;
            
            if (strcmp(style_value, "static") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_POSITION_STATIC;
            }
            else if (strcmp(style_value, "relative") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_POSITION_RELATIVE;
            }
            else if (strcmp(style_value, "absolute") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_POSITION_ABSOLUTE;
            }
            else if (strcmp(style_value, "fixed") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_POSITION_FIXED;
            }
            else if (strcmp(style_value, "sticky") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_POSITION_STICKY;
            }
            
            box->position_value_type = style_value_type;
          }
        }
        
        break;
      }
      case 'r' : {
        
        if (strcmp(style_name, "right") == 0) {
          if (!(style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN)) {
            box->right_value_type = style_value_type;
          }
          else {
            if (strcmp(style_value, "auto") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_RIGHT_AUTO;
            }
            else {
              double right;
              int32_t style_value_type = 0;
              int32_t success = parse_css_length_value(env, stack, style_value, style_value_length, &style_value_type, &right);
              
              if (success) {
                box->right_value_type = style_value_type;
                box->right = (int32_t)right;
              }
            }
          }
        }
        
        break;
      }
      case 't' : {
        
        if (strcmp(style_name, "top") == 0) {
          if (!(style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN)) {
            box->top_value_type = style_value_type;
          }
          else {
            if (strcmp(style_value, "auto") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_TOP_AUTO;
            }
            else {
              double top;
              int32_t style_value_type = 0;
              int32_t success = parse_css_length_value(env, stack, style_value, style_value_length, &style_value_type, &top);
              
              if (success) {
                box->top_value_type = style_value_type;
                box->top = (int32_t)top;
              }
            }
          }
        }
        
        break;
      }
      case 'w' : {
        
        if (strcmp(style_name, "width") == 0) {
          if (!(style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN)) {
            box->width_value_type = style_value_type;
          }
          else {
            if (strcmp(style_value, "auto") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_WIDTH_AUTO;
            }
            else {
              double width;
              int32_t style_value_type = 0;
              int32_t success = parse_css_length_value(env, stack, style_value, style_value_length, &style_value_type, &width);
              
              if (success) {
                box->width_value_type = style_value_type;
                box->width = (int32_t)width;
              }
            }
          }
        }
        
        break;
      }
      case 'h' : {
        
        if (strcmp(style_name, "height") == 0) {
          if (!(style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN)) {
            box->height_value_type = style_value_type;
          }
          else {
            if (strcmp(style_value, "auto") == 0) {
              style_value_type = EG_CSS_BOX_C_VALUE_TYPE_HEIGHT_AUTO;
            }
            else {
              double height;
              int32_t style_value_type = 0;
              int32_t success = parse_css_length_value(env, stack, style_value, style_value_length, &style_value_type, &height);
              
              if (success) {
                box->height_value_type = style_value_type;
                box->height = (int32_t)height;
              }
            }
          }
        }
        
        break;
      }
    }
  }
  
  return 0;
}

int32_t SPVM__Eg__CSS__BoxBuilder__build_box_set_default_values(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  void* obj_node = stack[1].oval;
  
  void* obj_box = env->get_field_object_by_name(env, stack, obj_node, "box", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  assert(obj_box);
  
  struct eg_css_box* box = (struct eg_css_box*)env->get_pointer(env, stack, obj_box);
  
  assert(box);
  
  int32_t is_anon_box = 0;
  if (env->is_type_by_name(env, stack, obj_node, "Eg::Node::Text", 0)) {
    is_anon_box = 1;
  }
  
  // Initial value
  if (is_anon_box) {
    if (box->background_color_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->background_color_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
    if (box->color_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->color_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
    if (box->left_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->left_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
    if (box->top_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->top_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
    if (box->right_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->right_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
    if (box->bottom_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->bottom_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
    if (box->width_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->width_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
    if (box->height_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->height_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
    if (box->font_size_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->font_size_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
    if (box->font_weight_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->font_weight_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
    if (box->font_style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->font_style_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
    if (box->position_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->position_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
    if (box->display_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->display_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
  }
  else {
    if (box->background_color_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->background_color_value_type = EG_CSS_BOX_C_VALUE_TYPE_BACKGROUND_COLOR_TRANSPARENT;
    }
    
    if (box->color_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->color_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT;
    }
    
    if (box->left_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->left_value_type = EG_CSS_BOX_C_VALUE_TYPE_LEFT_AUTO;
    }
    
    if (box->top_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->top_value_type = EG_CSS_BOX_C_VALUE_TYPE_TOP_AUTO;
    }
    
    if (box->right_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->right_value_type = EG_CSS_BOX_C_VALUE_TYPE_RIGHT_AUTO;
    }
    
    if (box->bottom_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->bottom_value_type = EG_CSS_BOX_C_VALUE_TYPE_BOTTOM_AUTO;
    }
    
    if (box->width_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->width_value_type = EG_CSS_BOX_C_VALUE_TYPE_WIDTH_AUTO;
    }
    
    if (box->height_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->height_value_type = EG_CSS_BOX_C_VALUE_TYPE_HEIGHT_AUTO;
    }
    
    if (box->font_size_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->font_size_value_type = EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_VALUE;
      box->font_size = 16;
    }
    
    if (box->font_weight_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->font_weight_value_type = EG_CSS_BOX_C_VALUE_TYPE_FONT_WEIGHT_NORMAL;
    }
    
    if (box->font_style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->font_style_value_type = EG_CSS_BOX_C_VALUE_TYPE_FONT_STYLE_NORMAL;
    }
    
    if (box->position_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->position_value_type = EG_CSS_BOX_C_VALUE_TYPE_POSITION_STATIC;
    }
    
    if (box->display_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_UNKNOWN) {
      box->display_value_type = EG_CSS_BOX_C_VALUE_TYPE_DISPLAY_BLOCK;
    }
    
  }
  
  return 0;
}

int32_t SPVM__Eg__CSS__BoxBuilder__build_box_descendant(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  void* obj_node = stack[1].oval;
  
  void* obj_box = env->get_field_object_by_name(env, stack, obj_node, "box", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  struct eg_css_box* box = (struct eg_css_box*)env->get_pointer(env, stack, obj_box);
  
  void* obj_parent_node = env->get_field_object_by_name(env, stack, obj_node, "parent_node", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  void* obj_parent_box = env->get_field_object_by_name(env, stack, obj_parent_node, "box", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  int32_t is_root = 0;
  
  if (obj_parent_node) {
    is_root = env->is_type_by_name(env, stack, obj_parent_node, "Eg::Node::Document", 0);
  }
  
  // Not document node
  if (obj_parent_box) {
    
    if (error_id) { return error_id; }
    struct eg_css_box* parent_box = (struct eg_css_box*)env->get_pointer(env, stack, obj_parent_box);
    
    if (box->color_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT) {
      if (is_root) {
        box->color_red = 0;
        box->color_green = 0;
        box->color_blue = 0;
        box->color_alpha = 1;
      }
      else {
        box->color_red = parent_box->color_red;
        box->color_green = parent_box->color_green;
        box->color_blue = parent_box->color_blue;
        box->color_alpha = parent_box->color_alpha;
      }
    }
    
    if (box->background_color_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT) {
      if (is_root) {
        box->color_red = 1;
        box->color_green = 1;
        box->color_blue = 1;
        box->color_alpha = 1;
      }
      else {
        box->background_color_red = parent_box->background_color_red;
        box->background_color_green = parent_box->background_color_green;
        box->background_color_blue = parent_box->background_color_blue;
        box->background_color_alpha = parent_box->background_color_alpha;
      }
    }
    
    if (box->left_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT) {
      box->left = parent_box->left;
    }
    
    if (box->top_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT) {
      box->top = parent_box->top;
    }
    
    if (box->right_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT) {
      box->right = parent_box->right;
    }
    
    if (box->bottom_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT) {
      box->bottom = parent_box->bottom;
    }
    
    if (box->width_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT) {
      box->width = parent_box->width;
    }
    else if (box->width_value_type == EG_CSS_BOX_C_VALUE_TYPE_WIDTH_AUTO) {
      if (is_root) {
        stack[0].oval = obj_self;
        env->call_instance_method_by_name(env, stack, "inner_width", 0, &error_id, __func__, FILE_NAME, __LINE__);
        if (error_id) { return error_id; }
        int32_t inner_width = stack[0].ival;
        
        box->width = inner_width;
      }
      else {
        box->width = parent_box->width;
      }
    }
    
    if (box->height_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT) {
      box->height = parent_box->height;
    }
    
    if (box->font_size_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT) {
      box->font_size = parent_box->font_size;
    }
    
    if (box->font_weight_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT) {
      box->font_weight_value_type = parent_box->font_weight_value_type;
    }
    
    if (box->font_style_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT) {
      box->font_style_value_type = parent_box->font_style_value_type;
    }
    
    if (box->position_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT) {
      box->position_value_type = parent_box->position_value_type;
    }
    
    if (box->display_value_type == EG_CSS_BOX_C_VALUE_TYPE_GLOBAL_INHERIT) {
      box->display_value_type = parent_box->display_value_type;
    }
    
  }
  
  return 0;
}

int32_t SPVM__Eg__CSS__BoxBuilder__build_box_ascendant(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  void* obj_node = stack[1].oval;
  
  void* obj_box = env->get_field_object_by_name(env, stack, obj_node, "box", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  struct eg_css_box* box = (struct eg_css_box*)env->get_pointer(env, stack, obj_box);
  
  void* obj_parent_node = env->get_field_object_by_name(env, stack, obj_node, "parent_node", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  void* obj_parent_box = env->get_field_object_by_name(env, stack, obj_parent_node, "box", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  stack[0].oval = obj_node;
  env->call_instance_method_by_name(env, stack, "node_value", 1, &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  void* obj_text = stack[0].oval;
  
  const char* text = NULL;
  if (obj_text) {
    text = env->get_chars(env, stack, obj_text);
  }
  
  // Not document node
  if (obj_parent_box) {
    
    if (error_id) { return error_id; }
    struct eg_css_box* parent_box = (struct eg_css_box*)env->get_pointer(env, stack, obj_parent_box);
    
    if (text) {
      box->text = text;
      
      stack[0].oval = obj_self;
      stack[1].oval = obj_node;
      env->call_instance_method_by_name(env, stack, "text_metrics_height", 2, &error_id, __func__, FILE_NAME, __LINE__);
      if (error_id) { return error_id; }
      box->height = stack[0].ival;
    }
    
    if (parent_box->height_value_type == EG_CSS_BOX_C_VALUE_TYPE_HEIGHT_AUTO) {
      parent_box->height = box->height;
    }
  }
  
  return 0;
}

int32_t SPVM__Eg__CSS__BoxBuilder__build_box_descendant_compute_position(SPVM_ENV* env, SPVM_VALUE* stack) {
  
  int32_t error_id = 0;
  
  void* obj_self = stack[0].oval;
  void* obj_node = stack[1].oval;
  
  void* obj_box = env->get_field_object_by_name(env, stack, obj_node, "box", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  struct eg_css_box* box = (struct eg_css_box*)env->get_pointer(env, stack, obj_box);
  
  void* obj_parent_node = env->get_field_object_by_name(env, stack, obj_node, "parent_node", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  void* obj_parent_box = env->get_field_object_by_name(env, stack, obj_parent_node, "box", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  void* obj_previous_sibling_node = env->get_field_object_by_name(env, stack, obj_node, "previous_sibling", &error_id, __func__, FILE_NAME, __LINE__);
  if (error_id) { return error_id; }
  
  void* obj_previous_sibling_box = NULL;
  if (obj_previous_sibling_node) {
    obj_previous_sibling_box = env->get_field_object_by_name(env, stack, obj_previous_sibling_node, "box", &error_id, __func__, FILE_NAME, __LINE__);
    if (error_id) { return error_id; }
  }
  
  if (box->position_value_type == EG_CSS_BOX_C_VALUE_TYPE_POSITION_STATIC) {
    if (obj_previous_sibling_box) {
      struct eg_css_box* previous_sibling_box = (struct eg_css_box*)env->get_pointer(env, stack, obj_previous_sibling_box);
      
      box->computed_top = previous_sibling_box->computed_top + previous_sibling_box->computed_height;
      
      box->computed_left = previous_sibling_box->computed_left;
    }
    
    else {
      if (obj_parent_box) {
        struct eg_css_box* parent_box = (struct eg_css_box*)env->get_pointer(env, stack, obj_parent_box);
        
        box->computed_top = parent_box->computed_top;
        
        box->computed_left = parent_box->computed_left;
      }
    }
    
    box->computed_width = box->width;
    
    box->computed_height = box->height;
  }
  else if (box->position_value_type == EG_CSS_BOX_C_VALUE_TYPE_POSITION_FIXED) {
    
    box->computed_top = box->top;
    
    box->computed_left = box->left;
    
    box->computed_width = box->width;
    
    box->computed_height = box->height;
  }
  
  return 0;
}

}
