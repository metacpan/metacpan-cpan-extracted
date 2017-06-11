package MooX::Locale::Passthrough;

use strict;
use warnings FATAL => 'all';

our $VERSION = "0.001";

use Carp qw/croak/;

use Moo::Role;

=head1 NAME

MooX::Locale::Passthrough - provide API used in translator modules without translating

=head1 SYNOPSIS

  { package WonderBar;
    use Moo;
    with "MooX::Locale::Passthrough";

    sub tell_me { my $self = shift; $self->__("Hello world"); }
  }

  WonderBar->new->tell_me;

=head1 DESCRIPTION

C<MooX::Locale::Passthrough> is made to allow CPAN modules use translator API
without adding heavy dependencies (external software) or requirements (operating
resulting solution).

This software is released together with L<MooX::Locale::TextDomain::OO>, which
allowes then to plugin any desired translation.

=head1 METHODS

=head2 __ MSGID

returns MSGID

=cut

## no critic (Subroutines::RequireArgUnpacking)
sub __ { $_[1] }

=head2 __n MSGID, MSGID_PLURAL, COUNT

returns MSGID when count is equal 1, MSGID_PLURAL otherwise

=cut

sub __n
{
    my (undef, $s, $p, $v) = @_;
    defined $v and int($v) == 1 and return $s;
    $p;
}

=head2 __p MSGCTX, MSGID

returns MSGID

=cut

sub __p
{
    my (undef, $ctx, $m) = @_;
    $m;
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-MooX-Locale-Passthrough at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Locale-Passthrough>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Locale::Passthrough

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Locale-Passthrough>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-Locale-Passthrough>

=item * CPAN Ratings

L<http://cpanratings.perl.org/m/MooX-Locale-Passthrough>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-Locale-Passthrough/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
