package Password::Policy::Exception::InvalidAlgorithm;
$Password::Policy::Exception::InvalidAlgorithm::VERSION = '0.06';
use strict;
use warnings;

use parent 'Password::Policy::Exception';

sub error { return "You specified an algorithm that is not available"; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::Policy::Exception::InvalidAlgorithm

=head1 VERSION

version 0.06

=head1 AUTHOR

Andrew Nelson <anelson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Nelson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
