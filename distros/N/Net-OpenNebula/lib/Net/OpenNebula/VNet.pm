#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#
# !no_doc!
use strict;
use warnings;

package Net::OpenNebula::VNet;
$Net::OpenNebula::VNet::VERSION = '0.311.0';
use version;

use Net::OpenNebula::RPC;
push our @ISA , qw(Net::OpenNebula::RPC);

use constant ONERPC => 'vn';
use constant ONEPOOLKEY => 'VNET';
use constant NAME_FROM_TEMPLATE => 1;

sub create {
   my ($self, $tpl_txt, %option) = @_;
   return $self->_allocate([ string => $tpl_txt ],
                           [ int => (exists $option{cluster} ? $option{cluster} : -1) ],
                           );
}

sub used {
   my ($self) = @_;
   my $tl = $self->_get_info_extended('TOTAL_LEASES');
   if ($tl->[0]) {
       return 1;
   }
};

# New since 4.8.0
sub _ar {
    my ($self, $txt, $mode) = @_;

    if ($self->{rpc}->version() < version->new('4.8.0')) {
        $self->error("AR RPC API new since 4.8.0");
        return;
    }

    $mode = "add" if (! ($mode && $mode =~ m/^(add|rm|update)$/));

    my $what = [ string => $txt ];
    if ($mode =~ m/^(rm|free)$/) {
        if ($txt =~ m/^\d+$/) {
            $what = [ int => $txt ];
        } else {
            $self->error("_ar mode $mode expects integer ID, got $txt");
            return;
        }
    };

    return $self->_onerpc("${mode}_ar",
                          [ int => $self->id ],
                          $what,
                          );
}

sub addar {
    my ($self, $txt) = @_;
    return $self->_ar($txt, "add");
}

# the id is in the template as AR_ID
sub updatear {
    my ($self, $txt) = @_;
    return $self->_ar($txt, "update");
}

sub rmar {
    my ($self, $id) = @_;
    return $self->_ar($id, "rm");
}

sub freear {
    my ($self, $id) = @_;
    return $self->_ar($id, "free");
}

