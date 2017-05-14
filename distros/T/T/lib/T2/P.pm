package T2::P;
use strict;
use warnings;

use parent 'T2';

our $VERSION = '0.001';

sub __DEFAULT_AS { 't2p' }
sub __DEFAULT_NS { 'Test2::Plugin' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

T2::P - Import Test2::Plugin::* in a box.

=head1 DESCRIPTION

See L<T> for documentation.

=head1 SOURCE

The source code repository for T can be found at
F<http://github.com/Test-More/T/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2016 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
