#include "netkafka.h"

static rd_kafka_topic_partition_list_t *krd_topic_partition_list_copy_shrinked(rd_kafka_topic_partition_list_t * ktpl)
{
    int orig_size = ktpl->size;
    ktpl->size = ktpl->cnt;
    rd_kafka_topic_partition_list_t *shrinked_ktpl = rd_kafka_topic_partition_list_copy(ktpl);
    ktpl->size = orig_size;
    return shrinked_ktpl;
}

static int
krd_fill_topic_config(pTHX_ plrd_kafka_t * krd, rd_kafka_topic_conf_t * topic_conf, char *errstr, HV * params)
{
    rd_kafka_conf_res_t res;
    HE *he;

    hv_iterinit(params);
    while ((he = hv_iternext(params)) != NULL) {
        STRLEN len;
        char *key = HePV(he, len);
        SV *val = HeVAL(he);
        char *strval = SvPV(val, len);
        DEBUGF(krd->debug_xs, "Setting topic config '%s' to '%s'", key, strval);
        res = rd_kafka_topic_conf_set(topic_conf, key, strval, errstr, ERRSTR_SIZE);
        if (res != RD_KAFKA_CONF_OK)
            return 1;
    }
    return 0;
}

static void
cns_commit_cb(rd_kafka_t * rk, rd_kafka_resp_err_t err, rd_kafka_topic_partition_list_t * offsets, void *opaque)
{
    dTHX;
    plrd_kafka_t *krd = (plrd_kafka_t *) opaque;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 3);

    DEBUG2F(krd->debug_xs, "Commit callback signaling");

    SV *sv_offsets = sv_newmortal();
    sv_setref_pv(sv_offsets, "Net::Kafka::TopicPartitionList", (void *)krd_topic_partition_list_copy_shrinked(offsets));

    PUSHs(sv_2mortal(newSVsv(krd->self)));
    PUSHs(sv_2mortal(newSViv(err)));
    PUSHs(sv_offsets);
    PUTBACK;
    call_sv(krd->commit_cb, G_DISCARD);
    FREETMPS;
    LEAVE;
}

static void
cns_rebalance_cb(rd_kafka_t * rk, rd_kafka_resp_err_t err, rd_kafka_topic_partition_list_t * partitions, void *opaque)
{
    dTHX;
    plrd_kafka_t *krd = (plrd_kafka_t *) opaque;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 3);

    DEBUG2F(krd->debug_xs, "Rebalance callback signaling");

    SV *err_tmp;
    SV *sv_partitions = sv_newmortal();
    sv_setref_pv(sv_partitions, "Net::Kafka::TopicPartitionList",
                 (void *)krd_topic_partition_list_copy_shrinked(partitions));

    PUSHs(sv_2mortal(newSVsv(krd->self)));
    PUSHs(sv_2mortal(newSViv(err)));
    PUSHs(sv_partitions);
    PUTBACK;
    call_sv(krd->rebalance_cb, G_DISCARD | G_EVAL);
    SPAGAIN;
    err_tmp = ERRSV;
    if (SvTRUE(err_tmp)) {
        rd_kafka_assign(rk, NULL);
        croak("%s\n", SvPV_nolen(err_tmp));
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
}

static void cns_error_cb(rd_kafka_t * rk, int err, const char *reason, void *opaque)
{
    dTHX;
    plrd_kafka_t *krd = (plrd_kafka_t *) opaque;
    DEBUG2F(krd->debug_xs, "Error callback signaling");
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 3);
    PUSHs(sv_2mortal(newSVsv(krd->self)));
    PUSHs(sv_2mortal(newSViv(err)));
    PUSHs(sv_2mortal(newSVpv(reason, strlen(reason))));
    PUTBACK;
    call_sv(krd->error_cb, G_DISCARD);
    FREETMPS;
    LEAVE;
}

static int cns_stats_cb(rd_kafka_t * rk, char *json, size_t json_len, void *opaque)
{
    dTHX;
    plrd_kafka_t *krd = (plrd_kafka_t *) opaque;
    DEBUG2F(krd->debug_xs, "Stats callback signaling");
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 3);
    PUSHs(sv_2mortal(newSVsv(krd->self)));
    PUSHs(sv_2mortal(newSVpvn(json, json_len)));
    PUTBACK;
    call_sv(krd->stats_cb, G_DISCARD);
    FREETMPS;
    LEAVE;
    return 0;                   /* libkrdafka can free the JSON */
}

void cns_init(plrd_kafka_t * krd, rd_kafka_conf_t * conf)
{
    if (krd->stats_cb != NULL) {
        DEBUGF(krd->debug_xs, "Setting custom consumer stats callback");
        rd_kafka_conf_set_stats_cb(conf, cns_stats_cb);
    }

    if (krd->error_cb != NULL) {
        DEBUGF(krd->debug_xs, "Setting custom consumer error callback");
        rd_kafka_conf_set_error_cb(conf, cns_error_cb);
    }

    if (krd->rebalance_cb != NULL) {
        DEBUGF(krd->debug_xs, "Setting custom rebalance callback");
        rd_kafka_conf_set_rebalance_cb(conf, cns_rebalance_cb);
    }

    if (krd->commit_cb != NULL) {
        DEBUGF(krd->debug_xs, "Setting custom commit callback");
        rd_kafka_conf_set_offset_commit_cb(conf, cns_commit_cb);
    }
}

