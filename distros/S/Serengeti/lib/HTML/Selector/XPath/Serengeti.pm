package HTML::Selector::XPath::Serengeti;

use strict;
use warnings;

use base qw(HTML::Selector::XPath);

my %INPUT_TYPE = (
    checkbox    => 1,
    file        => 1,
    image       => 1,
    password    => 1,
    radio       => 1,
    reset       => 1,
    submit      => 1,
    text        => 1,
);

sub parse_pseudo {
    my $self = shift;
	my ($pseudo) = @_;

    if (exists $INPUT_TYPE{$pseudo}) {
        return "[\@type='${pseudo}']";
    }

    return;
}

1;
__END__

=head1 NAME

HTML::Selector::XPath::Serengeti - HTML::Selector::XPath subclass with support 
for some of the :selectors from jQuery

=cut