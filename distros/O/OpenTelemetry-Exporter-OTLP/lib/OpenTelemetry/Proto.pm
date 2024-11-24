package OpenTelemetry::Proto;
# ABSTRACT: The protobuf definitions for the OpenTelemetry Protocol

our $VERSION = '0.018';

use experimental 'signatures';

use File::Share 'dist_dir';
use Path::Tiny 'path';
use Google::ProtocolBuffers::Dynamic;
use Feature::Compat::Try;

my $g = Google::ProtocolBuffers::Dynamic->new('proto');

my $share = do {
    try { dist_dir 'OpenTelemetry-Exporter-OTLP' }
    catch($e) { 'share' }
};

# Generated with
#
#     find . -name "*.proto" | while read proto; do
#        protoc --experimental_allow_proto3_optional -Iproto -o "$( echo ${proto%%.proto}.pb | sed -re 's/^\.\/proto/share/' )" $proto;
#     done
#
# The order of the list below is important! They are compiled
# in order because later ones depend on earlier ones.
for my $proto (qw(
    opentelemetry/proto/common/v1/common.pb
    opentelemetry/proto/resource/v1/resource.pb
    opentelemetry/proto/trace/v1/trace.pb
    opentelemetry/proto/metrics/v1/metrics.pb
    opentelemetry/proto/logs/v1/logs.pb

    opentelemetry/proto/collector/logs/v1/logs_service.pb
    opentelemetry/proto/collector/metrics/v1/metrics_service.pb
    opentelemetry/proto/collector/trace/v1/trace_service.pb
)) {
    $g->load_serialized_string( path("$share/$proto")->slurp );

    my @parts = split '/', $proto;
    pop @parts;

    $g->map({
        package => join('.', @parts ),
        prefix  => join( '::', map ucfirst, @parts ) =~ s/^Opente/OpenTe/r,
    });
}

# FIXME: This should probably be in a different distribution
#
# Generated with
#
#    cd share/google/rpc
#    wget https://raw.githubusercontent.com/googleapis/googleapis/6a8c7914d1b79bd832b5157a09a9332e8cbd16d4/google/rpc/status.proto
#    protoc -o status.pb status.proto
#    rm status.proto
#
$g->load_serialized_string( path("$share/google/rpc/status.pb")->slurp );
$g->map({
    package => 'google.rpc',
    prefix  => 'OTel::Google::RPC',
});

1;