void prd_init(plrd_kafka_t * krd, rd_kafka_conf_t * conf)
{
    if (krd->queue_fd == -1) {
        croak("'queue_fd' is missing from params");
    }
    if (krd->stats_cb != NULL || krd->error_cb != NULL || krd->rebalance_cb != NULL || krd->commit_cb != NULL) {
        croak("Net::Kafka::Producer must not pass any perl callbacks");
    }
    DEBUGF(krd->debug_xs,
           "Subscribing producer to RD_KAFKA_EVENT_DR | RD_KAFKA_EVENT_ERROR | RD_KAFKA_EVENT_STATS events");
    rd_kafka_conf_set_events(conf, RD_KAFKA_EVENT_DR | RD_KAFKA_EVENT_ERROR | RD_KAFKA_EVENT_STATS);
}

void prd_start(plrd_kafka_t * krd)
{
    krd->queue = rd_kafka_queue_get_main(krd->rk);
    rd_kafka_queue_io_event_enable(krd->queue, krd->queue_fd, "1", 1);
    DEBUGF(krd->debug_xs, "Created IO event queue with fd %d", krd->queue_fd);
}

void cns_start(plrd_kafka_t * krd)
{
    // redirect rd_kafka_poll to consumer_poll()
    rd_kafka_poll_set_consumer(krd->rk);
}

void krd_close_handles(plrd_kafka_t * krd)
{
    if (krd->is_closed) {
        return;
    }

    rd_kafka_t *rk = krd->rk;
    if (krd->type == RD_KAFKA_PRODUCER) {
        DEBUGF(krd->debug_xs, "Closing producer...");
        prd_stop(krd);
        DEBUGF(krd->debug_xs, "Closed producer.");
    } else {
        DEBUGF(krd->debug_xs, "Closing consumer...");
        cns_stop(krd);
        DEBUGF(krd->debug_xs, "Closed consumer.");
    }
    DEBUGF(krd->debug_xs, "Closing rk handle...");
    rd_kafka_destroy(rk);
    DEBUGF(krd->debug_xs, "Closed rk handle.");
    krd->is_closed = 1;
}

void prd_stop(plrd_kafka_t * krd)
{
    DEBUGF(krd->debug_xs, "Closing IO event queue...");
    rd_kafka_queue_destroy(krd->queue);
    DEBUGF(krd->debug_xs, "Closed IO event queue.");
}

void cns_stop(plrd_kafka_t * krd)
{
    rd_kafka_consumer_close(krd->rk);
}

rd_kafka_conf_t *krd_parse_config(pTHX_ plrd_kafka_t * krd, HV * params)
{
    char errstr[ERRSTR_SIZE];
    rd_kafka_conf_t *conf = rd_kafka_conf_new();
    rd_kafka_topic_conf_t *topic_conf = rd_kafka_topic_conf_new();
    rd_kafka_conf_res_t res;
    HE *he;

    krd->debug_xs = 0;
    krd->queue_fd = -1;

    if (params) {
        hv_iterinit(params);

        SV *debug_xs = hv_delete(params, "debug.xs", strlen("debug.xs"), 0);
        if (debug_xs != NULL && SvOK(debug_xs)) {
            krd->debug_xs = SvIV(debug_xs);
            DEBUGF(krd->debug_xs, "XS debug enabled: %d", krd->debug_xs);
        }

        while ((he = hv_iternext(params)) != NULL) {
            STRLEN len;
            char *key = HePV(he, len);
            SV *val = HeVAL(he);

            if (strncmp(key, "rebalance_cb", len) == 0) {
                krd->rebalance_cb = newSVsv(val);
            } else if (strncmp(key, "offset_commit_cb", len) == 0) {
                krd->commit_cb = newSVsv(val);
            } else if (strncmp(key, "error_cb", len) == 0) {
                krd->error_cb = newSVsv(val);
            } else if (strncmp(key, "stats_cb", len) == 0) {
                krd->stats_cb = newSVsv(val);
            } else if (strncmp(key, "queue_fd", len) == 0) {
                krd->queue_fd = SvIV(val);
            } else if (strncmp(key, "default_topic_config", len) == 0) {
                if (!SvROK(val) || strncmp(sv_reftype(SvRV(val), 0), "HASH", 5) != 0) {
                    strncpy(errstr, "default_topic_config must be a hash reference", ERRSTR_SIZE);
                    goto CROAK;
                }
                if (krd_fill_topic_config(aTHX_ krd, topic_conf, errstr, (HV *) SvRV(val)) != 0)
                    goto CROAK;
            } else {
                // set named configuration property
                char *strval = SvPV(val, len);
                DEBUGF(krd->debug_xs, "Setting global config '%s' to '%s'", key, strval);
                res = rd_kafka_conf_set(conf, key, strval, errstr, ERRSTR_SIZE);
                if (res != RD_KAFKA_CONF_OK)
                    goto CROAK;
            }
        }
    }

    rd_kafka_conf_set_opaque(conf, (void *)krd);
    rd_kafka_topic_conf_set_opaque(topic_conf, (void *)krd);
    rd_kafka_conf_set_default_topic_conf(conf, topic_conf);
    return conf;

 CROAK:
    rd_kafka_conf_destroy(conf);
    rd_kafka_topic_conf_destroy(topic_conf);
    croak("%s", errstr);
    return NULL;
}
