package Net::LDAP::Class::MultiIterator;
use strict;
use warnings;
use base qw( Rose::Object );
use Carp;
use Data::Dump qw( dump );
use Net::LDAP::Class::MethodMaker ( 'scalar' => [qw( iterators )], );

our $VERSION = '0.27';

=head1 NAME

Net::LDAP::Class::MultiIterator - a set of Net::LDAP::Class::Iterator objects

=head1 SYNOPSIS

 my $iterator = $user->groups_iterator;
 while ( my $group = $iterator->next ) {
    # $group isa Net::LDAP::Class::Group
 }
 printf("%d groups found\n", $iterator->count);

=head1 DESCRIPTION

Net::LDAP::Class::MultiIterator handles multiple iterators under a single
call to next(). Used by users_iterator() and groups_iterator() methods.

=head1 METHODS

=head2 iterators

The array ref of iterators. Required to be set in new().

=head2 init

Set up the object.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if (   !$self->iterators
        or !ref( $self->iterators )
        or ref( $self->iterators ) ne 'ARRAY' )
    {
        croak "iterators ARRAY ref required";
    }

    $self->{_count} = 0;

    return $self;
}

=head2 count

Returns the total number of iterations.

=cut

sub count {
    return shift->{_count};
}

=head2 next

Return the next result. If one iterator on the stack is exhausted,
automatically moves to the next one.

=cut

sub next {
    my $self = shift;

    # find the first un-exhausted child iterator's next() value.
    my $i = 0;
    for my $iter ( @{ $self->{iterators} } ) {
        next if $iter->is_exhausted;
        my $ret = $iter->next;
        if ( !defined $ret ) {
            if ( !$iter->is_exhausted ) {
                warn "non-exhausted iterator $iter returned undef";
            }
            next;
        }
        $self->{_count}++;
        return $ret;
    }

    # if we get here, completely exhausted.
    $self->{_is_exhausted} = 1;
    return undef;
}

=head2 is_exhausted

Returns true (1) if all the internal iterators return is_exhausted,
false (undef) otherwise.

=cut

sub is_exhausted {
    return shift->{_is_exhausted};
}

=head2 finish

Calls finish() on all un-exhausted iterators.

=cut

sub finish {
    my $self = shift;

    my $i        = 0;
    my $finished = 0;
    for my $iter ( @{ $self->{iterators} } ) {
        next if $iter->is_exhausted;
        $finished += $iter->finish();
    }

    return $finished;
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

