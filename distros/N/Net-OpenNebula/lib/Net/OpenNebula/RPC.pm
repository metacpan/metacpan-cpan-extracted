use strict;
use warnings;

package Net::OpenNebula::RPC;
$Net::OpenNebula::RPC::VERSION = '0.317.0';
use Data::Dumper;

use constant ONERPC => 'rpc';
use constant ONEPOOLKEY => undef;
use constant NAME_FROM_TEMPLATE => 0;


# If cacche->{add} attibute is true, add the cache for the following method
# If cacche->{remove} attribute is true, remove the cache for the following method
# The cache is removed before it is added (e.g. in case you want to refresh)
sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   $self->{ONERPC} = $proto->ONERPC;

   $self->{cache}->{add} = 0;
   $self->{cache}->{remove} = 0;

   bless($self, $proto);

   return $self;
}

sub _onerpc {
    my ($self, $method, @args) = @_;

	my $onemethod = "one.$self->{ONERPC}.$method";

    if ($self->{cache}->{remove}) {
        $self->{rpc}->remove_cache_method($onemethod);
        $self->{cache}->{remove} = 0;
    }

    if ($self->{cache}->{add}) {
        $self->{rpc}->add_cache_method($onemethod);
        $self->{cache}->{add} = 0;
    }

    return $self->{rpc}->_rpc($onemethod, @args);
}

sub _onerpc_id {
    my ($self, $method) = @_;

    $self->has_id("_onerpc_id") || return;

    return $self->_onerpc($method,
                            [ int => $self->id ],
                          );

};

sub _onerpc_simple {
    my ($self, $method, $arg) = @_;

    $self->has_id("_onerpc_simple") || return;

    return $self->_onerpc($method,
                          [ string => "$arg" ],
                          [ int => $self->id ],
                         );
};


# return info call
# opts
#   clearcache: if set to 1, clears the cache and queries again
#   id: get info for other id (if missing, use $self->id)
# Return extended_data (and if not existing, rerieves and sets extended_data)
sub _get_info {
    my ($self, %option) = @_;

    my $id;
    if (exists $option{id}) {
        $id = $option{id} ;
    } else {
        $self->has_id("_get_info") || return;
        $id = $self->id;
    }

    if(! exists $self->{extended_data} || (exists $option{clearcache} && $option{clearcache} == 1)) {
        $self->{extended_data} = $self->_onerpc("info", [ int => $id ]);
    }

    return $self->{extended_data};
}

# Similar to _get_info, but will try with with clearcache if C<entry> can't be
# found in extended_data and it returns the entry in extended_data.
sub _get_info_extended {
    my ($self, $entry) = @_;
    $self->_get_info();

    if(! exists $self->{extended_data}->{$entry}) {
        $self->_get_info(clearcache => 1);
    }

    if(exists $self->{extended_data}->{$entry}) {
        $self->debug(2, "Entry $entry present in extended_data");
        return $self->{extended_data}->{$entry};
    } else {
        $self->debug(2, "Entry $entry still not present in extended_data");
        return []; # empty array ref
    }
}


sub name {
    my ($self) = @_;

    my $name;

    if (NAME_FROM_TEMPLATE) {
        my $ext_name = $self->_get_info_extended('NAME');

        $name = $ext_name->[0];
    }

    if (!defined($name)) {
        $name = $self->{data}->{NAME}->[0];
        if (! $name) {
            my $template = $self->_get_info_extended('TEMPLATE');
            # if vm NAME is set, use that instead of template NAME
            $name = $template->[0]->{NAME}->[0];
        }
    }

    return $name;
}

sub id {
   my ($self) = @_;
   return $self->{data}->{ID}->[0];
}

# just check if the id is valid or not (returned result to be used as boolean)
sub has_id {
    my ($self, $msg) = @_;
    my $id = $self->id;

    if (defined($id)) {
        return 1;
    } else {
        $self->error("$self->{ONERPC}: no valid id ($msg)");
        return 0;
    }
};

sub dump {
    my $self = shift;
    return Dumper($self);
}

sub _allocate {
    my ($self, @args) = @_;

    my $id = $self->_onerpc("allocate", @args);

    if (! defined($id)) {
        my $args_txt = $self->{rpc}->_rpc_args_to_txt(@args);
        $self->error("$self->{ONERPC}: _allocate failed, no id returned (arguments $args_txt).");
        return;
    }

    $self->debug(1, "$self->{ONERPC} allocate returned id $id");

    my $data = $self->_get_info(id => $id);
    if (defined($data)) {
        $self->{data} = $data;
        $self->debug(3, "$self->{ONERPC} allocate updated data for id $id");
        return $id;
    } else {
        $self->error("$self->{ONERPC} allocate updated data failed for id $id");
        return;
    }
}

sub delete {
    my ($self) = @_;

    $self->has_id("delete") || return;

    $self->debug(1, "$self->{ONERPC} delete id ".$self->id);
    return $self->_onerpc_id("delete");
}

