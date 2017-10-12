package Muster::Hook::DeriveFields;
$Muster::Hook::DeriveFields::VERSION = '0.62';
=head1 NAME

Muster::Hook::DeriveFields - Muster hook for field derivation

=head1 VERSION

version 0.62

=head1 DESCRIPTION

L<Muster::Hook::DeriveFields> does field derivation;
that is, derives field values from other fields
(aka the meta-data for the Leaf).

This just does a bunch of specific calculations;
I haven't figured out a good way of defining derivations in a config file.

=cut

use Mojo::Base 'Muster::Hook';
use Muster::Hooks;
use Muster::LeafFile;
use Lingua::EN::Inflexion;
use YAML::Any;
use Carp;

=head1 METHODS

=head2 register

Initialize, and register hooks.

=cut
sub register {
    my $self = shift;
    my $hookmaster = shift;
    my $conf = shift;

    $self->{config} = $conf->{hook_conf}->{'Muster::Hook::DeriveFields'};

    $hookmaster->add_hook('derivefields' => sub {
            my %args = @_;

            return $self->process(%args);
        },
    );
    return $self;
} # register

=head2 process

Process (scan or modify) a leaf object.
This only does stuff in the scan phase.
This expects the leaf meta-data to be populated.

  my $new_leaf = $self->process(%args);

=cut
sub process {
    my $self = shift;
    my %args = @_;

    my $leaf = $args{leaf};
    my $phase = $args{phase};

    # only does derivations in scan phase
    if ($phase ne $Muster::Hooks::PHASE_SCAN)
    {
        return $leaf;
    }

    my $meta = $leaf->meta;

    # -----------------------------------------
    # Do derivations
    # -----------------------------------------

    # split the page-name on '-'
    # useful for project-types
    my @bits = split('-', $leaf->name);
    for (my $i=0; $i < scalar @bits; $i++)
    {
        my $p1 = sprintf('p%d', $i + 1); # page-bits start from 1 not 0
        $meta->{$p1} = $bits[$i];
    }

    # sections being the parts of the full page name
    @bits = split(/\//, $leaf->pagename);
    # remove the actual page-file from this list
    pop @bits;
    for (my $i=0; $i < scalar @bits; $i++)
    {
        my $section = sprintf('section%d', $i + 1); # sections start from 1 not 0
        $meta->{$section} = $bits[$i];
    }

    # the first Alpha of the name; good for headers in reports
    $meta->{name_a} = uc(substr($leaf->name, 0, 1));

    # plural and singular 
    # assuming that the page-name is a noun...
    my $noun = noun($leaf->name);
    if ($noun->is_plural())
    {
        $meta->{singular} = $noun->singular();
        $meta->{plural} = $leaf->name;
    }
    elsif ($noun->is_singular())
    {
        $meta->{singular} = $leaf->name;
        $meta->{plural} = $noun->plural();
    }
    else # neither
    {
        $meta->{singular} = $leaf->name;
        $meta->{plural} = $leaf->name;
    }

    # Classify the prose length for those pages that have wordcounts. Of course,
    # this assumes that all of the words are in one page, which for long
    # stories won't be the case. Hmmm.
    if ($meta->{wordcount})
    {
        my $len = '';
        if ($meta->{wordcount} == 100)
        {
            $len = 'Drabble';
        } elsif ($meta->{wordcount} == 200)
        {
            $len = 'Double-Drabble';
        } elsif ($meta->{wordcount} >= 75000)
        {
            $len = 'Long-Novel';
        } elsif ($meta->{wordcount} >= 50000)
        {
            $len = 'Novel';
        } elsif ($meta->{wordcount} >= 25000)
        {
            $len = 'Novella';
        } elsif ($meta->{wordcount} >= 7500)
        {
            $len = 'Novelette';
        } elsif ($meta->{wordcount} >= 2000)
        {
            $len = 'Short-Story';
        } elsif ($meta->{wordcount} > 500)
        {
            $len = 'Short-Short';
        } elsif ($meta->{wordcount} <= 500)
        {
            $len = 'Flash';
        }
        if ($meta->{tags})
        {
            if (ref $meta->{tags} eq 'ARRAY')
            {
                push @{$meta->{tags}}, $len;
            }
            else
            {
                $meta->{tags} .= "|$len";
            }
        }
        else
        {
            $meta->{tags} = $len;
        }
    }
    $leaf->{meta} = $meta;

    return $leaf;
} # process


1;
