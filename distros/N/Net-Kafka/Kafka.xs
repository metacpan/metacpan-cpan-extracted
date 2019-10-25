/* vim: set expandtab sts=4: */
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <librdkafka/rdkafka.h>

#ifndef TIME_UTC
    #ifdef CLOCK_REALTIME
        #define TIME_UTC CLOCK_REALTIME
    #else
        #define TIME_UTC 0
    #endif
#endif

#include "ppport.h"
#include "netkafka.h"

static void
make_constant_iv( pTHX_ HV *stash, const char *name, size_t namelen, IV value_iv )
{
    SV **sv = hv_fetch( stash, name, namelen, TRUE );
    SV *sv_value = newSViv( value_iv );

    if ( SvOK( *sv ) || SvTYPE( *sv ) == SVt_PVGV )
    {
        /* For whatever reason it already exists in the stash, we need to
         * create the slow constsub
         */
        newCONSTSUB( stash, name, sv_value );
    }
    else
    {
        /* Create a read-only constant. Fast, optimised at perl compilation. */
        SvUPGRADE( *sv, SVt_RV );
        SvRV_set( *sv, sv_value );
        SvROK_on( *sv );
        SvREADONLY_on( sv_value );
    }
}

#define MAKE_CONSTANT_IV( name ) make_constant_iv( aTHX_ stash, #name, strlen( #name ), name )

MODULE = Net::Kafka    PACKAGE = Net::Kafka    PREFIX = krd_
PROTOTYPES: DISABLE

BOOT:
    {
        dTHX;
        HV *stash = get_hv( "Net::Kafka::", GV_ADD );

        MAKE_CONSTANT_IV( RD_KAFKA_VERSION );
        MAKE_CONSTANT_IV( RD_KAFKA_PRODUCER );
        MAKE_CONSTANT_IV( RD_KAFKA_CONSUMER );
        MAKE_CONSTANT_IV( RD_KAFKA_TIMESTAMP_NOT_AVAILABLE );
        MAKE_CONSTANT_IV( RD_KAFKA_TIMESTAMP_CREATE_TIME );
        MAKE_CONSTANT_IV( RD_KAFKA_TIMESTAMP_LOG_APPEND_TIME );
        MAKE_CONSTANT_IV( RD_KAFKA_PARTITION_UA );
        MAKE_CONSTANT_IV( RD_KAFKA_OFFSET_BEGINNING );
        MAKE_CONSTANT_IV( RD_KAFKA_OFFSET_END );
        MAKE_CONSTANT_IV( RD_KAFKA_OFFSET_STORED );
        MAKE_CONSTANT_IV( RD_KAFKA_OFFSET_INVALID );

        MAKE_CONSTANT_IV( RD_KAFKA_EVENT_NONE );
        MAKE_CONSTANT_IV( RD_KAFKA_EVENT_DR );
        MAKE_CONSTANT_IV( RD_KAFKA_EVENT_FETCH );
        MAKE_CONSTANT_IV( RD_KAFKA_EVENT_LOG );
        MAKE_CONSTANT_IV( RD_KAFKA_EVENT_ERROR );
        MAKE_CONSTANT_IV( RD_KAFKA_EVENT_REBALANCE );
        MAKE_CONSTANT_IV( RD_KAFKA_EVENT_OFFSET_COMMIT );
        MAKE_CONSTANT_IV( RD_KAFKA_EVENT_STATS );

        ++PL_sub_generation;
    }

const char *
krd_rd_kafka_version()
    CODE:
        RETVAL = rd_kafka_version_str();
    OUTPUT:
        RETVAL

