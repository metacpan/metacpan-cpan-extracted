#include "arrow_bridge.h"

#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include <arrow/api.h>
#include <arrow/io/api.h>
#include <arrow/ipc/api.h>
#include <parquet/arrow/reader.h>
#include <parquet/arrow/writer.h>

static char* dup_str(const std::string& s) {
    char* out = static_cast<char*>(std::malloc(s.size() + 1));
    if (out) {
        std::memcpy(out, s.data(), s.size());
        out[s.size()] = '\0';
    }
    return out;
}

void pdl_arrow_table_free(PdlArrowTable* table) {
    if (!table) return;
    for (size_t i = 0; i < table->num_columns; ++i) {
        std::free(table->columns[i].name);
        std::free(table->columns[i].type_name);
        std::free(table->columns[i].data);
    }
    std::free(table->columns);
    std::free(table->error);
    std::free(table);
}

static bool extract_numeric_column(const std::shared_ptr<arrow::ChunkedArray>& col,
                                   const std::string& name,
                                   PdlArrowColumn* out,
                                   std::string* err) {
    auto type_id = col->type()->id();
    const char* pdl_type = nullptr;
    size_t elem_size = 0;

    if (type_id == arrow::Type::FIXED_SIZE_LIST) {
        auto fsl_type = std::static_pointer_cast<arrow::FixedSizeListType>(col->type());
        auto val_id   = fsl_type->value_type()->id();
        if (fsl_type->list_size() == 2 && (val_id == arrow::Type::FLOAT || val_id == arrow::Type::DOUBLE)) {
            pdl_type  = (val_id == arrow::Type::FLOAT) ? "cfloat" : "cdouble";
            elem_size = (val_id == arrow::Type::FLOAT) ? 8 : 16;
            int64_t total_len   = col->length();
            size_t  total_bytes = static_cast<size_t>(total_len) * elem_size;
            uint8_t* buf = static_cast<uint8_t*>(std::malloc(total_bytes > 0 ? total_bytes : 1));
            if (!buf) {
                *err = "Out of memory allocating complex buffer for column '" + name + "'";
                return false;
            }
            size_t offset_bytes = 0;
            for (int c = 0; c < col->num_chunks(); ++c) {
                auto fsl_arr = std::static_pointer_cast<arrow::FixedSizeListArray>(col->chunk(c));
                int64_t n = fsl_arr->length();
                if (n == 0) continue;
                auto values = fsl_arr->values();
                const auto& vdata = values->data();
                size_t child_elem = elem_size / 2;
                const uint8_t* raw = vdata->buffers[1]->data() + ((vdata->offset + fsl_arr->offset() * 2) * child_elem);
                size_t nbytes = static_cast<size_t>(n) * elem_size;
                std::memcpy(buf + offset_bytes, raw, nbytes);
                offset_bytes += nbytes;
            }
            out->name         = dup_str(name);
            out->type_name    = dup_str(pdl_type);
            out->data         = buf;
            out->data_len     = total_bytes;
            out->num_elements = total_len;
            return true;
        }
    }

    if (type_id == arrow::Type::LIST) {
        auto list_type = std::static_pointer_cast<arrow::ListType>(col->type());
        auto val_id    = list_type->value_type()->id();
        if (val_id == arrow::Type::FLOAT || val_id == arrow::Type::DOUBLE) {
            pdl_type  = (val_id == arrow::Type::FLOAT) ? "cfloat" : "cdouble";
            elem_size = (val_id == arrow::Type::FLOAT) ? 8 : 16;
            int64_t total_len   = col->length();
            size_t  total_bytes = static_cast<size_t>(total_len) * elem_size;
            uint8_t* buf = static_cast<uint8_t*>(std::malloc(total_bytes > 0 ? total_bytes : 1));
            if (!buf) {
                *err = "Out of memory allocating complex list buffer for column '" + name + "'";
                return false;
            }
            size_t offset_bytes = 0;
            for (int c = 0; c < col->num_chunks(); ++c) {
                auto list_arr = std::static_pointer_cast<arrow::ListArray>(col->chunk(c));
                int64_t n = list_arr->length();
                if (n == 0) continue;
                auto values = list_arr->values();
                const auto& vdata = values->data();
                size_t child_elem = elem_size / 2;
                int32_t start_off = list_arr->value_offset(0);
                const uint8_t* raw = vdata->buffers[1]->data() + ((vdata->offset + start_off) * child_elem);
                size_t nbytes = static_cast<size_t>(n) * elem_size;
                std::memcpy(buf + offset_bytes, raw, nbytes);
                offset_bytes += nbytes;
            }
            out->name         = dup_str(name);
            out->type_name    = dup_str(pdl_type);
            out->data         = buf;
            out->data_len     = total_bytes;
            out->num_elements = total_len;
            return true;
        }
    }

    switch (type_id) {
        case arrow::Type::DOUBLE: pdl_type = "double";    elem_size = 8; break;
        case arrow::Type::FLOAT:  pdl_type = "float";     elem_size = 4; break;
        case arrow::Type::INT8:   pdl_type = "sbyte";     elem_size = 1; break;
        case arrow::Type::UINT8:  pdl_type = "byte";      elem_size = 1; break;
        case arrow::Type::INT16:  pdl_type = "short";     elem_size = 2; break;
        case arrow::Type::UINT16: pdl_type = "ushort";    elem_size = 2; break;
        case arrow::Type::INT32:  pdl_type = "long";      elem_size = 4; break;
        case arrow::Type::UINT32: pdl_type = "ulong";     elem_size = 4; break;
        case arrow::Type::INT64:  pdl_type = "longlong";  elem_size = 8; break;
        case arrow::Type::UINT64: pdl_type = "ulonglong"; elem_size = 8; break;
        default:
            *err = "Unsupported Arrow column type for '" + name + "': " + col->type()->ToString();
            return false;
    }

    int64_t total_len = col->length();
    size_t total_bytes = static_cast<size_t>(total_len) * elem_size;
    uint8_t* buf = static_cast<uint8_t*>(std::malloc(total_bytes > 0 ? total_bytes : 1));
    if (!buf) {
        *err = "Out of memory allocating buffer for column '" + name + "'";
        return false;
    }

    size_t offset_bytes = 0;
    for (int c = 0; c < col->num_chunks(); ++c) {
        auto chunk = col->chunk(c);
        int64_t n = chunk->length();
        if (n == 0) continue;
        const auto& data = chunk->data();
        const uint8_t* raw = data->buffers[1]->data() + (data->offset * elem_size);
        size_t nbytes = static_cast<size_t>(n) * elem_size;
        std::memcpy(buf + offset_bytes, raw, nbytes);
        offset_bytes += nbytes;
    }

    out->name         = dup_str(name);
    out->type_name    = dup_str(pdl_type);
    out->data         = buf;
    out->data_len     = total_bytes;
    out->num_elements = total_len;
    return true;
}

