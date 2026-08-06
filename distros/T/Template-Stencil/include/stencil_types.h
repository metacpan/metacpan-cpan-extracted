#ifndef STENCIL_TYPES_H
#define STENCIL_TYPES_H

/* Capability bits: compiled-in code paths gated by runtime CPU support.
 * Reported by Template::Stencil::_stencil_built for diagnostics. */
#define STENCIL_CAP_COMPUTED_GOTO  0x01u
#define STENCIL_CAP_BUILTIN_EXPECT 0x02u
#define STENCIL_CAP_SSE2           0x04u
#define STENCIL_CAP_SSE42          0x08u
#define STENCIL_CAP_AVX2           0x10u
#define STENCIL_CAP_NEON           0x20u

/* Opcode list as an X-macro: the enum, the _inspect name table and the
 * phase 04 dispatch table are all generated from this single list so
 * they cannot drift. Operand encodings (all little-endian-native u32
 * unless stated) are documented per op; the VM reads operands with
 * memcpy for alignment safety. */
#define STENCIL_OPS(X) \
    X(SOP_END)           /* none - halt */ \
    X(SOP_LITERAL_SHORT) /* u8 len, payload inline (len 1..31) */ \
    X(SOP_LITERAL_LONG)  /* u32 pool_off, u32 len */ \
    X(SOP_PRINT_ESC)     /* none - pop value, escape, write */ \
    X(SOP_PRINT_RAW)     /* none - pop value, write */ \
    X(SOP_PUSH_PATH)     /* u32 path_id */ \
    X(SOP_PUSH_LIT_STR)  /* u32 pool_off, u32 len */ \
    X(SOP_PUSH_LIT_NUM)  /* 8-byte double */ \
    X(SOP_PUSH_UNDEF)    /* none */ \
    X(SOP_NOT)           /* none - pop, push boolean negation */ \
    X(SOP_DEFINED)       /* none - pop, push definedness */ \
    X(SOP_EQ_NUM) X(SOP_NE_NUM) X(SOP_LT_NUM) \
    X(SOP_GT_NUM) X(SOP_LE_NUM) X(SOP_GE_NUM) /* none - pop 2, push bool */ \
    X(SOP_EQ_STR) X(SOP_NE_STR) X(SOP_LT_STR) \
    X(SOP_GT_STR) X(SOP_LE_STR) X(SOP_GE_STR) /* none - pop 2, push bool */ \
    X(SOP_TEST_JF)       /* u32 target - pop, jump if false */ \
    X(SOP_TEST_JT)       /* u32 target - pop, jump if true */ \
    X(SOP_JF_KEEP)       /* u32 target - && : jump if false, keep value */ \
    X(SOP_JT_KEEP)       /* u32 target - || : jump if true, keep value */ \
    X(SOP_POP)           /* none */ \
    X(SOP_JUMP)          /* u32 target */ \
    X(SOP_FOR_ARY)       /* u32 name_id, u32 end_target - pop aggregate */ \
    X(SOP_FOR_HASH)      /* u32 key_id, u32 val_id, u32 end_target */ \
    X(SOP_FOR_NEXT)      /* u32 body_target */ \
    X(SOP_SET)           /* u32 name_id - pop, bind in scope */ \
    X(SOP_POP_BINDS)     /* u32 count - drop newest binds (block end) */ \
    X(SOP_INCLUDE)       /* u32 include_id (linked in phase 05) */ \
    X(SOP_CONTENT)       /* none - wrapper slot (phase 05) */ \
    X(SOP_FILTER)        /* u32 filter_id (semantics in phase 06) */

typedef enum stencil_op {
#define STENCIL_X_ENUM(n) n,
    STENCIL_OPS(STENCIL_X_ENUM)
#undef STENCIL_X_ENUM
    SOP__MAX
} stencil_op;

struct stencil_buf; /* phase 02 */

/* Escape src[0..n) into the buffer, return bytes written. */
typedef size_t (*stencil_escape_fn)(struct stencil_buf *b,
                                    const char *src, size_t n);

/* Return a pointer to the next '{' in [p, end), or end when none. */
typedef const char *(*stencil_scan_fn)(const char *p, const char *end);

/* Filled exactly once by stencil_boot(); every hot path calls through
 * these pointers - no per-call feature checks anywhere. */
typedef struct stencil_dispatch {
    stencil_escape_fn escape;
    stencil_scan_fn   scan;
    uint32_t          caps;
    int               force_switch; /* STENCIL_FORCE_SWITCH env at boot */
} stencil_dispatch_t;

extern stencil_dispatch_t stencil_dispatch;

void stencil_boot(pTHX);

#endif /* STENCIL_TYPES_H */
