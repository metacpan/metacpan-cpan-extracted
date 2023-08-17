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
    model  => undef,
    dbname => undef,
);
GetOptions( \%opts,
    'model=s',
    'dbname=s',
) or pod2usage(2);

pod2usage(1) if $opts{help};
pod2usage(-exitval => 0, -verbose => 2) if $opts{man};

if (my @missing = grep !defined($opts{$_}), qw(model)) {
    die 'Missing: ' . join(', ', @missing);
}

my $name = prompt('What is the name of this setting?', 'required');
die 'No name given' if $name eq 'required';

my $synth = Synth::Config->new(model => $opts{model});

# get a specs config file for the synth model
my $set = './eg/' . $synth->model . '.set';
my $specs = -e $set ? do $set : undef;

# get the setting keys to loop over
my @keys = qw(group parameter control bottom top value unit is_default);
if ($specs) {
    my $order = delete $specs->{order};
    @keys = $order ? @$order : sort keys %$specs;
}

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
    # loop over the setting keys
    INNER: for my $key (@keys) {
        my $prompt = { prompt => "$counter. $key:" };
        # if there is a known synth...
        if ($specs) {
            # use either a group parameter or the key list
            my $things = $key eq 'parameter' ? $specs->{$key}{$group} : $specs->{$key};
            # set the group
            if ($key eq 'group') {
                $group = $tc->choose($things, $prompt);
                print "\t$key set to: $group\n";
                $parameters{$key} = $group;
            }
            # set the control
            elsif ($key eq 'control') {
                $control = $tc->choose($things, $prompt);
                print "\t$key set to: $control\n";
                $parameters{$key} = $control;
            }
            # set a group_to patch
            elsif ($key eq 'group_to' && $control eq 'patch') {
                $group_to = $tc->choose($specs->{group}, $prompt);
                print "\t$key set to: $group_to\n";
                $parameters{$key} = $group_to;
            }
            # skip these keys unless control is patch
            elsif (($key eq 'group_to' || $key eq 'param_to') && $control ne 'patch') {
                next INNER;
            }
            # skip these keys if a group_to is set
            elsif (($key eq 'bottom' || $key eq 'top' || $key eq 'value' || $key eq 'unit') && $group_to) {
                next INNER;
            }
            # set a param_to patch with the group_to parameter list
            elsif ($key eq 'param_to' && $control eq 'patch') {
                $choice = $tc->choose($specs->{parameter}{$group_to}, $prompt);
                print "\t$key set to: $choice\n";
                $parameters{$key} = $choice;
            }
            # prompt for a value
            elsif ($key eq 'value') {
                $choice = prompt("$counter. Value for $key? (enter to skip)", 'enter');
                unless ($choice eq 'enter') {
                    print "\t$key set to: $choice\n";
                    $parameters{$key} = $choice;
                }
            }
            # prompt for a unit
            elsif ($key eq 'unit') {
                $choice = $tc->choose($things, $prompt);
                if ($choice ne 'none') {
                    print "\t$key set to: $choice\n";
                    $parameters{$key} = $choice;
                }
            }
            # handle all other keys
            else {
                $choice = $tc->choose($things, $prompt);
                print "\t$key set to: $choice\n";
                $parameters{$key} = $choice;
            }
        }
        # otherwise just ask for values
        else {
            $choice = prompt("$counter. Value for $key? (enter to skip, q to quit)", 'enter');
            if ($choice eq 'q') {
                last OUTER;
            }
            elsif ($choice eq 'enter') {
                next INNER;
            }
            else {
                $parameters{$key} = $choice;
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

  synth-config.pl --model=Something [--dbname=synth.db]

=head1 OPTIONS

=over 4

=item B<model>

The required synthesizer model name.

=item B<dbname>

The name of the SQLite database in which to save settings.

=back

=head1 DESCRIPTION

B<synth-config.pl> loops through the settings for a synthesizer,
prompting for values.

=cut
