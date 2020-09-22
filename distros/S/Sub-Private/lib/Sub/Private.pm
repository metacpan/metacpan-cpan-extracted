package Sub::Private;

use warnings;
use strict;

use Attribute::Handlers;

use namespace::clean     qw();
use B::Hooks::EndOfScope qw(on_scope_end);
use Sub::Identify        qw(get_code_info);

=head1 NAME

Sub::Private - Private subroutines and methods

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    package Foo;
    use Sub::Private;

    sub foo :Private {
        return 42;
    }

    sub bar {
        return foo() + 1;
    }

=cut

sub UNIVERSAL::Private :ATTR(CODE,BEGIN) {
    my ($package, $symbol, $referent, $attr, $data) = @_;

    on_scope_end {
        namespace::clean->clean_subroutines( get_code_info( $referent ) );
    }
}

=head1 DESCRIPTION

This module provide a C<:Private> attribute for subroutines. By using the
attribut you get truly private methods.


=head1 AUTHOR

Peter Makholm, C<< <peter at makholm.net> >>

=head1 MAINTAINER

Nigel Horne, C<< <njh@bandman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sub-private at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Private>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

namespace::clean

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Private


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Private>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sub-Private>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sub-Private>

=item * Search CPAN

L<http://search.cpan.org/dist/Sub-Private>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Makholm, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Sub::Private
