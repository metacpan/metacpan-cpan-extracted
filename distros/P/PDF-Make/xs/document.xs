MODULE = PDF::Make  PACKAGE = PDF::Make::Document
PROTOTYPES: ENABLE

pdfmake_doc_t *
new(class)
    char *class
    CODE:
        RETVAL = pdfmake_doc_new();
        if (!RETVAL) {
            croak("PDF::Make::Document::new: failed to create document");
        }
    OUTPUT:
        RETVAL

UV
add(self, obj_sv)
    pdfmake_doc_t *self
    SV *obj_sv
    CODE:
        /* For now, accept simple scalars. Full object support later. */
        pdfmake_obj_t obj;
        pdfmake_arena_t *arena = pdfmake_doc_arena(self);

        if (!SvOK(obj_sv)) {
            obj = pdfmake_null();
        }
        else if (SvIOK(obj_sv)) {
            obj = pdfmake_int(SvIV(obj_sv));
        }
        else if (SvNOK(obj_sv)) {
            obj = pdfmake_real(SvNV(obj_sv));
        }
        else if (SvPOK(obj_sv)) {
            STRLEN len;
            const char *str = SvPV(obj_sv, len);
            obj = pdfmake_str(arena, str, len);
        }
        else {
            croak("PDF::Make::Document::add: unsupported object type");
        }

        RETVAL = pdfmake_doc_add(self, obj);
        if (RETVAL == 0) {
            croak("PDF::Make::Document::add: failed to add object");
        }
    OUTPUT:
        RETVAL

void
set_root(self, num, gen = 0)
    pdfmake_doc_t *self
    UV num
    UV gen
    CODE:
        pdfmake_doc_set_root(self, (uint32_t)num, (uint16_t)gen);

void
set_info(self, num, gen = 0)
    pdfmake_doc_t *self
    UV num
    UV gen
    CODE:
        pdfmake_doc_set_info(self, (uint32_t)num, (uint16_t)gen);

void
set_encryption(self, algorithm, user_passwd, owner_passwd, permissions)
    pdfmake_doc_t *self
    const char *algorithm
    const char *user_passwd
    SV *owner_passwd
    IV permissions
    PREINIT:
        pdfmake_crypt_algo_t algo;
        const char *owner = NULL;
    CODE:
        if (strEQ(algorithm, "RC4-40") || strEQ(algorithm, "rc4-40")) {
            algo = PDFMAKE_CRYPT_RC4_40;
        } else if (strEQ(algorithm, "RC4-128") || strEQ(algorithm, "rc4-128")) {
            algo = PDFMAKE_CRYPT_RC4_128;
        } else if (strEQ(algorithm, "AES-128") || strEQ(algorithm, "aes-128")) {
            algo = PDFMAKE_CRYPT_AES_128;
        } else if (strEQ(algorithm, "AES-256") || strEQ(algorithm, "aes-256")) {
            algo = PDFMAKE_CRYPT_AES_256;
        } else {
            croak("PDF::Make::Document::set_encryption: unknown algorithm '%s'", algorithm);
        }
        if (SvOK(owner_passwd)) owner = SvPV_nolen(owner_passwd);
        if (pdfmake_doc_set_encryption(self, algo, user_passwd, owner,
                                       (int32_t)permissions) != PDFMAKE_OK) {
            croak("PDF::Make::Document::set_encryption: failed");
        }

SV *
to_bytes(self)
    pdfmake_doc_t *self
    CODE:
        pdfmake_buf_t buf;
        if (pdfmake_buf_init(&buf) != PDFMAKE_OK) {
            croak("PDF::Make::Document::to_bytes: buffer init failed");
        }
        if (pdfmake_doc_write(self, &buf) != PDFMAKE_OK) {
            pdfmake_buf_free(&buf);
            croak("PDF::Make::Document::to_bytes: write failed");
        }
        RETVAL = newSVpvn((char *)buf.data, buf.len);
        pdfmake_buf_free(&buf);
    OUTPUT:
        RETVAL

