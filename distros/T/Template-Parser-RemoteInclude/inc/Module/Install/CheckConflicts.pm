#line 1
use strict;
use warnings;

package Module::Install::CheckConflicts;

use base 'Module::Install::Base';

BEGIN {
    our $VERSION = '0.02';
    our $ISCORE  = 1;
}

sub check_conflicts {
    my $self = shift;
    # Deal with the fact that prompt_script calls us with just the script
    # name by totally ignoring it. HACK!
    my %conflicts = @_ unless scalar(@_) == 1;
    my %conflicts_found;
    for my $mod (sort keys %conflicts) {
        next unless $self->can_use($mod);

        my $installed = $mod->VERSION;
        next unless $installed le $conflicts{$mod};

        $conflicts_found{$mod} = $installed;
    }

    return unless scalar keys %conflicts_found;

    my $dist = $self->name;

    print <<"EOM";

***
  WARNING:

    This version of ${dist} conflicts with
    the version of some modules you have installed.

    You will need to upgrade these modules after
    installing this version of ${dist}.

    List of the conflicting modules and their installed
    versions:

EOM

    for my $mod (sort keys %conflicts_found) {
        print sprintf("    %s :   %s (<= %s)\n",
            $mod, $conflicts_found{$mod}, $conflicts{$mod},
        );
    }

    print "\n***\n";

    return if $ENV{PERL_MM_USE_DEFAULT};
    return unless -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT));

    sleep 4;
}

1;

__END__

#line 124
