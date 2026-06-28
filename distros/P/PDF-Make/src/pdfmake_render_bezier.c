/*
 * pdfmake_render_bezier.c - Bezier curve flattening
 *
 * Converts cubic Bezier curves to line segments using adaptive subdivision.
 * The flatness tolerance controls the maximum deviation from the true curve.
 */

#include "pdfmake_render.h"
#include <stdlib.h>
#include <math.h>

/*
 * Calculate squared distance from point to line segment
 */
static double point_line_distance_sq(
    pdfmake_point_t p,
    pdfmake_point_t a,
    pdfmake_point_t b)
{
    double dx = b.x - a.x;
    double dy = b.y - a.y;
    double len_sq = dx * dx + dy * dy;
    double t, cx, cy;

    if (len_sq < 1e-10) {
        /* Line segment is a point */
        dx = p.x - a.x;
        dy = p.y - a.y;
        return dx * dx + dy * dy;
    }

    /* Project point onto line */
    t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / len_sq;

    /* Clamp t to [0, 1] */
    if (t < 0) t = 0;
    if (t > 1) t = 1;

    /* Calculate closest point on segment */
    cx = a.x + t * dx;
    cy = a.y + t * dy;

    dx = p.x - cx;
    dy = p.y - cy;
    return dx * dx + dy * dy;
}

/*
 * Check if curve is flat enough
 * Returns 1 if flat, 0 if needs subdivision
 */
static int is_flat_enough(
    pdfmake_point_t p0, pdfmake_point_t p1,
    pdfmake_point_t p2, pdfmake_point_t p3,
    double tolerance)
{
    double tolerance_sq = tolerance * tolerance;
    
    /* Check distance of control points from chord */
    double d1_sq = point_line_distance_sq(p1, p0, p3);
    double d2_sq = point_line_distance_sq(p2, p0, p3);
    
    return (d1_sq <= tolerance_sq && d2_sq <= tolerance_sq);
}

/*
 * Subdivide cubic Bezier at t=0.5
 */
static void subdivide_bezier(
    pdfmake_point_t p0, pdfmake_point_t p1,
    pdfmake_point_t p2, pdfmake_point_t p3,
    pdfmake_point_t *left,   /* 4 points for left half */
    pdfmake_point_t *right)  /* 4 points for right half */
{
    /* De Casteljau's algorithm at t=0.5 */
    pdfmake_point_t q0, q1, q2;
    pdfmake_point_t r0, r1;
    pdfmake_point_t s;
    
    /* First level */
    q0.x = (p0.x + p1.x) * 0.5;
    q0.y = (p0.y + p1.y) * 0.5;
    q1.x = (p1.x + p2.x) * 0.5;
    q1.y = (p1.y + p2.y) * 0.5;
    q2.x = (p2.x + p3.x) * 0.5;
    q2.y = (p2.y + p3.y) * 0.5;
    
    /* Second level */
    r0.x = (q0.x + q1.x) * 0.5;
    r0.y = (q0.y + q1.y) * 0.5;
    r1.x = (q1.x + q2.x) * 0.5;
    r1.y = (q1.y + q2.y) * 0.5;
    
    /* Third level - midpoint */
    s.x = (r0.x + r1.x) * 0.5;
    s.y = (r0.y + r1.y) * 0.5;
    
    /* Left half: p0, q0, r0, s */
    left[0] = p0;
    left[1] = q0;
    left[2] = r0;
    left[3] = s;
    
    /* Right half: s, r1, q2, p3 */
    right[0] = s;
    right[1] = r1;
    right[2] = q2;
    right[3] = p3;
}

/*
 * Recursive flattening helper
 */
static pdfmake_render_err_t flatten_recursive(
    pdfmake_point_t p0, pdfmake_point_t p1,
    pdfmake_point_t p2, pdfmake_point_t p3,
    double tolerance,
    pdfmake_path_t *out,
    int depth)
{
    pdfmake_point_t left[4], right[4];
    pdfmake_render_err_t err;

    /* Prevent infinite recursion */
    if (depth > 20) {
        return pdfmake_path_line_to(out, p3.x, p3.y);
    }

    if (is_flat_enough(p0, p1, p2, p3, tolerance)) {
        /* Curve is flat enough, output line to endpoint */
        return pdfmake_path_line_to(out, p3.x, p3.y);
    }

    /* Subdivide and recurse */
    subdivide_bezier(p0, p1, p2, p3, left, right);

    err = flatten_recursive(left[0], left[1], left[2], left[3], 
                           tolerance, out, depth + 1);
    if (err != PDFMAKE_RENDER_OK) {
        return err;
    }

    err = flatten_recursive(right[0], right[1], right[2], right[3], 
                           tolerance, out, depth + 1);
    return err;
}

/*
 * Flatten cubic Bezier to line segments
 */
pdfmake_render_err_t pdfmake_bezier_flatten(
    pdfmake_point_t p0, pdfmake_point_t p1,
    pdfmake_point_t p2, pdfmake_point_t p3,
    double tolerance,
    pdfmake_path_t *out)
{
    if (!out) {
        return PDFMAKE_RENDER_ERR_NULL;
    }
    
    if (tolerance <= 0) {
        tolerance = 0.5;  /* Default tolerance */
    }
    
    /* First point should already be set by caller (move_to) */
    return flatten_recursive(p0, p1, p2, p3, tolerance, out, 0);
}

