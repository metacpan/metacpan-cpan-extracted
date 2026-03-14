/*
#define GL_NO_ERROR                      0
#define GL_INVALID_ENUM                  0x0500
#define GL_INVALID_VALUE                 0x0501
#define GL_INVALID_OPERATION             0x0502
#define GL_STACK_OVERFLOW                0x0503
#define GL_STACK_UNDERFLOW               0x0504
#define GL_OUT_OF_MEMORY                 0x0505
#define GL_INVALID_FRAMEBUFFER_OPERATION 0x0506
#define GL_CONTEXT_LOST                  0x0507
*/

const char* const gl_error_symbol_strings[] = {
    "GL_NO_ERROR",
    "GL_INVALID_ENUM",
    "GL_INVALID_VALUE",
    "GL_INVALID_OPERATION",
    "GL_STACK_OVERFLOW",
    "GL_STACK_UNDERFLOW",
    "GL_OUT_OF_MEMORY",
    "GL_INVALID_FRAMEBUFFER_OPERATION",
    "GL_CONTEXT_LOST",
};

int is_gl_error(int rval) {
    if (!(rval & 0x0507)) return 0;
    return (rval & 0x07) + 1;
}

const char* gl_error_string(int err) {
    return gl_error_symbol_strings[is_gl_error(err)];
}
