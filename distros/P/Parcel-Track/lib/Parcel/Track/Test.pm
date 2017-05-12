package Parcel::Track::Test;
# ABSTRACT: Parcel::Track driver for the Regional-Class Test

use utf8;

use Moo;

our $VERSION = '0.005';

with 'Parcel::Track::Role::Base';

use Encode qw( encode_utf8 );

has foo => ( is => 'ro' );
has bar => ( is => 'ro' );

our $URI = 'http://test?tracking_number=%s';

sub BUILDARGS {
    my ( $class, @args ) = @_;

    my %params;
    if ( ref $args[0] eq 'HASH' ) {
        %params = %{ $args[0] };
    }
    else {
        %params = @args;
    }
    $params{id} =~ s/\D//g;

    return \%params;
}

sub uri { sprintf( $URI, $_[0]->id ) }

sub track {
    my $self = shift;

    my %result = (
        from   => encode_utf8(q{Keedi Kim}),
        to     => encode_utf8(q{CPAN}),
        result => encode_utf8(q{2015.01.27 Shipping Completed}),
        htmls  => [
            encode_utf8(q{<div>dummy 1</div>}), encode_utf8(q{<div>dummy 2</div>}),
            encode_utf8(q{<div>dummy 3</div>}),
        ],
        descs => [
            encode_utf8(q{2015.01.24. 17:34 Receipt}),
            encode_utf8(q{2015.01.25. 09:00 Gwangjin Branch}),
            encode_utf8(q{2015.01.25. 13:01 Loading}),
            encode_utf8(q{2015.01.26. 15:23 Unloading}),
            encode_utf8(q{2015.01.27. 10:45 Gangdong Branch}),
            encode_utf8(q{2015.01.27. 16:13 Shipping Completed}),
        ],
    );

    return \%result;
}

sub clear { 1 }

1;

#
# This file is part of Parcel-Track
#
# This software is copyright (c) 2015 by Keedi Kim.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

__END__

=pod

=encoding UTF-8

=head1 NAME

Parcel::Track::Test - Parcel::Track driver for the Regional-Class Test

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    # create a testing tracker
    my $tracker = Parcel::Track->new( 'Test', '64537-0301-2020' );

    # get the tracking number
    say $tracker->id;

    # get the tracking information official uri
    say $tracker->uri;

    # get the tracking information
    my $info = $tracker->track;
    say $info->{from};
    say $info->{to};
    say $info->{result};
    say for @{ $info->{descs} };
    say for @{ $info->{htmls} };

=head1 DESCRIPTION

This module is a Parcel::Track driver for the International-Class Test.
Except for the name, it is otherwise identical to L<Parcel::Track::KR::Test>.

=head1 ATTRIBUTES

=head2 id

=head1 METHODS

=head2 uri

=head2 track

=head2 foo

=head2 bar

=head2 clear

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

김도형 - Keedi Kim <keedi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
