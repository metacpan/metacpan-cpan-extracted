package Module::Changes::Base;

use warnings;
use strict;


our $VERSION = '0.05';


use base 'Class::Accessor::Constructor';


__PACKAGE__->mk_constructor;


1;

__END__

=head1 NAME

Module::Changes::Base - base class for Module::Changes::* classes 

=head1 SYNOPSIS

None; this class is internal.

=head1 DESCRIPTION

This is the base class used by all other classes in this distribution.

=head1 METHODS

=over 4

=item new

A constructor per L<Class::Accessor::Constructor>.

=back

=head1 TAGS

If you talk about this module in blogs, on del.icio.us or anywhere else,
please use the C<modulechanges> tag.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-module-changes@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHOR

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

