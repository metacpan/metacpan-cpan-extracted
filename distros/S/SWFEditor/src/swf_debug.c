#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// #include "swf_define.h" no include

int swf_debug = 0;

// #define MALLOC_DEBUG_TABLE_NUM 0x20000
#define MALLOC_DEBUG_TABLE_NUM 0x40000

static struct malloc_debug_ {
    void *ptr;
    char *filename;
    int  linenum;
} malloc_debug_table[MALLOC_DEBUG_TABLE_NUM];

static int malloc_debug_stack = 0;

void
malloc_debug_start(void) {
    int i;
    malloc_debug_stack ++;
    if (malloc_debug_stack > 1) {
        fprintf(stderr, "malloc_debug_start: malloc_debug_stack=%d\n", malloc_debug_stack);
        return ;
    }
    for (i=0 ; i < MALLOC_DEBUG_TABLE_NUM ; i++) {
        malloc_debug_table[i].ptr = NULL;
    }
    fprintf(stderr, "malloc_debug_start: 0/n=0/%d\n", MALLOC_DEBUG_TABLE_NUM);
}

void
malloc_debug_end(void) {
    int i, j = 0;
    malloc_debug_stack --;
    if (malloc_debug_stack > 0) {
        fprintf(stderr, "malloc_debug_end: malloc_debug_stack=%d\n", malloc_debug_stack);
        return ;
    }
    for (i=0 ; i < MALLOC_DEBUG_TABLE_NUM ; i++) {
        if (malloc_debug_table[i].ptr) {
            fprintf(stderr, "XXX (%d) ptr=%p (%s, %d)\n",
                    i, malloc_debug_table[i].ptr,
                    malloc_debug_table[i].filename,
                    malloc_debug_table[i].linenum);
            j = i + 1;
        }
    }
    fprintf(stderr, "malloc_debug_end: j/n=%d/%d\n", j, MALLOC_DEBUG_TABLE_NUM);
}

void *
calloc_debug(size_t nmemb, size_t size, char *filename, int linenum) {
    int i;
    void *ptr;
    ptr = calloc(nmemb, size);
//    fprintf(stderr, "calloc_debug: ptr=%p (%s,%d)\n", ptr, filename, linenum);
    for (i=0 ; i < MALLOC_DEBUG_TABLE_NUM ; i++) {
        if (malloc_debug_table[i].ptr == NULL) {
            malloc_debug_table[i].ptr = ptr;
            malloc_debug_table[i].filename = filename;
            malloc_debug_table[i].linenum = linenum;
            break;
        }
    }
    return ptr;
}

void *
malloc_debug(size_t size, char *filename, int linenum) {
    int i;
    void *ptr;
    ptr = malloc(size);
//    fprintf(stderr, "malloc_debug: ptr=%p (%s,%d)\n", ptr, filename, linenum);
    for (i=0 ; i < MALLOC_DEBUG_TABLE_NUM ; i++) {
        if (malloc_debug_table[i].ptr == NULL) {
            malloc_debug_table[i].ptr = ptr;
            malloc_debug_table[i].filename = filename;
            malloc_debug_table[i].linenum = linenum;
//            fprintf(stderr, "(%d)\n", i);
            return ptr;
        }
    }
    fprintf(stderr, "malloc: table full... ;_;\n");
    return ptr;
}

void
free_debug(void *ptr, char *filename, int linenum) {
    int i;
//    fprintf(stderr, "free_debug: ptr=%p (%s,%d)\n", ptr, filename, linenum);
    for (i=0 ; i < MALLOC_DEBUG_TABLE_NUM ; i++) {
        if (malloc_debug_table[i].ptr == ptr) {
            malloc_debug_table[i].ptr = NULL;
            break;
        }
    }
    if (i == MALLOC_DEBUG_TABLE_NUM) {
        char *p;
        fprintf(stderr, "free non-allocated memory: ptr=%p (%s,%d)\n", ptr,
                filename, linenum);
        malloc_debug_end();
        p = ptr;
        p = 0;
    }
    free(ptr);
}

void *
realloc_debug(void *ptr, size_t size, char *filename, int linenum) {
    int i;
    void *new_ptr;
    new_ptr = realloc(ptr, size);
    if (new_ptr == ptr) {
        return new_ptr;
    }
//    fprintf(stderr, "realloc_debug: ptr=%p => new_ptr=%p (%s,%d)\n",
//            ptr, new_ptr, filename, linenum);
    for (i=0 ; i < MALLOC_DEBUG_TABLE_NUM ; i++) {
        if (malloc_debug_table[i].ptr == ptr) {
            malloc_debug_table[i].ptr = new_ptr;
            malloc_debug_table[i].filename = filename;
            malloc_debug_table[i].linenum = linenum;
            break;
        }
    }
    return new_ptr;
}

#define HEXBIN_DISP_UNIT 0x10

void
print_hexbin(unsigned char *data, int data_len) {
    int i;
    printf("\n");
    for (i=0 ; i < data_len ; i++) {
        if ((i%HEXBIN_DISP_UNIT) == 0) {
            printf("0x%08x: ", i);
        }
#if 1
        printf("%02x ", data[i] & 0xff);
        if ((i%HEXBIN_DISP_UNIT) == HEXBIN_DISP_UNIT-1) {
            printf("\n");
        }
#else
        do {
            unsigned char c = data[i];
            signed int j;
            if ((i%HEXBIN_DISP_UNIT) == 0) {
                printf("\n");
            }
            for (j=7 ; j >= 0 ; j--) {
                printf("%d", (c >> j) & 1);

            }
            printf("\n");
        } while(0);
#endif
    }
    printf("\n");
    return ;
}
