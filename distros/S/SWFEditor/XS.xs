#include "png.h" // must be included before setjmp.h

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "src/bitmap_util.c"
#include "src/bitstream.c"
#include "src/jpeg_segment.c"
#include "src/swf_action.c"
#include "src/swf_argb.c"
#include "src/swf_button_condaction.c"
#include "src/swf_button_record.c"
#include "src/swf_cxform.c"
#include "src/swf_cxformwithalpha.c"
#include "src/swf_fill_style.c"
#include "src/swf_fill_style_array.c"
#include "src/swf_fill_style_bitmap.c"
#include "src/swf_fill_style_gradient.c"
#include "src/swf_fill_style_solid.c"
#include "src/swf_gif.c"
#include "src/swf_gradient.c"
#include "src/swf_gradient_record.c"
#include "src/swf_header.c"
#include "src/swf_jpeg.c"
#include "src/swf_line_style.c"
#include "src/swf_line_style_array.c"
#include "src/swf_matrix.c"
#include "src/swf_morph_shape_with_style.c"
#include "src/swf_object.c"
#include "src/swf_png.c"
#include "src/swf_rect.c"
#include "src/swf_rgb.c"
#include "src/swf_rgba.c"
#include "src/swf_shape_record.c"
#include "src/swf_shape_record_edge.c"
#include "src/swf_shape_record_end.c"
#include "src/swf_shape_record_setup.c"
#include "src/swf_shape_with_style.c"
#include "src/swf_styles.c"
#include "src/swf_styles_count.c"
#include "src/swf_tag.c"
#include "src/swf_tag_action.c"
#include "src/swf_tag_button.c"
#include "src/swf_tag_edit.c"
#include "src/swf_tag_jpeg.c"
#include "src/swf_tag_lossless.c"
#include "src/swf_tag_place.c"
#include "src/swf_tag_shape.c"
#include "src/swf_tag_sound.c"
#include "src/swf_tag_sprite.c"
#include "src/swf_xrgb.c"
#include "src/trans_table.c"
#include "src/y_keyvalue.c"

MODULE = SWFEditor		PACKAGE = SWFEditor		

void
_swf_object_open(sv)
        SV *sv;
    PREINIT:
        swf_object_t *swf;
    CODE:
        swf = swf_object_open();
        sv_magic(SvRV(sv), NULL, PERL_MAGIC_ext, NULL, 0);
        mg_find(SvRV(sv), PERL_MAGIC_ext)->mg_obj = (void *) swf;

void
_swf_object_close(swf)
        swf_object_t *swf;
    CODE:
        if (swf) {
            swf_object_close(swf);
        }

int
_input(swf, data, data_len)
        swf_object_t *swf;
        unsigned char *data;
        unsigned long data_len;
    CODE:
        RETVAL = swf_object_input(swf, data, data_len);
    OUTPUT:
        RETVAL

SV *
output(swf)
        swf_object_t *swf;
    CODE:
        // new_buff ???
        //unsigned long len       = 0;
        //unsigned char *data     = NULL;
        //char          *new_buff = NULL;
        //data = swf_object_output(swf, &len);
        //Newx(new_buff, len, char);
        //memcpy(new_buff, data, len);
        //Safefree(data);
        //RETVAL = newSVpv(new_buff, len);
        
        unsigned long len       = 0;
        unsigned char *data     = NULL;
        data = swf_object_output(swf, &len);
        RETVAL = newSVpv(data, len);
    OUTPUT:
        RETVAL

int
swf_info(swf)
        swf_object_t *swf;
    CODE:
        swf_object_print(swf);
        fflush(stdout);
        RETVAL = 1;
    OUTPUT:
        RETVAL

int
set_action_variables(swf, hash_ref)
        swf_object_t *swf;
        SV           *hash_ref;
    CODE:
        HV      *hv;
        char    *hkey;
        I32     hkeylen = 0;
        SV      *value;
        
        if (!SvROK(hash_ref)) {
            croak("ref(hashref) expected");
        }
        hv = (HV *) SvRV(hash_ref);
        if (SvTYPE(hv) != SVt_PVHV) {
            croak("hashref expected");
        }
        hv_iterinit(hv);
        
        y_keyvalue_t *kv;
        kv = y_keyvalue_open();
        while ((value = hv_iternextsv(hv, &hkey, &hkeylen)) != NULL) {
            char *k   = (char *)hkey;
            int  klen = (int)hkeylen;
            STRLEN len;
            char *v   = SvPV(value, len);
            int  vlen = (int)len;
            y_keyvalue_set(kv, k, klen, v, vlen);
        }
        RETVAL = swf_object_insert_action_setvariables(swf, kv);
        y_keyvalue_close(kv);
    OUTPUT:
        RETVAL