void
krd_new(package, type, params = NULL)
        char *package
        int type
        HV* params
    PREINIT:
        plrd_kafka_t *krd;
        rd_kafka_conf_t* conf;
        rd_kafka_t* rk;
        char errstr[ERRSTR_SIZE];
    PPCODE:
        Newxz(krd, 1, plrd_kafka_t);
        conf = krd_parse_config(aTHX_ krd, params);
        if (type == RD_KAFKA_PRODUCER) {
            DEBUGF(krd->debug_xs, "Creating producer");
            prd_init(krd, conf);
        } else {
            DEBUGF(krd->debug_xs, "Creating consumer");
            cns_init(krd, conf);
        }
        rk = rd_kafka_new(type, conf, errstr, ERRSTR_SIZE);
        if (rk == NULL) {
            croak("%s", errstr);
        }
        krd->rk = rk;
        krd->thx = (IV) PERL_GET_THX;
        krd->type = type;
        krd->is_closed = 0;

        ST(0) = sv_newmortal();
        sv_setref_pv(ST(0), "Net::Kafka", (void *)krd);
        krd->self = newSVsv((SV*)ST(0));

        if (type == RD_KAFKA_PRODUCER) {
            prd_start(krd);
        } else {
            cns_start(krd);
        }

        XSRETURN(1);

const char *
krd_get_debug_contexts()
    CODE:
        RETVAL = rd_kafka_get_debug_contexts();
    OUTPUT:
        RETVAL

void
krd_subscribe(rdk, topics)
        plrd_kafka_t* rdk
        AV* topics
    PREINIT:
        STRLEN strl;
        int i, len;
        rd_kafka_topic_partition_list_t* topic_list;
        rd_kafka_resp_err_t err;
        char* topic;
        SV** topic_sv;
    CODE:
        len = av_len(topics) + 1;
        topic_list = rd_kafka_topic_partition_list_new(len);
        for (i=0; i < len; i++) {
            topic_sv = av_fetch(topics, i, 0);
            if (topic_sv != NULL) {
                topic = SvPV(*topic_sv, strl);
                rd_kafka_topic_partition_list_add(topic_list, topic, -1);
            }
        }
        err = rd_kafka_subscribe(rdk->rk, topic_list);
        rd_kafka_topic_partition_list_destroy(topic_list);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error subscribing to topics: %s", rd_kafka_err2str(err));
        }

void
krd_unsubscribe(rdk)
        plrd_kafka_t* rdk
    PREINIT:
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_unsubscribe(rdk->rk);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error unsubscribing from topics: %s", rd_kafka_err2str(err));
        }

rd_kafka_topic_partition_list_t *
krd_subscription(rdk)
        plrd_kafka_t* rdk
    PREINIT:
        rd_kafka_topic_partition_list_t* tp_list;
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_subscription(rdk->rk, &tp_list);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error retrieving subscriptions: %s", rd_kafka_err2str(err));
        }
        RETVAL = tp_list;
    OUTPUT:
        RETVAL

