package Ref::Store::XS::Key;
use strict;
use warnings;
use Ref::Store::Common;
use Ref::Store::XS::cfunc;

*new                    = \&HRXSK_new;
*kstring                = \&HRXSK_kstring;
*prefix_len             = \&HRXSK_prefix_len;

sub weaken_encapsulated { }
sub unlink_value { }
sub link_value { }
sub ithread_predup {}
sub ukey {}

*ithread_postdup        = \&HRXSK_ithread_postdup;

package Ref::Store::XS::Key::Encapsulating;
use strict;
use warnings;
use Ref::Store::XS::cfunc;

sub unlink_value { }

*new                    = \&HRXSK_encap_new;
*weaken_encapsulated    = \&HRXSK_encap_weaken;

#NOOP:
#*link_value             = \&HRXSK_encap_link_value;

*kstring                = \&HRXSK_encap_kstring;
*prefix_len             = \&HRXSK_prefix_len;

*ithread_predup         = \&HRXSK_encap_ithread_predup;
*ithread_postdup        = \&HRXSK_encap_ithread_postdup;

*ukey                   = \&HRXSK_encap_getencap;

sub dump {
    my ($self,$hrd) = @_;
    $hrd->iprint("ENCAP: %s", $hrd->fmt_ptr($self->HRXSK_encap_getencap));
}



package Ref::Store::XS::Attribute;
use strict;
use warnings;
use Ref::Store::XS::cfunc;

*unlink_value   = \&HRXSATTR_unlink_value;
*get_hash       = \&HRXSATTR_get_hash;
*kstring        = \&HRXSATTR_kstring;
*prefix_len     = \&HRXSATTR_prefix_len;
*ithread_predup = \&HRXSATTR_ithread_predup;
*ithread_postdup= \&HRXSATTR_ithread_postdup;

sub ukey { }

package Ref::Store::XS::Attribute::Encapsulating;
use Ref::Store::XS::cfunc;
our @ISA = qw(Ref::Store::XS::Attribute);
*ukey           = \&HRXSATTR_encap_ukey;

package Ref::Store::XS;
use strict;
use warnings;
use base qw(Ref::Store);
use Ref::Store::XS::cfunc;
use Log::Fu;

#These two lines completely override the perl store/fetch code and utilize
#pure C! - double the speed

*table_init         = \&HRA_table_init;

*store = *store_sk  = \&HRA_store_sk;
*fetch = *fetch_sk  = \&HRA_fetch_sk;
*store_kt           = \&HRA_store_kt;

*store_a            = \&HRA_store_a;
*fetch_a            = \&HRA_fetch_a;
*dissoc_a           = \&HRA_dissoc_a;
*unlink_a           = \&HRA_unlink_a;
*attr_get           = \&HRA_attr_get;
*ithread_store_lookup_info = \&HRA_ithread_store_lookup_info;


sub new_key {
    my ($self,$scalar) = @_;
    if(!ref $scalar) {
        return HRXSK_new('Ref::Store::XS::Key',
                     $scalar, $self->forward, $self->scalar_lookup);
    } else {
        return HRXSK_encap_new('Ref::Store::XS::Key::Encapsulating',
                               $scalar, $self, $self->forward,
                               $self->scalar_lookup);
    }
}

sub dref_add_ptr {
    my ($self,$value,$hashref) = @_;
    HR_PL_add_action_ptr($value, $hashref);
}

sub dref_add_str {
    my ($self,$value,$hashref,$str) = @_;
    HR_PL_add_action_str($value,$hashref,$str);
}

sub dref_del_ptr {
    my ($self,$value,$hashref,$arg) = @_;
    if(@_ == 3) {
        HR_PL_del_action_container($value, $hashref);
    } elsif(@_ == 4) {
        HR_PL_del_action_ptr($value, $hashref, $arg);
    } else {
        die("Need either 2 or 3 arguments, got ", (scalar @_) - 1);
    }
}


1;

__END__

=head1 NAME

Ref::Store::XS - XS/C implementation of the H::R API

=head2 DESCRIPTION

No user serviceable parts inside.

This backend currently handles store, fetch, and back-delete operations entirely
in C, making it significantly fast.