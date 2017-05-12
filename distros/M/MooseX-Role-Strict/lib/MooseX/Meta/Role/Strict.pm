package MooseX::Meta::Role::Strict;

use Moose;
extends 'Moose::Meta::Role';

our $VERSION = 0.05;

override apply => sub {
    my ( $self, $other, @args ) = @_;

    if ( blessed($other) && $other->isa('Moose::Meta::Class') ) {
        # already loaded
        return MooseX::Meta::Role::Application::ToClass::Strict->new(@args)
          ->apply( $self, $other );
    }

    super;
};

1;

__END__

=head1 NAME

MooseX::Meta::Role::Strict - Ensure we use strict role application.

=head1 VERSION

Version 0.05

=head1 DESCRIPTION

This is the metaclass for C<MooseX::Role::Strict>.  For internal use only.

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moosex-role-strict at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Role-Strict>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Role::Strict

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Role-Strict>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Role-Strict>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Role-Strict>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Role-Strict/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
