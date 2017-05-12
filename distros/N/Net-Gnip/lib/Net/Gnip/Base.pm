package Net::Gnip::Base;

use strict;
use XML::LibXML;

=head1 NAME

Net::Gnip::Base - base package for Net::Gnip objects

=head1 METHODS

=cut

=head2 parser

Return an XML::Parser object

=cut

my $parser;
sub parser {
    return $parser ||= XML::LibXML->new;
}


sub _do {
    my $self = shift;
    my $what = shift;
    $self->{$what} = shift if @_;
    return $self->{$what};
}


1;
