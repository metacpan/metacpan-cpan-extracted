#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "xs/protobuf/arena.h"
#include "xs/protobuf/message.h"
#include "xs/protobuf/utils.h"
#include "xs/descriptor_pool/pool.h"
#include "upb/mem/arena.h"
#include "upb/mem/alloc.h"
#include "upb/wire/encode.h"
#include "upb/wire/decode.h"

#ifndef _WIN32
#include <sys/mman.h>
#include <unistd.h>
#endif
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

static bool _use_guard_pages() {
#ifdef _WIN32
    return false;
#else
    static int val = -1;
    if (val == -1) {
        const char* env = getenv("PROTOBUF_PERL_USE_GUARD_PAGES");
        val = (env && *env != '0') ? 1 : 0;
    }
    return val == 1;
#endif
}

static size_t _page_size() {
#ifdef _WIN32
    return 4096;
#else
    static size_t size = 0;
    if (size == 0) {
        size = (size_t)sysconf(_SC_PAGESIZE);
        if (size <= 0) size = 4096; // Fallback
    }
    return size;
#endif
}

// Generalized Linear allocator
static void* PerlUpb_BlockAlloc_Func(upb_alloc* alloc, void* ptr, size_t oldsize,
                                     size_t size, size_t* actual_size) {
    PerlUpb_BlockAlloc* b = (PerlUpb_BlockAlloc*)alloc;

    if (b->poisoned) return NULL;

    bool use_guard_pages = _use_guard_pages() && b->type == PERL_UPB_BLOCK_MALLOC;
    size_t page_size = _page_size();

    if (size == 0) { // FREE
        if (ptr != NULL) {
            if (use_guard_pages) {
#ifndef _WIN32
                void* block_start = (char*)ptr - page_size;
                if (mprotect(block_start, b->mmap_size, PROT_READ | PROT_WRITE) != 0) {
                    // This is bad, but continuing munmap is probably the best course.
                    warn("mprotect failed during guard page free: %s", strerror(errno));
                }
                munmap(block_start, b->mmap_size);
#else
                croak("Guard pages not supported on Windows");
#endif
            } else {
                PerlUpb_VerifyCanaries(ptr, oldsize, "BlockAlloc free", &b->poisoned);
                // For non-guard-page PERL_UPB_BLOCK_MALLOC, memory is part of b->region, freed with arena.
                // For PERL_UPB_BLOCK_MMAP, the whole region is unmapped in DestroyRaw_Tmpfs.
            }
        }
        return NULL;
    }

    if (ptr != NULL) { // REALLOC
        // Realloc is complex with guard pages, as the size changes.
        // For now, realloc with guard pages is not supported.
        if (use_guard_pages) {
            croak("Realloc not supported with guard pages in BlockAllocator");
        }
        PerlUpb_VerifyCanaries(ptr, oldsize, "BlockAlloc realloc", &b->poisoned);
        void* new_ptr = PerlUpb_BlockAlloc_Func(alloc, NULL, 0, size, actual_size);
        if (new_ptr && oldsize > 0) {
            memcpy(new_ptr, ptr, oldsize < size ? oldsize : size);
            // Free the old block - for BLOCK_MALLOC, this is a no-op as it's part of the single region
        }
        return new_ptr;
    }

    // ALLOC
    if (use_guard_pages) {
#ifndef _WIN32
        size_t data_size = size;
        if (page_size > SIZE_MAX / 2 || data_size > SIZE_MAX - page_size * 2) {
            return NULL;
        }
        size_t total_alloc = page_size * 2 + data_size;
        b->mmap_size = total_alloc;

        void* mem = mmap(NULL, total_alloc, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
        if (mem == MAP_FAILED) {
            warn("mmap failed for guard page alloc: %s", strerror(errno));
            return NULL;
        }

        if (mprotect(mem, page_size, PROT_NONE) != 0) {
            warn("mprotect failed for start guard page: %s", strerror(errno));
            munmap(mem, total_alloc);
            return NULL;
        }
        if (mprotect((char*)mem + page_size + data_size, page_size, PROT_NONE) != 0) {
            warn("mprotect failed for end guard page: %s", strerror(errno));
            munmap(mem, total_alloc);
            return NULL;
        }

        void* ret = (char*)mem + page_size;
        if (actual_size) *actual_size = data_size;
        b->region = mem; // Store the base mmap address
        b->size = data_size; // Store the usable size
        return ret;
#else
        croak("Guard pages not supported on Windows");
        return NULL;
#endif
    } else {
        // Original canary-based logic with overflow guards
        if (size > SIZE_MAX - 2 * PERL_UPB_CANARY_SIZE - 15) return NULL;
        size_t requested_size = size + 2 * PERL_UPB_CANARY_SIZE;
        size_t aligned_size = (requested_size + 15) & ~(size_t)15;
        if (b->offset > b->size || aligned_size > b->size - b->offset) return NULL;

        void* raw = (char*)b->region + b->offset;
        PerlUpb_WriteCanaries(raw, size);
        void* ret = (char*)raw + PERL_UPB_CANARY_SIZE;

        b->offset += aligned_size;

        if (actual_size) *actual_size = size;
        return ret;
    }
}

#define PERL_UPB_SHM_WIRE_MAGIC 0x5550425749524531ULL

typedef struct {
    uint64_t magic;
    uint64_t wire_len;
} PerlUpb_ShmWireFrame;

SV* PerlUpb_Arena_NewTmpfs(pTHX_ const char* path, size_t size) {
#ifdef _WIN32
    croak("Tmpfs arenas are not supported on Windows");
    return &PL_sv_undef;
#else
    int flags = O_RDWR | O_CREAT | O_EXCL;
#ifdef O_NOFOLLOW
    flags |= O_NOFOLLOW;
#endif
    int fd = open(path, flags, 0600);
    if (fd < 0 && errno == EEXIST) {
        int reopen_flags = O_RDWR;
#ifdef O_NOFOLLOW
        reopen_flags |= O_NOFOLLOW;
#endif
        fd = open(path, reopen_flags, 0600);
        if (fd >= 0) {
            struct stat st;
            if (fstat(fd, &st) != 0 || !S_ISREG(st.st_mode) || st.st_uid != geteuid() || (st.st_mode & 0077) != 0) {
                close(fd);
                croak("Unsafe existing tmpfs file %s (must be regular file owned by current uid with mode 0600)", path);
            }
        }
    }
    if (fd < 0) croak("Failed to open tmpfs file %s: %s", path, strerror(errno));

    if (ftruncate(fd, size) != 0) {
        close(fd);
        croak("Failed to truncate tmpfs file %s: %s", path, strerror(errno));
    }

    void* region = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (region == MAP_FAILED) {
        close(fd);
        croak("Failed to mmap tmpfs file %s: %s", path, strerror(errno));
    }

    PerlUpb_BlockAlloc* b_alloc = (PerlUpb_BlockAlloc*)safemalloc(sizeof(PerlUpb_BlockAlloc));
    b_alloc->base.func = PerlUpb_BlockAlloc_Func;
    b_alloc->type = PERL_UPB_BLOCK_MMAP;
    b_alloc->fd = fd;
    b_alloc->path = savepv(path);
    b_alloc->region = region;
    b_alloc->size = size;
    b_alloc->offset = 0;
    b_alloc->poisoned = false;
    b_alloc->mmap_size = size; // For tmpfs, mmap_size is the file size

    upb_Arena* arena = upb_Arena_Init(NULL, 0, &b_alloc->base);
    if (!arena) {
        munmap(region, size);
        close(fd);
        safefree(b_alloc->path);
        safefree(b_alloc);
        croak("Failed to initialize upb_Arena with block allocator");
    }

    PerlUpb_Arena_Custom* wrapper = (PerlUpb_Arena_Custom*)safemalloc(sizeof(PerlUpb_Arena_Custom));
    memset(wrapper, 0, sizeof(PerlUpb_Arena_Custom));
    wrapper->base.arena = arena;
    wrapper->alloc = b_alloc;

    return PerlUpb_Arena_WrapInternal(aTHX_ wrapper, true, false);
#endif
}

// Internal helper for RAM-backed linear arenas
upb_Arena* PerlUpb_Arena_NewBlock(pTHX_ size_t size, PerlUpb_BlockAlloc** out_alloc) {
    PerlUpb_BlockAlloc* b_alloc = (PerlUpb_BlockAlloc*)safemalloc(sizeof(PerlUpb_BlockAlloc));
    b_alloc->base.func = PerlUpb_BlockAlloc_Func;
    b_alloc->type = PERL_UPB_BLOCK_MALLOC;
    b_alloc->fd = -1;
    b_alloc->path = NULL;
    b_alloc->poisoned = false;

    if (_use_guard_pages()) {
        // Defer allocation to the first BlockAlloc_Func call
        b_alloc->region = NULL;
        b_alloc->size = 0;
        b_alloc->offset = 0;
        b_alloc->mmap_size = 0;
    } else {
        void* region = safemalloc(size);
        b_alloc->region = region;
        b_alloc->size = size;
        b_alloc->offset = 0;
        b_alloc->mmap_size = size;
    }

    upb_Arena* arena = upb_Arena_Init(NULL, 0, &b_alloc->base);
    if (!arena) {
        if (b_alloc->region) safefree(b_alloc->region);
        safefree(b_alloc);
        return NULL;
    }

    if (out_alloc) *out_alloc = b_alloc;
    return arena;
}

SV* PerlUpb_Arena_AttachTmpfs(pTHX_ const char* path, size_t size) {
#ifdef _WIN32
    croak("Tmpfs arenas are not supported on Windows");
    return &PL_sv_undef;
#else
    if (size == 0) {
        croak("Tmpfs arena size must be greater than 0");
    }
    int open_flags = O_RDONLY;
#ifdef O_NOFOLLOW
    open_flags |= O_NOFOLLOW;
#endif
    int fd = open(path, open_flags);
    if (fd < 0) croak("Failed to open existing tmpfs file %s: %s", path, strerror(errno));

    struct stat st;
    if (fstat(fd, &st) != 0 || !S_ISREG(st.st_mode)) {
        close(fd);
        croak("Tmpfs path %s is not a regular file", path);
    }
    if (st.st_uid != geteuid() || (st.st_mode & 0077) != 0) {
        close(fd);
        croak("Unsafe permissions or ownership on tmpfs file %s", path);
    }
    if (st.st_size < 0 || (uint64_t)st.st_size < (uint64_t)size) {
        close(fd);
        croak("Tmpfs file %s is smaller (%lld bytes) than requested size %zu",
              path, (long long)st.st_size, size);
    }

    void* region = mmap(NULL, size, PROT_READ, MAP_SHARED, fd, 0);
    if (region == MAP_FAILED) {
        close(fd);
        croak("Failed to mmap tmpfs file (read-only) %s: %s", path, strerror(errno));
    }

    PerlUpb_BlockAlloc* b_alloc = (PerlUpb_BlockAlloc*)safemalloc(sizeof(PerlUpb_BlockAlloc));
    b_alloc->base.func = PerlUpb_BlockAlloc_Func;
    b_alloc->type = PERL_UPB_BLOCK_MMAP;
    b_alloc->fd = fd;
    b_alloc->path = savepv(path);
    b_alloc->region = region;
    b_alloc->size = size;
    b_alloc->offset = size;
    b_alloc->poisoned = false;
    b_alloc->mmap_size = size;

    upb_Arena* arena = upb_Arena_Init(NULL, 0, &upb_alloc_global);
    if (!arena) {
        munmap(region, size);
        close(fd);
        safefree(b_alloc->path);
        safefree(b_alloc);
        croak("Failed to create upb_Arena for attachment");
    }

    PerlUpb_Arena_Custom* wrapper = (PerlUpb_Arena_Custom*)safemalloc(sizeof(PerlUpb_Arena_Custom));
    memset(wrapper, 0, sizeof(PerlUpb_Arena_Custom));
    wrapper->base.arena = arena;
    wrapper->alloc = b_alloc;

    return PerlUpb_Arena_WrapInternal(aTHX_ wrapper, true, true);
#endif
}

void PerlUpb_Arena_DestroyRaw_Tmpfs(pTHX_ void* ptr, bool is_tmpfs) {
    if (!is_tmpfs) {
        PerlUpb_Arena_DestroyRaw(aTHX_ ptr);
        return;
    }

#ifdef _WIN32
    croak("Tmpfs arenas are not supported on Windows");
#else
    PerlUpb_Arena_Custom* wrapper = (PerlUpb_Arena_Custom*)ptr;
    if (wrapper) {
        if (wrapper->base.arena) PerlUpb_Arena_Release(aTHX_ wrapper->base.arena, PERL_UPB_LIFECYCLE_PERMANENT);
        if (wrapper->alloc) {
            if (wrapper->alloc->type == PERL_UPB_BLOCK_MMAP) {
                munmap(wrapper->alloc->region, wrapper->alloc->size);
                close(wrapper->alloc->fd);
                if (wrapper->alloc->path) safefree(wrapper->alloc->path);
            } else { // PERL_UPB_BLOCK_MALLOC
                if (_use_guard_pages()) {
                    // All allocations are separate mmaps, already freed by BlockAlloc_Func
                } else {
                    if (wrapper->alloc->region) safefree(wrapper->alloc->region);
                }
            }
            safefree(wrapper->alloc);
        }
        safefree(wrapper);
    }
#endif
}

static PerlUpb_Arena_Custom* _get_tmpfs_wrapper(pTHX_ SV* arena_sv) {
    bool is_tmpfs = false;
    void* raw = PerlUpb_Arena_GetWrapperRaw(aTHX_ arena_sv, &is_tmpfs);
    if (!raw || !is_tmpfs) return NULL;
    PerlUpb_Arena_Custom* wrapper = (PerlUpb_Arena_Custom*)raw;
    if (!wrapper->alloc || !wrapper->alloc->region) return NULL;
    return wrapper;
}

bool PerlUpb_Arena_IsTmpfs(pTHX_ SV* arena_sv) {
    return _get_tmpfs_wrapper(aTHX_ arena_sv) != NULL;
}

const char* PerlUpb_Arena_GetPath(pTHX_ SV* arena_sv) {
    PerlUpb_Arena_Custom* wrapper = _get_tmpfs_wrapper(aTHX_ arena_sv);
    if (!wrapper) return NULL;
    return wrapper->alloc->path;
}

bool PerlUpb_Arena_VerifySELinux(pTHX_ SV* arena_sv) {
#ifdef _WIN32
    return true;
#else
    const char* path = PerlUpb_Arena_GetPath(aTHX_ arena_sv);
    if (!path) return true;
    struct stat st;
    if (stat(path, &st) != 0) return false;
    return S_ISREG(st.st_mode);
#endif
}

static size_t _encode_msg_to_tmpfs_frame(pTHX_ PerlUpb_Arena_Custom* wrapper, const upb_Message* msg, const upb_MessageDef* mdef) {
    if (!wrapper || !wrapper->base.arena || !msg || !mdef) return 0;
    if (wrapper->alloc->offset >= wrapper->alloc->size) {
        croak("Cannot write shared message to read-only or full tmpfs arena");
    }
    const upb_MiniTable* mt = upb_MessageDef_MiniTable(mdef);
    if (!mt) croak("Message MiniTable missing");

    upb_Arena* tmp_arena = upb_Arena_New();
    if (!tmp_arena) croak("Failed to allocate temporary arena for IPC serialization");
    char* wire_buf = NULL;
    size_t wire_size = 0;
    upb_EncodeStatus st = upb_Encode(msg, mt, 0, tmp_arena, &wire_buf, &wire_size);
    if (st != kUpb_EncodeStatus_Ok) {
        upb_Arena_Free(tmp_arena);
        croak("Failed to serialize message into tmpfs shared frame");
    }
    if (wire_size > SIZE_MAX - sizeof(PerlUpb_ShmWireFrame)) {
        upb_Arena_Free(tmp_arena);
        croak("Serialized message too large for tmpfs frame");
    }
    size_t total_frame = sizeof(PerlUpb_ShmWireFrame) + wire_size;
    char* frame_mem = (char*)upb_Arena_Malloc(wrapper->base.arena, total_frame);
    if (!frame_mem) {
        upb_Arena_Free(tmp_arena);
        croak("Tmpfs arena exhausted while writing %zu-byte shared message frame", total_frame);
    }
    if ((void*)frame_mem < wrapper->alloc->region ||
        frame_mem + total_frame > (char*)wrapper->alloc->region + wrapper->alloc->size) {
        upb_Arena_Free(tmp_arena);
        croak("Shared message frame allocated outside tmpfs mapped region (arena size too small)");
    }
    PerlUpb_ShmWireFrame hdr;
    hdr.magic = PERL_UPB_SHM_WIRE_MAGIC;
    hdr.wire_len = (uint64_t)wire_size;
    memcpy(frame_mem, &hdr, sizeof(hdr));
    if (wire_size > 0 && wire_buf) {
        memcpy(frame_mem + sizeof(hdr), wire_buf, wire_size);
    }
    upb_Arena_Free(tmp_arena);
    return (size_t)(frame_mem - (char*)wrapper->alloc->region);
}

size_t PerlUpb_Arena_WriteSharedMessage(pTHX_ SV* arena_sv, SV* msg_sv) {
    PerlUpb_Arena_Custom* wrapper = _get_tmpfs_wrapper(aTHX_ arena_sv);
    if (!wrapper) croak("Arena is not a valid tmpfs arena");
    const upb_Message* msg = PerlUpb_Message_GetMsg(aTHX_ msg_sv);
    const upb_MessageDef* mdef = PerlUpb_Message_GetDef(aTHX_ msg_sv);
    if (!msg || !mdef) croak("Invalid message passed to WriteSharedMessage");
    return _encode_msg_to_tmpfs_frame(aTHX_ wrapper, msg, mdef);
}

size_t PerlUpb_Arena_GetOffset(pTHX_ SV* arena_sv, void* ptr) {
    PerlUpb_Arena_Custom* wrapper = _get_tmpfs_wrapper(aTHX_ arena_sv);
    if (!wrapper || !ptr) return 0;
    if (ptr < wrapper->alloc->region || (char*)ptr >= (char*)wrapper->alloc->region + wrapper->alloc->size) {
        return 0;
    }

    // Safe IPC upgrade: if ptr corresponds to a live wrapped Message, write a pointer-free
    // wire-serialized frame into the shared tmpfs region and return the frame's offset!
    SV* cached_msg_sv = PerlUpb_MaybeGetMessage(aTHX_ (const upb_Message*)ptr);
    if (cached_msg_sv) {
        const upb_MessageDef* mdef = PerlUpb_Message_GetDef(aTHX_ cached_msg_sv);
        if (mdef && wrapper->alloc->offset < wrapper->alloc->size) {
            size_t frame_off = _encode_msg_to_tmpfs_frame(aTHX_ wrapper, (const upb_Message*)ptr, mdef);
            SvREFCNT_dec(cached_msg_sv);
            return frame_off;
        }
        SvREFCNT_dec(cached_msg_sv);
    }

    return (size_t)((char*)ptr - (char*)wrapper->alloc->region);
}

SV* PerlUpb_Arena_AttachMessage(pTHX_ SV* arena_sv, const char* name, size_t offset) {
    PerlUpb_Arena_Custom* wrapper = _get_tmpfs_wrapper(aTHX_ arena_sv);
    if (!wrapper) croak("Arena is not a valid tmpfs arena");
    size_t region_size = wrapper->alloc->size;
    if (offset >= region_size || region_size - offset < sizeof(PerlUpb_ShmWireFrame)) {
        croak("Offset %zu out of bounds for tmpfs arena size %zu", offset, region_size);
    }
    if ((offset % sizeof(uint64_t)) != 0) {
        croak("Unaligned offset %zu for tmpfs message frame", offset);
    }

    const upb_DefPool* pool = PerlUpb_DescriptorPool_GetPool(aTHX_ PerlUpb_DescriptorPool_GeneratedPool(aTHX));
    const upb_MessageDef* mdef = upb_DefPool_FindMessageByName(pool, name);
    if (!mdef) croak("Message definition not found: %s", name);
    const upb_MiniTable* mt = upb_MessageDef_MiniTable(mdef);
    if (!mt) croak("Message MiniTable not found: %s", name);

    const char* base = (const char*)wrapper->alloc->region + offset;
    PerlUpb_ShmWireFrame hdr;
    memcpy(&hdr, base, sizeof(hdr));
    if (hdr.magic != PERL_UPB_SHM_WIRE_MAGIC) {
        croak("Refusing to reify unframed raw pointer at offset %zu in shared memory (expected wire frame header)", offset);
    }
    size_t remaining = region_size - offset - sizeof(PerlUpb_ShmWireFrame);
    if (hdr.wire_len > remaining || hdr.wire_len > (64ULL * 1024ULL * 1024ULL)) {
        croak("Invalid shared message wire frame length %llu at offset %zu",
              (unsigned long long)hdr.wire_len, offset);
    }

    upb_Arena* dst_arena = wrapper->base.arena;
    if (!dst_arena) croak("Invalid target arena on tmpfs wrapper");
    upb_Message* msg = upb_Message_New(mt, dst_arena);
    if (!msg) croak("Failed to allocate message for shared frame decode");

    const upb_FileDef* file = upb_MessageDef_File(mdef);
    const upb_ExtensionRegistry* extreg = file ? upb_DefPool_ExtensionRegistry(upb_FileDef_Pool(file)) : NULL;
    upb_DecodeStatus status = upb_Decode(base + sizeof(PerlUpb_ShmWireFrame), (size_t)hdr.wire_len,
                                         msg, mt, extreg, 0, dst_arena);
    if (status != kUpb_DecodeStatus_Ok) {
        PerlUpb_DecodeStatus_Die(aTHX_ status, "decode shared tmpfs message frame");
    }
    return PerlUpb_WrapMessage(aTHX_ msg, mdef, arena_sv, 0);
}
