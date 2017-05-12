#ifndef PIGDEBUG_H
#define PIGDEBUG_H

/*
 * Macros for outputting debugging information
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#define PIGDEBUG_SYMBOL	 0x0001
#define PIGDEBUG_INIT	 0x0002
#define PIGDEBUG_SIGSLOT 0x0004

#if PIGDEBUG & PIGDEBUG_SYMBOL
#define PIG_DEBUG_SYMBOL(args) warn args
#else
#define PIG_DEBUG_SYMBOL(args)
#endif

#if PIGDEBUG & PIGDEBUG_INIT
#define PIG_DEBUG_INIT(args) warn args
#else
#define PIG_DEBUG_INIT(args)
#endif

#endif  // PIGDEBUG_H
