package NetHack::Item::Role::IncorporatesStats;
{
  $NetHack::Item::Role::IncorporatesStats::VERSION = '0.21';
}
use MooseX::Role::Parameterized;

parameter attribute => (
    isa      => 'Str',
    required => 1,
);

parameter stat => (
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->attribute },
);

parameter bool_stat => (
    isa     => 'Bool',
    default => 0,
);

parameter defined_stat => (
    isa     => 'Bool',
    default => 0,
);

parameter stat_predicate => (
    isa => 'CodeRef',
);

role {
    my $p = shift;
    my $attr = $p->attribute;
    my $stat = $p->stat;

    my $predicate = $p->defined_stat
                  ? sub { $_ }
                  : $p->stat_predicate;

    after incorporate_stats => sub {
        my $self  = shift;
        my $stats = shift;

        my $value = $stats->{$stat};

        if ($predicate) {
            local $_ = $value;
            $value = $predicate->($_);
            return if !defined($value);
        }

        $value = $value ? 1 : 0 if $p->bool_stat;
        $self->$attr($value);
    };

    after incorporate_stats_from => sub {
        my $self  = shift;
        my $other = shift;

        $self->incorporate_stat($other => $attr);
    };
};

no MooseX::Role::Parameterized;

1;
