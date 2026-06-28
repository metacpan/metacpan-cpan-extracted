/*
 * pdfmake_action.h — PDF action system (§12.6)
 *
 * Actions define behaviors triggered by events like clicking a link
 * or bookmark. This header provides builders for common action types.
 *
 * Reference:
 * - §12.6 Actions
 * - §12.6.4 Action types
 */

#ifndef PDFMAKE_ACTION_H
#define PDFMAKE_ACTION_H

#include "pdfmake_types.h"
#include "pdfmake_doc.h"
#include "pdfmake_outline.h"  /* For pdfmake_dest_t */
#include "pdfmake_annot.h"    /* For pdfmake_rect_t */

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Action types (§12.6.4)
 *==========================================================================*/

typedef enum {
    PDFMAKE_ACTION_GOTO,        /* Navigate to destination in same document */
    PDFMAKE_ACTION_GOTOR,       /* Navigate to destination in another PDF */
    PDFMAKE_ACTION_URI,         /* Open a URI (web link) */
    PDFMAKE_ACTION_NAMED,       /* Execute a named action */
    PDFMAKE_ACTION_JAVASCRIPT,  /* Execute JavaScript (stored, not executed) */
    PDFMAKE_ACTION_HIDE,        /* Show/hide annotations */
    PDFMAKE_ACTION_LAUNCH       /* Launch external application (stored only) */
} pdfmake_action_type_t;

/*============================================================================
 * Named actions (§12.6.4.11)
 *==========================================================================*/

typedef enum {
    PDFMAKE_NAMED_NEXTPAGE,
    PDFMAKE_NAMED_PREVPAGE,
    PDFMAKE_NAMED_FIRSTPAGE,
    PDFMAKE_NAMED_LASTPAGE,
    PDFMAKE_NAMED_PRINT
} pdfmake_named_action_t;

/*============================================================================
 * Link highlight modes (§12.5.6.5)
 *==========================================================================*/

typedef enum {
    PDFMAKE_HIGHLIGHT_NONE,     /* /N - No highlighting */
    PDFMAKE_HIGHLIGHT_INVERT,   /* /I - Invert colors (default) */
    PDFMAKE_HIGHLIGHT_OUTLINE,  /* /O - Outline the rectangle */
    PDFMAKE_HIGHLIGHT_PUSH      /* /P - Pushed button appearance */
} pdfmake_highlight_mode_t;

/*============================================================================
 * Action structure
 *==========================================================================*/

typedef struct pdfmake_action {
    pdfmake_action_type_t type;
    pdfmake_doc_t        *doc;
    
    union {
        /* GOTO action */
        struct {
            pdfmake_dest_t dest;
        } go_to;
        
        /* GOTOR action (external PDF) */
        struct {
            char          *file;      /* File path or name */
            pdfmake_dest_t dest;
            int            new_window; /* Open in new window? */
        } go_tor;
        
        /* URI action */
        struct {
            char *uri;
            int   is_map;  /* IsMap flag for image maps */
        } uri;
        
        /* Named action */
        struct {
            pdfmake_named_action_t name;
        } named;
        
        /* JavaScript action */
        struct {
            char *script;
        } javascript;
        
        /* Hide action */
        struct {
            char **targets;   /* Array of annotation names to hide/show */
            size_t target_count;
            int    hide;      /* 1 = hide, 0 = show */
        } hide;
        
        /* Launch action */
        struct {
            char *file;
            int   new_window;
        } launch;
    } data;
    
    /* For chaining */
    struct pdfmake_action *next;  /* /Next action */
    
    /* Written object number */
    uint32_t obj_num;
} pdfmake_action_t;

/*============================================================================
 * Action builders
 *==========================================================================*/

/*
 * Create a GoTo action (navigate within document).
 * dest: Destination (page + view type)
 * Returns action pointer, or NULL on error.
 */
pdfmake_action_t *pdfmake_action_goto(pdfmake_doc_t *doc,
                                       pdfmake_dest_t dest);

/*
 * Create a GoToR action (navigate to external PDF).
 * file: Path to external PDF
 * dest: Destination in that PDF
 * new_window: Open in new window (1) or same (0)
 * Returns action pointer, or NULL on error.
 */
pdfmake_action_t *pdfmake_action_gotor(pdfmake_doc_t *doc,
                                        const char *file,
                                        pdfmake_dest_t dest,
                                        int new_window);

/*
 * Create a URI action (open web link).
 * uri: The URI to open
 * Returns action pointer, or NULL on error.
 */
pdfmake_action_t *pdfmake_action_uri(pdfmake_doc_t *doc,
                                      const char *uri);

/*
 * Create a Named action.
 * name: Named action type (NextPage, PrevPage, etc.)
 * Returns action pointer, or NULL on error.
 */
pdfmake_action_t *pdfmake_action_named(pdfmake_doc_t *doc,
                                        pdfmake_named_action_t name);

/*
 * Create a Named action by string name.
 * name_str: Action name as string ("NextPage", "Print", etc.)
 * Returns action pointer, or NULL on error.
 */
pdfmake_action_t *pdfmake_action_named_str(pdfmake_doc_t *doc,
                                            const char *name_str);

/*
 * Create a JavaScript action.
 * script: JavaScript code (stored, not executed)
 * Returns action pointer, or NULL on error.
 */
pdfmake_action_t *pdfmake_action_javascript(pdfmake_doc_t *doc,
                                             const char *script);

/*
 * Create a Hide action.
 * targets: Array of annotation names to hide/show
 * target_count: Number of targets
 * hide: 1 to hide, 0 to show
 * Returns action pointer, or NULL on error.
 */
pdfmake_action_t *pdfmake_action_hide(pdfmake_doc_t *doc,
                                       const char **targets,
                                       size_t target_count,
                                       int hide);

/*
 * Chain an action to another (sets /Next).
 * Returns PDFMAKE_OK on success.
 */
pdfmake_err_t pdfmake_action_chain(pdfmake_action_t *action,
                                    pdfmake_action_t *next);

/*============================================================================
 * Action writing
 *==========================================================================*/

/*
 * Write action dict to document.
 * Returns object number, or 0 on error.
 */
uint32_t pdfmake_action_write(pdfmake_action_t *action);

/*
 * Build action dict object (not indirect).
 */
pdfmake_obj_t pdfmake_action_to_obj(pdfmake_action_t *action);

/*============================================================================
 * Extended link annotation with action support
 *==========================================================================*/

/*
 * Create link annotation with action.
 * rect: Clickable area
 * action: Action to execute on click
 * highlight: Highlight mode
 * Returns object number, or 0 on error.
 */
uint32_t pdfmake_annot_link_action(pdfmake_doc_t *doc,
                                    pdfmake_rect_t rect,
                                    pdfmake_action_t *action,
                                    pdfmake_highlight_mode_t highlight);

/*
 * Create link annotation with named action by string.
 * rect: Clickable area
 * name: Named action string ("NextPage", "PrevPage", etc.)
 * highlight: Highlight mode
 * Returns object number, or 0 on error.
 */
uint32_t pdfmake_annot_link_named(pdfmake_doc_t *doc,
                                   pdfmake_rect_t rect,
                                   const char *name,
                                   pdfmake_highlight_mode_t highlight);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_ACTION_H */
