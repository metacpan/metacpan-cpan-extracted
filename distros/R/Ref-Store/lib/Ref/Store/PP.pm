package Ref::Store::PP::Key;
use strict;
use warnings;
use Scalar::Util qw(weaken refaddr);
use Ref::Store::Common;
use Carp::Heavy;
use Ref::Store::PP::Magic;

use base qw(Ref::Store::Key);

sub new {
    my ($cls,$scalar,$table) = @_;
    
    my $self = [];
    @{$self}[HR_KFLD_STRSCALAR, HR_KFLD_REFSCALAR, HR_KFLD_TABLEREF] =
        ("$scalar", $scalar, $table);
    bless $self, $cls;
    
    $table->scalar_lookup->{$scalar} = $self;
    weaken($table->scalar_lookup->{$scalar});
    
    hr_pp_trigger_register($self,$table->forward,"$scalar");
    hr_pp_trigger_register($self,$table->scalar_lookup,"$scalar");
    return $self;
}

sub ithread_predup {
    #Perl data structures are still valid here..
}

sub ithread_postdup {
    #PP::Magic information is dup'd as well, nothing for us here. Key is static
}

package Ref::Store::PP::Key::Encapsulating;
use strict;
use warnings;
use base qw(Ref::Store::PP::Key);
use Ref::Store::Common;
use Ref::Store::Common qw(:pp_constants);
use Ref::Store::PP::Magic;
use Scalar::Util qw(weaken isweak);
use Log::Fu;
use Ref::Store::ThreadUtil;
use Devel::GlobalDestruction;

use constant HR_KFLD_VHREF => HR_KFLD_AVAILABLE() + 1;

use Devel::Peek qw(Dump);

sub new {
    my ($cls,$obj,$table) = @_;
    my $self = [];
    @{$self}[HR_KFLD_STRSCALAR, HR_KFLD_REFSCALAR, HR_KFLD_TABLEREF] =
        ($obj+0, $obj, $table);
    
    #log_err("Creating new encapsulating key for object", $obj+0);
    hr_pp_trigger_register($obj, $table->scalar_lookup,$obj+0);
    
    weaken($table->scalar_lookup->{$obj+0} = $self);
    
    bless $self, $cls;
    return $self;
}


sub ithread_predup {
    my ($self,$table,$ptr_map,$value) = @_;
    hr_thrutil_store_kinfo(HR_THR_KENCAP_PREFIX, 
        $self->[HR_KFLD_STRSCALAR], $ptr_map, $value+0);
}

sub ithread_postdup {
    my ($self,$new_table,$ptr_map,$old_taddr) = @_;
    
    my $obj = $self->[HR_KFLD_REFSCALAR];
    my $old_objaddr = $self->[HR_KFLD_STRSCALAR];
    
    hr_pp_trigger_replace_key(
        $obj, $old_objaddr, $self->[HR_KFLD_TABLEREF]->scalar_lookup,
        $obj + 0);
    
    my $old_vaddr = hr_thrutil_get_kinfo(
        HR_THR_KENCAP_PREFIX, $old_objaddr, $ptr_map);
    if(!$old_vaddr) {
        print Dumper($ptr_map);
        die("Couldn't find old value for key");
    }
    my $vhash = $ptr_map->{
        HR_THR_LINFO_PREFIX . $old_taddr}->reverse->{$old_vaddr};
    if(!$vhash) {
        print Dumper($ptr_map->{HR_THR_LINFO_PREFIX.$old_taddr});
        die("Couldn't find old vhash! ($old_vaddr)");
    }
    hr_pp_trigger_replace_key(
        $obj, $old_objaddr, $vhash,
        $obj + 0);

    $self->[HR_KFLD_STRSCALAR] = $obj + 0;
}

sub link_value {
    my ($self,$value) = @_;
    my $obj = $self->[HR_KFLD_REFSCALAR];
    my $stored_privhash = $self->[HR_KFLD_TABLEREF]->reverse->{$value+0};
    hr_pp_trigger_register($obj, $stored_privhash, $obj+0);
}

