package Muster::Hook::DeriveFields;
$Muster::Hook::DeriveFields::VERSION = '0.92';
=head1 NAME

Muster::Hook::DeriveFields - Muster hook for field derivation

=head1 VERSION

version 0.92

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
use DateTime;
use POSIX qw(strftime);
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
    my @bits = split('-', $leaf->bald_name);
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
    $meta->{name_a} = uc(substr($leaf->bald_name, 0, 1));

    # name-spaced
    my $namespaced = $leaf->bald_name;
    $namespaced =~ s#_# #g;
    $namespaced =~ s#-# #g;
    $namespaced =~ s/([-\w]+)/\u\L$1/g;
    $meta->{namespaced} = $namespaced;

    # plural and singular 
    # assuming that the page-name is a noun...
    my $noun = noun($leaf->bald_name);
    if ($noun->is_plural())
    {
        $meta->{singular} = $noun->singular();
        $meta->{plural} = $leaf->bald_name;
    }
    elsif ($noun->is_singular())
    {
        $meta->{singular} = $leaf->bald_name;
        $meta->{plural} = $noun->plural();
    }
    else # neither
    {
        $meta->{singular} = $leaf->bald_name;
        $meta->{plural} = $leaf->bald_name;
    }

    # ============================================
    # DATE stuff
    # ============================================

    # Some date adjustments.
    # Files may have creation-date information in them;
    # use that for the "date" of the page
    if (exists $meta->{timestamp}
            and defined $meta->{timestamp}
            and $meta->{timestamp} != $meta->{mtime})
    {
        $meta->{date} = strftime('%Y-%m-%d %H:%M', localtime($meta->{timestamp}));
    }
    elsif (exists $meta->{creation_date}
            and defined $meta->{creation_date}
            and $meta->{creation_date} =~ /^\d\d\d\d-\d\d-\d\d/)
    {
        $meta->{date} = $meta->{creation_date};
    }
    elsif (exists $meta->{date_added}
            and defined $meta->{date_added}
            and $meta->{date_added} =~ /^\d\d\d\d-\d\d-\d\d/)
    {
        $meta->{date} = $meta->{creation_date};
    }
    elsif (exists $meta->{fetch_date}
            and defined $meta->{fetch_date}
            and $meta->{fetch_date} =~ /^\d\d\d\d-\d\d-\d\d/)
    {
        $meta->{date} = $meta->{fetch_date};
    }

    # Derived date-related info using DateTime
    # Look for existing fields which end with _date
    foreach my $field (keys %{$meta})
    {
        if (($field =~ /_date$/ 
                    or $field =~ /^date_/
                    or $field eq 'date')
                and defined $meta->{$field}
                and $meta->{$field} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)/)
        {
            my $year = $1;
            my $month = $2;
            my $day = $3;
            my $hour = 0;
            my $min = 0;
            # The date MAY have time info in it too
            if ($meta->{$field} =~ /^\d\d\d\d-\d\d-\d\d (\d+):(\d\d)/)
            {
                $hour = $1;
                $min = $2;
            }
            my $dt = DateTime->new(year=>$year,month=>$month,day=>$day,
                hour=>$hour,minute=>$min);
            my $new_fn = $field;
            $new_fn =~ s/date/datetime/;
            $meta->{$new_fn} = $dt->epoch();
            $new_fn = $field; $new_fn =~ s/date/date_year/;
            $meta->{$new_fn} = $dt->year();
            $new_fn = $field; $new_fn =~ s/date/date_month/;
            $meta->{$new_fn} = $dt->month();
            $new_fn = $field; $new_fn =~ s/date/date_monthname/;
            $meta->{$new_fn} = $dt->month_name();
        }
    }

    # -----------------------------------------
    # Default field-values
    # set on a per-extension basis.
    # These are set in the config for this hook.
    # They will not clobber existing values.
    # -----------------------------------------
    if (defined $self->{config}->{ext}->{$meta->{extension}})
    {
        foreach my $field (keys %{$self->{config}->{ext}->{$meta->{extension}}})
        {
            if (!defined $meta->{$field})
            {
                $meta->{$field} = $self->{config}->{ext}->{$meta->{extension}}->{$field};
            }
        }
    }

    $leaf->{meta} = $meta;

    return $leaf;
} # process


1;
