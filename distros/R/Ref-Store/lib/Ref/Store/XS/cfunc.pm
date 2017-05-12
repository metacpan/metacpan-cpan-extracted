package Ref::Store::XS::cfunc;
use strict;
use warnings;
use XSLoader;
our $VERSION = '0.20';

XSLoader::load 'Ref::Store', $VERSION;

use base qw(Exporter);

our @EXPORT = qw(
    HR_PL_add_action_ptr
    HR_PL_add_action_str
    
    HR_PL_del_action_container
    HR_PL_del_action_str
    HR_PL_del_action_ptr
    HR_PL_add_action_ext
    
    HRXSK_new
    HRXSK_kstring
    HRXSK_ithread_postdup
    HRXSK_prefix_len
    
    HRXSK_encap_new
    HRXSK_encap_kstring
    HRXSK_encap_weaken
    HRXSK_encap_link_value
    HRXSK_encap_getencap
    HRXSK_encap_ithread_predup
    HRXSK_encap_ithread_postdup
    
    HRA_table_init
	HRA_store_sk
    HRA_store_kt
	HRA_fetch_sk
    
    HRA_store_a
    HRA_fetch_a
    HRA_dissoc_a
    HRA_unlink_a
    HRA_attr_get
    HRA_ithread_store_lookup_info
    
    HRXSATTR_unlink_value
    HRXSATTR_get_hash
    HRXSATTR_kstring
    HRXSATTR_encap_ukey
    HRXSATTR_prefix_len
    HRXSATTR_ithread_predup
    HRXSATTR_ithread_postdup
);
1;