int
replace_action_strings(swf, hash_ref)
        swf_object_t *swf;
        SV           *hash_ref;
    CODE:
        HV      *hv;
        char    *hkey;
        I32     hkeylen = 0;
        SV      *value;
        
        if (!SvROK(hash_ref)) {
            croak("ref(hashref) expected");
        }
        hv = (HV *) SvRV(hash_ref);
        if (SvTYPE(hv) != SVt_PVHV) {
            croak("hashref expented");
        }
        hv_iterinit(hv);
        
        y_keyvalue_t *kv;
        kv = y_keyvalue_open();
        while ((value = hv_iternextsv(hv, &hkey, &hkeylen)) != NULL) {
            char *k   = (char *)hkey;
            int  klen = (int)hkeylen;
            STRLEN len;
            char *v   = SvPV(value, len);
            int  vlen = (int)len;
            y_keyvalue_set(kv, k, klen, v, vlen);
        }
        RETVAL = swf_object_replace_action_strings(swf, kv);
        y_keyvalue_close(kv);
    OUTPUT:
        RETVAL

int
_replace_movie_clip(swf, instance_name, swf_data, swf_data_len, unused_cid_purge)
        swf_object_t *swf;
        char         *instance_name;
        char         *swf_data;
        int           swf_data_len;
        int           unused_cid_purge;
    PREINIT:
        int           instance_name_len = 0;
    CODE:
        instance_name_len = strlen((char *)instance_name);
        RETVAL = swf_object_replace_movieclip(swf, instance_name,
                                                   instance_name_len,
                                                   swf_data,
                                                   swf_data_len);
    OUTPUT:
        RETVAL

void
purge_useless_contents(swf)
        swf_object_t *swf;
    CODE:
        swf_object_purge_contents(swf);

int
_replace_png_data(swf, image_id, data, data_len, opts)
        swf_object_t *swf;
        int           image_id;
        char         *data;
        int           data_len;
        SV           *opts;
    PREINIT: 
        int           rgb15  = -1;
        HV            *hv;
        SV            *sv_rgb15;
        HE            *he_rgb15;
    CODE:
        if (SvROK(opts)) {
            hv = (HV*)SvRV(opts);
            if (SvTYPE(hv) != SVt_PVHV) {
                croak("hashref expected");
            }
            sv_rgb15 = sv_2mortal(newSVpv("rgb15", 0));
            he_rgb15 = hv_fetch_ent(hv, sv_rgb15, 0, 0);
            if (he_rgb15) {
                rgb15 = SvIV(HeVAL(he_rgb15));
            }
        }
        RETVAL = swf_object_replace_pngdata(swf, image_id,
                                                 (unsigned char *)data,
                                                 (unsigned long) data_len,
                                                 rgb15);
    OUTPUT:
        RETVAL

int
set_shape_adjust_mode(swf, mode)
        swf_object_t *swf;
        unsigned long mode;
    CODE:
        RETVAL = swf_object_set_shape_adjust_mode(swf, mode);
    OUTPUT:
        RETVAL

char *
get_edit_string(swf, var_name)
        swf_object_t *swf;
        char         *var_name;
    PREINIT:
        int           var_name_len = strlen(var_name);
        int          error = 0;
    CODE:
        RETVAL = swf_object_get_editstring(swf, var_name, var_name_len, &error);
    OUTPUT:
        RETVAL

int
replace_edit_string(swf, var_name, ini_text)
        swf_object_t *swf;
        char*         var_name;
        char*         ini_text;
    PREINIT:
        int           var_name_len = strlen(var_name);
        int           ini_text_len = strlen(ini_text);
        char         *data   = NULL;
    CODE:
        RETVAL = swf_object_replace_editstring(swf, var_name, var_name_len, ini_text, ini_text_len);
    OUTPUT:
        RETVAL

int
set_compress_level(swf, compress_level)
        swf_object_t *swf;
        unsigned long compress_level;
    CODE:
        swf->compress_level = compress_level;
        RETVAL = 1;
    OUTPUT:
        RETVAL

int
rebuild(swf)
        swf_object_t *swf;
    CODE:
        RETVAL = swf_object_rebuild(swf);
    OUTPUT:
        RETVAL

SV *
get_shape_data(swf, cid)
        swf_object_t  *swf;
        unsigned long  cid;
    PREINIT:
        unsigned char *data     = NULL;
        unsigned long  data_len = 0;
    CODE:
        data = swf_object_get_shapedata(swf, cid, &data_len);
        if (NULL == data) {
            RETVAL = newSV(0);
        }
        else {
            RETVAL = newSVpvn(data, data_len);
        }
    OUTPUT:
        RETVAL

int
_replace_shape_data(swf, cid, data, data_len)
        swf_object_t  *swf;
        long           cid;
        char          *data;
        unsigned long  data_len;
    CODE:
        RETVAL = swf_object_replace_shapedata(swf, cid, (unsigned char *)data, data_len);
    OUTPUT:
        RETVAL

