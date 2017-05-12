#===============================================================================
#      PODNAME:  Net::IP::Identifier::WhoisParser
#     ABSTRACT:  parse WHOIS result, extracting particular information
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sat May  2 15:51:45 PDT 2015
#===============================================================================

use 5.002;
use strict;
use warnings;

package Net::IP::Identifier::WhoisParser;
use Math::BigInt;
use Net::IP;   # for IP_IDENTICAL, OVERLAP, etc
use Net::IP::Identifier::Net;
use Net::IP::Identifier::Regex;
use Moo;
use namespace::clean;

our $VERSION = '0.111'; # VERSION

has verbose => (    # verbose mode
    is => 'rw',
);
has text => (
    is => 'rw',
);
has relevant_lines => (
    is => 'lazy',
    default => \&get_relevant_lines,
);
has entity => (     # if entity is found in the WHOIS result from entity strings
    is => 'lazy',
    default => \&get_entity,
);
has range => (      # a Net::IP::Identifier::Net object
    is => 'lazy',
    default => \&get_range,
);
has _entity => (    # if entity is found before ->entity call, stash it here
    is => 'rw',
);
has _range => (     # if range is found before ->range call, stash it here
    is => 'rw',
);

# some class variables

#my $Re = Net::IP::Identifier::Regex->new;
#my $re_any      = $Re->IP_any;
#my $re_netblock = $Re->netblock;

my @whois_stop_regexs = (   # lines beyond which we should not go
    qr[^parent:]i,
    qr[^route([s6])?:]i,
    qr[^mnt-routes:]i,
);

my @whois_range_regexs = (   # lines which might contain the range
    qr[^inet6?num:\s*(.+)]i,
    qr[^NetRange:\s*(.+)]i,
    qr[^CIDR:\s*(\S+)]i,
    qr[^Network:IP-Network(?:-Block)?:\s*(.+)]i,
    qr/^a\.\s*\[Network Number\]\s*(.*)/i,
);

my @whois_entity_regexs = (   # lines that might contain the entity
    qr[^Organization:\s*(.*)]i,
    qr[^org-name:\s*(.*)]i,
    qr[^descr:\s*(.*)]i,
    qr[^owner:\s*(.*)]i,
    qr[^Network:Org-Name:(.*)]i,
    qr/^g\.\s*\[Organization\]\s*(.*)/i,
);

sub get_relevant_lines {
    my ($self) = @_;

    my @lines;
    my $non_server_lines = 0;

    for my $line (split "\n", $self->text) {
        $line =~ s/\s*$//;
        next if (not $line =~ m/\S/);   # skip blank lines
        if ($line =~ m/^[#%]/) {    # comments
            if ($line =~ m/ Information related to / and
                $non_server_lines > 0) {   # if it's not the first thing
                last;       # skip everything else
            }
            next;   # skip comments
        }
        if ($line =~ m/^No match for "/ or
            $line =~ m/^descr:.* address block not managed by/) {
            return []; # no relevant lines
        }
        for my $re (@whois_stop_regexs) {
            last if ($line =~ m/$re/);
        }
        push @lines, $line;
        $non_server_lines++ if (not $line =~ m/^\[/);
        # check for ARIN style listing:
        if (my ($entity, $range) = $line =~ m/(.*?) \S+ \(NET6?[\da-fA-F-]+\) (.*)/) {
            $range = Net::IP::Identifier::Net->new($range);
            if (defined $self->_range and
                $self->_range->overlaps($range) == $IP_A_IN_B_OVERLAP) {
                # previous _range is inside new range.  we want
                #    the smallest, so swap
                $range = $self->_range;
                $entity = $self->_entity;
            }
            else {
            }
            $self->_range($range);
            $self->_entity($entity);
        }
    }
    return \@lines;
}

sub get_range {
    my ($self) = @_;

    my @ranges;
    for my $line (@{$self->relevant_lines}) {
        return $self->_range if ($self->_range);
        for my $re (@whois_range_regexs) {
            if (my ($match) = $line =~ m/$re/) {
                push @ranges, Net::IP::Identifier::Net->new($match);
            }
        }
    }
    return $self->smallest_net(\@ranges);
}

# find and return smallest net in a group of nets
sub smallest_net {
    my ($self, $nets) = @_;

    for my $aa (0 .. $#{$nets}) {
        for my $bb ($aa+1 .. $#{$nets}) {
            next if (not defined $nets->[$aa] or not defined $nets->[$bb]);
            my $overlap = $nets->[$aa]->overlaps($nets->[$bb]);
            if ($overlap eq $IP_IDENTICAL) {    # duplicate netblocks, choose on notation
                if ($nets->[$aa]->src_str =~ m/\+/) {    # avoid '+' notation
                    $nets->[$aa] = undef;
                }
                elsif ($nets->[$aa]->src_str =~ m/-/) {     # prefer '-' notation
                    $nets->[$bb] = undef;
                }
                else {
                    $nets->[$aa] = undef;
                }
            }
            elsif ($overlap eq $IP_A_IN_B_OVERLAP) {    # aa is inside bb
                $nets->[$bb] = undef
            }
            elsif ($overlap eq $IP_B_IN_A_OVERLAP) {    # bb is inside aa
                $nets->[$aa] = undef
            }
        }
    }
    for my $net (@{$nets}) {
        return $net if (defined $net);  # should only be one, if not - shrug...
    }
    return; # no nets to start with?
}

sub get_entity {
    my ($self) = @_;

    for my $line (@{$self->relevant_lines}) {
        return $self->_entity if ($self->_entity);
        for my $re (@whois_entity_regexs) {
            if (my ($match) = $line =~ m/$re/) {
                return $match;
            }
        }
    }
    return; # undef
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::WhoisParser - parse WHOIS result, extracting particular information

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::WhoisParser;
 my $parser = Net::IP::Identifier::WhoisParser->new(text => $whois_result);

=head1 DESCRIPTION

Net::IP::Identifier::WhoisParser objects are created with the output string
of a call to 'whois', 'jwhois', etc.  Methods are available to extract
information such as the netblock range and the owner of the block.

=head2 Methods

=over

=item new( text => 'WHOIS results' )

Creates a new Net::IP::Identifier::WhoisParser object.  The B<text> option
must be provided for construction of the object, and should be the output of
running a 'whois' (or similar) command.

=item relevant_lines

Returns a reference to an array of lines from the B<text>.  Comments (lines
starting with '#' or '%') and blank lines are excluded, and many WHOIS
formats will have a fair amount of trailing cruft removed.

=item range

If the range of the netblock can be determined, it is returned here as a
Net::IP::Identifier::Net object.

=item entity

If an owner entity of the netblock can be determined, it is returned here.

=back

=head1 SEE ALSO

=over

=item Net::IP

=item Net::IP::Identifier::Net

=item Net::IP::Identifier::WhoisCache

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