/*
 * Flatten entire path (convert curves to lines)
 */
pdfmake_path_t *pdfmake_path_flatten(pdfmake_path_t *path, double tolerance) {
    pdfmake_path_t *flat;
    pdfmake_point_t current = {0, 0};
    pdfmake_point_t subpath_start = {0, 0};
    int has_current = 0;
    size_t i;

    if (!path) {
        return NULL;
    }

    flat = pdfmake_path_create();
    if (!flat) {
        return NULL;
    }

    if (tolerance <= 0) {
        tolerance = 0.5;
    }

    for (i = 0; i < path->seg_count; i++) {
        pdfmake_path_seg_t *seg = &path->segs[i];
        pdfmake_render_err_t err;
        
        switch (seg->op) {
            case PDFMAKE_PATH_MOVE:
                err = pdfmake_path_move_to(flat, seg->pts[0].x, seg->pts[0].y);
                if (err != PDFMAKE_RENDER_OK) {
                    pdfmake_path_destroy(flat);
                    return NULL;
                }
                current = seg->pts[0];
                subpath_start = current;
                has_current = 1;
                break;
                
            case PDFMAKE_PATH_LINE:
                if (!has_current) {
                    pdfmake_path_move_to(flat, seg->pts[0].x, seg->pts[0].y);
                    current = seg->pts[0];
                    has_current = 1;
                } else {
                    err = pdfmake_path_line_to(flat, seg->pts[0].x, seg->pts[0].y);
                    if (err != PDFMAKE_RENDER_OK) {
                        pdfmake_path_destroy(flat);
                        return NULL;
                    }
                    current = seg->pts[0];
                }
                break;
                
            case PDFMAKE_PATH_CURVE:
                if (!has_current) {
                    pdfmake_path_move_to(flat, seg->pts[0].x, seg->pts[0].y);
                    current = seg->pts[0];
                    has_current = 1;
                }
                
                /* Flatten the curve */
                err = pdfmake_bezier_flatten(
                    current, seg->pts[0], seg->pts[1], seg->pts[2],
                    tolerance, flat);
                if (err != PDFMAKE_RENDER_OK) {
                    pdfmake_path_destroy(flat);
                    return NULL;
                }
                current = seg->pts[2];
                break;
                
            case PDFMAKE_PATH_CLOSE:
                err = pdfmake_path_close(flat);
                if (err != PDFMAKE_RENDER_OK) {
                    pdfmake_path_destroy(flat);
                    return NULL;
                }
                current = subpath_start;
                break;
        }
    }
    
    return flat;
}

/*
 * Evaluate cubic Bezier at parameter t
 */
pdfmake_point_t pdfmake_bezier_eval(
    pdfmake_point_t p0, pdfmake_point_t p1,
    pdfmake_point_t p2, pdfmake_point_t p3,
    double t)
{
    double t2 = t * t;
    double t3 = t2 * t;
    double mt = 1 - t;
    double mt2 = mt * mt;
    double mt3 = mt2 * mt;
    
    pdfmake_point_t result;
    result.x = mt3 * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3 * p3.x;
    result.y = mt3 * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3 * p3.y;
    
    return result;
}

/*
 * Calculate tangent at parameter t
 */
pdfmake_point_t pdfmake_bezier_tangent(
    pdfmake_point_t p0, pdfmake_point_t p1,
    pdfmake_point_t p2, pdfmake_point_t p3,
    double t)
{
    double t2 = t * t;
    double mt = 1 - t;
    double mt2 = mt * mt;
    
    /* Derivative of cubic Bezier */
    pdfmake_point_t result;
    result.x = 3 * mt2 * (p1.x - p0.x) + 6 * mt * t * (p2.x - p1.x) + 3 * t2 * (p3.x - p2.x);
    result.y = 3 * mt2 * (p1.y - p0.y) + 6 * mt * t * (p2.y - p1.y) + 3 * t2 * (p3.y - p2.y);
    
    return result;
}

/*
 * Calculate approximate arc length of cubic Bezier
 * Uses chord length as approximation (good for flat curves)
 */
double pdfmake_bezier_length(
    pdfmake_point_t p0, pdfmake_point_t p1,
    pdfmake_point_t p2, pdfmake_point_t p3,
    double tolerance)
{
    pdfmake_path_t *flat;
    double length = 0;
    pdfmake_point_t prev = p0;
    size_t i;

    /* Simple approach: flatten and sum segment lengths */
    flat = pdfmake_path_create();
    if (!flat) {
        /* Fallback: chord length */
        double dx = p3.x - p0.x;
        double dy = p3.y - p0.y;
        return sqrt(dx * dx + dy * dy);
    }

    pdfmake_path_move_to(flat, p0.x, p0.y);
    pdfmake_bezier_flatten(p0, p1, p2, p3, tolerance, flat);

    for (i = 1; i < flat->seg_count; i++) {
        pdfmake_path_seg_t *seg = &flat->segs[i];
        if (seg->op == PDFMAKE_PATH_LINE) {
            double dx = seg->pts[0].x - prev.x;
            double dy = seg->pts[0].y - prev.y;
            length += sqrt(dx * dx + dy * dy);
            prev = seg->pts[0];
        }
    }

    pdfmake_path_destroy(flat);
    return length;
}
