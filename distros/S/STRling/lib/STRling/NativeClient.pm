package STRling::NativeAdapterError;

use 5.010;
use strict;
use warnings;
use overload '""' => sub { $_[0]->{message} }, fallback => 1;

# STRling-public-arity: new=3..4
sub new {
    my ($class, $kind, $message, $status) = @_;
    $message .= " (status $status)" if defined $status;
    return bless { kind => $kind, message => $message, status => $status }, $class;
}

package STRling::InteropProtocolError;

use 5.010;
use strict;
use warnings;
use overload '""' => sub { $_[0]->{message} }, fallback => 1;

# STRling-public-arity: new=2
sub new {
    my ($class, $response) = @_;
    my $error = $response->{error};
    return bless {
        code => $error->{code},
        path => $error->{path},
        operation => $response->{operation},
        message => "$error->{code} at $error->{path}",
    }, $class;
}

package STRling::NativeClient;

use 5.010;
use strict;
use warnings;
use B ();
use Config ();
use Cwd qw(abs_path);
use File::Spec ();
use STRling::StrictJSON ();

use constant INTEROP_PROTOCOL_VERSION => '1.0.0';
use constant NATIVE_ABI_VERSION => 1;
use constant MAX_INTEROP_REQUEST_BYTES => 10_485_760;
use constant MAX_INTEROP_RESPONSE_BYTES => 33_554_432;

# STRling-public-arity: load=2
sub load {
    my ($class, $library_path) = @_;
    die STRling::NativeAdapterError->new('native_load', 'native STRling library path must be absolute')
        unless defined($library_path) && File::Spec->file_name_is_absolute($library_path);
    my $normalized = abs_path($library_path);
    die STRling::NativeAdapterError->new('native_load', "native STRling library not found: $library_path")
        unless defined($normalized) && -f $normalized;

    eval { require FFI::Platypus; 1 }
        or die STRling::NativeAdapterError->new('native_load', 'FFI::Platypus is required');
    my $ffi = FFI::Platypus->new(api => 2);
    $ffi->lib($normalized);
    my ($abi, $execute, $free);
    eval {
        $abi = $ffi->function('strling_interop_abi_version_v1' => [] => 'uint32');
        $execute = $ffi->function('strling_interop_execute_v1' => ['opaque', 'size_t', 'opaque'] => 'uint32');
        $free = $ffi->function('strling_interop_owned_bytes_free_v1' => ['opaque'] => 'uint32');
        1;
    } or die STRling::NativeAdapterError->new('native_load', 'cannot load the complete strling.c-abi v1');
    my $actual = $abi->call();
    die STRling::NativeAdapterError->new('native_abi', 'expected strling.c-abi 1', $actual)
        unless $actual == NATIVE_ABI_VERSION;
    return bless {
        library_path => $normalized,
        ffi => $ffi,
        execute_fn => $execute,
        free_fn => $free,
        closed => 0,
        active_calls => 0,
    }, $class;
}

# STRling-public-arity: library_path=1
sub library_path { return $_[0]->{library_path}; }
# STRling-public-arity: is_closed=1
sub is_closed { return $_[0]->{closed} ? 1 : 0; }

# STRling-public-arity: execute=2
sub execute {
    my ($self, $request) = @_;
    my $encoded = eval { STRling::StrictJSON::encode($request) };
    die STRling::NativeAdapterError->new('transport', "interop request is not strict JSON: $@") if $@;
    die STRling::NativeAdapterError->new('transport', 'interop request exceeds ' . MAX_INTEROP_REQUEST_BYTES . ' bytes')
        if length($encoded) > MAX_INTEROP_REQUEST_BYTES;
    $self->_begin_call();
    my ($result, $error);
    eval { $result = $self->_execute_bytes($encoded); 1 } or $error = $@;
    $self->_end_call();
    die $error if $error;
    return $result;
}

# STRling-public-arity: describe=1
sub describe {
    my ($self) = @_;
    return $self->_completed_result($self->_envelope('describe', {}));
}

# STRling-public-arity: compile=2..3
sub compile {
    my ($self, $compile_request, $target_profile) = @_;
    my $payload = { compile_request => $compile_request };
    $payload->{target_profile} = $target_profile if defined $target_profile;
    return $self->_completed_result($self->_envelope('compile', $payload));
}

# STRling-public-arity: inspect_target_profile=2
sub inspect_target_profile {
    my ($self, $target_profile) = @_;
    return $self->_completed_result($self->_envelope('target_profile.inspect', { target_profile => $target_profile }));
}

