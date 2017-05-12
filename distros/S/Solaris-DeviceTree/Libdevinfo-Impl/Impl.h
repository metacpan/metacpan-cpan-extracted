


/* extern int */
/* devinfo_test( char *in ); */

extern di_node_t
di_init(const char *phys_path, unsigned int flag);

extern void
di_fini(di_node_t root);

/*
 * tree traversal
 */
extern di_node_t di_parent_node(di_node_t node);
extern di_node_t di_sibling_node(di_node_t node);
extern di_node_t di_child_node(di_node_t node);
extern di_node_t di_drv_first_node(const char *drv_name, di_node_t root);
extern di_node_t di_drv_next_node(di_node_t node);

/*
 * Null handles to make handles really opaque
 */
#define NULL 0
#define DI_NODE_NIL     NULL
#define DI_MINOR_NIL    NULL
#define DI_PROM_PROP_NIL        NULL
#define DI_PROM_HANDLE_NIL      NULL

#define DIIOC   (0xdf<<8)

#define  DDI_DEV_T_NONE  (dev_t) -1

/*
 * Any combination of the following ORed together will take a snapshot
 * of the device configuration data.
 *
 * XXX First three are public, last three are private
 */
#define DINFOSUBTREE    DIIOC | 0x01
#define DINFOMINOR      DIIOC | 0x02
#define DINFOPROP       DIIOC | 0x04

#define DINFOCPYALL     (DINFOSUBTREE | DINFOPROP | DINFOMINOR)

/* -- di_node_t functions -- */
char *di_binding_name(di_node_t node);
char *di_bus_addr(di_node_t node);
/* int di_compatible_names(di_node_t node, char **OUTPUT); */
ddi_devid_t di_devid(di_node_t node);
char *di_driver_name(di_node_t node);


unsigned int di_state(di_node_t node);
/* node & device states */
#define DI_DRIVER_DETACHED      0x8000
#define DI_DEVICE_OFFLINE       0x1
#define DI_DEVICE_DOWN          0x2
#define DI_BUS_QUIESCED         0x100
#define DI_BUS_DOWN             0x200

/*
int isDevidNull( ddi_devid_t devid );
*/

#define DI_BUS_OPS      0x1
#define DI_CB_OPS       0x2
#define DI_STREAM_OPS   0x4
unsigned int di_driver_ops(di_node_t node);

int di_instance(di_node_t node);

#define DI_PSEUDO_NODEID        -1
#define DI_SID_NODEID           -2
#define DI_PROM_NODEID          -3
int di_nodeid(di_node_t node);

char *di_node_name(di_node_t node);

extern di_prop_t di_prop_next(di_node_t node, di_prop_t prop);
extern char *di_prop_name(di_prop_t prop);
extern int di_prop_type(di_prop_t prop);

#define DI_PROP_TYPE_BOOLEAN    0
#define DI_PROP_TYPE_INT        1
#define DI_PROP_TYPE_STRING     2
#define DI_PROP_TYPE_BYTE       3
#define DI_PROP_TYPE_UNKNOWN    4
#define DI_PROP_TYPE_UNDEF_IT   5

extern dev_t di_prop_devt( di_prop_t prop );
/* extern major_t major(dev_t device);
extern minor_t minor(dev_t device);
*/

extern int di_prop_ints(di_prop_t prop, int **prop_data);
extern int di_prop_strings(di_prop_t prop, char **prop_data);
extern int di_prop_bytes(di_prop_t prop, uchar_t **prop_data);

extern di_minor_t di_minor_next( di_node_t node, di_minor_t minor );

extern dev_t di_minor_devt( di_minor_t minor );
extern char *di_minor_name( di_minor_t minor );
extern char *di_minor_nodetype( di_minor_t minor );
extern int di_minor_spectype( di_minor_t minor );

/* From /usr/include/sys/stat.h */
#define S_IFCHR         0x2000  /* character special */
#define S_IFBLK         0x6000  /* block special */


/* -- PROM access -- */

extern di_prom_handle_t di_prom_init();
extern void di_prom_fini( di_prom_handle_t ph );

extern di_prom_prop_t di_prom_prop_next(di_prom_handle_t ph, di_node_t node,
    di_prom_prop_t prom_prop);
extern char *di_prom_prop_name(di_prom_prop_t prom_prop);
extern int di_prom_prop_data(di_prom_prop_t prop, uchar_t **prom_prop_data);

/* -- from libdevid -- */
/*
extern
int devid_compare(ddi_devid_t devid1, ddi_devid_t devid2);
*/
