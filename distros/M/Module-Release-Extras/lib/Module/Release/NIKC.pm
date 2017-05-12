package Module::Release::NIKC;

use strict;
use warnings;

# Need to 'use' these modules first (rather then relying on 'use base' to
# require them) because they automatically export methods, and base.pm won't
# call the import() method on anything it requires.  This is one way to
# do mixins.

use Module::Release::ModuleBuild;
use Module::Release::Subversion;
use base qw(Module::Release);	# Rely on @EXPORT in the modules

=head1 NAME

Module::Release::NIKC - Subclass for releasing code

=head1 SYNOPSIS

This subclass exists to inherit from

=over 4

=item *

Module::Release::Subversion and

=item *

Module::Release::ModuleBuild

=back

so that scripts/modules written by nikc@cpan.org, using Module::Build and
stored in a Subversion repository can be released using Module::Release.

C<release> only supports specifying a single subclass, hence this wrapper
around the multiple subclasses required.

=head1 AUTHOR

Nik Clayton <nik@FreeBSD.org>

Copyright 2004 Nik Clayton.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module::Release::Extras>.

=head1 SEE ALSO

Module::Release, Module::Release::ModuleBuild, Module::Release::Subversion

=cut

1;
