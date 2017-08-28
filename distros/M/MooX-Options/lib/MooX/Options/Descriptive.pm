package MooX::Options::Descriptive;

use strictures 2;

=head1 NAME

MooX::Options::Descriptive - This method extend Getopt::Long::Descriptive to change the usage method

=head1 DESCRIPTION

This class will override the usage_class method, to customize the output of the help

=cut

our $VERSION = "4.103";

use Getopt::Long 2.43;
use Getopt::Long::Descriptive 0.099;
use MooX::Options::Descriptive::Usage;
use parent 'Getopt::Long::Descriptive';

=head1 METHODS

=head2 usage_class

Method to use for the descriptive build

=cut

sub usage_class { return 'MooX::Options::Descriptive::Usage' }

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Options

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Options>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-Options>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooX-Options>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-Options/>

=back

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This software is copyright (c) 2017 by Jens Rehsack.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

1;