# STRling-public-arity: simply_compile=2..3
sub simply_compile {
    my ($self, $builder_request, $target_profile) = @_;
    my $payload = { builder_request => $builder_request };
    $payload->{target_profile} = $target_profile if defined $target_profile;
    return $self->_completed_result($self->_envelope('simply.compile', $payload));
}

# STRling-public-arity: close=1
sub close {
    my ($self) = @_;
    return if $self->{closed};
    die STRling::NativeAdapterError->new('closed_client', 'cannot close native STRling client during an active call')
        if $self->{active_calls};
    $self->{closed} = 1;
    delete $self->{execute_fn};
    delete $self->{free_fn};
    delete $self->{ffi};
    return;
}

sub _begin_call {
    my ($self) = @_;
    die STRling::NativeAdapterError->new('closed_client', 'native STRling client is closed') if $self->{closed};
    ++$self->{active_calls};
}

sub _end_call { --$_[0]->{active_calls}; }

sub _execute_bytes {
    my ($self, $encoded) = @_;
    require FFI::Platypus::Buffer;
    require FFI::Platypus::Memory;
    my ($input, $input_length) = FFI::Platypus::Buffer::scalar_to_buffer($encoded);
    my $descriptor_size = $Config::Config{ptrsize} + $Config::Config{sizesize};
    my $output = FFI::Platypus::Memory::malloc($descriptor_size);
    FFI::Platypus::Memory::memset($output, 0, $descriptor_size);
    my ($result, $primary_error);
    eval {
        my $status = $self->{execute_fn}->call($input, $input_length, $output);
        die STRling::NativeAdapterError->new('native_abi', 'native STRling execution failed', $status) if $status != 0;
        my $descriptor = FFI::Platypus::Buffer::buffer_to_scalar($output, $descriptor_size);
        my $pointer_pack = $Config::Config{ptrsize} == 8 ? 'Q' : 'L';
        my $size_pack = $Config::Config{sizesize} == 8 ? 'Q' : 'L';
        my ($data, $length) = unpack("$pointer_pack $size_pack", $descriptor);
        die STRling::NativeAdapterError->new('transport', 'native STRling returned an invalid or oversized response')
            if !$data || !$length || $length > MAX_INTEROP_RESPONSE_BYTES;
        my $raw = FFI::Platypus::Buffer::buffer_to_scalar($data, $length);
        $result = $self->_decode_response($raw);
        1;
    } or $primary_error = $@;
    my $release_status = $self->{free_fn}->call($output);
    FFI::Platypus::Memory::free($output);
    die $primary_error if $primary_error;
    die STRling::NativeAdapterError->new('native_abi', 'native STRling response release failed', $release_status)
        if $release_status != 0;
    return $result;
}

sub _decode_response {
    my ($self, $raw) = @_;
    my $value = eval { STRling::StrictJSON::decode_object($raw) };
    die STRling::NativeAdapterError->new('transport', "native STRling response is not strict UTF-8 JSON: $@") if $@;
    die STRling::NativeAdapterError->new('transport', 'interop response has an unsupported version')
        unless defined($value->{interop_protocol_version}) && $value->{interop_protocol_version} eq INTEROP_PROTOCOL_VERSION;
    my $status = $value->{status};
    die STRling::NativeAdapterError->new('transport', 'interop response has an unsupported status')
        unless defined($status) && ($status eq 'completed' || $status eq 'error');
    die STRling::NativeAdapterError->new('transport', 'completed interop response has no result')
        if $status eq 'completed' && !exists($value->{result});
    if ($status eq 'error') {
        my $error = $value->{error};
        die STRling::NativeAdapterError->new('transport', 'failed interop response has no stable code and path')
            unless ref($error) eq 'HASH' && _is_json_string($error->{code}) && _is_json_string($error->{path});
    }
    return $value;
}

sub _is_json_string {
    my ($value) = @_;
    return 0 if !defined($value) || ref($value);
    return (B::svref_2object(\$value)->FLAGS & B::SVf_POK()) != 0;
}

sub _envelope {
    my ($self, $operation, $payload) = @_;
    return { interop_protocol_version => INTEROP_PROTOCOL_VERSION, operation => $operation, payload => $payload };
}

sub _completed_result {
    my ($self, $request) = @_;
    my $response = $self->execute($request);
    die STRling::InteropProtocolError->new($response) if $response->{status} eq 'error';
    return $response->{result};
}

1;
