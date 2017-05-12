use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object'; use_ok $class; }

my @lines = <DATA>;
my @o     = Net::Whois::Object->new(@lines);
for our $object (@o) {
    isa_ok $object, $class;
}
isa_ok $o[0], $class . "::Information";
can_ok $o[0], qw( comment );
ok( !$o[0]->can('source'), "No AUTOLOAD interference with ${class}::Information tests" );

isa_ok $o[3], $class . "::AsBlock";
can_ok $o[3], qw( as_block org source ), qw( descr remarks notify mnt_lower mnt_by changed);
ok( !$o[3]->can('bogusmethod'), "No AUTOLOAD interference with ${class}::AsBlock tests" );

isa_ok $o[5], $class . "::AutNum";
can_ok $o[5], qw( aut_num as_name org source ), qw( descr member_of import mp_import export mp_export
    default remarks tech_c admin_c notify
    mnt_lower mnt_by mnt_routes changed);
ok( !$o[5]->can('bogusmethod'), "No AUTOLOAD interference with ${class}::AutNum tests" );

#
# 'attributes' method
#
is_deeply( [ $o[0]->attributes('mandatory') ], ['comment'] );

is_deeply( [ $o[0]->attributes('optional') ], [] );
$o[0]->attributes( 'optional', [ 'opt1', 'opt2', 'opt3' ] );
is_deeply( [ $o[0]->attributes('optional') ], [ 'opt1', 'opt2', 'opt3' ] );

is_deeply( [ $o[0]->attributes('all') ], [ 'comment', 'opt1', 'opt2', 'opt3' ] );
is_deeply( [ $o[0]->attributes() ],      [ 'comment', 'opt1', 'opt2', 'opt3' ] );

#
# 'dump' method
#
is( $o[2]->dump, "\% Information related to 'AS30720 - AS30895'\n" );
is( $o[2]->dump( { align => 8 } ), "% Information related to 'AS30720 - AS30895'\n" );

#
# 'clone' method
#
my $full_clone = $o[3]->clone;
isa_ok($full_clone, ref $o[3], "Clone object has the same type of source");
is_deeply($full_clone, $o[3], "Clone object deeply similar to source");
my $clone = $o[3]->clone({remove => ['source','remarks','org', 'mnt-by','mnt-lower']});
is_deeply($clone, { class => 'AsBlock', order => ['as_block', 'descr'], as_block => 'AS30720 - AS30895', descr => ['RIPE NCC ASN block'] }, "Clone object similar with removed attribute");

#
# default 'append' mode in attribute modification
#
$clone->mnt_lower({value =>['MNT1-ADD','MNT2-ADD']});
is_deeply($clone->mnt_lower,['MNT1-ADD','MNT2-ADD'],'Array properly added to empty multiple attribute');
$clone->mnt_lower({value =>['MNT3-ADD','MNT4-ADD']});
is_deeply($clone->mnt_lower,['MNT1-ADD','MNT2-ADD','MNT3-ADD','MNT4-ADD'],'Array properly added to multiple attribute');

#
# 'replace' mode in attribute modification
#
$clone->mnt_lower({mode => 'replace', value => { old => 'MNT3-ADD', new => 'MNT3-RPL'}});
is_deeply($clone->mnt_lower,['MNT1-ADD','MNT2-ADD','MNT3-RPL','MNT4-ADD'],'Array properly added to multiple attribute');
eval { $clone->mnt_lower({mode => 'unknown', value => { old => 'MNT3-ADD', new => 'MNT3-RPL'}}); };
like($@ ,qr/Unknown mode/, "Unknown mode detected in accessor");
eval { $clone->mnt_lower({mode => 'replace', value => { old => 'MNT3-ADD'}}); };
like($@ ,qr/new.*replace mode/, "new=>... expected in replace mode");
eval { $clone->mnt_lower({mode => 'replace', value => { new => 'MNT3-ADD'}}); };
like($@ ,qr/old.*replace mode/, "old=>... expected in replace mode");