int
_replace_gif_data(swf, image_id, data, data_len)
        swf_object_t *swf;
        int           image_id;
        char         *data;
        int           data_len;
    CODE:
        RETVAL = swf_object_replace_gifdata(swf, image_id,
                                                 (unsigned char *)data,
                                                 (unsigned long) data_len);
    OUTPUT:
        RETVAL

int
_replace_bitmap_data(swf, image_cond, data, data_len, alpha_data, alpha_data_len, opts)
        swf_object_t *swf;
        SV           *image_cond;
        char         *data;
        int           data_len;
        char         *alpha_data;
        int           alpha_data_len;
        SV           *opts;
    PREINIT:
        int           image_id = 0;
        int           result   = 0;
        int           bitmap_format;
        int           width = -1, height = -1;
        int           red   = -1, green  = -1, blue = -1;
        int           without_converting = 0;
        int           rgb15 = -1;
        HV *hv;
        SV *sv_width, *sv_height, *sv_red, *sv_green, *sv_blue, *sv_rgb15, *sv_without_converting;
        HE *he_width, *he_height, *he_red, *he_green, *he_blue, *he_rgb15, *he_without_converting;
    CODE:
        if (SvROK(image_cond)) {
            hv = (HV*)SvRV(image_cond);
            if (SvTYPE(hv) != SVt_PVHV) {
                croak("hashref expected");
            }

            sv_width  = sv_2mortal(newSVpv("width",  0));
            sv_height = sv_2mortal(newSVpv("height", 0));
            sv_red    = sv_2mortal(newSVpv("red",    0));
            sv_green  = sv_2mortal(newSVpv("green",  0));
            sv_blue   = sv_2mortal(newSVpv("blue",   0));

            he_width = hv_fetch_ent(hv, sv_width, 0, 0);
            if (he_width) {
                width = SvIV(HeVAL(he_width));
            }
            he_height = hv_fetch_ent(hv, sv_height, 0, 0);
            if (he_height) {
                height = SvIV(HeVAL(he_height));
            }
            he_red = hv_fetch_ent(hv, sv_red, 0, 0);
            if (he_red) {
                red = SvIV(HeVAL(he_red));
            }
            he_green = hv_fetch_ent(hv, sv_green, 0, 0);
            if (he_green) {
                green = SvIV(HeVAL(he_green));
            }
            he_blue = hv_fetch_ent(hv, sv_blue, 0, 0);
            if (he_blue) {
                blue = SvIV(HeVAL(he_blue));
            }
        } else {
            image_id = SvIV(image_cond);
        }

        if (SvROK(opts)) {
            hv = (HV*)SvRV(opts);
            if (SvTYPE(hv) == SVt_PVHV) {
                sv_rgb15 = sv_2mortal(newSVpv("rgb15", 0));
                he_rgb15 = hv_fetch_ent(hv, sv_rgb15, 0, 0);
                if (he_rgb15) {
                    rgb15 = SvIV(HeVAL(he_rgb15));
                }
                sv_without_converting = sv_2mortal(newSVpv("without_converting", 0));
                he_without_converting = hv_fetch_ent(hv, sv_without_converting, 0, 0);
                if (he_without_converting) {
                    without_converting = SvIV(HeVAL(he_without_converting));
                }
            } else if(SvTYPE(hv) == SVt_IV) {
                if (0 < SvIV(opts)) {
                    without_converting = 1;
                }
            }
        }

        if (image_id == 0) {
            image_id = swf_object_search_cid_by_bitmap_condition(swf, width, height,
                                                                 red, green, blue);
        }

        if (image_id <= 0) {
            croak("image_id not found by bitmap condition(width=%d height=%d red=%d green=%d blue=%d)", width, height, red, green, blue);
        }

        bitmap_format = detect_bitmap_format((unsigned char*) data, data_len);

        if (without_converting) { // for v8 JPEG Tag
            switch (bitmap_format) {
            case BITMAP_UTIL_FORMAT_JPEG:
            case BITMAP_UTIL_FORMAT_PNG:
            case BITMAP_UTIL_FORMAT_GIF:
                result = swf_object_replace_jpegdata(swf, image_id,
                                                     (unsigned char *)data,
                                                     (unsigned long) data_len,
                                                     (unsigned char *) 0,
                                                     (unsigned long) 0,
                                                     1);
                break;
            default:
                croak("Unknown Bitmap Format");
            }
        } else {
            switch (bitmap_format) {
            case BITMAP_UTIL_FORMAT_JPEG:
                result = swf_object_replace_jpegdata(swf, image_id,
                                                     (unsigned char *)data,
                                                     (unsigned long) data_len,
                                                     (unsigned char *)alpha_data,
                                                     (unsigned long) alpha_data_len,
                                                     0);
                break;
            case BITMAP_UTIL_FORMAT_PNG:
                result = swf_object_replace_pngdata(swf, image_id,
                                                    (unsigned char *)data,
                                                    (unsigned long) data_len,
                                                    rgb15);
                break;
            case BITMAP_UTIL_FORMAT_GIF:
                result = swf_object_replace_gifdata(swf, image_id,
                                                    (unsigned char *)data,
                                                    (unsigned long) data_len);
                break;
            default:
                croak("Unknown Bitmap Format");
            }
        }

        RETVAL = result;
    OUTPUT:
        RETVAL

