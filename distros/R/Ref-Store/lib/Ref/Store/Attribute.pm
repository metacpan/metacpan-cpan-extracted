package Ref::Store::Attribute;
use strict;
use warnings;
use Scalar::Util qw(weaken isweak);
use Ref::Store::Common;
use Data::Dumper;
use Log::Fu;


sub new {
    my ($cls,$scalar,$ref,$table) = @_;
    my $self = [];
    $#{$self} = HR_KFLD_ATTRHASH;
    
    bless $self, $cls;
    
    @{$self}[HR_KFLD_STRSCALAR, HR_KFLD_REFSCALAR,
            HR_KFLD_TABLEREF, HR_KFLD_ATTRHASH] =
        ($scalar, $ref, $table, {});
    
    return $self;
}

sub link_value {
    my ($self,$value) = @_;
    
    $self->[HR_KFLD_TABLEREF]->dref_add_ptr(
        $value,
        $self->[HR_KFLD_ATTRHASH],
        $value + 0
    );
}

sub unlink_value {
    my ($self,$value) = @_;
    
    $self->[HR_KFLD_TABLEREF]->dref_del_ptr(
        $value,
        $self->[HR_KFLD_ATTRHASH],
        $value + 0
    );
    
    delete $self->[HR_KFLD_ATTRHASH]->{$value+0};
}

sub weaken_encapsulated {
}

sub store_weak {
    my ($self,$k,$v) = @_;
    weaken($self->[HR_KFLD_ATTRHASH]->{$k} = $v);
}

sub store_strong {
    my ($self,$k,$v) = @_;
    $self->[HR_KFLD_ATTRHASH]->{$k} = $v;
}

sub get_hash {
    $_[0]->[HR_KFLD_ATTRHASH];
}

sub kstring {
    my $self = shift;
    $self->[HR_KFLD_STRSCALAR];
}

sub dump {
    my ($self,$hrd) = @_;
    my $h = $self->[HR_KFLD_ATTRHASH];
    foreach my $v (values %$h) {
        $hrd->iprint("V: %s", $hrd->fmt_ptr($v));
    }
}

use Ref::Store::ThreadUtil;
sub ithread_predup { }
sub ithread_postdup {
    my ($self,$newtable,$ptr_map,$old_taddr) = @_;
    my $attrhash = $self->[HR_KFLD_ATTRHASH];
    my @old_keys = keys %$attrhash;
    foreach my $vaddr (@old_keys) {
        my $new_v = $ptr_map->{$vaddr};
        $newtable->dref_del_ptr($new_v, $attrhash, $vaddr);
        $newtable->dref_add_str($new_v, $attrhash, $new_v + 0);
        my $was_weak = isweak($attrhash->{$vaddr});
        $attrhash->{$new_v+0} = $new_v;
        if($was_weak) { 
            weaken($attrhash->{$new_v+0});
        }
        delete $attrhash->{$vaddr};
    }
}

sub DESTROY {
    my $self = shift;
    my $attrhash = $self->[HR_KFLD_ATTRHASH];
    my $table = $self->[HR_KFLD_TABLEREF];
    return unless $table;
    #log_err("Will iterate over contained values..");
    foreach my $v (values %$attrhash) {
        next unless defined $v;
        $table->dref_del_ptr($v, $attrhash, $v+0);
        
        my $vhash = $table->reverse->{$v+0};
        my $vaddr = $v+0;
        next unless defined $vhash;
        delete $vhash->{$self+0};
        
        if(! %$vhash) {
            delete $table->reverse->{$vaddr};
            if(defined $v) {
                $table->dref_del_ptr($v, $table->reverse, $vaddr);
            }
        }
    }
    
    delete $table->attr_lookup->{ $self->[HR_KFLD_STRSCALAR] };
}

package Ref::Store::Attribute::Encapsulating;
use strict;
use warnings;
use base qw(Ref::Store::Attribute);
use Scalar::Util qw(weaken);
use Ref::Store::Common;
use Log::Fu;
use Ref::Store::ThreadUtil;
use Data::Dumper;
use Devel::GlobalDestruction;


sub new {
    my ($cls,$astr,$encapsulated,$table) = @_;
    my $self = $cls->SUPER::new($astr, $encapsulated, $table);
    $table->dref_add($encapsulated, \&_encap_destroy_hook, $self);
    return $self;
}


sub weaken_encapsulated {
    my $self = shift;
    weaken($self->[HR_KFLD_REFSCALAR]);
}

sub dump {
    my ($self,$hrd) = @_;
    $hrd->iprint("ENCAP: %s", $self->[HR_KFLD_REFSCALAR]);
    $self->SUPER::dump($hrd);
}

sub ithread_predup {
    my ($self,$table,$ptr_map) = @_;
    hr_thrutil_store_kinfo(HR_THR_AENCAP_PREFIX, $self->[HR_KFLD_STRSCALAR],
        $ptr_map, [ $self->[HR_KFLD_REFSCALAR]+0, $self + 0 ] );
}

sub ithread_postdup {
    my ($self,$table,$ptr_map,$old_taddr) = @_;
    my $old = hr_thrutil_get_kinfo(HR_THR_AENCAP_PREFIX, 
        $self->[HR_KFLD_STRSCALAR], $ptr_map);
    my ($old_encap_addr,$old_self_addr) = @$old;

    my $new_encap_addr = $self->[HR_KFLD_REFSCALAR]+0;

    $self->[HR_KFLD_STRSCALAR] =~ s/\Q$old_encap_addr\E/$new_encap_addr/gi;

    $table->dref_del_ptr($self->[HR_KFLD_REFSCALAR],
        $table->attr_lookup, $self->[HR_KFLD_STRSCALAR]);

    my $attrhash = $self->[HR_KFLD_ATTRHASH];
    foreach my $v (values %$attrhash) {
        my $vhash = $table->reverse->{$v+0};
        $table->dref_del_ptr($self->[HR_KFLD_REFSCALAR],
            $vhash, $old_self_addr);
        $table->dref_add_str($self->[HR_KFLD_REFSCALAR],
            $vhash, $self + 0);
    }
    $self->SUPER::ithread_postdup($table,$ptr_map,$old_taddr);
}

use Carp qw(cluck);
sub _encap_destroy_hook {
    my ($encapped, $attr) = @_;
    return if in_global_destruction;
    $attr->DESTROY();
}

sub DESTROY {
    my $self = shift;
    return if in_global_destruction;
    $self->SUPER::DESTROY();
    my $table = $self->[HR_KFLD_TABLEREF];
    
    if($self->[HR_KFLD_REFSCALAR]) {
        $table->dref_del_ptr(
            $self->[HR_KFLD_REFSCALAR],
            \&_encap_destroy_hook,
            $self
        );
        $self->[HR_KFLD_REFSCALAR] = undef;
    }
}
1;