#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sys/time.h>

/* Doesn't seem to exist before 5.14 */
#ifndef OP_CLASS
#define OP_CLASS(o) (PL_opargs[(o)->op_type] & OA_CLASS_MASK)
#endif

enum {
    EVENT_KEYFRAME = 0,
    EVENT_SWITCH_FILE,
    EVENT_NEXT_STATEMENT,
    EVENT_DIE,
    EVENT_ENTER_SUB,
    EVENT_TZ,
    EVENT_PADSV,
    EVENT_LEAVE_SUB,
    EVENT_TZ_USEC,
};

typedef enum Event Event;

#define CONTINOUS_STORE    0x1  /* Write actual writing of buffer to disk, should be disabled when DUMP_BUFFER_ON_DIE is on */
#define DUMP_BUFFER_ON_DIE 0x2  /* Dump the buffer to disk when a OP_DIE is enountered */

#define DATA_BUFFER_SIZE 65536
#define DATA_BUFFER_MAX 65500

static unsigned int data_buffer_size = DATA_BUFFER_SIZE;
static unsigned int data_buffer_max = DATA_BUFFER_MAX;

static U32 options;

static char* data_buffer_base;
static char* data_buffer;
static char* data_buffer_wrap;

#define WRITE_EVENT(x,y,z) \
    if (data_buffer - data_buffer_base > data_buffer_max) { \
        if (options & CONTINOUS_STORE) \
            PerlIO_write(data_io, data_buffer_base, data_buffer - data_buffer_base); \
        data_buffer_wrap = data_buffer; \
        data_buffer = data_buffer_base; \
    } \
    *data_buffer = x; \
    Copy(&y, data_buffer + 1, 1, z); \
    data_buffer += sizeof(z) + 1;

/*
 This is so our tailing viewer knows where to start. It's inserted 
 here and there
*/
const char* KEYFRAME_DATA = "\0\0\0\0\0";

#define WRITE_KEYFRAME \
    if (data_buffer - data_buffer_base > data_buffer_max) { \
        if (options & CONTINOUS_STORE) \
            PerlIO_write(data_io, data_buffer_base, data_buffer - data_buffer_base); \
        data_buffer_wrap = data_buffer; \
        data_buffer = data_buffer_base; \
    } \
    Copy(KEYFRAME_DATA, data_buffer, 5, char); \
    data_buffer += 5; \

/* Where the recording go */
static PerlIO* data_io = NULL;

/* Where the source files go */
static HV* seen_identifier;
static PerlIO* identifiers_io = NULL;

static const char* base_dir;
static size_t base_dir_len;

static const char *prev_cop_file = NULL;

static uint32_t curr_file_id = 0;
static uint32_t next_identifier_id = 1;

static uint32_t last_seen_identifier = 0;
static uint32_t last_seen_entersub = 0;

static bool is_initial_recorder = TRUE;

int runops_recorder(pTHX);
static const char *create_path(const char *);
static void dump_buffer(const char *);
static void open_recording_files();
static uint32_t get_identifier(const char *);
static void record_tz();
static void record_COP(COP *);
static void record_OP_ENTERSUB(UNOP *);

static uint16_t keyframe_counter = 0x400;

static inline void check_and_insert_keyframe() {
    
    if (keyframe_counter & 0x400) {
        WRITE_KEYFRAME;
        if (curr_file_id) {
            WRITE_EVENT(EVENT_SWITCH_FILE, curr_file_id, uint32_t);
        }
        
        record_tz();
        
        keyframe_counter = 0;
    }

    keyframe_counter++;

}

static void record_tz() {
    struct timeval tp;
    if (gettimeofday(&tp, NULL) == 0) {
        WRITE_EVENT(EVENT_TZ, tp.tv_sec, uint32_t);
        WRITE_EVENT(EVENT_TZ_USEC, tp.tv_usec, uint32_t);
    }    
}

static const char* create_path(const char *filename) {
    char *path;
    size_t filename_len = strlen(filename);

    Newxz(path, base_dir_len + filename_len + 2, char);
    Copy(base_dir, path, base_dir_len, char);
    Copy(filename, path + base_dir_len + 1, filename_len, char);
    path[base_dir_len] = '/';

    return (const char *) path;
}

void open_recording_files() {
    pid_t pid = getpid();
    const char *fn;
    
    if (data_io != NULL) {
        PerlIO_close(data_io);
    }
    
    if (options & CONTINOUS_STORE) {
        fn = create_path(is_initial_recorder == TRUE ? "main.data" : Perl_form("%d.data", pid));
        data_io = PerlIO_open(fn, "w");
        check_and_insert_keyframe();
        Safefree(fn);
    }
    
    if (identifiers_io != NULL) {
        PerlIO_close(identifiers_io);
    }
    
    fn = create_path(is_initial_recorder == TRUE ? "main.identifiers" : Perl_form("%d.identifiers", pid));
    identifiers_io = PerlIO_open(fn, "w");
    get_identifier("(unknown identifier)");
    Safefree(fn);
}

void finish_recording() {
    if (data_buffer - data_buffer_base > 0 && options & CONTINOUS_STORE) {
        const char *fn = create_path(is_initial_recorder == TRUE ? "main.data" : Perl_form("%d.data", getpid()));
        data_io = PerlIO_open(fn, "a");
        Safefree(fn);
        PerlIO_write(data_io, data_buffer_base, data_buffer - data_buffer_base);        
        PerlIO_flush(data_io);
        PerlIO_close(data_io);
    }
}

