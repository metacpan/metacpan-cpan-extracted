#include "pvip.h"
#include "string.h"

int C;

int main() {
    C=0;
    printf("1..2\n");

    {
        PVIPString * x = PVIP_string_new();
        PVIP_string_printf(x, "%s%d", "hoge", 2);

        if (x->len==5 && !memcmp(x->buf, "hoge2", 5)) {
            printf("ok 1\n");
        } else {
            printf("not ok 1\n");
        }
    }

    {
        PVIPNode *node = PVIP_parse_string("\n", 1, 0, NULL);
        if (node) {
            printf("ok 2\n");
            PVIP_node_destroy(node);
        } else {
            printf("not ok 2\n");
        }
    }
    return 0;
}
