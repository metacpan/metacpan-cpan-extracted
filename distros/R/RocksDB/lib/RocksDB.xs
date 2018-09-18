#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#define NEED_newRV_noinc
#define NEED_sv_2pvbyte
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#ifdef do_open
#undef do_open
#endif
#ifdef do_close
#undef do_close
#endif

#pragma push_macro("NORMAL")
#undef NORMAL
#include <rocksdb/db.h>
#include <rocksdb/env.h>
#include <rocksdb/cache.h>
#include <rocksdb/comparator.h>
#include <rocksdb/write_batch.h>
#include <rocksdb/filter_policy.h>
#include <rocksdb/universal_compaction.h>
#include <rocksdb/slice_transform.h>
#include <rocksdb/compaction_filter.h>
#include <rocksdb/merge_operator.h>
#include <rocksdb/statistics.h>
#include <rocksdb/ldb_tool.h>
#include <rocksdb/table.h>
#pragma pop_macro("NORMAL")

#define DESTROY_ROCKSDB_OBJ(self) STMT_START { \
    mg_free(SvRV(self)); \
} STMT_END

#define IS_VALID_ROCKSDB_OBJ(sv, pkg, type) \
    (sv_isobject(sv) \
    && sv_derived_from(sv, pkg) \
    && mg_find(SvRV(sv), PERL_MAGIC_ext) != NULL \
    && mg_find(SvRV(sv), PERL_MAGIC_ext)->mg_private == type)

#define GET_MAGIC_PTR(sv) (mg_find(sv, PERL_MAGIC_ext)->mg_ptr)

#define GET_MAGIC_PTR_OBJ(sv) (mg_find((SV *) mg_find(SvRV(sv), PERL_MAGIC_ext)->mg_ptr, PERL_MAGIC_ext)->mg_obj)

#define GET_MAGIC_OBJ(sv) (mg_find(SvRV(sv), PERL_MAGIC_ext)->mg_obj)

#define FIND_MAGIC_OBJ(sv, pkg, type) \
    (IS_VALID_ROCKSDB_OBJ(sv, pkg, type) ? GET_MAGIC_OBJ(sv) : NULL)

#define SvRTypeEQ(sv, type) \
    (sv != NULL && SvOK(sv) && SvROK(sv) && SvTYPE(SvRV(sv)) == type)

#define SvCodeRefOK(sv) SvRTypeEQ(sv, SVt_PVCV)

#define SvHashRefOK(sv) SvRTypeEQ(sv, SVt_PVHV)

#define SvArrayRefOK(sv) SvRTypeEQ(sv, SVt_PVAV)

#define CHECK_ITER_VALID(it) STMT_START { \
    if (!it->Valid()) \
        croak("Iterator is not Valid()"); \
} STMT_END

#define CROAK_ON_ERROR(status) STMT_START { \
    if (!status.ok()) \
        croak("%s", status.ToString().c_str()); \
} STMT_END

#define SV2SLICE(sv, slice) STMT_START { \
    STRLEN _len_##slice; \
    const char* _str_##slice = SvPVbyte(sv, _len_##slice); \
    slice = rocksdb::Slice(_str_##slice, _len_##slice); \
} STMT_END

#define TYPE_ROCKSDB_CACHE                  (1)
#define TYPE_ROCKSDB_COMPARATOR             (2)
#define TYPE_ROCKSDB_DB                     (3)
#define TYPE_ROCKSDB_ITERATOR               (4)
#define TYPE_ROCKSDB_SNAPSHOT               (5)
#define TYPE_ROCKSDB_WRITEBATCH             (6)
#define TYPE_ROCKSDB_FILTERPOLICY           (7)
#define TYPE_ROCKSDB_COMPACTIONFILTER       (8)
#define TYPE_ROCKSDB_SLICETRANSFORM         (9)
#define TYPE_ROCKSDB_TRANSACTIONLOGITERATOR (10)
#define TYPE_ROCKSDB_BATCHRESULT            (11)
#define TYPE_ROCKSDB_MERGEOPERATOR          (12)
#define TYPE_ROCKSDB_STATISTICS             (13)
#define TYPE_ROCKSDB_WRITEBATCHHANDLER      (14)
#define TYPE_ROCKSDB_LDBTOOL                (15)

namespace RocksDB {

struct DB {
    rocksdb::DB* db;
    rocksdb::Iterator* it;
    SV* fields;

    DB(rocksdb::DB* db, SV* fields) : db(db), it(NULL), fields(fields) {}

    ~DB() {
        dTHX;
        SvREFCNT_dec(fields);
        if (it != NULL)
            delete it;
        delete db;
    }
};

struct Cache {
    Cache(std::shared_ptr<rocksdb::Cache> ptr) {
        this->ptr = ptr;
    }
    std::shared_ptr<rocksdb::Cache> ptr;
};

struct FilterPolicy {
    FilterPolicy(const rocksdb::FilterPolicy* policy) {
        this->ptr = std::shared_ptr<const rocksdb::FilterPolicy>(policy);
    }
    std::shared_ptr<const rocksdb::FilterPolicy> ptr;
};

struct Statistics {
    Statistics(std::shared_ptr<rocksdb::Statistics> ptr) {
        this->ptr = ptr;
    }

    std::shared_ptr<rocksdb::Statistics> ptr;

    static SV* HistogramDataToHashRef(pTHX_ rocksdb::HistogramData* data) {
        HV* hash = newHV();
        hv_stores(hash, "median", newSVnv(data->median));
        hv_stores(hash, "percentile95", newSVnv(data->percentile95));
        hv_stores(hash, "percentile99", newSVnv(data->percentile99));
        hv_stores(hash, "average", newSVnv(data->average));
        hv_stores(hash, "standard_deviation", newSVnv(data->standard_deviation));
        return newRV_noinc((SV*) hash);
    }
};

struct MergeOperator {
    MergeOperator(std::shared_ptr<rocksdb::MergeOperator> ptr) {
        this->ptr = ptr;
    }
    std::shared_ptr<rocksdb::MergeOperator> ptr;
};

struct TransactionLogIterator {
    std::unique_ptr<rocksdb::TransactionLogIterator> ptr;
};

struct BatchResult {
    BatchResult(rocksdb::BatchResult result) {
        this->sequence = result.sequence;
        this->writeBatchPtr = std::move(result.writeBatchPtr);
    }
    rocksdb::SequenceNumber sequence;
    std::unique_ptr<rocksdb::WriteBatch> writeBatchPtr;
};

class WriteBatchHandler : public rocksdb::WriteBatch::Handler {
public:
    WriteBatchHandler(SV* handler) : handler(handler) {
        dTHX;
        SvREFCNT_inc_simple_void_NN(handler);
    }

    ~WriteBatchHandler() {
        dTHX;
        SvREFCNT_dec(handler);
    }