sub unlink_value {
    my ($self,$value) = @_;
    my $obj = $self->[HR_KFLD_REFSCALAR];
    hr_pp_trigger_unregister($obj,
                             $self->[HR_KFLD_TABLEREF]->reverse->{$value+0},
                             $obj + 0
                             );
}

sub exchange_value {
    my ($self,$old,$new) = @_;
    $self->unlink_value($old);
    $self->link_value($new);
}


sub weaken_encapsulated {
    my $self = shift;
    weaken($self->[HR_KFLD_REFSCALAR]);
}


sub kstring {
    my $self = shift;
    $self->[HR_KFLD_STRSCALAR];
}

sub dump {
    my ($self,$hrd) = @_;
    $hrd->iprint("ENCAP: %s", $hrd->fmt_ptr($self->[HR_KFLD_REFSCALAR]));
}

#This is called:

# 1) When the reverse value entry is deleted:
#   ACTION: clean up encapsulated object magic
#
# 2) When the object itself has triggered
#   A deletion from the value's reverse entry.
#   ACTION: 

use Data::Dumper;

sub DESTROY {
    return if in_global_destruction;
    my $self = shift;
    my $table = $self->[HR_KFLD_TABLEREF];
    my $obj = $self->[HR_KFLD_REFSCALAR];
    my $obj_s = $self->[HR_KFLD_STRSCALAR];
    
    delete $table->scalar_lookup->{$obj_s};
    my $value = delete $table->forward->{$obj_s};
    
    if($obj) {
        hr_pp_trigger_unregister($obj, $table->scalar_lookup, $obj_s);
    }
    
    #log_info("Found stored.. $stored", $stored+0);
    
    return unless $value;
    my $vhash = $table->reverse->{$value+0};
    
    if(defined $value && defined $obj && defined $vhash) {
        hr_pp_trigger_unregister($obj, $vhash, $obj_s);
    }
    
    if(defined $vhash) {
        delete $vhash->{$self->[HR_KFLD_STRSCALAR]};
        if(!%$vhash) {
            #log_info("Table empty!");
            delete $table->reverse->{$value+0};
            hr_pp_trigger_unregister($value, $table->reverse, $obj_s);
        }
    }
}



package Ref::Store::PP;
use strict;
use warnings;
use Scalar::Util qw(weaken refaddr);
use base qw(Ref::Store);
use Ref::Store::PP::Magic;
use Ref::Store::Common qw(:pp_constants);
use Ref::Store::ThreadUtil;


use Log::Fu { level => "debug" };

sub new_key {
    my ($self,$ukey) = @_;
    my $cls = ref $ukey ? 'Ref::Store::PP::Key::Encapsulating' :
        'Ref::Store::PP::Key';
    $cls->new($ukey, $self);
}

sub dref_add {
    my ($self,$value,$target,$key) = @_;
    $key ||= $value+0;
    hr_pp_trigger_register($value,$target,$key);
}

sub dref_del {
    my ($self,$value,$target,$key) = @_;
    hr_pp_trigger_unregister($value, $target, $key);
}

*dref_add_str = \&dref_add;
*dref_add_ptr = \&dref_add;

*dref_del_ptr = \&dref_del;

#sub dref_add_str {
#    my ($self,$value,$target,$key) = @_;
#    hr_pp_trigger_register($value, $key, $target);
#}
#
#sub dref_add_ptr {
#    my ($self,$value,$target) = @_;
#    hr_pp_trigger_register($value, $value+0, $target);
#}
#
#sub dref_del_ptr {
#    my ($self,$value,$target,$mkey) = @_;
#    hr_pp_trigger_unregister($value,$target,$mkey);
#}

sub ithread_store_lookup_info {
    my ($self,$ptr_map) = @_;
    my $Linfo = Ref::Store::ThreadUtil::OldLookups->new($self);
    $ptr_map->{HR_THR_LINFO_PREFIX . ($self + 0) } = $Linfo;
}

1;
