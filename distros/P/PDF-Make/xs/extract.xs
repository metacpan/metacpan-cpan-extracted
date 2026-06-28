MODULE = PDF::Make  PACKAGE = PDF::Make::Extract
PROTOTYPES: ENABLE

SV *
_extract_from_reader(class, reader_sv, page_index)
    char *class
    pdfmake_reader_xs_t *reader_sv
    UV page_index
    PREINIT:
        pdfmake_err_t err;
        pdfmake_arena_t *arena;
        pdfmake_interp_t *interp;
        pdfmake_textract_result_t *result;
        pdfmake_textract_options_t opts;
        pdfmake_reader_page_t *rpage;
        pdfmake_buf_t content_buf;
        pdfmake_obj_t *resources;
        char outbuf[65536];
        size_t outlen;
    CODE:
        PERL_UNUSED_VAR(class);
        pdfmake_buf_init(&content_buf);

        if (page_index >= pdfmake_reader_page_count(reader_sv->reader))
            croak("PDF::Make::Extract: page index %lu out of range", (unsigned long)page_index);

        rpage = pdfmake_reader_page_at(reader_sv->reader, page_index);
        if (!rpage)
            croak("PDF::Make::Extract: failed to get page %lu", (unsigned long)page_index);

        /* Get content stream bytes */
        err = pdfmake_reader_page_content_bytes(reader_sv->reader, rpage, &content_buf);
        if (err != PDFMAKE_OK || content_buf.len == 0) {
            pdfmake_buf_free(&content_buf);
            RETVAL = newSVpvn("", 0);
        } else {
            /* Create interpreter with resources */
            /* Use the parser's arena so name IDs match across: stream dicts,
             * font dicts (all from parser), merged resources (keys re-interned
             * here during merge), and the interpreter's own lookups. */
            arena = reader_sv->reader->parser->doc->arena;
            interp = pdfmake_interp_new(arena);
            if (!interp) {
                pdfmake_buf_free(&content_buf);
                croak("PDF::Make::Extract: failed to create interpreter");
            }
            /* Phase 7: enable Form XObject recursion */
            pdfmake_interp_set_reader(interp, reader_sv->reader);

            /* Set page resources so Tf can resolve fonts */
            resources = pdfmake_reader_page_resources(reader_sv->reader, rpage);
            if (resources) {
                pdfmake_interp_set_resources(interp, resources);
            }

            /* Run extraction */
            result = pdfmake_textract_new(arena);
            pdfmake_textract_set_reader(result, reader_sv->reader);
            opts = pdfmake_textract_default_options();
            err = pdfmake_textract_run(interp, content_buf.data, content_buf.len, &opts, result);

            pdfmake_interp_free(interp);
            pdfmake_buf_free(&content_buf);

            if (err != PDFMAKE_OK) {
                pdfmake_textract_free(result);
                croak("PDF::Make::Extract: extraction failed");
            }

            outlen = pdfmake_textract_to_utf8(result, outbuf, sizeof(outbuf) - 1);
            outbuf[outlen] = '\0';

            RETVAL = newSVpvn(outbuf, outlen);
            SvUTF8_on(RETVAL);

            pdfmake_textract_free(result);
            /* arena owned by reader; do not free here */
        }
    OUTPUT:
        RETVAL

