package Punk::Kit::Fakesqitch;

# t/1316's fixture: a kit that manages its own schema and writes the Sqitch
# plan itself, which `punk new --sqitch` must notice rather than run init over.

use strict;
use warnings;
use File::Spec ();
use parent 'Punk::Generate';

sub run {
    my ($self) = @_;
    $self->SUPER::run;
    my $plan = File::Spec->catfile($self->dir, 'sqitch.plan');
    open my $fh, '>', $plan or die "$plan: $!";
    print {$fh} "%syntax-version=1.0.0\n%project=fake\n\n";
    close $fh;
    return $self->written;
}

1;
