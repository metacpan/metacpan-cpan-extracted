package Net::LDAP::Batch::Action;
use strict;
use warnings;
use Carp;
use base qw( Class::Accessor::Fast );

our $VERSION = '0.02';

__PACKAGE__->mk_accessors(qw( ldap entry complete debug ));

=head1 NAME

Net::LDAP::Batch::Action - base class for LDAP actions

=head1 SYNOPSIS

 use Net::LDAP::Batch::Action;
 my $action = Net::LDAP::Batch::Action->new(
            {
                ldap => $net_ldap_object,
            });
 $action->execute or $action->rollback;
        

=head1 DESCRIPTION

This is a base class for batch actions.

B<NOTE:> Net::LDAP::Batch::Action objects will croak() if anything
unusual happens. This approach assumes that Catastrophic Failure is a
Good Thing. So use eval() if you need to catch exceptions.

=head1 METHODS

=head2 new( I<hash_ref> )

Overrides base Class::Accessor::Fast constructor to call init().

This class defines the following accessor methods, all of which
can be set via new() or by themselves.

=over

=item

ldap

=item

entry

=item

complete

=item

debug

=back

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->init;
    return $self;
}

=head2 init

Confirms that the ldap() accessor returns a Net::LDAP-derived object.

=cut

sub init {
    my $self = shift;
    if ( !$self->ldap or !$self->ldap->isa('Net::LDAP') ) {
        croak "Net::LDAP object required";
    }
    $self->debug(1) if $ENV{PERL_DEBUG};
    return $self;
}

=head2 execute

Perform the action. Default behaviour is to croak indicating
you must override the method in your subclass.

=cut

sub execute { croak "must override execute()" }

=head2 rollback

Undo the action. Default behaviour is to croak indicating you
must override the method in your subclass.

=cut

sub rollback { croak "must override rollback()" }

=head2 get_ldap_err( I<ldap_msg> )

Returns the stringified error message for the I<ldap_msg> object.

=cut

sub get_ldap_err {
    my $self = shift;
    my $msg  = shift or croak "ldap_msg required";
    my $str  = "\n"
        . join( "\n",
        "Return code: " . $msg->code,
        "Message: " . $msg->error_name,
        " :" . $msg->error_text,
        "MessageID: " . $msg->mesg_id,
        "DN: " . $msg->dn,
        ) . "\n";
    return $str;
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

Net::LDAP::Batch

=cut
