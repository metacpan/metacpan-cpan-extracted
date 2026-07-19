=encoding UTF-8

=head1 NAME

Protobuf - High-performance Google Protocol Buffers implementation

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    use Protobuf;

    # Load descriptors (typically done by generated code)
    my $pool = Protobuf::DescriptorPool->generated_pool;

    # Example: Create a new message (assuming My::Message is generated)
    # my $msg = My::Message->new({ name => 'foo', value => 123 });

    # Serialize
    # my $binary = $msg->serialize;

    # Parse
    # my $decoded = My::Message->parse($binary);

=head1 DESCRIPTION

This module provides a Perl interface to Google Protocol Buffers, leveraging the high-performance C library L<upb|https://github.com/protocolbuffers/upb>. The implementation aims for speed, efficiency, and close alignment with the features and behaviors of the official Python UPB-based extension.

=head1 SEE ALSO

L<Protobuf::Message>, L<Protobuf::DescriptorPool>, L<Protobuf::Arena>

=head1 AUTHOR

C.J. Collier <cjac@google.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Google LLC.

This is free software; you can redistribute it and/or modify it under
the terms of the BSD 3-Clause License.

=cut

package Protobuf;

use strict;
use warnings;
use Log::Any qw($log);

our $VERSION = '0.09';

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
    require "$file.pm";

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

=head1 NAME

Protobuf - Fast Protocol Buffers implementation for Perl using upb

=head1 SYNOPSIS

    use Protobuf;

=head1 DESCRIPTION

Protobuf provides high-performance Protocol Buffers serialization and deserialization
for Perl using the Google upb C library.

=head1 SUPPORT AND BUG TRACKING

Please report any bugs or feature requests to the CPAN Bug Tracker at:

L<https://rt.cpan.org/Dist/Display.html?Queue=Protobuf>

Or via email to C<bug-Protobuf@rt.cpan.org>.

You can also visit the GitHub repository at:

L<https://github.com/GoogleCloudDataproc/google-auth-library-perl>

=head1 AUTHOR

C.J. Collier E<lt>cjac@colliertech.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Google LLC. Apache License, Version 2.0.

=cut