HV*
krd_metadata(rdk,topic,timeout_ms=1000)
        plrd_kafka_t* rdk
        rd_kafka_topic_t* topic
        int timeout_ms
    PREINIT:
        const rd_kafka_metadata_t *metadatap;
        rd_kafka_resp_err_t err;
        int t,p,b,r,i;
        rd_kafka_metadata_topic_t topic_md;
        rd_kafka_metadata_partition_t partition_md;
        rd_kafka_metadata_broker_t broker_md;
    CODE:
        err = rd_kafka_metadata(rdk->rk, 0, topic, &metadatap, timeout_ms);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error retrieving partition information: %s", rd_kafka_err2str(err));
        }
        RETVAL = newHV();
        hv_stores(RETVAL, "orig_broker_name", newSVpv(metadatap->orig_broker_name, strlen(metadatap->orig_broker_name)));
        hv_stores(RETVAL, "orig_broker_id", newSViv(metadatap->orig_broker_id));

        /* array of hashrefs containing topic information  */
        AV* topic_AV = newAV();
        for( t=0; t<metadatap->topic_cnt; t++) {

            /* hash for each topic information */
            HV * topic_HV = newHV();
            topic_md = metadatap->topics[t];
            hv_stores(topic_HV, "topic_name", newSVpv(topic_md.topic, strlen(topic_md.topic)));

            /* array of hashrefs containing partition information within each topic */
            AV * partition_AV = newAV();
            for( p=0; p<topic_md.partition_cnt; p++) {
                /* hash for each partition */
                HV * partition_HV = newHV();
                partition_md = topic_md.partitions[p];
                hv_stores(partition_HV, "id", newSViv(partition_md.id));
                hv_stores(partition_HV, "leader", newSViv(partition_md.leader));

                /* array containing replica broker ids for each partition */
                AV * replica_AV = newAV();
                for ( r=0; r < partition_md.replica_cnt; r++) {
                    av_push(replica_AV, newSViv(partition_md.replicas[r]));
                }
                hv_stores(partition_HV, "replicas", newRV_noinc((SV*)replica_AV));

                /* array containing isr broker ids for each partition */
                AV* isr_AV = newAV();
                for( i=0; i < partition_md.isr_cnt; i++ ) {
                    av_push(isr_AV, newSViv(partition_md.isrs[i]));
                }
                hv_stores(partition_HV, "isrs", newRV_noinc((SV*)isr_AV));

                av_push(partition_AV, newRV_noinc((SV*)partition_HV));
            }

            hv_stores(topic_HV, "partitions", newRV_noinc((SV*)partition_AV));

            av_push(topic_AV, newRV_noinc((SV*)topic_HV));
        }
        hv_stores(RETVAL, "topics", newRV_noinc((SV*)topic_AV));

        /* array of hashrefs containing broker information */
        AV* broker_AV = newAV();
        for( b = 0; b < metadatap->broker_cnt; b++) {
            /* broker hash */
            HV * broker_HV = newHV();
            broker_md = metadatap->brokers[b];
            hv_stores(broker_HV, "id", newSViv(broker_md.id));
            hv_stores(broker_HV, "host", newSVpv(broker_md.host, strlen(broker_md.host)));
            hv_stores(broker_HV, "port", newSViv(broker_md.port));

            av_push(broker_AV, newRV_noinc((SV*)broker_HV));
        }
        hv_stores(RETVAL, "brokers", newRV_noinc((SV*)broker_AV));

        /* Free up memory used by metadata struct */
        rd_kafka_metadata_destroy(metadatap);
    OUTPUT:
        RETVAL

void
krd_assign(rdk, tp_list = NULL)
        plrd_kafka_t* rdk
        rd_kafka_topic_partition_list_t* tp_list
    PREINIT:
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_assign(rdk->rk, tp_list);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error assigning partitions: %s", rd_kafka_err2str(err));
        }

void
krd_position(rdk, tp_list)
        plrd_kafka_t* rdk
        rd_kafka_topic_partition_list_t* tp_list
    PREINIT:
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_position(rdk->rk, tp_list);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error getting position: %s", rd_kafka_err2str(err));
        }

rd_kafka_topic_partition_list_t *
krd_assignment(rdk)
        plrd_kafka_t *rdk
    PREINIT:
        rd_kafka_topic_partition_list_t* tp_list;
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_assignment(rdk->rk, &tp_list);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error retrieving assignments: %s", rd_kafka_err2str(err));
        }
        RETVAL = tp_list;
    OUTPUT:
        RETVAL

rd_kafka_event_t*
krd_queue_poll(rdk, timeout_ms = 0)
        plrd_kafka_t *rdk
        int timeout_ms
    PREINIT:
        rd_kafka_event_t* rke;
    PPCODE:
        rke = rd_kafka_queue_poll(rdk->queue, timeout_ms);
        if (! rke) {
            XSRETURN_EMPTY;
            return;
        }

        ST(0) = sv_newmortal();
        sv_setref_pv( ST(0), "Net::Kafka::Event", (void *)rke );
        XSRETURN(1);

long
krd_queue_length(rdk)
        plrd_kafka_t *rdk
    CODE:
        RETVAL = rd_kafka_queue_length(rdk->queue);
    OUTPUT:
        RETVAL

