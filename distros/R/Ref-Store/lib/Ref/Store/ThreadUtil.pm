package Ref::Store::ThreadUtil::OldLookups;
use strict;
use warnings;
use Ref::Store::Common;

my @Lookups;
BEGIN {
    @Lookups = qw(forward reverse attr_lookup scalar_lookup);
}
use Class::XSAccessor::Array
    accessors => { %Ref::Store::Common::LookupNames };

sub new {
    my ($cls,$old_table) = @_;
    my %options = ();
    my $self = [];
    foreach my $idx (
        HR_TIDX_RLOOKUP, HR_TIDX_FLOOKUP,
        HR_TIDX_ALOOKUP, HR_TIDX_SLOOKUP) {
        $self->[$idx] = { %{$old_table->[$idx]} };
    }
    bless $self, $cls;
}

package Ref::Store::ThreadUtil;
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT;
use constant HR_THR_AENCAP_PREFIX => '__PP_AENCAP:';
use constant HR_THR_KENCAP_PREFIX => '__PP_KENCAP:';
use constant HR_THR_LINFO_PREFIX => '__PP_OLD_LOOKUPS:';

push @EXPORT, qw(
    HR_THR_AENCAP_PREFIX
    HR_THR_KENCAP_PREFIX
    HR_THR_LINFO_PREFIX
    );

sub hr_thrutil_store_linfo {
    my ($old_table,$ptr_map) = @_;
    my $linfo = Ref::Store::ThreadUtil::OldLookups->new($old_table);
    $ptr_map->{ HR_THR_LINFO_PREFIX . ($old_table + 0) } = $linfo;
}

sub hr_thrutil_get_linfo {
    my ($old_taddr,$ptr_map) = @_;
    return $ptr_map->{ HR_THR_LINFO_PREFIX . $old_taddr };
}

push @EXPORT, qw(hr_thrutil_store_linfo hr_thrutil_get_linfo);

sub hr_thrutil_store_kinfo {
    my ($prefix,$k,$ptr_map,$info) = @_;
    $ptr_map->{$prefix . $k} = $info;
}

sub hr_thrutil_get_kinfo {
    my ($prefix,$k,$ptr_map) = @_;
    $ptr_map->{$prefix.$k};
}

push @EXPORT, qw(hr_thrutil_store_kinfo hr_thrutil_get_kinfo);