SV*
get_tag_list(swf)
        swf_object_t   *swf;
    PREINIT:
        int             i        = 0;
        AV*             data     = (AV*)sv_2mortal((SV*)newAV());
        swf_tag_t      *tag      = NULL;
        swf_tag_info_t *tag_info = NULL;
    CODE:
        for (tag = swf->tag_head; tag; tag = tag->next) {
            HV *hv = (HV *)sv_2mortal((SV *)newHV());
            hv_store(hv, "code", 4, newSVuv(tag->code), 0);
            hv_store(hv, "tag",  3, newSVuv(tag->code), 0);
            tag_info = get_swf_tag_info(tag->code);
            if (tag_info && tag_info->name) {
                hv_store(hv, "tagName", 7,
                         newSVpv(tag_info->name, strlen(tag_info->name)), 0);
            }
            hv_store(hv, "length", 6, newSVuv(tag->length), 0);
            if (tag_info && tag_info->detail_handler) {
                hv_store(hv, "detail", 6, newSVuv(1), 0);
            }
            av_push(data, newRV_inc((SV *)hv));
        }
        RETVAL = newRV_inc((SV *)data);
    OUTPUT:
        RETVAL

SV*
get_tag_detail(swf, tag_seqno)
        swf_object_t   *swf;
        long            tag_seqno;
    PREINIT:
        swf_tag_t      *tag       = NULL;
        swf_tag_info_t *tag_info  = NULL;
        int             i         = 0;
        HV             *data      = NULL;
    CODE:
        for (tag = swf->tag_head; tag; tag = tag->next) {
            if (i == tag_seqno) {
                break;
            }
            i++;
        }
        if (tag == NULL) {
            croak("false");
        }
        tag_info = get_swf_tag_info(tag->code);
        if ((tag_info == NULL) || (tag_info->detail_handler == NULL)) {
            croak("false");
        }
        if (swf_tag_create_input_detail(tag, swf) == NULL) {
            croak("false");
        }
        switch (tag->code) {
          swf_tag_jpeg_detail_t     *tag_jpeg;
          swf_tag_lossless_detail_t *tag_lossless;
          swf_tag_edit_detail_t     *tag_edit;
          swf_tag_sound_detail_t    *tag_sound;
          swf_tag_action_detail_t   *tag_action;
          swf_tag_sprite_detail_t   *tag_sprite;
          swf_tag_shape_detail_t    *tag_shape;
          swf_tag_place_detail_t    *tag_place;
          swf_action_t   *action;
          int action_list_count;
          int *bitmap_id_list, bitmap_id_list_num;
          case 6:  // DefineBitsJPEG
          case 21: // DefineBitsJPEG2
          case 35: // DefineBitsJPEG3
              tag_jpeg = tag->detail;
              data = (HV *)sv_2mortal((SV *)newHV());
              hv_store(data, "image_id", 8, newSVuv(tag_jpeg->image_id), 0);
              hv_store(data, "jpeg_data_len", 13, newSVuv(tag_jpeg->jpeg_data_len), 0);
              if ((tag_jpeg->alpha_data != NULL) &&
                  (tag_jpeg->alpha_data_len > 0)) {
                  hv_store(data, "alpha_data_len", 14, newSVuv(tag_jpeg->alpha_data_len), 0);
              }
              break;
          case 20: // DefineBitsLossless
          case 36: // DefineBitsLossless2
              tag_lossless = tag->detail;
              data = (HV *)sv_2mortal((SV *)newHV());
              hv_store(data, "image_id", 8, newSVuv(tag_lossless->image_id), 0);
              hv_store(data, "format",   6, newSVuv(tag_lossless->format),   0);
              hv_store(data, "width",    5, newSVuv(tag_lossless->width),    0);
              hv_store(data, "height",   6, newSVuv(tag_lossless->height),   0);
              if (tag_lossless->format == 3) {
                  hv_store(data, "colormap_count", 14, newSVuv(tag_lossless->colormap_count), 0);
              }
              break;
          case 14: // DefineSound
              tag_sound = tag->detail;
              data = (HV *)sv_2mortal((SV *)newHV());
              hv_store(data, "sound_id", 8,
                       newSVuv(tag_sound->sound_id), 0);
              hv_store(data, "format", 6,
                       newSVuv((unsigned long) tag_sound->sound_format), 0);
              hv_store(data, "rate", 4,
                       newSVuv((unsigned long) tag_sound->sound_rate), 0);
              hv_store(data, "is_16bits", 9,
                       newSVuv(tag_sound->sound_is_16bits?1:0), 0);
              hv_store(data, "is_stereo", 9,
                       newSVuv(tag_sound->sound_is_stereo?1:0), 0);
              hv_store(data, "sound_samples_count", 19,
                       newSVuv(tag_sound->sound_samples_count), 0);
              hv_store(data, "sound_data_len", 14,
                       newSVuv(tag_sound->sound_data_len), 0);
              break;
          case 12: // DoAction
          case 59: // DoInitAction
              tag_action = tag->detail;
              data = (HV *)sv_2mortal((SV *)newHV());
              if (tag->code == 59) { // DoInitAction
                  hv_store(data, "action_sprite", 13,
                           newSVuv(tag_action->action_sprite), 0);
              }
              action = tag_action->action_list->head;
              if (action) {
                  for (action_list_count = 0; action; action_list_count++) {
                      action = action->next;
                  }
                  hv_store(data, "action_list_count", 17,
                           newSVuv(action_list_count), 0);
              }
              break;
          case 37: // DefineEditText;
              tag_edit = tag->detail;
              data = (HV *)sv_2mortal((SV *)newHV());
              hv_store(data, "edit_id", 7, newSVuv(tag_edit->edit_id), 0);
              if (tag_edit->edit_variable_name && tag_edit->edit_variable_name[0]) {
                  hv_store(data, "variable_name", 13,
                           newSVpv((char *)tag_edit->edit_variable_name,
                           strlen((char *)tag_edit->edit_variable_name)), 0);
              }
              if (tag_edit->edit_initial_text && tag_edit->edit_initial_text[0]) {
                  hv_store(data, "initial_text", 12,
                           newSVpv((char *)tag_edit->edit_initial_text,
                           strlen((char *)tag_edit->edit_initial_text)), 0);
              }
              break;
          case 39: // DefineSprite;
              tag_sprite = tag->detail;
              data = (HV *)sv_2mortal((SV *)newHV());
              hv_store(data, "sprite_id", 9,
                       newSVuv(tag_sprite->sprite_id), 0);
              hv_store(data, "frame_count", 11,
                       newSVuv(tag_sprite->frame_count), 0);
              break;
          case 2: // DefineShape;
          case 22: // DefineShape2;
          case 32: // DefineShape3;
          case 46: // DefineMorphShape;
              tag_shape = tag->detail;
              data = (HV *)sv_2mortal((SV *)newHV());
              hv_store(data, "shape_id", 8,
                       newSVuv(tag_shape->shape_id), 0);
              hv_store(data, "fill_styles.count", 17,
                       newSVuv(tag_shape->shape_with_style.styles.fill_styles.count), 0);
              hv_store(data, "line_styles.count", 17,
                       newSVuv(tag_shape->shape_with_style.styles.line_styles.count), 0);
              bitmap_id_list = swf_tag_shape_bitmap_get_refcid_list(tag, &bitmap_id_list_num);
              if (bitmap_id_list) {
                  int i;
                  AV* arr = newAV();
                  for (i = 0 ; i < bitmap_id_list_num ; i++) {
                      av_push(arr, newRV_inc(newSVuv(bitmap_id_list[i])));
                  }
                  hv_store(data, "bitmap_ref", 10, newRV_inc((SV *)arr), 0);
                  Safefree(bitmap_id_list);
              }
              break;
          case 4: // PlaceObject
          case 26: // PlaceObject2
              tag_place = tag->detail;
              data = (HV *)sv_2mortal((SV *)newHV());
              if ((tag->code == 4) || tag_place->flag_has_character) {
                  hv_store(data, "character_id", 12,
                           newSVuv(tag_place->character_id), 0);
              }
              hv_store(data, "depth", 5,
                       newSVuv(tag_place->depth), 0);
              if (tag_place->flag_has_name) {
                  hv_store(data, "name", 4,
                           newSVpv((char *)tag_place->name,
                           strlen((char *)tag_place->name)), 0);
              }
              break;
          default:
              croak("false");
        }
        RETVAL = newRV_inc((SV *)data);
    OUTPUT:
        RETVAL

