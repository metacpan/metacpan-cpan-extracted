package Net::IPAddress::Filter::IPFilterDat;

use strict;
use warnings;

# ABSTRACT: A fast IP address filter from ipfilter.dat
our $VERSION = '20121119.02'; # VERSION

use Scalar::Util ();

use Net::IPAddress::Filter 20121117;
use base qw( Net::IPAddress::Filter );


use constant {

    # 000.000.000.000 - 000.255.255.255 , 000 , invalid ip
    RULE_REGEX => qr{
        \A \s*
        ([0-9]{1,3} \. [0-9]{1,3} \. [0-9]{1,3} \. [0-9]{1,3}) # Start IP address
        \s* - \s*
        ([0-9]{1,3} \. [0-9]{1,3} \. [0-9]{1,3} \. [0-9]{1,3}) # End IP address
        \s* , \s*
        (\d+)                                                  # Score
        \s* , \s*
        (.*?)                                                  # Label
        \s* \z
    }xms,
};


sub load_file {
    my $self = shift;
    my $file = shift || return;

    my $FH;

    # A filehandle can be a GLOB ref, or a blessed ref to one of the IO::
    # packages.  reftype() handles boths cases.
    if ( ref($file)
        && ( Scalar::Util::reftype($file) eq 'GLOB' || Scalar::Util::reftype( \$file ) eq 'GLOB' ) )
    {
        $FH = $file;
    }
    else {
        open $FH, '<', $file
            or die __PACKAGE__ . "::load_file() unable to open $file for reading: $!";
    }

    my $rules_added = 0;
    while ( my $line = <$FH> ) {
        $rules_added++ if $self->add_rule($line);
    }

    close $FH;

    return $rules_added;
}


sub add_rule {
    my $self = shift;
    my $rule = shift || return 0;

    if ( my $data = _parse_rule($rule) ) {
        $self->add_range_with_value( $data->{label}, $data->{start_ip}, $data->{end_ip} );
        return 1;
    }

    return 0;
}


sub _parse_rule {
    my $rule = shift;

    # 000.000.000.000 - 000.255.255.255 , 000 , invalid ip
    if ( $rule =~ RULE_REGEX ) {
        return {
            start_ip => $1,
            end_ip   => $2,
            score    => $3,
            label    => $4,
        };
    }
    return;
}

1;

__END__

=pod

=head1 NAME

Net::IPAddress::Filter::IPFilterDat - A fast IP address filter from ipfilter.dat

=head1 VERSION

version 20121119.02

=head1 SYNOPSIS

    use Net::IPAddress::Filter::IPFilterDat;

    my $filter = Net::IPAddress::Filter::IPFilterDat->new();

    $filter->load_file('/tmp/ipfilter.dat');
    # Or
    $filter->load_file($FILEHANDLE);
    # Or
    $filter->add_rule("000.000.000.000 - 000.255.255.255 , 000 , invalid ip");

    print "BLOCKED\n" if $filter->in_filter('192.168.1.20');

=head1 DESCRIPTION

An ipfilter.dat file holds a list of IP address ranges, and is often used by
p2p clients such as B<eMule> or various bittorrent clients to block connections
to or from the listed addresses.

Net::IPAddress::Filter::IPFilterDat can read in these files and provides a fast
(greater than 100k lookups per second) way of seeing if an IP address should be
filtered/blocked.

There is a dependency on the XS module L<Set::IntervalTree> so a c++ compiler
is required. The XS data structure is the reason for the small RAM usage and
high performance of the IP address filter.

=head1 METHODS

=head2 load_file( )

Fetches rows from an ipfilter.dat-formatted file and adds the ranges to the
filter. Can be called with a filename, or with an opened filehandle.  The
filehandle is closed after reading.

Expects:

    $file - Either a filename, or a filehandle.

Returns:

    Number of rules added from the file.

=head2 add_rule( )

Given a line from an ipfilter.dat file, add the rule to the filter.

Expects:

    $rule - A string containing an ipfilter.dat rule.

Returns:

    1 if rule was parsable and added to the filter.

    0 otherwise.

=head1 FUNCTIONS

=head2 _parse_rule( )

Given a line from an ipfilter.dat file, try to parse out the fields.

Expects:

    $rule - A string containing an ipfilter.dat rule.

Returns:

    A hashref of the fields if parsable.

    Otherwise undef.

=head1 TODO

=over 4

=item *

Support for reading zipped or gzipped ipfilter.dat files.

=item *

Support for the score field in ipfilter.dat.

=back

=head1 SEE ALSO

=over 4

=item *

L<Net::IPAddress::Filter> - The parent class of this module. All methods of

the parent can also be used.

=item *

L<NET::IPFilter> - Pure Perl extension for Accessing eMule / Bittorrent

IPFilter.dat Files and checking a given IP against this ipfilter.dat IP Range.

=back

=head1 BUGS OR FEATURE REQUESTS

See F<https://rt.cpan.org/Public/Dist/Display.html?Name=Net-IPAddress-Filter-IPFilterDat>
to report and view bugs, or to request features.

Alternatively, email F<bug-Net-IPAddress-Filter-IPFilterDat@rt.cpan.org>

=head1 REPOSITORY

L<Net::IPAddress::Filter::IPFilterDat> is hosted on github at F<https://github.com/d5ve/p5-Net-IPAddress-Filter-IPFilterDat.git>

=head1 AUTHOR

Dave Webb <Net-IPAddress-Filter-IPFilterDat@d5ve.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dave Webb.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
