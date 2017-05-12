package Monitoring::TT::Input::CSV;

use strict;
use warnings;
use utf8;
use Monitoring::TT::Log qw/error warn info debug trace/;
use Monitoring::TT::Utils;

#####################################################################

=head1 NAME

Monitoring::TT::Input::CSV - Input CSV data

=head1 DESCRIPTION

CSV Input for Hosts and Contacts

=cut

#####################################################################

=head1 CONSTRUCTOR

=head2 new

  new(%options)

=cut

sub new {
    my($class, %options) = @_;
    my $self = {
        'fields' => {
            'hosts'    => [qw/name alias address type tags groups apps/],
            'contacts' => [qw/name alias email roles tags groups/],
        },
        'montt' => $options{'montt'},
    };
    bless $self, $class;
    return $self;
}

#####################################################################

=head1 METHODS

=head2 get_types

  get_types($list_of_folders)

  return supported types for this input type

=cut
sub get_types {
    my($self, $folders) = @_;
    my $types = [];
    for my $dir (@{$folders}) {
        for my $type (sort keys %{$self->{'fields'}}) {
            my $pattern = $dir.'/'.$type.'*.csv';
            trace('looking for csv file: '.$pattern);
            my @files = glob($pattern);
            for my $f (@files) {
                debug('found csv file: '.$f);
                push @{$types}, $type;
            }
        }
    }
    return Monitoring::TT::Utils::get_uniq_sorted($types);
}

#####################################################################

=head2 read

read csv file

=cut
sub read {
    my($self, $dir, $type) = @_;
    my $data = [];
    my $pattern = $dir.'/'.$type.'*.csv';
    my @files = glob($pattern);
    for my $file (@files) {
        info("reading $type from $file");
        open(my $fh, '<', $file) or die('cannot read '.$file.': '.$!);
        while(my $line = <$fh>) {
            next if substr($line, 0, 1) eq '#';
            chomp($line);
            next if $line =~ m/^\s*$/gmx;
            my @d = split(/\s*;\s*/mx, $line);
            my $d = {};
            my $x = 0;
            for my $k (@{$self->{'fields'}->{$type}}) {
                $d->{$k} = $d[$x];
                $x++;
            }

            $d->{'file'} = $file;
            $d->{'line'} = $.;

            # bring tags in shape
            $d->{'tags'} = Monitoring::TT::Utils::parse_tags($d->{'tags'});

            # bring groups in shape
            $d->{'groups'} = Monitoring::TT::Utils::parse_groups($d->{'groups'});

            # bring apps in shape
            $d->{'apps'} = Monitoring::TT::Utils::parse_tags($d->{'apps'}) if $type eq 'hosts';

            push @{$data}, $d;
        }
        close($fh);
        debug("read ".(scalar @{$data})." $type from $file");
    }
    return $data;
}

#####################################################################

=head1 AUTHOR

Sven Nierlein, 2013, <sven.nierlein@consol.de>

=cut

1;
