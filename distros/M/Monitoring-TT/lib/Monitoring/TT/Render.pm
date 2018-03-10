package Monitoring::TT::Render;

use strict;
use warnings;
use utf8;
use Carp;
use Monitoring::TT::Log qw/error warn info debug trace log/;

#####################################################################

=head1 NAME

Monitoring::TT::Render - Render Helper Functions

=head1 DESCRIPTION

All functions from this render helper can be used in templates

=cut

#####################################################################

=head1 METHODS

=head2 die

    die(error message)

    die with an hopefully useful error message

=cut
sub die {
    my( $msg ) = @_;
    return croak($msg);
}

#####################################################################

=head2 _warn

    _warn(message)

=cut
sub _warn {
    return warn(@_);
}

#####################################################################

=head2 _die

    _die(message)

=cut
sub _die {
    return __PACKAGE__::die(@_);
}

#####################################################################

=head2 _info

    _info(message)

=cut
sub _info {
    return info(@_);
}

#####################################################################

=head2 _error

    _error(message)

=cut
sub _error {
    return error(@_);
}

#####################################################################

=head2 _debug

    _debug(message)

=cut
sub _debug {
    return debug(@_);
}

#####################################################################

=head2 _trace

    _trace(message)

=cut
sub _trace {
    return trace(@_);
}

#####################################################################

=head2 _log

    _log(lvl, message)

=cut
sub _log {
    return log(@_);
}

#####################################################################

=head2 uniq

    uniq(objects, attr)
    uniq(objects, attr, name)

    returns list of uniq values for one attr of a list of objects

    ex.:

    get uniq list of group items
    uniq(hosts, 'group')

    get uniq list of test tags
    uniq(hosts, 'tag', 'test')

=cut
sub uniq {
    my( $objects, $attrlist , $name ) = @_;
    croak('expected list of objects') unless ref $objects eq 'ARRAY';
    my $uniq = {};
    for my $o (@{$objects}) {
        for my $attr (@{_list($attrlist)}) {
            if($name) {
                next unless defined $o->{$attr};
                next unless defined $o->{$attr}->{$name};
                for my $v (split(/\s*\|\s*|\s*,\s*/mx, $o->{$attr}->{$name})) {
                    $uniq->{$v} = 1;
                }
            } else {
                next unless defined $o->{$attr};
                my $tmp = $o->{$attr};
                if(ref $tmp ne 'ARRAY') { my @tmp = split(/\s*,\s*/mx,$tmp); $tmp = \@tmp; }
                for my $a (@{$tmp}) {
                    $uniq->{$a} = 1;
                }
            }
        }
    }
    my @list = keys %{$uniq};
    return \@list;
}

#####################################################################

=head2 uniq_list

    uniq_list(list1, list2, ...)

    returns list of uniq values in all lists

=cut
sub uniq_list {
    return join_hash_list(@_) if defined $_[0] and ref $_[0] eq 'HASH';
    my $uniq = {};
    for my $list (@_) {
        if(ref $list eq 'HASH') {
            for my $i (keys %{$list}) {
                $i =~ s/^\s+//mx;
                $i =~ s/\s+$//mx;
                $uniq->{$i} = 1;
            }
        }
        elsif(ref $list eq 'ARRAY') {
            for my $i (@{$list}) {
                my $tmp = uniq_list($i);
                if(ref $tmp eq '') { $tmp = [split(/\s*,\s*/mx, $tmp)]; }
                for my $k (@{$tmp}) {
                    $k =~ s/^\s+//mx;
                    $k =~ s/\s+$//mx;
                    $uniq->{$k} = 1;
                }
            }
        }
        elsif(ref $list eq '') {
            $list =~ s/^\s+//mx;
            $list =~ s/\s+$//mx;
            $uniq->{$list} = 1;
        }
        else {
            croak('unexpected objects type in uniq_list()'.(ref $list));
        }
    }
    my @items = sort keys %{$uniq};
    return \@items;
}

#####################################################################

=head2 join_hash_list

    join_hash_list($hashlist, $exceptions)

    returns list csv list for hash but leave out exceptions

=cut
sub join_hash_list {
    my($hash, $exceptions) = @_;
    return "" unless defined $hash;
    my $list = [];
    for my $key (sort keys %{$hash}) {
        my $skip = 0;
        for my $ex (@{_list($exceptions)}) {
            if($key =~ m/$ex/mx) {
                $skip = 1;
                last;
            }
        }
        next if $skip;
        for my $val (@{_list($hash->{$key})}) {
            if($val) {
                push @{$list}, $key.'='.$val;
            } else {
                push @{$list}, $key;
            }
        }
    }
    $list = uniq_list($list);
    return join(', ', sort @{$list});
}

#####################################################################

=head2 lower

    lower(str)

    returns lower case string

=cut
sub lower {
    return lc($_[0]);
}

#####################################################################

=head2 services

    services()

    returns list of services

=cut
sub services {
    my $tt = $Monitoring::TT::Render::tt;
    if($tt->{'data'}->{'services'}) {
        return($tt->{'data'}->{'services'});
    }
    my $reader = Monitoring::TT::Input::Nagios->new(montt => $tt);
    my $data = $reader->read($tt->{'out'}.'/conf.d/', '');
    my @services;
    for my $o (@{$data}) {
        push @services, $o if $o->{'type'} eq 'service';
    }
    $tt->{'data'}->{'services'} = \@services;
    return($tt->{'data'}->{'services'});
}

#####################################################################
sub _list {
    my($data) = @_;
    return([]) unless defined $data;
    return($data) if ref $data eq 'ARRAY';
    return([$data]);
}
#####################################################################

=head1 AUTHOR

Sven Nierlein, 2013, <sven.nierlein@consol.de>

=cut

1;