SV*
get_header_info(swf)
        swf_object_t   *swf;
    CODE:
        HV *data = (HV *)sv_2mortal((SV *)newHV());
        if (memcmp(swf->header.magic, "CWS", 3) == 0) {
            hv_store(data, "compress", 8, newSVuv(1), 0);
        } else { // FWS
            hv_store(data, "compress", 8, newSVuv(0), 0);
        }
        hv_store(data, "version", 7, newSVuv(swf->header.version), 0);
        hv_store(data, "x_min", 5,
                 newSVuv(swf->header_movie.frame_size.x_min / SWF_TWIPS), 0);
        hv_store(data, "y_min", 5,
                 newSVuv(swf->header_movie.frame_size.y_min / SWF_TWIPS), 0);
        hv_store(data, "x_max", 5,
                 newSVuv(swf->header_movie.frame_size.x_max / SWF_TWIPS), 0);
        hv_store(data, "y_max", 5,
                 newSVuv(swf->header_movie.frame_size.y_max / SWF_TWIPS), 0);
        RETVAL = newRV_inc((SV *)data);
    OUTPUT:
        RETVAL

void
set_header_info(swf, header_info)
        swf_object_t *swf;
        SV           *header_info;
    PREINIT:
        HV *hv;
        SV *sv_compress, *sv_version, *sv_x_min, *sv_y_min, *sv_x_max, *sv_y_max;
    CODE:
        if (!SvROK(header_info)) {
            croak("ref(hashref) expected");
        }
        hv = (HV *) SvRV(header_info);
        if (SvTYPE(hv) != SVt_PVHV) {
            croak("hashref expented");
        }
        hv_iterinit(hv);

        sv_compress = sv_2mortal(newSVpv("compress", 0));
        sv_version  = sv_2mortal(newSVpv("version",  0));
        sv_x_min    = sv_2mortal(newSVpv("x_min",    0));
        sv_y_min    = sv_2mortal(newSVpv("y_min",    0));
        sv_x_max    = sv_2mortal(newSVpv("x_max",    0));
        sv_y_max    = sv_2mortal(newSVpv("y_max",    0));
        
        if (hv_exists_ent(hv, sv_compress, 0)) {
            HE *he = hv_fetch_ent(hv, sv_compress, 0, 0);
            if (SvIV(HeVAL(he)) != 0) {
                memcpy(swf->header.magic, "CWS", 3);
            } else {
                memcpy(swf->header.magic, "FWS", 3);
            }
        }

        if (hv_exists_ent(hv, sv_version, 0)) {
            HE *he = hv_fetch_ent(hv, sv_version, 0, 0);
            swf->header.version = SvIV(HeVAL(he));
        }

        if (hv_exists_ent(hv, sv_x_min, 0)) {
            HE *he = hv_fetch_ent(hv, sv_x_min, 0, 0);
            swf->header_movie.frame_size.x_min = SvIV(HeVAL(he)) * SWF_TWIPS;
        }

        if (hv_exists_ent(hv, sv_y_min, 0)) {
            HE *he = hv_fetch_ent(hv, sv_y_min, 0, 0);
            swf->header_movie.frame_size.y_min = SvIV(HeVAL(he)) * SWF_TWIPS;
        }

        if (hv_exists_ent(hv, sv_x_max, 0)) {
            HE *he = hv_fetch_ent(hv, sv_x_max, 0, 0);
            swf->header_movie.frame_size.x_max = SvIV(HeVAL(he)) * SWF_TWIPS;
        }

        if (hv_exists_ent(hv, sv_y_max, 0)) {
            HE *he = hv_fetch_ent(hv, sv_y_max, 0, 0);
            swf->header_movie.frame_size.y_max = SvIV(HeVAL(he)) * SWF_TWIPS;
        }

