# This file was created automatically by SWIG 1.3.29.
# Don't modify this file, modify the SWIG interface instead.
package RDF::Redland::CORE;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
package RDF::Redland::COREc;
bootstrap RDF::Redland::CORE;
package RDF::Redland::CORE;
@EXPORT = qw( );

# ---------- BASE METHODS -------------

package RDF::Redland::CORE;

sub TIEHASH {
    my ($classname,$obj) = @_;
    return bless $obj, $classname;
}

sub CLEAR { }

sub FIRSTKEY { }

sub NEXTKEY { }

sub FETCH {
    my ($self,$field) = @_;
    my $member_func = "swig_${field}_get";
    $self->$member_func();
}

sub STORE {
    my ($self,$field,$newval) = @_;
    my $member_func = "swig_${field}_set";
    $self->$member_func($newval);
}

sub this {
    my $ptr = shift;
    return tied(%$ptr);
}


# ------- FUNCTION WRAPPERS --------

package RDF::Redland::CORE;

*librdf_new_digest = *RDF::Redland::COREc::librdf_new_digest;
*librdf_free_digest = *RDF::Redland::COREc::librdf_free_digest;
*librdf_digest_init = *RDF::Redland::COREc::librdf_digest_init;
*librdf_digest_update = *RDF::Redland::COREc::librdf_digest_update;
*librdf_digest_update_string = *RDF::Redland::COREc::librdf_digest_update_string;
*librdf_digest_final = *RDF::Redland::COREc::librdf_digest_final;
*librdf_digest_to_string = *RDF::Redland::COREc::librdf_digest_to_string;
*librdf_new_hash_from_string = *RDF::Redland::COREc::librdf_new_hash_from_string;
*librdf_new_hash_from_array_of_strings = *RDF::Redland::COREc::librdf_new_hash_from_array_of_strings;
*librdf_free_hash = *RDF::Redland::COREc::librdf_free_hash;
*librdf_new_world = *RDF::Redland::COREc::librdf_new_world;
*librdf_free_world = *RDF::Redland::COREc::librdf_free_world;
*librdf_world_open = *RDF::Redland::COREc::librdf_world_open;
*librdf_world_get_feature = *RDF::Redland::COREc::librdf_world_get_feature;
*librdf_world_set_feature = *RDF::Redland::COREc::librdf_world_set_feature;
*librdf_parser_get_accept_header = *RDF::Redland::COREc::librdf_parser_get_accept_header;
*librdf_free_iterator = *RDF::Redland::COREc::librdf_free_iterator;
*librdf_iterator_end = *RDF::Redland::COREc::librdf_iterator_end;
*librdf_iterator_get_object = *RDF::Redland::COREc::librdf_iterator_get_object;
*librdf_iterator_get_context = *RDF::Redland::COREc::librdf_iterator_get_context;
*librdf_iterator_next = *RDF::Redland::COREc::librdf_iterator_next;
*librdf_new_uri = *RDF::Redland::COREc::librdf_new_uri;
*librdf_new_uri_from_uri = *RDF::Redland::COREc::librdf_new_uri_from_uri;
*librdf_new_uri_from_filename = *RDF::Redland::COREc::librdf_new_uri_from_filename;
*librdf_free_uri = *RDF::Redland::COREc::librdf_free_uri;
*librdf_uri_to_string = *RDF::Redland::COREc::librdf_uri_to_string;
*librdf_uri_equals = *RDF::Redland::COREc::librdf_uri_equals;
*librdf_new_node = *RDF::Redland::COREc::librdf_new_node;
*librdf_new_node_from_uri_string = *RDF::Redland::COREc::librdf_new_node_from_uri_string;
*librdf_new_node_from_uri = *RDF::Redland::COREc::librdf_new_node_from_uri;
*librdf_new_node_from_literal = *RDF::Redland::COREc::librdf_new_node_from_literal;
*librdf_new_node_from_typed_literal = *RDF::Redland::COREc::librdf_new_node_from_typed_literal;
*librdf_new_node_from_node = *RDF::Redland::COREc::librdf_new_node_from_node;
*librdf_new_node_from_blank_identifier = *RDF::Redland::COREc::librdf_new_node_from_blank_identifier;
*librdf_free_node = *RDF::Redland::COREc::librdf_free_node;
*librdf_node_get_uri = *RDF::Redland::COREc::librdf_node_get_uri;
*librdf_node_get_type = *RDF::Redland::COREc::librdf_node_get_type;
*librdf_node_get_literal_value = *RDF::Redland::COREc::librdf_node_get_literal_value;
*librdf_node_get_literal_value_as_latin1 = *RDF::Redland::COREc::librdf_node_get_literal_value_as_latin1;
*librdf_node_get_literal_value_language = *RDF::Redland::COREc::librdf_node_get_literal_value_language;
*librdf_node_get_literal_value_datatype_uri = *RDF::Redland::COREc::librdf_node_get_literal_value_datatype_uri;
*librdf_node_get_literal_value_is_wf_xml = *RDF::Redland::COREc::librdf_node_get_literal_value_is_wf_xml;
*librdf_node_to_string = *RDF::Redland::COREc::librdf_node_to_string;
*librdf_node_get_blank_identifier = *RDF::Redland::COREc::librdf_node_get_blank_identifier;
*librdf_node_is_resource = *RDF::Redland::COREc::librdf_node_is_resource;
*librdf_node_is_literal = *RDF::Redland::COREc::librdf_node_is_literal;
*librdf_node_is_blank = *RDF::Redland::COREc::librdf_node_is_blank;
*librdf_node_equals = *RDF::Redland::COREc::librdf_node_equals;
*librdf_new_statement = *RDF::Redland::COREc::librdf_new_statement;
*librdf_new_statement_from_statement = *RDF::Redland::COREc::librdf_new_statement_from_statement;
*librdf_new_statement_from_nodes = *RDF::Redland::COREc::librdf_new_statement_from_nodes;
*librdf_free_statement = *RDF::Redland::COREc::librdf_free_statement;
*librdf_statement_get_subject = *RDF::Redland::COREc::librdf_statement_get_subject;
*librdf_statement_set_subject = *RDF::Redland::COREc::librdf_statement_set_subject;
*librdf_statement_get_predicate = *RDF::Redland::COREc::librdf_statement_get_predicate;
*librdf_statement_set_predicate = *RDF::Redland::COREc::librdf_statement_set_predicate;
*librdf_statement_get_object = *RDF::Redland::COREc::librdf_statement_get_object;
*librdf_statement_set_object = *RDF::Redland::COREc::librdf_statement_set_object;
*librdf_statement_equals = *RDF::Redland::COREc::librdf_statement_equals;
*librdf_statement_match = *RDF::Redland::COREc::librdf_statement_match;
*librdf_statement_to_string = *RDF::Redland::COREc::librdf_statement_to_string;
*librdf_new_model = *RDF::Redland::COREc::librdf_new_model;
*librdf_new_model_with_options = *RDF::Redland::COREc::librdf_new_model_with_options;
*librdf_new_model_from_model = *RDF::Redland::COREc::librdf_new_model_from_model;
*librdf_free_model = *RDF::Redland::COREc::librdf_free_model;
*librdf_model_size = *RDF::Redland::COREc::librdf_model_size;
*librdf_model_add = *RDF::Redland::COREc::librdf_model_add;
*librdf_model_add_typed_literal_statement = *RDF::Redland::COREc::librdf_model_add_typed_literal_statement;
*librdf_model_add_statement = *RDF::Redland::COREc::librdf_model_add_statement;
*librdf_model_add_statements = *RDF::Redland::COREc::librdf_model_add_statements;
*librdf_model_remove_statement = *RDF::Redland::COREc::librdf_model_remove_statement;
*librdf_model_contains_statement = *RDF::Redland::COREc::librdf_model_contains_statement;
*librdf_model_as_stream = *RDF::Redland::COREc::librdf_model_as_stream;
*librdf_model_find_statements = *RDF::Redland::COREc::librdf_model_find_statements;
*librdf_model_find_statements_in_context = *RDF::Redland::COREc::librdf_model_find_statements_in_context;
*librdf_model_get_sources = *RDF::Redland::COREc::librdf_model_get_sources;
*librdf_model_get_arcs = *RDF::Redland::COREc::librdf_model_get_arcs;
*librdf_model_get_targets = *RDF::Redland::COREc::librdf_model_get_targets;
*librdf_model_get_source = *RDF::Redland::COREc::librdf_model_get_source;
*librdf_model_get_arc = *RDF::Redland::COREc::librdf_model_get_arc;
*librdf_model_get_arcs_out = *RDF::Redland::COREc::librdf_model_get_arcs_out;
*librdf_model_get_arcs_in = *RDF::Redland::COREc::librdf_model_get_arcs_in;
*librdf_model_has_arc_in = *RDF::Redland::COREc::librdf_model_has_arc_in;
*librdf_model_has_arc_out = *RDF::Redland::COREc::librdf_model_has_arc_out;
*librdf_model_get_target = *RDF::Redland::COREc::librdf_model_get_target;
*librdf_model_context_add_statement = *RDF::Redland::COREc::librdf_model_context_add_statement;
*librdf_model_context_add_statements = *RDF::Redland::COREc::librdf_model_context_add_statements;
*librdf_model_context_remove_statement = *RDF::Redland::COREc::librdf_model_context_remove_statement;
*librdf_model_context_remove_statements = *RDF::Redland::COREc::librdf_model_context_remove_statements;
*librdf_model_context_as_stream = *RDF::Redland::COREc::librdf_model_context_as_stream;
*librdf_model_sync = *RDF::Redland::COREc::librdf_model_sync;
*librdf_model_get_contexts = *RDF::Redland::COREc::librdf_model_get_contexts;
*librdf_model_contains_context = *RDF::Redland::COREc::librdf_model_contains_context;
*librdf_model_get_feature = *RDF::Redland::COREc::librdf_model_get_feature;
*librdf_model_set_feature = *RDF::Redland::COREc::librdf_model_set_feature;
*librdf_model_load = *RDF::Redland::COREc::librdf_model_load;
*librdf_model_query_execute = *RDF::Redland::COREc::librdf_model_query_execute;
*librdf_model_to_string = *RDF::Redland::COREc::librdf_model_to_string;
*librdf_new_storage = *RDF::Redland::COREc::librdf_new_storage;
*librdf_new_storage_from_storage = *RDF::Redland::COREc::librdf_new_storage_from_storage;
*librdf_free_storage = *RDF::Redland::COREc::librdf_free_storage;
*librdf_new_parser = *RDF::Redland::COREc::librdf_new_parser;
*librdf_free_parser = *RDF::Redland::COREc::librdf_free_parser;
*librdf_parser_parse_as_stream = *RDF::Redland::COREc::librdf_parser_parse_as_stream;
*librdf_parser_parse_into_model = *RDF::Redland::COREc::librdf_parser_parse_into_model;
*librdf_parser_parse_string_as_stream = *RDF::Redland::COREc::librdf_parser_parse_string_as_stream;
*librdf_parser_parse_string_into_model = *RDF::Redland::COREc::librdf_parser_parse_string_into_model;
*librdf_parser_parse_counted_string_as_stream = *RDF::Redland::COREc::librdf_parser_parse_counted_string_as_stream;
*librdf_parser_parse_counted_string_into_model = *RDF::Redland::COREc::librdf_parser_parse_counted_string_into_model;
*librdf_parser_get_feature = *RDF::Redland::COREc::librdf_parser_get_feature;
*librdf_parser_set_feature = *RDF::Redland::COREc::librdf_parser_set_feature;
*librdf_new_query = *RDF::Redland::COREc::librdf_new_query;
*librdf_new_query_from_query = *RDF::Redland::COREc::librdf_new_query_from_query;
*librdf_free_query = *RDF::Redland::COREc::librdf_free_query;
*librdf_query_execute = *RDF::Redland::COREc::librdf_query_execute;
*librdf_query_get_limit = *RDF::Redland::COREc::librdf_query_get_limit;
*librdf_query_set_limit = *RDF::Redland::COREc::librdf_query_set_limit;
*librdf_query_get_offset = *RDF::Redland::COREc::librdf_query_get_offset;
*librdf_query_set_offset = *RDF::Redland::COREc::librdf_query_set_offset;
*librdf_query_results_as_stream = *RDF::Redland::COREc::librdf_query_results_as_stream;
*librdf_query_results_get_count = *RDF::Redland::COREc::librdf_query_results_get_count;
*librdf_query_results_next = *RDF::Redland::COREc::librdf_query_results_next;
*librdf_query_results_finished = *RDF::Redland::COREc::librdf_query_results_finished;
*librdf_query_results_get_binding_value = *RDF::Redland::COREc::librdf_query_results_get_binding_value;
*librdf_query_results_get_binding_name = *RDF::Redland::COREc::librdf_query_results_get_binding_name;
*librdf_query_results_get_binding_value_by_name = *RDF::Redland::COREc::librdf_query_results_get_binding_value_by_name;
*librdf_query_results_get_bindings_count = *RDF::Redland::COREc::librdf_query_results_get_bindings_count;
*librdf_query_results_to_file = *RDF::Redland::COREc::librdf_query_results_to_file;
*librdf_query_results_to_string = *RDF::Redland::COREc::librdf_query_results_to_string;
*librdf_free_query_results = *RDF::Redland::COREc::librdf_free_query_results;
*librdf_query_results_is_bindings = *RDF::Redland::COREc::librdf_query_results_is_bindings;
*librdf_query_results_is_boolean = *RDF::Redland::COREc::librdf_query_results_is_boolean;
*librdf_query_results_is_graph = *RDF::Redland::COREc::librdf_query_results_is_graph;
*librdf_query_results_get_boolean = *RDF::Redland::COREc::librdf_query_results_get_boolean;
*librdf_new_serializer = *RDF::Redland::COREc::librdf_new_serializer;
*librdf_free_serializer = *RDF::Redland::COREc::librdf_free_serializer;
*librdf_serializer_serialize_model_to_file = *RDF::Redland::COREc::librdf_serializer_serialize_model_to_file;
*librdf_serializer_serialize_model_to_string = *RDF::Redland::COREc::librdf_serializer_serialize_model_to_string;
*librdf_serializer_get_feature = *RDF::Redland::COREc::librdf_serializer_get_feature;
*librdf_serializer_set_feature = *RDF::Redland::COREc::librdf_serializer_set_feature;
*librdf_serializer_set_namespace = *RDF::Redland::COREc::librdf_serializer_set_namespace;
*librdf_free_stream = *RDF::Redland::COREc::librdf_free_stream;
*librdf_stream_end = *RDF::Redland::COREc::librdf_stream_end;
*librdf_stream_next = *RDF::Redland::COREc::librdf_stream_next;
*librdf_stream_get_object = *RDF::Redland::COREc::librdf_stream_get_object;
*librdf_stream_get_context = *RDF::Redland::COREc::librdf_stream_get_context;
*librdf_log_message_code = *RDF::Redland::COREc::librdf_log_message_code;
*librdf_log_message_level = *RDF::Redland::COREc::librdf_log_message_level;
*librdf_log_message_facility = *RDF::Redland::COREc::librdf_log_message_facility;
*librdf_log_message_message = *RDF::Redland::COREc::librdf_log_message_message;
*librdf_log_message_locator = *RDF::Redland::COREc::librdf_log_message_locator;
*raptor_locator_line = *RDF::Redland::COREc::raptor_locator_line;
*raptor_locator_column = *RDF::Redland::COREc::raptor_locator_column;
*raptor_locator_byte = *RDF::Redland::COREc::raptor_locator_byte;
*raptor_locator_file = *RDF::Redland::COREc::raptor_locator_file;
*raptor_locator_uri = *RDF::Redland::COREc::raptor_locator_uri;
*librdf_internal_test_error = *RDF::Redland::COREc::librdf_internal_test_error;
*librdf_internal_test_warning = *RDF::Redland::COREc::librdf_internal_test_warning;
*librdf_perl_world_init = *RDF::Redland::COREc::librdf_perl_world_init;
*librdf_perl_world_finish = *RDF::Redland::COREc::librdf_perl_world_finish;

