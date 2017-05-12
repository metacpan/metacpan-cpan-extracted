use Data::Dumper;

use TM::Materialized::AsTMa;
my $tm = new TM::Materialized::AsTMa (inline => '
sacklpicka (cat)
bn: Der Sacklpicka
bn (nickname): Sleeping Devil
sin: http://kill.devc.at/system/files/aad.small.jpg

rho (person)
oc (blog): http://kill.devc.at/

(owns)
owner: rho
owned: sacklpicka
')->sync_in;

use TM::DM;
my $tmdm = new TM::DM (map => $tm);

my $topicmap = $tmdm->topicmap;

my @ts = $topicmap->topics (\ '+all -infrastructure');

warn join "," , (map { $_->id } @ts);

#my $sp = $topicmap->topic ('sacklpicka');
#my $sp = $topicmap->topic ('tm://nirvana/sacklpicka');
my $sp = $topicmap->topic (\ 'http://kill.devc.at/system/files/aad.small.jpg');
warn $sp->id;
foreach my $n ($sp->names) {
   next if $n->type->id eq 'tm://nirvana/nickname';
   warn $n->value;
}

my $rho = $topicmap->topic ('rho');
foreach my $o ($rho->occurrences) {
   warn $o->value->[0];
}

foreach my $r ( $rho->roles ) {
   warn "player: ".$r->player->id;
   warn " for role: ".$r->type->id;
}

my @as = $topicmap->associations (iplayer => 'rho');

foreach my $a (@as) {
   warn $a->type->id;
   warn $a->scope->id;
   warn map { $_->type->id } $a->roles;
}


__END__


