package SWISH::Prog::Xapian::InvIndex;
use strict;
use warnings;
use base qw( SWISH::Prog::InvIndex );
use Carp;
use Search::Xapian ':db';
__PACKAGE__->mk_ro_accessors(qw( xdb ));

our $VERSION = '0.09';

=head1 NAME

SWISH::Prog::Xapian::InvIndex - Swish3 Xapian backend InvIndex

=head1 SYNOPSIS

 # see SWISH::Prog::InvIndex
 
=cut

=head1 METHODS

Only new and overridden methods are documented here. See
the L<SWISH::Prog::InvIndex> documentation.

=head2 open

Open a WriteableDatabase and calls begin_transaction() on the
database handle.

=cut

sub open {
    my $self = shift;
    $self->{xdb}
        = Search::Xapian::WritableDatabase->new( "$self",
        $self->clobber ? DB_CREATE_OR_OVERWRITE : DB_CREATE_OR_OPEN )
        or croak "can't create Xapian WritableDatabase $self: $!";
    $self->{xdb}->begin_transaction();

    #warn "xdb open for $self->{xdb}";
}

=head2 open_ro

Open a Database.

=cut

sub open_ro {
    my $self = shift;
    $self->{xdb} = Search::Xapian::Database->new("$self")
        or croak "can't open Xapian Database $self: $!";

    #warn "xdb open_ro for $self->{xdb}";
}

=head2 close

Calls commit_transaction() if the xdb() isa WriteableDatabase.

=cut

sub close {
    my $self = shift;
    $self->{xdb}->commit_transaction()
        if $self->{xdb}->can('commit_transaction');
    $self->{xdb}->close() if $self->{xdb}->can('close');

    #warn "xdb close for $self->{xdb}";
}

=head2 xdb

Returns the internal Search::Xapian::Database object.

=cut

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan dot org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-swish-prog-xapian at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog-Xapian>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog::Xapian

You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog-Xapian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog-Xapian>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog-Xapian>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog-Xapian>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