static uint32_t get_identifier(const char *identifier) {
    uint32_t identifier_id;
    STRLEN len = strlen(identifier);
    
    if (!hv_exists(seen_identifier, identifier, len)) {
        identifier_id = next_identifier_id++;
        hv_store(seen_identifier, identifier, len, newSViv(identifier_id), 0);
        PerlIO_printf(identifiers_io, "%d:%s\n", identifier_id, identifier);
    }
    else {
        SV** sv = hv_fetch(seen_identifier, identifier, len, 0);
        if (sv != NULL) {
            identifier_id = SvIV(*sv);
        }
        else {
            /* Store failed, do something clever */
            identifier_id = 0;
        }
    }

    return identifier_id;
}

static void record_switch_file(const char *cop_file) {
    curr_file_id = get_identifier(cop_file);        
    prev_cop_file = cop_file;
    
    WRITE_EVENT(EVENT_SWITCH_FILE, curr_file_id, uint32_t);
}

static void record_COP(COP *cop) {
    const char *cop_file = CopFILE(cop);
    line_t cop_line = CopLINE(cop);
    
    if (prev_cop_file != cop_file && cop_file != NULL) {
        record_switch_file(cop_file);
    }    

    WRITE_EVENT(EVENT_NEXT_STATEMENT, cop_line, uint32_t);
            
    check_and_insert_keyframe();
}

static void record_OP_ENTERSUB(UNOP *op) {
    const PERL_CONTEXT *cx = caller_cx(0, NULL);
    if (cx != NULL && CxTYPE(cx) == CXt_SUB) {
        const GV *gv = CvGV(cx->blk_sub.cv);
        if (isGV(gv)) {
            last_seen_entersub = get_identifier(Perl_form("%s::%s", HvNAME(GvSTASH(gv)), GvNAME(gv)));
            WRITE_EVENT(EVENT_ENTER_SUB, last_seen_entersub, uint32_t);
        }
        else {
            last_seen_entersub = 0;
        }
    }
}

static void record_OP_LEAVESUB(UNOP *op) {
    if (last_seen_entersub) {
        WRITE_EVENT(EVENT_LEAVE_SUB, last_seen_entersub, uint32_t);
    }
}

static void dump_buffer(const char *name) {
    const char *fn = create_path(name);
    
    PerlIO *io = PerlIO_open(fn, "w");     
    /* If we've wrapped we need to write the tail first */
    if (data_buffer_wrap != NULL) {
        PerlIO_write(io, KEYFRAME_DATA, 5);
        PerlIO_write(io, data_buffer, data_buffer_wrap - data_buffer);
    }       
    PerlIO_write(io, KEYFRAME_DATA, 5);
    PerlIO_write(io, data_buffer_base, data_buffer - data_buffer_base);
    PerlIO_flush(io);
    PerlIO_close(io);    
    
    Safefree(fn);
}

static uint32_t empty = 0;
static void record_OP_DIE(LISTOP *op) {
    record_tz();
    WRITE_EVENT(EVENT_DIE, empty, uint32_t);
    if (options & DUMP_BUFFER_ON_DIE) {
        /* TODO: dump buffer */
        struct timeval tp;
        if (gettimeofday(&tp, NULL) == 0) {
            unsigned int sec = tp.tv_sec;
            unsigned int usec = tp.tv_usec;
            dump_buffer(Perl_form("died-%u.%d.data", sec, usec));

        }
    }
}

static void handle_OP_PADSV(PADOP *op) {
    CV *cv = find_runcv(NULL);
    AV *names = (AV *) *av_fetch(CvPADLIST(cv), 0, 0);
    last_seen_identifier = get_identifier(SvPV_nolen(AvARRAY(names)[PL_op->op_targ]));
}

int runops_recorder(pTHX) {
    dVAR;
    OP *prev_op;    
    PERL_BITFIELD16 op_type;
    
    while (PL_op) {
        if (OP_CLASS(PL_op) == OA_COP) {
            record_COP(cCOPx(PL_op));
        }

        op_type = PL_op->op_type;
        
        switch(op_type) {            
            case OP_DIE:
                record_OP_DIE(cLISTOPx(PL_op));            
                break;
            
            case OP_PADSV:
                handle_OP_PADSV(cPADOPx(PL_op));
                break;            
        }
            
        /* Perform the op */
        PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX);    

        /* Maybe perform something */
        switch(op_type) {
            case OP_ENTERSUB:
                record_OP_ENTERSUB(cUNOPx(PL_op));
            break;            
            
            case OP_LEAVESUB:
                 OP_LEAVESUBLV:
                 record_OP_LEAVESUB(cUNOPx(PL_op));
            break;
        }

        PERL_ASYNC_CHECK();
    }
    
    TAINT_NOT;
    return 0;
}

void init_recorder() {
    seen_identifier = newHV();
    Newxz(data_buffer_base, data_buffer_size, char);
    data_buffer = data_buffer_base;
    open_recording_files();
    atexit(finish_recording);
    
    PL_runops = runops_recorder;
}

MODULE = Runops::Recorder		PACKAGE = Runops::Recorder		

void
set_target_dir(path)
    SV *path;
    PREINIT:
        STRLEN len;
    CODE:
        base_dir = SvPV(path, len);       
        base_dir_len = (size_t) len;
         
void
set_buffer_size(size)
    unsigned int size;
    CODE:
        if (size < 128) {
            size = 128;
        }
        data_buffer_size = size;
        data_buffer_max  = size - 10;
        data_buffer_wrap = NULL;
        
void
set_options(new_opts)
    U32 new_opts;
    CODE:
        options = new_opts;

void
init_recorder()
    CODE:
        init_recorder();
        
void
dump(name)
    const char *name;
    CODE:
        if (strncmp(name + strlen(name) - 5, ".data", 5) == 0) {
            dump_buffer(name);
        }
        else {
            dump_buffer(Perl_form("%s.data", name));
        }
        