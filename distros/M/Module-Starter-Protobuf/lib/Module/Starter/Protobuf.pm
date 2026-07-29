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

our $VERSION = '0.04';

sub create_distro {
    my ($self, %args) = @_;

    $self->{version} ||= $self->_detect_version();

    $args{license} ||= 'apache_2';
    $args{author}  ||= 'Google LLC <cjac@google.com>';
    $args{email}   ||= 'cjac@google.com';

    $self->{license} ||= 'apache_2';
    $self->{author}  ||= 'Google LLC <cjac@google.com>';
    $self->{email}   ||= 'cjac@google.com';

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

    my $separate = $self->{separate_clients} // $ENV{PROTOBUF_SEPARATE_CLIENTS} // 1; # Default to separate
    $self->{separate_clients} = $separate;

    if ($separate && $self->{_protobuf_files}) {
        my %services = $self->_parse_services_meta();
        $self->{_services_meta_all} = \%services;

        my $base_module = $self->{modules}->[0];
        my ($base_ns) = $base_module =~ /^(.*)::(\w+)$/;
        $base_ns ||= $base_module; # Fallback

        my @new_modules = ($base_module);
        for my $svc (sort keys %services) {
            my $module = "${base_ns}::${svc}Client";
            push @new_modules, $module;
            $self->{_module_to_service}->{$module} = $svc;
        }
        $self->{modules} = \@new_modules if @new_modules > 1;
    }

    return $self->SUPER::create_distro(%args);
}

