package ossec::log::parse;
# ABSTRACT: Perl interface for parsing Ossec alert files

use strict;
use warnings;
use autodie;
use Carp;
use Scalar::Util qw/openhandle/;

our $VERSION = '0.1.0';

BEGIN {
    my @accessors = qw/fh file/;
    for my $accessor ( @accessors ) {
        no strict 'refs';
        *$accessor = sub {
            my $self = shift;
            return $self->{$accessor};
        }
    }
}

sub new {
    my $class = shift;
    my $arg = shift;

    my $self = {};

    if ( !defined($arg) ) {
        $self->{diamond} = 1;
    } elsif ( ref($arg) eq 'HASH' ) {
        $self = $arg;
    } elsif ( defined(openhandle($arg)) ) {
        $self->{fh} = $arg;
    } else {
        $self->{file} = $arg;
    }

    bless $self, $class;

    if ( defined($self->{file}) && !(defined($self->{fh})) ) {
        unless ( -f $self->{file} ) {
            carp("Could not open ".$self->{file});
            return 0;
        }
        open( my $fh, "<", $self->{file} ) or croak("Cannot open ".$self->{file});
        $self->{fh} = $fh;
    }

    if ( !defined($self->{fh}) && ( !defined($self->{diamond}) || !$self->{diamond} ) ) {
        carp("No filename given in constructor. Aborting");
        return 0;
    }

    return $self;
}

sub getAlert {

    my $self = shift;
    my $fh = $self->{fh};

    my %alert;
    my $position = 0;

    while ( my $line = defined($fh) ? <$fh> : <> ) {

        chomp($line);

        if ($line =~ m/^\*\* Alert (\d+\.\d+):(.*)-(.*)/) {
            $alert{'ts'} = $1;
            $alert{'type'} = $2;
            $alert{'group'} = $3;
            # clean up variables
            $alert{'type'} =~ s/^\s+|\s+$//g; # strip leading/trailing whitespace
            $alert{'group'} =~ s/^\s+|\s+$//g;
            $alert{'group'} =~ s/,$//g; # strip trailing comma
            $position = 1;
            next;
        }
        if ($position > 0) {
            $position++;
            if ($position == 2) {
                if ($line =~ m!(\d+ \w+ \d+ \d+:\d+:\d+) \((.*)\) (\S+)->(.*)!) { # alert from remote agent
                    $alert{'ts.human'} = $1;
                    $alert{'agent.name'} = $2;
                    $alert{'agent.ip'} = $3;
                    $alert{'location'} = $4;
                }
                elsif ($line =~ m!(\d+ \w+ \d+ \d+:\d+:\d+) (\S+)->(.*)!) { # alert from local agent
                    $alert{'ts.human'} = $1;
                    $alert{'agent.name'} = $2;
                    $alert{'agent.ip'} = '-';
                    $alert{'location'} = $3;
                }
                $alert{'2'} = $line;
                next;
            }
            elsif ($position == 3) {
                if ($line =~ /^Rule: (\d+) \(level (\d+)\) -> '(.*)'$/) {
                    $alert{'rule.id'} = $1;
                    $alert{'rule.level'} = $2;
                    $alert{'rule.comment'} = $3;
                    # clean up variable
                    $alert{'rule.comment'} =~ s/\.$//; # remove any trailing period
                }
                $alert{'3'} = $line;
                next;
            }
            elsif ($line !~ m/^$/ ) {
                if ($alert{'full_log'} ) {
                    $alert{'full_log'} = "$alert{'full_log'}\n$line";
                }
                else {
                    $alert{'full_log'} = $line;
                }
            }
            else {
                $position = 0;
                return \%alert;
            }
        }
    }
}

1;

