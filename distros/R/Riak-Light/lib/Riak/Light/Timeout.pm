#
# This file is part of Riak-Light
#
# This software is copyright (c) 2013 by Weborama.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
## no critic (RequireUseStrict, RequireUseWarnings)
package Riak::Light::Timeout;
{
    $Riak::Light::Timeout::VERSION = '0.12';
}
## use critic

use Moo::Role;

# ABSTRACT: socket interface to add timeout in in/out operations

requires 'sysread';
requires 'syswrite';

1;


=pod

=head1 NAME

Riak::Light::Timeout - socket interface to add timeout in in/out operations

=head1 VERSION

version 0.12

=head1 DESCRIPTION

  Internal class

=head1 AUTHORS

=over 4

=item *

Tiago Peczenyj <tiago.peczenyj@gmail.com>

=item *

Damien Krotkine <dams@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Weborama.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
