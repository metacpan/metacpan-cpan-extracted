package Pcore::Dist::CLI::Create;

use Pcore -class;
use Pcore::Dist;

with qw[Pcore::Core::CLI::Cmd];

# CLI
sub CLI ($self) {
    return {
        abstract => 'create new distribution',
        name     => 'new',
        opt      => {
            cpan => {
                desc    => 'create CPAN distribution',
                default => 0,
            },
            upstream => {
                desc    => 'create upstream repository',
                isa     => [qw[bitbucket github]],
                default => 'bitbucket',
            },
            upstream_namespace => {
                short => 'N',
                desc  => 'upstream repository namespace',
                isa   => 'Str',
            },
            private => {
                desc    => 'upstream repository is private',
                default => 0,
            },
            scm => {
                desc    => 'SCM type for upstream',
                isa     => [qw[hg git hggit]],
                default => 'hg',
            },
        },
        arg => [    #
            namespace => { type => 'Str', },
        ],
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    $opt->{namespace} = $arg->{namespace};

    $opt->{base_path} = $ENV->{START_DIR};

    if ( my $dist = Pcore::Dist->create( $opt->%* ) ) {
        return;
    }
    else {
        say $Pcore::Dist::Build::Create::ERROR;

        exit 3;
    }
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::CLI::Create - create new distribution

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
