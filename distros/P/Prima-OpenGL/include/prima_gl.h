#ifdef __cplusplus
extern "C" {
#endif

#define GLREQ_TARGET_APPLICATION 0
#define GLREQ_TARGET_WINDOW      1
#define GLREQ_TARGET_BITMAP      2
#define GLREQ_TARGET_IMAGE       3
#define GLREQ_TARGET_PRINTER     4

#define GLREQ_RENDER_DIRECT     1
#define GLREQ_RENDER_XSERVER    2

#define GLREQ_PIXEL_RGBA        1
#define GLREQ_PIXEL_PALETTE     2

#define GLREQ_BUFFER_SINGLE     1
#define GLREQ_BUFFER_DOUBLE     2

#define GLREQ_DONTCARE          0
#define GLREQ_TRUE              1
#define GLREQ_FALSE             2

/* the struct is defined so that if a field is 0, it is not requested, and is left for default system value */
typedef struct {
	int target;         /* GLREQ_TARGET */
	int render;         /* GLREQ_RENDER */
	int pixels;         /* GLREQ_PIXEL  */
	int layer;          /* layer number */

	/* GLREQ_GENERIC  */
	int double_buffer;  
	int stereo;
	
	/* 0 or request( 1 to 64 ) */
	int color_bits;     
	int aux_buffers;
	int red_bits;
	int green_bits;
	int blue_bits;
	int alpha_bits;
	int depth_bits;
	int stencil_bits;
	int accum_red_bits;
	int accum_green_bits;
	int accum_blue_bits;
	int accum_alpha_bits;
} GLRequest;

Handle
gl_context_create( Handle widget, GLRequest * request);

void
gl_context_destroy( Handle context);

Bool
gl_context_make_current( Handle context);

Bool
gl_flush( Handle context);

int 
gl_context_push(void);

int 
gl_context_pop(void);

char *
gl_error_string(char * buf, int len);

#define CONTEXT_STACK_SIZE 32

#ifdef __cplusplus
}
#endif

