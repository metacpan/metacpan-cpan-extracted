package Net::LDAP::Batch::Action::Add;
use strict;
use warnings;
use Carp;
use base qw( Net::LDAP::Batch::Action );

our $VERSION = '0.02';

__PACKAGE__->mk_accessors(qw( dn attr ));

=head1 NAME

Net::LDAP::Batch::Action::Add - add entry to LDAP server

=head1 SYNOPSIS

 use Net::LDAP::Batch::Action::Add;
 my $action = Net::LDAP::Batch::Action->new(
            {
                ldap => $net_ldap_object,
                dn   => 'name=foo,dc=company,dc=com',
                attr => [
                        name => 'foo',
                        mail => 'foo@company.com'
                        ],
            });
 $action->execute or $action->rollback;
        

=head1 DESCRIPTION

This is a base class for batch actions.

B<NOTE:> Net::LDAP::Batch::Action objects will croak() if anything
unusual happens. This approach assumes that Catastrophic Failure is a
Good Thing. So use eval() if you need to catch exceptions.

=head1 METHODS

=head2 init

Overrides base method to confirm that dn() and attr() are set.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if ( !$self->dn ) {
        croak "dn required";
    }
    if (   !$self->attr
        or !ref( $self->attr )
        or ref( $self->attr ) ne 'ARRAY' )
    {
        croak "attr array ref required";
    }
    return $self;
}

=head2 execute

Creates a Net::LDAP::Entry object, adds the dn() and attr()
values to it, then adds to the LDAP server.

=cut

sub execute {
    my $self = shift;
    if ( $self->complete ) {
        croak "action already flagged as complete";
    }
    my $dn   = $self->dn   or croak "dn required";
    my $attr = $self->attr or croak "attr required";

    carp "adding $dn: " . Data::Dump::dump($attr) if $self->debug;
    my $entry = Net::LDAP::Entry->new;
    $entry->dn($dn);
    $entry->add(@$attr);
    my $msg = $self->ldap->add($entry);
    if ( $msg->code ) {
        croak "failed to add $dn: " . $self->get_ldap_err($msg);
    }
    $self->entry($entry);
    $self->complete(1);
    return 1;
}

=head2 rollback

Deletes the entry added in execute().

=cut

sub rollback {
    my $self = shift;
    return 0 unless $self->complete;

    my $dn = $self->dn or croak "dn required to rollback";
    carp "rolling back $dn" if $self->debug;
    my $msg = $self->ldap->delete($dn);
    if ( $msg->code ) {
        croak "failed to rollback $dn: " . $self->get_ldap_err($msg);
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


