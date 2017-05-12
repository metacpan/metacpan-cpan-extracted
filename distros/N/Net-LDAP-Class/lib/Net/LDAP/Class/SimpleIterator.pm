package Net::LDAP::Class::SimpleIterator;
use strict;
use warnings;
use base qw( Rose::Object );
use Carp;
use Data::Dump qw( dump );
use Net::LDAP::Class::MethodMaker ( 'scalar' => [qw( code )], );

our $VERSION = '0.27';

=head1 NAME

Net::LDAP::Class::SimpleIterator - iterate over Net::LDAP::Class objects

=head1 SYNOPSIS

 my $iterator = $user->groups_iterator;
 while ( my $group = $iterator->next ) {
    # $group isa Net::LDAP::Class::Group
 }
 printf("%d groups found\n", $iterator->count);

=head1 DESCRIPTION

Net::LDAP::Class::SimpleIterator uses a closure (CODE reference)
to implement a simple next()-based API.

=head1 METHODS

=head2 init

Implements the standard object initialization.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    if ( !defined $self->code ) {
        croak "code ref required";
    }
    $self->{_count} = 0;
    return $self;
}

=head2 code(I<sub_ref>)

Required in new(). I<sub_ref> is called on every invocation
of next().

=head2 next

Calls code() and returns its value, incrementing count() if the value
is defined.

=cut

sub next {
    my $self = shift;
    return undef if !exists $self->{code};
    my $ret = $self->{code}->();
    if ( defined $ret ) {
        $self->{_count}++;
    }
    else {
        $self->finish;
    }
    return $ret;
}

=head2 count

Returns the number of iterations of next() that returned defined.

=cut

sub count { return shift->{_count} }

=head2 finish

Deletes the internal code reference.

=cut

sub finish {
    my $self = shift;
    delete $self->{code};
}

=head2 is_exhausted

Tests for the existence of the internal code reference, returning
true if the internal code reference no longer exists and false
if it does.

=cut

sub is_exhausted {
    my $self = shift;
    return exists $self->{code} ? 0 : 1;
}

sub DESTROY {
    my $self = shift;
    if ( defined $self->{code} ) {
        carp("non-exhausted iterator DESTROY'd");
        Data::Dump::dump($self);
        $self->finish;
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

