package Google::ProtocolBuffers::Dynamic;

use strict;
use warnings;
use Protobuf;
use Protobuf::DescriptorPool;
use File::Basename qw(dirname basename);
use File::Temp qw(tempfile);

our $VERSION = '0.14';

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        include_path => $opts{include_path} // ['.'],
        package_map  => {},
        message_map  => {},
        files        => [],
    }, $class;
    return $self;
}

sub load_file {
    my ($self, $file) = @_;
    push @{ $self->{files} }, $file;

    my $dir = dirname($file);
    my @inc = (@{ $self->{include_path} }, $dir);
    my %seen;
    @inc = grep { !$seen{$_}++ } @inc;

    my @inc_flags = map { '-I' . $_ } @inc;
    open my $ph, '-|', 'protoc', @inc_flags, '-o', '/dev/stdout', $file
        or die 'Failed to execute protoc: ' . $!;
    binmode $ph;
    local $/;
    my $bytes = <$ph>;
    close $ph;

    if (defined $bytes && length($bytes) > 0) {
        Protobuf::DescriptorPool->generated_pool->add_serialized_file_descriptor_set($bytes);
        my $base = basename($file);
        my $file_def = Protobuf::DescriptorPool->generated_pool->find_file_by_name($base)
                    // Protobuf::DescriptorPool->generated_pool->find_file_by_name($file);
        if ($file_def) {
            require Protobuf::ClassGenerator;
            my $proto_pkg = $file_def->get_package;
            if (my $perl_pkg = $self->{package_map}{$proto_pkg}) {
                my $count = $file_def->top_level_message_count;
                for my $i (0 .. $count - 1) {
                    my $mdef = $file_def->get_top_level_message($i);
                    Protobuf::ClassGenerator::_generate_recursively($mdef, $perl_pkg);
                }
            } else {
                Protobuf::ClassGenerator->generate_for_file($file_def);
            }
        }
        return 1;
    }
    die "protoc failed to generate binary descriptor set for '$file'";
}

sub load_string {
    my ($self, $string, %opts) = @_;
    my ($fh, $tmp_file) = tempfile('proto_XXXXXX', SUFFIX => '.proto', TMPDIR => 1, UNLINK => 1);
    print {$fh} $string;
    close $fh;

    my $ret = eval { $self->load_file($tmp_file) };
    my $err = $@;
    unlink $tmp_file if -f $tmp_file;
    die $err if $err;
    return $ret;
}

sub resolve_references {
    return 1;
}

sub map_package {
    my ($self, $proto_pkg, $perl_pkg, %opts) = @_;
    $self->{package_map}{$proto_pkg} = $perl_pkg;

    my $pool = $self->{pool} // Protobuf::DescriptorPool->generated_pool;
    for my $file_name (@{ $self->{files} }) {
        my $base = basename($file_name);
        my $file_def = $pool->find_file_by_name($base) // $pool->find_file_by_name($file_name);
        if ($file_def) {
            my $pkg1 = $file_def->get_package; $pkg1 =~ s/^\.//;
            my $pkg2 = $proto_pkg; $pkg2 =~ s/^\.//;
            if ($pkg1 eq $pkg2) {
                my $count = $file_def->top_level_message_count;
                require Protobuf::ClassGenerator;
                for my $i (0 .. $count - 1) {
                    my $mdef = $file_def->get_top_level_message($i);
                    Protobuf::ClassGenerator::_generate_recursively($mdef, $perl_pkg);
                }
            }
        }
    }
    return 1;
}

sub map_message {
    my ($self, $proto_msg, $perl_pkg, %opts) = @_;
    $self->{message_map}{$proto_msg} = $perl_pkg;
    return 1;
}