# ------- VARIABLE STUBS --------

package RDF::Redland::CORE;

*librdf_short_copyright_string = *RDF::Redland::COREc::librdf_short_copyright_string;
*librdf_copyright_string = *RDF::Redland::COREc::librdf_copyright_string;
*librdf_version_string = *RDF::Redland::COREc::librdf_version_string;
*librdf_version_major = *RDF::Redland::COREc::librdf_version_major;
*librdf_version_minor = *RDF::Redland::COREc::librdf_version_minor;
*librdf_version_release = *RDF::Redland::COREc::librdf_version_release;
*librdf_version_decimal = *RDF::Redland::COREc::librdf_version_decimal;
*raptor_version_string = *RDF::Redland::COREc::raptor_version_string;
*raptor_version_major = *RDF::Redland::COREc::raptor_version_major;
*raptor_version_minor = *RDF::Redland::COREc::raptor_version_minor;
*raptor_version_release = *RDF::Redland::COREc::raptor_version_release;
*raptor_version_decimal = *RDF::Redland::COREc::raptor_version_decimal;
*rasqal_version_string = *RDF::Redland::COREc::rasqal_version_string;
*rasqal_version_major = *RDF::Redland::COREc::rasqal_version_major;
*rasqal_version_minor = *RDF::Redland::COREc::rasqal_version_minor;
*rasqal_version_release = *RDF::Redland::COREc::rasqal_version_release;
*rasqal_version_decimal = *RDF::Redland::COREc::rasqal_version_decimal;
1;