PdlArrowTable* pdl_arrow_read_file(const char* path, int format) {
    PdlArrowTable* res = static_cast<PdlArrowTable*>(std::calloc(1, sizeof(PdlArrowTable)));
    if (!res) return nullptr;

    auto infile_res = arrow::io::ReadableFile::Open(path);
    if (!infile_res.ok()) {
        res->error = dup_str("Failed to open file: " + infile_res.status().ToString());
        return res;
    }
    auto infile = *infile_res;

    std::shared_ptr<arrow::Table> table;
    if (format == 0) {
        auto reader_res = arrow::ipc::RecordBatchFileReader::Open(infile);
        if (!reader_res.ok()) {
            res->error = dup_str("Arrow IPC open failed: " + reader_res.status().ToString());
            return res;
        }
        auto reader = *reader_res;
        std::vector<std::shared_ptr<arrow::RecordBatch>> batches;
        for (int i = 0; i < reader->num_record_batches(); ++i) {
            auto batch_res = reader->ReadRecordBatch(i);
            if (!batch_res.ok()) {
                res->error = dup_str("Arrow IPC read batch failed: " + batch_res.status().ToString());
                return res;
            }
            batches.push_back(*batch_res);
        }
        auto tbl_res = arrow::Table::FromRecordBatches(reader->schema(), batches);
        if (!tbl_res.ok()) {
            res->error = dup_str("Arrow Table::FromRecordBatches failed: " + tbl_res.status().ToString());
            return res;
        }
        table = *tbl_res;
    } else if (format == 1) {
        auto reader_res = parquet::arrow::OpenFile(infile, arrow::default_memory_pool());
        if (!reader_res.ok()) {
            res->error = dup_str("Parquet open failed: " + reader_res.status().ToString());
            return res;
        }
        auto status = (*reader_res)->ReadTable(&table);
        if (!status.ok()) {
            res->error = dup_str("Parquet ReadTable failed: " + status.ToString());
            return res;
        }
    } else {
        res->error = dup_str("Unsupported format code");
        return res;
    }

    int ncols = table->num_columns();
    res->columns = static_cast<PdlArrowColumn*>(std::calloc(ncols > 0 ? ncols : 1, sizeof(PdlArrowColumn)));
    res->num_columns = 0;

    for (int i = 0; i < ncols; ++i) {
        std::string err;
        if (!extract_numeric_column(table->column(i), table->schema()->field(i)->name(),
                                    &res->columns[res->num_columns], &err)) {
            res->error = dup_str(err);
            return res;
        }
        res->num_columns++;
    }
    return res;
}

template <typename ArrowType, typename CType>
static arrow::Result<std::shared_ptr<arrow::Array>> build_numeric_array(const uint8_t* data, int64_t n) {
    arrow::NumericBuilder<ArrowType> builder;
    ARROW_RETURN_NOT_OK(builder.Reserve(n));
    const CType* typed = reinterpret_cast<const CType*>(data);
    ARROW_RETURN_NOT_OK(builder.AppendValues(typed, n));
    return builder.Finish();
}