SV *
_extract_structured(class, reader_sv, page_index, ...)
    char *class
    pdfmake_reader_xs_t *reader_sv
    UV page_index
    PREINIT:
        pdfmake_err_t err;
        pdfmake_arena_t *arena;
        pdfmake_interp_t *interp;
        pdfmake_textract_result_t *result;
        pdfmake_textract_options_t opts;
        pdfmake_reader_page_t *rpage;
        pdfmake_buf_t content_buf;
        pdfmake_obj_t *resources;
        int include_invisible = 1;  /* default: include Tr=3 text (OCR) */
    CODE:
        PERL_UNUSED_VAR(class);
        /* Optional 4th arg: include_invisible (0 or 1). */
        if (items > 3) include_invisible = (int)SvIV(ST(3));
        pdfmake_buf_init(&content_buf);

        if (page_index >= pdfmake_reader_page_count(reader_sv->reader))
            croak("PDF::Make::Extract: page index %lu out of range", (unsigned long)page_index);

        rpage = pdfmake_reader_page_at(reader_sv->reader, page_index);
        if (!rpage)
            croak("PDF::Make::Extract: failed to get page %lu", (unsigned long)page_index);

        err = pdfmake_reader_page_content_bytes(reader_sv->reader, rpage, &content_buf);
        if (err != PDFMAKE_OK || content_buf.len == 0) {
            pdfmake_buf_free(&content_buf);
            RETVAL = newRV_noinc((SV *)newAV());
        } else {
            /* Use the parser's arena so name IDs match across: stream dicts,
             * font dicts (all from parser), merged resources (keys re-interned
             * here during merge), and the interpreter's own lookups. */
            arena = reader_sv->reader->parser->doc->arena;
            interp = pdfmake_interp_new(arena);
            if (!interp) {
                pdfmake_buf_free(&content_buf);
                croak("PDF::Make::Extract: failed to create interpreter");
            }
            /* Phase 7: enable Form XObject recursion */
            pdfmake_interp_set_reader(interp, reader_sv->reader);

            resources = pdfmake_reader_page_resources(reader_sv->reader, rpage);
            if (resources)
                pdfmake_interp_set_resources(interp, resources);

            result = pdfmake_textract_new(arena);
            pdfmake_textract_set_reader(result, reader_sv->reader);
            opts = pdfmake_textract_default_options();
            opts.include_invisible = include_invisible;

            /* Phase 12: resolve /StructTreeRoot from the catalog (if the
             * PDF is tagged) so the extractor can look up structure roles
             * from MCIDs the visitor collects. */
            if (reader_sv->reader->catalog) {
                uint32_t str_key = pdfmake_arena_intern_name(
                    arena, "StructTreeRoot", 14);
                pdfmake_obj_t *str_root = pdfmake_dict_get(
                    reader_sv->reader->catalog, str_key);
                if (str_root) {
                    pdfmake_textract_resolve_struct_tree(
                        result, str_root, rpage->page_dict);
                }
            }

            err = pdfmake_textract_run(interp, content_buf.data, content_buf.len, &opts, result);

            pdfmake_interp_free(interp);
            pdfmake_buf_free(&content_buf);

            if (err != PDFMAKE_OK) {
                pdfmake_textract_free(result);
                croak("PDF::Make::Extract: extraction failed");
            }

            /* Build Perl data structure: blocks -> lines -> words -> glyphs */
            AV *blocks_av = newAV();
            for (size_t b = 0; b < result->len; b++) {
                pdfmake_text_block_t *block = &result->blocks[b];
                HV *block_hv = newHV();
                hv_stores(block_hv, "x0", newSVnv(block->x0));
                hv_stores(block_hv, "y0", newSVnv(block->y0));
                hv_stores(block_hv, "x1", newSVnv(block->x1));
                hv_stores(block_hv, "y1", newSVnv(block->y1));

                AV *lines_av = newAV();
                for (size_t l = 0; l < block->len; l++) {
                    pdfmake_text_line_t *line = &block->lines[l];
                    HV *line_hv = newHV();
                    hv_stores(line_hv, "x0", newSVnv(line->x0));
                    hv_stores(line_hv, "y0", newSVnv(line->y0));
                    hv_stores(line_hv, "x1", newSVnv(line->x1));
                    hv_stores(line_hv, "y1", newSVnv(line->y1));
                    hv_stores(line_hv, "baseline", newSVnv(line->baseline_y));

                    AV *words_av = newAV();
                    for (size_t w = 0; w < line->len; w++) {
                        pdfmake_text_word_t *word = &line->words[w];
                        HV *word_hv = newHV();
                        hv_stores(word_hv, "x0", newSVnv(word->x0));
                        hv_stores(word_hv, "y0", newSVnv(word->y0));
                        hv_stores(word_hv, "x1", newSVnv(word->x1));
                        hv_stores(word_hv, "y1", newSVnv(word->y1));

                        /* Build word text from glyphs */
                        pdfmake_buf_t wbuf;
                        pdfmake_buf_init(&wbuf);
                        double word_font_size = 0;
                        for (size_t g = 0; g < word->len; g++) {
                            pdfmake_text_glyph_t *gl = &word->glyphs[g];
                            if (gl->font_size > word_font_size)
                                word_font_size = gl->font_size;
                            /* Encode Unicode codepoint as UTF-8 */
                            uint32_t cp = gl->unicode;
                            if (cp < 0x80) {
                                pdfmake_buf_append_byte(&wbuf, (uint8_t)cp);
                            } else if (cp < 0x800) {
                                pdfmake_buf_append_byte(&wbuf, 0xC0 | (cp >> 6));
                                pdfmake_buf_append_byte(&wbuf, 0x80 | (cp & 0x3F));
                            } else if (cp < 0x10000) {
                                pdfmake_buf_append_byte(&wbuf, 0xE0 | (cp >> 12));
                                pdfmake_buf_append_byte(&wbuf, 0x80 | ((cp >> 6) & 0x3F));
                                pdfmake_buf_append_byte(&wbuf, 0x80 | (cp & 0x3F));
                            } else {
                                pdfmake_buf_append_byte(&wbuf, 0xF0 | (cp >> 18));
                                pdfmake_buf_append_byte(&wbuf, 0x80 | ((cp >> 12) & 0x3F));
                                pdfmake_buf_append_byte(&wbuf, 0x80 | ((cp >> 6) & 0x3F));
                                pdfmake_buf_append_byte(&wbuf, 0x80 | (cp & 0x3F));
                            }
                        }
                        SV *text_sv = newSVpvn((const char *)wbuf.data, wbuf.len);
                        SvUTF8_on(text_sv);
                        hv_stores(word_hv, "text", text_sv);
                        hv_stores(word_hv, "font_size", newSVnv(word_font_size));
                        pdfmake_buf_free(&wbuf);

                        /* Phase 12: expose marked-content tag for this word */
                        if (word->mcid >= 0) {
                            hv_stores(word_hv, "mcid", newSViv(word->mcid));
                            uint32_t role_id = pdfmake_textract_role_for_mcid(
                                result, word->mcid);
                            if (role_id) {
                                pdfmake_obj_t role_obj;
                                role_obj.kind = PDFMAKE_NAME;
                                role_obj.as.name.id = role_id;
                                const char *role_name =
                                    pdfmake_get_name_bytes(arena, &role_obj);
                                if (role_name) {
                                    hv_stores(word_hv, "tag",
                                        newSVpv(role_name, 0));
                                }
                            }
                        }

                        av_push(words_av, newRV_noinc((SV *)word_hv));
                    }
                    hv_stores(line_hv, "words", newRV_noinc((SV *)words_av));
                    av_push(lines_av, newRV_noinc((SV *)line_hv));
                }
                hv_stores(block_hv, "lines", newRV_noinc((SV *)lines_av));
                av_push(blocks_av, newRV_noinc((SV *)block_hv));
            }

            RETVAL = newRV_noinc((SV *)blocks_av);

            pdfmake_textract_free(result);
            /* arena owned by reader; do not free here */
        }
    OUTPUT:
        RETVAL

