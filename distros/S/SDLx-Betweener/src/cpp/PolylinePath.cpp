
#include <algorithm>
#include "PolylinePath.h"

PolylinePath::PolylinePath(std::vector<Vector2i> points) {
    segments.reserve(points.size()); 
    float total_len = 0;
    std::vector<Vector2i>::iterator pit = points.begin(); 
    Vector2i p0 = *pit;
    pit++;
    for (;pit != points.end(); pit++) {
        Vector2i p1 = *pit;
        float len   = distance(p0, p1);
        total_len  += len;
        segments.push_back(PolylineSegment(p0, p1, len));
        p0 = p1;
    }
    float progress = 0;
    for (std::vector<PolylineSegment>::iterator sit = segments.begin();
         sit != segments.end(); sit++
    ) {
        float ratio    = sit->len / total_len;
        progress      += ratio;
        sit->progress  = progress;
        sit->ratio     = ratio;
    }
}

Vector2i PolylinePath::solve(float t) {
    std::vector<PolylineSegment>::iterator it = std::lower_bound(
        segments.begin(),
        segments.end(),
        t
    );
    PolylineSegment segment = it == segments.end()?
                                    segments[segments.size()-1]:
                                    *it;

    float r  = segment.ratio;
    float p1 = segment.progress;
    float p0 = p1 - r;
    float tn = (t - p0) / r;

    return segment.solve(tn);
}



