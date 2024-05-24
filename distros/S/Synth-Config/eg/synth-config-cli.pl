#!/usr/bin/perl

# PODNAME: synth-config-cli.pl

use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
use IO::Prompt::Tiny qw(prompt);
use Term::Choose ();

use lib map { "$ENV{HOME}/sandbox/$_/lib" } qw(Synth-Config);
use Synth::Config ();

pod2usage(1) unless @ARGV;

my %opts = (
    model => undef, # e.g. 'Modular'
    patch => undef, # e.g. 'Simple 001'
    specs => undef, # e.g. modular.set
);
GetOptions( \%opts,
    'model=s',
    'patch=s',
    'specs=s',
) or pod2usage(2);

pod2usage(1) if $opts{help};
pod2usage(-exitval => 0, -verbose => 2) if $opts{man};

die "Usage: perl $0 --model='Modular'\n"
    unless $opts{model};

my $name = $opts{patch};
unless ($name) {
    $name = prompt('What is the name of the new setting?', 'required');
}
die 'No name given' if $name eq 'required';

my $synth = Synth::Config->new(model => $opts{model});

my ($spec_id, $specs);
if ($opts{specs}) {
    die 'Specs file does not exist' unless -e $opts{specs};
    unless ($specs = do $opts{specs}) {
        die "Couldn't parse $opts{specs}: $@" if $@;
        die "Couldn't do $opts{specs}: $!"    unless defined $specs;
    }
    $spec_id = $synth->make_spec(%$specs);
    print "Added $opts{specs} ($spec_id) to the database\n"
        if $spec_id;
    $specs = $synth->recall_spec(id => $spec_id);
}
else {
   $specs = $synth->recall_specs; 
}
die "Specifications not found for the $opts{model} model\n"
    unless $specs;

# instantiate a chooser if needed
my $tc = $specs ? Term::Choose->new : undef;

# declare loop variables
my ($choice, $group, $group_to, $control);

# outer loop counter
my $counter = 0;

# add setting until the user quits
OUTER: while (1) {
    $counter++;
    # initialize the parameters to commit
    my %parameters = (name => $name);
    # loop over the settings
    INNER: for my $spec (@$specs) {
        my $prompt = { prompt => "$counter. $spec:" };
        # if there is a known synth...
        if ($specs) {
            # use either a group parameter or the spec list
            my $things = $spec eq 'parameter' ? $specs->{$spec}{$group} : $specs->{$spec};
            # set the group
            if ($spec eq 'group') {
                $group = $tc->choose($things, $prompt);
                print "\t$spec set to: $group\n";
                $parameters{$spec} = $group;
            }
            # set the control
            elsif ($spec eq 'control') {
                $control = $tc->choose($things, $prompt);
                print "\t$spec set to: $control\n";
                $parameters{$spec} = $control;
            }
            # set a group_to patch
            elsif ($spec eq 'group_to' && $control eq 'patch') {
                $group_to = $tc->choose($specs->{group}, $prompt);
                print "\t$spec set to: $group_to\n";
                $parameters{$spec} = $group_to;
            }
            # skip these specss unless control is patch
            elsif (($spec eq 'group_to' || $spec eq 'param_to') && $control ne 'patch') {
                next INNER;
            }
            # skip these specss if a group_to is set
            elsif (($spec eq 'bottom' || $spec eq 'top' || $spec eq 'value' || $spec eq 'unit') && $group_to) {
                next INNER;
            }
            # set a param_to patch with the group_to parameter list
            elsif ($spec eq 'param_to' && $control eq 'patch') {
                $choice = $tc->choose($specs->{parameter}{$group_to}, $prompt);
                print "\t$spec set to: $choice\n";
                $parameters{$spec} = $choice;
            }
            # prompt for a value
            elsif ($spec eq 'value') {
                $choice = prompt("$counter. Value for $spec? (enter to skip)", 'enter');
                unless ($choice eq 'enter') {
                    print "\t$spec set to: $choice\n";
                    $parameters{$spec} = $choice;
                }
            }
            # prompt for a unit
            elsif ($spec eq 'unit') {
                $choice = $tc->choose($things, $prompt);
                if ($choice ne 'none') {
                    print "\t$spec set to: $choice\n";
                    $parameters{$spec} = $choice;
                }
            }
            # handle all other specss
            else {
                $choice = $tc->choose($things, $prompt);
                print "\t$spec set to: $choice\n";
                $parameters{$spec} = $choice;
            }
        }
        # otherwise just ask for values
        else {
            $choice = prompt("$counter. Value for $spec? (enter to skip, q to quit)", 'enter');
            if ($choice eq 'q') {
                last OUTER;
            }
            elsif ($choice eq 'enter') {
                next INNER;
            }
            else {
                $parameters{$spec} = $choice;
            }
        }
    }
    # commit if there are more parameters than just name
    if (keys(%parameters) > 1) {
#        print ddc \%parameters;
        my $id = $synth->make_setting(%parameters);
    }
    # to proceed or not to proceed?
    $choice = prompt('Enter for another setting (q to quit)', 'enter');
    if ($choice eq 'q') {
        last OUTER;
    }
}

__END__

=head1 NAME

synth-config.pl - Save synth settings

=head1 SYNOPSIS

  $ perl synth-config.pl --model=Modular

=head1 OPTIONS

=over 4

=item B<model>

The required synthesizer model name.

=back

=head1 DESCRIPTION

B<synth-config.pl> loops through the settings for a synthesizer,
prompting for values.

=cut
