# ============================================================================
package MooseX::App::Plugin::Typo::Meta::Class;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

use Text::WagnerFischer qw(distance);

around 'command_candidates' => sub {
    my ($orig,$self,$command) = @_;

    my $lc_command = lc($command);
    my $commands = $self->app_commands;

    # Fuzzy match
    my @candidates;
    my $candidate_length = length($command);

    # Compare all commands to find matching candidates
    foreach my $command_name (keys %$commands) {
        my $candidate_substr = substr($command_name,0,$candidate_length+1);
        if ($lc_command eq $command_name) {
            return $command_name;
        } elsif ($lc_command eq $candidate_substr
            || distance($lc_command,$candidate_substr) <= 1) {
            push(@candidates,$command_name);
        }
    }
    return [ sort @candidates ];
};

1;