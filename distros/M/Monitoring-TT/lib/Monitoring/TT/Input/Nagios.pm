package Monitoring::TT::Input::Nagios;

use strict;
use warnings;
use utf8;
use Monitoring::TT::Log qw/error warn info debug trace/;
use Monitoring::TT::Utils;

#####################################################################

=head1 NAME

Monitoring::TT::Input::Nagios - Input Nagios data

=head1 DESCRIPTION

Nagios Input for Hosts and Contacts

=cut

#####################################################################

=head1 CONSTRUCTOR

=head2 new

  new(%options)

=cut

sub new {
    my($class, %options) = @_;
    my $self = {
        'types' => [ 'hosts', 'contacts' ],
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
        for my $type (sort @{$self->{'types'}}) {
            my $pattern = $dir.'/'.$type.'*.cfg';
            trace('looking for nagios file: '.$pattern);
            my @files = glob($pattern);
            for my $f (@files) {
                debug('found nagios file: '.$f);
                push @{$types}, $type;
            }
        }
    }
    return Monitoring::TT::Utils::get_uniq_sorted($types);
}

#####################################################################

=head2 read

read nagios file

=cut
sub read {
    my($self, $dir, $type) = @_;
    my $data = [];
    my $pattern = $dir.'/'.$type.'*.cfg';
    my @files = glob($pattern);
    my $current = { 'conf' => {}};
    my $in_obj  = 0;
    for my $file (@files) {
        info("reading $type from $file");

        my $output   = "";
        if($self->{'montt'}) {
            my $template = $self->{'montt'}->_process_template($self->{'montt'}->_read_replaced_template($file));
            $self->{'montt'}->tt->process(\$template, {}, \$output) or $self->{'montt'}->_template_process_die($file, $data);
        } else {
            open(my $fh, '<', $file) or die("cannot read: ".$file.': '.$!);
            while(my $line = <$fh>) {
                $output .= $line;
            }
            close($fh);
        }

        my $in_type;
        for my $line (split(/\n/mx, $output)) {
            next if substr($line, 0, 1) eq '#';
            next if $line =~ m/^\s*$/gmx;
            chomp($line);
            if($line =~ m/^\s*define\s+(\w+)($|\s|{)/mx) {
                $in_type = $1;
                if($type && $in_type.'s' ne $type) {
                    warn("unexpected input type '".$in_type."' in ".$file.':'.$.);
                    next;
                }
                $in_obj = 1;
            } elsif($in_obj) {
                if($line =~ m/^\s*}/mx) {
                    $in_obj = 0;

                    # bring tags in shape
                    $current->{'tags'} = Monitoring::TT::Utils::parse_tags(delete $current->{'conf'}->{'_tags'});

                    # bring groups in shape
                    $current->{'groups'} = Monitoring::TT::Utils::parse_groups(delete $current->{'conf'}->{'_groups'});

                    # bring apps in shape
                    $current->{'apps'} = Monitoring::TT::Utils::parse_tags(delete $current->{'conf'}->{'_apps'}) if $in_type eq 'host';

                    # transfer type and some other attributes
                    $current->{'type'}  = delete $current->{'conf'}->{'_type'};
                    $current->{'alias'} = $current->{'conf'}->{'alias'} || '';

                    if($in_type eq 'host') {
                        $current->{'name'}    = $current->{'conf'}->{'host_name'}   || '';
                        $current->{'address'} = $current->{'conf'}->{'address'}     || '';
                        $current->{'groups'}  = $current->{'conf'}->{'host_groups'} || $current->{'conf'}->{'hostgroups'} || [];
                    }
                    if($in_type eq 'contact') {
                        $current->{'name'}   = $current->{'conf'}->{'contact_name'}   || '';
                        $current->{'email'}  = $current->{'conf'}->{'email'}          || '';
                        $current->{'groups'} = $current->{'conf'}->{'contact_groups'} || $current->{'conf'}->{'contactgroups'} || [];
                    }
                    if($in_type eq 'service') {
                        $current->{'groups'}  = $current->{'conf'}->{'service_groups'} || $current->{'conf'}->{'servicegroups'} || [];
                    }

                    $current->{'type'} = $in_type unless $current->{'type'};

                    $current->{'file'} = delete $current->{'conf'}->{'_src'};
                    $current->{'file'} = $file unless $current->{'file'};
                    $current->{'file'} =~ s/:(\d+)$//gmx;
                    $current->{'line'} = defined $1 ? $1 : $.;

                    push @{$data}, $current;
                    $current = { 'conf' => {}};
                } else {
                    $line =~ s/^\s*//gmx;
                    $line =~ s/\s*$//gmx;
                    my($key,$val) = split/\s+/mx, $line, 2;
                    $key = lc $key;
                    $current->{'conf'}->{$key} = $val;
                }
            }
        }
        debug("read ".(scalar @{$data})." $type from $file");
    }
    return $data;
}

#####################################################################
# internal subs
#####################################################################

#####################################################################

=head1 AUTHOR

Sven Nierlein, 2013, <sven.nierlein@consol.de>

=cut

1;
