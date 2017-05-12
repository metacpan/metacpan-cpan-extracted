package SVN::Dump::Text;

use strict;
use warnings;

my $NL = "\012";

# blessed string reference
sub new {
    my ( $class, @args ) = @_;
    return bless \( join '', @args ), $class;
}

sub set {
    my ( $self, $text ) = @_;
    $$self = $text;
}
sub get { ${ $_[0] } }
*as_string = \&get;

sub digest {
    my ( $self, $algo ) = @_;
    return eval {
        require Digest;
        Digest->new( uc $algo )->add($$self)->hexdigest;
    };
}

1;

__END__

=head1 NAME

SVN::Dump::Text - A text block from a svn dump

=head1 SYNOPSIS

    # SVN::Dump::Text objects are returned by the read_text_block()
    # method of SVN::Dump::Reader

=head1 DESCRIPTION

A SVN::Dump::Text object represents the text of a
SVN dump record.

=head1 METHODS

The following methods are available:

=over 4

=item new( $text )

Create a new SVN::Dump::Text object, initialised with the given text.

=item get()

Return the text of the SVN::Dump::Text object.

=item set( $text )

Set the text of the SVN::Dump::Text object.

=item as_string()

Return a string representation of the text block.

=item digest( $algo )

Return a digest of the text computed with the C<$algo> algorithm in
hexadecimal form. See the L<Digest> module for valid values of C<$algo>.

Return C<undef> if the digest algorithm is not supported.

=back

=head1 SEE ALSO

L<SVN::Dump::Reader>, L<SVN::Dump::Record>.

=head1 COPYRIGHT

Copyright 2006-2013 Philippe Bruhat (BooK), All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
