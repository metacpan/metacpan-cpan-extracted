
#include "CircularPath.h"

CircularPath::CircularPath
    (Vector2i center, int radius, float from_angle, float to_angle) :
    center(center),
    radius(radius),
    from_angle(from_angle),
    to_angle(to_angle),
    angle_delta(to_angle - from_angle) {}

Vector2i CircularPath::solve(float t) {
    float    angle = from_angle + angle_delta * t;
    Vector2f dir   = { { cos(angle), sin(angle) } };
    return center + dir * radius;
}


