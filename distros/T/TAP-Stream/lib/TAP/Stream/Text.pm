package TAP::Stream::Text;
$TAP::Stream::Text::VERSION = '0.44';
# ABSTRACT: Create a TAP text object.

use Moose;
use namespace::autoclean;
with qw(TAP::Stream::Role::ToString);

has 'text' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub to_string { shift->text }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TAP::Stream::Text - Create a TAP text object.

=head1 VERSION

version 0.44

=head1 SYNOPSIS

    my $tap = <<'END';
    ok 1 - some test
    ok 2 - another test
    1..2
    END
    
    my $text = TAP::Stream::Text->new(
        name => $what_this_tap_tested, # String
        text => $tap,
    );

=head1 DESCRIPTION

This module is used to create a named chunk of TAP text representing a
complete stream, including the plan.

=head1 METHODS

=head2 C<new>

    my $text = TAP::Stream::Text->new(
        name => $some_name,
        text => $tap,
    );
    say $text->name;         # return name
    say $text->to_string;    # return text

=head2 C<name>

    my $name = $stream->name;

A read/write string accessor.

Returns the name of the stream. Default to C<Unnamed TAP stream>. If you add
this stream to another stream, consider naming this stream for a more useful
TAP output. This is used by C<TAP::Stream> to create the subtest summary line:

        1..2
        ok 1 - some test
        ok 2 - another test
    ok 1 - this is $tap->name

=head2 C<text>

A read-only accessor for the text passed to the constructor.

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
