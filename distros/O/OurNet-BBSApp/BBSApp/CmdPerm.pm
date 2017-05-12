package OurNet::BBSApp::CmdPerm;

# XXX: this module should split for each kind of isa/board/.
use strict;
use constant P_SYSBOT   => 0x01;
use constant P_ARENA    => 0x02;
use constant P_INVOLVED => 0x04;

my %cmdtable = (
    'cr_time'  => P_SYSBOT,
    'wg_time'  => P_ARENA|P_SYSBOT,
    'pp_time'  => P_ARENA|P_SYSBOT,
    'vt_time'  => P_ARENA|P_SYSBOT,
    'depend'   => P_INVOLVED,
    'wg_min'   => P_ARENA|P_SYSBOT,
    'involved' => P_INVOLVED|P_SYSBOT,
    'descr'    => P_ARENA|P_SYSBOT,
    'owner'    => P_SYSBOT,
    'issue'    => P_ARENA,
    'consensus'=> P_ARENA,
    'status'   => P_SYSBOT,
    'draft'    => P_INVOLVED|P_SYSBOT,
    'vote'     => P_INVOLVED|P_SYSBOT,
);

my %cmdmap = (
    '討論時限' => 'wg_time', 'GatherTime' => 'wg_time',  '論時' => 'wg_time',
    '草案時限' => 'pp_time', 'DraftTime'  => 'pp_time',  '案時' => 'pp_time',
    '投票時限' => 'vt_time', 'VoteTime'   => 'wg_time',  '票時' => 'vt_time',
    '成員下限' => 'wg_min',  'Threshold'  => 'wg_min',   '下限' => 'wg_min',
    '新增成員' => 'involved','AddMember'  => 'involved', '新增' => 'involved',
    '主旨說明' => 'descr',   'Description'=> 'descr',    '主旨' => 'descr',
    '原提議人' => 'owner',   'Originator' => 'owner',    '提議' => 'owner',
    '目前進度' => 'status',  'Status'     => 'status',   '進度' => 'status',
    '增修草案' => 'draft',   'Draft'      => 'draft',    '草案' => 'draft',
    '進行投票' => 'vote',    'Vote'       => 'vote',     '投票' => 'vote',
);

sub check {
    my ($who, $prop, $art, $cmd, $param) = @_;

    $_[3] = $cmd if (not exists $cmdtable{$cmd} and $cmd = $cmdmap{$cmd});
    return unless exists $cmdtable{$cmd} && (my $perm = $cmdtable{$cmd});
    return 1 if $perm & P_SYSBOT &&
	$art->{author} && $art->{author} eq 'sysbot';
    return 1 if $perm & P_ARENA && $who->isa('OurNet::BBSApp::Arena');
    return 1 if $perm & P_INVOLVED && $prop && $prop->involved &&
	(grep {$_.'.' eq $art->{author}} split(',',$prop->involved));
    return 0;
}

1;