SV *
_detect_tables(class, reader_sv, page_index)
    char *class
    pdfmake_reader_xs_t *reader_sv
    UV page_index
    PREINIT:
        pdfmake_err_t err;
        pdfmake_arena_t *arena;
        pdfmake_interp_t *interp;
        pdfmake_textract_result_t *result;
        pdfmake_textract_options_t opts;
        pdfmake_reader_page_t *rpage;
        pdfmake_buf_t content_buf;
        pdfmake_obj_t *resources;
        pdfmake_textract_table_list_t *tlist;
    CODE:
        PERL_UNUSED_VAR(class);
        pdfmake_buf_init(&content_buf);

        if (page_index >= pdfmake_reader_page_count(reader_sv->reader))
            croak("PDF::Make::Extract: page index %lu out of range",
                  (unsigned long)page_index);

        rpage = pdfmake_reader_page_at(reader_sv->reader, page_index);
        err = pdfmake_reader_page_content_bytes(reader_sv->reader, rpage, &content_buf);
        if (err != PDFMAKE_OK || content_buf.len == 0) {
            pdfmake_buf_free(&content_buf);
            RETVAL = newRV_noinc((SV *)newAV());
        } else {
            arena = reader_sv->reader->parser->doc->arena;
            interp = pdfmake_interp_new(arena);
            if (!interp) {
                pdfmake_buf_free(&content_buf);
                croak("PDF::Make::Extract: interp alloc failed");
            }
            pdfmake_interp_set_reader(interp, reader_sv->reader);
            resources = pdfmake_reader_page_resources(reader_sv->reader, rpage);
            if (resources) pdfmake_interp_set_resources(interp, resources);

            result = pdfmake_textract_new(arena);
            pdfmake_textract_set_reader(result, reader_sv->reader);
            opts = pdfmake_textract_default_options();
            err = pdfmake_textract_run(interp, content_buf.data, content_buf.len, &opts, result);
            pdfmake_interp_free(interp);
            pdfmake_buf_free(&content_buf);
            if (err != PDFMAKE_OK) {
                pdfmake_textract_free(result);
                croak("PDF::Make::Extract: extraction failed");
            }

            tlist = pdfmake_textract_table_list_new(arena);
            pdfmake_textract_detect_tables(result, NULL, tlist);

            AV *av = newAV();
            for (size_t ti = 0; ti < tlist->len; ti++) {
                pdfmake_textract_table_t *t = &tlist->items[ti];
                HV *hv = newHV();
                hv_stores(hv, "x0", newSVnv(t->x0));
                hv_stores(hv, "y0", newSVnv(t->y0));
                hv_stores(hv, "x1", newSVnv(t->x1));
                hv_stores(hv, "y1", newSVnv(t->y1));
                hv_stores(hv, "rows", newSVuv((UV)t->rows));
                hv_stores(hv, "cols", newSVuv((UV)t->cols));

                AV *rows_av = newAV();
                for (size_t r = 0; r < t->rows; r++) {
                    AV *row_av = newAV();
                    for (size_t c = 0; c < t->cols; c++) {
                        size_t idx = r * t->cols + c;
                        const char *txt = t->cells[idx] ? t->cells[idx] : "";
                        SV *sv = newSVpv(txt, 0);
                        SvUTF8_on(sv);
                        av_push(row_av, sv);
                    }
                    av_push(rows_av, newRV_noinc((SV *)row_av));
                }
                hv_stores(hv, "cells", newRV_noinc((SV *)rows_av));

                av_push(av, newRV_noinc((SV *)hv));
            }

            pdfmake_textract_table_list_free(tlist);
            pdfmake_textract_free(result);
            RETVAL = newRV_noinc((SV *)av);
        }
    OUTPUT:
        RETVAL

