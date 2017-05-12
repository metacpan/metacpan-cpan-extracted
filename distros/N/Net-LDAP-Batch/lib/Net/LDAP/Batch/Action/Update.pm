package Net::LDAP::Batch::Action::Update;
use strict;
use warnings;
use Carp;
use base qw( Net::LDAP::Batch::Action );

our $VERSION = '0.02';

__PACKAGE__->mk_accessors(qw( before search replace delete dn prev_dn ));

=head1 NAME

Net::LDAP::Batch::Action::Update - update entry on LDAP server

=head1 SYNOPSIS

 use Net::LDAP::Batch::Action::Update;
 my $action = Net::LDAP::Batch::Action::Update->new(
            {
                ldap => $net_ldap_object,
                search => [
                        base    => 'name=foo,dc=company,dc=com'
                        scope   => 'base'
                    ],
                replace => {
                        mail    => 'bar@company.com'
                    },
                delete  => {
                        someAttr => ['val1', 'val2'],
                    },
            });
 $action->execute or $action->rollback;
        

=head1 DESCRIPTION

Updates an entry from a LDAP server, restoring it on failure of any kind.

=head2 init

Override base method to check that search() param is set to an array ref.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if ( !$self->entry ) {
        if (   !$self->search
            or !ref( $self->search )
            or ref( $self->search ) ne 'ARRAY' )
        {
            croak "search array ref required";
        }
    }
    return $self;
}

=head2 execute

If entry() is set, will simply call update() on the Net::LDAP::Entry
and croak on any error.

Otherwise, uses search(), replace() and (optionally) delete() to
instatiate a Net::LDAP::Entry object, alter its attributes and write
it back to the LDAP server.

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

        carp "updating $where" if $self->debug;

        if ( $self->dn && ref( $self->dn ) ne 'HASH' ) {
            croak "dn() must be a hash ref";
        }
        if ( $self->replace && ref( $self->replace ) ne 'HASH' ) {
            croak "replace() must be a hash ref";
        }
        if ( $self->delete and ref( $self->delete ) ne 'HASH' ) {
            croak "delete() must be a hash ref";
        }

        if ( !$self->replace and !$self->dn and !$self->delete ) {
            croak "nothing to update for $where";
        }

        my $msg = $self->ldap->search(@$search);
        if ( $msg->count > 0 ) {
            $entry = $msg->entry(0);
            $self->before( $entry->clone );    # before
            if ( $self->replace ) {
                my $replace = $self->replace;
                for my $key ( sort keys %$replace ) {
                    my $new = $replace->{$key};
                    my @old = $entry->get_value($key);
                    carp "updating $key from "
                        . Data::Dump::dump( \@old ) . " -> "
                        . Data::Dump::dump($new)
                        if $self->debug;
                    $entry->replace( $key => $new );
                }
            }
            if ( $self->delete ) {
                for my $key ( sort keys %{ $self->delete } ) {
                    carp "deleting $key from entry" if $self->debug;
                    $entry->delete( $key => $self->delete->{$key} );
                }
            }
            if ( $self->dn ) {

                $self->prev_dn( $entry->dn );

                if ( $self->debug ) {
                    carp "changing dn from "
                        . $self->prev_dn . " to "
                        . Data::Dump::dump( $self->dn );
                }

                $entry->changetype('moddn');
                for my $attr ( keys %{ $self->dn } ) {
                    $entry->replace( $attr => $self->dn->{$attr} );
                }
            }
            $self->entry($entry);    # after
        }
        else {

            # no match for search.
            # in SQL, this would just be a no-op, since WHERE failed.
            # but here we assume that caller expects the object to exist.
            croak "update search for $where failed to match";

        }
    }

    my $msg = $entry->update( $self->ldap );
    if ( $msg->code ) {
        croak "failed to update entry: " . $self->get_ldap_err($msg);
    }

    $self->complete(1);
    return 1;
}

=head2 rollback

Cannot rollback an entry if you did not specify a search() and replace()
value (i.e., if you set entry() explicitly prior to execute).

=cut

sub rollback {
    my $self = shift;
    return 0 unless $self->complete;

    my $before = $self->before;
    if ( !$before or !$before->isa('Net::LDAP::Entry') ) {
        croak "no original Net::LDAP::Entry to rollback to in update";
    }

    my $after = $self->entry;
    if ( !$after or !$after->isa('Net::LDAP::Entry') ) {
        croak "no updated Net::LDAP::Entry to revert";
    }

    my $search  = $self->search  or croak "search required";
    my $replace = $self->replace or croak "replace required";
    my $where = Data::Dump::dump($search);

    carp "rollback update for $where" if $self->debug;

    # put the old values back.
    for my $key ( sort keys %$replace ) {
        my $old = $before->get_value($key);
        $after->replace( $key => $old );
    }

    # revert any DN changes -- TODO test this!!
    #if ( $self->dn ) {
    #        $after->dn( $self->prev_dn );
    #        $after->changetype('moddn');
    #        for my $attr ( keys %{ $self->dn } ) {
    #            $after->replace( $attr => $self->dn->{$attr} );
    #        }
    #    }

    # save the old values
    my $msg = $after->update( $self->ldap );
    if ( $msg->code ) {
        croak "failed to rollback $where: " . $self->get_ldap_err($msg);
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

Net::LDAP::Batch

=cut
