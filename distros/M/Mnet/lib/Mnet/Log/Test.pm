package Mnet::Log::Test;

=head1 NAME

Mnet::Log::Test - Use to filter Mnet::Log entries for testing

=head1 SYNOPSIS

    use Mnet::Log::Test;

=head1 DESCRIPTION

This module can be used as a pragma to enable the filtering out of timestamps
and other varying output from L<Mnet::Log> entries. This was made to be used
for test scripts that might fail with logged timestamps.

Refer to L<Mnet::Log> and L<Mnet::Test> for more information.

=cut

# required modules
use warnings;
use strict;

=head1 SEE ALSO

L<Mnet>

L<Mnet::Log>

L<Mnet::Test>

=cut

# normal end of package
1;

