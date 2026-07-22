package Google::ProtocolBuffers::Dynamic;

use strict;
use warnings;
use Protobuf;
use Protobuf::DescriptorPool;
use File::Basename qw(dirname basename);

our $VERSION = '0.10';

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

    my @inc_flags = map { "-I$_" } @inc;
    my $cmd = "protoc @inc_flags -o /dev/stdout \"$file\"";
    open my $ph, '-|', $cmd or die "Failed to execute protoc: $!";
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
    my $tmp_file = 'tmp_' . time() . '_' . int(rand(100000)) . '.proto';
    open my $fh, '>', $tmp_file or die "Cannot write temp proto file: $!";
    print $fh $string;
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

C<Google::ProtocolBuffers::Dynamic> provides a high-performance compatibility layer mapping
dynamically parsed C<.proto> files directly into Perl classes via the UPB engine.

=head1 SUPPORT AND BUG TRACKING

Please report bugs or feature requests to the CPAN Bug Tracker at:

L<https://rt.cpan.org/Dist/Display.html?Queue=Protobuf>

=head1 AUTHOR

C.J. Collier E<lt>cjac@colliertech.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Google LLC. Apache License, Version 2.0.

=cut
