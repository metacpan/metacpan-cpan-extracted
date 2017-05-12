package Net::LDAP::Class::Iterator;
use strict;
use warnings;
use base qw( Rose::Object );
use Carp;
use Data::Dump qw( dump );
use Net::LDAP::Class::MethodMaker (
    'scalar' => [qw( ldap base_dn page_size filter class )], );
use Net::LDAP::Control::Paged;
use Net::LDAP::Constant qw( LDAP_CONTROL_PAGED );

our $VERSION = '0.27';

=head1 NAME

Net::LDAP::Class::Iterator - iterate over Net::LDAP::Class objects

=head1 SYNOPSIS

 my $iterator = $user->groups_iterator;
 while ( my $group = $iterator->next ) {
    # $group isa Net::LDAP::Class::Group
 }
 printf("%d groups found\n", $iterator->count);

=head1 DESCRIPTION

Net::LDAP::Class::Iterator handles paged searching using Net::LDAP::Control::Paged.

=head1 ITERATORS vs ARRAYS

Many of the relationship methods in Net::LDAP::Class get and set arrays
or array refs of related objects. For small (<1000) data sets arrays are just
fine but as data sets scale, different techniques become necessary. An iterator
has a big resource advantage over an array: instead of holding all the related
objects in memory at once, as an array does, an iterator reads one
object at a time from the LDAP server.

For example, if you want to look at all the users who are members of a group,
and the number of users is large (>1000), some LDAP servers (Active Directory
in particular) won't return all of your user objects in a single query. Instead,
the results must be paged using Net::LDAP::Control::Paged. You'll see the
evidence of this if you call the following code against Active Directory
with a group of more than 1000 users.

 my $group = MyADGroup->new( cn => 'myBigGroup', ldap => $ldap )->read;
 my $users = $group->users;  # bitten by AD! returns an empty array ref!
 foreach my $user (@$users) {
   # nothing here -- the array is empty
 }

The call to $group->users returns an empty array because Active Directory
refuses to return more than 1000 results at a time. (NOTE the number 1000
is the default maximum; your server may be configured differently.)

So an iterator to the rescue!

 my $users = $group->users_iterator;
 while ( my $user = $users->next ) {
    # do something with $user
 }
 printf("We saw %d users in group %s\n", $users->count, $group->name);

You might ask, why bother with arrays at all if iterators are so great.
The answer is convenience. 
For small data sets, arrays are convenient,
especially if you intend to do things with subsets of them at a time.
Of course, you could do this:

 my $users = $group->users_iterator;
 my @allusers;
 while ( my $user = $users->next ) {
     push @allusers, $user;
 }
 
But then you've negated one of the advantages of the iterator: it is
less resource-intensive. But hey, if you've got the memory, honey,
Perl's got the time.

=head1 METHODS

=head2 ldap

Accessor for Net::LDAP object. Set in new().

=head2 base_dn

Required in new().

=head2 page_size

The size of the Net::LDAP::Control::Paged set. Default is 500. Set in new().

=head2 filter

The search filter to use. Set in new().

=head2 class

The class to bless results into. Set in new().

=head2 init

Checks that alll required params are defined and sets up the pager.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if ( !$self->class ) {
        croak "class param required";
    }
    my $page_size = $self->page_size || 500;
    $self->{_page}   = Net::LDAP::Control::Paged->new( size => $page_size, );
    $self->{_count}  = 0;
    $self->{_cookie} = undef;
    $self->_do_search();
    return $self;
}

sub _cookie_check {
    my $self = shift;
    my ($resp) = $self->{_ldap_search}->control(LDAP_CONTROL_PAGED)
        or croak "failed to get PAGED control response";

    $self->{_cookie} = $resp->cookie;
    if ( !$self->{_cookie} ) {
        return;
    }

    # Set cookie in paged control
    $self->{_page}->cookie( $self->{_cookie} );

    return $self->{_cookie};
}

sub _do_search {
    my $self = shift;

    # execute the search, stashing the search object
    my $filter = $self->filter or croak "filter required";
    my $base_dn    = $self->base_dn || $self->class->metadata->base_dn;
    my $attributes = $self->class->metadata->attributes;
    my @args       = (
        'base'    => $base_dn,
        'filter'  => $filter,
        'attrs'   => $attributes,
        'control' => [ $self->{_page} ],
    );
    my $ldap = $self->ldap or croak "need Net::LDAP object";

    #warn "$self->{_count} : _do_search with args: " . dump( \@args ) . "\n";

    my $ldap_search = $ldap->search(@args);

    if ( !$ldap_search ) {

        # be nice to the server and stop the search
        # if we still have a cookie
        if ( $self->{_cookie} ) {
            $self->{_page}->size(0);
            $self->{_page}->cookie( $self->{_cookie} );
            $ldap->search(@args);
            croak "LDAP seach ended prematurely.";
        }

        $self->{_exhausted} = 1;
        return;    # no more entries

    }

    # fatal on search error
    croak "error searching ldap: ",
        Net::LDAP::Class->get_ldap_error($ldap_search)
        if ( $ldap_search->code );

    $self->{_current_set} = $ldap_search->count;
    $self->{_ldap_search} = $ldap_search;

    # if we found nothing.
    if ( !$self->{_current_set} ) {
        $self->{_exhausted} = 1;
        return;
    }

    return $self;
}

=head2 count

Returns the number of iterations performed.

=cut

sub count {
    return shift->{_count};
}

=head2 is_exhausted

Returns true (1) if all the results for this iterator have
been seen, false (0) otherwise.

=cut

sub is_exhausted {
    return shift->{_exhausted};
}

=head2 next

Returns the next Net::LDAP::Class object from the pager. Returns
undef if no more results are found.

=cut

sub next {
    my $self = shift;

    return undef if $self->{_exhausted};

    my $ldap_entry = $self->{_ldap_search}->shift_entry;

    if ( !defined $ldap_entry ) {

        #warn "no ldap_entry ... trying next page";

        # handle next search page
        $self->_cookie_check;

        # if there is no cookie, this was the last page.
        if ( !$self->{_cookie} ) {
            $self->{_exhausted} = 1;
            return undef;
        }

        $self->_do_search or return undef;
        $ldap_entry = $self->{_ldap_search}->shift_entry;
        if ( !$ldap_entry ) {
            $self->{_exhausted} = 1;
            return undef;
        }
    }

    $self->{_count}++;

    return $self->class->new(
        ldap       => $self->ldap,
        ldap_entry => $ldap_entry
    );

}

=head2 finish

Tell the server you're done iterating over results.
This method is only necessary if you stop before exhausting
all the results.

=cut

sub finish {
    my $self = shift;
    $self->{_page}->size(0);
    $self->_cookie_check;
    if ( !$self->_do_search() ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub DESTROY {
    my $self = shift;
    if ( !$self->is_exhausted ) {
        carp("non-exhausted iterator DESTROY'd");
        Data::Dump::dump($self);
        $self->finish();
    }
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-ldap-class at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LDAP-Class>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::LDAP::Class

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LDAP-Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LDAP-Class>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LDAP-Class>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LDAP-Class>

=back

=head1 COPYRIGHT

Copyright 2009 by Peter Karman.

All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Net::LDAP, Net::LDAP::Batch

=cut