    void Put(const rocksdb::Slice& key, const rocksdb::Slice& value) override {
        dTHX;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHs(SvREFCNT_inc_simple_NN(handler));
        mXPUSHs(newSVpvn(key.data(), key.size()));
        mXPUSHs(newSVpvn(value.data(), value.size()));
        PUTBACK;
        (void) call_method("put", G_EVAL|G_DISCARD);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            warn("RocksDB::WriteBatchHandler::put: %s", SvPV_nolen_const(ERRSV));
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    void Merge(const rocksdb::Slice& key, const rocksdb::Slice& value) override {
        dTHX;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHs(SvREFCNT_inc_simple_NN(handler));
        mXPUSHs(newSVpvn(key.data(), key.size()));
        mXPUSHs(newSVpvn(value.data(), value.size()));
        PUTBACK;
        (void) call_method("merge", G_EVAL|G_DISCARD);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            warn("RocksDB::WriteBatchHandler::merge: %s", SvPV_nolen_const(ERRSV));
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    void LogData(const rocksdb::Slice& blob) override {
        dTHX;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHs(SvREFCNT_inc_simple_NN(handler));
        mXPUSHs(newSVpvn(blob.data(), blob.size()));
        PUTBACK;
        (void) call_method("log_data", G_EVAL|G_DISCARD);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            warn("RocksDB::WriteBatchHandler::log_data: %s", SvPV_nolen_const(ERRSV));
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    void Delete(const rocksdb::Slice& key) override {
        dTHX;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHs(SvREFCNT_inc_simple_NN(handler));
        mXPUSHs(newSVpvn(key.data(), key.size()));
        PUTBACK;
        (void) call_method("delete", G_EVAL|G_DISCARD);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            warn("RocksDB::WriteBatchHandler::delete: %s", SvPV_nolen_const(ERRSV));
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    bool Continue() override {
        dTHX;
        bool ret;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHs(SvREFCNT_inc_simple_NN(handler));
        PUTBACK;
        int count = call_method("continue", G_EVAL|G_SCALAR);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            warn("RocksDB::WriteBatchHandler::continue: %s", SvPV_nolen_const(ERRSV));
            POPs;
            ret = false;
        } else if (count == 1) {
            SV* res = POPs;
            ret = SvTRUE(res);
        } else {
            croak("RocksDB::WriteBatchHandler::continue: wanted 1 value, got %d", count);
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
        return ret;
    }

private:
    SV* handler;
};

class MergeOperatorImpl : public rocksdb::MergeOperator {
public:
    MergeOperatorImpl(SV* handler) : handler(handler) {
        dTHX;
        SvREFCNT_inc_simple_void_NN(handler);
    }

    ~MergeOperatorImpl() {
        dTHX;
        SvREFCNT_dec(handler);
    }

    bool FullMerge(const rocksdb::Slice& key,
            const rocksdb::Slice* existing_value,
            const std::deque<std::string>& operand_list,
            std::string* new_value,
            rocksdb::Logger* logger) const override {
        dTHX;
        bool ret = false;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHs(SvREFCNT_inc_simple_NN(handler));
        mXPUSHs(newSVpvn(key.data(), key.size()));
        if (existing_value != NULL) {
            mXPUSHs(newSVpvn(existing_value->data(), existing_value->size()));
        } else {
            mXPUSHs(newSV(0));
        }
        AV* operands = newAV();
        for (const auto &operand : operand_list) {
            av_push(operands, newSVpvn(operand.c_str(), operand.size()));
        }
        mXPUSHs(newRV_noinc((SV*) operands));
        PUTBACK;
        int count = call_method("full_merge", G_EVAL|G_SCALAR);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            const char* err = SvPV_nolen_const(ERRSV);
            rocksdb::Log(logger, "RocksDB::MergeOperator::full_merge failed: %s", err);
            ret = false;
        } else if (count == 1) {
            SV* sv_new_value = POPs;
            STRLEN len;
            const char* str = SvPVbyte(sv_new_value, len);
            new_value->assign(str, len);
            ret = true;
        } else {
            croak("full_merge: wanted 1 value, got %d", count);
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
        return ret;
    }

    bool PartialMerge(const rocksdb::Slice& key,
            const rocksdb::Slice& left_operand,
            const rocksdb::Slice& right_operand,
            std::string* new_value,
            rocksdb::Logger* logger) const override {
        dTHX;
        bool ret = false;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHs(SvREFCNT_inc_simple_NN(handler));
        mXPUSHs(newSVpvn(key.data(), key.size()));
        mXPUSHs(newSVpvn(left_operand.data(), left_operand.size()));
        mXPUSHs(newSVpvn(right_operand.data(), right_operand.size()));
        PUTBACK;
        int count = call_method("partial_merge", G_EVAL|G_SCALAR);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            const char* err = SvPV_nolen_const(ERRSV);
            rocksdb::Log(logger, "RocksDB::MergeOperator::partial_merge failed: %s", err);
            ret = false;
        } else if (count == 1) {
            SV* sv_new_value = POPs;
            STRLEN len;
            const char* str = SvPVbyte(sv_new_value, len);
            new_value->assign(str, len);
            ret = true;
        } else {
            croak("partial_merge: wanted 1 value, got %d", count);
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
        return ret;
    }

    const char* Name() const override {
        dTHX;
        return HvNAME(SvSTASH(SvRV(handler)));
    }

private:
    SV* handler;
};

class AssociativeMergeOperatorImpl : public rocksdb::AssociativeMergeOperator {
public:
    AssociativeMergeOperatorImpl(SV* handler) : handler(handler) {
        dTHX;
        SvREFCNT_inc_simple_void_NN(handler);
    }

    ~AssociativeMergeOperatorImpl() {
        dTHX;
        SvREFCNT_dec(handler);
    }

    bool Merge(const rocksdb::Slice& key,
            const rocksdb::Slice* existing_value,
            const rocksdb::Slice& value,
            std::string* new_value,
            rocksdb::Logger* logger) const override {
        dTHX;
        bool ret = false;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHs(SvREFCNT_inc_simple_NN(handler));
        mXPUSHs(newSVpvn(key.data(), key.size()));
        if (existing_value != NULL) {
            mXPUSHs(newSVpvn(existing_value->data(), existing_value->size()));
        } else {
            mXPUSHs(newSV(0));
        }
        mXPUSHs(newSVpvn(value.data(), value.size()));
        PUTBACK;
        int count = call_method("merge", G_EVAL|G_SCALAR);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            const char* err = SvPV_nolen_const(ERRSV);
            rocksdb::Log(logger, "RocksDB::AssociativeMergeOperator::merge failed: %s", err);
            ret = false;
        } else if (count == 1) {
            SV* sv_new_value = POPs;
            STRLEN len;
            const char* str = SvPVbyte(sv_new_value, len);
            new_value->assign(str, len);
            ret = true;
        } else {
            croak("merge: wanted 1 value, got %d", count);
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
        return ret;
    }

    const char* Name() const override {
        dTHX;
        return HvNAME(SvSTASH(SvRV(handler)));
    }

private:
    SV* handler;
};

class Comparator : public rocksdb::Comparator {
private:
    SV* handler;
public:
    Comparator(SV* handler) : handler(handler) {
        dTHX;
        SvREFCNT_inc_simple_void_NN(handler);
    }

    ~Comparator() {
        dTHX;
        SvREFCNT_dec(handler);
    }

    int Compare(const rocksdb::Slice& a, const rocksdb::Slice& b) const override {
        dTHX;
        int res;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHs(SvREFCNT_inc_simple_NN(handler));
        mXPUSHs(newSVpvn(a.data(), a.size()));
        mXPUSHs(newSVpvn(b.data(), b.size()));
        PUTBACK;
        int count = call_method("compare", G_EVAL|G_SCALAR);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            warn("RocksDB::Comparator::compare: %s", SvPV_nolen_const(ERRSV));
            POPs;
            res = 0;
        } else if (count == 1) {
            res = POPi;
        } else {
            croak("compare: wanted 1 value, got %d", count);
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
        return res;
    }

    const char* Name() const override {
        dTHX;
        return HvNAME(SvSTASH(SvRV(handler)));
    }

    void FindShortestSeparator(std::string* start, const rocksdb::Slice& limit) const override {
        /* Not supported yet */
    }

    void FindShortSuccessor(std::string* key) const override {
        /* Not supported yet */
    }
};

class CompactionFilter : public rocksdb::CompactionFilter {
private:
    SV* handler;
public:
    CompactionFilter(SV* handler) : handler(handler) {
        dTHX;
        SvREFCNT_inc_simple_void_NN(handler);
    }

    ~CompactionFilter() {
        dTHX;
        SvREFCNT_dec(handler);
    }

    bool Filter(int level, const rocksdb::Slice& key,
            const rocksdb::Slice& existing_value, std::string* new_value,
            bool* value_changed) const override {
        dTHX;
        bool ret;
        SV* res;
        SV* sv_new_value;
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHs(SvREFCNT_inc_simple_NN(handler));
        mXPUSHs(newSViv(level));
        mXPUSHs(newSVpvn(key.data(), key.size()));
        mXPUSHs(newSVpvn(existing_value.data(), existing_value.size()));
        mXPUSHs(sv_new_value = newRV_noinc(newSV(0)));
        PUTBACK;
        int count = call_method("filter", G_EVAL|G_SCALAR);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            warn("RocksDB::CompactionFilter::filter: %s", SvPV_nolen_const(ERRSV));
            POPs;
            res = NULL;
            ret = false;
        } else if (count == 1) {
            res = POPs;
            ret = true;
        } else {
            croak("compare: wanted 1 value, got %d", count);
        }
        ret = res == NULL ? false : SvTRUE(res);
        if (SvOK(SvRV(sv_new_value))) {
            STRLEN len;
            const char* s = SvPV(SvRV(sv_new_value), len);
            new_value->assign(s, len);
            *value_changed = true;
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
        return ret;
    }

    const char* Name() const override {
        dTHX;
        return HvNAME(SvSTASH(SvRV(handler)));
    }
};

struct SliceTransform {
    SliceTransform(std::shared_ptr<const rocksdb::SliceTransform> ptr) {
        this->ptr = ptr;
    }
    std::shared_ptr<const rocksdb::SliceTransform> ptr;
};

class SVLogger : public rocksdb::Logger {
public:
    SVLogger() {
        dTHX;
        sv = newSV(0);
    }
    ~SVLogger() {
        dTHX;
        SvREFCNT_dec(sv);
    }
    virtual void Logv(const char* format, va_list ap) override {
        dTHX;
        va_list ap2;
        va_copy(ap2, ap);
        sv_vcatpvf(sv, format, &ap2);
    }
    SV* GetSV() {
        return sv;
    }
private:
    SV* sv;
};

}

static rocksdb::CompressionType
sv_to_compression_type(pTHX_ SV* sv, const char* name) {
    if (SvTRUE(sv)) {
        STRLEN len;
        char* str = SvPV(sv, len);
        if (strnEQ(str, "snappy", len)) {
            return rocksdb::kSnappyCompression;
        } else if (strnEQ(str, "zlib", len)) {
            return rocksdb::kZlibCompression;
        } else if (strnEQ(str, "bzip2", len)) {
            return rocksdb::kBZip2Compression;
        } else if (strnEQ(str, "lz4", len)) {
            return rocksdb::kLZ4Compression;
        } else if (strnEQ(str, "lz4hc", len)) {
            return rocksdb::kLZ4HCCompression;
        } else {
            croak("invalid value '%s' for compression", name);
            return rocksdb::kNoCompression; /* NOT REACHED */
        }
    } else {
        return rocksdb::kNoCompression;
    }
}

static void
apply_block_based_table_options(pTHX_ rocksdb::BlockBasedTableOptions* opts, HV* options, AV* fields) {
    SV** val;
    if (val = hv_fetchs(options, "cache_index_and_filter_blocks", 0))
        opts->cache_index_and_filter_blocks = SvTRUE(*val);
    if (val = hv_fetchs(options, "index_type", 0)) {
        STRLEN len;
        char* str = SvPV(*val, len);
        if (strnEQ(str, "binary_search", len)) {
            opts->index_type = rocksdb::BlockBasedTableOptions::IndexType::kBinarySearch;
        } else if (strnEQ(str, "hash_search", len)) {
            opts->index_type = rocksdb::BlockBasedTableOptions::IndexType::kHashSearch;
        } else {
            croak("invalid value '%s' for index_type", str);
        }
    }
    if (val = hv_fetchs(options, "hash_index_allow_collision", 0))
        opts->hash_index_allow_collision = SvTRUE(*val);
    if (val = hv_fetchs(options, "checksum", 0)) {
        STRLEN len;
        char* str = SvPV(*val, len);
        if (strnEQ(str, "no_checksum", len)) {
            opts->checksum = rocksdb::ChecksumType::kNoChecksum;
        } else if (strnEQ(str, "crc32c", len)) {
            opts->checksum = rocksdb::ChecksumType::kCRC32c;
        } else if (strnEQ(str, "xxhash", len)) {
            opts->checksum = rocksdb::ChecksumType::kxxHash;
        } else {
            croak("invalid value '%s' for checksum", str);
        }
    }
    if (val = hv_fetchs(options, "block_cache", 0)) {
        if (RocksDB::Cache *cache =
                (RocksDB::Cache*) FIND_MAGIC_OBJ(*val, "RocksDB::Cache",
                        TYPE_ROCKSDB_CACHE)) {
            av_push(fields, SvREFCNT_inc_simple_NN(*val));
            opts->block_cache = cache->ptr;
        } else {
            croak("block_cache is not of type RocksDB::Cache");
        }
    }
    if (val = hv_fetchs(options, "block_cache_compressed", 0)) {
        if (RocksDB::Cache *cache =
                (RocksDB::Cache*) FIND_MAGIC_OBJ(*val, "RocksDB::Cache",
                        TYPE_ROCKSDB_CACHE)) {
            av_push(fields, SvREFCNT_inc_simple_NN(*val));
            opts->block_cache_compressed = cache->ptr;
        } else {
            croak("block_cache is not of type RocksDB::Cache");
        }
    }
    if (val = hv_fetchs(options, "block_size", 0))
        opts->block_size = SvIV(*val);
    if (val = hv_fetchs(options, "block_restart_interval", 0))
        opts->block_restart_interval = SvIV(*val);
    if (val = hv_fetchs(options, "filter_policy", 0)) {
        if (RocksDB::FilterPolicy* policy =
                (RocksDB::FilterPolicy*) FIND_MAGIC_OBJ(*val, "RocksDB::FilterPolicy",
                        TYPE_ROCKSDB_FILTERPOLICY)) {
            av_push(fields, SvREFCNT_inc_simple_NN(*val));
            opts->filter_policy = policy->ptr;
        } else {
            croak("filter_policy is not of type RocksDB::FilterPolicy");
        }
    }
    if (val = hv_fetchs(options, "whole_key_filtering", 0))
        opts->whole_key_filtering = SvTRUE(*val);
    if (val = hv_fetchs(options, "no_block_cache", 0))
        opts->no_block_cache = SvTRUE(*val);
    if (val = hv_fetchs(options, "block_size_deviation", 0))
        opts->block_size_deviation = SvIV(*val);
}

static void
apply_plain_table_options(pTHX_ rocksdb::PlainTableOptions * opts, HV* options, AV* fields) {
    SV** val;
    if (val = hv_fetchs(options, "user_key_len", 0))
        opts->user_key_len = SvIV(*val);
    if (val = hv_fetchs(options, "bloom_bits_per_key", 0))
        opts->bloom_bits_per_key = SvIV(*val);
    if (val = hv_fetchs(options, "hash_table_ratio", 0))
        opts->hash_table_ratio = SvNV(*val);
    if (val = hv_fetchs(options, "index_sparseness", 0))
        opts->index_sparseness = SvIV(*val);
    if (val = hv_fetchs(options, "huge_page_tlb_size", 0))
        opts->huge_page_tlb_size = SvIV(*val);
    if (val = hv_fetchs(options, "encoding_type", 0)) {
        STRLEN len;
        char* str = SvPV(*val, len);
        if (strnEQ(str, "plain", len)) {
            opts->encoding_type = rocksdb::EncodingType::kPlain;
        } else if (strnEQ(str, "prefix", len)) {
            opts->encoding_type = rocksdb::EncodingType::kPrefix;
        } else {
            croak("invalid value '%s' for encoding_type", str);
        }
    }
    if (val = hv_fetchs(options, "full_scan_mode", 0))
        opts->full_scan_mode = SvTRUE(*val);
    if (val = hv_fetchs(options, "store_index_in_file", 0))
        opts->store_index_in_file = SvTRUE(*val);
}

static void
apply_cuckoo_table_options(pTHX_ rocksdb::CuckooTableOptions * opts, HV* options, AV* fields) {
    SV** val;
    if (val = hv_fetchs(options, "hash_table_ratio", 0))
        opts->hash_table_ratio = SvNV(*val);
    if (val = hv_fetchs(options, "max_search_depth", 0))
        opts->max_search_depth = SvIV(*val);
    if (val = hv_fetchs(options, "cuckoo_block_size", 0))
        opts->cuckoo_block_size = SvIV(*val);
    if (val = hv_fetchs(options, "identity_as_first_hash", 0))
        opts->identity_as_first_hash = SvTRUE(*val);
    if (val = hv_fetchs(options, "use_module_hash", 0))
        opts->use_module_hash = SvTRUE(*val);
}

static void
apply_options(pTHX_ rocksdb::Options* opts, HV* options, AV* fields) {
    SV** val;
    if (val = hv_fetchs(options, "IncreaseParallelism", 0))
        opts->IncreaseParallelism();
    if (val = hv_fetchs(options, "PrepareForBulkLoad", 0))
        opts->PrepareForBulkLoad();
    if (val = hv_fetchs(options, "OptimizeForPointLookup", 0))
        opts->OptimizeForPointLookup(SvIV(*val));
    if (val = hv_fetchs(options, "OptimizeLevelStyleCompaction", 0)) {
        if (SvOK(*val)) {
            opts->OptimizeLevelStyleCompaction(SvIV(*val));
        } else {
            opts->OptimizeLevelStyleCompaction();
        }
    }
    if (val = hv_fetchs(options, "OptimizeUniversalStyleCompaction", 0)) {
        if (SvOK(*val)) {
            opts->OptimizeUniversalStyleCompaction(SvIV(*val));
        } else {
            opts->OptimizeUniversalStyleCompaction();
        }
    }
    if (val = hv_fetchs(options, "comparator", 0)) {
        if (RocksDB::Comparator* cmp =
                (RocksDB::Comparator*) FIND_MAGIC_OBJ(*val, "RocksDB::Comparator",
                        TYPE_ROCKSDB_COMPARATOR)) {
            av_push(fields, SvREFCNT_inc_simple_NN(*val));
            opts->comparator = cmp;
        } else {
            croak("comparator is not of type RocksDB::Comparator");
        }
    }
    if (val = hv_fetchs(options, "merge_operator", 0)) {
        if (RocksDB::MergeOperator* ope =
                (RocksDB::MergeOperator*) FIND_MAGIC_OBJ(*val, "RocksDB::MergeOperator",
                        TYPE_ROCKSDB_MERGEOPERATOR)) {
            av_push(fields, SvREFCNT_inc_simple_NN(*val));
            opts->merge_operator = ope->ptr;
        } else {
            croak("merge_operator is not of type RocksDB::MergeOperator");
        }
    }
    if (val = hv_fetchs(options, "compaction_filter", 0)) {
        if (RocksDB::CompactionFilter* filter =
                (RocksDB::CompactionFilter*) FIND_MAGIC_OBJ(*val, "RocksDB::CompactionFilter",
                        TYPE_ROCKSDB_COMPACTIONFILTER)) {
            av_push(fields, SvREFCNT_inc_simple_NN(*val));
            opts->compaction_filter = filter;
        } else {
            croak("compaction_filter is not of type RocksDB::CompactionFilter");
        }
    }
    if (val = hv_fetchs(options, "create_if_missing", 0))
        opts->create_if_missing = SvTRUE(*val);
    if (val = hv_fetchs(options, "error_if_exists", 0))
        opts->error_if_exists = SvTRUE(*val);
    if (val = hv_fetchs(options, "paranoid_checks", 0))
        opts->paranoid_checks = SvTRUE(*val);
    if (val = hv_fetchs(options, "write_buffer_size", 0))
        opts->write_buffer_size = SvIV(*val);
    if (val = hv_fetchs(options, "max_write_buffer_number", 0))
        opts->max_write_buffer_number = SvIV(*val);
    if (val = hv_fetchs(options, "min_write_buffer_number_to_merge", 0))
        opts->min_write_buffer_number_to_merge = SvIV(*val);
    if (val = hv_fetchs(options, "max_open_files", 0))
        opts->max_open_files = SvIV(*val);
    if (val = hv_fetchs(options, "max_total_wal_size", 0))
        opts->max_total_wal_size = SvIV(*val);
    if (val = hv_fetchs(options, "compression", 0))
        opts->compression = sv_to_compression_type(aTHX_ *val, "compression");
    if (val = hv_fetchs(options, "compression_per_level", 0)) {
        if (SvArrayRefOK(*val)) {
            AV* av = (AV*) SvRV(*val);
            std::vector<rocksdb::CompressionType> v;
            for (I32 i = 0; i <= av_len(av); i++) {
                SV *type = *av_fetch(av, i, 0);
                v.push_back(sv_to_compression_type(aTHX_ type, "compression_per_level"));
            }
            opts->compression_per_level = v;
        } else {
            croak("invalid value for compression_per_level");
        }
    }
    if (val = hv_fetchs(options, "prefix_extractor", 0)) {
        if (RocksDB::SliceTransform* transform =
                (RocksDB::SliceTransform*) FIND_MAGIC_OBJ(*val, "RocksDB::SliceTransform",
                        TYPE_ROCKSDB_SLICETRANSFORM)) {
            av_push(fields, SvREFCNT_inc_simple_NN(*val));
            opts->prefix_extractor = transform->ptr;
        } else {
            croak("prefix_extractor is not of type RocksDB::SliceTransform");
        }
    }
    if (val = hv_fetchs(options, "num_levels", 0))
        opts->num_levels = SvIV(*val);
    if (val = hv_fetchs(options, "level0_file_num_compaction_trigger", 0))
        opts->level0_file_num_compaction_trigger = SvIV(*val);
    if (val = hv_fetchs(options, "level0_slowdown_writes_trigger", 0))
        opts->level0_slowdown_writes_trigger = SvIV(*val);
    if (val = hv_fetchs(options, "level0_stop_writes_trigger", 0))
        opts->level0_stop_writes_trigger = SvIV(*val);
    if (val = hv_fetchs(options, "max_mem_compaction_level", 0))
        opts->max_mem_compaction_level = SvIV(*val);
    if (val = hv_fetchs(options, "target_file_size_base", 0))
        opts->target_file_size_base = SvIV(*val);
    if (val = hv_fetchs(options, "target_file_size_multiplier", 0))
        opts->target_file_size_multiplier = SvIV(*val);
    if (val = hv_fetchs(options, "max_bytes_for_level_base", 0))
        opts->max_bytes_for_level_base = SvIV(*val);
    if (val = hv_fetchs(options, "max_bytes_for_level_multiplier", 0))
        opts->max_bytes_for_level_multiplier = SvIV(*val);
    if (val = hv_fetchs(options, "max_bytes_for_level_multiplier_additional", 0)) {
        if (SvArrayRefOK(*val)) {
            AV* av = (AV*) SvRV(*val);
            std::vector<int> v;
            for (I32 i = 0; i <= av_len(av); i++) {
                v.push_back((int) SvIV(*av_fetch(av, i, 0)));
            }
            opts->max_bytes_for_level_multiplier_additional = v;
        } else {
            croak("invalid value for max_bytes_for_level_multiplier_additional");
        }
    }
    if (val = hv_fetchs(options, "max_compaction_bytes", 0))
        opts->max_compaction_bytes = SvIV(*val);
    if (val = hv_fetchs(options, "enable_statistics", 0))
        opts->statistics = rocksdb::CreateDBStatistics();
    if (val = hv_fetchs(options, "use_fsync", 0))
        opts->use_fsync = SvTRUE(*val);
    if (val = hv_fetchs(options, "db_log_dir", 0)) {
        STRLEN len;
        const char *str = SvPV(*val, len);
        opts->db_log_dir = std::string(str, len);
    }
    if (val = hv_fetchs(options, "wal_dir", 0)) {
        STRLEN len;
        const char *str = SvPV(*val, len);
        opts->wal_dir = std::string(str, len);
    }
    if (val = hv_fetchs(options, "delete_obsolete_files_period_micros", 0))
        opts->delete_obsolete_files_period_micros = SvIV(*val);
    if (val = hv_fetchs(options, "max_background_compactions", 0))
        opts->max_background_compactions = SvIV(*val);
    if (val = hv_fetchs(options, "max_background_flushes", 0))
        opts->max_background_flushes = SvIV(*val);
    if (val = hv_fetchs(options, "max_log_file_size", 0))
        opts->max_log_file_size = SvIV(*val);
    if (val = hv_fetchs(options, "log_file_time_to_roll", 0))
        opts->log_file_time_to_roll = SvIV(*val);
    if (val = hv_fetchs(options, "keep_log_file_num", 0))
        opts->keep_log_file_num = SvIV(*val);
    if (val = hv_fetchs(options, "soft_rate_limit", 0))
        opts->soft_rate_limit = SvNV(*val);
    if (val = hv_fetchs(options, "hard_rate_limit", 0))
        opts->hard_rate_limit = SvNV(*val);
    if (val = hv_fetchs(options, "rate_limit_delay_max_milliseconds", 0))
        opts->rate_limit_delay_max_milliseconds = SvIV(*val);
    if (val = hv_fetchs(options, "max_manifest_file_size", 0))
        opts->max_manifest_file_size = SvIV(*val);
    if (val = hv_fetchs(options, "table_cache_numshardbits", 0))
        opts->table_cache_numshardbits = SvIV(*val);
    if (val = hv_fetchs(options, "arena_block_size", 0))
        opts->arena_block_size = SvIV(*val);
    if (val = hv_fetchs(options, "disable_auto_compactions", 0))
        opts->disable_auto_compactions = SvTRUE(*val);
    if (val = hv_fetchs(options, "WAL_ttl_seconds", 0))
        opts->WAL_ttl_seconds = SvIV(*val);
    if (val = hv_fetchs(options, "WAL_size_limit_MB", 0))
        opts->WAL_size_limit_MB = SvIV(*val);
    if (val = hv_fetchs(options, "manifest_preallocation_size", 0))
        opts->manifest_preallocation_size = SvIV(*val);
    if (val = hv_fetchs(options, "purge_redundant_kvs_while_flush", 0))
        opts->purge_redundant_kvs_while_flush = SvTRUE(*val);
    if (val = hv_fetchs(options, "allow_mmap_reads", 0))
        opts->allow_mmap_reads = SvTRUE(*val);
    if (val = hv_fetchs(options, "allow_mmap_writes", 0))
        opts->allow_mmap_writes = SvTRUE(*val);
    if (val = hv_fetchs(options, "is_fd_close_on_exec", 0))
        opts->is_fd_close_on_exec = SvTRUE(*val);
    if (val = hv_fetchs(options, "skip_log_error_on_recovery", 0))
        opts->skip_log_error_on_recovery = SvTRUE(*val);
    if (val = hv_fetchs(options, "stats_dump_period_sec", 0))
        opts->stats_dump_period_sec = SvIV(*val);
    if (val = hv_fetchs(options, "advise_random_on_open", 0))
        opts->advise_random_on_open = SvTRUE(*val);
    if (val = hv_fetchs(options, "access_hint_on_compaction_start", 0)) {
        STRLEN len;
        char* str = SvPV(*val, len);
        if (strnEQ(str, "none", len)) {
            opts->access_hint_on_compaction_start = rocksdb::Options::NONE;
        } else if (strnEQ(str, "normal", len)) {
            /* Default */
        } else if (strnEQ(str, "sequential", len)) {
            opts->access_hint_on_compaction_start = rocksdb::Options::SEQUENTIAL;
        } else if (strnEQ(str, "willneed", len)) {
            opts->access_hint_on_compaction_start = rocksdb::Options::WILLNEED;
        } else {
            croak("invalid value '%s' for access_hint_on_compaction_start", str);
        }
    }
    if (val = hv_fetchs(options, "use_adaptive_mutex", 0))
        opts->use_adaptive_mutex = SvTRUE(*val);
    if (val = hv_fetchs(options, "bytes_per_sync", 0))
        opts->bytes_per_sync = SvIV(*val);
    if (val = hv_fetchs(options, "compaction_style", 0)) {
        STRLEN len;
        char* str = SvPV(*val, len);
        if (strnEQ(str, "level", len)) {
            opts->compaction_style = rocksdb::kCompactionStyleLevel;
        } else if (strnEQ(str, "universal", len)) {
            opts->compaction_style = rocksdb::kCompactionStyleUniversal;
        } else if (strnEQ(str, "fifo", len)) {
            opts->compaction_style = rocksdb::kCompactionStyleFIFO;
        } else {
            croak("invalid value '%s' for compaction_style", str);
        }
    }
    if (val = hv_fetchs(options, "compaction_options_universal", 0)) {
        if (!SvHashRefOK(*val)) {
            croak("invalid value for compaction_options_universal");
        }
        HV* hv = (HV*) SvRV(*val);
        rocksdb::CompactionOptionsUniversal copts_univ;
        if (val = hv_fetchs(hv, "size_ratio", 0))
            copts_univ.size_ratio = SvIV(*val);
        if (val = hv_fetchs(hv, "min_merge_width", 0))
            copts_univ.min_merge_width = SvIV(*val);
        if (val = hv_fetchs(hv, "max_merge_width", 0))
            copts_univ.max_merge_width = SvIV(*val);
        if (val = hv_fetchs(hv, "max_size_amplification_percent", 0))
            copts_univ.max_size_amplification_percent = SvIV(*val);
        if (val = hv_fetchs(hv, "compression_size_percent", 0))
            copts_univ.compression_size_percent = SvIV(*val);
        if (val = hv_fetchs(hv, "stop_style", 0)) {
            STRLEN len;
            char* str = SvPV(*val, len);
            if (strnEQ(str, "similar_size", len)) {
                copts_univ.stop_style = rocksdb::CompactionStopStyle::kCompactionStopStyleSimilarSize;
            } else if (strnEQ(str, "total_size", len)) {
                copts_univ.stop_style = rocksdb::CompactionStopStyle::kCompactionStopStyleTotalSize;
            } else {
                croak("invalid value '%s' for stop_style", str);
            }
        }
        opts->compaction_options_universal = copts_univ;
    }
    if (val = hv_fetchs(options, "compaction_options_fifo", 0)) {
        if (!SvHashRefOK(*val)) {
            croak("invalid value for compaction_options_fifo");
        }
        HV* hv = (HV*) SvRV(*val);
        rocksdb::CompactionOptionsFIFO copts_fifo;
        if (val = hv_fetchs(hv, "max_table_files_size", 0))
            copts_fifo.max_table_files_size = SvIV(*val);
        opts->compaction_options_fifo = copts_fifo;
    }
    if (val = hv_fetchs(options, "max_sequential_skip_in_iterations", 0))
        opts->max_sequential_skip_in_iterations = SvIV(*val);
    if (val = hv_fetchs(options, "inplace_update_support", 0))
        opts->inplace_update_support = SvTRUE(*val);
    if (val = hv_fetchs(options, "inplace_update_num_locks", 0))
        opts->inplace_update_num_locks = SvIV(*val);
    if (val = hv_fetchs(options, "memtable_prefix_bloom_size_ratio", 0))
        opts->memtable_prefix_bloom_size_ratio = SvNV(*val);
    if (val = hv_fetchs(options, "memtable_huge_page_size", 0))
        opts->memtable_huge_page_size = SvIV(*val);
    if (val = hv_fetchs(options, "bloom_locality", 0))
        opts->bloom_locality = SvIV(*val);
    if (val = hv_fetchs(options, "max_successive_merges", 0))
        opts->max_successive_merges = SvIV(*val);

    if (val = hv_fetchs(options, "block_based_table_options", 0)) {
        if (!SvHashRefOK(*val)) {
            croak("invalid value for block_based_table_options");
        }
        HV* hv = (HV*) SvRV(*val);
        rocksdb::BlockBasedTableOptions table_options;
        apply_block_based_table_options(aTHX_ &table_options, hv, fields);
        opts->table_factory = std::shared_ptr<rocksdb::TableFactory>(
                rocksdb::NewBlockBasedTableFactory(table_options));
    } else if (val = hv_fetchs(options, "plain_table_options", 0)) {
        if (!SvHashRefOK(*val)) {
            croak("invalid value for plain_table_options");
        }
        HV* hv = (HV*) SvRV(*val);
        rocksdb::PlainTableOptions table_options;
        apply_plain_table_options(aTHX_ &table_options, hv, fields);
        opts->table_factory = std::shared_ptr<rocksdb::TableFactory>(
                rocksdb::NewPlainTableFactory(table_options));
    } else if (val = hv_fetchs(options, "cuckoo_table_options", 0)) {
        if (!SvHashRefOK(*val)) {
            croak("invalid value for cuckoo_table_options");
        }
        HV* hv = (HV*) SvRV(*val);
        rocksdb::CuckooTableOptions table_options;
        apply_cuckoo_table_options(aTHX_ &table_options, hv, fields);
        opts->table_factory = std::shared_ptr<rocksdb::TableFactory>(
                rocksdb::NewCuckooTableFactory(table_options));
    }
}

static void
apply_read_options(pTHX_ rocksdb::ReadOptions* opts, HV* options) {
    SV** val;
    if (val = hv_fetchs(options, "verify_checksums", 0))
        opts->verify_checksums = SvTRUE(*val);
    if (val = hv_fetchs(options, "fill_cache", 0))
        opts->fill_cache = SvTRUE(*val);
    if (val = hv_fetchs(options, "tailing", 0))
        opts->tailing = SvTRUE(*val);
    if (val = hv_fetchs(options, "read_tier", 0)) {
        STRLEN len;
        char* str = SvPV(*val, len);
        if (strnEQ(str, "read_all", len)) {
            opts->read_tier = rocksdb::kReadAllTier;
        } else if (strnEQ(str, "block_cache", len)) {
            opts->read_tier = rocksdb::kBlockCacheTier;
        } else {
            croak("invalid value '%s' for read_tier", str);
        }
    }
    if (val = hv_fetchs(options, "snapshot", 0)) {
        if (rocksdb::Snapshot* snapshot =
                (rocksdb::Snapshot*) FIND_MAGIC_OBJ(*val, "RocksDB::Snapshot",
                        TYPE_ROCKSDB_SNAPSHOT)) {
            opts->snapshot = snapshot;
        } else {
            croak("snapshot is not of type RocksDB::Snapshot");
        }
    }
    if (val = hv_fetchs(options, "total_order_seek", 0))
        opts->total_order_seek = SvTRUE(*val);
}

static void
apply_write_options(pTHX_ rocksdb::WriteOptions* opts, HV* options) {
    SV** val;
    if (val = hv_fetchs(options, "sync", 0))
        opts->sync = SvTRUE(*val);
    if (val = hv_fetchs(options, "disableWAL", 0))
        opts->disableWAL = SvTRUE(*val);
}

static void
apply_flush_options(pTHX_ rocksdb::FlushOptions* opts, HV* options) {
    SV** val;
    if (val = hv_fetchs(options, "wait", 0))
        opts->wait = SvTRUE(*val);
}

MODULE = RocksDB        PACKAGE = RocksDB

PROTOTYPES: DISABLE

static int
RocksDB::major_version()
CODE:
    RETVAL = rocksdb::kMajorVersion;
OUTPUT:
    RETVAL

static int
RocksDB::minor_version()
CODE:
    RETVAL = rocksdb::kMinorVersion;
OUTPUT:
    RETVAL

static void
RocksDB::repair_db(const char* name, HV* options = NULL)
CODE:
    AV* fields = (AV*) sv_2mortal((SV*) newAV());
    rocksdb::Options opts = rocksdb::Options();
    if (options)
        apply_options(aTHX_ &opts, options, fields);
    CROAK_ON_ERROR(rocksdb::RepairDB(name, opts));

static void
RocksDB::destroy_db(const char* name, HV* options = NULL)
CODE:
    AV* fields = (AV*) sv_2mortal((SV*) newAV());
    rocksdb::Options opts = rocksdb::Options();
    if (options)
        apply_options(aTHX_ &opts, options, fields);
    CROAK_ON_ERROR(rocksdb::DestroyDB(name, opts));

RocksDB::DB*
RocksDB::new(const char* name, HV* options = NULL)
ALIAS:
    RocksDB::open    = 1
    RocksDB::TIEHASH = 2
CODE:
    rocksdb::Options opts = rocksdb::Options();
    AV* fields = newAV();
    bool read_only = false;
    if (options) {
        apply_options(aTHX_ &opts, options, fields);
        if (SV** val = hv_fetchs(options, "read_only", 0)) {
            read_only = SvTRUE(*val);
        }
    }
    rocksdb::DB* db;
    if (read_only) {
        CROAK_ON_ERROR(rocksdb::DB::OpenForReadOnly(opts, name, &db));
    } else {
        CROAK_ON_ERROR(rocksdb::DB::Open(opts, name, &db));
    }
    RETVAL = new RocksDB::DB(db, newRV_noinc((SV*) fields));
OUTPUT:
    RETVAL

std::string
RocksDB::DB::get(rocksdb::Slice key, HV* options = NULL)
ALIAS:
    RocksDB::FETCH = 1
CODE:
    rocksdb::ReadOptions opts = rocksdb::ReadOptions();
    if (options)
        apply_read_options(aTHX_ &opts, options);
    std::string value;
    rocksdb::Status status = THIS->db->Get(opts, key, &value);
    if (status.IsNotFound())
        XSRETURN_EMPTY;
    CROAK_ON_ERROR(status);
    RETVAL = value;
OUTPUT:
    RETVAL

SV*
RocksDB::DB::get_multi(...)
CODE:
    if (items < 2) {
        croak_xs_usage(cv,  "THIS, keys..., options= NULL");
    }
    I32 num_keys = items - 1;
    HV* options = NULL;
    if (SvHashRefOK(ST(items - 1))) {
        options = (HV*) SvRV(ST(items - 1));
        num_keys--;
    }
    rocksdb::ReadOptions opts = rocksdb::ReadOptions();
    if (options)
        apply_read_options(aTHX_ &opts, options);
    std::vector<rocksdb::Slice> vkeys;
    for (I32 i = 1; i <= num_keys; i++) {
        STRLEN len;
        const char* str = SvPVbyte(ST(i), len);
        vkeys.push_back(rocksdb::Slice(str, len));
    }
    std::vector<std::string> values;
    std::vector<rocksdb::Status> statuses = THIS->db->MultiGet(opts, vkeys, &values);
    HV* result = newHV();
    for (std::vector<std::string>::size_type i = 0; i < values.size(); i++) {
        if (statuses[i].IsNotFound()) {
            hv_store_ent(result, ST(i + 1), newSV(0), 0);
        } else {
            CROAK_ON_ERROR(statuses[i]);
            std::string value = values.at(i);
            SV* sv = newSVpvn(value.c_str(), value.size());
            hv_store_ent(result, ST(i + 1), sv, 0);
        }
    }
    RETVAL = newRV_noinc((SV*) result);
OUTPUT:
    RETVAL

void
RocksDB::DB::put(rocksdb::Slice key, rocksdb::Slice value, HV* options = NULL)
ALIAS:
    RocksDB::STORE = 1
CODE:
    rocksdb::WriteOptions opts = rocksdb::WriteOptions();
    if (options)
        apply_write_options(aTHX_ &opts, options);
    CROAK_ON_ERROR(THIS->db->Put(opts, key, value));

void
RocksDB::DB::put_multi(HV* hash, HV* options = NULL)
CODE:
    rocksdb::WriteOptions opts = rocksdb::WriteOptions();
    if (options)
        apply_write_options(aTHX_ &opts, options);
    rocksdb::WriteBatch batch;
    hv_iterinit(hash);
    SV* value;
    char *key;
    I32 klen;
    STRLEN vlen;
    while ((value = hv_iternextsv(hash, &key, &klen)) != NULL) {
        const char* val = SvPV(value, vlen);
        batch.Put(rocksdb::Slice(key, klen), rocksdb::Slice(val, vlen));
    }
    CROAK_ON_ERROR(THIS->db->Write(opts, &batch));

void
RocksDB::DB::merge(rocksdb::Slice key, rocksdb::Slice value, HV* options = NULL)
CODE:
    rocksdb::WriteOptions opts = rocksdb::WriteOptions();
    if (options)
        apply_write_options(aTHX_ &opts, options);
    CROAK_ON_ERROR(THIS->db->Merge(opts, key, value));

void
RocksDB::DB::remove(rocksdb::Slice key, HV* options = NULL)
ALIAS:
    RocksDB::delete = 1
    RocksDB::DELETE = 2
CODE:
    rocksdb::WriteOptions opts = rocksdb::WriteOptions();
    if (options)
        apply_write_options(aTHX_ &opts, options);
    CROAK_ON_ERROR(THIS->db->Delete(opts, key));

bool
RocksDB::DB::exists(rocksdb::Slice key, HV* options = NULL)
ALIAS:
    RocksDB::EXISTS = 1
CODE:
    rocksdb::ReadOptions opts = rocksdb::ReadOptions();
    if (options)
        apply_read_options(aTHX_ &opts, options);
    std::string value;
    rocksdb::Status status = THIS->db->Get(opts, key, &value);
    if (status.IsNotFound()) {
        RETVAL = false;
    } else {
        CROAK_ON_ERROR(status);
        RETVAL = true;
    }
OUTPUT:
    RETVAL

bool
RocksDB::DB::key_may_exist(rocksdb::Slice key, SV* value_ref = NULL, HV* options = NULL)
CODE:
    rocksdb::ReadOptions opts = rocksdb::ReadOptions();
    if (options)
        apply_read_options(aTHX_ &opts, options);
    std::string value;
    if (value_ref != NULL && SvROK(value_ref)) {
        bool value_found = false;
        RETVAL = THIS->db->KeyMayExist(opts, key, &value, &value_found);
        if (value_found) {
            sv_setpvn(SvRV(value_ref), value.c_str(), value.size());
        }
    } else {
        RETVAL = THIS->db->KeyMayExist(opts, key, &value);
    }
OUTPUT:
    RETVAL

rocksdb::Iterator *
RocksDB::DB::new_iterator(HV* options = NULL)
PREINIT:
    const char* CLASS = "RocksDB::Iterator";
CODE:
    rocksdb::ReadOptions opts = rocksdb::ReadOptions();
    if (options) {
        apply_read_options(aTHX_ &opts, options);
    }
    RETVAL = THIS->db->NewIterator(opts);
OUTPUT:
    RETVAL

const rocksdb::Snapshot *
RocksDB::DB::get_snapshot()
PREINIT:
    const char* CLASS = "RocksDB::Snapshot";
CODE:
    RETVAL = THIS->db->GetSnapshot();
OUTPUT:
    RETVAL

void
RocksDB::DB::update(SV* cb, HV* options = NULL)
CODE:
    SV* batch = NULL;
    PUSHMARK(SP);
    mXPUSHs(newSVpvs("RocksDB::WriteBatch"));
    PUTBACK;
    int count = call_method("new", G_SCALAR);
    SPAGAIN;
    if (count == 1) {
        SV* res = POPs;
        batch = sv_2mortal(SvREFCNT_inc_simple_NN(res));
    } else {
        croak("RocksDB::WriteBatch::new: wanted 1 value, got %d", count);
    }
    PUTBACK;

    rocksdb::WriteOptions opts = rocksdb::WriteOptions();
    if (options) {
        apply_write_options(aTHX_ &opts, options);
    }

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    mXPUSHs(SvREFCNT_inc_simple_NN(batch));
    PUTBACK;
    (void) call_sv(cb, G_DISCARD);
    SPAGAIN;
    PUTBACK;
    FREETMPS;
    LEAVE;

    if (rocksdb::WriteBatch* write_batch =
            (rocksdb::WriteBatch*) FIND_MAGIC_OBJ(batch, "RocksDB::WriteBatch",
                    TYPE_ROCKSDB_WRITEBATCH)) {
        CROAK_ON_ERROR(THIS->db->Write(opts, write_batch));
    } else {
        croak("write_batch is not of type RocksDB::WriteBatch");
    }

void
RocksDB::DB::write(rocksdb::WriteBatch* batch, HV* options = NULL)
CODE:
    rocksdb::WriteOptions opts = rocksdb::WriteOptions();
    if (options)
        apply_write_options(aTHX_ &opts, options);
    CROAK_ON_ERROR(THIS->db->Write(opts, batch));

SV*
RocksDB::DB::get_name()
CODE:
    const std::string name = THIS->db->GetName();
    RETVAL = newSVpvn(name.c_str(), name.size());
OUTPUT:
    RETVAL

std::string
RocksDB::DB::get_property(rocksdb::Slice property)
CODE:
    std::string value;
    if (!THIS->db->GetProperty(property, &value))
        XSRETURN_EMPTY;
    RETVAL = value;
OUTPUT:
    RETVAL

uint64_t
RocksDB::DB::get_approximate_size(rocksdb::Slice start, rocksdb::Slice limit)
CODE:
    rocksdb::Range ranges[1];
    ranges[0] = rocksdb::Range(start, limit);
    uint64_t sizes[1];
    THIS->db->GetApproximateSizes(ranges, 1, sizes);
    RETVAL = sizes[0];
OUTPUT:
    RETVAL

void
RocksDB::DB::compact_range(SV* begin = NULL, SV* end = NULL, HV* options = NULL)
PREINIT:
    bool b, e;
    rocksdb::Slice sbegin, send;
    bool reduce_level = false;
    int target_level = -1;
CODE:
    if (b = (begin != NULL && SvOK(begin)))
        SV2SLICE(begin, sbegin);
    if (e = (end != NULL && SvOK(end)))
        SV2SLICE(end, send);
    if (options != NULL) {
        SV** val;
        if (val = hv_fetchs(options, "reduce_level", 0))
            reduce_level = SvTRUE(*val);
        if (val = hv_fetchs(options, "target_level", 0))
            target_level = SvIV(*val);
    }
    THIS->db->CompactRange(b ? &sbegin : NULL, e ? &send : NULL, reduce_level, target_level);

int
RocksDB::DB::number_levels()
CODE:
    RETVAL = THIS->db->NumberLevels();
OUTPUT:
    RETVAL

int
RocksDB::DB::max_mem_compaction_level()
CODE:
    RETVAL = THIS->db->MaxMemCompactionLevel();
OUTPUT:
    RETVAL

int
RocksDB::DB::level0_stop_write_trigger()
CODE:
    RETVAL = THIS->db->Level0StopWriteTrigger();
OUTPUT:
    RETVAL

void
RocksDB::DB::flush(HV *options = NULL)
CODE:
    rocksdb::FlushOptions opts = rocksdb::FlushOptions();
    if (options)
        apply_flush_options(aTHX_ &opts, options);
    CROAK_ON_ERROR(THIS->db->Flush(opts));

void
RocksDB::DB::disable_file_deletions()
CODE:
    THIS->db->DisableFileDeletions();

void
RocksDB::DB::enable_file_deletions()
CODE:
    THIS->db->EnableFileDeletions();

void
RocksDB::DB::delete_file(const char* name)
CODE:
    THIS->db->DeleteFile(name);

rocksdb::SequenceNumber
RocksDB::DB::get_latest_sequence_number()
CODE:
    RETVAL = THIS->db->GetLatestSequenceNumber();
OUTPUT:
    RETVAL

void
RocksDB::DB::get_live_files_meta_data()
PPCODE:
    std::vector<rocksdb::LiveFileMetaData> metadata;
    THIS->db->GetLiveFilesMetaData(&metadata);
    for (std::vector<rocksdb::LiveFileMetaData>::size_type i = 0; i < metadata.size(); i++) {
        rocksdb::LiveFileMetaData data = metadata[i];
        HV *hv = newHV();
        hv_stores(hv, "name", newSVpvn(data.name.c_str(), data.name.size()));
        hv_stores(hv, "level", newSViv(data.level));
        hv_stores(hv, "size", newSViv(data.size));
        hv_stores(hv, "smallestkey", newSVpvn(data.smallestkey.c_str(), data.smallestkey.size()));
        hv_stores(hv, "largestkey", newSVpvn(data.largestkey.c_str(), data.largestkey.size()));
        hv_stores(hv, "smallest_seqno", newSVnv(data.smallest_seqno));
        hv_stores(hv, "largest_seqno", newSVnv(data.largest_seqno));
        mXPUSHs(newRV_noinc((SV*) hv));
    }

void
RocksDB::DB::get_sorted_wal_files()
PPCODE:
    rocksdb::VectorLogPtr files;
    CROAK_ON_ERROR(THIS->db->GetSortedWalFiles(files));
    for (std::vector<std::unique_ptr<rocksdb::LogFile>>::size_type i = 0; i < files.size(); i++) {
        HV* hv = newHV();
        std::string path_name = files[i]->PathName();
        hv_stores(hv, "path_name", newSVpvn(path_name.c_str(), path_name.size()));
        hv_stores(hv, "log_number", newSViv(files[i]->LogNumber()));
        SV* type;
        if (files[i]->Type() == rocksdb::WalFileType::kArchivedLogFile) {
            type = newSVpvs("archived");
        } else { /* kAliveLogFile */
            type = newSVpvs("alive");
        }
        hv_stores(hv, "type", type);
        hv_stores(hv, "start_sequence", newSViv(files[i]->StartSequence()));
        hv_stores(hv, "size_file_bytes", newSViv(files[i]->SizeFileBytes()));
        mXPUSHs(newRV_noinc((SV*) hv));
    }

RocksDB::TransactionLogIterator*
RocksDB::DB::get_updates_since(rocksdb::SequenceNumber seq_number)
PREINIT:
    const char* CLASS = "RocksDB::TransactionLogIterator";
CODE:
    auto iter = new RocksDB::TransactionLogIterator();
    rocksdb::Status status = THIS->db->GetUpdatesSince(seq_number, &iter->ptr);
    if (!status.ok()) {
        delete iter;
        CROAK_ON_ERROR(status);
    }
    RETVAL = iter;
OUTPUT:
    RETVAL

std::string
RocksDB::DB::get_db_identity()
CODE:
    std::string identity;
    CROAK_ON_ERROR(THIS->db->GetDbIdentity(identity));
    RETVAL = identity;
OUTPUT:
    RETVAL

RocksDB::Statistics*
RocksDB::DB::get_statistics()
PREINIT:
    const char* CLASS = "RocksDB::Statistics";
CODE:
    if (THIS->db->GetOptions().statistics != NULL) {
        RETVAL = new RocksDB::Statistics(THIS->db->GetOptions().statistics);
    } else {
        RETVAL = NULL;
    }
OUTPUT:
    RETVAL

void
RocksDB::DB::CLEAR()
CODE:
    rocksdb::Iterator* it = THIS->db->NewIterator(rocksdb::ReadOptions());
    rocksdb::WriteBatch batch;
    for (it->SeekToFirst(); it->Valid(); it->Next()) {
        rocksdb::Slice key = it->key();
        batch.Delete(key);
    }
    rocksdb::Status status = THIS->db->Write(rocksdb::WriteOptions(), &batch);
    delete it;
    CROAK_ON_ERROR(status);

uint64_t
RocksDB::DB::SCALAR()
CODE:
    uint64_t count = 0;
    rocksdb::Iterator* it = THIS->db->NewIterator(rocksdb::ReadOptions());
    for (it->SeekToFirst(); it->Valid(); it->Next()) {
        count++;
    }
    delete it;
    RETVAL = count;
OUTPUT:
    RETVAL

rocksdb::Slice
RocksDB::DB::FIRSTKEY()
CODE:
    if (THIS->it != NULL)
        delete THIS->it;
    THIS->it = THIS->db->NewIterator(rocksdb::ReadOptions());
    THIS->it->SeekToFirst();
    if (!THIS->it->Valid())
        XSRETURN_EMPTY;
    RETVAL = THIS->it->key();
OUTPUT:
    RETVAL

rocksdb::Slice
RocksDB::DB::NEXTKEY(SV* lastkey)
CODE:
    if (THIS->it == NULL)
        XSRETURN_EMPTY;
    THIS->it->Next();
    if (!THIS->it->Valid())
        XSRETURN_EMPTY;
    RETVAL = THIS->it->key();
OUTPUT:
    RETVAL

void
RocksDB::DB::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::Iterator

SV*
rocksdb::Iterator::seek_to_first()
CODE:
    THIS->SeekToFirst();
    RETVAL = SvREFCNT_inc_simple_NN(SELF);
OUTPUT:
    RETVAL

SV*
rocksdb::Iterator::seek_to_last()
CODE:
    THIS->SeekToLast();
    RETVAL = SvREFCNT_inc_simple_NN(SELF);
OUTPUT:
    RETVAL

SV*
rocksdb::Iterator::seek(rocksdb::Slice target)
CODE:
    THIS->Seek(target);
    RETVAL = SvREFCNT_inc_simple_NN(SELF);
OUTPUT:
    RETVAL

void
rocksdb::Iterator::next()
CODE:
    CHECK_ITER_VALID(THIS);
    THIS->Next();

void
rocksdb::Iterator::prev()
CODE:
    CHECK_ITER_VALID(THIS);
    THIS->Prev();

bool
rocksdb::Iterator::valid()
CODE:
    RETVAL = THIS->Valid();
OUTPUT:
    RETVAL

rocksdb::Slice
rocksdb::Iterator::key()
INIT:
    CHECK_ITER_VALID(THIS);

rocksdb::Slice
rocksdb::Iterator::value()
INIT:
    CHECK_ITER_VALID(THIS);

void
rocksdb::Iterator::each()
PPCODE:
    if (!THIS->Valid())
        XSRETURN_EMPTY;
    rocksdb::Slice key = THIS->key(), value = THIS->value();
    mXPUSHs(newSVpvn(key.data(), key.size()));
    mXPUSHs(newSVpvn(value.data(), value.size()));
    THIS->Next();

void
rocksdb::Iterator::reverse_each()
PPCODE:
    if (!THIS->Valid())
        XSRETURN_EMPTY;
    rocksdb::Slice key = THIS->key(), value = THIS->value();
    mXPUSHs(newSVpvn(key.data(), key.size()));
    mXPUSHs(newSVpvn(value.data(), value.size()));
    THIS->Prev();

void
rocksdb::Iterator::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::WriteBatch

rocksdb::WriteBatch *
rocksdb::WriteBatch::new()

void
rocksdb::WriteBatch::put(rocksdb::Slice key, rocksdb::Slice value)
CODE:
    THIS->Put(key, value);

void
rocksdb::WriteBatch::merge(rocksdb::Slice key, rocksdb::Slice value)
CODE:
    THIS->Merge(key, value);

void
rocksdb::WriteBatch::remove(rocksdb::Slice key)
ALIAS:
    RocksDB::WriteBatch::delete = 1
CODE:
    THIS->Delete(key);

void
rocksdb::WriteBatch::put_log_data(rocksdb::Slice blob)
CODE:
    THIS->PutLogData(blob);

int
rocksdb::WriteBatch::count()
CODE:
    RETVAL = THIS->Count();
OUTPUT:
    RETVAL

std::string
rocksdb::WriteBatch::data()
CODE:
    RETVAL = THIS->Data();
OUTPUT:
    RETVAL

void
rocksdb::WriteBatch::clear()
CODE:
    THIS->Clear();

void
rocksdb::WriteBatch::iterate(RocksDB::WriteBatchHandler* handler)
CODE:
    CROAK_ON_ERROR(THIS->Iterate(handler));

void
rocksdb::WriteBatch::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::WriteBatchHandler

RocksDB::WriteBatchHandler*
RocksDB::WriteBatchHandler::new(SV* handler)
INIT:
    if (!sv_isobject(handler))
        croak("The argument is not an object");

void
RocksDB::WriteBatchHandler::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::Cache

void
RocksDB::Cache::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::LRUCache

BOOT:
    av_push(get_av("RocksDB::LRUCache::ISA", TRUE), newSVpvs("RocksDB::Cache"));

RocksDB::Cache *
RocksDB::LRUCache::new(size_t capacity)
CODE:
    RETVAL = new RocksDB::Cache(rocksdb::NewLRUCache(capacity));
OUTPUT:
    RETVAL

MODULE = RocksDB        PACKAGE = RocksDB::FilterPolicy

void
RocksDB::FilterPolicy::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::BloomFilterPolicy

BOOT:
    av_push(get_av("RocksDB::BloomFilterPolicy::ISA", TRUE), newSVpvs("RocksDB::FilterPolicy"));

RocksDB::FilterPolicy *
RocksDB::BloomFilterPolicy::new(int bits_per_key)
CODE:
    RETVAL = new RocksDB::FilterPolicy(rocksdb::NewBloomFilterPolicy(bits_per_key));
OUTPUT:
    RETVAL

MODULE = RocksDB        PACKAGE = RocksDB::Snapshot

void
rocksdb::Snapshot::DESTROY()
CODE:
    if (RocksDB::DB* rocksdb = (RocksDB::DB*) GET_MAGIC_PTR_OBJ(SELF)) {
        rocksdb->db->ReleaseSnapshot(THIS);
    }
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::Comparator

RocksDB::Comparator*
RocksDB::Comparator::new(SV* handler)
INIT:
    if (!sv_isobject(handler))
        croak("The argument is not an object");

void
RocksDB::Comparator::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::SliceTransform

void
RocksDB::SliceTransform::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::FixedPrefixTransform

BOOT:
    av_push(get_av("RocksDB::FixedPrefixTransform::ISA", TRUE), newSVpvs("RocksDB::SliceTransform"));

RocksDB::SliceTransform*
RocksDB::FixedPrefixTransform::new(size_t prefix_len)
CODE:
    const rocksdb::SliceTransform* transform = rocksdb::NewFixedPrefixTransform(prefix_len);
    RETVAL = new RocksDB::SliceTransform(std::shared_ptr<const rocksdb::SliceTransform>(transform));
OUTPUT:
    RETVAL

MODULE = RocksDB        PACKAGE = RocksDB::CompactionFilter

RocksDB::CompactionFilter*
RocksDB::CompactionFilter::new(SV* handler)
INIT:
    if (!sv_isobject(handler))
        croak("The argument is not an object");

void
RocksDB::CompactionFilter::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::TransactionLogIterator

void
RocksDB::TransactionLogIterator::next()
CODE:
    CHECK_ITER_VALID(THIS->ptr);
    THIS->ptr->Next();

bool
RocksDB::TransactionLogIterator::valid()
CODE:
    RETVAL = THIS->ptr->Valid();
OUTPUT:
    RETVAL

RocksDB::BatchResult*
RocksDB::TransactionLogIterator::get_batch()
PREINIT:
    const char* CLASS = "RocksDB::BatchResult";
CODE:
    CHECK_ITER_VALID(THIS->ptr);
    RETVAL = new RocksDB::BatchResult(THIS->ptr->GetBatch());
OUTPUT:
    RETVAL

void
RocksDB::TransactionLogIterator::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::BatchResult

rocksdb::SequenceNumber
RocksDB::BatchResult::sequence()
CODE:
    RETVAL = THIS->sequence;
OUTPUT:
    RETVAL

rocksdb::WriteBatch*
RocksDB::BatchResult::write_batch()
PREINIT:
    const char* CLASS = "RocksDB::WriteBatch";
CODE:
    RETVAL = THIS->writeBatchPtr.get(); /* FIXME */
OUTPUT:
    RETVAL

MODULE = RocksDB        PACKAGE = RocksDB::MergeOperator

RocksDB::MergeOperator*
RocksDB::MergeOperator::new(SV* handler)
CODE:
    if (!sv_isobject(handler))
        croak("The argument is not an object");
    auto impl = new RocksDB::MergeOperatorImpl(handler);
    RETVAL = new RocksDB::MergeOperator(std::shared_ptr<rocksdb::MergeOperator>(impl));
OUTPUT:
    RETVAL

void
RocksDB::MergeOperator::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::AssociativeMergeOperator

BOOT:
    av_push(get_av("RocksDB::AssociativeMergeOperator::ISA", TRUE), newSVpvs("RocksDB::MergeOperator"));

RocksDB::MergeOperator*
RocksDB::AssociativeMergeOperator::new(SV* handler)
CODE:
    if (!sv_isobject(handler))
        croak("The argument is not an object");
    auto impl = new RocksDB::AssociativeMergeOperatorImpl(handler);
    RETVAL = new RocksDB::MergeOperator(std::shared_ptr<rocksdb::MergeOperator>(impl));
OUTPUT:
    RETVAL

void
RocksDB::MergeOperator::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::Statistics

BOOT:
    {
        HV* tickers = get_hv("RocksDB::Statistics::TICKERS", TRUE | GV_ADDMULTI);
        for (const auto &pair : rocksdb::TickersNameMap) {
            SV* name = newSVpvn(pair.second.c_str(), pair.second.size());
            hv_store_ent(tickers, name, newSViv(pair.first), 0);
        }

        HV* histograms = get_hv("RocksDB::Statistics::HISTOGRAMS", TRUE | GV_ADDMULTI);
        for (const auto &pair : rocksdb::HistogramsNameMap) {
            SV* name = newSVpvn(pair.second.c_str(), pair.second.size());
            hv_store_ent(histograms, name, newSViv(pair.first), 0);
        }
    }

SV*
RocksDB::Statistics::get_ticker_count(SV* name)
CODE:
    STRLEN namelen;
    char* nameptr = SvPV(name, namelen);
    HV* tickers = get_hv("RocksDB::Statistics::TICKERS", FALSE);
    if (tickers == NULL)
        XSRETURN_UNDEF;
    SV** ticker = hv_fetch(tickers, nameptr, namelen, 0);
    if (ticker != NULL) {
        rocksdb::Tickers t = (rocksdb::Tickers) SvIV(*ticker);
        RETVAL = newSViv(THIS->ptr->getTickerCount(t));
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
RocksDB::Statistics::histogram_data(SV* name)
CODE:
    STRLEN namelen;
    char* nameptr = SvPV(name, namelen);
    HV* histograms = get_hv("RocksDB::Statistics::HISTOGRAMS", FALSE);
    if (histograms == NULL)
        XSRETURN_UNDEF;
    SV** histogram = hv_fetch(histograms, nameptr, namelen, 0);
    if (histogram != NULL) {
        rocksdb::Histograms h = (rocksdb::Histograms) SvIV(*histogram);
        rocksdb::HistogramData data;
        THIS->ptr->histogramData(h, &data);
        RETVAL = RocksDB::Statistics::HistogramDataToHashRef(aTHX_ &data);
    } else {
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

SV*
RocksDB::Statistics::to_hashref()
CODE:
    HV* hash = newHV();
    for (const auto &pair : rocksdb::TickersNameMap) {
        SV* name = newSVpvn(pair.second.c_str(), pair.second.size());
        hv_store_ent(hash, name, newSViv(THIS->ptr->getTickerCount(pair.first)), 0);
    }
    for (const auto &pair : rocksdb::HistogramsNameMap) {
        SV* name = newSVpvn(pair.second.c_str(), pair.second.size());
        rocksdb::HistogramData data;
        THIS->ptr->histogramData(pair.first, &data);
        SV* hashref = RocksDB::Statistics::HistogramDataToHashRef(aTHX_ &data);
        hv_store_ent(hash, name, hashref, 0);
    }
    RETVAL = newRV_noinc((SV*) hash);
OUTPUT:
    RETVAL

std::string
RocksDB::Statistics::to_string()
CODE:
    RETVAL = THIS->ptr->ToString();
OUTPUT:
    RETVAL

void
RocksDB::Statistics::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

MODULE = RocksDB        PACKAGE = RocksDB::LDBTool

rocksdb::LDBTool*
rocksdb::LDBTool::new()

void
rocksdb::LDBTool::run()
PREINIT:
    int i;
    char** argv;
CODE:
    AV* argv_av = get_av("ARGV", 0);
    int argc = av_len(argv_av) + 2;
    Newx(argv, argc + 1, char*);
    argv[0] = SvPV_nolen(get_sv("0", 0));
    for (i = 1; i < argc; i++) {
        argv[i] = SvPV_nolen(*av_fetch(argv_av, i - 1, 0));
    }
    argv[i] = NULL;
    THIS->Run(argc, argv);

void
rocksdb::LDBTool::DESTROY()
CLEANUP:
    DESTROY_ROCKSDB_OBJ(SELF);