SV *
get_tag_data(swf, seqno)
        swf_object_t  *swf;
        long           seqno;
    PREINIT:
        unsigned char *data     = NULL;
        unsigned long  data_len = 0;
    CODE:
        data = swf_object_get_tagdata(swf, seqno, &data_len);
        if (data == NULL) {
            croak("getTagData: Can't get_tagdata\n");
        }
        RETVAL = newSVpvn(data, data_len);
    OUTPUT:
        RETVAL

SV *
get_tag_data_by_cid(swf, cid)
        swf_object_t  *swf;
        long           cid;
    PREINIT:
        unsigned char *data     = NULL;
        unsigned long  data_len = 0;
    CODE:
        data = swf_object_get_tagdata_bycid(swf, cid, &data_len);
        if (data == NULL) {
            croak("getTagDataByCID: Can't get_tagdata_bycid\n");
        }
        RETVAL = newSVpvn(data, data_len);
    OUTPUT:
        RETVAL

int
_replace_tag_data(swf, seqno, data, data_len)
        swf_object_t *swf;
        long          seqno;
        char         *data;
        int           data_len;
    CODE:
        RETVAL = swf_object_replace_tagdata(swf, seqno,
                                            (unsigned char *)data, data_len);
    OUTPUT:
        RETVAL

