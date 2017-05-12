package Ref::Store::Sweeping::Key;
use strict;
use warnings;
use Ref::Store::Common;
use Ref::Store::Key;
use Scalar::Util qw(weaken);
use base qw(Ref::Store::Key);
use Log::Fu;

use constant {
    HR_KFLD_VADDR => HR_KFLD_AVAILABLE()
};

sub new {
    my ($cls,$ukey,$table) = @_;
    my $self = [];
    @{$self}[HR_KFLD_REFSCALAR, HR_KFLD_STRSCALAR, HR_KFLD_TABLEREF] =
        ($ukey, ref $ukey ? $ukey+0 : $ukey, $table);
    
    weaken($table->scalar_lookup->{$self->[HR_KFLD_STRSCALAR]} = $self);
    bless $self, $cls;
}

sub weaken_encapsulated {
    if(ref $_[0]->[HR_KFLD_REFSCALAR]) {
        weaken($_[0]->[HR_KFLD_REFSCALAR]);
    }
}

sub link_value {
    #my ($self,$value) = @_;
    #log_err("LINK: $value");
    $_[0]->[HR_KFLD_VADDR] = $_[1] + 0;
}

sub vaddr {
    $_[0]->[HR_KFLD_VADDR];
}

sub encapsulated {
    $_[0]->[HR_KFLD_REFSCALAR];
}

sub is_valid {
    return exists $_[0]->[HR_KFLD_TABLEREF]->forward->{
        $_[0]->[HR_KFLD_STRSCALAR]
    };
}

#sub DESTROY {
#    my $self = shift;
#    $self->[HR_KFLD_TABLEREF]->del_key($self);
#}

package Ref::Store::Sweeping::Attribute;
use strict;
use warnings;
use Ref::Store::Common;
use Scalar::Util qw(weaken);
use base qw(Ref::Store::Sweeping::Key);

use constant {
    HR_KFLD_LOOKUP => HR_KFLD_AVAILABLE()+1
};

sub new {
    my ($cls,$scalar,$ref,$table) = @_;
    my $self = [];
    @{$self}[HR_KFLD_REFSCALAR, HR_KFLD_STRSCALAR, HR_KFLD_LOOKUP,
             HR_KFLD_TABLEREF] =
        ($ref, $scalar, {}, $table);
    bless $self, $cls;
}

sub store_strong {
    my ($self,$k,$v) = @_;
    $self->[HR_KFLD_LOOKUP]->{$k} = $v;
}

sub store_weak {
    my ($self,$k,$v) = @_;
    eval {
        $self->[HR_KFLD_LOOKUP]->{$k} = $v;
        weaken($self->[HR_KFLD_LOOKUP]->{$k});
    }; if ($@) {
        use Data::Dumper;
        print Dumper($self);
        die $@;
    }
}

sub get_hash {
    my $self = shift;
    $self->[HR_KFLD_LOOKUP];
}

sub unlink_value {
    my ($self,$value) = @_;
    my $h = $self->[HR_KFLD_LOOKUP];
    delete $h->{$value+0};
    if(!scalar %$h && ref $self->[HR_KFLD_REFSCALAR]) {
        $self->[HR_KFLD_REFSCALAR] = undef;
    }
}

sub is_valid {
    return exists $_[0]->[HR_KFLD_TABLEREF]->attr_lookup->{
        $_[0]->[HR_KFLD_STRSCALAR]
    };
}

#sub DESTROY {
#    delete
#        $_[0]->[HR_KFLD_TABLEREF]->attr_lookup->{
#            $_[0]->[HR_KFLD_STRSCALAR]
#        };
#}


package Ref::Store::Sweeping;
use strict;
use warnings;
use Ref::Store;
use base qw(Ref::Store);
use Ref::Store::Common;
use Log::Fu;
use Carp qw(cluck);
#An implementation of Ref::Store which does not
#use magic, but rather sweeps

our $AccessCount = 0;
our $SweepInterval = 10000;
use constant HR_KFLD_VADDR => Ref::Store::Sweeping::Key::HR_KFLD_VADDR;

sub del_key {
    my ($self,$key) = @_;
    #cluck("..");
    #log_err("DEL_KEY=$key");
    my $kstr = $key->[HR_KFLD_STRSCALAR];
    my $vaddr = $key->[HR_KFLD_VADDR];
    
    delete $self->forward->{$kstr};
    delete $self->scalar_lookup->{$kstr};
    if($vaddr) {
        if($self->reverse->{$vaddr}) {
            delete $self->reverse->{$vaddr}->{$kstr};
        } else {
            delete $self->reverse->{$vaddr};
        }
    }
}

