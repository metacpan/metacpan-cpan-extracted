##- Nanar <nanardon@zarb.org>
##-
##- This program is free software; you can redistribute it and/or modify
##- it under the terms of the GNU General Public License as published by
##- the Free Software Foundation; either version 2, or (at your option)
##- any later version.
##-
##- This program is distributed in the hope that it will be useful,
##- but WITHOUT ANY WARRANTY; without even the implied warranty of
##- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##- GNU General Public License for more details.
##-
##- You should have received a copy of the GNU General Public License
##- along with this program; if not, write to the Free Software
##- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id$

package RPM4::Media;

use strict;
use RPM4::Index;
use RPM4::Header;

# $options = {
# prefixurl if need, ie real rpms locations
# type => rpms, hdlist, headers
# source => $ (hdlist,dir) or @ (rpms, headers)
sub new {
    my ($class, %options) = @_;
    my $media = {
        hdlist => undef,
        synthesis => undef,
        list => 'list',
        rpmsdir => undef,
        
        rpms => [],

        rpmn2path => {},
        id2path => {},

        info => undef,
        
        hdr => [],

        use_light_header => 1,
    };

    foreach (keys %$media) {
        defined($options{$_}) and $media->{$_} = $options{$_};
    }
    
    bless($media, $class);
}

sub init {
    my ($self, $callback) = @_;
    
    $self->{hdr} = [];
    $self->{hdrid} = [];
    my %reqfiles;
    $self->{selectedhdrid} = {};
    $self->{reqfiles} = [];

    $callback ||= sub {
        my (%arg) = @_;
        @reqfiles{$arg{header}->requiredfiles()} = ();
        1;
    };

    if (defined(my $synthesis = $self->get_indexfile('synthesis'))) {
        RPM4::Index::parsesynthesis(
            synthesis => $synthesis,
            callback => sub {
                my %arg = @_;
                $callback->(%arg) or return;
                push(@{$self->{hdr}}, $arg{header});
            },
        );
    } elsif (defined(my $hdlist = $self->get_indexfile('hdlist'))) {
        RPM4::Index::parsehdlist(
            hdlist => $hdlist,
            callback => sub {
                my %arg = @_;
                $callback->(%arg) or return;
                $self->{selectedhdrid}{$arg{header}->tag('HDRID')} = 1;
            },
        );
    } elsif (defined($self->{rpms})) {
        my @rpms = grep { defined($_) } map { $self->get_rpm($_) } @{$self->{rpms}};
        RPM4::parserpms(
            rpms => \@rpms,
            callback => sub {
                my %arg = @_;
                $callback->(%arg) or return;
                $self->{selectedhdrid}{$arg{header}->tag('HDRID')} = 1;
            },
        );
    }
    $self->{reqfiles} = [ keys %reqfiles ];
}

sub load {
    my ($self, $reqfiles) = @_;
    $reqfiles ||= $self->{reqfiles};

    if (defined($self->get_indexfile('synthesis'))) {
        # populate is done during first pass
    } elsif (defined(my $hdlist = $self->get_indexfile('hdlist'))) {
        RPM4::Index::parsehdlist(
            hdlist => $hdlist,
            callback => sub {
                my %arg = @_;
                $self->{selectedhdrid}{$arg{header}->tag('HDRID')} or return;
                if ($self->{use_light_header}) {
                    my $h = $arg{header}->getlight($reqfiles);
                    push(@{$self->{hdr}}, $h);
                } else {
                    push(@{$self->{hdr}}, $arg{header});
                }
            },
        );
    } elsif (defined($self->{rpms})) {
        my @rpms = grep { defined($_) } map { $self->get_rpm($_) } @{$self->{rpms}};
        RPM4::parserpms(
            rpms => \@rpms,
            callback => sub {
                my %arg = @_;
                $self->{selectedhdrid}{$arg{header}->tag('HDRID')} or return;
                if ($self->{use_light_header}) {
                    my $h = $arg{header}->getlight($reqfiles);
                    push(@{$self->{hdr}}, $h);
                } else {
                    push(@{$self->{hdr}}, $arg{header});
                }
                $self->{id2path}{$#{$self->{hdr}}} = $arg{rpm};
            },
        );
    }
    delete($self->{reqfiles});
    delete($self->{selectedhdrid});

    if (my $listf = $self->get_indexfile('list')) {
        if (open(my $lh, "<", $listf)) {
            while (my $line = <$lh>) {
                chomp($line);
                my ($fullname) = $line =~ m,^(?:.*/)?(.*)\.rpm$,;
                $self->{rpmn2path}{$fullname} = $line;
            }
            close($lh);
        }
    }
}

sub traverse {
    my ($self, $callback) = @_;
    
    foreach my $id (0 .. $#{$self->{hdr} || []}) {
        my $header = $self->{hdr}[$id];
        $callback->($header, $id) or return;
    }
}

sub get_header {
    my ($self, $id) = @_;
    return $self->{hdr}[$id];
}

sub get_indexfile {
    my ($self, $file) = @_;
    defined($self->{$file}) or return undef;
    my $f =
        (substr($self->{$file}, 0, 1) ne '/' && defined($self->{rpmsdir}) ? "$self->{rpmsdir}/" : "") . 
        $self->{$file};
    -e $f ? $f : undef;
}

sub id2rpm {
    my ($self, $id) = @_;
    my $rpm = $self->get_header($id)->fullname;
    return exists($self->{rpmn2path}{$rpm}) ? $self->{rpmn2path}{$rpm}  :
        (exists($self->{id2path}{$id}) ? $self->{id2path}{$id} : "$rpm.rpm");
}

sub get_rpm {
    my ($self, $rpm) = @_;
    my $file =
        (substr($rpm, 0, 1) ne '/' && defined($self->{rpmsdir}) ? "$self->{rpmsdir}/" : "") .
        $rpm;
    -e $file ? $file : undef;
}

1;
