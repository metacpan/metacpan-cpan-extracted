# * Rserve client for Perl
# * @author Djun Kim
# * Based on Clément Turbelin's PHP client
# * Licensed under GPL v2 or at your option v3

# * Supports Rserve protocol 0103 only (used by Rserve 0.5 and higher)
# *
# * Developed using code from Simple Rserve client for PHP by Simon
# * Urbanek Licensed under GPL v2 or at your option v3

# * This code is inspired from Java client for Rserve (Rserve package
# * v0.6.2) developed by Simon Urbanek(c)

#use warnings;
#use autodie;

# wrapper for R Unknown type

#class Rserve_REXP_Unknown extends Rserve_REXP {

package Statistics::RserveClient::REXP::Unknown;

our $VERSION = '0.12'; #VERSION

sub new($) {
    my $class = shift;
    my $type  = shift;
    my $self  = { unknowntype => $type, };
    bless $self, $class;
    return $self;
}

sub getUnknownType($) {
    my $this = shift;
    return $this->{unknowntype};
}

1;
