#pragma once
#include <xs/xs.h>
#include <panda/refcnt.h>

using panda::shared_ptr;
using panda::RefCounted;
using xs::XSBackref;

static int dcnt = 0;

#include "orefs.h"
#include "mybase.h"
#include "myrefcounted.h"
#include "mystatic.h"
#include "myother.h"
#include "mixin.h"
#include "mythreads.h"
#include "wrap.h"
#include "backref.h"