void
krd_commit(rdk, async = 0, tp_list = NULL)
        plrd_kafka_t* rdk
        int async
        rd_kafka_topic_partition_list_t* tp_list
    PREINIT:
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_commit(rdk->rk, tp_list, async);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR && err != RD_KAFKA_RESP_ERR__NO_OFFSET) {
            croak("Error committing offsets: %s", rd_kafka_err2str(err));
        }

void
krd_commit_message(rdk, async = 0, rd_msg)
        plrd_kafka_t *rdk
        int async
        rd_kafka_message_t *rd_msg
    PREINIT:
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_commit_message(rdk->rk, rd_msg, async);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error committing message: %s", rd_kafka_err2str(err));
        }

void
krd_committed(rdk, tp_list, timeout_ms)
        plrd_kafka_t* rdk
        rd_kafka_topic_partition_list_t* tp_list
        int timeout_ms
    PREINIT:
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_committed(rdk->rk, tp_list, timeout_ms);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error retrieving commited offsets: %s", rd_kafka_err2str(err));
        }

void
krd_offsets_for_times(rdk, tp_list, timeout_ms)
        plrd_kafka_t* rdk
        rd_kafka_topic_partition_list_t* tp_list
        int timeout_ms
    PREINIT:
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_offsets_for_times(rdk->rk, tp_list, timeout_ms);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error retrieving offsets for times: %s", rd_kafka_err2str(err));
        }

void
krd_pause(rdk, tp_list = NULL)
        plrd_kafka_t *rdk
        rd_kafka_topic_partition_list_t* tp_list
    PREINIT:
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_pause_partitions(rdk->rk, tp_list);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error pausing partitions: %s", rd_kafka_err2str(err));
        }

void
krd_resume(rdk, tp_list = NULL)
        plrd_kafka_t *rdk
        rd_kafka_topic_partition_list_t* tp_list
    PREINIT:
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_resume_partitions(rdk->rk, tp_list);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error resuming partitions: %s", rd_kafka_err2str(err));
        }

void
krd_consumer_poll(rdk, timeout_ms = 0)
        plrd_kafka_t *rdk
        int timeout_ms
    PPCODE:
        rd_kafka_message_t *rd_msg = rd_kafka_consumer_poll( rdk->rk, timeout_ms );

        if (! rd_msg) {
            XSRETURN_EMPTY;
            return;
        }

        ST(0) = sv_newmortal();
        sv_setref_pv( ST(0), "Net::Kafka::Message", (void *)rd_msg );
        XSRETURN(1);

void
krd_topic(rdk, topic)
        plrd_kafka_t* rdk
        char *topic
    PPCODE:
        rd_kafka_topic_t* rd_topic = rd_kafka_topic_new(rdk->rk, topic, NULL);
        DEBUG2F(rdk->debug_xs, "Created Net::Kafka::Topic %s", rd_kafka_topic_name(rd_topic));
        ST(0) = sv_newmortal();
        sv_setref_pv( ST(0), "Net::Kafka::Topic", (void *)rd_topic );
        XSRETURN(1);

void
krd_close(rdk)
        plrd_kafka_t* rdk
    CODE:
        krd_close_handles(rdk);

void
krd_DESTROY(rdk)
        plrd_kafka_t* rdk
    CODE:
        krd_close_handles(rdk);
        if (rdk->thx == (IV)PERL_GET_THX)
            Safefree(rdk);

void
krd_dump(rdk)
        plrd_kafka_t* rdk
    CODE:
        rd_kafka_dump(stdout, rdk->rk);

void
krd_query_watermark_offsets(rdk, topic, partition, timeout_ms)
        plrd_kafka_t* rdk
        char *topic
        int partition
        long timeout_ms
    PREINIT:
        rd_kafka_resp_err_t err;
        long low, high;
    PPCODE:
        err = rd_kafka_query_watermark_offsets(rdk->rk, topic, partition, &low, &high, timeout_ms);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error querying watermark offsets: %s", rd_kafka_err2str(err));
        }
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(low)));
        PUSHs(sv_2mortal(newSViv(high)));

