package Setup::Project::CLI;
use strict;
use warnings;
use parent 'Exporter';

our @EXPORT = qw/
    usage
/;

use Class::Accessor::Lite (
    rw  => [qw/version/]
);

use Getopt::Compact::WithCmd;
use Setup::Project;

sub new {
    my $class = shift;
    my $go = Getopt::Compact::WithCmd->new(
        global_struct => {
            'distdir' => {
                alias    => 'd',
                type     => 'Str',
                desc     => 'dist dir',
                opts => {
                    required => 1,
                },
            },
        },
    );

    bless {
        go   => $go,
        argv => \@ARGV,
    }, $class;
}

sub argv {
    my $self = shift;
    return $self->{argv};
}

sub maker {
    my ($self, %args) = @_;

    my $maker = Setup::Project->new(
        tmpl_dir  => $args{tmpl_dir},
        write_dir => $self->{go}->opts->{distdir},
    );
}

sub usage {
    my $msg = shift;
    print("usage: $0 -d /tmp/distdir $msg \n");
    exit -1;
}

1;
