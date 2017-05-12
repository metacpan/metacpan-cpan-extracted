package SQL::Snippet::ExampleRepository;
use strict;
use base 'SQL::Snippet';


sub init_parm {  # returns parameter info to invocant

  ### boilerplate ###

    my $self = shift;
    my %args = @_;
    my $parm = $args{parm};

    # the current value of other parms could be useful setting return list for this parm,
    # so we'll provide this method for getting to that information
    my $contextual_parm_info = sub {
        my @args;
        push @args, (lim => $args{lim}) if $args{lim};
        push @args, (pop => $args{pop}) if $args{pop};

        my @return = $self->contextual_parm_info( @args, @_ );
        return (wantarray) ? @return : $return[0];
    };

  ### END boilerplate ###


    if ($parm eq 'gender') {
        return (
            msg         =>  "By default, gender will bear no impact on selection.  Press ENTER to accept this default, or, to limit the selection by gender, type one or more gender codes from the following list:  M (Male), F (Female), U (Unknown)",
            default     =>  '',
            delimiter   =>  ',',
            prompt      =>  'Gender: ',
            check       =>  [ 'M','F','U' ],
        );
    } elsif ($parm eq 'offer_dec_codes') {
        return (
            delimiter   =>  ',',
            prompt      =>  'Offer Code(s): ',
            default     =>  ['O','AO'],
            check       =>  ['O','AO','W','R'],
          # you can switch checks if you actually set up a sample database...
          # check       =>  [$self->dbh,'SELECT DISTINCT DEC_CODE FROM V_DECISION'],
        );
    } elsif ($parm eq 'offer_excld_dec_codes') {
        return (
            delimiter   =>  ',',
            prompt      =>  'Offer Exclude Code(s): ',
            default     =>  ['W','R'],
            check       =>  ['O','AO','W','R'],
          # check       =>  [$self->dbh,'SELECT DISTINCT DEC_CODE FROM V_DECISION'],
        );
     } else {
        # watch out!  if invocant misspelled a parm name it will get the empty list back with no warning!
        return ();
    }
}



sub init_lim {   # returns limit info to invocant

  ### boilerplate ###

    my $self = shift;
    my %args = @_;

    if ($args{lim}) {
        if (!ref $args{lim}) {
            # make a list of this one element
            $args{lim} = [$args{lim}];
        } elsif (ref $args{lim} ne 'ARRAY') {
            die "lim must be scalar or aref!";
        }
    } else {
        die "No lim was specified!";
    }

    my $pop = (defined $args{pop}) ? $args{pop} : '';
    my $single_meta = $args{single_meta} || 0;

    my $contextual_parm_info = sub {
        my @return = $self->contextual_parm_info( @_, ($pop ? (pop => $pop) : ()) );
        return (wantarray) ? @return : $return[0];
    };

    # repository specific #
    # we'll often need the base_id and table to tie in our limits
    # to the base population
    my $get_base_id = sub {
        return join '.' => $contextual_parm_info->(
            method  =>  'value',
            parm    =>  [
                            ['base_table' => { dont_qnd => 1 }],
                            ['base_id'    => { dont_qnd => 1 }],
                        ]
        );

    };
    # END repository specific #

    my $return = {};
    my $assign = sub { $return = _assign($return, @_) };


    LIM:
    for (@{$args{lim}}) {

  ### END boilerplate ###

        if (m'^_meta_data|gender') {
            $assign->(
                'gender',
                valid_pop   => [qw/ individual recruit applicant offer member alum /],
                prompt_parm => [ 'gender' ],
                selectable  => [ 'gender' ],
            );

            unless (m'^_meta_data' or $single_meta) {
                if (my $gender = $contextual_parm_info->( lim => $_, method => 'value', parm => 'gender' ) ) {
                    # If gender parm(s) include U for 'Unknown'...
                    if ($gender =~ /U/i) {
                        $assign->( $_,
                                    sql =>  [
                                                "and personal.id(+) = " . $get_base_id->(),
                                                "and (personal.gender in ($gender) or personal.gender is null)",
                                            ]
                                 );
                    } else {
                        $assign->( $_,
                                    sql =>  [
                                                "and personal.id = " . $get_base_id->(),
                                                "and personal.gender in ($gender)",
                                            ]
                        );
                    }
                    $assign->( $_,
                                table  =>  'personal',
                                note   =>  "This population limited to Gender(s): $gender",
                             );
                }
            }
        }

    }
    return $return;
}