MODULE = Net::Kafka    PACKAGE = Net::Kafka::Event    PREFIX = krdev_
PROTOTYPES: DISABLE

const char *
krdev_event_name(rkev)
        rd_kafka_event_t* rkev
    CODE:
        RETVAL = rd_kafka_event_name(rkev);
    OUTPUT:
        RETVAL

int
krdev_event_error(rkev)
        rd_kafka_event_t* rkev
    CODE:
        RETVAL = rd_kafka_event_error(rkev);
    OUTPUT:
        RETVAL

const char *
krdev_event_error_string(rkev)
        rd_kafka_event_t* rkev
    CODE:
        RETVAL = rd_kafka_event_error_string(rkev);
    OUTPUT:
        RETVAL

const char*
krdev_event_stats(rkev)
        rd_kafka_event_t* rkev
    CODE:
        RETVAL = rd_kafka_event_stats(rkev);
    OUTPUT:
        RETVAL

int
krdev_event_message_count(rkev)
        rd_kafka_event_t* rkev
    CODE:
        RETVAL = rd_kafka_event_message_count(rkev);
    OUTPUT:
        RETVAL

HV*
krdev_event_delivery_report_next(rkev)
        rd_kafka_event_t* rkev
    PREINIT:
        const rd_kafka_message_t* rkm;
    CODE:
        rkm = rd_kafka_event_message_next(rkev);
        if (! rkm) {
            XSRETURN_UNDEF;
            return;
        }

        RETVAL = newHV();
        hv_stores(RETVAL, "offset", newSViv(rkm->offset));
        hv_stores(RETVAL, "partition", newSViv(rkm->partition));
        hv_stores(RETVAL, "timestamp", newSViv(rd_kafka_message_timestamp(rkm, NULL)));
        hv_stores(RETVAL, "msg_id", newSViv((IV)rkm->_private));
        if (rkm->err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            char* err_msg = (char *)rd_kafka_err2str(rkm->err);
            hv_stores(RETVAL, "err", newSViv(rkm->err));
            hv_stores(RETVAL, "err_msg", newSVpvn(err_msg, strlen(err_msg)));
        }

    OUTPUT:
        RETVAL

int
krdev_event_type(rkev)
        rd_kafka_event_t* rkev
    CODE:
        RETVAL = rd_kafka_event_type(rkev);
    OUTPUT:
        RETVAL

void
krdev_DESTROY(rkev)
        rd_kafka_event_t* rkev
    CODE:
        rd_kafka_event_destroy(rkev);

MODULE = Net::Kafka    PACKAGE = Net::Kafka::Topic    PREFIX = krdt_
PROTOTYPES: DISABLE

void
krdt_produce(rkt, partition, key, payload, timestamp, msg_id, msgflags = 0, hdrs = NULL)
        rd_kafka_topic_t* rkt
        int partition
        SV* key
        SV* payload
        long timestamp
        IV msg_id
        int msgflags
        rd_kafka_headers_t *hdrs
    PREINIT:
        STRLEN plen = 0, klen = 0;
        char *plptr = NULL, *keyptr = NULL;
        plrd_kafka_t* krd;
        rd_kafka_resp_err_t err;
    CODE:
        if (SvOK(payload))
            plptr = SvPVbyte(payload, plen);
        if (SvOK(key))
            keyptr = SvPVbyte(key, klen);

        krd = (plrd_kafka_t *)rd_kafka_topic_opaque(rkt);
        err = rd_kafka_producev(
            krd->rk,
            RD_KAFKA_V_RKT(rkt),
            RD_KAFKA_V_PARTITION(partition),
            RD_KAFKA_V_MSGFLAGS(RD_KAFKA_MSG_F_COPY | msgflags),
            RD_KAFKA_V_KEY(keyptr, klen),
            RD_KAFKA_V_TIMESTAMP(timestamp),
            RD_KAFKA_V_VALUE(plptr, plen),
            RD_KAFKA_V_OPAQUE((void *) msg_id),
            /* making a copy here avoids ownership nightmares */
            RD_KAFKA_V_HEADERS(hdrs ? rd_kafka_headers_copy(hdrs) : NULL),
            RD_KAFKA_V_END);

        if (err) {
            croak("Error producing: %s", rd_kafka_err2str(err));
        }

