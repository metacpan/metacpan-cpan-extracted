#!/usr/local/bin/perl
# =============================================================================
# tinymrtg.pl - Tiny Multi Router Traffic Grapher
# -----------------------------------------------------------------------------
$main::VERSION = '1.04';
# -----------------------------------------------------------------------------

=head1 NAME

tinymrtg.pl - Tiny Multi Router Traffic Grapher

=head1 SYNOPSIS

    $ tinymrtg.pl [-c COMMUNITY_NAME] [-x REGEXP] HOST [HOST [...]]

    COMMUNITY_NAME ... SNMP Community Name. Omitting uses 'public'.
    REGEXP         ... Specify regular expression for pickup IFs by name.
    HOST           ... Target hosts to check.

    Environment Variables:
    PATH2DATADIR   ... Path to data directry where files are stored.
    URL2HTMLDIR    ... URL which specifys PATH2DATADIR via HTTP service.

    This program is for devices which can deal SNMP version 2c.

=head1 DESCRIPTION

With installing Tobias Oetiker's RRDtool and RRD::Simple, this sample will do
like MRTG. (It is better to execute this by cron. And note that RRD::Simple
creates RRD files with 10 min. intervals when using schema 'mrtg')

If Environmental variables, PATH2DATADIR and URL2HTMLDIR, are defined, files will
be stored under PATH2DATADIR and URL pathes will include URL2HTMLDIR in html.
Or Modify $datadir and $htmldir to decide these path and URL where browser can
access through your http service.

=head1 NOTE

This script is a sample of C<Net::SNMP::Util>.
This program is for devices which can deal SNMP version 2c.

=cut

use strict;
use warnings;
use Getopt::Std;
use CGI qw(:html);
use RRD::Simple;        # install the "RRDtool" and RRD::Simple
use Net::SNMP::Util qw(:para);

my %opt;
getopts('hc:x:', \%opt);
my @hosts = @ARGV;

sub HELP_MESSAGE {
    print "Usage: $0 [-c COMMUNITY_NAME] [-x REGEXP] HOST [HOST [...]]\n";
    exit 1;
}
HELP_MESSAGE() if ( !@hosts || $opt{h} );

my $datadir = $ENV{PATH2DATADIR} || "/path/to/datadir";   # !!! Modify !!!
my $htmldir = $ENV{URL2HTMLDIR}  || "/path/to/htmldir";   # !!! Modify !!!
my $regexp  = $opt{x}? qr/$opt{x}/: '';
my %sesopts = ( -version => 2, -community=> ($opt{c} || 'public') );

sub escname {
    my $n = shift;
    $n =~ tr/\\\/\*\?\|"<>:,;%/_/;
    return $n;
}

# gather traffic data and store to RRD
my ($result, $error) = snmpparawalk(
    hosts => \@hosts,
    snmp  => \%sesopts,
    oids  => {
        ifData => [ '1.3.6.1.2.1.31.1.1.1.1',   # ifName
                    '1.3.6.1.2.1.31.1.1.1.6',   # ifHCInOctets
                    '1.3.6.1.2.1.31.1.1.1.10' ] # ifHCOutOctets
    },

    # this callback will work everything of necessary
    -mycallback => sub {
        my ($s, $host, $key, $val) = @_;
        # val=[[index,name], [index,inOcts], [index,outOcts]]
        my ($index, $name) = @{$val->[0]};

        # check necessarity by ifName
        return 0 if ( $regexp && $name !~ /$regexp/ );

        my $basename = "$host.".escname($name);
        my $rrdfile  = "$datadir/$basename.rrd";

        # treat RRD
        my $rrd = RRD::Simple->new( file => $rrdfile );

        #eval { # wanna catch an error, uncomment here.
        $rrd->create($rrdfile, 'mrtg',
            'in'  => 'COUNTER', 'out' => 'COUNTER'
        ) unless -e $rrdfile;
        $rrd->update( $rrdfile, time,
            'in'  => $val->[1][1], 'out' => $val->[2][1]
        );
        $rrd->graph( $rrdfile,
            destination => $datadir,
            basename    => $basename,
            title       => "$host :: $name",
            sources          => [ qw( in       out      ) ],
            source_labels    => [ qw( incoming outgoing ) ],
            source_colors    => [ qw( 00cc00   0000ff   ) ],
            source_drawtypes => [ qw( AREA     LINE1    ) ]
        );
        #}; warn "[EVAL ERROR] $@" if $@;

        return 1;
    }
);
die "[ERROR] $error\n" unless $result;

