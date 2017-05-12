#include <stdio.h>
#include <stdlib.h>
#include "trans_table.h"

trans_table_t *
trans_table_open() {
    trans_table_t *trans_table;
    trans_table = calloc(sizeof(*trans_table), 1);
    trans_table->table_num = 256; // XXX
    trans_table->table = calloc(trans_table->table_num, sizeof(int));
    return trans_table;
}
void
trans_table_close(trans_table_t *trans_table) {
    if (trans_table) {
        if (trans_table->table) {
            free(trans_table->table);
            trans_table->table = NULL;
        }
        free(trans_table);
    }
}

int
trans_table_realloc(trans_table_t *trans_table, int offset) {
    int new_table_num = trans_table->table_num;
    int *table;
    int i;
    while (new_table_num <= offset) {
        new_table_num *= 2;
    }
    table = realloc(trans_table->table, new_table_num * sizeof(int));
    if (table == NULL) {
        return 1; // failed
    }
    for (i = trans_table->table_num ; i < new_table_num ; i++) {
        table[i] = 0;
    }
    trans_table->table = table;
    trans_table->table_num = new_table_num;
    return 0;
}
int
trans_table_get(trans_table_t  *trans_table, int offset) {
    if (offset < 0) {
        return 0;
    }
    if (trans_table->table_num <= offset) {
        return 0;
    }
    return trans_table->table[offset];
}
int
trans_table_set(trans_table_t  *trans_table, int offset, int cid) {
    if (offset < 0) {
        return 1; // failed
    }
    if (trans_table->table_num <= offset) {
      if (trans_table_realloc(trans_table, offset)) {
	return 1; // failed
      }
    }
    trans_table->table[offset] = cid;
    return 0;
}
int
trans_table_get_freeid(trans_table_t  *trans_table) {
    int i;
    // 0 is special.
    for (i = 1 ; i < trans_table->table_num ; i++) {
        if (trans_table->table[i] == 0) {
            return i;
        }
    }
    trans_table_realloc(trans_table, i);
    return i;
}

void
trans_table_print(trans_table_t  *trans_table) {
    int i, new_table_num = trans_table->table_num;
    printf("trans_table_print num=%d\n", new_table_num);
    for (i = 1 ; i < new_table_num ; i++) {
        int v = trans_table->table[i];
        if (v > 0) {
            printf("%d: %d\n", i, v);
        } else if (v == TRANS_TABLE_RESERVE_ID) {
            printf("%d: reserved\n", i);
        }
    }
}
