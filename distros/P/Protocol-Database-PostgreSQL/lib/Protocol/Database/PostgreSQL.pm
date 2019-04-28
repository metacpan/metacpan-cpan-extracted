package Protocol::Database::PostgreSQL;
# ABSTRACT: PostgreSQL wire protocol implementation
use strict;
use warnings;

our $VERSION = '1.002';

=head1 NAME

Protocol::Database::PostgreSQL - support for the PostgreSQL wire protocol

=head1 SYNOPSIS

 use strict;
 use warnings;
 use mro;
 package Example::PostgreSQL::Client;

 sub new { bless { @_[1..$#_] }, $_[0] }

 sub protocol {
  my ($self) = @_;
  $self->{protocol} //= Protocol::Database::PostgresQL->new(
   outgoing => $self->outgoing,
  )
 }
 # Any received packets will arrive here
 sub incoming { shift->{incoming} //= Ryu::Source->new }
 # Anything we want to send goes here
 sub outgoing { shift->{outgoing} //= Ryu::Source->new }

 ...
 # We raise events on our incoming source in this example -
 # if you prefer to handle each message as it's extracted you
 # could add that directly in the loop
 $self->incoming
   ->switch_str(
    sub { $_->type },
    authentication_request => sub { ... },
    sub { warn 'unknown message - ' . $_->type }
   );
 # When there's something to write, we'll get an event here
 $self->outgoing
      ->each(sub { $sock->write($_) });
 while(1) {
  $sock->read(my $buf, 1_000_000);
  while(my $msg = $self->protocol->extract_message(\$buf)) {
   $self->incoming->emit($msg);
  }
 }

=head1 DESCRIPTION

Provides protocol-level support for PostgreSQL 7.4+, as defined in L<http://www.postgresql.org/docs/current/static/protocol.html>.

=head2 How do I use this?

The short answer: don't.

Use L<Database::Async::Engine::PostgreSQL> instead, unless you're writing a driver for talking to PostgreSQL (or compatible) systems.

This distribution provides the abstract protocol handling, meaning that it understands the packets that make up the PostgreSQL
communication protocol, but it does B<not> attempt to send or receive those packets itself. You need to provide the transport layer
(typically this would involve TCP or Unix sockets).

=head2 Connection states

Possible states:

=over 4

=item * B<Unconnected> - we have a valid instantiated PostgreSQL object, but no connection yet.

=item * B<Connected> - transport layer has made a connection for us

=item * B<AuthRequested> - the server has challenged us to identify

=item * B<Authenticated> - we have successfully identified with the server

=item * B<Idle> - session is active and ready for commands

=item * B<Parsing> - a statement has been passed to the server for parsing

=item * B<Describing> - the indicated statement is being described, called after the transport layer has sent the Describe request

=item * B<Binding> - parameters for a given query have been transmitted

=item * B<Executing> - we have sent a request to execute

=item * B<ShuttingDown> - terminate request sent

=item * B<CopyIn> - the server is expecting data for a COPY command

=back

=begin HTML

<p><img src="http://tickit.perlsite.co.uk/cpan-screenshot/protocol-postgresql-states.png" alt="PostgreSQL connection states" width="388" height="827"></p>

=end HTML

=head2 Message types

The L<Protocol::Database::Backend/type> for incoming messages can currently include the following:

=over 4

=item * C<send_request> - Called each time there is a new message to be sent to the other side of the connection.

=item * C<authenticated> - Called when authentication is complete

=item * C<copy_data> - we have received data from an ongoing COPY request

=item * C<copy_complete> - the active COPY request has completed

=back

For the client, the following additional callbacks are available:

=over 4

=item * C<request_ready> - the server is ready for the next request

=item * C<bind_complete> - a Bind request has completed

=item * C<close_complete> - the Close request has completed

=item * C<command_complete> - the requested command has finished, this will typically be followed by an on_request_ready event

=item * C<copy_in_response> - indicates that the server is ready to receive COPY data

=item * C<copy_out_response> - indicates that the server is ready to send COPY data

=item * C<copy_both_response> - indicates that the server is ready to exchange COPY data (for replication)

=item * C<data_row> - data from the current query

=item * C<empty_query> - special-case response when sent an empty query, can be used for 'ping'. Typically followed by on_request_ready

=item * C<error> - server has raised an error

=item * C<function_call_result> - results from a function call

=item * C<no_data> - indicate that a query returned no data, typically followed by on_request_ready

=item * C<notice> - server has sent us a notice

=item * C<notification> - server has sent us a NOTIFY

=item * C<parameter_description> - parameters are being described

=item * C<parameter_status> - parameter status...

=item * C<parse_complete> - parsing is done

=item * C<portal_suspended> - the portal has been suspended, probably hit the row limit

=item * C<ready_for_query> - we're ready for queries

=item * C<row_description> - descriptive information about the rows we're likely to be seeing shortly

=back

And there are also these potential events back from the server:

=over 4

=item * C<copy_fail> - the frontend is indicating that the copy has failed

=item * C<describe> - request for something to be described

=item * C<execute> - request execution of a given portal

=item * C<flush> - request flush

=item * C<function_call> - request execution of a given function

=item * C<parse> - request to parse something

=item * C<password> - password information

=item * C<query> - simple query request

=item * C<ssl_request> - we have an SSL request

=item * C<startup_message> - we have an SSL request

=item * C<sync> - sync request

=item * C<terminate> - termination request

=back

=cut

no indirect;

use Digest::MD5 ();
use Time::HiRes ();
use POSIX qw(strftime);

use Log::Any qw($log);
use Ryu;
use Future;
use Sub::Identify;

use Protocol::Database::PostgreSQL::Backend::AuthenticationRequest;
use Protocol::Database::PostgreSQL::Backend::BackendKeyData;
use Protocol::Database::PostgreSQL::Backend::BindComplete;
use Protocol::Database::PostgreSQL::Backend::CloseComplete;
use Protocol::Database::PostgreSQL::Backend::CommandComplete;
use Protocol::Database::PostgreSQL::Backend::CopyData;
use Protocol::Database::PostgreSQL::Backend::CopyDone;
use Protocol::Database::PostgreSQL::Backend::CopyInResponse;
use Protocol::Database::PostgreSQL::Backend::CopyOutResponse;
use Protocol::Database::PostgreSQL::Backend::CopyBothResponse;
use Protocol::Database::PostgreSQL::Backend::DataRow;
use Protocol::Database::PostgreSQL::Backend::EmptyQueryResponse;
use Protocol::Database::PostgreSQL::Backend::ErrorResponse;
use Protocol::Database::PostgreSQL::Backend::FunctionCallResponse;
use Protocol::Database::PostgreSQL::Backend::NoData;
use Protocol::Database::PostgreSQL::Backend::NoticeResponse;
use Protocol::Database::PostgreSQL::Backend::NotificationResponse;
use Protocol::Database::PostgreSQL::Backend::ParameterDescription;
use Protocol::Database::PostgreSQL::Backend::ParameterStatus;
use Protocol::Database::PostgreSQL::Backend::ParseComplete;
use Protocol::Database::PostgreSQL::Backend::PortalSuspended;
use Protocol::Database::PostgreSQL::Backend::ReadyForQuery;
use Protocol::Database::PostgreSQL::Backend::RowDescription;

# Currently v3.0, which is used in PostgreSQL 7.4+
use constant PROTOCOL_VERSION   => 0x00030000;

# Types of authentication response
our %AUTH_TYPE = (
    0   => 'AuthenticationOk',
    2   => 'AuthenticationKerberosV5',
    3   => 'AuthenticationCleartextPassword',
    5   => 'AuthenticationMD5Password',
    6   => 'AuthenticationSCMCredential',
    7   => 'AuthenticationGSS',
    8   => 'AuthenticationGSSContinue',
    9   => 'AuthenticationSSPI',
);

# The terms "backend" and "frontend" used in the documentation here reflect
# the meanings assigned in the official PostgreSQL manual:
# * frontend - the client connecting to the database server
# * backend - the database server process

# Transaction states the backend can be in
our %BACKEND_STATE = (
    I   => 'idle',
    T   => 'transaction',
    E   => 'error'
);

# used for error and notice responses
our %NOTICE_CODE = (
    S   => 'severity',
    V   => 'severity',
    C   => 'code',
    M   => 'message',
    D   => 'detail',
    H   => 'hint',
    P   => 'position',
    p   => 'internal_position',
    q   => 'internal_query',
    W   => 'where',
    F   => 'file',
    L   => 'line',
    R   => 'routine'
);

# Mapping from name to backend message code (single byte)
our %MESSAGE_TYPE_BACKEND = (
    AuthenticationRequest => 'R',
    BackendKeyData        => 'K',
    BindComplete          => '2',
    CloseComplete         => '3',
    CommandComplete       => 'C',
    CopyData              => 'd',
    CopyDone              => 'c',
    CopyInResponse        => 'G',
    CopyOutResponse       => 'H',
    CopyBothResponse      => 'W',
    DataRow               => 'D',
    EmptyQueryResponse    => 'I',
    ErrorResponse         => 'E',
    FunctionCallResponse  => 'V',
    NoData                => 'n',
    NoticeResponse        => 'N',
    NotificationResponse  => 'A',
    ParameterDescription  => 't',
    ParameterStatus       => 'S',
    ParseComplete         => '1',
    PortalSuspended       => 's',
    ReadyForQuery         => 'Z',
    RowDescription        => 'T',
);
our %BACKEND_MESSAGE_CODE = reverse %MESSAGE_TYPE_BACKEND;

# Mapping from name to frontend message code (single byte)
our %MESSAGE_TYPE_FRONTEND = (
    Bind            => 'B',
    Close           => 'C',
    CopyData        => 'd',
    CopyDone        => 'c',
    CopyFail        => 'f',
    Describe        => 'D',
    Execute         => 'E',
    Flush           => 'H',
    FunctionCall    => 'F',
    Parse           => 'P',
    PasswordMessage => 'p',
    Query           => 'Q',
# Both of these are handled separately, and for legacy reasons they don't
# have a byte prefix for the message code
#   SSLRequest      => '',
#   StartupMessage  => '',
    Sync            => 'S',
    Terminate       => 'X',
);
our %FRONTEND_MESSAGE_CODE = reverse %MESSAGE_TYPE_FRONTEND;

# Defined message handlers for outgoing frontend messages
our %FRONTEND_MESSAGE_BUILDER;

# from https://www.postgresql.org/docs/current/static/errcodes-appendix.html
our %ERROR_CODE = (
    '00000' => 'successful_completion',
    '01000' => 'warning',
    '01003' => 'null_value_eliminated_in_set_function',
    '01004' => 'string_data_right_truncation',
    '01006' => 'privilege_not_revoked',
    '01007' => 'privilege_not_granted',
    '01008' => 'implicit_zero_bit_padding',
    '0100C' => 'dynamic_result_sets_returned',
    '01P01' => 'deprecated_feature',
    '02000' => 'no_data',
    '02001' => 'no_additional_dynamic_result_sets_returned',
    '03000' => 'sql_statement_not_yet_complete',
    '08000' => 'connection_exception',
    '08001' => 'sqlclient_unable_to_establish_sqlconnection',
    '08003' => 'connection_does_not_exist',
    '08004' => 'sqlserver_rejected_establishment_of_sqlconnection',
    '08006' => 'connection_failure',
    '08007' => 'transaction_resolution_unknown',
    '08P01' => 'protocol_violation',
    '09000' => 'triggered_action_exception',
    '0A000' => 'feature_not_supported',
    '0B000' => 'invalid_transaction_initiation',
    '0F000' => 'locator_exception',
    '0F001' => 'invalid_locator_specification',
    '0L000' => 'invalid_grantor',
    '0LP01' => 'invalid_grant_operation',
    '0P000' => 'invalid_role_specification',
    '0Z000' => 'diagnostics_exception',
    '0Z002' => 'stacked_diagnostics_accessed_without_active_handler',
    '20000' => 'case_not_found',
    '21000' => 'cardinality_violation',
    '22000' => 'data_exception',
    '22001' => 'string_data_right_truncation',
    '22002' => 'null_value_no_indicator_parameter',
    '22003' => 'numeric_value_out_of_range',
    '22004' => 'null_value_not_allowed',
    '22005' => 'error_in_assignment',
    '22007' => 'invalid_datetime_format',
    '22008' => 'datetime_field_overflow',
    '22009' => 'invalid_time_zone_displacement_value',
    '2200B' => 'escape_character_conflict',
    '2200C' => 'invalid_use_of_escape_character',
    '2200D' => 'invalid_escape_octet',
    '2200F' => 'zero_length_character_string',
    '2200G' => 'most_specific_type_mismatch',
    '2200H' => 'sequence_generator_limit_exceeded',
    '2200L' => 'not_an_xml_document',
    '2200M' => 'invalid_xml_document',
    '2200N' => 'invalid_xml_content',
    '2200S' => 'invalid_xml_comment',
    '2200T' => 'invalid_xml_processing_instruction',
    '22010' => 'invalid_indicator_parameter_value',
    '22011' => 'substring_error',
    '22012' => 'division_by_zero',
    '22013' => 'invalid_preceding_or_following_size',
    '22014' => 'invalid_argument_for_ntile_function',
    '22015' => 'interval_field_overflow',
    '22016' => 'invalid_argument_for_nth_value_function',
    '22018' => 'invalid_character_value_for_cast',
    '22019' => 'invalid_escape_character',
    '2201B' => 'invalid_regular_expression',
    '2201E' => 'invalid_argument_for_logarithm',
    '2201F' => 'invalid_argument_for_power_function',
    '2201G' => 'invalid_argument_for_width_bucket_function',
    '2201W' => 'invalid_row_count_in_limit_clause',
    '2201X' => 'invalid_row_count_in_result_offset_clause',
    '22021' => 'character_not_in_repertoire',
    '22022' => 'indicator_overflow',
    '22023' => 'invalid_parameter_value',
    '22024' => 'unterminated_c_string',
    '22025' => 'invalid_escape_sequence',
    '22026' => 'string_data_length_mismatch',
    '22027' => 'trim_error',
    '2202E' => 'array_subscript_error',
    '2202G' => 'invalid_tablesample_repeat',
    '2202H' => 'invalid_tablesample_argument',
    '22P01' => 'floating_point_exception',
    '22P02' => 'invalid_text_representation',
    '22P03' => 'invalid_binary_representation',
    '22P04' => 'bad_copy_file_format',
    '22P05' => 'untranslatable_character',
    '22P06' => 'nonstandard_use_of_escape_character',
    '23000' => 'integrity_constraint_violation',
    '23001' => 'restrict_violation',
    '23502' => 'not_null_violation',
    '23503' => 'foreign_key_violation',
    '23505' => 'unique_violation',
    '23514' => 'check_violation',
    '23P01' => 'exclusion_violation',
    '24000' => 'invalid_cursor_state',
    '25000' => 'invalid_transaction_state',
    '25001' => 'active_sql_transaction',
    '25002' => 'branch_transaction_already_active',
    '25003' => 'inappropriate_access_mode_for_branch_transaction',
    '25004' => 'inappropriate_isolation_level_for_branch_transaction',
    '25005' => 'no_active_sql_transaction_for_branch_transaction',
    '25006' => 'read_only_sql_transaction',
    '25007' => 'schema_and_data_statement_mixing_not_supported',
    '25008' => 'held_cursor_requires_same_isolation_level',
    '25P01' => 'no_active_sql_transaction',
    '25P02' => 'in_failed_sql_transaction',
    '25P03' => 'idle_in_transaction_session_timeout',
    '26000' => 'invalid_sql_statement_name',
    '27000' => 'triggered_data_change_violation',
    '28000' => 'invalid_authorization_specification',
    '28P01' => 'invalid_password',
    '2B000' => 'dependent_privilege_descriptors_still_exist',
    '2BP01' => 'dependent_objects_still_exist',
    '2D000' => 'invalid_transaction_termination',
    '2F000' => 'sql_routine_exception',
    '2F002' => 'modifying_sql_data_not_permitted',
    '2F003' => 'prohibited_sql_statement_attempted',
    '2F004' => 'reading_sql_data_not_permitted',
    '2F005' => 'function_executed_no_return_statement',
    '34000' => 'invalid_cursor_name',
    '38000' => 'external_routine_exception',
    '38001' => 'containing_sql_not_permitted',
    '38002' => 'modifying_sql_data_not_permitted',
    '38003' => 'prohibited_sql_statement_attempted',
    '38004' => 'reading_sql_data_not_permitted',
    '39000' => 'external_routine_invocation_exception',
    '39001' => 'invalid_sqlstate_returned',
    '39004' => 'null_value_not_allowed',
    '39P01' => 'trigger_protocol_violated',
    '39P02' => 'srf_protocol_violated',
    '39P03' => 'event_trigger_protocol_violated',
    '3B000' => 'savepoint_exception',
    '3B001' => 'invalid_savepoint_specification',
    '3D000' => 'invalid_catalog_name',
    '3F000' => 'invalid_schema_name',
    '40000' => 'transaction_rollback',
    '40001' => 'serialization_failure',
    '40002' => 'transaction_integrity_constraint_violation',
    '40003' => 'statement_completion_unknown',
    '40P01' => 'deadlock_detected',
    '42000' => 'syntax_error_or_access_rule_violation',
    '42501' => 'insufficient_privilege',
    '42601' => 'syntax_error',
    '42602' => 'invalid_name',
    '42611' => 'invalid_column_definition',
    '42622' => 'name_too_long',
    '42701' => 'duplicate_column',
    '42702' => 'ambiguous_column',
    '42703' => 'undefined_column',
    '42704' => 'undefined_object',
    '42710' => 'duplicate_object',
    '42712' => 'duplicate_alias',
    '42723' => 'duplicate_function',
    '42725' => 'ambiguous_function',
    '42803' => 'grouping_error',
    '42804' => 'datatype_mismatch',
    '42809' => 'wrong_object_type',
    '42830' => 'invalid_foreign_key',
    '42846' => 'cannot_coerce',
    '42883' => 'undefined_function',
    '428C9' => 'generated_always',
    '42939' => 'reserved_name',
    '42P01' => 'undefined_table',
    '42P02' => 'undefined_parameter',
    '42P03' => 'duplicate_cursor',
    '42P04' => 'duplicate_database',
    '42P05' => 'duplicate_prepared_statement',
    '42P06' => 'duplicate_schema',
    '42P07' => 'duplicate_table',
    '42P08' => 'ambiguous_parameter',
    '42P09' => 'ambiguous_alias',
    '42P10' => 'invalid_column_reference',
    '42P11' => 'invalid_cursor_definition',
    '42P12' => 'invalid_database_definition',
    '42P13' => 'invalid_function_definition',
    '42P14' => 'invalid_prepared_statement_definition',
    '42P15' => 'invalid_schema_definition',
    '42P16' => 'invalid_table_definition',
    '42P17' => 'invalid_object_definition',
    '42P18' => 'indeterminate_datatype',
    '42P19' => 'invalid_recursion',
    '42P20' => 'windowing_error',
    '42P21' => 'collation_mismatch',
    '42P22' => 'indeterminate_collation',
    '44000' => 'with_check_option_violation',
    '53000' => 'insufficient_resources',
    '53100' => 'disk_full',
    '53200' => 'out_of_memory',
    '53300' => 'too_many_connections',
    '53400' => 'configuration_limit_exceeded',
    '54000' => 'program_limit_exceeded',
    '54001' => 'statement_too_complex',
    '54011' => 'too_many_columns',
    '54023' => 'too_many_arguments',
    '55000' => 'object_not_in_prerequisite_state',
    '55006' => 'object_in_use',
    '55P02' => 'cant_change_runtime_param',
    '55P03' => 'lock_not_available',
    '57000' => 'operator_intervention',
    '57014' => 'query_canceled',
    '57P01' => 'admin_shutdown',
    '57P02' => 'crash_shutdown',
    '57P03' => 'cannot_connect_now',
    '57P04' => 'database_dropped',
    '58000' => 'system_error',
    '58030' => 'io_error',
    '58P01' => 'undefined_file',
    '58P02' => 'duplicate_file',
    '72000' => 'snapshot_too_old',
    'F0000' => 'config_file_error',
    'F0001' => 'lock_file_exists',
    'HV000' => 'fdw_error',
    'HV001' => 'fdw_out_of_memory',
    'HV002' => 'fdw_dynamic_parameter_value_needed',
    'HV004' => 'fdw_invalid_data_type',
    'HV005' => 'fdw_column_name_not_found',
    'HV006' => 'fdw_invalid_data_type_descriptors',
    'HV007' => 'fdw_invalid_column_name',
    'HV008' => 'fdw_invalid_column_number',
    'HV009' => 'fdw_invalid_use_of_null_pointer',
    'HV00A' => 'fdw_invalid_string_format',
    'HV00B' => 'fdw_invalid_handle',
    'HV00C' => 'fdw_invalid_option_index',
    'HV00D' => 'fdw_invalid_option_name',
    'HV00J' => 'fdw_option_name_not_found',
    'HV00K' => 'fdw_reply_handle',
    'HV00L' => 'fdw_unable_to_create_execution',
    'HV00M' => 'fdw_unable_to_create_reply',
    'HV00N' => 'fdw_unable_to_establish_connection',
    'HV00P' => 'fdw_no_schemas',
    'HV00Q' => 'fdw_schema_not_found',
    'HV00R' => 'fdw_table_not_found',
    'HV010' => 'fdw_function_sequence_error',
    'HV014' => 'fdw_too_many_handles',
    'HV021' => 'fdw_inconsistent_descriptor_information',
    'HV024' => 'fdw_invalid_attribute_value',
    'HV090' => 'fdw_invalid_string_length_or_buffer_length',
    'HV091' => 'fdw_invalid_descriptor_field_identifier',
    'P0000' => 'plpgsql_error',
    'P0001' => 'raise_exception',
    'P0002' => 'no_data_found',
    'P0003' => 'too_many_rows',
    'P0004' => 'assert_failure',
    'XX000' => 'internal_error',
    'XX001' => 'data_corrupted',
    'XX002' => 'index_corrupted',
);

=head1 METHODS

=cut

=head2 new

Instantiate a new object. Blesses an empty hashref and calls L</configure>, subclasses can bypass this entirely
and just call L</configure> directly after instantiation.

=cut

sub new {
    my $self = bless {
    }, shift;
    $self->configure(@_);
    return $self;
}

=head2 configure

Does the real preparation for the object.

=cut

sub configure {
    my ($self, %args) = @_;

    $self->{$_} = 0 for grep !exists $self->{$_}, qw(authenticated message_count);
    $self->{wait_for_startup} = 1 unless exists $self->{wait_for_startup};
    $self->{$_} = delete $args{$_} for grep exists $args{$_}, qw(user pass database replication outgoing);

    return %args;
}

=head2 frontend_bind

Bind parameters to an existing prepared statement.

=cut

sub frontend_bind {
    my ($self, %args) = @_;

    $args{param} ||= [];
    my $param = '';
    my $count = 0 + @{$args{param}};
    for my $p (@{$args{param}}) {
        if(!defined $p) {
            $param .= pack 'N1', 0xFFFFFFFF;
        } else {
            $param .= pack 'N/a*', $p;
        }
    }
    my $msg = pack('Z*Z*n1n1a*n1',
        $args{portal} // '',
        $args{statement} // '',
        0,      # Parameter types
        $count, # Number of bound parameters
        $param, # Actual parameter values
        0       # Number of result column format definitions (0=use default text format)
    );
    push @{$self->{pending_bind}}, $args{sth} || ();
    $log->tracef(sub {
        join('',
            "Bind",
            defined($args{portal}) ? " for portal [" . $args{portal} . "]" : '',
            defined($args{statement}) ? " for statement [" . $args{statement} . "]" : '',
            " with $count parameter(s): ",
            join(',', @{$args{param}})
        )
    }) if $log->is_debug;
    return $self->build_message(
        type    => 'Bind',
        data    => $msg,
    );
}

=head2 frontend_copy_data



=cut

sub frontend_copy_data {
    my $self = shift;
    my %args = @_;
    return $self->build_message(
        type    => 'CopyData',
        data    => pack('a*', $args{data})
    );
}

=head2 frontend_close



=cut

sub frontend_close {
    my ($self, %args) = @_;

    my $msg = pack('a1Z*',
        exists $args{portal} ? 'P' : 'S', # close a portal or a statement
          defined($args{statement})
        ? $args{statement}
        :  (defined($args{portal})
          ? $args{portal}
          : ''
        )
    );
    return $self->build_message(
        type    => 'Close',
        data    => $msg,
    );
}

=head2 frontend_copy_done



=cut

sub frontend_copy_done {
    my $self = shift;
    return $self->build_message(
        type    => 'CopyDone',
        data    => '',
    );
}

=head2 frontend_describe

Describe expected SQL results

=cut

sub frontend_describe {
    my ($self, %args) = @_;

    my $msg = pack('a1Z*', exists $args{portal} ? 'P' : 'S', defined($args{statement}) ? $args{statement} : (defined($args{portal}) ? $args{portal} : ''));
    return $self->build_message(
        type    => 'Describe',
        data    => $msg,
    );
}

=head2 frontend_execute

Execute either a named or anonymous portal (prepared statement with bind vars)

=cut

sub frontend_execute {
    my ($self, %args) = @_;

    $args{portal} //= '';
    my $msg = pack('Z*N1', $args{portal}, $args{limit} || 0);
    $log->tracef(
        "Executing portal '%s' %s",
        $args{portal},
        $args{limit} ? " with limit " . $args{limit} : " with no limit"
    ) if $log->is_debug;
    return $self->build_message(
        type    => 'Execute',
        data    => $msg,
    );
}

=head2 frontend_parse

Parse SQL for a prepared statement

=cut

sub frontend_parse {
    my ($self, %args) = @_;
    die "No SQL provided" unless defined $args{sql};

    my $msg = pack('Z*Z*n1', (defined($args{statement}) ? $args{statement} : ''), $args{sql}, 0);
    return $self->build_message(
        type    => 'Parse',
        data    => $msg,
    );
}

=head2 frontend_password_message

Password data, possibly encrypted depending on what the server specified.

=cut

sub frontend_password_message {
    my ($self, %args) = @_;

    my $pass = $args{password} // die 'no password provided';
    if($args{password_type} eq 'md5') {
        # md5hex of password . username,
        # then md5hex result with salt appended
        # then stick 'md5' at the front.
        $pass = 'md5' . Digest::MD5::md5_hex(
            Digest::MD5::md5_hex($pass . $args{user})
            . $args{password_salt}
        );
    }

    # Yes, protocol requires zero-terminated string format even
    # if we have a binary password value.
    return $self->build_message(
        type    => 'PasswordMessage',
        data    => pack('Z*', $pass)
    );
}

=head2 frontend_query

Simple query

=cut

sub frontend_query {
    my ($self, %args) = @_;
    return $self->build_message(
        type    => 'Query',
        data    => pack('Z*', $args{sql})
    );
}

=head2 frontend_startup_message

Initial mesage informing the server which database and user we want

=cut

sub frontend_startup_message {
    my ($self, %args) = @_;
    die "Not first message" unless $self->is_first_message;

    if($args{replication}) {
        $args{replication} = 'database';
        $args{database} = 'postgres';
    } else {
        delete $args{replication};
    }
    $log->tracef("Startup with %s", \%args);

    my $parameters = join('', map { pack('Z*', $_) } map { $_, $args{$_} } grep { exists $args{$_} } qw(user database options application_name replication));
    $parameters .= "\0";

    return $self->build_message(
        type    => undef,
        data    => pack('N*', PROTOCOL_VERSION) . $parameters
    );
}

sub send_startup_request {
    my ($self, %args) = @_;
    $self->outgoing->emit($self->frontend_startup_message(%args));
}

=head2 frontend_sync

Synchonise after a prepared statement has finished execution.

=cut

sub frontend_sync {
    my $self = shift;
    return $self->build_message(
        type    => 'Sync',
        data    => '',
    );
}

=head2 frontend_terminate



=cut

sub frontend_terminate {
    my $self = shift;
    return $self->build_message(
        type    => 'Terminate',
        data    => '',
    );
}

=head2 is_authenticated

Returns true if we are authenticated (and can start sending real data).

=cut

sub is_authenticated { $_[0]->{authenticated} ? 1 : 0 }

=head2 is_first_message

Returns true if this is the first message, as per L<http://developer.postgresql.org/pgdocs/postgres/protocol-overview.html>:

 "For historical reasons, the very first message sent by the client (the startup message)
  has no initial message-type byte."

=cut

sub is_first_message { $_[0]->{message_count} < 1 }

=head2 send_message

Send a message.

=cut

sub send_message {
    my ($self, @args) = @_;

    # Clear the ready-to-send flag since we're about to throw a message over to the
    # server and we don't want any others getting in the way.
    $self->{is_ready} = 0;

    $log->tracef("Will send message with %s", \@args);
    die "Empty message?" unless defined(my $msg = $self->message(@args));

    $log->tracef(
        "send data: [%v02x] %s (%s)",
        $msg,
        (($self->is_first_message ? "startup packet" : $FRONTEND_MESSAGE_CODE{substr($msg, 0, 1)}) || 'unknown message'),
        join('', '', map { (my $txt = defined($_) ? $_ : '') =~ tr/ []"'!#$%*&=:;A-Za-z0-9,()_ -/./c; $txt } split //, $msg)
    ) if $log->is_debug;
    $self->outgoing->emit($msg);
    return $self;
}

sub outgoing { shift->{outgoing} // die 'no outgoing source' }

=head2 method_for_frontend_type

Returns the method name for the given frontend type.

=cut

sub method_for_frontend_type {
    my ($self, $type) = @_;
    my $method = 'frontend' . $type;
    $method =~ s/([A-Z])/'_' . lc $1/ge;
    $method
}

=head2 is_known_frontend_message_type

Returns true if the given frontend type is one that we know how to handle.

=cut

sub is_known_frontend_message_type {
    my ($self, $type) = @_;
    return 1 if exists $FRONTEND_MESSAGE_BUILDER{$type};
    return 1 if $self->can($self->method_for_frontend_type($type));
    return 0;
}

=head2 message

Creates a new message of the given type.

=cut

sub message {
    my ($self, $type, @args) = @_;
    die "Message $type unknown" unless $self->is_known_frontend_message_type($type);

    my $method = ($FRONTEND_MESSAGE_BUILDER{$type} || $self->can($self->method_for_frontend_type($type)) || die 'no method for ' . $type);
    $log->tracef("Method is %s", Sub::Identify::sub_name $method);
    my $msg = $self->$method(@args);
    ++$self->{message_count};
    return $msg;
}

=head2 handle_message

Handle an incoming message from the server.

=cut

sub handle_message {
    my ($self, $msg) = @_;

    # Extract code and identify which message handler to use
    my $type = do {
        my $code = substr $msg, 0, 1;
        my $type = $BACKEND_MESSAGE_CODE{$code}
            or die 'unknown backend message code ' . $code;
        $log->tracef('Handle message of type %s (code %s)', $type, $code);
        $type
    };

    # Clear the ready-to-send flag until we've processed this
    $self->{is_ready} = 0;
    return ('Protocol::Database::PostgreSQL::Backend::' . $type)->new_from_message($msg);
}

sub ssl_request {
    my ($self) = @_;
    # Magic SSL code, see https://www.postgresql.org/docs/current/protocol-message-formats.html
    my $data = pack("n1n1", 1234, 5679);
    return pack 'Na*', 8, $data;
}

=head2 message_length

Returns the length of the given message.

=cut

sub message_length {
    my ($self, $msg) = @_;
    return undef unless length($msg) >= 5;
    (undef, my $len) = unpack('C1N1', substr($msg, 0, 5));
    return $len;
}

=head2 simple_query

Send a simple query to the server - only supports plain queries (no bind parameters).

=cut

sub simple_query {
    my ($self, $sql) = @_;

    $log->tracef("Running query [%s]", $sql);
    $self->send_message('Query', sql => $sql);
    return $self;
}

=head2 copy_data

Send copy data to the server.

=cut

sub copy_data {
    my $self = shift;
    my $data = shift;
    die "Invalid backend state" if $self->backend_state eq 'error';

    $self->send_message('CopyData', data => $data);
    return $self;
}

=head2 copy_done

Indicate that the COPY data from the client is complete.

=cut

sub copy_done {
    my $self = shift;
    my $data = shift;
    die "Invalid backend state" if $self->backend_state eq 'error';

    $self->send_message('CopyDone');
    return $self;
}

=head2 backend_state

Accessor for current backend state.

=cut

sub backend_state {
    my $self = shift;
    if(@_) {
        my $state = shift;
        die "bad state code" unless grep { $state eq $_ } qw(idle transaction error);

        $self->{backend_state} = $state;
        return $self;
    }
    return $self->{backend_state};
}

=head2 is_ready

Returns true if we're ready to send more data to the server.

=cut

sub is_ready {
    my $self = shift;
    if(@_) {
        $self->{is_ready} = shift;
        return $self;
    }
    return 0 if $self->{wait_for_startup};
    return $self->{is_ready};
}

=head2 send_copy_data

Send COPY data to the server. Takes an arrayref and replaces any reserved characters with quoted versions.

=cut

{
    my %_charmap = (
        "\\"   => "\\\\",
        "\x08" => "\\b",
        "\x09" => "\\t",
        "\x0A" => "\\r",
        "\x0C" => "\\f",
        "\x0D" => "\\n",
    );

    sub send_copy_data  {
        my ($self, $data) = @_;
        my $content = pack 'a*', (
            join("\t", map {
                defined($_)
                ? s/([\\\x08\x09\x0A\x0C\x0D])/$_charmap{$1}/ger
                : '\N'
            } @$data) . "\n"
        );

        $self->outgoing->emit(
            $MESSAGE_TYPE_FRONTEND{'CopyData'} . pack('N1', 4 + length $content) . $content
        );
        return $self;
    }
}

sub extract_message {
    my ($self, $buffref) = @_;
    # The smallest possible message is 5 bytes
    return undef unless length($$buffref) >= 5;
    # Don't start extracting until we know we have a full packet
    my ($code, $size) = unpack('C1N1', $$buffref);
    return undef unless length($$buffref) >= $size+1;
    return $self->handle_message(
        substr $$buffref, 0, $size+1, ''
    );
}

=head2 build_message

Construct a new message.

=cut

sub build_message {
    my $self = shift;
    my %args = @_;

    # Can be undef
    die "No type provided" unless exists $args{type};
    die "No data provided" unless exists $args{data};

    # Length includes the 4-byte length field, but not the type byte
    my $length = length($args{data}) + 4;
    return (defined($args{type}) ? $MESSAGE_TYPE_FRONTEND{$args{type}} : '') . pack('N1', $length) . $args{data};
}

sub state { $_[0]->{state} = $_[1] }

sub current_state { shift->{state} }

1;

__END__

=head1 SEE ALSO

Some PostgreSQL-related modules - plenty of things build on these so have a look at the relevant reverse deps if you're after something higher level:

=over 4

=item * L<DBD::Pg> - uses the official library and (unlike this module) provides full support for L<DBI>

=item * L<Pg::PQ> - another libpq wrapper

=item * L<Postgres> - quite an old (1998) libpq binding

=item * L<Pg> - slightly less old (2000) libpq binding

=item * L<DBD::PgPP> - provides another pure-Perl implemmentation, with the focus on DBI compatibility

=back

Other related database protocols:

=over 4

=item * L<Protocol::MySQL> - Oracle's popular database product

=item * L<Protocol::TDS> - the tabular data stream protocol, mainly of interest for SQL Server users

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

