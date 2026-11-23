package Protobuf;

use strict;
use warnings;
use Log::Any qw($log);

our $VERSION = '0.14';

our $HAS_XS;
{
    my $no_xs = $ENV{'PROTOBUF_NO_XS'} || ($ENV{'PROTOBUF_ENGINE'} && $ENV{'PROTOBUF_ENGINE'} eq 'pure_perl');
    if ($no_xs) {
        $HAS_XS = 0;
    } else {
        eval {
            require XSLoader;
            XSLoader::load('Protobuf', $VERSION);
            $HAS_XS = 1;
        };
        if ($@) {
            $HAS_XS = 0;
            warn "Protobuf XS not loaded: $@" if $ENV{'PROTOBUF_DEBUG'};
            $log->debugf('Protobuf XS not loaded: %s', $@) if $ENV{'PROTOBUF_DEBUG'};
        }
    }
}

if ($HAS_XS) {
    require Protobuf::Internal;
    Protobuf::Internal::init_registry();
}
require Protobuf::Message;
require Protobuf::Arena;


our $ENGINE;
my %engines;

sub get_engine {
    my ($class_or_name, $name) = @_;

    # Handle method call vs function call
    if (defined($class_or_name) && $class_or_name eq 'Protobuf') {
        # Method call: Protobuf->get_engine($name)
    } else {
        # Function call: get_engine($name)
        $name = $class_or_name;
    }

    $name ||= $ENV{PROTOBUF_ENGINE} || ($HAS_XS ? 'xs' : 'pure_perl');

    # Map high-level profiles to implementation engines
    my $engine_key = ($name =~ /^(?:xs|balanced|write_heavy|read_heavy|zero_copy)$/) ? 'xs' : 'pure_perl';

    # If we requested XS but don't have it, fallback to PurePerl
    if ($engine_key eq 'xs' && !$HAS_XS) {
        $engine_key = 'pure_perl';
    }

    return $engines{$engine_key} if $engines{$engine_key};

    my $class = "Protobuf::Engine::" . ($engine_key eq 'xs' ? 'XS' : 'PurePerl');
    (my $file = $class) =~ s/::/\//g;
    require "$file.pm"; ## no critic (Modules::RequireBarewordIncludes)

    return $engines{$engine_key} = $class->new();
}

sub engine {
    my ($class, $name) = @_;
    if ($name) {
        $ENGINE = get_engine($name);
    }
    return $ENGINE ||= get_engine();
}

1;

__END__

=encoding UTF-8

=head1 NAME

Protobuf - High-performance Google Protocol Buffers for Perl backed by Google's upb C engine

=head1 VERSION

Version 0.14

=head1 SYNOPSIS

    # 1. Compile your .proto schema with the bundled protoc plugin:
    #    protoc --plugin=protoc-gen-perl-pb=$(which protoc-gen-perl-pb) \
    #           --perl-pb_out=lib --proto_path=protos protos/addressbook.proto

    # 2. Construct, serialize, and parse typed messages in Perl:
    use Tutorial::Addressbook;

    my $person = Tutorial::Addressbook::Person->new({
        name  => 'Ada Lovelace',
        id    => 1234,
        email => 'ada@example.com',
        phones => [
            { number => '555-0100', type => 'MOBILE' },
        ],
    });

    # Wire-format binary serialization
    my $bytes   = $person->serialize();
    my $decoded = Tutorial::Addressbook::Person->parse($bytes);
    print $decoded->name(), "\n";    # Ada Lovelace

    # Canonical ProtoJSON serialization
    my $json     = $person->to_json();
    my $from_js  = Tutorial::Addressbook::Person->from_json($json);

    # Human-readable Text Format
    my $text = $person->to_text();

    # Unblessed Perl HashRef projection
    my $hash = $person->to_perl();

=head1 DESCRIPTION

C<Protobuf> provides a modern, high-performance Protocol Buffers (proto2 and
proto3) runtime and C<protoc> code generator for Perl, backed by Google's
L<upb|https://github.com/protocolbuffers/protobuf/tree/main/upb> C library
(the same C kernel used by the official Python and Ruby Protocol Buffers
implementations).

When the compiled XS extension is available (the default), parsing,
serialization, ProtoJSON encoding/decoding, reflection, and arena memory
management execute at native C speed. If XS is disabled or unavailable, a
Pure-Perl fallback engine (L<Protobuf::Engine::PurePerl>) is selected
automatically.

=head1 COMPILING C<.proto> FILES

Installing C<Protobuf> installs the C<protoc-gen-perl-pb> compiler plugin.
Invoke C<protoc> as you would for Go, Python, Java, C++, or Ruby:

    protoc \
      --plugin=protoc-gen-perl-pb=$(which protoc-gen-perl-pb) \
      --perl-pb_out=lib \
      --perl-pb_opt=embed_descriptors \
      -I path/to/protos \
      path/to/protos/my_service.proto

=over 4

=item * C<embed_descriptors> - Embeds serialized C<FileDescriptorProto> metadata into the generated Perl module so descriptors self-register in L<Protobuf::DescriptorPool/generated_pool> on C<use>.

=item * C<generate_services> - Generates gRPC/REST service client stubs alongside message classes. For full CPAN distribution scaffolding (C<Makefile.PL>, tests, POD), see L<Module::Starter::Protobuf> (C<protobuf-starter>).

=back

=head1 GENERATED CODE REFERENCE

=head2 Packages and Class Names

A C<.proto> package C<foo.bar.v1> in file C<widget.proto> maps to Perl
namespace C<Foo::Bar::V1::Widget>, with message C<Item> generated as
C<Foo::Bar::V1::Widget::Item>.