sub init_pop {   # returns population info to invocant

  ### boilerplate ###

    my $self = shift;
    my %args = @_;

    my $pop = $args{pop} or die "No pop was specified!";
    my $single_meta = $args{single_meta} || 0;

    my $contextual_parm_info = sub {
        # allow for abbreviated style when simply requesting parm values
        my @args = (scalar @_ == 1)
                 ? ( parm => shift(), method => 'value' )
                 : @_;

        my @return = $self->contextual_parm_info( pop => $pop, @args );
        return (wantarray) ? @return : $return[0];
    };


    my $return = {};
    my $assign = sub { $return = _assign($return, @_) };

  ### END boilerplate ###

    if ($pop =~ m'^_meta_data|individual') {
        $assign->($pop, selectable => [ qw' person_id fname mname lname ' ]);

        unless ($pop =~ m'^meta_data' or $single_meta) {
            # Set the base table and pidm parm for to allow any limits to link in
            $self->pop->$pop->parm->base_table->value( 'person' );
            $self->pop->$pop->parm->base_id->value( 'id' );

            return (
                table   =>  'person',
                sql     =>  "and change_ind is null",
            );
        }
    }

    if ($pop =~ m'^_meta_data|recruit') {
        $assign->($pop, selectable => [ qw' person_id referral_id ' ]);

        unless ($pop =~ m'^meta_data' or $single_meta) {
            $self->pop->$pop->parm->base_table->value( 'recruit' );
            $self->pop->$pop->parm->base_id->value( 'person_id' );

            return ( table   =>  'recruit' );
        }
    }

    if ($pop =~ m'^_meta_data|applicant') {
        $assign->($pop, selectable => [ qw' person_id app_status_code ' ]);

        unless ($pop =~ m'^meta_data' or $single_meta) {
            $self->pop->$pop->parm->base_table->value( 'applicant' );
            $self->pop->$pop->parm->base_id->value( 'person_id' );

            return (
                table   =>  'applicant',
                sql     =>  "and app_status_code <> 'N'",
            );
        }
    }

    if ($pop =~ m'^_meta_data|offer') {
        $assign->(  $pop,
                    prompt_parm => [ 'offer_dec_codes', 'offer_excld_dec_codes' ],
                    selectable => [ qw' person_id app_status_code ' ],
        );

        unless ($pop =~ m'^meta_data' or $single_meta) {
            $self->pop->$pop->parm->base_table->value( 'applicant' );
            $self->pop->$pop->parm->base_id->value( 'person_id' );

            my ($offer_dec_codes, $offer_excld_dec_codes)
                = $contextual_parm_info->(
                                            method  =>  'value',
                                            parm    =>  [
                                                            'offer_dec_codes',
                                                            'offer_excld_dec_codes',
                                                        ],
                                         );
            return (
                table   =>  'applicant',
                sql     =>  [
                                "and app_status_code <> 'N'",
                                _left_justify_block(<<""),
                                and exists (select 'x'
                                              from appdec
                                             where appdec.applicant_key = applicant.key
                                               and appdec.dec_code in ($offer_dec_codes)
                                )

                                _left_justify_block(<<""),
                                and not exists(select 'x'
                                                 from appdec
                                                where appdec.applicant_key = applicant.key
                                                  and appdec.dec_code in ($offer_excld_dec_codes)
                                )

                            ],
            );
        }
    }

    if ($pop =~ m'^_meta_data|member') {
        $assign->($pop, selectable => [ qw' person_id app_status_code ' ]);

        unless ($pop =~ m'^meta_data' or $single_meta) {
            $self->pop->$pop->parm->base_table->value( 'applicant' );
            $self->pop->$pop->parm->base_id->value( 'person_id' );

            return (
                table   =>  'applicant',
                sql     =>  "and app_status_code = 'M'",
            );
        }
    }

    if ($pop =~ m'^_meta_data|alum') {
        $assign->($pop, selectable => [ qw' person_id app_status_code ' ]);

        unless ($pop =~ m'^meta_data' or $single_meta) {
            $self->pop->$pop->parm->base_table->value( 'applicant' );
            $self->pop->$pop->parm->base_id->value( 'person_id' );

            return (
                table   =>  'applicant',
                sql     =>  "and app_status_code = 'A'",
            );
        }
    }

    return $return;
}

# this is just a small helper function for pretty formatting snippets
# with eggregious left spacing due to "here document" style creation
sub _left_justify_block {
    my $block = shift;
    die "This is a function for local use, not a method!" if ref $block;
    my @lines = split /\n/ => $block;
    my $space_length;
    for (@lines) {
        m/^(\s+)/;
        $space_length = length $1 if (!defined $space_length or length $1 < $space_length);
    }
    for (@lines) {
        substr($_, 0, $space_length) = '';
    }
    return join "\n" => @lines;
}

# another helper sub
sub _assign {
    my $href = shift;
    my $key1 = shift;
    die "Uneven number of args for hash assignemt!" if (scalar @_ % 2);
    my %args = @_;
    for my $key2 (keys %args) {
        if (defined $href->{$key1}{$key2}) {
            if (ref $href->{$key1}{$key2} eq 'ARRAY') {
                if (!ref $args{$key2}) {
                    push @{$href->{$key1}{$key2}}, $args{$key2};
                } elsif (ref $args{$key2} eq 'ARRAY') {
                    push @{$href->{$key1}{$key2}}, @{$args{$key2}};
                } else {
                    die "Can't _assign this additional value for return!  Current value is an aref.";
                }
            } elsif (ref $href->{$key1}{$key2} eq 'HASH') {
                if (ref $args{$key2} eq 'HASH') {
                    $href->{$key1}{$key2}{$_} = $args{$key2}{$_} for (keys %{ $args{$key2} });
                } elsif (ref $args{$key2} eq 'ARRAY') {
                    die "Uneven number of args for hash assignemt!" if (scalar @{$args{$key2}} % 2);
                    my %args = %{$args{$key2}};
                    $href->{$key1}{$key2}{$_} = $args{$_} for (keys %args);
                } else {
                    die "Can't _assign this additional value for return!  Current value is an href.";
                }
            } elsif (!ref $href->{$key1}{$key2}) {
                die "Can't _assign this additional value for return!  Current value is a scalar.";
            }
        } else {
            $href->{$key1}{$key2} = $args{$key2};
        }
    }
    return $href;
};


# modules must return true
1;
