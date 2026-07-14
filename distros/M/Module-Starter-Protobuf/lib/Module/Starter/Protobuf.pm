package Module::Starter::Protobuf;

use 5.008003;
use strict;
use warnings;
use parent qw(Module::Starter::Simple);

use Path::Tiny qw(path);
use Carp qw(croak);
use File::Spec;
use File::Basename qw(basename);
use File::Which qw(which);

our $VERSION = '0.01';

sub create_distro {
    my ($self, %args) = @_;

    # Read protobuf configuration from args, instance properties, or environment
    my $proto_files_str = $args{protos} || $self->{protos} || $ENV{PROTOBUF_FILES};
    my $import_path = $args{proto_import_path} || $args{import_path} 
                      || $self->{proto_import_path} || $self->{import_path} 
                      || $ENV{PROTOBUF_IMPORT_PATH} || '.';
    my $grpc_target = $args{grpc_target} || $self->{grpc_target} || $ENV{PROTOBUF_GRPC_TARGET} || 'localhost:50051';

    if ($proto_files_str) {
        $self->{_protobuf_files} = [ split /,/, $proto_files_str ];
        $self->{_protobuf_import_path} = $import_path;
        $self->{_protobuf_grpc_target} = $grpc_target;
    }

    return $self->SUPER::create_distro(%args);
}

# 2. Override create_modules to run protoc and generate the client wrappers
sub create_modules {
    my ($self, @modules) = @_;

    # First, let the base class create the standard module skeletons
    my @files = $self->SUPER::create_modules(@modules);

    # If no protobuf files are configured, behave like a standard starter
    return @files unless $self->{_protobuf_files};

    my $lib_dir = File::Spec->catdir($self->{basedir}, 'lib');

    for my $proto_file (@{$self->{_protobuf_files}}) {
        if (! -f $proto_file) {
            croak 'Protobuf file not found: ' . $proto_file;
        }

        # Execute protoc using native Perl compiler plugin from PATH or ENV
        my $plugin_path = $ENV{PROTOC_GEN_PERL_PB} || which('protoc-gen-perl-pb') || 'protoc-gen-perl-pb';
        
        my @cmd = ('protoc');
        push @cmd, '--plugin=protoc-gen-perl-pb=' . $plugin_path;
        push @cmd, '--perl-pb_out=' . $lib_dir;
        push @cmd, (
            '-I', $self->{_protobuf_import_path},
            '-I', '/usr/include',
            '-I', '/usr/local/include',
            $proto_file
        );
        
        # Print progress and flush stdout
        local $| = 1;
        print "Compiling $proto_file...\n";

        my $rc = system(@cmd);
        if ($rc != 0) {
            croak 'protoc execution failed with code ' . $rc . ' for ' . $proto_file;
        }
    }

    # B. Generate the high-level client wrappers for each requested module
    # For now, we assume the first module in the list is the primary client wrapper
    my $primary_module = $modules[0];
    my $primary_file = $files[0];
    my $abs_primary_file = File::Spec->catfile($self->{basedir}, $primary_file);

    if ($abs_primary_file && -f $abs_primary_file) {
        $self->_generate_client_wrapper($primary_module, $abs_primary_file);
    }

    return @files;
}

# 2.5 Override create_t to generate our dynamic integration tests
sub create_t {
    my ($self, @modules) = @_;

    # First, let the base class create the standard t/ directory and load tests
    my @files = $self->SUPER::create_t(@modules);

    # If we have parsed service metadata, generate our integration test!
    if ($self->{_protobuf_files} && $self->{_services_meta}) {
        my $primary_module = $modules[0];
        my $test_file = $self->_generate_service_test($primary_module);
        push @files, $test_file if $test_file;
        my $rest_test_file = $self->_generate_rest_test($primary_module);
        push @files, $rest_test_file if $rest_test_file;
    }

    return @files;
}