# Helper to pre-parse services from proto files
sub _parse_services_meta {
    my ($self) = @_;

    my %services;

    for my $proto_file (@{$self->{_protobuf_files}}) {
        my $proto_content = path($proto_file)->slurp_utf8();

        my $file_package = '';
        if ($proto_content =~ / package \s+ ([\w\.]+) ; /x) {
            $file_package = $1;
        }

        my $file_service_name = '';
        while ($proto_content =~ /
            (?: service \s+ (\w+) \s* \{ )
            |
            (?: rpc \s+ (\w+) \s*
                \( \s* (?:stream\s+)? ([\w\.]+) \s* \) \s*
                returns \s* \( \s* (?:stream\s+)? ([\w\.]+) \s* \)
            )
        /gsx) {
            if ($1) {
                $file_service_name = $1;
                $services{$file_service_name} = {
                    package => $file_package,
                    methods => [],
                    file    => $proto_file,
                };
            }
            elsif ($file_service_name && $2) {
                push @{$services{$file_service_name}->{methods}}, {
                    name => $2,
                    input => $3,
                    output => $4,
                };
            }
        }
    }
    return %services;
}

sub _detect_version {
    my ($self) = @_;
    my $target_dir = $self->{dir} || $self->{basedir};
    return '0.01' unless $target_dir;
    
    my $changes_file = File::Spec->catfile($target_dir, 'Changes');
    if (-f $changes_file) {
        my $content = path($changes_file)->slurp_utf8();
        if ($content =~ /^(\d+\.\d+)/m) {
            my $current_version = $1;
            my $next = $current_version + 0.01;
            return sprintf("%0.2f", $next);
        }
    }
    return '0.01';
}

# 2. Override create_modules to run protoc and generate the client wrappers
sub create_modules {
    my ($self, @modules) = @_;

    # First, let the base class create the standard module skeletons
    my @files = $self->SUPER::create_modules(@modules);

    # Generate SECURITY.md
    my $security_file = File::Spec->catfile($self->{basedir}, 'SECURITY.md');
    my $security_guts = $self->SECURITY_md_guts();
    $self->create_file($security_file, $security_guts);
    $self->progress("Created $security_file");
    push @files, 'SECURITY.md';

    # If no protobuf files are configured, behave like a standard starter
    return @files unless $self->{_protobuf_files};

    my $lib_dir = File::Spec->catdir($self->{basedir}, 'lib');

    for my $proto_file (@{$self->{_protobuf_files}}) {
        if (! -f $proto_file) {
            croak 'Protobuf file not found: ' . $proto_file;
        }

        # Execute protoc using native Perl compiler plugin from PATH or ENV
        my $protoc_bin = $ENV{PROTOC} 
            || which('protoc') 
            || which('protoc.exe') 
            || (-f 'C:\ProgramData\chocolatey\bin\protoc.exe' ? 'C:\ProgramData\chocolatey\bin\protoc.exe' : undef)
            || (-f 'C:\tools\protoc\bin\protoc.exe' ? 'C:\tools\protoc\bin\protoc.exe' : undef)
            || 'protoc';
        my $plugin_path = $ENV{PROTOC_GEN_PERL_PB};
        if (!defined $plugin_path) {
            my $perl_dir = File::Basename::dirname($^X);
            if ($^O eq 'MSWin32') {
                my $dev_exe  = File::Spec->rel2abs(File::Spec->catfile(File::Spec->updir(), 'Protobuf', 'bin', 'protoc-gen-perl-pb.exe'));
                my $dev_exe2 = File::Spec->rel2abs(File::Spec->catfile(File::Spec->updir(), File::Spec->updir(), 'Protobuf', 'bin', 'protoc-gen-perl-pb.exe'));
                my $dev_final = -f $dev_exe ? $dev_exe : (-f $dev_exe2 ? $dev_exe2 : undef);
                my $found = $dev_final
                    || which('protoc-gen-perl-pb.exe')
                    || (-f File::Spec->catfile($perl_dir, 'protoc-gen-perl-pb.exe') ? File::Spec->catfile($perl_dir, 'protoc-gen-perl-pb.exe') : undef)
                    || which('protoc-gen-perl-pb.bat')
                    || (-f File::Spec->catfile($perl_dir, 'protoc-gen-perl-pb.bat') ? File::Spec->catfile($perl_dir, 'protoc-gen-perl-pb.bat') : undef);
                $plugin_path = $found || 'protoc-gen-perl-pb.exe';
            } else {
                my $found = which('protoc-gen-perl-pb')
                    || (-f File::Spec->catfile($perl_dir, 'protoc-gen-perl-pb') ? File::Spec->catfile($perl_dir, 'protoc-gen-perl-pb') : undef);
                if ($found) {
                    $plugin_path = $found;
                } else {
                    my $dev_bin = File::Spec->catfile(File::Spec->updir(), 'Protobuf', 'bin', 'protoc-gen-perl-pb');
                    $plugin_path = -f $dev_bin ? File::Spec->rel2abs($dev_bin) : 'protoc-gen-perl-pb';
                }
            }
        }
        
        $plugin_path = File::Spec->rel2abs($plugin_path) if -f $plugin_path;
        my $abs_lib_dir = File::Spec->rel2abs($lib_dir);
        File::Path::make_path($abs_lib_dir) unless -d $abs_lib_dir;
        (my $norm_lib_dir = $abs_lib_dir) =~ s{\\}{/}g;
        (my $norm_plugin_path = $plugin_path) =~ s{\\}{/}g;
        (my $norm_proto_file = $proto_file) =~ s{\\}{/}g;
        (my $norm_import_path = $self->{_protobuf_import_path}) =~ s{\\}{/}g;

        my $rel_proto = File::Spec->abs2rel($norm_proto_file, $norm_import_path);
        $rel_proto =~ s{\\}{/}g;

        my @cmd = ($protoc_bin);
        push @cmd, '--plugin=protoc-gen-perl-pb=' . $norm_plugin_path;
        push @cmd, '--perl-pb_out=' . $norm_lib_dir;
        push @cmd, '--perl-pb_opt=embed_descriptors,generate_services';
        push @cmd, ('-I', $norm_import_path);
        push @cmd, ('-I', '/usr/include') if -d '/usr/include';
        push @cmd, ('-I', '/usr/local/include') if -d '/usr/local/include';
        
        my $temp_deps = Path::Tiny->tempfile();
        push @cmd, '--dependency_out=' . $temp_deps;
        
        push @cmd, $rel_proto;
        
        my $cmd_str = join(' ', map { $_ =~ /\s/ ? qq("$_\") : $_ } @cmd);
        print "Executing protoc: $cmd_str\n";

        my $rc = system(@cmd);
        if ($rc != 0) {
            die "protoc execution failed with code $rc for $norm_proto_file. Command: $cmd_str\n";
        }

        # Parse dependencies
        my $deps_content = $temp_deps->slurp_utf8();
        $deps_content =~ s/\\\n//g; # Remove line continuations
        my ($target, $prereqs_str) = split /:/, $deps_content, 2;
        die "Malformed dependency output: missing colon" unless defined $prereqs_str;

        # Filter out empty elements, target itself, and the dependent file itself (self-loop prevention)
        my @prereqs = grep { $_ && $_ ne $target && $_ ne $norm_proto_file } split /\s+/, $prereqs_str;
        $self->{_protobuf_dependencies}->{$proto_file} = \@prereqs;
    }

    # B. Generate the high-level client wrappers for each requested module
    for my $i (0 .. $#modules) {
        my $module = $modules[$i];
        my $file = $files[$i];
        my $abs_file = File::Spec->catfile($self->{basedir}, $file);

        if ($abs_file && -f $abs_file) {
            $self->_generate_client_wrapper($module, $abs_file);
        }
    }

    return @files;
}

# 2.5 Override create_t to generate our dynamic integration tests
sub create_t {
    my ($self, @modules) = @_;

    # First, let the base class create the standard t/ directory and load tests
    my @files = $self->SUPER::create_t(@modules);

    # If we have parsed service metadata, generate our integration test!
    if ($self->{_protobuf_files} && ($self->{_services_meta_by_module} || $self->{_services_meta})) {
        for my $m (@modules) {
            my $test_file = $self->_generate_service_test($m);
            push @files, $test_file if $test_file;
            my $rest_test_file = $self->_generate_rest_test($m);
            push @files, $rest_test_file if $rest_test_file;
        }
    }

    # Generate xt/00_perl-critic.t for author/release quality checks
    my $xt_dir = path($self->{basedir}, "xt");
    $xt_dir->mkpath;
    my $critic_file = path($self->{basedir}, "xt", "00_perl-critic.t");
    $critic_file->spew_utf8(<<'EOF');
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;

unless ( $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} ) {
    plan( skip_all => 'Author/Release tests not required for installation' );
}

eval 'use Test::Perl::Critic';
plan( skip_all => 'Test::Perl::Critic required for testing code quality' ) if $@;

my $root = File::Spec->rel2abs('../..');
my $rcfile = File::Spec->catfile($root, '.perlcriticrc');
if (-f $rcfile) {
    Test::Perl::Critic->import( -profile => $rcfile );
}

all_critic_ok('lib');
EOF
    push @files, 'xt/00_perl-critic.t';

    return @files;
}

# Helper to parse protos and generate the high-level client wrapper class
sub _generate_client_wrapper {
    my ($self, $module_name, $file_path) = @_;

    my @methods;
    my $package_name = '';
    my $service_name = '';

    my $service_to_gen = $self->{_module_to_service}->{$module_name};
    $service_name = $service_to_gen if $service_to_gen;

    # Pre-scan messages across all files to build a dictionary
    $self->{_message_file_base} = {};
    for my $proto_file (@{$self->{_protobuf_files}}) {
        my $content = path($proto_file)->slurp_utf8();
        $content =~ s{ // .*? $ }{}gmx;
        $content =~ s{ /\* .*? \*/ }{}gsx;
        
        my $pkg = '';
        if ($content =~ /^\s*package\s+([\w\.]+)\s*;/mx) {
            $pkg = $1;
        }
        
        my $fname = basename($proto_file);
        $fname =~ s/\.proto$//;
        my $pm_base = join '', map { ucfirst($_) } split /_/, $fname;
        
        while ($content =~ /^\s*message\s+(\w+)/gmx) {
            my $msg = $1;
            $self->{_message_file_base}->{"$pkg.$msg"} = $pm_base;
            $self->{_message_file_base}->{$msg} = $pm_base; # Fallback
        }
    }

    # Loop over and parse all proto files in the list!
    for my $proto_file (@{$self->{_protobuf_files}}) {
        my $proto_content = path($proto_file)->slurp_utf8();
        
        # Strip all single-line and multi-line comments to avoid parsing docs!
        $proto_content =~ s{ // .*? $ }{}gmx;
        $proto_content =~ s{ /\* .*? \*/ }{}gsx;
        
        my $file_package = '';
        if ($proto_content =~ /^\s*package\s+([\w\.]+)\s*;/mx) {
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
            (?: service \s+ (\w+) \s* \{ )
            |
            (?: rpc \s+ (\w+) \s*
                \( \s* (?:stream\s+)? ([\w\.]+) \s* \) \s*
                returns \s* \( \s* (?:stream\s+)? ([\w\.]+) \s* \)
            )
        /gsx) {
            if ($1) {
                $file_service_name = $1;
                $service_name ||= $file_service_name unless $service_to_gen; # Keep track of the first service name for metadata
            }
            elsif ($file_service_name && $2) {
                my ($method_name, $input_type, $output_type) = ($2, $3, $4);
                
                my $input_class = $self->_resolve_perl_type($input_type, $file_package, $message_prefix);
                my $output_class = $self->_resolve_perl_type($output_type, $file_package, $message_prefix);
                
                my $perl_method_name = _camel_to_snake($method_name);
                my $grpc_service_path = $file_package . '.' . $file_service_name;

                my $m_info = {
                    raw_name => $method_name,
                    perl_name => $perl_method_name,
                    input_class => $input_class,
                    output_class => $output_class,
                    service_path => $grpc_service_path,
                };

                if (!$service_to_gen || $file_service_name eq $service_to_gen) {
                    push @methods, $m_info;
                }
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
    # Build Dependency DAG and sort topologically (Kahn's algorithm)
    my %dependencies = %{$self->{_protobuf_dependencies} || {}};
    my %in_degree;
    my %adj_list;

    for my $u (keys %dependencies) {
        $in_degree{$u} //= 0;
        $adj_list{$u} //= [];
    }

    for my $u (keys %dependencies) {
        for my $v (@{$dependencies{$u}}) {
            # v is a prerequisite of u, so edge goes v -> u
            push @{$adj_list{$v}}, $u;
            $in_degree{$u}++;
            $in_degree{$v} //= 0;
            $adj_list{$v} //= [];
        }
    }

    my @q = grep { $in_degree{$_} == 0 } keys %in_degree;
    my @sorted;

    while (@q) {
        my $u = shift @q;
        push @sorted, $u;
        for my $v (@{$adj_list{$u}}) {
            $in_degree{$v}--;
            if ($in_degree{$v} == 0) {
                push @q, $v;
            }
        }
    }
    die 'Circular dependency detected' if @sorted != keys %in_degree;

    # %local_files is a lookup hash derived from @{$self->{_protobuf_files}}
    my %local_files = map { $_ => 1 } @{$self->{_protobuf_files}};

    for my $proto_file (@sorted) {
        # Only generate 'use' for files in the local processing set
        next unless exists $local_files{$proto_file}; 
        
        my $content = path($proto_file)->slurp_utf8();
        my $pkg = '';
        if ($content =~ / package \s+ ([\w\.]+) ; /x) {
            $pkg = $1;
        } else {
            die "Failed to extract package name from $proto_file using heuristic regex";
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
            ($p =~ /^v\d+$/i) ? uc($p) : ucfirst($p);
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

    my $EQ = '=';
    
    my $import_path = $self->{_protobuf_import_path} || '';
    my $source_pod_items = '';
    for my $proto_file (@{$self->{_protobuf_files}}) {
        my $display_path = $proto_file; # Fallback
        if ($import_path && $display_path =~ /^\Q$import_path\E\/(.*)/) {
            my $rel = $1;
            if ($import_path =~ /googleapis$/) {
                $display_path = "googleapis/" . $rel;
            } else {
                $display_path = $rel;
            }
        }
        elsif ($display_path =~ m{/(googleapis/.*)$}) {
            $display_path = $1;
        }
        if ($display_path =~ /^\//) {
            $display_path = basename($display_path);
        }

        $source_pod_items .= "${EQ}item * C<$display_path>\n\n";
    }

    my $client_code;
    if (@methods) {
        # Generate methods POD block dynamically
        my $methods_pod = "${EQ}head2 METHODS\n\nThe following RPC methods are available in this client:\n\n${EQ}over 4\n\n";
        for my $m (@methods) {
            $methods_pod .= sprintf("${EQ}item * B<%s>\n\nCalls the RPC method C<%s> on the service. Takes a hash of parameters representing the request.\n\n", $m->{perl_name}, $m->{raw_name});
        }
        $methods_pod .= "${EQ}back\n\n";

        # Generate full gRPC service client wrapper
        my $version = $self->{version} || $self->_detect_version();
        $client_code = sprintf(<<"EOF", $module_name, $bridge_code, $use_statements, $version, $grpc_target, $methods_code, $module_name, $module_name, $module_name, $module_name, $module_name, $module_name, $source_pod_items, $module_name, $methods_pod);
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

our \$VERSION = '%s';

has credentials => ( is => 'ro', required => 0 );
has transport   => ( is => 'rw' );

sub BUILD {
    my (\$self) = \@_;

    # Resolve credentials: use passed credentials object if it implements get_token, or default to ADC
    my \$auth = \$self->credentials;
    if (!\$auth || !eval { \$auth->can('get_token') }) {
        \$auth = Google::Auth->default();
    }
    my \$token = \$auth->get_token();

    my \$target = '%s';
    my \$t = \$self->transport || 'grpc';

    if (ref(\$t) && eval { \$t->can('call') }) {
        # Already a transport object
    } elsif (lc(\$t) eq 'rest') {
        my \$client = Google::Cloud::REST::Client->new(
            target     => \$target,
            auth_token => \$token,
        );
        \$self->transport(\$client);
    } else {
        # Default high-performance HTTP/2 gRPC client
        my \$client = Google::gRPC::Client->new(
            target     => \$target,
            auth_token => \$token,
        );
        \$self->transport(\$client);
    }
}
%s1; # End of %s

__END__

${EQ}head1 NAME

%s - Client library for Google Cloud Services

${EQ}head1 SYNOPSIS

    use %s;
    use Google::Auth;

    my \$auth = Google::Auth->default();

    # 1. High-performance gRPC Transport (Default)
    my \$grpc_client = %s->new(
        credentials => \$auth,
        transport   => 'grpc', # Optional: 'grpc' is default
    );

    # 2. HTTP/REST Transport
    my \$rest_client = %s->new(
        credentials => \$auth,
        transport   => 'rest',
    );

    # Execute service methods
    my \$res = \$grpc_client->some_method( %%params );

${EQ}head1 DESCRIPTION

C<%s> is an auto-generated client library for Google Cloud Services.

It provides a unified client interface supporting both high-performance HTTP/2 gRPC and HTTP/REST transports, with automatic Google Cloud Application Default Credentials (ADC) resolution and typed Protocol Buffers message handling.

${EQ}head1 SOURCE

Generated from the following Protocol Buffers schemas:

${EQ}over 4

%s

${EQ}back

${EQ}head1 CONSTRUCTOR

${EQ}head2 new

    my \$client = %s->new(
        credentials => \$auth,   # Optional: Google::Auth object (defaults to ADC)
        transport   => 'grpc', # Optional: 'grpc' (default) or 'rest'
    );

${EQ}head1 ATTRIBUTES

${EQ}head2 credentials

Returns or accepts the L<Google::Auth> credentials object.

${EQ}head2 transport

Returns or accepts the active transport object (L<Google::gRPC::Client> or L<Google::Cloud::REST::Client>).

${EQ}head1 METHODS

%s

${EQ}head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

${EQ}cut
EOF
    }
    else {
        # Generate a pure, lightweight schema container with no service dependencies
        my $version = $self->{version} || $self->_detect_version();
        $client_code = sprintf(<<"EOF", $module_name, $bridge_code, $use_statements, $version, $module_name, $module_name, $source_pod_items);
package %s;

use strict;
use warnings;
%s
%s

our \$VERSION = '%s';
1; # End of %s

__END__

${EQ}head1 NAME

%s - Auto-generated Protocol Buffers schema container

${EQ}head1 DESCRIPTION

This is an auto-generated Protocol Buffers schema container module for Google Cloud Services.

${EQ}head1 SOURCE

Generated from the following Protocol Buffers schemas:

${EQ}over 4

%s

${EQ}back

${EQ}head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

${EQ}cut
EOF
    }

    # Write the generated code to the primary module file
    path($file_path)->spew_utf8($client_code);

    # Store service metadata for test generation
    $self->{_services_meta_by_module}->{$module_name} = {
        primary_module => $module_name,
        package_name   => $package_name,
        service_name   => $service_name,
        methods        => \@methods,
    };
    $self->{_services_meta} = $self->{_services_meta_by_module}->{$module_name} if !$self->{separate_clients};

    return;
}

# 3. Override Makefile_PL_guts to inject the required GCP/gRPC dependencies
sub Makefile_PL_guts {
    my ($self, @args) = @_;
    my $guts = $self->SUPER::Makefile_PL_guts(@args);

    # If we are generating a protobuf client, inject the appropriate CPAN dependencies
    if ($self->{_protobuf_files}) {
        my $has_services = 0;
        if ($self->{_services_meta_by_module}) {
            for my $m (keys %{$self->{_services_meta_by_module}}) {
                if (@{$self->{_services_meta_by_module}->{$m}->{methods}}) {
                    $has_services = 1;
                    last;
                }
            }
        }
        $has_services ||= ($self->{_services_meta} && @{$self->{_services_meta}->{methods}}) ? 1 : 0;
        my $deps;
        
        if ($has_services) {
            # Full service client dependencies
            $deps = <<'EOF';
        'Moo'                     => '0',
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

# 4. Override Changes_guts, README_guts, README_md_guts, and license_guts to remove boilerplate and enforce Apache 2.0
sub Changes_guts {
    my ($self, $date) = @_;
    my $distro = $self->{distro} || $self->{main_module} || 'Module';
    my $version = $self->{version} || '0.01';
    return sprintf(<<'EOF', $distro, $version, $date || scalar localtime);
Revision history for %s

%s  %s
    - Initial release. Auto-generated from Protocol Buffers schema.
EOF
}

sub README_guts {
    my ($self, $build_fn, $date) = @_;
    my $module = $self->{main_module} || $self->{distro} || 'Module';
    return sprintf(<<'EOF', $module, $module);
# %s

Auto-generated Protocol Buffers client library for Google Cloud Services.

## Installation

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## Documentation

After installing, you can find documentation for this module with the `perldoc` command:

    perldoc %s

## License and Copyright

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.
EOF
}

sub README_md_guts {
    my ($self, $build_fn, $date) = @_;
    return $self->README_guts($build_fn, $date);
}

sub SECURITY_md_guts {
    my ($self) = @_;
    my $link = $self->{security_link} || $ENV{SECURITY_LINK};
    
    if ($link) {
        return "# Security Policy\n\nThis security policy covers all packages contained within this repository.\n\nTo report a security issue, please visit [$link]($link).\n";
    } else {
        my $author_str = ref($self->{author}) eq 'ARRAY' ? $self->{author}->[0] : $self->{author};
        $author_str ||= 'Maintainer';
        if ($author_str =~ /<([^>]+)>/) {
            return "# Security Policy\n\n## Reporting a Vulnerability\n\nIf you discover a security vulnerability in this project, please report it to the maintainer:\n\n*   **Contact:** $author_str\n\nWe take security issues seriously and will respond to reports as quickly as possible.\n";
        } else {
            return "# Security Policy\n\n## Reporting a Vulnerability\n\nIf you discover a security vulnerability in this project, please report it to the maintainer.\n\nWe take security issues seriously and will respond to reports as quickly as possible.\n";
        }
    }
}

sub license_guts {
    my ($self, $license, $author, $year) = @_;
    my $holder = 'Google LLC';
    return sprintf(<<'EOF', $year || '2026', $holder);
Copyright (C) %s %s

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the specific language
governing permissions and limitations under the License.
EOF
}

sub t_guts {
    my ($self, @modules) = @_;
    my %files = $self->SUPER::t_guts(@modules);
    if (exists $files{'pod-coverage.t'}) {
        $files{'pod-coverage.t'} = <<'EOF';
#!/perl
use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} || $ENV{AUTHOR_TESTING} ) {
    plan( skip_all => "Author/Release tests not required for installation" );
}

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage" if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage" if $@;

my @modules = all_modules('lib');
my @tested;
for my $module (@modules) {
    eval "require $module;";
    my $pc = Pod::Coverage->new(package => $module);
    if (!defined $pc || !defined $pc->coverage || ($pc->why_unrated && $pc->why_unrated =~ /couldn't find pod/i)) {
        note("Skipping POD coverage for $module (no POD present)");
        next;
    }
    pod_coverage_ok($module, { also_private => [ qr!^[a-z_]!, 'BUILD' ] });
    push @tested, $module;
}

if (!@tested) {
    plan skip_all => "No modules with POD documentation found in distribution";
} else {
    done_testing();
}

EOF
    }
    return %files;
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
        if ($part =~ m{ ^ v \d+ $ }ix) {
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
    my ($self, $raw_type, $current_file_package, $message_prefix) = @_;
    
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
        
        if (my $mapped_base = $self->{_message_file_base}->{"$package.$message_name"}) {
            $file_base = $mapped_base;
        }
        elsif ($package eq 'google.protobuf') {
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
        elsif ($package eq 'google.longrunning') {
            # Standard long running operations are in operations.proto -> Operations
            $file_base = 'Operations';
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
        if (my $file_base = $self->{_message_file_base}->{"$current_file_package.$raw_type"} || $self->{_message_file_base}->{$raw_type}) {
            my $perl_package_prefix = _proto_to_perl_namespace($current_file_package);
            return $perl_package_prefix . '::' . $file_base . '::' . $raw_type;
        }
        return $message_prefix . '::' . $raw_type;
    }
}

# Helper to dynamically generate and write an integration test (t/01-service.t)
# that mocks and exercises all auto-generated gRPC client methods
sub _generate_service_test {
    my ($self, $module_name) = @_;

    my $meta = $self->{_services_meta_by_module}->{$module_name} || $self->{_services_meta};
    return unless $meta && @{$meta->{methods}};

    my %output_classes = map { $_->{output_class} => 1 } @{$meta->{methods}};
    my $packages_to_mock = join(' ', sort keys %output_classes);

    my ($service_name) = $module_name =~ /::(\w+)Client$/;
    $service_name ||= 'Default';
    my $test_file = File::Spec->catfile('t', "01-service-$service_name.t");
    my $abs_test_file = File::Spec->catfile($self->{basedir}, $test_file);

    # Start building the test content
    # We must escape %args as %%args to prevent sprintf from parsing it as a format specifier!
    my $test_code = sprintf(<<'EOF', $packages_to_mock, $module_name, $module_name);
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
    my $class = shift;
    my $args = ( @_ == 1 && ref($_[0]) eq 'HASH' ) ? $_[0] : { @_ };
    return bless $args, $class;
}
sub call {
    my ($self, $args) = @_;
    if ($self->{mock_call}) {
        return $self->{mock_call}->($args);
    }
    die 'No mock_call handler configured in transport!';
}

# C. Fallback Mocks for External Response Classes
BEGIN {
    for my $pkg (qw( %s )) {
        unless ($pkg->can('new')) {
            no strict 'refs';
            *{"${pkg}::new"} = sub { bless {}, $_[0] };
            $INC{join('/', split('::', $pkg)) . '.pm'} = 1;
        }
    }
}

# D. Main test execution
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

    my $meta = $self->{_services_meta_by_module}->{$module_name} || $self->{_services_meta};
    return unless $meta && @{$meta->{methods}};

    my ($service_name) = $module_name =~ /::(\w+)Client$/;
    $service_name ||= 'Default';
    my $test_file = File::Spec->catfile('t', "02-rest-transport-$service_name.t");
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

Version 0.03

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

Generates the dynamic service integration tests (C<t/01-service.t>) under the target directory, including a mock C<Google::gRPC::Client> constructor that accepts both HashRef and list options.

=head2 Makefile_PL_guts

Injects the required dependencies (C<Moo>, C<Log::Any>, C<Google::Auth>, C<Google::gRPC::Client>, C<Protobuf>) into the generated C<Makefile.PL>.

=head1 AUTHOR

C.J. Collier <cjac@google.com>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut

1; # End of Module::Starter::Protobuf