=head2 Messages and Constructors

Generated message classes inherit from L<Protobuf::Message> and support:

=over 4

=item * C<< My::Message->new(\%fields) >> - Construct a message, coercing nested HashRefs, ArrayRefs, and enum names automatically.

=item * C<< My::Message->parse($bytes) >> (alias: C<decode>) - Deserialize binary protobuf wire format into a new message object.

=item * C<< My::Message->from_json($json_str) >> (alias: C<fromJSON>) - Parse canonical ProtoJSON into a new message object.

=item * C<< $msg->serialize() >> (alias: C<encode>) - Serialize to binary protobuf wire format.

=item * C<< $msg->to_json() >> (alias: C<toJSON>) - Serialize to canonical ProtoJSON (camelCase field names).

=item * C<< $msg->to_text() >> - Format as human-readable Protocol Buffers text format.

=item * C<< $msg->to_perl() >> - Project the message tree into plain Perl HashRefs/ArrayRefs.

=item * C<< $msg->merge_from($other) >> / C<< $msg->copy_from($other) >> / C<< $msg->parse_from($bytes) >> - Mutating merge, copy, and wire-format merge operations.

=back

=head2 Fields, Presence, Repeated Fields, Maps, and Enums

=over 4

=item * B<Scalar accessors:> C<< $msg->field() >> gets the value; C<< $msg->field($val) >> sets it. 64-bit integer fields preserve full 64-bit precision on 64-bit Perls.

=item * B<Explicit presence:> C<< $msg->has_field() >> and C<< $msg->clear_field() >> test and clear field presence (proto2 fields, proto3 C<optional> fields, submessages, and oneofs).

=item * B<Repeated fields:> Accessors return a tied ArrayRef supporting standard Perl operations (C<push>, C<pop>, C<shift>, indexing, iteration).

=item * B<Map fields:> Accessors return a tied HashRef supporting standard Perl hash operations (C<exists>, C<delete>, C<keys>, C<each>, C<as_hash>).

=item * B<Enums:> Accept either integer values or symbolic enum names (e.g., C<'MOBILE'>). Invalid enum names throw an exception.

=item * B<Unknown fields:> Preserved across parse/serialize roundtrips.

=back

=head1 WELL-KNOWN TYPES (WKTs)

Standard Google Protocol Buffers Well-Known Types are bundled in this
distribution under C<Google::Protobuf::*> with Perl helpers under
C<Protobuf::WKT::*>:

=over 4

=item * L<Google::Protobuf::Timestamp> / L<Protobuf::WKT::Timestamp>

=item * L<Google::Protobuf::Duration> / L<Protobuf::WKT::Duration>

=item * L<Google::Protobuf::Any> / L<Protobuf::WKT::Any>

=item * L<Google::Protobuf::Struct> / L<Protobuf::WKT::Struct>

=item * L<Google::Protobuf::FieldMask> / L<Protobuf::WKT::FieldMask>

=item * L<Google::Protobuf::Empty>, L<Google::Protobuf::Wrappers>, L<Google::Protobuf::Descriptor>

=back

=head1 DYNAMIC DESCRIPTORS & COMPATIBILITY

=over 4

=item * L<Protobuf::DescriptorPool> - Runtime descriptor registry (C<< Protobuf::DescriptorPool->generated_pool >> or isolated pools).

=item * L<Google::ProtocolBuffers::Dynamic> - Compatibility shim supporting C<load_file>, C<load_string>, C<map_package>, C<map_message>, C<encode>, and C<decode> backed by the upb engine.

=back

=head1 MEMORY MANAGEMENT & ARENAS

Messages allocate their backing C structures on a L<Protobuf::Arena>. Arenas
free all associated memory in O(1) when destroyed, avoiding per-field
deallocation overhead. Both heap-backed and tmpfs-backed arenas are supported.
XS objects implement C<CLONE_SKIP> for safe behavior under Perl ithreads.

=head1 ENGINE SELECTION & RUNTIME API

=head2 get_engine( $name )

    my $engine = Protobuf->get_engine();          # 'xs' (default) or 'pure_perl'
    my $pp     = Protobuf->get_engine('pure_perl');

Returns the active engine singleton (L<Protobuf::Engine::XS> or
L<Protobuf::Engine::PurePerl>). Falls back to PurePerl if XS is unavailable.

=head2 engine( $name )

Gets or sets the default engine singleton used by C<Protobuf>.

=head1 ENVIRONMENT VARIABLES

=over 4

=item * C<PROTOBUF_NO_XS> - Set to a true value to disable XS loading and force PurePerl mode.

=item * C<PROTOBUF_ENGINE> - Explicitly select C<xs> or C<pure_perl>.

=item * C<PROTOBUF_DEBUG> - Set to a true value to log XS loader diagnostics.

=back

=head1 SEE ALSO

L<Protobuf::Message>, L<Protobuf::DescriptorPool>, L<Protobuf::Arena>,
L<Google::ProtocolBuffers::Dynamic>, L<Module::Starter::Protobuf>,
L<Google::gRPC>, L<Google::Auth>,
L<https://protobuf.dev/>

=head1 SUPPORT AND BUG TRACKING

Please report any bugs or feature requests to the CPAN Bug Tracker at:

L<https://rt.cpan.org/Dist/Display.html?Queue=Protobuf>

Or via email to C<bug-Protobuf@rt.cpan.org>.

Source repository and issue tracker:

L<https://github.com/GoogleCloudPlatform/google-auth-library-perl>

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2026 Google LLC and contributors.

This distribution is licensed under the Apache License, Version 2.0 (vendored
C<upb> components are licensed under the BSD 3-Clause License).

=cut