# Helper to parse protos and generate the high-level client wrapper class
sub _generate_client_wrapper {
    my ($self, $module_name, $file_path) = @_;

    my @methods;
    my $package_name = '';
    my $service_name = '';

    # Loop over and parse all proto files in the list!
    for my $proto_file (@{$self->{_protobuf_files}}) {
        my $proto_content = path($proto_file)->slurp_utf8();
        
        # Strip all single-line and multi-line comments to avoid parsing docs!
        $proto_content =~ s{ // .*? $ }{}gmx;
        $proto_content =~ s{ /\* .*? \*/ }{}gsx;
        
        my $file_package = '';
        if ($proto_content =~ / package \s+ ([\w\.]+) ; /x) {
            $file_package = $1;
            $package_name ||= $file_package; # Use the first package name as primary
        }
        
        my $perl_package_prefix = _proto_to_perl_namespace($file_package);
        
        # Derive the proto file name base to match the compiler's nested namespace
        my $proto_filename = basename($proto_file);
        $proto_filename =~ s/\.proto$//;
        my $pm_base = join '', map { ucfirst($_) } split /_/, $proto_filename;
        my $message_prefix = $perl_package_prefix . '::' . $pm_base;
        
        # Find services and their RPC methods using a robust token scanner
        my $file_service_name = '';
        while ($proto_content =~ /
            (?: service \s+ (\w+) )
            |
            (?: rpc \s+ (\w+) \s*
                \( \s* ([\w\.]+) \s* \) \s*
                returns \s* \( \s* ([\w\.]+) \s* \)
            )
        /gsx) {
            if ($1) {
                $file_service_name = $1;
                $service_name ||= $file_service_name; # Keep track of the first service name for metadata
            }
            elsif ($file_service_name && $2) {
                my ($method_name, $input_type, $output_type) = ($2, $3, $4);
                
                my $input_class = _resolve_perl_type($input_type, $file_package, $message_prefix);
                my $output_class = _resolve_perl_type($output_type, $file_package, $message_prefix);
                
                my $perl_method_name = _camel_to_snake($method_name);
                my $grpc_service_path = $file_package . '.' . $file_service_name;

                push @methods, {
                    raw_name => $method_name,
                    perl_name => $perl_method_name,
                    input_class => $input_class,
                    output_class => $output_class,
                    service_path => $grpc_service_path,
                };
            }
        }
    }

    # Generate the client class content
    my $grpc_target = $self->{_protobuf_grpc_target};
    my $methods_code = '';

    for my $m (@methods) {
        $methods_code .= sprintf(<<'EOF', $m->{perl_name}, $m->{input_class}, $m->{output_class}, $m->{service_path}, $m->{raw_name});

sub %s {
    my ($self, %%params) = @_;

    my $request_class = '%s';
    my $request = eval { $request_class->new(\%%params) } || eval { $request_class->new(%%params) } || ($request_class->can('encode') ? $request_class->encode(\%%params) : \%%params);

    my $response_class = '%s';
    my $response = $self->transport->call({
        service        => '%s',
        method         => '%s',
        request        => $request,
        response_class => $response_class,
    });

    return $response;
}
EOF
    }

    # Collect and generate use statements for all compiled proto modules
    my @use_modules = (
        'Protobuf',
        'Google::Api::Common',
    );
    for my $proto_file (@{$self->{_protobuf_files}}) {
        my $content = path($proto_file)->slurp_utf8();
        my $pkg = '';
        if ($content =~ / package \s+ ([\w\.]+) ; /x) {
            $pkg = $1;
        }
        my $prefix = _proto_to_perl_namespace($pkg);
        my $fname = basename($proto_file);
        $fname =~ s/\.proto$//;
        my $camel_fname = join '', map { ucfirst($_) } split /_/, $fname;
        push @use_modules, $prefix . '::' . $camel_fname;
    }
    my $use_statements = join "\n", map { "use $_;" } @use_modules;

    # Determine the raw C/XS namespace segment-by-segment (pure capitalization)
    my $cxs_namespace = '';
    if ($package_name) {
        my @parts = split /\./, $package_name;
        my @cxs_parts = map {
            my $p = $_;
            ($p =~ /^v\d+/i) ? uc($p) : ucfirst($p);
        } @parts;
        $cxs_namespace = join '::', @cxs_parts;
    }

    my $bridge_code = '';
    if ($cxs_namespace && lc($cxs_namespace) eq lc($module_name) && $cxs_namespace ne $module_name) {
        $bridge_code = sprintf(<<'EOF', $cxs_namespace, $module_name);

# Dynamic C/XS casing alias bridge to resolve split-brain mismatches
BEGIN {
    no strict 'refs';
    *{"%s::"} = *{"%s::"};
}
EOF
    }

    my $client_code;
    if (@methods) {
        # Generate methods POD block dynamically
        my $methods_pod = "=head2 METHODS\n\nThe following RPC methods are available in this client:\n\n=over 4\n\n";
        for my $m (@methods) {
            $methods_pod .= sprintf(<<'EOF', $m->{perl_name}, $m->{raw_name});
=item * B<%s>

Calls the RPC method C<%s> on the service. Takes a hash of parameters representing the request.

EOF
        }
        $methods_pod .= "=back\n\n";

        # Generate full gRPC service client wrapper
        $client_code = sprintf(<<'EOF', $module_name, $bridge_code, $use_statements, $grpc_target, $methods_code, $module_name, $module_name, $module_name, $module_name, $methods_pod);
package %s;

use strict;
use warnings;
use Moo;
use Google::gRPC::Client;
use Google::Cloud::REST::Client;
use Google::Auth;
use Carp qw(croak);
%s
%s

our $VERSION = '0.01';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my ($self) = @_;

    # Resolve credentials: use passed credentials object if it implements get_token, or default to ADC
    my $auth = $self->credentials;
    if (!$auth || !eval { $auth->can('get_token') }) {
        $auth = Google::Auth->default();
    }
    my $token = $auth->get_token();

    my $target = '%s';
    my $t = $self->transport || 'grpc';

    if (ref($t) && eval { $t->can('call') }) {
        # Already a transport object
    } elsif (lc($t) eq 'rest') {
        my $client = Google::Cloud::REST::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    } else {
        # Default high-performance HTTP/2 gRPC client
        my $client = Google::gRPC::Client->new(
            target     => $target,
            auth_token => $token,
        );
        $self->transport($client);
    }
}
%s1; # End of %s

__END__

=head1 NAME

%s - Auto-generated client library for Google Cloud Services

=head1 SYNOPSIS

    use %s;
    use Google::Auth;

    my $auth = Google::Auth->new(...);
    my $client = %s->new(
        credentials => $auth
    );

=head1 DESCRIPTION

This is an auto-generated Protocol Buffers client library for Google Cloud Services, built on top of high-performance gRPC and Protocol Buffers!

%s=head1 LICENSE

Apache License 2.0

=cut
EOF
    }
    else {
        # Generate a pure, lightweight schema container with no service dependencies
        $client_code = sprintf(<<'EOF', $module_name, $bridge_code, $use_statements, $module_name, $module_name);
package %s;

use strict;
use warnings;
%s
%s

our $VERSION = '0.01';
1; # End of %s

__END__

=head1 NAME

%s - Auto-generated Protocol Buffers schema container

=head1 DESCRIPTION

This is an auto-generated Protocol Buffers schema container module for Google Cloud Services.

=head1 LICENSE

Apache License 2.0

=cut
EOF
    }

    # Write the generated code to the primary module file
    path($file_path)->spew_utf8($client_code);

    # Store service metadata for test generation
    $self->{_services_meta} = {
        primary_module => $module_name,
        package_name   => $package_name,
        service_name   => $service_name,
        methods        => \@methods,
    };

    return;
}