void
to_file(self, path)
    pdfmake_doc_t *self
    const char *path
    CODE:
        pdfmake_buf_t buf;
        if (pdfmake_buf_init(&buf) != PDFMAKE_OK) {
            croak("PDF::Make::Document::to_file: buffer init failed");
        }
        if (pdfmake_doc_write(self, &buf) != PDFMAKE_OK) {
            pdfmake_buf_free(&buf);
            croak("PDF::Make::Document::to_file: write failed");
        }

        FILE *fp = fopen(path, "wb");
        if (!fp) {
            pdfmake_buf_free(&buf);
            croak("PDF::Make::Document::to_file: cannot open %s", path);
        }
        size_t expected = buf.len;
        size_t written = fwrite(buf.data, 1, buf.len, fp);
        fclose(fp);
        pdfmake_buf_free(&buf);

        if (written != expected) {
            croak("PDF::Make::Document::to_file: write incomplete");
        }

SV *
title(self, ...)
    pdfmake_doc_t *self
    CODE:
        if (items > 1) {
            const char *val = SvPV_nolen(ST(1));
            if (pdfmake_meta_set_title(self, val) != PDFMAKE_OK) {
                croak("PDF::Make::Document::title: failed to set title");
            }
            RETVAL = ST(1);
            SvREFCNT_inc(RETVAL);
        } else {
            const char *val = pdfmake_meta_get_title(self);
            RETVAL = val ? newSVpv(val, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
author(self, ...)
    pdfmake_doc_t *self
    CODE:
        if (items > 1) {
            const char *val = SvPV_nolen(ST(1));
            if (pdfmake_meta_set_author(self, val) != PDFMAKE_OK) {
                croak("PDF::Make::Document::author: failed to set author");
            }
            RETVAL = ST(1);
            SvREFCNT_inc(RETVAL);
        } else {
            const char *val = pdfmake_meta_get_author(self);
            RETVAL = val ? newSVpv(val, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
subject(self, ...)
    pdfmake_doc_t *self
    CODE:
        if (items > 1) {
            const char *val = SvPV_nolen(ST(1));
            if (pdfmake_meta_set_subject(self, val) != PDFMAKE_OK) {
                croak("PDF::Make::Document::subject: failed to set subject");
            }
            RETVAL = ST(1);
            SvREFCNT_inc(RETVAL);
        } else {
            const char *val = pdfmake_meta_get_subject(self);
            RETVAL = val ? newSVpv(val, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
keywords(self, ...)
    pdfmake_doc_t *self
    CODE:
        if (items > 1) {
            const char *val = SvPV_nolen(ST(1));
            if (pdfmake_meta_set_keywords(self, val) != PDFMAKE_OK) {
                croak("PDF::Make::Document::keywords: failed to set keywords");
            }
            RETVAL = ST(1);
            SvREFCNT_inc(RETVAL);
        } else {
            const char *val = pdfmake_meta_get_keywords(self);
            RETVAL = val ? newSVpv(val, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
creator(self, ...)
    pdfmake_doc_t *self
    CODE:
        if (items > 1) {
            const char *val = SvPV_nolen(ST(1));
            if (pdfmake_meta_set_creator(self, val) != PDFMAKE_OK) {
                croak("PDF::Make::Document::creator: failed to set creator");
            }
            RETVAL = ST(1);
            SvREFCNT_inc(RETVAL);
        } else {
            const char *val = pdfmake_meta_get_creator(self);
            RETVAL = val ? newSVpv(val, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
producer(self, ...)
    pdfmake_doc_t *self
    CODE:
        if (items > 1) {
            const char *val = SvPV_nolen(ST(1));
            if (pdfmake_meta_set_producer(self, val) != PDFMAKE_OK) {
                croak("PDF::Make::Document::producer: failed to set producer");
            }
            RETVAL = ST(1);
            SvREFCNT_inc(RETVAL);
        } else {
            const char *val = pdfmake_meta_get_producer(self);
            RETVAL = val ? newSVpv(val, 0) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
get_meta(self, key)
    pdfmake_doc_t *self
    const char *key
    CODE:
        const char *val = pdfmake_meta_get(self, key);
        RETVAL = val ? newSVpv(val, 0) : &PL_sv_undef;
    OUTPUT:
        RETVAL

void
set_meta(self, key, value)
    pdfmake_doc_t *self
    const char *key
    const char *value
    CODE:
        if (pdfmake_meta_set(self, key, value) != PDFMAKE_OK) {
            croak("PDF::Make::Document::set_meta: failed to set %s", key);
        }

pdfmake_page_t *
add_page(self, ...)
    pdfmake_doc_t *self
    PREINIT:
        double width = PDFMAKE_PAGE_LETTER_WIDTH;
        double height = PDFMAKE_PAGE_LETTER_HEIGHT;
    CODE:
        if (items > 1) width = SvNV(ST(1));
        if (items > 2) height = SvNV(ST(2));
        RETVAL = pdfmake_doc_add_page(self, width, height);
        if (!RETVAL)
            croak("PDF::Make::Document::add_page: failed to add page");
    OUTPUT:
        RETVAL

UV
page_count(self)
    pdfmake_doc_t *self
    CODE:
        RETVAL = pdfmake_doc_page_count(self);
    OUTPUT:
        RETVAL

pdfmake_page_t *
get_page(self, idx)
    pdfmake_doc_t *self
    UV idx
    CODE:
        RETVAL = pdfmake_doc_get_page(self, (size_t)idx);
        if (!RETVAL)
            croak("PDF::Make::Document::get_page: invalid page index %u", (unsigned)idx);
    OUTPUT:
        RETVAL

void
insert_page(self, idx, page)
    pdfmake_doc_t *self
    UV idx
    pdfmake_page_t *page
    CODE:
        pdfmake_err_t err = pdfmake_doc_insert_page(self, (size_t)idx, page);
        if (err != PDFMAKE_OK)
            croak("PDF::Make::Document::insert_page: failed to insert page");

void
remove_page(self, idx)
    pdfmake_doc_t *self
    UV idx
    CODE:
        pdfmake_err_t err = pdfmake_doc_remove_page(self, (size_t)idx);
        if (err != PDFMAKE_OK)
            croak("PDF::Make::Document::remove_page: failed to remove page %u", (unsigned)idx);

void
move_page(self, from_idx, to_idx)
    pdfmake_doc_t *self
    UV from_idx
    UV to_idx
    CODE:
        pdfmake_err_t err = pdfmake_doc_move_page(self, (size_t)from_idx, (size_t)to_idx);
        if (err != PDFMAKE_OK)
            croak("PDF::Make::Document::move_page: failed to move page %u to %u", (unsigned)from_idx, (unsigned)to_idx);

void
rotate_page(self, idx, degrees)
    pdfmake_doc_t *self
    UV idx
    IV degrees
    CODE:
        pdfmake_rotation_t rot;
        switch (degrees) {
            case 0: rot = PDFMAKE_ROTATE_0; break;
            case 90: rot = PDFMAKE_ROTATE_90; break;
            case 180: rot = PDFMAKE_ROTATE_180; break;
            case 270: rot = PDFMAKE_ROTATE_270; break;
            case -90: rot = PDFMAKE_ROTATE_270; break;
            default:
                croak("PDF::Make::Document::rotate_page: invalid rotation %d (use 0, 90, 180, 270)", (int)degrees);
        }
        pdfmake_err_t err = pdfmake_doc_rotate_page(self, (size_t)idx, rot);
        if (err != PDFMAKE_OK)
            croak("PDF::Make::Document::rotate_page: failed to rotate page %u", (unsigned)idx);

void
duplicate_page(self, idx)
    pdfmake_doc_t *self
    UV idx
    CODE:
        pdfmake_err_t err = pdfmake_doc_duplicate_page(self, (size_t)idx);
        if (err != PDFMAKE_OK)
            croak("PDF::Make::Document::duplicate_page: failed to duplicate page %u", (unsigned)idx);

UV
add_text_annot(self, x1, y1, x2, y2, contents, ...)
    pdfmake_doc_t *self
    double x1
    double y1
    double x2
    double y2
    const char *contents
    PREINIT:
        pdfmake_annot_icon_t icon = PDFMAKE_ANNOT_ICON_NOTE;
        int open = 0;
    CODE:
        if (items > 6) {
            const char *icon_str = SvPV_nolen(ST(6));
            if (strEQ(icon_str, "Comment")) icon = PDFMAKE_ANNOT_ICON_COMMENT;
            else if (strEQ(icon_str, "Key")) icon = PDFMAKE_ANNOT_ICON_KEY;
            else if (strEQ(icon_str, "Help")) icon = PDFMAKE_ANNOT_ICON_HELP;
            else if (strEQ(icon_str, "Paragraph")) icon = PDFMAKE_ANNOT_ICON_PARAGRAPH;
            else if (strEQ(icon_str, "NewParagraph")) icon = PDFMAKE_ANNOT_ICON_NEWPARAGRAPH;
            else if (strEQ(icon_str, "Insert")) icon = PDFMAKE_ANNOT_ICON_INSERT;
        }
        if (items > 7) open = SvIV(ST(7));
        
        pdfmake_rect_t rect = {x1, y1, x2, y2};
        RETVAL = pdfmake_annot_text(self, rect, contents, icon, open);
        if (RETVAL == 0)
            croak("PDF::Make::Document::add_text_annot: failed to create annotation");
    OUTPUT:
        RETVAL

UV
add_link_uri(self, x1, y1, x2, y2, uri)
    pdfmake_doc_t *self
    double x1
    double y1
    double x2
    double y2
    const char *uri
    CODE:
        pdfmake_rect_t rect = {x1, y1, x2, y2};
        RETVAL = pdfmake_annot_link_uri(self, rect, uri);
        if (RETVAL == 0)
            croak("PDF::Make::Document::add_link_uri: failed to create annotation");
    OUTPUT:
        RETVAL

UV
add_link_goto(self, x1, y1, x2, y2, dest_page)
    pdfmake_doc_t *self
    double x1
    double y1
    double x2
    double y2
    UV dest_page
    CODE:
        pdfmake_rect_t rect = {x1, y1, x2, y2};
        RETVAL = pdfmake_annot_link_goto(self, rect, (size_t)dest_page);
        if (RETVAL == 0)
            croak("PDF::Make::Document::add_link_goto: failed to create annotation");
    OUTPUT:
        RETVAL

UV
add_stamp(self, x1, y1, x2, y2, stamp_type)
    pdfmake_doc_t *self
    double x1
    double y1
    double x2
    double y2
    const char *stamp_type
    PREINIT:
        pdfmake_stamp_type_t type = PDFMAKE_STAMP_DRAFT;
    CODE:
        if (strEQ(stamp_type, "Approved")) type = PDFMAKE_STAMP_APPROVED;
        else if (strEQ(stamp_type, "Experimental")) type = PDFMAKE_STAMP_EXPERIMENTAL;
        else if (strEQ(stamp_type, "NotApproved")) type = PDFMAKE_STAMP_NOTAPPROVED;
        else if (strEQ(stamp_type, "AsIs")) type = PDFMAKE_STAMP_ASIS;
        else if (strEQ(stamp_type, "Expired")) type = PDFMAKE_STAMP_EXPIRED;
        else if (strEQ(stamp_type, "NotForPublicRelease")) type = PDFMAKE_STAMP_NOTFORPUBLICRELEASE;
        else if (strEQ(stamp_type, "Confidential")) type = PDFMAKE_STAMP_CONFIDENTIAL;
        else if (strEQ(stamp_type, "Final")) type = PDFMAKE_STAMP_FINAL;
        else if (strEQ(stamp_type, "Sold")) type = PDFMAKE_STAMP_SOLD;
        else if (strEQ(stamp_type, "Departmental")) type = PDFMAKE_STAMP_DEPARTMENTAL;
        else if (strEQ(stamp_type, "ForLegalReview")) type = PDFMAKE_STAMP_FORLEGALREVIEW;
        else if (strEQ(stamp_type, "TopSecret")) type = PDFMAKE_STAMP_TOPSECRET;
        else if (strEQ(stamp_type, "ForComment")) type = PDFMAKE_STAMP_FORCOMMENT;
        /* Default is Draft */
        
        pdfmake_rect_t rect = {x1, y1, x2, y2};
        RETVAL = pdfmake_annot_stamp(self, rect, type);
        if (RETVAL == 0)
            croak("PDF::Make::Document::add_stamp: failed to create annotation");
    OUTPUT:
        RETVAL

##############################################################################
# Outline (Bookmarks) API
##############################################################################

SV *
add_outline(self, title, page_index, dest_type = "Fit", left = 0, top = 0, zoom = 0)
    pdfmake_doc_t *self
    const char *title
    UV page_index
    const char *dest_type
    double left
    double top
    double zoom
    PREINIT:
        pdfmake_dest_t dest;
        pdfmake_outline_item_t *item;
        SV *sv;
    CODE:
        /* Build destination based on type */
        if (strEQ(dest_type, "XYZ")) {
            dest = pdfmake_dest_xyz((size_t)page_index, left, top, zoom);
        }
        else if (strEQ(dest_type, "Fit")) {
            dest = pdfmake_dest_fit((size_t)page_index);
        }
        else if (strEQ(dest_type, "FitH")) {
            dest = pdfmake_dest_fith((size_t)page_index, top);
        }
        else if (strEQ(dest_type, "FitV")) {
            dest = pdfmake_dest_fitv((size_t)page_index, left);
        }
        else if (strEQ(dest_type, "FitB")) {
            dest = pdfmake_dest_fitb((size_t)page_index);
        }
        else if (strEQ(dest_type, "FitBH")) {
            dest = pdfmake_dest_fitbh((size_t)page_index, top);
        }
        else if (strEQ(dest_type, "FitBV")) {
            dest = pdfmake_dest_fitbv((size_t)page_index, left);
        }
        else {
            dest = pdfmake_dest_fit((size_t)page_index);
        }

        item = pdfmake_doc_add_outline_root(self, title, dest);
        if (!item)
            croak("PDF::Make::Document::add_outline: failed to create outline root");

        sv = newSV(0);
        sv_setref_pv(sv, "PDF::Make::Outline", (void *)item);
        RETVAL = sv;
    OUTPUT:
        RETVAL

##############################################################################
# Action API
##############################################################################

pdfmake_action_t *
action_goto(self, page_index, dest_type = "Fit", left = 0, top = 0, zoom = 0)
    pdfmake_doc_t *self
    UV page_index
    const char *dest_type
    double left
    double top
    double zoom
    PREINIT:
        pdfmake_dest_t dest;
    CODE:
        /* Build destination based on type */
        if (strEQ(dest_type, "XYZ")) {
            dest = pdfmake_dest_xyz((size_t)page_index, left, top, zoom);
        }
        else if (strEQ(dest_type, "Fit")) {
            dest = pdfmake_dest_fit((size_t)page_index);
        }
        else if (strEQ(dest_type, "FitH")) {
            dest = pdfmake_dest_fith((size_t)page_index, top);
        }
        else if (strEQ(dest_type, "FitV")) {
            dest = pdfmake_dest_fitv((size_t)page_index, left);
        }
        else if (strEQ(dest_type, "FitB")) {
            dest = pdfmake_dest_fitb((size_t)page_index);
        }
        else if (strEQ(dest_type, "FitBH")) {
            dest = pdfmake_dest_fitbh((size_t)page_index, top);
        }
        else if (strEQ(dest_type, "FitBV")) {
            dest = pdfmake_dest_fitbv((size_t)page_index, left);
        }
        else {
            dest = pdfmake_dest_fit((size_t)page_index);
        }
        
        RETVAL = pdfmake_action_goto(self, dest);
        if (!RETVAL)
            croak("PDF::Make::Document::action_goto: failed to create action");
    OUTPUT:
        RETVAL

pdfmake_action_t *
action_uri(self, uri)
    pdfmake_doc_t *self
    const char *uri
    CODE:
        RETVAL = pdfmake_action_uri(self, uri);
        if (!RETVAL)
            croak("PDF::Make::Document::action_uri: failed to create action");
    OUTPUT:
        RETVAL

pdfmake_action_t *
action_named(self, name)
    pdfmake_doc_t *self
    const char *name
    CODE:
        RETVAL = pdfmake_action_named_str(self, name);
        if (!RETVAL)
            croak("PDF::Make::Document::action_named: unknown named action '%s'", name);
    OUTPUT:
        RETVAL

pdfmake_action_t *
action_javascript(self, script)
    pdfmake_doc_t *self
    const char *script
    CODE:
        RETVAL = pdfmake_action_javascript(self, script);
        if (!RETVAL)
            croak("PDF::Make::Document::action_javascript: failed to create action");
    OUTPUT:
        RETVAL

pdfmake_action_t *
action_gotor(self, file, page_index, new_window = 0)
    pdfmake_doc_t *self
    const char *file
    UV page_index
    int new_window
    PREINIT:
        pdfmake_dest_t dest;
    CODE:
        dest = pdfmake_dest_fit((size_t)page_index);
        RETVAL = pdfmake_action_gotor(self, file, dest, new_window);
        if (!RETVAL)
            croak("PDF::Make::Document::action_gotor: failed to create action");
    OUTPUT:
        RETVAL

UV
add_link_with_action(self, x1, y1, x2, y2, action, highlight = "Invert")
    pdfmake_doc_t *self
    double x1
    double y1
    double x2
    double y2
    pdfmake_action_t *action
    const char *highlight
    PREINIT:
        pdfmake_rect_t rect;
        pdfmake_highlight_mode_t hl;
    CODE:
        rect.x1 = x1;
        rect.y1 = y1;
        rect.x2 = x2;
        rect.y2 = y2;
        
        if (strEQ(highlight, "None")) {
            hl = PDFMAKE_HIGHLIGHT_NONE;
        }
        else if (strEQ(highlight, "Outline")) {
            hl = PDFMAKE_HIGHLIGHT_OUTLINE;
        }
        else if (strEQ(highlight, "Push")) {
            hl = PDFMAKE_HIGHLIGHT_PUSH;
        }
        else {
            hl = PDFMAKE_HIGHLIGHT_INVERT;  /* Default */
        }
        
        RETVAL = pdfmake_annot_link_action(self, rect, action, hl);
        if (RETVAL == 0)
            croak("PDF::Make::Document::add_link_with_action: failed to create link");
    OUTPUT:
        RETVAL

UV
add_link_named_action(self, x1, y1, x2, y2, name, highlight = "Invert")
    pdfmake_doc_t *self
    double x1
    double y1
    double x2
    double y2
    const char *name
    const char *highlight
    PREINIT:
        pdfmake_rect_t rect;
        pdfmake_highlight_mode_t hl;
    CODE:
        rect.x1 = x1;
        rect.y1 = y1;
        rect.x2 = x2;
        rect.y2 = y2;
        
        if (strEQ(highlight, "None")) {
            hl = PDFMAKE_HIGHLIGHT_NONE;
        }
        else if (strEQ(highlight, "Outline")) {
            hl = PDFMAKE_HIGHLIGHT_OUTLINE;
        }
        else if (strEQ(highlight, "Push")) {
            hl = PDFMAKE_HIGHLIGHT_PUSH;
        }
        else {
            hl = PDFMAKE_HIGHLIGHT_INVERT;
        }
        
        RETVAL = pdfmake_annot_link_named(self, rect, name, hl);
        if (RETVAL == 0)
            croak("PDF::Make::Document::add_link_named_action: unknown named action '%s'", name);
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_doc_t *self
    CODE:
        pdfmake_doc_free(self);

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Document", GV_ADD);
    PDFMAKE_REGISTER_META(stash, "title",    pdfmake_meta_get_title,    pdfmake_meta_set_title);
    PDFMAKE_REGISTER_META(stash, "author",   pdfmake_meta_get_author,   pdfmake_meta_set_author);
    PDFMAKE_REGISTER_META(stash, "subject",  pdfmake_meta_get_subject,  pdfmake_meta_set_subject);
    PDFMAKE_REGISTER_META(stash, "keywords", pdfmake_meta_get_keywords, pdfmake_meta_set_keywords);
    PDFMAKE_REGISTER_META(stash, "creator",  pdfmake_meta_get_creator,  pdfmake_meta_set_creator);
    PDFMAKE_REGISTER_META(stash, "producer", pdfmake_meta_get_producer, pdfmake_meta_set_producer);
}
