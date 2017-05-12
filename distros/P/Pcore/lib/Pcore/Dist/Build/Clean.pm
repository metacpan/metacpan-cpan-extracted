package Pcore::Dist::Build::Clean;

use Pcore -class, -const;

has dist => ( is => 'ro', isa => InstanceOf ['Pcore::Dist'], required => 1 );

const our $DIR => [

    # general build
    'blib/',

    # Module::Build
    '_build/',
];

const our $FILE => [

    # general build
    qw[META.json META.yml MYMETA.json MYMETA.yml],

    # Module::Build
    qw[_build_params Build.PL Build Build.bat],

    # MakeMaker
    qw[Makefile pm_to_blib],
];

sub run ($self) {
    for my $dir ( sort $DIR->@* ) {
        say 'rmtree ' . $dir;

        P->file->rmtree( $self->dist->root . $dir );
    }

    for my $file ( sort $FILE->@* ) {
        say 'unlink ' . $file;

        unlink $self->dist->root . $file or die qq[Can't unlink "$file"] if -f $self->dist->root . $file;
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Dist::Build::Clean - clean dist root dir

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
