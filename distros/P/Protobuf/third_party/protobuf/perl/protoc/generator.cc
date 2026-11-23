// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file or at
// https://developers.google.com/open-source/licenses/bsd

#include "third_party/protobuf/perl/protoc/generator.h"

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <map>

#ifdef GOOGLE3
#include "net/proto2/proto/descriptor.upb.h"
#include "third_party/absl/strings/str_cat.h"
#include "third_party/absl/strings/string_view.h"
#include "third_party/protobuf/compiler/perl/plugin.upb.h"
#else
#include "google/protobuf/compiler/plugin.upb.h"
#include "google/protobuf/descriptor.upb.h"
#endif

#include "third_party/protobuf/perl/protoc/helpers.h"

namespace google {
namespace protobuf {
namespace compiler {
namespace perl {

void PerlCodeGenerator::BuildPackageMap() {
  size_t file_count;
  const proto2_FileDescriptorProto* const* files =
      proto2_compiler_CodeGeneratorRequest_proto_file(request_, &file_count);

  for (size_t i = 0; i < file_count; i++) {
    upb_StringView name_sv = proto2_FileDescriptorProto_name(files[i]);
    absl::string_view name(name_sv.data, name_sv.size);
    file_to_package_[std::string(name)] = GetPerlPackage(files[i]);
  }
}

void PerlCodeGenerator::RegisterTypesRecursively(
    const proto2_DescriptorProto* msg_proto, absl::string_view proto_prefix,
    absl::string_view perl_prefix) {
  upb_StringView name_sv = proto2_DescriptorProto_name(msg_proto);
  absl::string_view name(name_sv.data, name_sv.size);

  std::string full_proto = absl::StrCat(proto_prefix, ".", name);
  std::string full_perl = absl::StrCat(perl_prefix, "::", name);

  type_to_perl_class_[full_proto] = full_perl;

  size_t nested_count;
  const proto2_DescriptorProto* const* nested =
      proto2_DescriptorProto_nested_type(msg_proto, &nested_count);
  for (size_t i = 0; i < nested_count; i++) {
    RegisterTypesRecursively(nested[i], full_proto, full_perl);
  }
}

void PerlCodeGenerator::BuildTypeMap() {
  size_t file_count;
  const proto2_FileDescriptorProto* const* files =
      proto2_compiler_CodeGeneratorRequest_proto_file(request_, &file_count);

  for (size_t i = 0; i < file_count; i++) {
    upb_StringView name_sv = proto2_FileDescriptorProto_name(files[i]);
    absl::string_view name(name_sv.data, name_sv.size);

    std::string perl_pkg;
    auto it = file_to_package_.find(std::string(name));
    if (it != file_to_package_.end()) {
      perl_pkg = it->second;
    }

    upb_StringView pkg_sv = proto2_FileDescriptorProto_package(files[i]);
    std::string proto_pkg =
        absl::StrCat(".", absl::string_view(pkg_sv.data, pkg_sv.size));

    size_t msg_count;
    const proto2_DescriptorProto* const* messages =
        proto2_FileDescriptorProto_message_type(files[i], &msg_count);
    for (size_t j = 0; j < msg_count; j++) {
      RegisterTypesRecursively(messages[j], proto_pkg, perl_pkg);
    }
  }
}

std::string PerlCodeGenerator::ResolvePerlClass(absl::string_view proto_type) {
  auto it = type_to_perl_class_.find(std::string(proto_type));
  if (it != type_to_perl_class_.end()) {
    return it->second;
  }
  absl::string_view s = proto_type;
  ConsumePrefix(&s, ".");
  return CapitalizePackage(s);
}

std::string PerlCodeGenerator::GetPerlPackage(
    const proto2_FileDescriptorProto* file_proto) {
  upb_StringView name_sv = proto2_FileDescriptorProto_name(file_proto);
  absl::string_view name(name_sv.data, name_sv.size);

  upb_StringView pkg_sv = proto2_FileDescriptorProto_package(file_proto);
  absl::string_view pkg(pkg_sv.data, pkg_sv.size);

  absl::string_view file_segment = name;
  size_t last_slash = file_segment.find_last_of('/');
  if (last_slash != absl::string_view::npos) {
    file_segment = file_segment.substr(last_slash + 1);
  }
  size_t dot = file_segment.find_last_of('.');
  if (dot != absl::string_view::npos) {
    file_segment = file_segment.substr(0, dot);
  }
  std::string camel_file_segment = ToCamelCase(file_segment);

  std::string base_package = CapitalizePackage(pkg);
  if (!base_package.empty()) {
    return absl::StrCat(base_package, "::", camel_file_segment);
  } else {
    return camel_file_segment;
  }
}

proto2_compiler_CodeGeneratorResponse* PerlCodeGenerator::Generate() {
  proto2_compiler_CodeGeneratorResponse* response =
      proto2_compiler_CodeGeneratorResponse_new(arena_);
  proto2_compiler_CodeGeneratorResponse_set_supported_features(
      response,
      proto2_compiler_CodeGeneratorResponse_FEATURE_PROTO3_OPTIONAL |
          proto2_compiler_CodeGeneratorResponse_FEATURE_SUPPORTS_EDITIONS);
  proto2_compiler_CodeGeneratorResponse_set_minimum_edition(response, 1000);
  proto2_compiler_CodeGeneratorResponse_set_maximum_edition(response, 1001);

  size_t gen_file_count;
  const upb_StringView* gen_files =
      proto2_compiler_CodeGeneratorRequest_file_to_generate(request_,
                                                            &gen_file_count);

  size_t all_file_count;
  const proto2_FileDescriptorProto* const* all_files =
      proto2_compiler_CodeGeneratorRequest_proto_file(request_,
                                                      &all_file_count);

  for (size_t i = 0; i < gen_file_count; i++) {
    absl::string_view name(gen_files[i].data, gen_files[i].size);

    const proto2_FileDescriptorProto* file_proto = nullptr;
    for (size_t j = 0; j < all_file_count; j++) {
      upb_StringView cur_name_sv =
          proto2_FileDescriptorProto_name(all_files[j]);
      if (name == absl::string_view(cur_name_sv.data, cur_name_sv.size)) {
        file_proto = all_files[j];
        break;
      }
    }
    if (!file_proto) continue;

    auto it = file_to_package_.find(std::string(name));
    if (it != file_to_package_.end()) {
      package_name_ = it->second;
    }

    // 1. Generate Main Module (.pm)
    std::string module_content = GenerateModule(file_proto);
    proto2_compiler_CodeGeneratorResponse_File* file =
        proto2_compiler_CodeGeneratorResponse_add_file(response, arena_);

    std::string p = package_name_;
    std::replace(p.begin(), p.end(), ':', '/');
    size_t double_slash;
    while ((double_slash = p.find("//")) != std::string::npos) {
      p.replace(double_slash, 2, "/");
    }

    std::string final_path = absl::StrCat(p, ".pm");
    proto2_compiler_CodeGeneratorResponse_File_set_name(file,
                                                        ArenaCopy(final_path));
    proto2_compiler_CodeGeneratorResponse_File_set_content(
        file, ArenaCopy(module_content));

    // 2. Generate Types Module (::Types)
    std::string types_content = GenerateTypes(file_proto);
    proto2_compiler_CodeGeneratorResponse_File* types_file =
        proto2_compiler_CodeGeneratorResponse_add_file(response, arena_);
    std::string types_path = absl::StrCat(p, "/Types.pm");
    proto2_compiler_CodeGeneratorResponse_File_set_name(types_file,
                                                        ArenaCopy(types_path));
    proto2_compiler_CodeGeneratorResponse_File_set_content(
        types_file, ArenaCopy(types_content));
  }

  return response;
}

static std::string FieldTypeToString(int type) {
  switch (type) {
    case 1:
      return "Double";
    case 2:
      return "Float";
    case 3:
      return "Int64";
    case 4:
      return "UInt64";
    case 5:
      return "Int32";
    case 6:
      return "Fixed64";
    case 7:
      return "Fixed32";
    case 8:
      return "Bool";
    case 9:
      return "String";
    case 10:
      return "Group";
    case 11:
      return "Message";
    case 12:
      return "Bytes";
    case 13:
      return "UInt32";
    case 14:
      return "Enum";
    case 15:
      return "SFixed32";
    case 16:
      return "SFixed64";
    case 17:
      return "SInt32";
    case 18:
      return "SInt64";
    default:
      return "Unknown";
  }
}

static std::string FormatProtoCommentForPod(absl::string_view raw) {
  std::stringstream out;
  size_t pos = 0;
  bool any_line = false;
  while (pos < raw.size()) {
    size_t nl = raw.find('\n', pos);
    absl::string_view line =
        (nl == absl::string_view::npos) ? raw.substr(pos) : raw.substr(pos, nl - pos);
    pos = (nl == absl::string_view::npos) ? raw.size() : nl + 1;

    // Strip a single leading space (standard protoc comment formatting)
    if (!line.empty() && line[0] == ' ') {
      line.remove_prefix(1);
    }
    // Convert Markdown **bold** to POD B<bold>
    std::string converted;
    size_t lpos = 0;
    while (lpos < line.size()) {
      size_t b_start = line.find("**", lpos);
      if (b_start == absl::string_view::npos) {
        converted.append(line.data() + lpos, line.size() - lpos);
        break;
      }
      size_t b_end = line.find("**", b_start + 2);
      if (b_end == absl::string_view::npos || b_end == b_start + 2) {
        converted.append(line.data() + lpos, line.size() - lpos);
        break;
      }
      converted.append(line.data() + lpos, b_start - lpos);
      converted.append("B<");
      converted.append(line.data() + b_start + 2, b_end - (b_start + 2));
      converted.append(">");
      lpos = b_end + 2;
    }
    // Prevent raw '=' at column 0 from being parsed as a POD directive
    if (!converted.empty() && converted[0] == '=') {
      out << " " << converted << "\n";
    } else {
      out << converted << "\n";
    }
    any_line = true;
  }
  return any_line ? out.str() : std::string();
}

#ifndef GOOGLE3
#ifndef proto2_SourceCodeInfo
#define proto2_SourceCodeInfo google_protobuf_SourceCodeInfo
#define proto2_SourceCodeInfo_Location google_protobuf_SourceCodeInfo_Location
#define proto2_FileDescriptorProto_source_code_info google_protobuf_FileDescriptorProto_source_code_info
#define proto2_SourceCodeInfo_location google_protobuf_SourceCodeInfo_location
#define proto2_SourceCodeInfo_Location_leading_comments google_protobuf_SourceCodeInfo_Location_leading_comments
#define proto2_SourceCodeInfo_Location_trailing_comments google_protobuf_SourceCodeInfo_Location_trailing_comments
#define proto2_SourceCodeInfo_Location_path google_protobuf_SourceCodeInfo_Location_path
#endif
#endif

static std::map<std::string, std::string> BuildCommentMap(
    const proto2_FileDescriptorProto* file_proto) {
  std::map<std::string, std::string> comments;
  const proto2_SourceCodeInfo* sci =
      proto2_FileDescriptorProto_source_code_info(file_proto);
  if (!sci) return comments;

  size_t loc_count = 0;
  const proto2_SourceCodeInfo_Location* const* locs =
      proto2_SourceCodeInfo_location(sci, &loc_count);
  for (size_t i = 0; i < loc_count; i++) {
    const proto2_SourceCodeInfo_Location* loc = locs[i];
    upb_StringView lead = proto2_SourceCodeInfo_Location_leading_comments(loc);
    upb_StringView trail = proto2_SourceCodeInfo_Location_trailing_comments(loc);
    absl::string_view text = (lead.size > 0)
                                 ? absl::string_view(lead.data, lead.size)
                                 : absl::string_view(trail.data, trail.size);
    if (text.empty()) continue;

    size_t path_len = 0;
    const int32_t* path = proto2_SourceCodeInfo_Location_path(loc, &path_len);
    if (path_len == 0) continue;

    std::stringstream key;
    for (size_t j = 0; j < path_len; j++) {
      if (j > 0) key << ".";
      key << path[j];
    }
    std::string formatted = FormatProtoCommentForPod(text);
    if (!formatted.empty()) {
      comments[key.str()] = formatted;
    }
  }
  return comments;
}

std::string PerlCodeGenerator::GenerateModule(
    const proto2_FileDescriptorProto* file_proto) {
  std::map<std::string, std::string> comment_map = BuildCommentMap(file_proto);
  std::stringstream ss;
  ss << "package " << package_name_ << ";\n\n";
  ss << "use strict;\n";
  ss << "use warnings;\n\n";
#ifndef PROTOBUF_PERL_VERSION
#define PROTOBUF_PERL_VERSION "0.05"
#endif
  ss << "our $VERSION = '" << PROTOBUF_PERL_VERSION << "';\n\n";

  ss << "use Protobuf::Message;\n";
  ss << "use Protobuf::DescriptorPool;\n";
  ss << "use Protobuf::Internal qw(:all);\n";
  ss << "use MIME::Base64;\n\n";

  ss << "BEGIN {\n";

  // Add requires for dependencies INSIDE BEGIN block
  size_t dep_count;
  const upb_StringView* deps =
      proto2_FileDescriptorProto_dependency(file_proto, &dep_count);
  for (size_t i = 0; i < dep_count; i++) {
    absl::string_view dep(deps[i].data, deps[i].size);
    auto it = file_to_package_.find(std::string(dep));
    if (it != file_to_package_.end()) {
      ss << "    eval { require " << it->second << " };\n";
    }
  }

  ss << "    my $descriptor_b64 = <<'EOF';\n";

  size_t size;
  char* buf = proto2_FileDescriptorProto_serialize(file_proto, arena_, &size);

  static const char b64_table[] =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  for (size_t i = 0; i < size; i += 3) {
    uint32_t val = (uint8_t)buf[i] << 16;
    if (i + 1 < size) val |= (uint8_t)buf[i + 1] << 8;
    if (i + 2 < size) val |= (uint8_t)buf[i + 2];

    ss << b64_table[(val >> 18) & 0x3F];
    ss << b64_table[(val >> 12) & 0x3F];
    ss << (i + 1 < size ? b64_table[(val >> 6) & 0x3F] : '=');
    ss << (i + 2 < size ? b64_table[val & 0x3F] : '=');

    if ((i / 3 + 1) % 18 == 0) ss << "\n";
  }
  ss << "\nEOF\n";
  ss << "    "
        "Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::"
        "Base64::decode_base64($descriptor_b64));\n";
  ss << "}\n\n";

  ss << "# Message definitions\n\n";

  std::stringstream pod_messages;
  std::string first_msg_name;
  std::vector<std::string> first_msg_fields;

  size_t message_count;
  const proto2_DescriptorProto* const* messages =
      proto2_FileDescriptorProto_message_type(file_proto, &message_count);

  for (size_t i = 0; i < message_count; i++) {
    const proto2_DescriptorProto* msg = messages[i];
    upb_StringView msg_name_sv = proto2_DescriptorProto_name(msg);
    absl::string_view msg_name(msg_name_sv.data, msg_name_sv.size);

    if (first_msg_name.empty()) {
      first_msg_name = std::string(msg_name);
    }

    ss << "# === Message: " << package_name_ << "::" << msg_name << " ===\n";
    ss << "    # Fields for " << msg_name << "\n";

    size_t field_count;
    const proto2_FieldDescriptorProto* const* fields =
        proto2_DescriptorProto_field(msg, &field_count);

    for (size_t j = 0; j < field_count; j++) {
      const proto2_FieldDescriptorProto* f = fields[j];
      upb_StringView f_name_sv = proto2_FieldDescriptorProto_name(f);
      upb_StringView f_type_name_sv = proto2_FieldDescriptorProto_type_name(f);
      int f_type = proto2_FieldDescriptorProto_type(f);

      if (i == 0 && first_msg_fields.size() < 4) {
        first_msg_fields.emplace_back(f_name_sv.data, f_name_sv.size);
      }

      ss << "    # Field: "
         << absl::string_view(f_name_sv.data, f_name_sv.size);
      ss << " Type: " << f_type << " ("
         << absl::string_view(f_type_name_sv.data, f_type_name_sv.size)
         << ")\n";
    }
    ss << "\n";

    // Accumulate unified POD for this message
    pod_messages << "=head2 " << package_name_ << "::" << msg_name << "\n\n";
    auto msg_cit = comment_map.find("4." + std::to_string(i));
    if (msg_cit != comment_map.end()) {
      pod_messages << msg_cit->second << "\n";
    }
    pod_messages << "Inherits from L<Protobuf::Message>.\n\n";
    if (field_count > 0) {
      pod_messages << "=head3 Accessors\n\n=over 4\n\n";
      for (size_t j = 0; j < field_count; j++) {
        const proto2_FieldDescriptorProto* f = fields[j];
        upb_StringView f_name_sv = proto2_FieldDescriptorProto_name(f);
        absl::string_view f_name(f_name_sv.data, f_name_sv.size);
        int f_type = proto2_FieldDescriptorProto_type(f);
        upb_StringView f_type_name_sv = proto2_FieldDescriptorProto_type_name(f);

        pod_messages << "=item * C<< $msg->" << f_name << "() >> / C<< $msg->"
                     << f_name << "($value) >>\n\n";
        pod_messages << "Type: C<" << FieldTypeToString(f_type) << ">";
        if (f_type_name_sv.size > 0) {
          absl::string_view tn(f_type_name_sv.data, f_type_name_sv.size);
          std::string resolved = ResolvePerlClass(tn);
          pod_messages << " (L<" << resolved << ">)";
        }
        pod_messages << "\n\n";
        auto f_cit = comment_map.find("4." + std::to_string(i) + ".2." + std::to_string(j));
        if (f_cit != comment_map.end()) {
          pod_messages << f_cit->second << "\n";
        }
      }
      pod_messages << "=back\n\n";
    }

    size_t enum_count;
    const proto2_EnumDescriptorProto* const* enums =
        proto2_DescriptorProto_enum_type(msg, &enum_count);
    for (size_t j = 0; j < enum_count; j++) {
      const proto2_EnumDescriptorProto* e = enums[j];
      upb_StringView e_name_sv = proto2_EnumDescriptorProto_name(e);
      absl::string_view e_name(e_name_sv.data, e_name_sv.size);

      ss << "# Enum: " << msg_name << "::" << e_name << "\n";
      size_t val_count;
      const proto2_EnumValueDescriptorProto* const* values =
          proto2_EnumDescriptorProto_value(e, &val_count);
      for (size_t k = 0; k < val_count; k++) {
        const proto2_EnumValueDescriptorProto* ev = values[k];
        upb_StringView ev_name_sv = proto2_EnumValueDescriptorProto_name(ev);
        int ev_num = proto2_EnumValueDescriptorProto_number(ev);
        ss << "our $" << msg_name << "_"
           << absl::string_view(ev_name_sv.data, ev_name_sv.size) << " = "
           << ev_num << ";\n";
      }
      ss << "\n";

      pod_messages << "=head3 Enum: " << msg_name << "::" << e_name << "\n\n";
      pod_messages << "=over 4\n\n";
      for (size_t k = 0; k < val_count; k++) {
        const proto2_EnumValueDescriptorProto* ev = values[k];
        upb_StringView ev_name_sv = proto2_EnumValueDescriptorProto_name(ev);
        absl::string_view ev_name(ev_name_sv.data, ev_name_sv.size);
        int ev_num = proto2_EnumValueDescriptorProto_number(ev);
        pod_messages << "=item * C<" << ev_name << "> => C<" << ev_num
                     << ">\n\n";
      }
      pod_messages << "=back\n\n";
    }
  }

  // Service definitions
  size_t service_count;
  const proto2_ServiceDescriptorProto* const* services =
      proto2_FileDescriptorProto_service(file_proto, &service_count);

  upb_StringView pkg_sv = proto2_FileDescriptorProto_package(file_proto);
  absl::string_view proto_pkg(pkg_sv.data, pkg_sv.size);
  std::string default_host = GetDefaultHost(proto_pkg);

  for (size_t i = 0; i < service_count; i++) {
    const proto2_ServiceDescriptorProto* srv = services[i];
    upb_StringView srv_name_sv = proto2_ServiceDescriptorProto_name(srv);
    absl::string_view srv_name(srv_name_sv.data, srv_name_sv.size);

    ss << "# === Service Client: " << package_name_ << "::" << srv_name
       << "Client ===\n";
    ss << "package " << package_name_ << "::" << srv_name << "Client;\n\n";

    ss << "=pod\n\n";
    ss << "=head2 Service Client: " << package_name_ << "::" << srv_name
       << "Client\n\n";
    ss << "Client stub representing the remote C<" << srv_name << "> gRPC "
          "service. Delegates call dispatching to L<Google::gRPC::Client>.\n\n";
    ss << "=head3 target\n\n";
    ss << "The endpoint target address. Defaults to C<" << default_host
       << ">.\n\n";
    ss << "=head3 credentials\n\n";
    ss << "The authentication credentials provider. Defaults to application "
          "default credentials via L<Google::Auth>.\n\n";
    ss << "=cut\n\n";

    ss << "use Moo;\n";
    ss << "use Google::Auth;\n";
    ss << "use Google::gRPC::Client;\n\n";

    ss << "has credentials => ( is => 'ro', default => sub { "
          "Google::Auth->default() } );\n";
    ss << "has target      => ( is => 'ro', default => '" << default_host
       << "' );\n\n";

    ss << "has _grpc_client => (\n";
    ss << "    is => 'ro',\n";
    ss << "    lazy => 1,\n";
    ss << "    builder => sub {\n";
    ss << "        my $self = shift;\n";
    ss << "        return Google::gRPC::Client->new(\n";
    ss << "            target     => $self->target,\n";
    ss << "            auth_token => $self->credentials->get_token(),\n";
    ss << "        );\n";
    ss << "    }\n";
    ss << ");\n\n";

    size_t method_count;
    const proto2_MethodDescriptorProto* const* methods =
        proto2_ServiceDescriptorProto_method(srv, &method_count);
    for (size_t j = 0; j < method_count; j++) {
      const proto2_MethodDescriptorProto* m = methods[j];
      upb_StringView m_name_sv = proto2_MethodDescriptorProto_name(m);
      absl::string_view m_name(m_name_sv.data, m_name_sv.size);

      upb_StringView in_type_sv = proto2_MethodDescriptorProto_input_type(m);
      absl::string_view in_type(in_type_sv.data, in_type_sv.size);
      std::string req_class = ResolvePerlClass(in_type);

      upb_StringView out_type_sv = proto2_MethodDescriptorProto_output_type(m);
      absl::string_view out_type(out_type_sv.data, out_type_sv.size);
      std::string res_class = ResolvePerlClass(out_type);

      std::string snake_method = ToSnakeCase(m_name);

      ss << "sub " << snake_method << " {\n";
      ss << "    my ($self, $args) = @_;\n";
      ss << "    my $req = ref($args) eq 'HASH'\n";
      ss << "        ? " << req_class << "->new($args)\n";
      ss << "        : $args;\n";
      ss << "    return $self->_grpc_client->call({\n";
      ss << "        service        => '" << proto_pkg << "." << srv_name
         << "',\n";
      ss << "        method         => '" << m_name << "',\n";
      ss << "        request        => $req,\n";
      ss << "        response_class => '" << res_class << "',\n";
      ss << "    });\n";
      ss << "}\n\n";
    }
  }

  upb_StringView proto_file_sv = proto2_FileDescriptorProto_name(file_proto);
  absl::string_view proto_file_name(proto_file_sv.data, proto_file_sv.size);

  ss << "1;\n\n__END__\n\n=encoding UTF-8\n\n=head1 NAME\n\n"
     << package_name_ << " - Compiled Protocol Buffers messages for "
     << proto_file_name << "\n\n";

  if (!first_msg_name.empty()) {
    std::string full_first = absl::StrCat(package_name_, "::", first_msg_name);
    ss << "=head1 SYNOPSIS\n\n";
    ss << "    use " << package_name_ << ";\n\n";
    ss << "    my $msg = " << full_first << "->new({\n";
    for (const auto& fn : first_msg_fields) {
      ss << "        " << fn << " => $" << fn << ",\n";
    }
    ss << "    });\n\n";
    if (!first_msg_fields.empty()) {
      ss << "    # Read or update a field\n";
      ss << "    my $val = $msg->" << first_msg_fields[0] << "();\n\n";
    }
    ss << "    # Binary wire-format roundtrip\n";
    ss << "    my $bytes   = $msg->serialize();\n";
    ss << "    my $decoded = " << full_first << "->parse($bytes);\n\n";
    ss << "    # Canonical ProtoJSON\n";
    ss << "    my $json = $msg->to_json();\n\n";
  }

  ss << "=head1 DESCRIPTION\n\n"
     << "Auto-generated L<Protobuf> message classes compiled from C<"
     << proto_file_name << ">. All message classes inherit from\n"
     << "L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,\n"
     << "C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.\n\n";

  std::string msgs_pod = pod_messages.str();
  if (!msgs_pod.empty()) {
    ss << "=head1 MESSAGES\n\n" << msgs_pod;
  }

  ss << "=head1 SEE ALSO\n\n"
     << "L<Protobuf>, L<Protobuf::Message>, L<" << package_name_
     << "::Types>, L<https://protobuf.dev/>\n\n"
     << "=head1 LICENSE AND COPYRIGHT\n\nCopyright (C) 2026 Google LLC\n\n"
     << "This program is released under the Apache 2.0 license.\n\n=cut\n";
  return ss.str();
}

std::string PerlCodeGenerator::GenerateTypes(
    const proto2_FileDescriptorProto* file_proto) {
  std::stringstream ss;
  ss << "package " << package_name_ << "::Types;\n\n";
  ss << "use strict;\n";
  ss << "use warnings;\n\n";
  ss << "use Type::Library -base;\n";
  ss << "use Type::Utils -all;\n";
  ss << "use Types::Standard -types;\n\n";

  size_t enum_count;
  const proto2_EnumDescriptorProto* const* enums =
      proto2_FileDescriptorProto_enum_type(file_proto, &enum_count);
  for (size_t j = 0; j < enum_count; ++j) {
    PrintEnumTypes(enums[j], package_name_, ss);
  }

  size_t message_count;
  const proto2_DescriptorProto* const* messages =
      proto2_FileDescriptorProto_message_type(file_proto, &message_count);
  for (size_t j = 0; j < message_count; ++j) {
    PrintTypesRecursively(messages[j], package_name_, ss);
  }

  ss << "1;\n\n__END__\n\n=head1 NAME\n\n"
     << package_name_
     << "::Types - Type definitions and coercions\n\n=head1 DESCRIPTION\n\n"
     << "Auto-generated Type::Tiny definitions and coercions for Protocol "
        "Buffers.\n\n"
     << "=head1 LICENSE AND COPYRIGHT\n\nCopyright (C) 2026 Google LLC\n\n"
     << "This program is released under the Apache 2.0 license.\n\n=cut\n";
  return ss.str();
}

void PerlCodeGenerator::PrintTypesRecursively(
    const proto2_DescriptorProto* msg_proto, absl::string_view current_package,
    std::stringstream& ss) {
  upb_StringView msg_name_sv = proto2_DescriptorProto_name(msg_proto);
  absl::string_view msg_name(msg_name_sv.data, msg_name_sv.size);
  std::string full_msg_name = absl::StrCat(current_package, "::", msg_name);

  PrintMessageTypes(msg_proto, current_package, ss);

  size_t nested_enum_count;
  const proto2_EnumDescriptorProto* const* nested_enums =
      proto2_DescriptorProto_enum_type(msg_proto, &nested_enum_count);
  for (size_t k = 0; k < nested_enum_count; ++k) {
    PrintEnumTypes(nested_enums[k], full_msg_name, ss);
  }

  size_t nested_message_count;
  const proto2_DescriptorProto* const* nested_messages =
      proto2_DescriptorProto_nested_type(msg_proto, &nested_message_count);
  for (size_t k = 0; k < nested_message_count; ++k) {
    PrintTypesRecursively(nested_messages[k], full_msg_name, ss);
  }
}

void PerlCodeGenerator::PrintMessageTypes(
    const proto2_DescriptorProto* msg_proto, absl::string_view current_package,
    std::stringstream& ss) {
  upb_StringView msg_name_sv = proto2_DescriptorProto_name(msg_proto);
  absl::string_view msg_name(msg_name_sv.data, msg_name_sv.size);
  std::string full_perl_class = absl::StrCat(current_package, "::", msg_name);

  ss << "declare '" << msg_name << "',\n";
  ss << "    as InstanceOf['" << full_perl_class << "'];\n\n";

  ss << "coerce '" << msg_name << "',\n";
  ss << "    from HashRef, via { '" << full_perl_class << "'->new($_) };\n\n";

  // Add Repeated and Map variants
  ss << "declare 'Repeated" << msg_name << "',\n";
  ss << "    as ArrayRef[" << msg_name << "()];\n\n";

  ss << "coerce 'Repeated" << msg_name << "',\n";
  ss << "    from ArrayRef[HashRef], via { [ map { '" << full_perl_class
     << "'->new($_) } @$_ ] };\n\n";

  ss << "declare 'MapString" << msg_name << "',\n";
  ss << "    as HashRef[" << msg_name << "()];\n\n";
}

void PerlCodeGenerator::PrintEnumTypes(
    const proto2_EnumDescriptorProto* enum_proto,
    absl::string_view current_package, std::stringstream& ss) {
  upb_StringView enum_name_sv = proto2_EnumDescriptorProto_name(enum_proto);
  absl::string_view enum_name(enum_name_sv.data, enum_name_sv.size);

  ss << "declare '" << enum_name << "',\n";
  ss << "    as (Int | Str);\n\n";
}

}  // namespace perl
}  // namespace compiler
}  // namespace protobuf
}  // namespace google