SV *
_extract_annotations(class, reader_sv)
    char *class
    pdfmake_reader_xs_t *reader_sv
    PREINIT:
        pdfmake_annot_text_list_t *list;
        pdfmake_arena_t *arena;
    CODE:
        PERL_UNUSED_VAR(class);
        arena = reader_sv->reader->parser->doc->arena;
        list = pdfmake_annot_text_list_new(arena);
        if (!list) croak("PDF::Make::Extract: annot list alloc failed");

        if (pdfmake_textract_annotations(reader_sv->reader, list) != PDFMAKE_OK) {
            pdfmake_annot_text_list_free(list);
            croak("PDF::Make::Extract: annotation extraction failed");
        }

        AV *av = newAV();
        for (size_t i = 0; i < list->len; i++) {
            pdfmake_annot_text_t *r = &list->items[i];
            HV *hv = newHV();
            if (r->kind) hv_stores(hv, "kind", newSVpv(r->kind, 0));
            if (r->page_index != (size_t)-1)
                hv_stores(hv, "page", newSVuv((UV)r->page_index));
            AV *rect_av = newAV();
            for (int k = 0; k < 4; k++)
                av_push(rect_av, newSVnv(r->rect[k]));
            hv_stores(hv, "rect", newRV_noinc((SV *)rect_av));

            SV *tsv = newSVpv(r->text ? r->text : "", 0);
            SvUTF8_on(tsv);
            hv_stores(hv, "text", tsv);

            if (r->author) {
                SV *sv = newSVpv(r->author, 0);
                SvUTF8_on(sv);
                hv_stores(hv, "author", sv);
            }
            if (r->subject) {
                SV *sv = newSVpv(r->subject, 0);
                SvUTF8_on(sv);
                hv_stores(hv, "subject", sv);
            }
            if (r->field_name) {
                SV *sv = newSVpv(r->field_name, 0);
                SvUTF8_on(sv);
                hv_stores(hv, "field_name", sv);
            }

            av_push(av, newRV_noinc((SV *)hv));
        }

        pdfmake_annot_text_list_free(list);
        RETVAL = newRV_noinc((SV *)av);
    OUTPUT:
        RETVAL
