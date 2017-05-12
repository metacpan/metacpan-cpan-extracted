# $Id: Iterator.pm,v 1.14 2008/03/03 16:55:04 asc Exp $
use strict;

package Net::Delicious::Iterator;

$Net::Delicious::Iterator::VERSION = '1.14';

=head1 NAME

Net::Delicious::Iterator - iterator class for Net::Delicious thingies

=head1 SYNOPSIS

 use Net::Delicious::Iterator;

 my @dates = ({...},{...});
 my $it    = Net::Delicious::Iterator->new("Date",\@dates);

 while (my $d = $it->next()) {

    # Do stuff with $d here
 }

=head1 DESCRIPTION

Iterator class for Net::Delicious thingies

=head1 NOTES

It isn't really expected that you will instantiate these
objects outside of I<Net::Delicious> itself.

=cut

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new($foreign_class,\@data)

Returns a I<Net::Delicious::Iterator> object. Woot!

=cut

sub new {
        my $pkg = shift;
        return bless {pkg=>$_[0], data=>$_[1], count=>0}, $pkg;
}

=head2 $it->count()

Return the number of available thingies.

=cut

sub count {
        my $self = shift;
        return scalar @{$self->{data}};
}

=head2 $it->next()

Returns the next object in the list of available thingies. Woot!

=cut 

sub next {
        my $self = shift;

        if (my $data = $self->{data}->[$self->{count}++]) {
                return $self->{pkg}->new($data);
        }
}

sub reset {
        my $self = shift;
        $self->{count} = 0;
}


=head1 VERSION

1.13

=head1 DATE

$Date: 2008/03/03 16:55:04 $

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 SEE ALSO

L<Net::Delicious>

=head1 LICENSE

Copyright (c) 2004-2008 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