void
krdt_seek(rkt, partition, offset, timeout_ms = 0)
        rd_kafka_topic_t* rkt
        int partition
        long offset
        int timeout_ms
    PREINIT:
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_seek(rkt, partition, offset, timeout_ms);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error while seeking: %s", rd_kafka_err2str(err));
        }

void
krdt_DESTROY(rkt)
        rd_kafka_topic_t* rkt
    CODE:
        plrd_kafka_t* krd = (plrd_kafka_t *)rd_kafka_topic_opaque(rkt);
        DEBUG2F(krd->debug_xs, "Destroying Net::Kafka::Topic %s", rd_kafka_topic_name(rkt));
        rd_kafka_topic_destroy( rkt );

MODULE = Net::Kafka    PACKAGE = Net::Kafka::Message    PREFIX = krdm_
PROTOTYPES: DISABLE

int
krdm_err(rd_msg)
        rd_kafka_message_t *rd_msg
    CODE:
        RETVAL = rd_msg->err;
    OUTPUT:
        RETVAL

const char *
krdm_err_name(rd_msg)
        rd_kafka_message_t *rd_msg
    CODE:
        RETVAL = rd_kafka_err2name(rd_msg->err);
    OUTPUT:
        RETVAL

int
krdm_partition(rd_msg)
        rd_kafka_message_t *rd_msg
    CODE:
        RETVAL = rd_msg->partition;
    OUTPUT:
        RETVAL

const char*
krdm_topic(rd_msg)
        rd_kafka_message_t *rd_msg
    CODE:
        RETVAL = rd_kafka_topic_name(rd_msg->rkt);
    OUTPUT:
        RETVAL

SV*
krdm_payload(rd_msg)
        rd_kafka_message_t *rd_msg
    CODE:
        RETVAL = newSVpvn(rd_msg->payload, rd_msg->len);
    OUTPUT:
        RETVAL

SV*
krdm_key(rd_msg)
        rd_kafka_message_t *rd_msg
    CODE:
        if (rd_msg->err == 0) {
            RETVAL = newSVpvn(rd_msg->key, rd_msg->key_len);
        } else {
            RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

void
krdm_timestamp(rd_msg)
        rd_kafka_message_t *rd_msg
    PREINIT:
        rd_kafka_timestamp_type_t tstype;
    PPCODE:
        long timestamp = rd_kafka_message_timestamp(rd_msg, &tstype);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(timestamp)));
        PUSHs(sv_2mortal(newSViv(tstype)));

long
krdm_offset(rd_msg)
        rd_kafka_message_t *rd_msg
    CODE:
        /* that will truncate offset if perl doesn't support 64bit ints */
        RETVAL = rd_msg->offset;
    OUTPUT:
        RETVAL

rd_kafka_headers_t*
krdm_headers(rd_msg)
        rd_kafka_message_t* rd_msg
    PREINIT:
        rd_kafka_headers_t *hdrs;
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_message_headers(rd_msg, &hdrs);
        if (err == RD_KAFKA_RESP_ERR_NO_ERROR) {
            /* making a copy here avoids ownership nightmares */
            RETVAL = rd_kafka_headers_copy(hdrs);
        } else if (err == RD_KAFKA_RESP_ERR__NOENT) {
            XSRETURN_UNDEF;
        } else {
            croak("Error while getting headers: %s", rd_kafka_err2str(err));
        }
    OUTPUT:
        RETVAL