int
_replace_tag_data_by_cid(swf, cid, data, data_len)
        swf_object_t *swf;
        long          cid;
        char         *data;
        int           data_len;
    CODE:
        RETVAL = swf_object_replace_tagdata_bycid(swf, cid,
                                                  (unsigned char *)data,
                                                  data_len);
    OUTPUT:
        RETVAL

SV *
get_tag_contents_by_cid(swf, cid)
        swf_object_t  *swf;
        long           cid;
    PREINIT:
        unsigned char *data     = NULL;
        unsigned long  data_len = 0;
    CODE:
        data = swf_object_get_tagcontents_bycid(swf, cid, &data_len);
        if (data == NULL) {
            croak("getTagContentsByCID: Can't get_tagcontents_bycid\n");
        }
        RETVAL = newSVpvn(data, data_len);
    OUTPUT:
        RETVAL

int
_replace_tag_contents_by_cid(swf, cid, data, data_len)
        swf_object_t *swf;
        long          cid;
        char         *data;
        int           data_len;
    CODE:
        RETVAL = swf_object_replace_tagcontents_bycid(swf, cid,
                                                      (unsigned char *)data,
                                                      data_len);
    OUTPUT:
        RETVAL

int
_is_shape_tag_data(swf, data, data_len)
        swf_object_t *swf;
        char         *data;
        int           data_len;
    CODE:
        RETVAL = swf_object_is_shape_tagdata(data, data_len);
    OUTPUT:
        RETVAL

int
_is_bitmap_tag_data(swf, data, data_len)
        swf_object_t *swf;
        char         *data;
        int           data_len;
    CODE:
        RETVAL = swf_object_is_bitmap_tagdata(data, data_len);
    OUTPUT:
        RETVAL

SV *
get_jpeg_data(swf, image_id)
        swf_object_t  *swf;
        long           image_id;
    PREINIT:
        unsigned char *data     = NULL;
        unsigned long  data_len = 0;
    CODE:
        data = swf_object_get_jpegdata(swf, &data_len, image_id);
        if (data == NULL) {
            croak("get_jpeg_data: error");
        }
        RETVAL = newSVpvn(data, data_len);
    OUTPUT:
        RETVAL

SV *
get_png_data(swf, image_id)
        swf_object_t  *swf;
        long           image_id;
    PREINIT:
        unsigned char *data     = NULL;
        unsigned long  data_len = 0;
    CODE:
        data = swf_object_get_pngdata(swf, &data_len, image_id);
        if (data == NULL) {
            croak("get_png_data: error");
        }
        RETVAL = newSVpvn(data, data_len);
    OUTPUT:
        RETVAL

SV *
get_jpeg_alpha(swf, image_id)
        swf_object_t  *swf;
        long           image_id;
    PREINIT:
        unsigned char *data     = NULL;
        unsigned long  data_len = 0;
    CODE:
        data = swf_object_get_alphadata(swf, &data_len, image_id);
        if (data == NULL) {
            croak("get_jpeg_data: error");
        }
        RETVAL = newSVpvn(data, data_len);
    OUTPUT:
        RETVAL

SV*
get_bitmap_size(swf, bitmap_id)
        swf_object_t   *swf;
        long            bitmap_id;
    PREINIT:
        int             width;
        int             height;
        int             ret;
        HV             *data      = NULL;
    CODE:
        ret = swf_object_get_bitmap_size(swf, bitmap_id, &width, &height);
        if (ret) {
            croak("get_bitmap_size: error");
        }
        data = (HV *)sv_2mortal((SV *)newHV());
        hv_store(data, "width",  5, newSVuv(width),  0);
        hv_store(data, "height", 6, newSVuv(height), 0);
        RETVAL = newRV_inc((SV *)data);
    OUTPUT:
        RETVAL

SV *
get_sound_data(swf, sound_id)
        swf_object_t  *swf;
        long           sound_id;
    PREINIT:
        unsigned char *data     = NULL;
        unsigned long  data_len = 0;
    CODE:
        data = swf_object_get_sounddata(swf, &data_len, sound_id);
        if (data == NULL) {
            croak("get_jpeg_data: error");
        }
        RETVAL = newSVpvn(data, data_len);
    OUTPUT:
        RETVAL

int
_replace_mld_data(swf, sound_id, data, data_len)
        swf_object_t *swf;
        long          sound_id;
        char         *data;
        int           data_len;
    CODE:
        RETVAL = swf_object_replace_melodata(swf, sound_id,
                                             (unsigned char *)data,
                                             (unsigned long) data_len);
    OUTPUT:
        RETVAL

int
_remove_tag(swf, tag_seqno, tag_seqno_in_sprite)
        swf_object_t *swf;
        long          tag_seqno;
        long          tag_seqno_in_sprite;
    CODE:
        RETVAL = swf_object_remove_tag(swf, tag_seqno, tag_seqno_in_sprite);
    OUTPUT:
        RETVAL

