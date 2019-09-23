#!/usr/bin/perl

package My::Moodulino;

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Indent = 1;

use Moo;
with 'MooX::Role::CliOptions';

use MooX::StrictConstructor;

my $cli = 0;

=pod
has debug => (
    is => 'rw',
    default => 0,
);
=cut

has custom_opt => ( is => 'ro', );

has internal_attr => (
    is => 'rw',

    #init_arg => undef,
);

has cli => (
    is      => 'lazy',
    default => sub { return $cli; },
);

# all attributes and package variable MUST be declared before this!
do {
    print "caller-stack is empty\n";

    # set this so test scripts can see it in the attribute
    $cli = 1;

    my $app = __PACKAGE__->init(
        argv     => \@ARGV,
        add_opts => ['custom_opt=s'],
    );

    exit $app->run;
} unless caller();

print "command line flag not set\n" if !$cli;
print "exit was not called\n";

# BUILD will be called like normal if present as part of 'init', shown
# here for illustration purposes only.
sub BUILD {
    my $self = shift;

    print "cli: $cli\n" if $self->verbose;
}

sub run {
    my $self = shift;

    print "running from command line\n" if $self->cli;
    print 'custom_opt: ' . $self->custom_opt . "\n" if $self->custom_opt;

    print Dumper($self) if $self->debug;

    return 0;
}

1;
__END__

=pod

=head1 NAME
 
moodulino - eample showing how to use MooX::Role::CliOptions
 
=head1 SYNOPSIS
 
moodulino [options]
 
 Options:
   --debug    add diagnostic messages and/or disable database writes
   --verbose  extra information in stdout
   --help     brief help message
   --man      full documentation
 
=head1 OPTIONS
 
=over 4
 
=item B<--help>
 
Print a brief help message and exits.
 
=item B<--man>
 
Prints the manual page and exits.
 
=back
 
=head1 DESCRIPTION
 
This script demonstrates how to use C<MooX::Role::CliOptions>. With no
options will print a message and the contents of C<custom_opt>, if any.
 
=head1 AUTHOR

Jim Bacon, C<< <boftx at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Jim Bacon.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
