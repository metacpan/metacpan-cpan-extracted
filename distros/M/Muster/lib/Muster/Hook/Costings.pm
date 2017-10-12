package Muster::Hook::Costings;
$Muster::Hook::Costings::VERSION = '0.62';
=head1 NAME

Muster::Hook::Costings - Muster hook for costings derivation

=head1 VERSION

version 0.62

=head1 DESCRIPTION

L<Muster::Hook::Costings> does costings derivation;
that is, derives costs of things from the page meta-data
plus looking up information in various databases.

This just does a bunch of specific calculations;
I haven't figured out a good way of defining derivations in a config file.

=cut

use Mojo::Base 'Muster::Hook';
use Muster::Hooks;
use Muster::LeafFile;
use DBI;
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

    # we need to be able to look things up in the database
    $self->{metadb} = $hookmaster->{metadb};

    # and in the other databases as well!
    $self->{databases} = {};
    while (my ($alias, $file) = each %{$conf->{hook_conf}->{'Muster::Hook::SqlReport'}})
    {
        if (!-r $file)
        {
            warn __PACKAGE__, " cannot read database '$file'";
        }
        else
        {
            my $dbh = DBI->connect("dbi:SQLite:dbname=$file", "", "");
            if (!$dbh)
            {
                croak "Can't connect to $file $DBI::errstr";
            }
            $self->{databases}->{$alias} = $dbh;
        }
    }
    $self->{config} = $conf->{hook_conf}->{'Muster::Hook::Costings'};

    $hookmaster->add_hook('costings' => sub {
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

    # -----------------------------------------------------------
    # All these costings are only relevant for craft inventory pages
    # so skip everything else
    # -----------------------------------------------------------
    if ($leaf->pagename !~ /inventory/)
    {
        return $leaf;
    }

    # -----------------------------------------------------------
    # LABOUR TIME
    # If "construction" is given, use that to calculate the labour time
    # There may be more than one means of contruction; for example,
    # a resin pendant with a maille chain.
    # An explicit top-level "labour_time" overrides this
    # -----------------------------------------------------------
    if (exists $meta->{construction}
            and defined $meta->{construction}
            and not exists $meta->{labour_time}
            and not defined $meta->{labour_time})
    {
        my $labour = 0;
        my $constr = $meta->{construction};
        if (!ref $meta->{construction} and $meta->{construction} =~ /^---/ms) # YAML
        {
            $constr = Load($meta->{construction});
        }
        foreach my $key (sort keys %{$constr})
        {
            my $item = $constr->{$key};
            my $item_mins = 0;
            if (defined $item->{uses} and $item->{uses} eq 'yarn')
            {
                # This is a yarn/stitch related method

                # Do extra calculations for Lucet cord if need be
                if ($item->{method} eq 'Lucet Cord'
                        and !$item->{stitches_length}
                        and defined $item->{length}
                        and defined $item->{stitches_per})
                {
                    $item->{stitches_length} = ($item->{stitches_per}->{stitches} / $item->{stitches_per}->{length}) * $item->{length};
                }

                # Look in the yarn database
                my $cref = $self->_do_n_col_query('yarn',
                    "SELECT Minutes,StitchesWide,StitchesLong FROM metrics WHERE Method = '$item->{method}';");
                if ($cref and $cref->[0])
                {
                    my $row = $cref->[0];
                    my $minutes = $row->{Minutes};
                    my $wide = $row->{StitchesWide};
                    my $long = $row->{StitchesLong};

                    $item_mins = ((($item->{stitches_width} * $item->{stitches_length}) / ($wide * $long)) * $minutes);
                    # round them
                    $item_mins=sprintf ("%.0f",$item_mins+.5);
                }
            }
            elsif (defined $item->{uses} and $item->{uses} eq 'chainmaille')
            {
                # default time-per-ring is 30 seconds
                # but it can be overridden for something like, say, Titanium, or experimental weaves
                my $secs_per_ring = ($item->{secs_per_ring} ? $item->{secs_per_ring} : 30);
                $item_mins = ($secs_per_ring * $item->{rings}) / 60.0;
            }
            elsif (defined $item->{uses} and $item->{uses} =~ /resin/i)
            {
                # Resin time depends on the number of layers
                # but the number of minutes per layer may be overridden; by default 30 mins
                # This of course does not include curing time.
                my $mins_per_layer = ($item->{mins_per_layer} ? $item->{mins_per_layer} : 30);
                $item_mins = $mins_per_layer * $item->{layers};
            }
            elsif ($item->{minutes})
            {
                # generic task override, just say how many minutes it took
                $item_mins = $item->{minutes};

                # This may be multiplied by an "amount", because this could be
                # talking about repeated actions. For example, wire-wrapping the
                # ends of six cords, the amount would be six.
                $item_mins = $item_mins * $item->{amount} if $item->{amount};
            }
            $meta->{construction}->{$key}->{minutes} = $item_mins;
            $labour += $item_mins;
        }
        $meta->{labour_time} = $labour if $labour;
    }

    # -----------------------------------------------------------
    # MATERIAL COSTS
    # -----------------------------------------------------------
    if (exists $meta->{materials} and defined $meta->{materials})
    {
        my %materials_hash = ();
        my $cost = 0;
        my $mat = $meta->{materials};
        if (!ref $meta->{materials} and $meta->{materials} =~ /^---/ms) # YAML
        {
            my $mat = Load($meta->{materials});
        }
        foreach my $key (sort keys %{$mat})
        {
            my $item = $mat->{$key};
            my $item_cost = 0;
            if ($item->{cost})
            {
                $item_cost = $item->{cost};
                if ($key !~ /findings/i)
                {
                    if ($key =~ /Made By Ring/i)
                    {
                        $materials_hash{'Anodized Aluminium'}++;
                    }
                    else
                    {
                        $materials_hash{$key}++;
                    }
                }
            }
            elsif ($item->{type})
            {
                if ($item->{type} eq 'yarn')
                {
                    my $cref = $self->_do_n_col_query('yarn',
                        "SELECT BallCost,Materials FROM yarn WHERE SourceCode = '$item->{source}' AND Name = '$item->{name}';");
                    if ($cref and $cref->[0])
                    {
                        my $row = $cref->[0];
                        $item_cost = $row->{BallCost};
                        my @mar = split(/[|]/, $row->{Materials});
                        foreach my $mm (@mar)
                        {
                            $mm =~ s/Viscose/Artificial Silk/;
                            $mm =~ s/Rayon/Artificial Silk/;
                            $materials_hash{$mm}++;
                        }
                    }
                }
                elsif ($item->{type} eq 'maille')
                {
                    # the cost-per-ring in the chainmaille db is in cents, not dollars
                    my $cref = $self->_do_n_col_query('chainmaille',
                        "SELECT CostPerRing,Metal FROM rings WHERE Code = '$item->{code}';");
                    if ($cref and $cref->[0])
                    {
                        my $row = $cref->[0];
                        $item_cost = ($row->{CostPerRing}/100.0);
                        $materials_hash{$row->{Metal}}++;
                    }
                }
                elsif ($item->{type} eq 'supplies')
                {
                    my $cref = $self->_do_n_col_query('supplies',
                        "SELECT cost,materials,title,tags FROM supplies WHERE Name = '$item->{name}';");
                    if ($cref and $cref->[0])
                    {
                        my $row = $cref->[0];
                        $item_cost = $row->{cost};
                        if ($key =~ /resin/i)
                        {
                            $materials_hash{'Resin'}++;
                        }
                        else
                        {
                            $materials_hash{$key}++;
                        }
                    }
                }
            }
            else
            {
                $materials_hash{$key}++;
            }

            if ($item->{amount})
            {
                $item_cost = $item_cost * $item->{amount};
            }
            $meta->{materials}->{$key}->{cost} = $item_cost;
            $cost += $item_cost;
        } # for each item
        $meta->{materials_cost} = $cost;
        $meta->{materials_list} = join(', ', sort keys %materials_hash);
    }
    # -----------------------------------------------------------
    # LABOUR COSTS
    # the labour_time will either be defined or derived
    # if no suffix is given, assume minutes
    # -----------------------------------------------------------
    my $per_hour = (exists $meta->{cost_per_hour}
        ? $meta->{cost_per_hour}
        : (exists $self->{config}->{cost_per_hour}
            ? $self->{config}->{cost_per_hour}
            : 20));
    if (exists $meta->{labour_time} and defined $meta->{labour_time})
    {
        my $hours;
        if ($meta->{labour_time} =~ /(\d+)h/i)
        {
            $hours = $1;
        }
        elsif ($meta->{labour_time} =~ /(\d+)d/i)
        {
            # assume an eight-hour day
            $hours = $1 * 8;
        }
        elsif ($meta->{labour_time} =~ /(\d+)s/i)
        {
            # seconds
            $hours = $1 / (60.0 * 60.0);
        }
        elsif ($meta->{labour_time} =~ /(\d+)/i)
        {
            # minutes
            $hours = $1 / 60.0;
        }
        if ($hours)
        {
            $meta->{used_cost_per_hour} = $per_hour;
            $meta->{labour_cost} = $hours * $per_hour;
        }
    }
    # -----------------------------------------------------------
    # ITEMIZE TIME and ITEMIZE COSTS
    # Every item listed in my inventory and listed on Etsy
    # takes a certain amount of labour:
    # * photographing
    # * naming and tagging the photos
    # * adding the item to the inventory
    # * adding the item to Etsy
    # This is in common for all items, no matter what their labour is,
    # so I'm doing this as a separate cost.
    # -----------------------------------------------------------
    my $itemize_mins = (exists $meta->{itemize_time}
        ? $meta->{itemize_time}
            : (exists $self->{config}->{itemize_time}
                ? $self->{config}->{itemize_time}
                : 15));
    if ($itemize_mins)
    {
        $meta->{itemize_time} = $itemize_mins;
        my $hours = $itemize_mins / 60.0;
        $meta->{used_cost_per_hour} = $per_hour;
        $meta->{itemize_cost} = $hours * $per_hour;
    }

    # -----------------------------------------------------------
    # TOTAL COSTS AND OVERHEADS
    # Calculate total costs from previously derived costs
    # Add in the overheads, then re-calculate the total;
    # this is because some overheads depend on a percentage of the total cost.
    # -----------------------------------------------------------
    if (exists $meta->{materials_cost} or exists $meta->{labour_cost})
    {
        my $wholesale = $meta->{materials_cost} + $meta->{labour_cost} + $meta->{itemize_cost};
        my $overheads = calculate_overheads($wholesale);
        $meta->{estimated_overheads1} = $overheads;
        my $retail = $wholesale + $overheads;
        $overheads = calculate_overheads($retail);
        $meta->{estimated_overheads} = $overheads;
        $meta->{estimated_cost} = $retail;
        if ($meta->{actual_price})
        {
            $meta->{actual_overheads} = calculate_overheads($meta->{actual_price});
            $meta->{actual_return} = $meta->{actual_price} - $meta->{actual_overheads};
        }
    }
    if (exists $meta->{postage} and defined $meta->{postage})
    {
        # Note that all my jewellery is too thick to be able to be sent as a Large Letter.
        # Postage within AU for a small-500g parcel is $7.60.
        # Putting in the prices here for Economy-Air for overseas parcels. But round to a round number.
        # Price as of 13-05-2017
        # Plus the cost of the packaging.
        # The very smallest padded bags range from 30c to $2 each - ha!
        # I'm not sure what size of bag I would need for the larger/heavier items
        # (apart from Rayvyn's scarf, which barely fits into a size-4 bag)
        # (but it is interesting, that despite its bulk, it still weighs less than 500g)
        if ($meta->{postage} eq 'light') # less than 500g
        {
            $meta->{postage_au} = 7.60 + 1;
            $meta->{postage_nz} = 12.00 + 1; # 11.86
            $meta->{postage_us} = 16.00 + 1; # 15.85
            $meta->{postage_uk} = 20.50 + 1; # 20.46
        }
        elsif ($meta->{postage} eq 'light-large') # less than 500g, but big size, needs a larger envelope
        {
            $meta->{postage_au} = 7.60 + 2;
            $meta->{postage_nz} = 12.00 + 2;
            $meta->{postage_us} = 16.00 + 2;
            $meta->{postage_uk} = 20.50 + 2;
        }
        elsif ($meta->{postage} eq 'middling') # up to 1kg
        {
            $meta->{postage_au} = 16.40 + 2;
            $meta->{postage_nz} = 24.00 + 2;
            $meta->{postage_us} = 33.50 + 2;
            $meta->{postage_uk} = 35.50 + 2;
        }
        elsif ($meta->{postage} eq 'heavy') # up to 1.5 kg
        {
            $meta->{postage_au} = 19.50 + 2;
            $meta->{postage_nz} = 29.00 + 2;
            $meta->{postage_us} = 45.50 + 2;
            $meta->{postage_uk} = 48.00 + 2;
        }
        elsif ($meta->{postage} eq 'v-heavy') # up to 2kg
        {
            $meta->{postage_au} = 19.50 + 2;
            $meta->{postage_nz} = 34.00 + 2;
            $meta->{postage_us} = 58.00 + 2;
            $meta->{postage_uk} = 60.00 + 2;
        }
    }

    $leaf->{meta} = $meta;
    return $leaf;
} # process

=head2 calculate_overheads

Calculate overheads like listing fees and COMMISSION (which depends on the total, backwards)

=cut
sub calculate_overheads {
    my $bare_cost = shift;

    # Etsy listing fees are 20c US per listing per four months;
    # but I can't assume that a listing will sell within that period, so double that.
    # Etsy promoted listings depend on one's budget;
    # I'm currently doing $1.50 a day, spread over N items, so need to guestimate that.
    # Etsy transaction fees are: 3.5% commission
    # "Etsy Payments" fees are 25c AU per item, plus 4% of item cost
    my $overheads = ((0.2 / 0.7) * 2)
    + 0.5
    + ($bare_cost * 0.035)
    + 0.25
    + ($bare_cost * 0.04);

    # And now Etsy are charging GST on their fees
    $overheads += $overheads * 0.1;

    # Add another 5% for random other overheads, such as handling.
    $bare_cost += $overheads;
    $overheads += ($bare_cost * 0.05);
    
    # I'm not including Paypal here -- that's for if I'm not selling through Etsy.
    # (Paypal fees: 3.5% plus 30c per transaction?)
    # GST is not included because I don't have to pay GST because I'm not making $75,000

    return $overheads;
} # calculate_overheads

=head2 _do_one_col_query

Do a SELECT query, and return the first column of results.
This is a freeform query, so the caller must be careful to formulate it correctly.

my $results = $self->_do_one_col_query($dbname,$query);

=cut

sub _do_one_col_query {
    my $self = shift;
    my $dbname = shift;
    my $q = shift;

    if ($q !~ /^SELECT /)
    {
        # bad boy! Not a SELECT.
        return undef;
    }
    my $dbh = $self->{databases}->{$dbname};
    return undef if !$dbh;

    my $sth = $dbh->prepare($q);
    if (!$sth)
    {
        croak "FAILED to prepare '$q' $DBI::errstr";
    }
    my $ret = $sth->execute();
    if (!$ret)
    {
        croak "FAILED to execute '$q' $DBI::errstr";
    }
    my @results = ();
    my @row;
    while (@row = $sth->fetchrow_array)
    {
        push @results, $row[0];
    }
    return \@results;
} # _do_one_col_query

=head2 _do_n_col_query

Do a SELECT query, and return all the results.
This is a freeform query, so the caller must be careful to formulate it correctly.

my $results = $self->_do_n_col_query($dbname,$query);

=cut

sub _do_n_col_query {
    my $self = shift;
    my $dbname = shift;
    my $q = shift;

    if ($q !~ /^SELECT /)
    {
        # bad boy! Not a SELECT.
        return undef;
    }
    my $dbh = $self->{databases}->{$dbname};
    return undef if !$dbh;

    my $sth = $dbh->prepare($q);
    if (!$sth)
    {
        croak "FAILED to prepare '$q' $DBI::errstr";
    }
    my $ret = $sth->execute();
    if (!$ret)
    {
        croak "FAILED to execute '$q' $DBI::errstr";
    }
    my @results = ();
    my $row;
    while ($row = $sth->fetchrow_hashref)
    {
        push @results, $row;
    }
    return \@results;
} # _do_n_col_query

1;