sub update {
    my ($self, $tpl, $merge) = @_;

    # reset $merge to integer value; undef implies merge = 0
    if ($merge) {
        $merge = 1;
    } else {
        $merge = 0;
    }

    $self->has_id("update") || return;

    return $self->_onerpc("update",
                          [ int => $self->id ],
                          [ string => $tpl ],
                          [ int => $merge ]
                          );
}

sub _lookup
{
    my ($self, $type, $id, $one) = @_;

    $id = -1 if ! defined($id);

    my $err;
    if ($id !~ m/^-?\d+$/) {
        my $msg = "Non-integer ${type}name $id";
        if ($one) {
            my $method = "get_${type}s";
            $self->debug(1, "$msg, looking up id using $method");
            my @found = $one->$method($id);
            if (@found) {
                if (scalar @found > 1) {
                    $self->warn("$msg and more than one $type found: ".join(", ", @found));
                }
                $id = $found[0]->id();
                $self->debug(1, "$msg resolved to id $id");
            } else {
                $err = "$msg and no matching ${type}s found.";
            }
        } else {
            $err = "$msg and no ONE instance provided";
        }
    }

    if ($err) {
        $self->error($err);
        return;
    } else {
        return $id;
    }
}


# Chown
# options
#    uid : uid to use
#    gid : gid to use
#    one : Net::OpenNebula instance to use for user/groupname lookup
#          (i.e. when uid/gid is not a integer)
#          It wil use $one->get_users and/or $one->get_groups methods.

sub chown
{
    my ($self, %opts) = @_;

    $self->has_id("chown") || return;

    my $uid = $self->_lookup('user', $opts{uid}, $opts{one});
    return if ! defined($uid);

    my $gid = $self->_lookup('group', $opts{gid}, $opts{one});
    return if ! defined($gid);

    return $self->_onerpc("chown",
                          [ int => $self->id ],
                          [ int => $uid ],
                          [ int => $gid ]
                          );
}


# Mode can be
#   an integer, typical in octal mode 0664, but can be decimal or whatever
sub chmod
{
    my ($self, $mode) = @_;

    $self->has_id("chmod") || return;

    my @bits;
    if ($mode =~ m/^\d+/) {
        my $bin = sprintf("%b", $mode & oct("777"));
        @bits = split('', $bin);
    } else {
        $self->error("chown cannot handle mode $mode");
        return;
    };

    if((scalar @bits) == 9) {
        my @allargs = qw(chmod);
        push(@allargs, [ int => $self->id ], map {[ int => $_ ]} @bits);
        return $self->_onerpc(@allargs);
    } else {
        $self->error("9 permissions bits required, got ".join(",", @bits));
        return;
    }
}


# When C<nameregex> is defined, only instances with name matching
# the regular expression are returned (if any).
# C<nameregex> is a compiled regular expression (e.g. qr{^somename$}).
sub _get_instances {
    my ($self, $nameregex, @args) = @_;

    my $class = ref $self;
    my $pool = $class->ONERPC . "pool";
    my $key = $class->ONEPOOLKEY || uc($class->ONERPC);

    my @ret = ();
    my $info = "info";

    # Change VM info by new infoextended if version >= 5.8.x
    if (($self->{rpc}->version() >= version->new('5.8.0')) and ($pool eq "vmpool")) {
        $info = 'infoextended';
        push(@args, [ string => "" ]);
    };

    my $reply = $self->{rpc}->_rpc("one.$pool.$info", @args);

    foreach my $data (@{ $reply->{$key} }) {
        # This is data from pool.info, so it is as complete as individual info
        # so we can set it as extended_data
        my $inst = $self->new(rpc => $self->{rpc}, data => $data, extended_data => $data);
        if (! defined($nameregex) || ($inst->name && $inst->name =~ $nameregex) ) {
            push(@ret, $inst);
        }
    }

    return @ret;
}

# Given state, wait until the state is reached.
# Between each check, sleep number of seconds;
# and there's a maximum number of iterations to try.
# Return 1 if the state is reached, 0 otherwise.
# state: the state (in text) to wait for
# opts:
#    sleep: sleep per interval
#    max_iter: maximum iterations (if 0, no sleep)
sub wait_for_state {
    my ($self, $state, %opts) = @_;

    my $sleep = 5; # in seconds
    my $max_iter = 200; # approx 15 minutes with default sleep
    $sleep = $opts{sleep} if defined($opts{sleep});
    $max_iter = $opts{max_iter} if defined($opts{max_iter});

    my $currentstate = $state eq $self->state;
    my $ind = 1; # first state fetched, no sleep involved
    while ($ind < $max_iter && ! $currentstate) {
        sleep($sleep);
        $currentstate = $state eq $self->state;
        $ind +=1;
    }

    return $currentstate;

}

# add logging shortcuts
no strict 'refs'; ## no critic
foreach my $i (qw(error warn info verbose debug)) {
    *{$i} = sub {
        my ($self, @args) = @_;
        return $self->{rpc}->{log}->$i(@args);
    }
}
use strict 'refs';

1;
