package TM::Serializable::Summary;

use Class::Trait 'base';
use Class::Trait 'TM::Serializable';

use Data::Dumper;
use TM::Analysis;
use TM::PSI;

use TM::Index::Match;

sub serialize {
    my $self = shift;

    my $idx  = new TM::Index::Match ($self);

    my $info = TM::Analysis::statistics ($self, 'nr_toplets', 'nr_asserts');
    $info->{sub_topicmaps} = [ $self->instances ($self->tids (\ TM::PSI->TOPICMAP ))];
    $info->{untyped}       = TM::Analysis::orphanage ($self, 'untyped')->{untyped};

#    warn "info ".Dumper $info;

    my @infra = keys %{$TM::infrastructure->{mid2iid}};
    my %infra;
    @infra{ @infra } = (1) x @infra;

    $info->{non_infra_untyped} = {
                                   map { $_ => scalar $self->instancesT ($_) }
                                   grep (!$infra{$_}, @{ $info->{untyped} } )
                                   };
    delete $info->{untyped};                              # maybe show this later
    return Data::Dumper->Dump ([ $info ], ['summary' ]);
}

sub deserialize {
    die "cannot be done, entropy is not our friend here, this is just a placeholder";
}

1;
