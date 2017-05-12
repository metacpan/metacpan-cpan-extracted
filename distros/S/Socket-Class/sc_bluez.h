#include "socket_class.h"

int bt_device_list( bdaddr_t *r_addr, int r_addr_max );
int bt_device_name( bdaddr_t *addr, char *name, int name_len );
int bt_service_list( bdaddr_t *addr );
int bt_setaddr( my_thread_var_t *tv, const char *p1, const char *p2, int use );
