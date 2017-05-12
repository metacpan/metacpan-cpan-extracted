package Setup::Project::ShareDir;
use strict;
use warnings;

use Setup::Project;
use Class::Accessor::Lite (
    rw  => [qw/maker/]
);

sub new {
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    my $maker = Setup::Project->new(
        tmpl_dir  => $self->tmpl_dir,
        write_dir => $args{distdir},
    );
    $self->maker($maker);

    $self;
}

sub argv     { die 'please override method: option' }
sub parse    { die 'please override method: parse' }
sub run      { die 'please override method: run' }
sub tmpl_dir { die 'please override method: tmpl_dir' }
sub version  { '' }

1;
