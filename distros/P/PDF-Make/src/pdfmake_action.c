/*
 * pdfmake_action.c — PDF action system implementation
 *
 * Creates action dictionaries for link navigation, JavaScript, etc.
 */

#include "pdfmake_action.h"
#include "pdfmake_arena.h"
#include "pdfmake_annot.h"
#include <string.h>
#include <stdlib.h>

/*============================================================================
 * Named action string mapping
 *==========================================================================*/

static const char *named_action_strings[] = {
    "NextPage",
    "PrevPage",
    "FirstPage",
    "LastPage",
    "Print"
};

static const char *highlight_mode_names[] = {
    "N",  /* None */
    "I",  /* Invert */
    "O",  /* Outline */
    "P"   /* Push */
};

/*============================================================================
 * Action allocation helper
 *==========================================================================*/

static pdfmake_action_t *alloc_action(pdfmake_doc_t *doc, pdfmake_action_type_t type)
{
    pdfmake_action_t *action;
    if (!doc) return NULL;
    
    action = pdfmake_arena_alloc(doc->arena, sizeof(pdfmake_action_t));
    if (!action) return NULL;
    
    memset(action, 0, sizeof(*action));
    action->type = type;
    action->doc = doc;
    
    return action;
}

/*============================================================================
 * Action builders
 *==========================================================================*/

pdfmake_action_t *pdfmake_action_goto(pdfmake_doc_t *doc, pdfmake_dest_t dest)
{
    pdfmake_action_t *action = alloc_action(doc, PDFMAKE_ACTION_GOTO);
    if (!action) return NULL;
    
    action->data.go_to.dest = dest;
    return action;
}

pdfmake_action_t *pdfmake_action_gotor(pdfmake_doc_t *doc,
                                        const char *file,
                                        pdfmake_dest_t dest,
                                        int new_window)
{
    pdfmake_action_t *action;
    if (!file) return NULL;
    
    action = alloc_action(doc, PDFMAKE_ACTION_GOTOR);
    if (!action) return NULL;
    
    action->data.go_tor.file = pdfmake_arena_strdup(doc->arena, file);
    action->data.go_tor.dest = dest;
    action->data.go_tor.new_window = new_window;
    
    if (!action->data.go_tor.file) return NULL;
    return action;
}

pdfmake_action_t *pdfmake_action_uri(pdfmake_doc_t *doc, const char *uri)
{
    pdfmake_action_t *action;
    if (!uri) return NULL;
    
    action = alloc_action(doc, PDFMAKE_ACTION_URI);
    if (!action) return NULL;
    
    action->data.uri.uri = pdfmake_arena_strdup(doc->arena, uri);
    action->data.uri.is_map = 0;
    
    if (!action->data.uri.uri) return NULL;
    return action;
}

pdfmake_action_t *pdfmake_action_named(pdfmake_doc_t *doc, pdfmake_named_action_t name)
{
    pdfmake_action_t *action = alloc_action(doc, PDFMAKE_ACTION_NAMED);
    if (!action) return NULL;
    
    action->data.named.name = name;
    return action;
}

pdfmake_action_t *pdfmake_action_named_str(pdfmake_doc_t *doc, const char *name_str)
{
    pdfmake_named_action_t name;
    if (!name_str) return NULL;
    
    if (strcmp(name_str, "NextPage") == 0) {
        name = PDFMAKE_NAMED_NEXTPAGE;
    } else if (strcmp(name_str, "PrevPage") == 0) {
        name = PDFMAKE_NAMED_PREVPAGE;
    } else if (strcmp(name_str, "FirstPage") == 0) {
        name = PDFMAKE_NAMED_FIRSTPAGE;
    } else if (strcmp(name_str, "LastPage") == 0) {
        name = PDFMAKE_NAMED_LASTPAGE;
    } else if (strcmp(name_str, "Print") == 0) {
        name = PDFMAKE_NAMED_PRINT;
    } else {
        return NULL;  /* Unknown named action */
    }
    
    return pdfmake_action_named(doc, name);
}