rd_kafka_headers_t*
krdm_detach_headers(rd_msg)
        rd_kafka_message_t* rd_msg
    PREINIT:
        rd_kafka_headers_t *hdrs;
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_message_detach_headers(rd_msg, &hdrs);
        if (err == RD_KAFKA_RESP_ERR_NO_ERROR) {
            RETVAL = hdrs;
        } else if (err == RD_KAFKA_RESP_ERR__NOENT) {
            XSRETURN_UNDEF;
        } else {
            croak("Error while getting headers: %s", rd_kafka_err2str(err));
        }
    OUTPUT:
        RETVAL

void
krdm_DESTROY(rd_msg)
        rd_kafka_message_t *rd_msg
    CODE:
        rd_kafka_message_destroy( rd_msg );

MODULE = Net::Kafka    PACKAGE = Net::Kafka::Headers    PREFIX = krdh_
PROTOTYPES: DISABLE

rd_kafka_headers_t*
krdh_new(klass)
        SV *klass
    CODE:
        RETVAL = rd_kafka_headers_new(0);
    OUTPUT:
        RETVAL

void
krdh_add(hdrs, name, value)
    PREINIT:
        STRLEN name_len, value_len;
        rd_kafka_resp_err_t err;
    INPUT:
        rd_kafka_headers_t* hdrs
        const char *name = SvPV($arg, name_len);
        const char *value = SvPV($arg, value_len);
    CODE:
        err = rd_kafka_header_add(hdrs, name, name_len, value, value_len);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error while adding header: %s", rd_kafka_err2str(err));
        }

void
krdh_remove(hdrs, name)
    PREINIT:
        rd_kafka_resp_err_t err;
    INPUT:
        rd_kafka_headers_t* hdrs
        const char *name
    CODE:
        err = rd_kafka_header_remove(hdrs, name);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error while removing header: %s", rd_kafka_err2str(err));
        }

void
krdh_get_last(hdrs, name)
    PREINIT:
        rd_kafka_resp_err_t err;
        const void *value;
        size_t value_len;
    INPUT:
        rd_kafka_headers_t* hdrs
        const char *name
    PPCODE:
        err = rd_kafka_header_get_last(hdrs, name, &value, &value_len);
        if (err == RD_KAFKA_RESP_ERR_NO_ERROR) {
            PUSHs(sv_2mortal(newSVpvn(value, value_len)));
        } else if (err == RD_KAFKA_RESP_ERR__NOENT) {
            XSRETURN_UNDEF;
        } else {
            croak("Error while getting header: %s", rd_kafka_err2str(err));
        }

HV*
krdh_to_hash(hdrs)
        rd_kafka_headers_t* hdrs
    PREINIT:
        rd_kafka_resp_err_t err;
        int i;
        const char *name;
        const void *value;
        size_t value_len;
        SV **slot;
        AV *value_list;
    CODE:
        RETVAL = newHV();
        for (i = 0; ; ++i) {
            err = rd_kafka_header_get_all(hdrs, i, &name, &value, &value_len);
            if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
               break;
            }
            slot = hv_fetch(RETVAL, name, strlen(name), 1);
            if (slot == NULL) { /* should never happen */
                croak("Error while building hash, lvalue fetch returned a NULL value");
            }
            if (!SvOK(*slot)) {
                value_list = newAV();

                SvUPGRADE(*slot, SVt_RV);
                SvROK_on(*slot);
                SvRV_set(*slot, (SV *) value_list);
            } else {
                value_list = (AV *) SvRV(*slot);
            }
            av_push(value_list, newSVpvn(value, value_len));
        }
    OUTPUT:
        RETVAL

void
krdh_DESTROY(hdrs)
        rd_kafka_headers_t* hdrs
    CODE:
        rd_kafka_headers_destroy(hdrs);

MODULE = Net::Kafka    PACKAGE = Net::Kafka::Error    PREFIX = krde_
PROTOTYPES: DISABLE

