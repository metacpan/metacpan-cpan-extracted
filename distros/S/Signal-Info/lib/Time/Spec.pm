package Time::Spec;
$Time::Spec::VERSION = '0.002';
use strict;
use warnings;

use Signal::Info;

1;

# ABSTRACT: a wrapper arount struct timespec

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::Spec - a wrapper arount struct timespec

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 my $spec = Time::Spec->new(1.5);
 my_sleeper($spec);
 say $spec->to_float;

=head1 DESCRIPTION

This holds a time specification, broken down into seconds and nanoseconds. This is typically used by XS modules and not by pure-perl ones.

=head1 METHODS

=head2 new($fractional)

This creates a new C<Time::Spec> object from a fractional amount of time.

=head2 sec()

This returns the number of whole seconds.

=head2 nsec()

This returns the fractional part of the time specification in nanoseconds.

=head2 to_float()

Convert the time back into fractional seconds.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