pdfmake_action_t *pdfmake_action_javascript(pdfmake_doc_t *doc, const char *script)
{
    pdfmake_action_t *action;
    if (!script) return NULL;
    
    action = alloc_action(doc, PDFMAKE_ACTION_JAVASCRIPT);
    if (!action) return NULL;
    
    action->data.javascript.script = pdfmake_arena_strdup(doc->arena, script);
    
    if (!action->data.javascript.script) return NULL;
    return action;
}

pdfmake_action_t *pdfmake_action_hide(pdfmake_doc_t *doc,
                                       const char **targets,
                                       size_t target_count,
                                       int hide)
{
    pdfmake_action_t *action;
    size_t i;
    if (target_count == 0) return NULL;
    
    action = alloc_action(doc, PDFMAKE_ACTION_HIDE);
    if (!action) return NULL;
    
    action->data.hide.targets = pdfmake_arena_alloc(doc->arena, target_count * sizeof(char *));
    if (!action->data.hide.targets) return NULL;
    
    for (i = 0; i < target_count; i++) {
        action->data.hide.targets[i] = pdfmake_arena_strdup(doc->arena, targets[i]);
        if (!action->data.hide.targets[i]) return NULL;
    }
    
    action->data.hide.target_count = target_count;
    action->data.hide.hide = hide ? 1 : 0;
    
    return action;
}

pdfmake_err_t pdfmake_action_chain(pdfmake_action_t *action, pdfmake_action_t *next)
{
    if (!action || !next) return PDFMAKE_EINVAL;
    action->next = next;
    return PDFMAKE_OK;
}

/*============================================================================
 * Action writing
 *==========================================================================*/

