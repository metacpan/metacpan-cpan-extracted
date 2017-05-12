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
    open my $fh, '<', 'lib/Task/BeLike/TOKUHIROM.pm'
        or return;
    open my $cpanfile, '>', 'cpanfile'
        or return;

    my %seen;
    while (<$fh>) {
        if (/=head2 (.*)/) {
            print $cpanfile qq!\n# $1\n!;
        } elsif (/L<([^|>]+)>/) {
            next if $seen{$1}++;
            next if $1 eq 'Task';
            print $cpanfile qq!requires "$1";\n!;
        }
    }

    print $cpanfile qq!\n!;
    print $cpanfile qq!on test => sub {\n!;
    print $cpanfile qq!    requires "Test::More", 0.98;\n!;
    print $cpanfile qq!};\n!;
}

1;

