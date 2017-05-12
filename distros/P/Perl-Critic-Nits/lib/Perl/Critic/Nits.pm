package Perl::Critic::Nits;

use strict;
use warnings;

use version; our $VERSION = qv('v1.0.0');

1;

__END__

=head1 NAME

Perl::Critic::Nits - policies of nits I like to pick.

=head1 AFFILIATION

This module has no functionality, but instead contains documentation for
this distribution and acts as a means of pulling other modules into a
bundle.  All of the policy modules contained herein will have an
"AFFILIATION" section announcing their participation in this grouping.

=head1 VERSION

This document describes Perl::Critic::Nits version 1.0.0.

=head1 SYNOPSIS

Some L<Perl::Critic> policies to make your code more clean.

=head1 DESCRIPTION

The included policy is:

=over

=item L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitAccessOfPrivateData>

Prohibits direct access to a hash-based object's hash. [Severity: 5]

=back

=head1 INTERFACE

None.  This is nothing but documentation.

=head1 DIAGNOSTICS

None.  This is nothing but documentation.

=head1 CONFIGURATION AND ENVIRONMENT

All policies included are in the "nits" theme, as well as the
"maintenance" theme.  See the L<Perl::Critic> documentation for how to
make use of this.

=head1 DEPENDENCIES

L<Perl::Critic>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

False positives may be encountered if, internal to a module, the code does
not use $self, $class, or $package to refer to the object it represents.

Please report any bugs or feature requests to
C<bug-perl-critic-nits@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 WHY NITS?

Similar to L<Perl::Critic::Tics>, take your pick:

=over

=item B<N>agging B<I>diosyncratic B<T>houghtless B<S>yntax

=item Nits I like to pick.

=back

=head1 AUTHOR

Kent Cowgill, C<< <kent@c2group.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Kent Cowgill C<< <kent@c2group.net> >>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 textwidth=78 nowrap autoindent :