pdfmake_obj_t pdfmake_action_to_obj(pdfmake_action_t *action)
{
    pdfmake_arena_t *arena;
    pdfmake_obj_t dict;
    uint32_t type_key;
    uint32_t s_key;
    uint32_t d_key;
    pdfmake_obj_t dest;
    uint32_t f_key;
    pdfmake_obj_t dest_arr;
    uint32_t nw_key;
    uint32_t uri_key;
    uint32_t map_key;
    uint32_t n_key;
    const char *name_str;
    uint32_t js_key;
    uint32_t t_key;
    pdfmake_obj_t arr;
    size_t i;
    uint32_t h_key;
    uint32_t next_key;
    uint32_t next_num;
    if (!action || !action->doc) return pdfmake_null();
    
    arena = action->doc->arena;
    dict = pdfmake_dict_new(arena);
    
    type_key = pdfmake_arena_intern_name(arena, "Type", 4);
    s_key = pdfmake_arena_intern_name(arena, "S", 1);
    
    pdfmake_dict_set(arena, &dict, type_key, pdfmake_name(arena, "Action", 6));
    
    switch (action->type) {
        case PDFMAKE_ACTION_GOTO: {
            pdfmake_dict_set(arena, &dict, s_key, pdfmake_name(arena, "GoTo", 4));
            
            d_key = pdfmake_arena_intern_name(arena, "D", 1);
            dest = pdfmake_dest_to_obj(arena, action->doc, action->data.go_to.dest);
            pdfmake_dict_set(arena, &dict, d_key, dest);
            break;
        }
        
        case PDFMAKE_ACTION_GOTOR: {
            pdfmake_dict_set(arena, &dict, s_key, pdfmake_name(arena, "GoToR", 5));
            
            f_key = pdfmake_arena_intern_name(arena, "F", 1);
            d_key = pdfmake_arena_intern_name(arena, "D", 1);
            
            pdfmake_dict_set(arena, &dict, f_key, 
                pdfmake_str(arena, action->data.go_tor.file, strlen(action->data.go_tor.file)));
            
            /* For external destinations, use page number as int */
            dest_arr = pdfmake_array_new(arena);
            pdfmake_array_push(arena, &dest_arr, pdfmake_int((int64_t)action->data.go_tor.dest.page_index));
            pdfmake_array_push(arena, &dest_arr, pdfmake_name(arena, "Fit", 3));
            pdfmake_dict_set(arena, &dict, d_key, dest_arr);
            
            if (action->data.go_tor.new_window) {
                nw_key = pdfmake_arena_intern_name(arena, "NewWindow", 9);
                pdfmake_dict_set(arena, &dict, nw_key, pdfmake_bool(1));
            }
            break;
        }
        
        case PDFMAKE_ACTION_URI: {
            pdfmake_dict_set(arena, &dict, s_key, pdfmake_name(arena, "URI", 3));
            
            uri_key = pdfmake_arena_intern_name(arena, "URI", 3);
            pdfmake_dict_set(arena, &dict, uri_key,
                pdfmake_str(arena, action->data.uri.uri, strlen(action->data.uri.uri)));
            
            if (action->data.uri.is_map) {
                map_key = pdfmake_arena_intern_name(arena, "IsMap", 5);
                pdfmake_dict_set(arena, &dict, map_key, pdfmake_bool(1));
            }
            break;
        }
        
        case PDFMAKE_ACTION_NAMED: {
            pdfmake_dict_set(arena, &dict, s_key, pdfmake_name(arena, "Named", 5));
            
            n_key = pdfmake_arena_intern_name(arena, "N", 1);
            name_str = named_action_strings[action->data.named.name];
            pdfmake_dict_set(arena, &dict, n_key, 
                pdfmake_name(arena, name_str, strlen(name_str)));
            break;
        }
        
        case PDFMAKE_ACTION_JAVASCRIPT: {
            pdfmake_dict_set(arena, &dict, s_key, pdfmake_name(arena, "JavaScript", 10));
            
            js_key = pdfmake_arena_intern_name(arena, "JS", 2);
            pdfmake_dict_set(arena, &dict, js_key,
                pdfmake_str(arena, action->data.javascript.script, 
                            strlen(action->data.javascript.script)));
            break;
        }
        
        case PDFMAKE_ACTION_HIDE: {
            pdfmake_dict_set(arena, &dict, s_key, pdfmake_name(arena, "Hide", 4));
            
            t_key = pdfmake_arena_intern_name(arena, "T", 1);
            
            if (action->data.hide.target_count == 1) {
                /* Single target as string */
                pdfmake_dict_set(arena, &dict, t_key,
                    pdfmake_str(arena, action->data.hide.targets[0],
                                strlen(action->data.hide.targets[0])));
            } else {
                /* Multiple targets as array */
                arr = pdfmake_array_new(arena);
                for (i = 0; i < action->data.hide.target_count; i++) {
                    pdfmake_array_push(arena, &arr,
                        pdfmake_str(arena, action->data.hide.targets[i],
                                    strlen(action->data.hide.targets[i])));
                }
                pdfmake_dict_set(arena, &dict, t_key, arr);
            }
            
            if (!action->data.hide.hide) {
                /* H defaults to true (hide), so only set if false (show) */
                h_key = pdfmake_arena_intern_name(arena, "H", 1);
                pdfmake_dict_set(arena, &dict, h_key, pdfmake_bool(0));
            }
            break;
        }
        
        case PDFMAKE_ACTION_LAUNCH: {
            pdfmake_dict_set(arena, &dict, s_key, pdfmake_name(arena, "Launch", 6));
            
            f_key = pdfmake_arena_intern_name(arena, "F", 1);
            pdfmake_dict_set(arena, &dict, f_key,
                pdfmake_str(arena, action->data.launch.file,
                            strlen(action->data.launch.file)));
            
            if (action->data.launch.new_window) {
                nw_key = pdfmake_arena_intern_name(arena, "NewWindow", 9);
                pdfmake_dict_set(arena, &dict, nw_key, pdfmake_bool(1));
            }
            break;
        }
    }
    
    /* Chain action */
    if (action->next) {
        next_key = pdfmake_arena_intern_name(arena, "Next", 4);
        next_num = pdfmake_action_write(action->next);
        if (next_num > 0) {
            pdfmake_dict_set(arena, &dict, next_key, pdfmake_ref(next_num, 0));
        }
    }
    
    return dict;
}

