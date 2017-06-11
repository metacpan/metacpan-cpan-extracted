package MooX::Locale::TextDomain::OO;

use strict;
use warnings FATAL => 'all';

our $VERSION = "0.001";

use Carp                   ("croak");
use Locale::TextDomain::OO ();
use Scalar::Util           ("blessed");

use Moo::Role;
with "MooX::Locale::Passthrough";

=head1 NAME

MooX::Locale::TextDomain::OO - provide API used in translator modules without translating

=head1 SYNOPSIS

  { package WonderBar;
    use Moo;
    with "MooX::Locale::TextDomain::OO";

    sub tell_me { my $self = shift; $self->__("Hello world"); }
  }

  WonderBar->new->tell_me;

=head1 DESCRIPTION

C<MooX::Locale::TextDomain::OO> 

=head1 OVERLOADED METHODS

=head2 __ MSGID

returns translation for MSGID

=cut

has localizer => (is => "lazy");

sub _build_localizer { Locale::TextDomain::OO->instance() }

around __ => sub {
    my ($next, $self, $msgid) = @_;
    my $loc = blessed $self ? $self->localizer : $self->_build_localizer;
    $loc->translate(undef, $msgid);
};

=head2 __n MSGID, MSGID_PLURAL, COUNT

returns translation for MSGID when count is equal 1, translation for MSGID_PLURAL otherwise

=cut

around __n => sub {
    my ($next, $self, $msgid_sin, $msgid_plu, $count) = @_;
    my $loc = blessed $self ? $self->localizer : $self->_build_localizer;
    $loc->translate(undef, $msgid_sin, $msgid_plu, $count, 1);
};

=head2 __p MSGCTXT, MSGID

returns translation for MSGID in MSGCTXT context

=cut

around __p => sub {
    my ($next, $self, $ctx, $msgid) = @_;
    my $loc = blessed $self ? $self->localizer : $self->_build_localizer;
    $loc->translate($ctx, $msgid);
};

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-MooX-Locale-TextDomain-OO at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Locale-TextDomain-OO>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Locale::TextDomain::OO

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Locale-TextDomain-OO>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-Locale-TextDomain-OO>

=item * CPAN Ratings

L<http://cpanratings.perl.org/m/MooX-Locale-TextDomain-OO>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-Locale-TextDomain-OO/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