int
_print_tag_data(swf, data, data_len)
        swf_object_t *swf;
        char         *data;
        int           data_len;
    PREINIT:
        int           ret;
    CODE:
        RETVAL = swf_object_print_tagdata(swf, (unsigned char *)data, data_len);
        fflush(stdout);
    OUTPUT:
        RETVAL

SV *
get_action_data(swf, tag_seqno)
        swf_object_t  *swf;
        long           tag_seqno;
    PREINIT:
        unsigned char *data     = NULL;
        unsigned long  data_len = 0;
    CODE:
        data = swf_object_get_actiondata(swf, &data_len, tag_seqno);
        if (data == NULL) {
            croak("get_action_data: error");
        }
        RETVAL = newSVpvn(data, data_len);
    OUTPUT:
        RETVAL

SV*
get_shape_id_list_by_bitmap_ref(swf, bitmap_id)
        swf_object_t   *swf;
        int             bitmap_id;
    PREINIT:
        int             i        = 0;
        AV*             data     = (AV*)sv_2mortal((SV*)newAV());
        swf_tag_t      *tag      = NULL;
        swf_tag_info_t *tag_info = NULL;
        int *bitmap_id_list, bitmap_id_list_num;
    CODE:
        for (tag = swf->tag_head; tag; tag=tag->next) {
            register int tag_code = tag->code;
            if (isShapeTag(tag_code)) {
                bitmap_id_list = swf_tag_shape_bitmap_get_refcid_list(tag, &bitmap_id_list_num);
                if (bitmap_id_list) {
                    int j;
                    for (j=0 ; j < bitmap_id_list_num ; j++) {
                        if (bitmap_id_list[j] == bitmap_id) {
                            swf_tag_shape_detail_t *swf_tag_shape = tag->detail;
                            av_push(data, newSViv((long)swf_tag_shape->shape_id));
                            i++;
                            break;
                        }
                    }
                    free(bitmap_id_list);
                }
            }
        }
        RETVAL = newRV_inc((SV *)data);
    OUTPUT:
        RETVAL

int
convert_bitmap_data_to_jpeg_tag(swf)
        swf_object_t *swf;
    CODE:
        RETVAL = swf_object_convert_bitmapdata_tojpegtag(swf);
    OUTPUT:
        RETVAL

int
apply_shape_matrix_factor(swf, shape_id, scale_x, scale_y, rotate_rad, trans_x, trans_y)
        swf_object_t *swf;
        long          shape_id;
        double        scale_x;
        double        scale_y;
        double        rotate_rad;
        long          trans_x;
        long          trans_y;
    CODE:
        RETVAL = swf_object_apply_shapematrix_factor(swf, shape_id, -1,
                                                     scale_x, scale_y, rotate_rad,
                                                     trans_x, trans_y);
    OUTPUT:
        RETVAL

int
apply_shape_rect_factor(swf, shape_id, scale_x, scale_y, trans_x, trans_y)
        swf_object_t *swf;
        long          shape_id;
        double        scale_x;
        double        scale_y;
        long          trans_x;
        long          trans_y;
    PREINIT:
        int           result;
    CODE:
        RETVAL = swf_object_apply_shaperect_factor(swf, shape_id, -1,
                                                     scale_x, scale_y,
                                                     trans_x, trans_y);
    OUTPUT:
        RETVAL

int
disasm_action_data(swf)
        swf_object_t      *swf;
    PREINIT:
        unsigned char     *data        = NULL;
        unsigned long      data_len    = 0;
        bitstream_t       *bs          = NULL;
        swf_action_list_t *action_list = NULL;
    CODE:
        //array_init(return_value);
        bs = bitstream_open();
        bitstream_input(bs, (unsigned char*) data, data_len);
        action_list = swf_action_list_create();
        swf_action_list_parse(bs, action_list);
        bitstream_close(bs);
        if (action_list) {
            swf_action_t *action = action_list->head;
            while(action) {
                printf("\t");
                action = action->next;
            }
        }
        swf_action_list_destroy(action_list);
        RETVAL = 1;
    OUTPUT:
        RETVAL

int
_replace_jpeg_data(swf, image_id, data, data_len, alpha_data, alpha_data_len)
        swf_object_t *swf;
        int          image_id;
        char         *data;
        int           data_len;
        char         *alpha_data;
        int           alpha_data_len;
    PREINIT:
        int           result = 0;
    CODE:
        RETVAL = swf_object_replace_jpegdata(swf, image_id,
                                             (unsigned char *)data,
                                             (unsigned long) data_len,
                                             (unsigned char *)alpha_data,
                                             (unsigned long) alpha_data_len,
                                             0);
    OUTPUT:
        RETVAL
