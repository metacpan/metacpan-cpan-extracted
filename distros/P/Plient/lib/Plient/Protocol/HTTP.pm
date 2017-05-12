package Plient::Protocol::HTTP;

use warnings;
use strict;
require Plient::Protocol unless $Plient::bundle_mode;
our @ISA = 'Plient::Protocol';

sub prefix { 'http' }
sub methods { qw/get post head/ }

1;

__END__

=head1 NAME

Plient::Protocol::HTTP - 


=head1 SYNOPSIS

    use Plient::Protocol::HTTP;

=head1 DESCRIPTION


=head1 INTERFACE

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2010-2011 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