sub _resolve_class {
    my ($self, $type) = @_;
    if (my $mapped = $self->{message_map}{$type}) {
        return $mapped;
    }
    for my $proto_pkg (keys %{ $self->{package_map} }) {
        if ($type =~ /^\Q$proto_pkg\E\.(.*)$/) {
            my $rest = $1;
            my $perl_pkg = $self->{package_map}{$proto_pkg};
            my $class = "${perl_pkg}::${rest}";
            $class =~ s/\./::/g;
            if (!$class->can('new')) {
                my $pool = $self->{pool} // Protobuf::DescriptorPool->generated_pool;
                my $mdef = $pool->find_message_by_name($type) // $pool->find_message_by_name(".$type");
                if ($mdef) {
                    require Protobuf::ClassGenerator;
                    Protobuf::ClassGenerator::_generate_recursively($mdef, $perl_pkg);
                }
            }
            return $class;
        }
    }
    my $pool = $self->{pool} // Protobuf::DescriptorPool->generated_pool;
    my $mdef = $pool->find_message_by_name($type) // $pool->find_message_by_name(".$type");
    if ($mdef) {
        require Protobuf::ClassGenerator;
        return Protobuf::ClassGenerator->generate_for_message($mdef);
    }
    my $class = $type;
    $class =~ s/\./::/g;
    return $class;
}

sub encode {
    my ($self, $type, $data) = @_;
    my $class = $self->_resolve_class($type);
    my $msg = (ref $data eq $class) ? $data : $class->new(%$data);
    return $msg->encode();
}

sub decode {
    my ($self, $type, $bytes) = @_;
    my $class = $self->_resolve_class($type);
    return $class->parse($bytes);
}

sub encode_json {
    my ($self, $type, $data) = @_;
    my $class = $self->_resolve_class($type);
    my $msg = ref $data eq $class ? $data : $class->new(%$data);
    return $msg->to_json();
}

sub decode_json {
    my ($self, $type, $json_str) = @_;
    my $class = $self->_resolve_class($type);
    return $class->from_json($json_str);
}

1;

__END__

=head1 NAME

Google::ProtocolBuffers::Dynamic - Dynamic Protocol Buffers binding layer compatible with upb backend

=head1 SYNOPSIS

    use Google::ProtocolBuffers::Dynamic;

    my $dynamic = Google::ProtocolBuffers::Dynamic->new();
    $dynamic->load_file("person.proto");
    $dynamic->map_package("foo.bar", "My::Perl::Package");

    my $bytes = $dynamic->encode("My::Perl::Package::Person", { name => "Alice", id => 123 });
    my $msg   = $dynamic->decode("My::Perl::Package::Person", $bytes);

=head1 DESCRIPTION

C<Google::ProtocolBuffers::Dynamic> provides a compatibility layer modeled on
the CPAN C<Google::ProtocolBuffers::Dynamic> API, compiling C<.proto> schemas
on demand via C<protoc> into L<Protobuf::DescriptorPool> and generating Perl
message classes backed by the L<Protobuf> C<upb> / Pure-Perl engine.

=head1 METHODS

=head2 new(%opts)

    my $dynamic = Google::ProtocolBuffers::Dynamic->new(
        include_path => ['protos/', '/usr/include'],
    );

Creates a new dynamic loader instance. Accepts an optional C<include_path>
arrayref passed to C<protoc -I>.

=head2 load_file($path)

Compiles C<$path> with C<protoc>, registers its C<FileDescriptorSet> in
L<Protobuf::DescriptorPool/generated_pool>, and generates Perl message classes.

=head2 load_string($proto_source)

Writes C<$proto_source> to a temporary C<.proto> file and loads it via
L</load_file>.

=head2 map_package($proto_package, $perl_package)

Maps a Protobuf package name (e.g. C<foo.bar>) to a Perl namespace prefix
(e.g. C<My::Perl::Package>) and generates message classes for any matching
loaded files.

=head2 map_message($proto_message, $perl_class)

Maps a specific fully qualified Protobuf message name to a Perl class name.

=head2 resolve_references()

Compatibility no-op returning C<1>; references are resolved automatically
during L</load_file>.

=head2 encode($type, $data) / decode($type, $bytes)

Serializes a Perl hashref or message object of C<$type> to binary Protobuf
wire format, or decodes binary wire bytes into a message object.

=head2 encode_json($type, $data) / decode_json($type, $json)

Serializes a message of C<$type> to Proto3 canonical JSON, or parses JSON into
a message object.

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::DescriptorPool>, L<Protobuf::ClassGenerator>

=head1 SUPPORT AND BUG TRACKING

Please report bugs or feature requests to the CPAN Bug Tracker at:

L<https://rt.cpan.org/Dist/Display.html?Queue=Protobuf>

=head1 AUTHOR

C.J. Collier E<lt>cjac@colliertech.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Google LLC. Apache License, Version 2.0.

=cut
