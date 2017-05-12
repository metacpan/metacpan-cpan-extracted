package Password::Policy::Exception::NoAlgorithm;
$Password::Policy::Exception::NoAlgorithm::VERSION = '0.04';
use strict;
use warnings;

use parent 'Password::Policy::Exception';

sub error { return "You did not specify an algorithm for that profile"; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::Policy::Exception::NoAlgorithm

=head1 VERSION

version 0.04

=head1 AUTHOR

Andrew Nelson <anelson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Nelson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
