package MooseX::Storage::Engine::IO::AtomicFile;
# ABSTRACT: The actual atomic file storage mechanism.

our $VERSION = '0.52';

use Moose;
use IO::AtomicFile;
use Carp 'confess';
use namespace::autoclean;

extends 'MooseX::Storage::Engine::IO::File';

sub store {
    my ($self, $data) = @_;
    my $fh = IO::AtomicFile->new($self->file, 'w')
        || confess "Unable to open file (" . $self->file . ") for storing : $!";

    # TODO ugh! this is surely wrong and should be fixed.
    $fh->binmode(':utf8') if utf8::is_utf8($data);
    print $fh $data;
    $fh->close()
        || confess "Could not write atomic file (" . $self->file . ") because: $!";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage::Engine::IO::AtomicFile - The actual atomic file storage mechanism.

=head1 VERSION

version 0.52

=head1 DESCRIPTION

This provides the actual means to store data to a file atomically.

=head1 METHODS

=over 4

=item B<file>

=item B<load>

=item B<store ($data)>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Storage>
(or L<bug-MooseX-Storage@rt.cpan.org|mailto:bug-MooseX-Storage@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris.prather@iinteractive.com>

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
