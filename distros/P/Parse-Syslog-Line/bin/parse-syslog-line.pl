#!perl
# PODNAME: parse-syslog-line.pl
# ABSTRACT: Parse a syslog message and display the structured data
use strict;
use warnings;

use Data::Printer;
use Getopt::Long::Descriptive;
use JSON;
use Parse::Syslog::Line qw( parse_syslog_line );
use YAML;

my $enc;
my %formats = (
    print => sub { p($_[0]) },
    json  => sub {
        $enc ||= JSON->new->utf8->canonical;
        printf "%s\n", $enc->encode($_[0]);
    },
    pretty  => sub {
        $enc ||= JSON->new->utf8->canonical->pretty;
        print $enc->encode($_[0]);
    },
    yaml => sub {
        print YAML::Dump($_[0]);
    },
);
my ($opt,$usage) = describe_options("%c %o",
    ['Output Format'],
    ['format' => 'hidden', {
        one_of => [
            [ print => 'Format with Data::Printer' ],
            [ json => 'Format as JSON, minified' ],
            [ pretty => 'Format as JSON, pretty' ],
            [ yaml => 'Format as YAML' ],
        ],
        default => 'print',
    }],
    [],
    ['Field Control'],
    ['empty|e',  'Display fields with undef or blank string', ],
    ['raw|r',    'Display the raw fields in the hash.',],
    ['all|a', 'Display all fields.', { implies => [qw(raw empty)] }],
    [],
    ['help', 'Display this help', { shortcircuit => 1 }],
);
if( $opt->help ) {
    print $usage->text;
    exit 0;
}


# Configure
$Parse::Syslog::Line::PruneEmpty = !$opt->empty;
$Parse::Syslog::Line::PruneRaw   = !$opt->raw;

while(<>) {
    my $msg = parse_syslog_line($_);
    $formats{$opt->format}->( $msg );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

parse-syslog-line.pl - Parse a syslog message and display the structured data

=head1 VERSION

version 4.2

=head1 SYNOPSIS

Use this utility to parse syslog lines to arbitrary formats.

    tail -1 /var/log/messages | parse-syslog-line.pl

For help, see:

    parse-syslog-line.pl --help

=head1 EXAMPLES

Use C<parse-syslog-line.pl> as a way to do things with L<jq|https://stedolan.github.io/jq/>:

    tail /var/log/messages | parse-syslog-line.pl --json |jq '.program'

See all the keys available,

    tail /var/log/messages | parse-syslog-line.pl --all

Output Pretty JSON:

    tail -1 /var/log/messages | parse-syslog-line.pl --pretty

Output prettier JSON:

    tail -1 /var/log/messages | parse-syslog-line.pl --json | jq '.'

Output as YAML:

    tail -1 /var/log/messages | parse-syslog-line.pl --yaml

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
