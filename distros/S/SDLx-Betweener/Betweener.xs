
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

MODULE = SDLx::Betweener         PACKAGE = SDLx::Betweener

INCLUDE: src/xs/Timeline.xs
INCLUDE: src/xs/Tween.xs
INCLUDE: src/xs/Seeker.xs

MODULE = SDLx::Betweener         PACKAGE = SDLx::Betweener