HV *
krde_rd_kafka_get_err_descs()
    PREINIT:
        const struct rd_kafka_err_desc* descs;
        size_t cnt;
        int i;
    CODE:
        rd_kafka_get_err_descs(&descs, &cnt);
        RETVAL = newHV();
        for (i = 0; i < cnt; i++) {
            if (descs[i].name != NULL) {
                hv_store(RETVAL, descs[i].name, strnlen(descs[i].name, 1024), newSViv(descs[i].code), 0);
            }
        }
    OUTPUT:
        RETVAL

const char*
krde_to_string(code)
        int code
    CODE:
        RETVAL = rd_kafka_err2str(code);
    OUTPUT:
        RETVAL

const char*
krde_to_name(code)
        int code
    CODE:
        RETVAL = rd_kafka_err2name(code);
    OUTPUT:
        RETVAL

int
krde_last_error()
    CODE:
        RETVAL = rd_kafka_last_error();
    OUTPUT:
        RETVAL

MODULE = Net::Kafka    PACKAGE = Net::Kafka::TopicPartitionList    PREFIX = ktpl_
PROTOTYPES: DISABLE

rd_kafka_topic_partition_list_t *
ktpl_new(class, initial_size = 10)
    char *class
    int initial_size
    CODE:
        RETVAL = rd_kafka_topic_partition_list_new(initial_size);
    OUTPUT:
        RETVAL

void
ktpl_add(rktpl, topic, partition)
        rd_kafka_topic_partition_list_t *rktpl
        char *topic
        int partition
    PREINIT:
        rd_kafka_topic_partition_t *tp;
    CODE:
        tp = rd_kafka_topic_partition_list_find(rktpl, topic, partition);
        if (tp == NULL) {
            rd_kafka_topic_partition_list_add(rktpl, topic, partition);
        }

rd_kafka_topic_partition_list_t*
ktpl_copy(rktpl)
        rd_kafka_topic_partition_list_t* rktpl
    CODE:
        RETVAL = rd_kafka_topic_partition_list_copy(rktpl);
    OUTPUT:
        RETVAL

void
ktpl_get(rktpl, idx)
        rd_kafka_topic_partition_list_t *rktpl
        int idx
    PPCODE:
        if (!rktpl || idx < 0 || idx >= rktpl->cnt) {
            return;
        }
        char* tn = rktpl->elems[idx].topic;
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSVpv(tn, strlen(tn))));
        PUSHs(sv_2mortal(newSViv(rktpl->elems[idx].partition)));
        PUSHs(sv_2mortal(newSViv(rktpl->elems[idx].offset)));

void
ktpl_set_offset(rktpl, topic, partition, offset)
        rd_kafka_topic_partition_list_t *rktpl
        char *topic
        int partition
        long offset
    PREINIT:
        rd_kafka_resp_err_t err;
    CODE:
        err = rd_kafka_topic_partition_list_set_offset(rktpl, topic, partition, offset);
        if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
            croak("Error setting offset: %s", rd_kafka_err2str(err));
        }

void
ktpl_offset(rktpl, topic, partition)
        rd_kafka_topic_partition_list_t *rktpl
        char *topic
        int partition
    PREINIT:
        rd_kafka_topic_partition_t *tp;
    PPCODE:
        tp = rd_kafka_topic_partition_list_find(rktpl, topic, partition);
        if (tp == NULL) {
            XSRETURN_EMPTY;
            return;
        }

        ST(0) = sv_2mortal(newSViv(tp->offset));
        XSRETURN(1);

int
ktpl_del(rktpl, topic, partition)
        rd_kafka_topic_partition_list_t *rktpl
        char *topic
        int partition
    CODE:
        RETVAL = rd_kafka_topic_partition_list_del(rktpl, topic, partition);
    OUTPUT:
        RETVAL

int
ktpl_size(rktpl)
        rd_kafka_topic_partition_list_t *rktpl
    CODE:
        RETVAL = (rktpl == NULL ? 0 : rktpl->cnt);
    OUTPUT:
        RETVAL

void
ktpl_DESTROY(rktpl)
        rd_kafka_topic_partition_list_t *rktpl
    CODE:
        rd_kafka_topic_partition_list_destroy(rktpl);
