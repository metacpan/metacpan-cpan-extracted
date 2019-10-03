#pragma once

#define DEBUG_MODE 0
#if DEBUG_MODE
#  define DEBUG_OUT(msg, ...) printf("%s(): " msg, __func__, ## __VA_ARGS__)
#else
#  define DEBUG_OUT(msg, ...) /* printf("%s(): " msg, __func__, ## __VA_ARGS__) */
#endif
