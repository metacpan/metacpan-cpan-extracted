use strict;
package ObjStore::REP::HashRecord;
use base 'Exporter';
use ObjStore::MakeMaker qw(add_os_args);
use vars qw($VERSION @EXPORT_OK $Fspec %align);
$VERSION = '0.96';
@EXPORT_OK = qw($VERSION &hrec_args &c_types $Fspec %align);

$Fspec = "osp_hashrec_field_spec";

sub hrec_args {
    require Config;
    my $sitearch = $Config::Config{sitearch};
    $sitearch =~ s,$Config::Config{prefix},$ENV{PERL5PREFIX}, if
	exists $ENV{PERL5PREFIX};
    my %arg = @_;
    $arg{INC} .= " -I$sitearch/auto/ObjStore/REP/HashRecord";
    $arg{LIBS} ||= [''];
    for (@{$arg{LIBS}}) {
	$_ .= " -L$sitearch/auto/ObjStore/REP/HashRecord -lHashRecord"
    }
    %arg;
}

my $max_osp_str = 35;
sub c_types() {
    # It is important not to change the order of these types!
    my @T = ('OSSV','OSPVptr','char','float','double');
    for (16,32) { push @T, "os_int$_"; }
    for (my $w=3; $w <= $max_osp_str; $w+=4) { push @T, "osp_str$w"; }
    push @T, 'os_reference', 'os_reference_this_DB';
    @T
}

# These cannot change either!
%align = (OSSV => 8, OSPVptr => 4, char => 1, float => 4, double => 8,
	   os_int16 => 2, os_int32 => 4, os_reference => 4,
	   os_reference_this_DB => 4);
for (my $w=3; $w <= $max_osp_str; $w+=4) { $align{"osp_str$w"} = 4 }

1;
