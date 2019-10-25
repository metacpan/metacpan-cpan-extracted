#ifndef _NETKAFKAH_
#define _NETKAFKAH_

#include <EXTERN.h>
#include <perl.h>
#include <librdkafka/rdkafka.h>

#define ERRSTR_SIZE 1024
#ifndef DEBUGLF
#define DEBUGLF( flag, level, fmt, ... )  \
    do { if ( flag >= level ) fprintf( stderr, "KafkaXS: " fmt "\n", ##__VA_ARGS__ ); } while (0)
#endif
#define DEBUGF( flag, fmt, ... )  DEBUGLF( flag, 1, fmt, ##__VA_ARGS__ )
#define DEBUG2F( flag, fmt, ... ) DEBUGLF( flag, 2, fmt, ##__VA_ARGS__ )
#define DEBUG3F( flag, fmt, ... ) DEBUGLF( flag, 3, fmt, ##__VA_ARGS__ )

typedef struct {
    SV *self;
    rd_kafka_t *rk;
    rd_kafka_queue_t *queue;
    IV thx;
    int type;
    int debug_xs;
    SV *rebalance_cb;
    SV *commit_cb;
    SV *error_cb;
    SV *stats_cb;
    int queue_fd;
    int is_closed;
} plrd_kafka_t;

void
krd_close_handles(plrd_kafka_t *rdk);

rd_kafka_conf_t*
krd_parse_config(pTHX_ plrd_kafka_t *krd, HV* params);

void
prd_init(plrd_kafka_t *krd, rd_kafka_conf_t *conf);

void
cns_init(plrd_kafka_t *ctl, rd_kafka_conf_t *conf);

void
prd_start(plrd_kafka_t *ctl);

void
cns_start(plrd_kafka_t *ctl);

void
prd_stop(plrd_kafka_t *ctl);

void
cns_stop(plrd_kafka_t* ctl);

#endif
