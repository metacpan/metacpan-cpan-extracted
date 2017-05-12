#ifndef __Y_KEYVALUE_H__
#define __Y_KEYVALUE_H__

typedef struct _y_keyvalue_entry_t {
    char *key, *value;
    int key_len, value_len;
    int use;
} y_keyvalue_entry_t;

typedef struct _y_keyvalue_t {
    int use_len;
    int alloc_len;
    y_keyvalue_entry_t *table;
    //
    signed int get_offset;
} y_keyvalue_t;

// open/close
extern y_keyvalue_t *y_keyvalue_open();
extern void y_keyvalue_close(y_keyvalue_t *st);

// set/get/delete
extern int y_keyvalue_set(y_keyvalue_t *st, char *key, int key_len, char *value, int value_len);
extern char *y_keyvalue_get(y_keyvalue_t *st, char *key, int key_len,int *value_len);
extern int y_keyvalue_delete(y_keyvalue_t *st, char *key, int key_len);

// itelator
extern void y_keyvalue_rewind(y_keyvalue_t *st);
extern void y_keyvalue_seeklast(y_keyvalue_t *st);
extern int y_keyvalue_next(y_keyvalue_t *st);
extern int y_keyvalue_prev(y_keyvalue_t *st);

extern char * y_keyvalue_get_currentkey(y_keyvalue_t *st, int *key_len);
extern char * y_keyvalue_get_currentvalue(y_keyvalue_t *st, int *value_len);


// info
extern int y_keyvalue_get_maxkeylength(y_keyvalue_t *st);
extern int y_keyvalue_get_maxvaluelength(y_keyvalue_t *st);
extern int y_keyvalue_get_maxkeyvaluelength(y_keyvalue_t *st);
extern void y_keyvalue_dump(y_keyvalue_t *st);

#endif /* __Y_KEYVALUE_H__ */
