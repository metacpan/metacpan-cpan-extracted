package STIX::Common::Binary;

use 5.010001;
use strict;
use warnings;
use utf8;

use overload '""' => \&to_string, fallback => 1;

use Carp;
use MIME::Base64;

use Moo;

around BUILDARGS => sub {

    my ($orig, $class, @args) = @_;

    return {value => $args[0]} if @args == 1;
    return $class->$orig(@args);

};

my $BASE64_REGEXP = qr{^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{4}|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)$};

has value => (
    is     => 'rw',
    isa    => sub { Carp::croak 'MUST be base64-encoded string' unless $_[0] =~ /$BASE64_REGEXP/ },
    coerce => sub { _parse($_[0]) }
);

sub _parse {

    my $bin = shift;

    return $bin if $bin =~ /$BASE64_REGEXP/;
    return encode_base64($bin, '');

}

sub to_string { shift->value }
sub TO_JSON   { shift->value }


1;

=encoding utf-8

=head1 NAME

STIX::Common::Binary - Binary type

=head1 SYNOPSIS

    use STIX::Common::Binary;

    my $bin_object = STIX::Common::Binary->new(value => $bin);

    say $bin_object; # base64-encoded string


=head1 DESCRIPTION

The binary data type represents a sequence of bytes. In order to allow pattern
matching on custom objects, for all properties that use the binary type, the
property name MUST end with '_bin'.

=head2 PROPERTIES

=over

=item value

=back

=head2 HELPERS

=over

=item $binary->TO_JSON

Helper for JSON encoders.

=item $binary->to_string

Encode the object in JSON.

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-STIX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-STIX>

    git clone https://github.com/giterlizzi/perl-STIX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