uint32_t pdfmake_action_write(pdfmake_action_t *action)
{
    pdfmake_obj_t dict;
    if (!action || !action->doc) return 0;
    
    if (action->obj_num > 0) {
        return action->obj_num;  /* Already written */
    }
    
    dict = pdfmake_action_to_obj(action);
    if (dict.kind != PDFMAKE_DICT) return 0;
    
    action->obj_num = pdfmake_doc_add(action->doc, dict);
    return action->obj_num;
}

/*============================================================================
 * Extended link annotation with action
 *==========================================================================*/

uint32_t pdfmake_annot_link_action(pdfmake_doc_t *doc,
                                    pdfmake_rect_t rect,
                                    pdfmake_action_t *action,
                                    pdfmake_highlight_mode_t highlight)
{
    pdfmake_arena_t *arena;
    pdfmake_obj_t dict;
    uint32_t type_key;
    uint32_t subtype_key;
    uint32_t rect_key;
    pdfmake_obj_t rect_arr;
    uint32_t border_key;
    pdfmake_obj_t border;
    uint32_t action_key;
    pdfmake_obj_t action_obj;
    if (!doc || !action) return 0;
    
    arena = doc->arena;
    dict = pdfmake_dict_new(arena);
    
    /* /Type /Annot */
    type_key = pdfmake_arena_intern_name(arena, "Type", 4);
    pdfmake_dict_set(arena, &dict, type_key, pdfmake_name(arena, "Annot", 5));
    
    /* /Subtype /Link */
    subtype_key = pdfmake_arena_intern_name(arena, "Subtype", 7);
    pdfmake_dict_set(arena, &dict, subtype_key, pdfmake_name(arena, "Link", 4));
    
    /* /Rect */
    rect_key = pdfmake_arena_intern_name(arena, "Rect", 4);
    rect_arr = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &rect_arr, pdfmake_real(rect.x1));
    pdfmake_array_push(arena, &rect_arr, pdfmake_real(rect.y1));
    pdfmake_array_push(arena, &rect_arr, pdfmake_real(rect.x2));
    pdfmake_array_push(arena, &rect_arr, pdfmake_real(rect.y2));
    pdfmake_dict_set(arena, &dict, rect_key, rect_arr);
    
    /* /Border [0 0 0] - no visible border */
    border_key = pdfmake_arena_intern_name(arena, "Border", 6);
    border = pdfmake_array_new(arena);
    pdfmake_array_push(arena, &border, pdfmake_int(0));
    pdfmake_array_push(arena, &border, pdfmake_int(0));
    pdfmake_array_push(arena, &border, pdfmake_int(0));
    pdfmake_dict_set(arena, &dict, border_key, border);
    
    /* /A (action) */
    action_key = pdfmake_arena_intern_name(arena, "A", 1);
    action_obj = pdfmake_action_to_obj(action);
    pdfmake_dict_set(arena, &dict, action_key, action_obj);
    
    /* /H (highlight mode) - only if not default (Invert) */
    if (highlight != PDFMAKE_HIGHLIGHT_INVERT) {
        uint32_t h_key = pdfmake_arena_intern_name(arena, "H", 1);
        const char *h_name = highlight_mode_names[highlight];
        pdfmake_dict_set(arena, &dict, h_key, pdfmake_name(arena, h_name, strlen(h_name)));
    }
    
    return pdfmake_doc_add(doc, dict);
}

uint32_t pdfmake_annot_link_named(pdfmake_doc_t *doc,
                                   pdfmake_rect_t rect,
                                   const char *name,
                                   pdfmake_highlight_mode_t highlight)
{
    pdfmake_action_t *action = pdfmake_action_named_str(doc, name);
    if (!action) return 0;
    
    return pdfmake_annot_link_action(doc, rect, action, highlight);
}
