package Net::PT2;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Net::PT - The great new Net::PT!

=head1 VERSION

Version 0.01




=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Paul Taylor.

This program is released under the following license: BSD


=cut

our $VERSION = '1.0.2';

use 5.006;
use strict;
use warnings FATAL => 'all';

use Net::PT2::Test;

sub test {
    my ($class, $s) = @_;

    print "\n";
    print "Net::PT2 - test(${class}, ${s})\n";
    print "Done\n";
    print "\n";
}
    

1;

