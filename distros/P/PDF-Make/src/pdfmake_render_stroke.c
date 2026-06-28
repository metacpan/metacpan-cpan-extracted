/*
 * pdfmake_render_stroke.c - Minimal stroke support
 *
 * Provides the declared stroke API so render/text callers link correctly.
 * Current implementation uses a conservative fill-path fallback until a
 * full geometric stroker lands.
 */

#include "pdfmake_render.h"

pdfmake_path_t *pdfmake_stroke_to_path(
	pdfmake_path_t *path,
	pdfmake_stroke_style_t *style)
{
	(void)style;

	if (!path || pdfmake_path_is_empty(path)) {
		return NULL;
	}

	return pdfmake_path_flatten(path, 0.5);
}

pdfmake_render_err_t pdfmake_stroke_path(
	pdfmake_render_ctx_t *ctx,
	pdfmake_path_t *path,
	pdfmake_stroke_style_t *style)
{
	(void)style;

	if (!ctx || !path) {
		return PDFMAKE_RENDER_ERR_NULL;
	}

	if (pdfmake_path_is_empty(path)) {
		return PDFMAKE_RENDER_ERR_EMPTY_PATH;
	}

	return pdfmake_fill_path(ctx, path, PDFMAKE_FILL_NONZERO);
}

pdfmake_render_err_t pdfmake_render_stroke(pdfmake_render_ctx_t *ctx)
{
	pdfmake_render_err_t err;

	if (!ctx) {
		return PDFMAKE_RENDER_ERR_NULL;
	}

	err = pdfmake_stroke_path(ctx, ctx->path, &ctx->stroke_style);
	pdfmake_path_clear(ctx->path);
	return err;
}

pdfmake_render_err_t pdfmake_render_stroke_preserve(pdfmake_render_ctx_t *ctx)
{
	if (!ctx) {
		return PDFMAKE_RENDER_ERR_NULL;
	}

	return pdfmake_stroke_path(ctx, ctx->path, &ctx->stroke_style);
}