# Find the AR matching opts
# opts are
#    ip : check that it is in range (assuming IPv4)
#    mac : check that it is in range
#    size : match if range is lower or equal the size
#    template : (try to) extract ip/mac/size from the template
#               ip/mac/size defined via opts take precedence
#    If more then opts is defined, all requirements have to fullfill
# Only one AR is returned (first one wins)
# (If no opts are specified, first AR is returned)
sub get_ar {
    my ($self, %opts) = @_;
    $self->verbose("get_ar: no options specified") if (! %opts);

    if ($opts{template}) {
        if(! exists($opts{mac}) && $opts{template} =~ m/[^#]*MAC\s*=\s*("|')((?:[0-9a-f]{2}:){5}[0-9a-f]{2})\1/i) {
            $opts{mac} = $2;
            $self->debug(1, "get_ar: found MAC $opts{mac} in template, none in opts");
        }

        if (! exists($opts{ip}) && $opts{template} =~ m/[^#]*IP\s*=\s*("|')((?:\d{1,3}\.){3}\d{1,3})\1/) {
            $opts{ip} = $2;
            $self->debug(1, "get_ar: found IP $opts{ip} in template, none in opts");
        }

        if (! exists($opts{size}) && $opts{template} =~ m/[^#]*SIZE\s*=\s*("|')(\d+)\1/) {
            $opts{size} = $2;
            $self->debug(1, "get_ar: found SIZE $opts{size} in template, none in opts");
        }
    }

    my %ar_pool = $self->get_ar_pool();
    return if (! %ar_pool);

    foreach my $id (sort keys %ar_pool) {
        my $msg = "get_ar AR_ID $id:";
        my $mac = $ar_pool{$id}->{MAC}->[0];
        my $ip = $ar_pool{$id}->{IP}->[0];
        my $size = $ar_pool{$id}->{SIZE}->[0];
        if(!defined($size)) {
            $self->debug(2, "$msg AR SIZE undefined, using 1");
            $size = 1;
        }

        # use inverse logic because all requirements have to match
        my $match = 1;

        # no match if requested size is larger then set one
        if (exists($opts{size}) && $opts{size} > $size) {
            $self->debug(2, "$msg NO match: requested size $opts{size} larger then AR Size $size");
            $match = 0;
        }

        if (exists($opts{mac})) {
            # get the range
            if(!defined($mac)) {
                $self->debug(2, "$msg NO match: requested mac $opts{mac}, but no MAC defined");
                $match = 0;
            } else {
                # http://www.perlmonks.org/?node_id=440768
                # Use doubles, no int (bit operators use ints)
                my $mac_hex2num = sub {
                    my $mac_hex = shift;
                    $mac_hex =~ s/://g;
                    $mac_hex = substr(('0'x12).$mac_hex, -12);
                    my @mac_bytes = unpack("A2"x6, $mac_hex);
                    my $mac_num = 0;
                    foreach (@mac_bytes) {
                        $mac_num = $mac_num * (2**8) + hex($_);
                    }
                    return $mac_num;
                };

                my $om = &$mac_hex2num($opts{mac});
                my $am = &$mac_hex2num($mac);
                # include boundaries of size?
                if( ($om < $am) || ($om > ($am + $size -1) )) {
                    $self->debug(2, "$msg NO match: requested mac $opts{mac} falls outside the range starting with AR MAC $mac and size $size (int mac $om AR MAC $am)");
                    $match = 0;
                }
            }
        }

        if (exists($opts{ip})) {
            # get the range
            if(!defined($ip)) {
                $self->debug(2, "$msg NO match: requested ip $opts{ip}, but no IP defined");
                $match = 0;
            } else {
                # Use doubles, no int (bit operators use ints)
                my $ip2num = sub {
                    my $ip = shift;
                    my $num = 0;
                    foreach (split(/\./, $ip)) {
                        $num = $num * (2**8) + $_;
                    }
                    return $num;
                };

                my $oi = &$ip2num($opts{ip});
                my $ai = &$ip2num($ip);
                # include boundaries of size?
                if( ($oi < $ai) || ($oi > ($ai + $size -1) )) {
                    $self->debug(2, "$msg NO match: requested ip $opts{ip} falls outside the range starting with AR IP $ip and size $size (int ip $oi AR IP $ai)");
                    $match = 0;
                }
            }
        }

        if($match) {
            $self->debug(1, "$msg found match, returning AR.");
            return $ar_pool{$id};
        } else {
            $self->debug(1, "$msg no match found, continuing.");
        }
    }
    $self->verbose("get_ar: no matching ARs found. Returning undef.");
    return;

}

# Using same opts as get_ar, returns the ID
sub get_ar_id {
    my($self, %opts) = @_;

    my $arref = $self->get_ar(%opts);
    if(defined($arref)) {
        my $id = $arref->{AR_ID}->[0];
        $self->verbose("get_ar_id: found ID $id");
        return $id;
    } else {
        $self->verbose("get_ar_id: no AR found");
    }
}

# Return hash with key=AR_ID, and value the AR instance
sub get_ar_pool  {
    my ($self) = @_;

    if ($self->{rpc}->version() < version->new('4.8.0')) {
        $self->error("AR RPC API new since 4.8.0");
        return;
    }

    my $ap = $self->_get_info_extended('AR_POOL');

    my %res;

    foreach my $arref (@{$ap->[0]->{AR}}) {
        my $id = int($arref->{AR_ID}->[0]);
        $res{$id} = $arref;
    }

    if (%res) {
        $self->verbose("AR POOL with ", scalar keys %res, " AR instances found");
    } else {
        $self->verbose("empty AR POOL");
    };

    return %res;
}


# Removed since 4.8.0
sub _leases {
    my ($self, $txt, $mode) = @_;

    if ($self->{rpc}->version() >= version->new('4.8.0')) {
        $self->error("Leases RPC API removed since 4.8.0");
        return;
    }

    $mode = "add" if (! ($mode && $mode =~ m/^(add|rm)$/));

    return $self->_onerpc("${mode}leases",
                          [ int => $self->id ],
                          [ string => $txt ]
                          );
}

sub addleases {
    my ($self, $txt) = @_;
    return $self->_leases($txt, "add");
}

sub rmleases {
    my ($self, $txt) = @_;
    return $self->_leases($txt, "rm");
}

1;
