package SBOM::CycloneDX::Timestamp;

use 5.010001;
use strict;
use warnings;
use utf8;

use Carp;
use Time::Piece;

use overload '""' => \&to_string, fallback => 1;

use Moo;

around BUILDARGS => sub {

    my ($orig, $class, @args) = @_;

    return {value => $args[0]} if @args == 1;
    return $class->$orig(@args);

};

has value => (is => 'rw', default => sub { Time::Piece->new }, coerce => sub { _parse($_[0]) });

my @PATTERNS = (
    ['%Y-%m-%dT%H:%M:%S', qr/(\d{4}-\d{2}-\d{2}[T]\d{2}:\d{2}:\d{2})\.\d+Z/],
    ['%Y-%m-%dT%H:%M:%S', qr/(\d{4}-\d{2}-\d{2}[T]\d{2}:\d{2}:\d{2})/],
    ['%Y-%m-%d %H:%M:%S', qr/(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})/],
    ['%Y-%m-%d',          qr/(\d{4}-\d{2}-\d{2})/],
);

sub _parse {

    my $datetime = shift;

    return $datetime if (ref $datetime eq 'Time::Piece');

    return $datetime->value if ($datetime->isa('SBOM::CycloneDX::Timestamp'));

    return Time::Piece->new unless $datetime;

    return Time::Piece->new($datetime) if ($datetime =~ /^([0-9]+)$/);
    return Time::Piece->new            if ($datetime eq 'now');

    foreach my $pattern (@PATTERNS) {
        my ($format, $regexp) = @{$pattern};
        return Time::Piece->strptime($1, $format) if ($datetime =~ /$regexp/);
    }

    Carp::carp 'Malformed timestamp';

    return Time::Piece->new;

}

sub to_string { shift->TO_JSON }

sub TO_JSON { shift->value->datetime . '.000Z' }

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Timestamp - Timestamp representation for CycloneDX

=head1 SYNOPSIS

    SBOM::CycloneDX::Timestamp->new('2025-01-01');

    SBOM::CycloneDX::Timestamp->new('2025-01-01 00:00:00');

    SBOM::CycloneDX::Timestamp->new('2025-01-01T00:00:00');

    SBOM::CycloneDX::Timestamp->new(Time::Piece->new);


=head1 DESCRIPTION

L<SBOM::CycloneDX::Timestamp> provides represents the timestamp for L<SBOM::CycloneDX>.

=head2 METHODS

=over

=item SBOM::CycloneDX::Timestamp->new( %PARAMS )

=item $ts->value

Return L<Time::Piece> object.

=item $ts->to_string

=item $ts->TO_JSON

Return timestamp in JSON format.

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
