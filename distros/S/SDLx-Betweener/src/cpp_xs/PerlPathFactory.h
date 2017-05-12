
#ifndef PERLPATHFACTORY_H
#define PERLPATHFACTORY_H

#include <vector>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "VectorTypes.h"
#include "IPath.h"
#include "LinearPath.h"
#include "CircularPath.h"
#include "PolylinePath.h"

Vector2i av_to_vec_2D(SV *rv) {
    AV*      arr = (AV*) SvRV(rv);
    SV**     e1  = av_fetch(arr, 0, 0);
    SV**     e2  = av_fetch(arr, 1, 0);
    Vector2i v   = { {(int) SvIV(*e1), (int) SvIV(*e2)} };
    return v;
}

IPath *Build_Path_Linear(SV *path_args) {
    HV* args      = (HV*) SvRV(path_args);
    SV** from_sv  = hv_fetch(args, "from", 4, 0);
    SV** to_sv    = hv_fetch(args, "to"  , 2, 0);
    Vector2i from = av_to_vec_2D(*from_sv);
    Vector2i to   = av_to_vec_2D(*to_sv);
    return new LinearPath(from, to);
}

IPath *Build_Path_Circular(SV *path_args) {
    HV*  args       = (HV*) SvRV(path_args);
    SV** center     = hv_fetch(args, "center", 6, 0);
    SV** radius     = hv_fetch(args, "radius", 6, 0);
    SV** from_angle = hv_fetch(args, "from"  , 4, 0);
    SV** to_angle   = hv_fetch(args, "to"    , 2, 0);
    return new CircularPath(
        av_to_vec_2D(*center),
        (int)   SvIV(*radius),
        (float) SvNV(*from_angle),
        (float) SvNV(*to_angle)
    );
}

IPath *Build_Path_Polyline(SV *path_args) {
    AV* args = (AV*) SvRV(path_args);
    int len  = av_len(args) + 1;
    std::vector<Vector2i> points(len);
    int i;
    for (i = 0; i < len; i++) {
        SV** point_arr_ref = av_fetch(args, i, 0);
        Vector2i point = av_to_vec_2D(*point_arr_ref);
        points[i] = point;
    }
    return new PolylinePath(points);
}

static IPath* (*Path_Table[3]) (SV*) = {
    Build_Path_Linear,
    Build_Path_Circular,
    Build_Path_Polyline
};

IPath *Build_Path(int path_type, SV *path_args) {
    return Path_Table[path_type](path_args);
}

#endif
