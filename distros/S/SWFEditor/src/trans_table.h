#ifndef __TRANS_TABLE_H__
#define __TRANS_TABLE_H__

typedef struct _trans_table_t {
    int *table;
    int table_num;
} trans_table_t;

#define TRANS_TABLE_RESERVE_ID -1

extern trans_table_t *trans_table_open();
extern void trans_table_close(trans_table_t  *trans_table);

extern int trans_table_get(trans_table_t  *trans_table, int offset);
extern int trans_table_set(trans_table_t  *trans_table, int offset, int cid);
extern int trans_table_get_freeid(trans_table_t  *trans_table);
extern void trans_table_print(trans_table_t  *trans_table);

#endif /* __TRANS_TABLE_H__ */