#
# 'delete' mode in attribute modification
#
$clone->mnt_lower({mode => 'delete', value => { old => 'MNT3-RPL'}});
is_deeply($clone->mnt_lower,['MNT1-ADD','MNT2-ADD','MNT4-ADD'],'Array properly deleted in to multiple attribute');
eval { $clone->mnt_lower({mode => 'delete', value => { new => 'MNT3-ADD'}}); };
like($@ ,qr/old.*delete mode/, "old=>... expected in delete mode");
$clone->mnt_lower({mode => 'delete', value => { old => '.'}});
is_deeply($clone->mnt_lower,[],'Array properly emptyed through delete wildcard');
like($clone->dump,qr/as-block:\s+AS30720 - AS30895\ndescr:\s+RIPE NCC ASN block\n/,"Dump of deleted attributes ok");
my $delete_clone = $full_clone->clone({remove=>['remarks']});
like($full_clone->dump,qr/as-block:\s+AS30720 - AS30895\ndescr:\s+RIPE NCC ASN block\nremarks:\s+These AS Numbers are further assigned to network\nremarks:\s+operators in the RIPE NCC service region. AS\nremarks:\s+assignment policy is documented in:\nremarks:\s+<http:\/\/www.ripe.net\/ripe\/docs\/asn-assignment.html>\nremarks:\s+RIPE NCC members can request AS Numbers using the\nremarks:\s+form available in the LIR Portal or at:\nremarks:\s+<http:\/\/www.ripe.net\/ripe\/docs\/asnrequestform.html>\norg:\s+ORG-NCC1-RIPE\nmnt-by:\s+RIPE-DBM-MNT\nmnt-lower:\s+RIPE-NCC-HM-MNT\nsource:\s+RIPE # Filtered\n/,"org full clone stil ok");
$full_clone->mnt_lower({mode=>'delete', value => {old => 'RIPE-NCC-HM-MNT'}});
like($full_clone->dump,qr/as-block:\s+AS30720 - AS30895\ndescr:\s+RIPE NCC ASN block\nremarks:\s+These AS Numbers are further assigned to network\nremarks:\s+operators in the RIPE NCC service region. AS\nremarks:\s+assignment policy is documented in:\nremarks:\s+<http:\/\/www.ripe.net\/ripe\/docs\/asn-assignment.html>\nremarks:\s+RIPE NCC members can request AS Numbers using the\nremarks:\s+form available in the LIR Portal or at:\nremarks:\s+<http:\/\/www.ripe.net\/ripe\/docs\/asnrequestform.html>\norg:\s+ORG-NCC1-RIPE\nmnt-by:\s+RIPE-DBM-MNT\nsource:\s+RIPE # Filtered\n$/,"non last attribute deletion ok");
$full_clone->source({mode=>'delete', value => {old => 'RIPE'}});
like($full_clone->dump,qr/as-block:\s+AS30720 - AS30895\ndescr:\s+RIPE NCC ASN block\nremarks:\s+These AS Numbers are further assigned to network\nremarks:\s+operators in the RIPE NCC service region. AS\nremarks:\s+assignment policy is documented in:\nremarks:\s+<http:\/\/www.ripe.net\/ripe\/docs\/asn-assignment.html>\nremarks:\s+RIPE NCC members can request AS Numbers using the\nremarks:\s+form available in the LIR Portal or at:\nremarks:\s+<http:\/\/www.ripe.net\/ripe\/docs\/asnrequestform.html>\norg:\s+ORG-NCC1-RIPE\nmnt-by:\s+RIPE-DBM-MNT\n$/,"last attribute deletion ok");

my @objects;
eval { @objects = Net::Whois::Object->query('AS30781', {attribute => 'remarks'}) };
like($@ ,qr/deprecated/i, "Deprecation warning for Net::Whois::Object->query()");

__DATA__
% This is the RIPE Database query service.
% The objects are in RPSL format.
%
% The RIPE Database is subject to Terms and Conditions.
% See http://www.ripe.net/db/support/db-terms-conditions.pdf

% Note: this output has been filtered.
%       To receive output for a database update, use the "-B" flag.

% Information related to 'AS30720 - AS30895'

as-block:       AS30720 - AS30895
descr:          RIPE NCC ASN block
remarks:        These AS Numbers are further assigned to network
remarks:        operators in the RIPE NCC service region. AS
remarks:        assignment policy is documented in:
remarks:        <http://www.ripe.net/ripe/docs/asn-assignment.html>
remarks:        RIPE NCC members can request AS Numbers using the
remarks:        form available in the LIR Portal or at:
remarks:        <http://www.ripe.net/ripe/docs/asnrequestform.html>
org:            ORG-NCC1-RIPE
mnt-by:         RIPE-DBM-MNT
mnt-lower:      RIPE-NCC-HM-MNT
source:         RIPE # Filtered

% Information related to 'AS99999'

aut-num:         AS99999
as-name:         COMPANY-AS
descr:           Company Entity SAS
org:             ORG-CO30-RIPE
remarks:
remarks:         UPSTREAMS
remarks:         ----------------------------------------------------------------
import:          from AS2914 action pref=80; accept ANY
import:          from AS3356 action pref=80; accept ANY
export:          to AS2914 announce AS-COMPANY
export:          to AS3356 announce AS-COMPANY
remarks:
remarks:
remarks:         UPSTREAMS IPv6
remarks:         ----------------------------------------------------------------
mp-import:       afi ipv6.unicast from AS2914 action pref=80; accept ANY
mp-import:       afi ipv6.unicast from AS3356 action pref=80; accept ANY
mp-export:       afi ipv6.unicast to AS2914 announce AS-COMPANY-V6;
mp-export:       afi ipv6.unicast to AS3356 announce AS-COMPANY-V6;
remarks:         ----------------------------------------------------------------
remarks:         Operational issues: noc at as99999 dot net
remarks:         ----------------------------------------------------------------
remarks:         Spam & abuse issues: abuse at as99999 dot net
remarks:         ----------------------------------------------------------------
remarks:         Peering Request: peering at as99999 dot net
remarks:         ----------------------------------------------------------------
remarks:         Network informations: http://extranet.company-entity.com/
remarks:         ----------------------------------------------------------------
remarks:
admin-c:         CPNY-RIPE
tech-c:          CPNY-RIPE
mnt-by:          COMPANY-MNT
mnt-routes:      COMPANY-MNT
mnt-by:          RIPE-NCC-END-MNT
source:          RIPE # Filtered

