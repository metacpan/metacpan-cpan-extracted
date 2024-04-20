package Net::EPP::Parser;
use base qw(XML::LibXML);
use strict;
use warnings;

=pod

=head1 NAME

Net::EPP::Parser - a wrapper around the LibXML parser.

=head1 DESCRIPTION

Nothing to see here, move along.

=cut

sub new {
    my $package = shift;
    my $self    = bless($package->SUPER::new(@_), $package);
    return $self;
}

1;

=pod

=head1 COPYRIGHT

This module is (c) 2008 - 2023 CentralNic Ltd and 2024 Gavin Brown. This module
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