sub del_attr {
    my ($self,$attr) = @_;
    my $ahash = $attr->get_hash;
    while (my ($vaddr,$vobj) = each %$ahash) {
        my $vhash = $self->reverse->{$vaddr};
        if($vhash) {
            delete $vhash->{$attr + 0};
            if(! scalar %$vhash) {
                delete $self->reverse->{$vaddr};
            }
        }
    }
    
    delete $self->attr_lookup->{$attr->kstring};
}

sub new_key {
    my ($self,$ukey) = @_;
    Ref::Store::Sweeping::Key->new($ukey, $self);
}

sub new_attr {
    my ($self,$astr,$attr) = @_;
    Ref::Store::Sweeping::Attribute->new($astr,$attr,$self);
}

#NOPify all backdelete operations
{
    no strict 'refs';
    foreach my $nop (qw(dref_add dref_del
             dref_add_ptr dref_del_ptr
             dref_add_str dref_del_str))
    {
        *{$nop} = sub { };
    }
}

#Wrap all API calls for possible garbage collection
{
    no strict 'refs';
    no warnings 'once';
    my @wrapped;
    foreach my $api_func (qw(store fetch dissoc purgeby unlink)) {
        push @wrapped, map { $api_func . "_$_" } qw(sk kt a);
    }
    push @wrapped, qw(has_value has_key is_empty);
    
    foreach my $fn_name (@wrapped) {
        #log_warn($fn_name);
        my $real_sub = \&{"Ref::Store" . "::$fn_name"};
        #log_info($real_sub);
        next unless $real_sub;
        *{$fn_name} = sub {
        my $self = $_[0];
        
            if(++$AccessCount >= $SweepInterval) {
                $self->sweep();
                $AccessCount = 0;
            }
            return $real_sub->(@_);
        };
        #log_warn("Assigned $fn_name");
    }
}

sub sweep {
    my $self = shift;
    #log_err("Invoking GC");
    #Check key objects to determine if their encapsulated object has been
    #destroyed
    while (my ($ustr,$kobj) = each %{$self->scalar_lookup}) {
        if(!$kobj) {
            delete $self->scalar_lookup->{$ustr};
            next;
        }
        
        #The value
        my $kstr = $kobj->[HR_KFLD_STRSCALAR];
        my $vaddr = $kobj->[HR_KFLD_VADDR];
        
        if(
            #Value has been destroyed
            (!defined $self->scalar_lookup->{$kstr})
            
            #value has been deleted
           ||(!exists $self->reverse->{$vaddr})
           ||(!defined $self->forward->{$kstr})
           
           #key has been unlinked from value
           || (!exists $self->reverse->{$vaddr}->{$kstr})
                      
           #dependent lookup object has been destroyed
           || (!defined $kobj->[HR_KFLD_REFSCALAR]))
        {
            
            $self->del_key($kobj);
            next;
        }
    }
    
    #Attributes
    while (my ($astr,$aobj) = each %{$self->attr_lookup}) {
        if(!defined $aobj) {
            delete $self->attr_lookup->{$astr};
            next;
        }
        my $ahash = $aobj->get_hash;
        
        
        while (my ($vaddr,$vobj) = each %$ahash) {
            if(!defined $vobj
               || (!exists $self->reverse->{$vaddr})
               || (!defined $self->reverse->{$vaddr}->{$aobj+0})
               )
            {
                delete $ahash->{$vaddr};
            }
        }
        
        if(!scalar %$ahash || !defined $aobj->[HR_KFLD_REFSCALAR]) {
            $self->del_attr($aobj);
        }
    }
    
    #Values
    while (my ($vaddr,$vhash) = each %{$self->reverse}) {
        while (my ($kstring,$lobj) = each %$vhash) {
            #if(defined $lobj) {
            #    log_infof("$lobj: VALID=%d", $lobj->is_valid);
            #}
            if((!defined $lobj) || (!$lobj->is_valid)) {
                #lookup has been deleted
                delete $vhash->{$kstring};
            }
        }
        
        if(! scalar %$vhash) {
            #no more lookups for this object
            delete $self->reverse->{$vaddr};
        }
    }
    #log_err("GC Done!");
}

1;

__END__

=head1 NAME

Ref::Store::Sweeping

A sweeping implementation of the H::R api.

=head2 DESCRIPTION

This implements an extra method called C<sweep>, and is called regularly at
API access intervals. This currently does not work with chained deletion, and
therefore you cannot use the same object as both key and value (as you are able to
with the other backends)