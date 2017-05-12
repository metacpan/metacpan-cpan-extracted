package Net::LDAP::Batch::Action::Delete;
use strict;
use warnings;
use Carp;
use base qw( Net::LDAP::Batch::Action );

our $VERSION = '0.02';

__PACKAGE__->mk_accessors(qw( search ));

=head1 NAME

Net::LDAP::Batch::Action::Delete - delete entry from LDAP server

=head1 SYNOPSIS

 use Net::LDAP::Batch::Action::Delete;
 my $action = Net::LDAP::Batch::Action::Delete->new(
            {
                ldap => $net_ldap_object,
                search => [
                        base    => 'name=foo,dc=company,dc=com'
                        scope   => 'base'
                        ],
            });
 $action->execute or $action->rollback;
        

=head1 DESCRIPTION

Deletes an entry from a LDAP server, restoring it on failure of any kind.

=head1 METHODS

=head2 init

Override base method to check that search() param is set to an array ref.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if ( $self->search
        and ref( $self->search ) ne 'ARRAY' )
    {
        croak "search must be an ARRAY ref";
    }
    return $self;
}

=head2 execute

Perform the action. Will croak() if search() fails to match.

=cut

sub execute {
    my $self = shift;
    my $entry;
    if ( $self->entry ) {
        $entry = $self->entry;
    }
    else {

        my $search = $self->search or croak "search required";
        my $where = Data::Dump::dump($search);

        carp "deleting $where" if $self->debug;

        my $msg = $self->ldap->search(@$search);
        if ( $msg->count > 0 ) {
            $entry = $msg->entry(0);
        }
        else {

            # no match for search.
            # in SQL, this would just be a no-op, since WHERE failed.
            # but here we assume that caller expects the object to exist.
            croak "delete search failed to match $where:\n"
                . $self->get_ldap_err($msg);
        }

    }
    $self->entry( $entry->clone );
    $entry->delete;
    my $msg = $entry->update( $self->ldap );
    if ( $msg->code ) {
        croak "failed to delete entry: " . $self->get_ldap_err($msg);
    }

    $self->complete(1);
    return 1;
}

=head2 rollback

Revert the deletion by calling ldap->add for the original Net::LDAP::Entry
object.

=cut

sub rollback {
    my $self = shift;
    return 0 unless $self->complete;

    if ( !$self->entry ) {
        croak "cannot rollback deleted entry - no entry cached";
    }

    carp "rolling back delete" if $self->debug;

    my $entry = $self->entry;
    my $msg   = $self->ldap->add($entry);
    if ( $msg->code ) {
        croak "failed to rollback deletion of entry: "
            . $self->get_ldap_err($msg);
    }

    $self->complete(0);
    return 1;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-ldap-batch at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-Batch>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::Batch

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LDAP-Batch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LDAP-Batch>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-Batch>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LDAP-Batch>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT

Copyright 2008 by the Regents of the University of Minnesota.
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Net::LDAP

=cut