# 3. Override Makefile_PL_guts to inject the required GCP/gRPC dependencies
sub Makefile_PL_guts {
    my ($self, @args) = @_;
    my $guts = $self->SUPER::Makefile_PL_guts(@args);

    # If we are generating a protobuf client, inject the appropriate CPAN dependencies
    if ($self->{_protobuf_files}) {
        my $has_services = ($self->{_services_meta} && @{$self->{_services_meta}->{methods}}) ? 1 : 0;
        my $deps;
        
        if ($has_services) {
            # Full service client dependencies
            $deps = <<'EOF';
        'Moo'                     => '0',
        'Net::Curl'               => '0',
        'Log::Any'                => '0',
        'Google::Auth'            => '0.01',
        'Google::gRPC::Client'    => '0.01',
        'Google::Api::Common'     => '0.01',
        'Protobuf'                => '0.01',
EOF
        }
        else {
            # Pure schema dependencies
            $deps = <<'EOF';
        'Protobuf'                => '0.01',
        'Const::Fast'             => '0',
EOF
        }
        
        # Inject our dependencies right into the PREREQ_PM hash in Makefile.PL
        $guts =~ s/(PREREQ_PM\s*=>\s*\{)/$1\n$deps/x;
    }

    return $guts;
}

# Utility: Convert camelCase/PascalCase to snake_case
sub _camel_to_snake {
    my ($str) = @_;
    $str =~ s{ ([a-z0-9]) ([A-Z]) }{${1}_${2}}gx;
    return lc($str);
}

# Utility: Convert dot-separated proto package to Camel::Case Perl namespace
sub _proto_to_perl_namespace {
    my ($proto_package) = @_;
    return '' if !$proto_package;
    
    my @parts = split /\./, $proto_package;
    my @perl_parts = map {
        my $part = $_;
        if ($part =~ m{ ^ v \d+ }ix) {
            uc($part); # v2 -> V2
        } else {
            my %custom = (
                'ggrpc'    => 'gRPC',
            );
            $custom{lc($part)} || ucfirst($part);
        }
    } @parts;
    return join '::', @perl_parts;
}

# Utility: Resolve fully-qualified or relative proto type to Perl package name
sub _resolve_perl_type {
    my ($raw_type, $current_file_package, $message_prefix) = @_;
    
    # Strip any leading dot (e.g. .google.protobuf.Empty -> google.protobuf.Empty)
    $raw_type =~ s/^\.//;
    
    if ($raw_type =~ /\./) {
        # It is a fully qualified type!
        my @parts = split /\./, $raw_type;
        my $message_name = pop @parts;
        my $package = join '.', @parts;
        
        my $perl_package = _proto_to_perl_namespace($package);
        
        # Determine the compiled file-module namespace part (CamelCase filename)
        my $file_base = '';
        
        if ($package eq 'google.protobuf') {
            # Descriptor options and schemas are in descriptor.proto
            if ($message_name =~ /Descriptor/ || $message_name =~ /Options/ || $message_name eq 'FileDescriptorSet') {
                $file_base = 'Descriptor';
            } else {
                # Other WKTs are named after the message (e.g. Empty -> empty.proto -> Empty)
                $file_base = $message_name;
            }
        }
        elsif ($package eq 'google.api') {
            # HttpRule and CustomHttpPattern are in http.proto
            if ($message_name =~ /^Http/ || $message_name eq 'CustomHttpPattern') {
                $file_base = 'Http';
            } else {
                # Default to the message name (e.g. AuditConfig -> AuditConfig)
                $file_base = $message_name;
            }
        }
        else {
            # For all other packages (like google.type or custom packages),
            # we default to the message name as the file base.
            $file_base = $message_name;
        }
        
        return $perl_package . '::' . $file_base . '::' . $message_name;
    }
    else {
        # It is a relative type!
        return $message_prefix . '::' . $raw_type;
    }
}

# Helper to dynamically generate and write an integration test (t/01-service.t)
# that mocks and exercises all auto-generated gRPC client methods
sub _generate_service_test {
    my ($self, $module_name) = @_;

    my $meta = $self->{_services_meta};
    return unless $meta && @{$meta->{methods}};

    my $test_file = File::Spec->catfile('t', '01-service.t');
    my $abs_test_file = File::Spec->catfile($self->{basedir}, $test_file);

    # Start building the test content
    # We must escape %args as %%args to prevent sprintf from parsing it as a format specifier!
    my $test_code = sprintf(<<'EOF', $module_name, $module_name);
use strict;
use warnings;
use Test::More;
use File::Spec;

# A. Mock Google::Auth
package Google::Auth;
BEGIN { $INC{'Google/Auth.pm'} = 1; }
sub default {
    my ($class, %%args) = @_;
    return bless \%%args, 'Google::Auth::MockCredentials';
}
package Google::Auth::MockCredentials;
sub get_token {
    return 'mock-token';
}

# B. Mock Google::gRPC::Client
package Google::gRPC::Client;
BEGIN { $INC{'Google/gRPC/Client.pm'} = 1; }
sub new {
    my ($class, %%args) = @_;
    return bless \%%args, $class;
}
sub call {
    my ($self, $args) = @_;
    if ($self->{mock_call}) {
        return $self->{mock_call}->($args);
    }
    die 'No mock_call handler configured in transport!';
}

# C. Main test execution
package main;
use %s;

my $client = %s->new( credentials => 'dummy' );
ok($client, 'Instantiated generated client');
isa_ok($client->transport, 'Google::gRPC::Client', 'Client transport');
EOF

    # Generate a subtest for each method
    for my $m (@{$meta->{methods}}) {
        $test_code .= sprintf(<<'EOF', $m->{perl_name}, $m->{service_path}, $m->{raw_name}, $m->{input_class}, $m->{output_class}, $m->{perl_name}, $m->{output_class});

subtest '%s method' => sub {
    $client->transport->{mock_call} = sub {
        my ($args) = @_;
        is($args->{service}, '%s', 'Correct service path');
        is($args->{method}, '%s', 'Correct RPC method');
        isa_ok($args->{request}, '%s', 'Request object');
        
        my $response = '%s'->new();
        return $response;
    };
    
    my $res = $client->%s();
    ok($res, 'Method returned a response');
    isa_ok($res, '%s', 'Response object class');
    done_testing();
};
EOF
    }

    $test_code .= "\ndone_testing();\n";

    # Write the test file
    path($abs_test_file)->spew_utf8($test_code);

    return $test_file;
}

sub _generate_rest_test {
    my ($self, $module_name) = @_;

    my $meta = $self->{_services_meta};
    return unless $meta && @{$meta->{methods}};

    my $test_file = File::Spec->catfile('t', '02-rest-transport.t');
    my $abs_test_file = File::Spec->catfile($self->{basedir}, $test_file);

    my $test_code = sprintf(<<'EOF', $module_name, $module_name);
use strict;
use warnings;
use Test::More;
use Test::LWP::UserAgent;
use HTTP::Response;
use JSON::MaybeXS qw(encode_json);

package Google::Auth;
BEGIN { $INC{'Google/Auth.pm'} = 1; }
sub default { bless {}, 'Google::Auth::Mock' }
package Google::Auth::Mock;
sub get_token { 'mock-token-abc' }

package main;
use Google::Api::Common;
use %s;
use Google::Cloud::REST::Client;

subtest 'Client REST Transport Initialization' => sub {
    my $client = %s->new(
        credentials => bless({}, 'Google::Auth::Mock'),
        transport   => 'rest',
    );

    ok($client, 'Created client with REST transport');
    isa_ok($client->transport, 'Google::Cloud::REST::Client');
};

subtest 'Client REST API Request' => sub {
    my $mock_ua = Test::LWP::UserAgent->new;
    $mock_ua->map_response(
        sub { 1 },
        HTTP::Response->new(
            200, 'OK',
            ['Content-Type' => 'application/json'],
            encode_json({ kind => 'response' })
        )
    );

    my $rest_client = Google::Cloud::REST::Client->new(
        target     => 'test.googleapis.com',
        auth_token => 'mock-token-abc',
        ua         => $mock_ua,
    );

    my $res = $rest_client->request(
        method => 'GET',
        path   => '/v1/test',
    );

    ok($res, 'Received response from mock REST client');
};

done_testing();
EOF

    path($abs_test_file)->spew_utf8($test_code);
    return $test_file;
}

=head1 NAME

Module::Starter::Protobuf - A Module::Starter plugin for generating Protocol Buffers client libraries

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Module::Starter qw(Module::Starter::Protobuf);
    
    # Or from the command line:
    # PROTOBUF_FILES=protos/my_service.proto module-starter --module=My::Client --plugin=Module::Starter::Protobuf

=head1 DESCRIPTION

This is a L<Module::Starter> plugin that automates the generation of skeletal CPAN distributions
from Protocol Buffers (proto3) schemas. It runs the C<protoc> compiler to generate low-level
serialization classes using the C<upb> C/XS compiler plugin and automatically generates
high-level client wrappers with idiomatic gRPC call methods.

=head1 METHODS

=head2 create_distro

Intercepts and validates the protobuf configuration parameters from arguments or environment variables.

=head2 create_modules

Generates the low-level protobuf serialization classes and the high-level client wrapper modules.

=head2 create_t

Generates the dynamic service integration tests (C<t/01-service.t>) under the target directory.

=head2 Makefile_PL_guts

Injects the required dependencies (C<Moo>, C<Net::Curl>, C<Google::Auth>, C<Google::gRPC::Client>, C<Protobuf>) into the generated C<Makefile.PL>.

=head1 AUTHOR

C.J. Collier <cjac@google.com>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by C.J. Collier <cjac@google.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Module::Starter::Protobuf

