package builder::MyBuilder;
use strict;
use warnings;
use utf8;

use parent qw(Module::Build);
use File::Copy;
use Config;

sub new {
    my ( $self, %args ) = @_;
    $self->SUPER::new(
        %args,
    );
}

sub ACTION_code {
    my ($self) = @_;
    $self->regenerate_cpanfile();
    $self->SUPER::ACTION_code();
}

sub regenerate_cpanfile {
    my $self = shift;

    return unless -d '.git';

    print "Generating cpanfile\n";
    open my $fh, '<', 'lib/Task/BeLike/SONGMU.pm' or die $!;
    open my $cpanfile, '>', 'cpanfile' or die $!;

    while (<$fh>) {
        if (/=head[2-6] L<([-_a-zA-Z0-9:]+)>\s*(v?[\.0-9]*)$/) {
            print $cpanfile qq{requires "$1"};
            print $cpanfile qq{, "$2"} if $2;
            print $cpanfile qq{;\n};
        }
        elsif (/=head[2-6] (.*)/) {
            next if $1 =~ /plenv/;
            print $cpanfile qq{\n# $1\n};
        }
    }

    print $cpanfile qq!\n!;
    print $cpanfile qq!on test => sub {\n!;
    print $cpanfile qq!    requires "Test::More", 0.98;\n!;
    print $cpanfile qq!};\n!;
}

1;
