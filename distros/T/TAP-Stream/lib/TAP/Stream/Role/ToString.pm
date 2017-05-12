package TAP::Stream::Role::ToString;
$TAP::Stream::Role::ToString::VERSION = '0.44';
# ABSTRACT: Named strings for TAP::Stream and TAP::Stream::Text

use Moose::Role;

requires qw(
  to_string
);
has 'name' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Unnamed TAP stream',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TAP::Stream::Role::ToString - Named strings for TAP::Stream and TAP::Stream::Text

=head1 VERSION

version 0.44

=head1 SYNOPSIS

    package TAP::Stream;
    use Moose;
    with qw(TAP::Stream::Role::ToString);

    ...

    1;

=head1 REQUIRES

=head2 C<to_string>

We don't know how the consumer of this role will produce a string, so we
require a C<to_string> method.

=head1 PROVIDES

=head2 C<name>

This is a string attribute, suitable for use in the constructor. It defaults
to C<Unnamed TAP stream>. It is C<rw> in case you create an unnamed stream and
later need to add it to another stream and want to name it.

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
