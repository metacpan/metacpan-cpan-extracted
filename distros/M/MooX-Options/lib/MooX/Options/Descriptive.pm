#
# This file is part of MooX-Options
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MooX::Options::Descriptive;

# ABSTRACT: This method extend Getopt::Long::Descriptive to change the usage method

use strict;
use warnings;

our $VERSION = '4.023';    # VERSION

use Getopt::Long 2.43;
use Getopt::Long::Descriptive 0.099;
use MooX::Options::Descriptive::Usage;
use parent 'Getopt::Long::Descriptive';

sub usage_class { return 'MooX::Options::Descriptive::Usage' }

1;

__END__

=pod

=head1 NAME

MooX::Options::Descriptive - This method extend Getopt::Long::Descriptive to change the usage method

=head1 VERSION

version 4.023

=head1 DESCRIPTION

This class will override the usage_class method, to customize the output of the help

=head1 METHODS

=head2 usage_class

Method to use for the descriptive build

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/MooX-Options/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
