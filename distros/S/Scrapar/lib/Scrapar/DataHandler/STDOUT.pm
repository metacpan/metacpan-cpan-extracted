package Scrapar::DataHandler::STDOUT;

use strict;
use warnings;
use base qw(Scrapar::DataHandler::_base);
use Data::Dumper;

sub handle {
    my $self = shift;
    my $data = shift;

    print Dumper $data;
}

1;

__END__

=pod

=head1 NAME

Scrapar::DataHandler::STDOUT - Outputs data to STDOUT

=head1 COPYRIGHT

Copyright 2009 by Yung-chung Lin

All right reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
