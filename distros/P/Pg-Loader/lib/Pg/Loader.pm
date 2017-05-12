
# Copyright (C) 2008 Ioannis Tambouras <ioannis@cpan.org>. All rights reserved.
# LICENSE:  GPLv3, eead licensing terms at  http://www.fsf.org .

package Pg::Loader;

use 5.010000;
use strict;
use warnings;
use Pg::Loader::Update qw/ update_loader /;
use Pg::Loader::Copy   qw/ copy_loader   /;
use base 'Exporter';
our $VERSION = '0.21';

our @EXPORT = qw( copy_loader  update_loader ) ;




1;
__END__

=over

=item dist_abstract

=back

Perl extension for loading and updating Postgres tables


=head1 NAME

Pg::Loader - Perl extension for loading and updating Postgres tables

=head1 SYNOPSIS

  use Pg::Loader;

=head1 DESCRIPTION

This is a helper module for pgloader.pl(1), it loads and updates 
tables in a Postgres database. It is similar in function to 
the pgloader(1) python program (written by other authors) with
enhancements plus the ability to update tables.

=head2 EXPORT

Pg::Loader - Perl extension for loading and updating Postgres tables


=head1 SEE ALSO

http://pgfoundry.org/projects/pgloader/  hosts the original python
project.


=head1 AUTHOR

Ioannis Tambouras, E<lt>ioannis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Ioannis Tambouras

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