# make html
sub mkimgtag {
    my ($host, $name, $type) = @_;
    my $basename = escname($name);
    img({ -src   => "$htmldir/$host.$basename-$type.png",
          -alt   => "$host $name $type",
          -title => "$type graph of $host $name",
          -border=> 0 });
}

open(HTML,"> $datadir/index.html") or die "$!";
print HTML start_html(
    -title=> 'Traffic Monitor',
    -head => meta({ -http_equiv => 'refresh',
                    -content    => 300 })
), h1('Traffic Monitor');

foreach my $host ( sort @hosts ){
    print HTML h2($host);
    foreach my $i ( sort keys %{$result->{$host}{ifData}[0]} ){
        my $name     = $result->{$host}{ifData}[0]{$i};
        my $subhtml  = "$host.".escname($name).".html";

        printf HTML a( {-href=>"$htmldir/$subhtml"},
            mkimgtag($host, $name, 'daily')
        );

        if ( open(HTML2,"> $datadir/$subhtml") ){
            print HTML2 start_html(
                    -title=> 'Traffic Monitor',
                    -head => meta({ -http_equiv => 'refresh',
                                    -content    => 300 }) ),
                h1("$host $name"),
                (map { h2($_).p(mkimgtag($host, $name, $_)) }
                    qw(daily weekly monthly annual)),
                end_html();
            close(HTML2);
        } else {
            warn "$!";
        }
    }
}

print HTML end_html();
close(HTML);
__END__


=head1 EXAMPLES

It is better to modify definition of C<$datadir> and C<$htmldir> to your path.
Of course, your HTTP service must run already.

The basic way to run this program is like;

    example% tinymrtg.pl -c yes5 dream rouge lemonade mint aqua

It is important to except unnecessary ports (e.g. management port), so use
C<-x> option.

    example% tinymrtg.pl -c yes5gogo -r '^\d+/\d+$' milkyrose

I think it is a way to use hosts file for checking devices out of DNS.

    example% tinymrtg.pl -c yes5gogo -r '^\d+/\d+$' \
    `cat /etc/hosts | awk '/\.precure\./{print $2}'`

Its good way to edit crontable to execute this automatically and periodically.

    0,5,10,15,20,25,30,35,40,45,50,55 * * * * /path/to/tinymrtg.pl ...


=head1 REQUIREMENTS

RRDtool - This sample uses the advantage of RRDtool, RoundRobinDatabase Tool.
C<Net::SNMP>,C<CGI> and L<RRD::Simple>.


=head1 AUTHOR

t.onodera, C<< <cpan :: garakuta.net> >>


=head1 SEE ALSO

Tobias Oetiker's MRTG - http://oss.oetiker.ch/mrtg/
Tobias Oetiker's RRDtool - http://www.mrtg.org/rrdtool/

L<Net::SNMP> - Core module of C<Net::SNMP::Util> which brings us good SNMP
implementations.
L<Net::SNMP::Util::OID> - Sub module of C<Net::SNMP::Util> which provides
easy and simple functions to treat OID.
L<Net::SNMP::Util::TC> - Sub module of C<Net::SNMP::Util> which provides
easy and simple functions to treat textual conversion.


=head1 LICENSE AND COPYRIGHT

Copyright(C) 2011- Takahiro Ondoera.

This program is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