char* pdl_arrow_write_file(const char* path, int format,
                           const PdlArrowColumn* cols, size_t num_cols) {
    std::vector<std::shared_ptr<arrow::Field>> fields;
    std::vector<std::shared_ptr<arrow::Array>> arrays;
    fields.reserve(num_cols);
    arrays.reserve(num_cols);

    for (size_t i = 0; i < num_cols; ++i) {
        std::string t(cols[i].type_name);
        std::shared_ptr<arrow::DataType> dt;
        arrow::Result<std::shared_ptr<arrow::Array>> arr_res;

        if (t == "double") {
            dt = arrow::float64();
            arr_res = build_numeric_array<arrow::DoubleType, double>(cols[i].data, cols[i].num_elements);
        } else if (t == "float") {
            dt = arrow::float32();
            arr_res = build_numeric_array<arrow::FloatType, float>(cols[i].data, cols[i].num_elements);
        } else if (t == "sbyte") {
            dt = arrow::int8();
            arr_res = build_numeric_array<arrow::Int8Type, int8_t>(cols[i].data, cols[i].num_elements);
        } else if (t == "byte") {
            dt = arrow::uint8();
            arr_res = build_numeric_array<arrow::UInt8Type, uint8_t>(cols[i].data, cols[i].num_elements);
        } else if (t == "short") {
            dt = arrow::int16();
            arr_res = build_numeric_array<arrow::Int16Type, int16_t>(cols[i].data, cols[i].num_elements);
        } else if (t == "ushort") {
            dt = arrow::uint16();
            arr_res = build_numeric_array<arrow::UInt16Type, uint16_t>(cols[i].data, cols[i].num_elements);
        } else if (t == "long") {
            dt = arrow::int32();
            arr_res = build_numeric_array<arrow::Int32Type, int32_t>(cols[i].data, cols[i].num_elements);
        } else if (t == "ulong") {
            dt = arrow::uint32();
            arr_res = build_numeric_array<arrow::UInt32Type, uint32_t>(cols[i].data, cols[i].num_elements);
        } else if (t == "longlong") {
            dt = arrow::int64();
            arr_res = build_numeric_array<arrow::Int64Type, int64_t>(cols[i].data, cols[i].num_elements);
        } else if (t == "ulonglong") {
            dt = arrow::uint64();
            arr_res = build_numeric_array<arrow::UInt64Type, uint64_t>(cols[i].data, cols[i].num_elements);
        } else if (t == "cfloat") {
            dt = arrow::fixed_size_list(arrow::float32(), 2);
            auto child_res = build_numeric_array<arrow::FloatType, float>(cols[i].data, cols[i].num_elements * 2);
            if (!child_res.ok()) {
                return dup_str("Failed to build cfloat child array: " + child_res.status().ToString());
            }
            arr_res = arrow::FixedSizeListArray::FromArrays(*child_res, 2);
        } else if (t == "cdouble") {
            dt = arrow::fixed_size_list(arrow::float64(), 2);
            auto child_res = build_numeric_array<arrow::DoubleType, double>(cols[i].data, cols[i].num_elements * 2);
            if (!child_res.ok()) {
                return dup_str("Failed to build cdouble child array: " + child_res.status().ToString());
            }
            arr_res = arrow::FixedSizeListArray::FromArrays(*child_res, 2);
        } else {
            return dup_str("Unsupported PDL type for Arrow write: " + t);
        }

        if (!arr_res.ok()) {
            return dup_str("Failed to build Arrow array: " + arr_res.status().ToString());
        }
        fields.push_back(arrow::field(cols[i].name, dt));
        arrays.push_back(*arr_res);
    }

    auto schema = arrow::schema(fields);
    auto table  = arrow::Table::Make(schema, arrays);

    auto outfile_res = arrow::io::FileOutputStream::Open(path);
    if (!outfile_res.ok()) {
        return dup_str("Failed to open output file: " + outfile_res.status().ToString());
    }
    auto outfile = *outfile_res;

    if (format == 0) {
        auto writer_res = arrow::ipc::MakeFileWriter(outfile, schema);
        if (!writer_res.ok()) {
            return dup_str("Arrow MakeFileWriter failed: " + writer_res.status().ToString());
        }
        auto writer = *writer_res;
        auto st = writer->WriteTable(*table);
        if (!st.ok()) return dup_str("Arrow WriteTable failed: " + st.ToString());
        st = writer->Close();
        if (!st.ok()) return dup_str("Arrow writer Close failed: " + st.ToString());
    } else if (format == 1) {
        auto st = parquet::arrow::WriteTable(*table, arrow::default_memory_pool(), outfile, 65536);
        if (!st.ok()) return dup_str("Parquet WriteTable failed: " + st.ToString());
    } else {
        return dup_str("Unsupported format code");
    }

    auto close_st = outfile->Close();
    if (!close_st.ok()) return dup_str("Output file Close failed: " + close_st.ToString());
    return nullptr;
}
