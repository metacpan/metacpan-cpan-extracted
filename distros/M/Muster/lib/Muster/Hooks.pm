package Muster::Hooks;
$Muster::Hooks::VERSION = '0.92';
#ABSTRACT: Muster::Hooks - scanning and processing hooks
=head1 NAME

Muster::Hooks - scanning and processing hooks

=head1 VERSION

version 0.92

=head1 DESCRIPTION

Content Management System
scanning and processing hooks

=cut

use Mojo::Base -base;
use Carp;
use Muster::MetaDb;
use Muster::LeafFile;
use Muster::Hook;
use File::Spec;
use File::Find;
use YAML::Any;
use Const::Fast;
use Module::Pluggable search_path => ['Muster::Hook'], instantiate => 'new';

=head1 PACKAGE CONSTANTS

=over

=item $PHASE_SCAN

Hooks are currently in scanning phase where pages are scanned for meta-data.

=item $PHASE_BUILD

Hooks are currently in build/assemble phase, where the pages are read and built.

=item $PHASE_FILTER

Hooks are currently in filter phase, where the page has already been converted to HTML, and needs post-processing.

=back

=cut

const our $PHASE_SCAN => 'scan';
const our $PHASE_POST_SCAN => 'post_scan';
const our $PHASE_BUILD => 'build';
const our $PHASE_FILTER => 'filter';

=head1 METHODS

=head2 init

Set the defaults for the object if they are not defined already.

=cut
sub init {
    my $self = shift;
    my $config = shift;

    # connect to the metadb because some hooks might need the info
    $self->{metadb} = Muster::MetaDb->new(%{$config});
    $self->{metadb}->init();

    # Hooks are defined by Muster::Hook objects. The Pluggable module will find
    # all possible hooks but the config will have defined a subset in the order
    # we want to apply them.
    # The way this is done is that we call "register" for the hooks in that order,
    # and while a given hook object may have more than one callback, at least
    # all of the hooks for THAT module will come after the module before, etc.
    $self->{hooks} = {};
    $self->{hookorder} = [];
    my %phooks = ();
    foreach my $ph ($self->plugins())
    {
        $phooks{ref $ph} = $ph;
    }
    foreach my $hookmod (@{$config->{hooks}})
    {
        if ($phooks{$hookmod})
        {
            $phooks{$hookmod}->register($self,$config);
        }
        else
        {
            warn "Hook '$hookmod' does not exist";
        }
    }

    # Filters use register_filter instead
    # This will be a no-op for most hooks.
    $self->{filters} = {};
    $self->{filterorder} = [];
    foreach my $mod (@{$config->{hooks}})
    {
        if ($phooks{$mod})
        {
            $phooks{$mod}->register_filter($self,$config);
        }
        else
        {
            warn "Filter '$mod' does not exist";
        }
    }

    return $self;
} # init

=head2 add_hook

Add a hook.

=cut
sub add_hook {
    my ($self, $name, $call) = @_;
    $self->{hooks}->{$name} = $call;
    push @{$self->{hookorder}}, $name;
    return $self;
} # add_hook

=head2 run_hooks

Run the hooks over the given leaf.
Leaf must already be created and reclassified.
The "phase" flag says what phase we are in (e.g. scanning)
    
    $leaf = $self->run_hooks(leaf=>$leaf,phase=>$phase);

=cut

sub run_hooks {
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};

    foreach my $hn (@{$self->{hookorder}})
    {
        $leaf = $self->{hooks}->{$hn}(%args);
    }

    return $leaf;
} # run_hooks

=head2 add_filter

Add a post-processing filter.

=cut
sub add_filter {
    my ($self, $name, $call) = @_;
    $self->{filters}->{$name} = $call;
    push @{$self->{filterorder}}, $name;
    return $self;
} # add_filter

=head2 run_filters

Run post-processing filters over already-rendered HTML.
    
    $html = $self->run_filters(html=>$html,phase=>$phase);

=cut

sub run_filters {
    my $self = shift;
    my %args = @_;

    my $html = $args{html};

    foreach my $hn (@{$self->{filterorder}})
    {
        $html = $self->{filters}->{$hn}(%args);
    }

    return $html;
} # run_filters

1; # End of Muster::Hooks
__END__
