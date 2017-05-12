package RRDTool::OO;

use 5.6.0;
use strict;
use warnings;
use Carp;
use RRDs;
use Storable;
use Data::Dumper;
use Log::Log4perl qw(:easy);

our $VERSION = '0.36';

   # Define the mandatory and optional parameters for every method.
our $OPTIONS = {
    new        => { mandatory => ['file'],
                    optional  => [qw(raise_error dry_run strict)],
                  },
    create     => { mandatory => [qw(data_source)],
                    optional  => [qw(step start hwpredict archive)],
                    data_source => { 
                      mandatory => [qw(name type)],
                      optional  => [qw(min max heartbeat)],
                    },
                    archive     => {
                      mandatory => [qw(rows)],
                      optional  => [qw(cfunc cpoints xff)],
                    },
                    hwpredict   => {
                      mandatory => [qw(rows)],
                      optional  => [qw(
                                       alpha beta gamma
                                       seasonal_period
                                       threshold window_length
                                      )],
                    },
                  },
    update     => { mandatory => [qw()],
                    optional  => [qw(time value values)],
                  },
    graph      => { mandatory => [qw(image)],
                    optional  => [qw(vertical_label title start end x_grid
                                     y_grid alt_y_grid no_minor alt_y_mrtg
                                     alt_autoscale alt_autoscale_max base
                                     units_exponent units_length width
                                     height interlaced imginfo imgformat
                                     overlay unit lazy upper_limit lower_limit
                                     rigid
                                     logarithmic color no_legend only_graph
                                     force_rules_legend title step draw
                                     line area shift tick
                                     print gprint vrule hrule comment font
                                     no_gridfit font_render_mode
                                     font_smoothing_threshold slope_mode
                                     tabwidth units watermark zoom
                                     disable_rrdtool_tag
                                    )],
                    draw      => {
                      mandatory => [qw()],
                      optional  => [qw(file dsname cfunc thickness 
                                       type color legend name cdef vdef
                                       stack step start end
                                      )],
                    },
                    color     => {
                      mandatory => [qw()],
                      optional  => [qw(back canvas shadea shadeb
                                       grid mgrid font frame arrow)],
                    },
                    font      => {
                      mandatory => [qw(name)],
                      optional  => [qw(element size)],
                    },
                    print      => {
                      mandatory => [qw()],
                      optional  => [qw(draw format cfunc)],
                    },
                    gprint     => {
                      mandatory => [qw(format)],
                      optional  => [qw(draw cfunc)],
                    },
                    vrule      => {
                      mandatory => [qw(time)],
                      optional  => [qw(color legend)],
                    },
                    hrule      => {
                      mandatory => [qw(value)],
                      optional  => [qw(color legend)],
                    },
                    comment    => {
                      mandatory => [],
                      optional  => [],
                    },
                    line        => {
                      mandatory => [qw(value)],
                      optional  => [qw(width color legend stack)],
                    },
                    area        => {
                      mandatory => [qw(value)],
                      optional  => [qw(color legend stack)],
                    },
                    tick        => {
                      mandatory => [qw()],
                      optional  => [qw(draw color legend fraction)],
                    },
                    shift       => {
                      mandatory => [qw(offset)],
                      optional  => [qw(draw)],
                    },
                 },
     xport => {
        mandatory => [qw(xport)],
        optional  => [qw(def cdef start end step maxrows daemon)],
        def => {
            mandatory => [qw(file vname dsname cfunc)],
            optional => [],
        },
        cdef => {
            mandatory => [qw(vname rpn)],
            optional => [],
        },
        xport => {
            mandatory => [qw(vname)],
            optional => [qw(legend)],
        },
    },
    fetch_start=> { mandatory => [qw()],
                    optional  => [qw(cfunc start end resolution)],
                  },
    fetch_next => { mandatory => [],
                    optional  => [],
                  },
    dump       => { mandatory => [],
                    optional  => [],
                  },
    restore    => { mandatory => [qw()],
                    optional  => [qw(xml range_check)],
                  },
    tune       => { mandatory => [],
                    optional  => [qw(heartbeat minimum maximum 
                                     type name)],
                  },
    first      => { mandatory => [],
                    optional  => [],
                  },
    last       => { mandatory => [],
                    optional  => [],
                  },
    info       => { mandatory => [],
                    optional  => [],
                  },
    rrdresize  => { mandatory => [],
                    optional  => [],
                  },
    rrdcgi     => { mandatory => [],
                    optional  => [],
                  },
};

my %RRDs_functions = (
    create    => \&RRDs::create,
    fetch     => \&RRDs::fetch,
    update    => \&RRDs::update,
    updatev   => \&RRDs::updatev,
    graph     => \&RRDs::graph,
    graphv    => \&RRDs::graphv,
    info      => \&RRDs::info,
    dump      => \&RRDs::dump,
    restore   => \&RRDs::restore,
    tune      => \&RRDs::tune,
    first     => \&RRDs::first,
    last      => \&RRDs::last,
    info      => \&RRDs::info,
    rrdresize => \&RRDs::rrdresize,
    xport     => \&RRDs::xport,
    rrdcgi    => \&RRDs::rrdcgi,
);

#################################################
sub option_add {
#################################################
    my($self, $method, @options) = @_;

    my @parts = split m#/#, $method;
    my $ref = $OPTIONS;
    $ref = $ref->{$_} for @parts;

    push @{ $ref->{optional} }, $_ for @options;
}

#################################################
sub check_options {
#################################################
    my($self, $method, $options) = @_;

    $options = [] unless defined $options;

    my %options_hash = (@$options);

    my @parts = split m#/#, $method;

    my $ref = $OPTIONS;

    $ref = $ref->{$_} for @parts;

    my %optional  = map { $_ => 1 } @{$ref->{optional}};
    my %mandatory = map { $_ => 1 } @{$ref->{mandatory}};

        # Check if we got all mandatory parameters
    for(@{$ref->{mandatory}}) {
        if(! exists $options_hash{$_}) {
            Log::Log4perl->get_logger("")->logcroak(
                "Mandatory parameter '$_' not set " .
                "in $method() (@{[%mandatory]}) (@$options)");
        }
    }
    
        # Check if all of the optional parameters we got are indeed
        # valid optional parameters
    if($self->{strict}) {
        for(keys %options_hash) {
            if(! exists $optional{$_} and
               ! exists $mandatory{$_}) {
                Log::Log4perl->get_logger("")->logcroak(
                    "Illegal parameter '$_' in $method()");
            }
        }
    }

    1;
}

#################################################
sub new {
#################################################
    my($class, %options) = @_;

    my $self = {
        raise_error        => 1,
        strict             => 1,
        dry_run            => 0,
        exec_subref        => undef,
        exec_args          => [],
        exec_func          => [],
        print_results      => [],
        meta               => 
            { discovered   => 0,
              cfuncs       => [],
              cfuncs_hash  => {},
              dsnames      => [],
              dsnames_hash => {},
            },
        %options,
    };

    bless $self, $class;

      # For this one, we need to be strict
    local $self->{strict} = 1;
    $self->check_options("new", [%options]);

    return $self;
}

#################################################
sub first_def {
#################################################
    foreach(@_) {
        return $_ if defined $_;
    }
    return undef;
}

#################################################
sub create {
#################################################
    my($self, @options) = @_;

    $self->check_options("create", \@options);
    my %options_hash = @options;

      # If it's a DateTime object, handle it gracefully
    if( ref $options_hash{start} eq "DateTime" ) {
        $options_hash{start} = $options_hash{start}->epoch();
    }

    my @archives;
    my @data_sources;
    my @hwpredict;

    for(my $i=0; $i < @options; $i += 2) {
          # Push copies (!) of original hashes onto internal data structures
        push @archives, { %{$options[$i+1]} } if $options[$i] eq "archive";
        push @hwpredict, { %{$options[$i+1]} } if $options[$i] eq "hwpredict";
        push @data_sources, 
            { %{$options[$i+1]} } if $options[$i] eq "data_source";
    }

    if(!@archives and !@hwpredict) {
        LOGDIE "No archives specified (use either 'archive' or 'hwpredict')";
    }

    DEBUG "Archives: ", scalar @archives, " Sources: ", scalar @data_sources;

    for(@archives) {
        $self->check_options("create/archive", [%$_]);
    }
    for(@data_sources) {
        $self->check_options("create/data_source", [%$_]);
    }
    for(@hwpredict) {
        $self->check_options("create/hwpredict", [%$_]);
    }

    my @rrdtool_options = ($self->{file});

    push @rrdtool_options, "--start", $options_hash{start} if
        exists $options_hash{start};

    push @rrdtool_options, "--step", $options_hash{step} if
        exists $options_hash{step};

        # RRDtool default setting
    $options_hash{step} ||= 300;

    for(@data_sources) {
       # DS:ds-name:DST:heartbeat:min:max
       DEBUG "data_source: @{[%$_]}";
       $_->{heartbeat} ||= $options_hash{step} * 2;
       push @rrdtool_options, 
           "DS:$_->{name}:$_->{type}:$_->{heartbeat}:" .
           (defined $_->{min} ? $_->{min} : "U") . ":" .
           (defined $_->{max} ? $_->{max} : "U");

       $self->meta_data("dsnames", $_->{name}, 1);
    }

    for(@archives) {
       # RRA:CF:xff:steps:rows
       DEBUG "archive: @{[%$_]}";
       if(! exists $_->{xff}) {
           $_->{xff} = 0.5;
       }

       $_->{cpoints} ||= 1;

       if($_->{cpoints} > 1 and
          !exists $_->{cfunc}) {
           LOGDIE "Must specify cfunc if cpoints > 1";
       }
       if(! exists $_->{cfunc}) {
           $_->{cfunc} = 'MAX';
       }
       
       $self->meta_data("cfuncs", $_->{cfunc}, 1);

       push @rrdtool_options, 
           "RRA:$_->{cfunc}:$_->{xff}:$_->{cpoints}:$_->{rows}";
    }

    my $hwpredict_num = (scalar @archives) + 1;

    for(@hwpredict) {
      # RRA:HWPREDICT:rows:alpha:beta:seasonal period[:rra-num]
      # RRA:SEASONAL:seasonal period:gamma:rra-num
      # RRA:DEVSEASONAL:seasonal period:gamma:rra-num
      # RRA:DEVPREDICT:rows:rra-num
      # RRA:FAILURES:rows:threshold:window length:rra-num

       DEBUG "hwpredict: @{[%$_]}";

       def_or($_->{alpha}, 0.1);
       def_or($_->{beta},  0.1);
       def_or($_->{gamma}, $_->{alpha});
       def_or($_->{threshold}, 7);
       def_or($_->{window_length}, 9);
       def_or($_->{seasonal_period}, int($_->{rows}/5) );

#       push @rrdtool_options, 
#        "RRA:HWPREDICT:$_->{rows}:$_->{alpha}:" .
#        "$_->{beta}:$_->{seasonal_period}:";

         #0
       push @rrdtool_options, 
        "RRA:HWPREDICT:$_->{rows}:$_->{alpha}:" .
        "$_->{beta}:$_->{seasonal_period}:" . 
        ($hwpredict_num + 1);

         #1
       push @rrdtool_options, 
        "RRA:SEASONAL:$_->{seasonal_period}:$_->{gamma}:" .
        ($hwpredict_num + 0);

         #2
       push @rrdtool_options, 
        "RRA:DEVSEASONAL:$_->{seasonal_period}:$_->{gamma}:" .
        ($hwpredict_num + 0);

         #3
       push @rrdtool_options, 
        "RRA:DEVPREDICT:$_->{rows}:" . 
        ($hwpredict_num + 2);

         #4
       push @rrdtool_options, 
        "RRA:FAILURES:$_->{rows}:$_->{threshold}:" .
        "$_->{window_length}:" .
        ($hwpredict_num + 2);

       $hwpredict_num++;
    }

    $self->RRDs_execute("create", @rrdtool_options);
}

#################################################
sub RRDs_execute {
#################################################
    my ($self, $command, @args) = @_;

    my $logger = get_logger("rrdtool");
    $logger->info("rrdtool '$command' ", join " ", map { "'$_'" } @args);

    if ($self->{dry_run}) {
        $self->{exec_subref} = $RRDs_functions{$command} ;
        $self->{exec_args}   = \@args ;
        $self->{exec_func}   = $command;
        return ;
    }
	
    my @rc;
    my $error;

    if(wantarray) {
        @rc = $RRDs_functions{$command}->(@args);
        INFO "rrdtool rc=(", array_as_string(\@rc), ")";
        $error = 1 unless defined $rc[0];
    } else {
        $rc[0] = $RRDs_functions{$command}->(@args);
        INFO "rrdtool rc=(", array_as_string(\@rc), ")";
        $error = 1 unless $rc[0];
    }

    if($error) {
        LOGDIE "rrdtool $command @args failed: ", $self->error_message() if
            $self->{raise_error};
    }

        # Important to return no array in scalar context.
    if(wantarray) {
        return @rc;
    } else {
        return $rc[0];
    }
}

#################################################
sub get_exec_env {
#################################################
    my($self) = @_;

    # returns stored environment in previous dry-run exec
    return ($self->{exec_subref},
            $self->{exec_args},
            $self->{exec_func},
           );
}

#################################################
sub update {
#################################################
    my($self, @options) = @_;

        # Expand short form
    @options = (value => $options[0]) if @options == 1;

    $self->check_options("update", \@options);

    my %options_hash = @options;

    $options_hash{time} = "N" unless exists $options_hash{time};

      # If it's a DateTime object, handle it gracefully
    if( ref $options_hash{time} eq "DateTime" ) {
        $options_hash{time} = $options_hash{time}->epoch();
    }

    my $update_string  = "$options_hash{time}:";
    my @update_options = ();

    if(exists $options_hash{values}) {
        if(ref($options_hash{values}) eq "HASH") {
                # Do the template magic
            push @update_options, "--template", 
                 join(":", keys %{$options_hash{values}});
            $update_string .= join ":", values %{$options_hash{values}};
        } else {
                # We got multiple values in correct order
            $update_string .= join ":", @{$options_hash{values}};
        }
    } else {
            # We just have a single value
        $update_string .= $options_hash{value};
    }

    my $caller = (caller(1))[3] ? (caller(1))[3] : '';
    my $updatecmd = $caller eq __PACKAGE__."::updatev" ? 'updatev' : 'update';
    my ($print_results) = 
        $self->RRDs_execute($updatecmd, $self->{file},
                            @update_options, $update_string);

    if(!defined $print_results) {
        return undef;
    }

    $self->print_results( $print_results );

    return 1;
}

#################################################
sub updatev {
#################################################
    &update (@_);
}

#################################################
sub fetch_start {
#################################################
    my($self, @options) = @_;

    $self->check_options("fetch_start", \@options);

    my %options_hash = @options;

    if(!exists $options_hash{cfunc}) {
        my $cfuncs = $self->meta_data("cfuncs");
        LOGDIE "No default archive cfunc" unless 
            defined $cfuncs->[0];
        $options_hash{cfunc} = $cfuncs->[0];
        DEBUG "Getting default cfunc '$options_hash{cfunc}'";
    }

    my $cfunc = $options_hash{cfunc};
    delete $options_hash{cfunc};

    @options = add_dashes(\%options_hash);

    INFO "rrdtool fetch $self->{file} $cfunc @options";

    ($self->{fetch_time_current}, 
     $self->{fetch_time_step},
     $self->{fetch_ds_names},
     $self->{fetch_data}) =
         $self->RRDs_execute("fetch", $self->{file}, $cfunc, @options);

    $self->{fetch_idx} = 0;
}

#################################################
sub fetch_next {
#################################################
    my($self) = @_;

    if(!defined $self->{fetch_data}->[$self->{fetch_idx}]) {
        INFO "Idx $self->{fetch_idx} returned undef";
        return ();
    }

    my @values = @{$self->{fetch_data}->[$self->{fetch_idx}++]};

        # Put the time of the data point in front
    unshift @values, $self->{fetch_time_current};

    INFO "rrdtool fetch $self->{file} ", array_as_string(\@values) if @values;

    $self->{fetch_time_current} += $self->{fetch_time_step};

    return @values;
}

#################################################
sub array_as_string {
#################################################
    my($arrayref) = @_;

    return join "-", map { defined $_ ? $_ : '[undef]' } @$arrayref;
}

#################################################
sub fetch_skip_undef {
#################################################
    my($self) = @_;

    {
        if(!defined $self->{fetch_data}->[$self->{fetch_idx}]) {
            return undef;
        }
   
        my $value = $self->{fetch_data}->[$self->{fetch_idx}]->[0];

        unless(defined $value) {
            $self->{fetch_idx}++;
            $self->{fetch_time_current} += $self->{fetch_time_step};
            redo;
        }
    }
}

#################################################
sub add_dashes {
#################################################
    my($options_hashref, $assign_hashref) = @_;

    $assign_hashref = {} unless $assign_hashref;

    my @options = ();

    foreach(keys %$options_hashref) {
        (my $newname = $_) =~ s/_/-/g;
        if($assign_hashref->{$_}) {
            push @options, "--$newname=$options_hashref->{$_}";
        } elsif(defined $options_hashref->{$_}) {
            push @options, "--$newname", $options_hashref->{$_};
        } else {
            push @options, "--$newname";
        }
    }
   
    return @options;
}

#################################################
sub error_message {
#################################################
    my($self) = @_;

    return RRDs::error();
}

#################################################
sub graph {
#################################################
    my($self, @params) = @_;

    my @options = @{ Storable::dclone( \@params ) };

    my @trailing_options = ();

    $self->check_options("graph", \@options);
    $self->print_results( [] );

    my @colors = ();
    my @prints = ();
    my @vrules = ();
    my @hrules = ();
    my @fonts  = ();

    my @items = ();
    my $nof_draws = 0;
    my @draws = ();

    my %options_hash = @options;
    my $draw_count   = 1;

    my $image = delete $options_hash{image};
    delete $options_hash{draw};

    for(my $i=0; $i < @options; $i += 2) {
        if($options[$i] eq "draw") {
            push @items, ['draw', $options[$i+1]];
            push @draws, $options[$i+1];
            $nof_draws++;
        } elsif($options[$i] eq "color") {
            $self->check_options("graph/color", [%{$options[$i+1]}]);
            for(keys %{$options[$i+1]}) {
                push @colors, "--color", 
                              uc($_) . "$options[$i+1]->{$_}";
            }
        } elsif($options[$i] eq "print") {
            $self->check_options("graph/print", [%{$options[$i+1]}]);
            push @items, ['print', [$options[$i], $options[$i+1]]];
        } elsif($options[$i] eq "gprint") {
            $self->check_options("graph/gprint", [%{$options[$i+1]}]);
            push @items, ['print', [$options[$i], $options[$i+1]]];
        } elsif($options[$i] eq "comment") {
            push @items, ['print', option_expand(@options[$i, $i+1])];
        } elsif($options[$i] eq "line") {
            $self->check_options("graph/line", [%{$options[$i+1]}]);
            push @items, ['print', option_expand(@options[$i, $i+1])];
        } elsif($options[$i] eq "area") {
            $self->check_options("graph/area", [%{$options[$i+1]}]);
            push @items, ['print', option_expand(@options[$i, $i+1])];
        } elsif($options[$i] eq "vrule") {
            $self->check_options("graph/vrule", [%{$options[$i+1]}]);
            push @items, ['vrule', [$options[$i], $options[$i+1]]];
        } elsif($options[$i] eq "hrule") {
            $self->check_options("graph/hrule", [%{$options[$i+1]}]);
            push @items, ['hrule', [$options[$i], $options[$i+1]]];
        } elsif($options[$i] eq "tick") {
            $self->check_options("graph/tick", [%{$options[$i+1]}]);
            push @items, ['print', option_expand(@options[$i, $i+1])];
        } elsif($options[$i] eq "shift") {
            $self->check_options("graph/shift", [%{$options[$i+1]}]);
            push @items, ['print', option_expand(@options[$i, $i+1])];
        } elsif($options[$i] eq "font") {
            push @fonts,$options[$i+1];
        }
    }

    delete $options_hash{color};
    delete $options_hash{vrule};
    delete $options_hash{hrule};
    delete $options_hash{'print'};
    delete $options_hash{gprint};
    delete $options_hash{comment};
    delete $options_hash{font};
    delete $options_hash{line};
    delete $options_hash{area};
    delete $options_hash{tick};
    delete $options_hash{'shift'};

      # If it's a DateTime object, handle it gracefully
    for my $o (qw(start end)) {
        if( ref $options_hash{$o} eq "DateTime" ) {
            $options_hash{$o} = $options_hash{$o}->epoch();
        }
    }

    @options = add_dashes(\%options_hash);

    # Set dsname default
    if(!exists $options_hash{dsname}) {
        my $dsname = $self->default("dsname");
        LOGDIE "No default archive dsname" unless defined $dsname;
        $options_hash{dsname} = $dsname;
        DEBUG "Getting default dsname '$dsname'";
    }

    # Set cfunc default
    if(!exists $options_hash{cfunc}) {
        my $cfunc = $self->default("cfunc");
        LOGDIE "No default archive cfunc" unless defined $cfunc;
        $options_hash{cfunc} = $cfunc;
        DEBUG "Getting default cfunc '$cfunc'";
    }

        # Push a pseudo draw if there's none.
    unshift @items, ['draw', {}] unless $nof_draws;

    for(@fonts) {

        $self->check_options("graph/font", [%$_]);

        $_->{size}     ||= 8;
        $_->{element}  ||= 'default';
        $_->{name}     ||= '';       # but this breaks. 
                                     # Need to issue an error eventually.

        push @options,"--font", uc($_->{element}) . ":" .
                                $_->{size} . ":" . $_->{name};
    }

    for my $item (@items) {
        if($item->[0] eq 'draw') {
            $self->process_draw($item->[1], \@options, 
                                \%options_hash, $draw_count);
            $draw_count++;
        } elsif($item->[0] eq 'vrule') {
            $self->process_vrule($item->[1], \@options);
        } elsif($item->[0] eq 'hrule') {
            $self->process_hrule($item->[1], \@options);
        } elsif($item->[0] eq 'print') {
            for(@$item[1..$#$item]) {
                $self->process_print($_, \@options, \@draws);
            }
        }
    }

    push @options, @colors;
    unshift @options, $image;

    my $caller = (caller(1))[3] ? (caller(1))[3] : '';
    my $graphcmd = $caller eq __PACKAGE__."::graphv" ? 'graphv' : 'graph';
    my($print_results, $img_width, $img_height) = 
        $self->RRDs_execute($graphcmd, @options);

    if(!defined $print_results) {
        return undef;
    }

    $self->print_results( $print_results );

    return 1;
}

#################################################
sub graphv {
#################################################
    &graph (@_);
}

###########################################
sub print_results {
###########################################
    my($self, $results) = @_;

    if(defined $results) {
        $self->{results} = $results;
    }

    return $self->{results};
}

#################################################
sub option_expand {
#################################################
    my($oname, $ovalue) = @_;

    # If $ovalue is an array ref, return ($oname, $element)
    # for each of the elements in @$ovalue.
    my @result;

    if ( ref($ovalue) eq 'ARRAY' ) {
        push @result, [$oname, $_] foreach @$ovalue;
    } else {
        push @result, [$oname, $ovalue];
    }

    return @result;
}

#################################################
sub dump {
#################################################
    my($self, @options) = @_;

    $self->RRDs_execute("dump", $self->{file}, @options);
}

#################################################
sub restore {
#################################################
    my($self, @options) = @_;

        # Called with only the xml file
    if(@options == 1) {
        @options = (xml => $options[0]);
    }

    my %options_hash = @options;
    my $xml = delete $options_hash{xml};

    @options = add_dashes(\%options_hash);

    $self->RRDs_execute("restore", $xml, $self->{file}, 
                        @options);
}

#################################################
sub tune {
#################################################
    my($self, @options) = @_;

    my %options_hash = @options;

    my $dsname = first_def $options_hash{dsname}, $self->default("dsname");
    delete $options_hash{dsname};

    @options = ();

    my %map = qw( type data-source-type
                  name data-source-rename
                );

    for my $param (qw(heartbeat minimum maximum type name)) {
        if(exists $options_hash{$param}) {
            my $newparam = $param;
    
            $newparam = $map{$param} if exists $map{$param};
    
            push @options, "--$newparam", 
                 "$dsname:$options_hash{$param}";
        }
    }

    my $rc = $self->RRDs_execute("tune", $self->{file}, @options);

    # This might impact the default dsname, rediscover
    $self->meta_data_discover();

    return $rc;
}

#################################################
sub default {
#################################################
    my($self, $param) = @_;

    if($param eq "cfunc") {
        my $cfuncs = $self->meta_data("cfuncs");
        return undef unless $cfuncs;
            # Return the first of all defined consolidation functions
        return $cfuncs->[0];
    }

    if($param eq "dsname") {
        my $dsnames = $self->meta_data("dsnames");
        return undef unless $dsnames;
            # Return the first of all defined data sources
        return $dsnames->[0];
    }

    return undef;
}

#################################################
sub meta_data {
#################################################
    my($self, $field, $value, $unique_push) = @_;

    if(defined $value) {
        $self->{meta}->{discovered} = 1;
    }

    if(!$self->{meta}->{discovered}) {
        $self->meta_data_discover();
    }

    if(defined $value) {
        if($unique_push) {
            push @{$self->{meta}->{$field}}, $value unless 
                   $self->{meta}->{"${field}_hash"}->{$value}++;
        } else {
            $self->{meta}->{$field} = $value;
        }
    }

    return $self->{meta}->{$field};
}

#################################################
sub meta_data_discover {
#################################################
    my($self) = @_;

    #==========================================
    # rrdtoo info output
    #==========================================
    #filename = "myrrdfile.rrd"
    #rrd_version = "0001"
    #step = 1
    #last_update = 1084773097
    #ds[mydatasource].type = "GAUGE"
    #ds[mydatasource].minimal_heartbeat = 2
    #ds[mydatasource].min = NaN
    #ds[mydatasource].max = NaN
    #ds[mydatasource].last_ds = "UNKN"
    #ds[mydatasource].value = 0.0000000000e+00
    #ds[mydatasource].unknown_sec = 0
    #rra[0].cf = "MAX"
    #rra[0].rows = 5
    #rra[0].pdp_per_row = 1
    #rra[0].xff = 5.0000000000e-01
    #rra[0].cdp_prep[0].value = NaN
    #rra[0].cdp_prep[0].unknown_datapoints = 0

        # Nuke everything
    delete $self->{meta};

    my $hashref = $self->RRDs_execute("info", $self->{file});

    foreach my $key (keys %$hashref){

        if($key =~ /^rra\[\d+\]\.cf/) {
            DEBUG "rrdinfo: rra found: $key";
            $self->meta_data("cfuncs", $hashref->{$key}, 1);
            next;
        } elsif ($key =~ /^ds\[(.*?)]\./) {
            DEBUG "rrdinfo: da found: $key";
            $self->meta_data("dsnames", $1, 1);
            next;
        } else {
            DEBUG "rrdinfo: no match: $key";
        }
    }

    DEBUG "Discovery: cfuncs=(@{$self->{meta}->{cfuncs}}) ",
                    "dsnames=(@{$self->{meta}->{dsnames}})";

    $self->{meta}->{discovered} = 1;
}

#################################################
sub info_aux {
#################################################
    my($self) = @_;

    return $self->RRDs_execute("info", $self->{file});
}

#################################################
sub info {
#################################################
    my($self) = @_;

    my $hashref = $self->info_aux();

        # Returns something like
          # {'rra[0].rows' => 5,
          # 'rra[1].pdp_per_row' => 5,
          # 'last_update' => 1080462600,
          # 'rra[0].cf' => 'MAX',
          # 'step' => 60,
          # 'rra[1].cdp_prep[0].value' => undef,
          # 'rra[0].cdp_prep[0].unknown_datapoints' => 0,
          # ...
          # }
        # Parse it into a Perl array/hash hierarchy:

    my $h = {};

    for my $key (keys %$hashref) {

        my $ptr = \$h;

        while($key =~ /\G(?:\.?(\w+)|\[(\d+)\]|\[(.*?)\])/g) {
            $ptr = $1         ? \$$ptr->{$1} : 
                   defined $2 ? \$$ptr->[$2] : 
                                \$$ptr->{$3};
        }

        $$ptr = $hashref->{$key};
    }

    return $h;
}

#################################################
sub first {
#################################################
    my($self) = @_;

    $self->RRDs_execute("first", $self->{file});
}

#################################################
sub last {
#################################################
    my($self) = @_;

    $self->RRDs_execute("last", $self->{file});
}

###########################################
sub process_draw {
###########################################
    my($self, $p, $options, $options_hash, $draw_count) = @_;

    $self->check_options("graph/draw", [%$p]);

        $p->{thickness} ||= 1;        # LINE1 is default
        $p->{color}     ||= 'FF0000'; # red is default
        $p->{legend}    ||= '';       # no legend by default

        $p->{file}   = first_def $p->{file}, $self->{file};

        my($dsname, $cfunc);

        if($p->{file} ne $self->{file}) {
            my $rrd = __PACKAGE__->new(file => $p->{file});
            $dsname = $rrd->default('dsname');
            $cfunc  = $rrd->default('cfunc');
        }

        unless(defined $p->{name}) {
            $p->{name} = "draw$draw_count";
        }

            # Is it just a CDEF, a different view of a another draw?
        if($p->{cdef}) {
            push @$options, "CDEF:$p->{name}=$p->{cdef}";
        } elsif($p->{vdef}) {
            push @$options, "VDEF:$p->{name}=$p->{vdef}";
        } else {
                # Use either directly defined, default for a given file or
                # default for default file, in this order.
            $p->{dsname} = first_def $p->{dsname}, $dsname, 
                                     $options_hash->{dsname};
            $p->{cfunc}  = first_def $p->{cfunc}, $cfunc, 
                                     $options_hash->{cfunc};

            # Create the draw strings
            # DEF:vname=rrdfile:ds-name:CF[:step=step][:start=time][:end=time]
            my $def = "DEF:$p->{name}=$p->{file}:$p->{dsname}:$p->{cfunc}";
            map { $def .= ":$_=$p->{$_}" } grep { defined $p->{$_} } qw(step start end);
            push @$options, $def;
        }

            #LINE2:myload#FF0000
        $p->{type} ||= 'line';

        my $draw_attributes = ":$p->{name}#$p->{color}";

        if( length $p->{legend} ) {
            $draw_attributes .= ":$p->{legend}";
        } elsif( exists $p->{stack} ) {
            $draw_attributes .= ":";
        }

        $draw_attributes .= ":STACK" if exists $p->{stack};

        if($p->{type} eq "hidden") {
            # Invisible graph
        } elsif($p->{type} eq "line") {
            push @$options, "LINE$p->{thickness}$draw_attributes";
        } elsif($p->{type} eq "area") {
            push @$options, "AREA$draw_attributes";
        } elsif($p->{type} eq "stack") {
            if( ! length $p->{legend} ) {
                $draw_attributes .= ":";
            }
              # modified for backwards compatibility
            push @$options, "AREA$draw_attributes:STACK";
        } else {
            die "Invalid graph type: $p->{type}";
        }
}

###########################################
sub process_vrule {
###########################################
    my($self, $vrule, $options) = @_;

    # Push vrules
    $vrule->[1]->{color} ||= "#000000";
    push @$options, uc($vrule->[0]) . ":" .
                    $vrule->[1]->{time} .
                    $vrule->[1]->{color} .
                    ( $vrule->[1]->{legend} ?  
                         ":" . $vrule->[1]->{legend} : "");
}

###########################################
sub process_hrule {
###########################################
    my($self, $hrule, $options) = @_;

    # Push hrules
    $hrule->[1]->{color} ||= "#000000";
    push @$options, uc($hrule->[0]) . ":" .
                    $hrule->[1]->{value} .
                    $hrule->[1]->{color} .
                    ( $hrule->[1]->{legend} ?  
                         ":" . $hrule->[1]->{legend} : "");
}

###########################################
sub process_print {
###########################################
    my($self, $p, $options, $draws) = @_;

    if ( $p->[0] eq 'comment' ) {
        push @$options, uc($p->[0]) . ":" . $p->[1];

    } elsif( $p->[0] =~ /^(line)|(area)$/ ) {
        push @$options, uc($p->[0]) . 
                       ($p->[1]->{width} || "") .
                       ":" .
                       $p->[1]->{value} .
                       ($p->[1]->{color} || "") .
                       ($p->[1]->{legend} ? ":$p->[1]->{legend}" : "") .
                       ($p->[1]->{stack} ? ":STACK" : "");
        
    } elsif( $p->[0] eq "tick" ) {
        push @$options, uc($p->[0]) . ":" .
                   ($p->[1]->{draw} || $draws->[0]->{name}) .
                   ($p->[1]->{color} || '#ff0000') .
                   ($p->[1]->{fraction} ? ":$p->[1]->{fraction}" : ":.1") .
                   ($p->[1]->{legend} ? ":$p->[1]->{legend}" : "");
        
    } elsif( $p->[0] eq "shift" ) {
        push @$options, uc($p->[0]) . ":" .
                       ($p->[1]->{draw} || $draws->[0]->{name}) .
                       ":$p->[1]->{offset}";
        
    } else {
        $p->[1]->{draw}   ||= $draws->[0]->{name};
        $p->[1]->{format} ||= "Average=%lf";
        push @$options, uc($p->[0]) . ":" .
                       $p->[1]->{draw} . ":" .
                       ($p->[1]->{cfunc} ? "$p->[1]->{cfunc}:" : "") .
                       $p->[1]->{format};
    }
}

#################################################
sub xport {
#################################################
	my ($this, @options) = @_;

	my $sname = "xport";
	my $section = $OPTIONS->{$sname};

	DEBUG(sub { Dumper($OPTIONS) });
	DEBUG(sub { Dumper($section) });

	$this->check_options($sname, \@options);
	$this->print_results([]);

	my %options = @options;
	my $ref;
	my @cmd;
	# If it's a DateTime object, handle it gracefully
	foreach (qw(start end)) {
		next unless exists($options{$_});
		next unless defined($options{$_});
		if (ref($options{$_}) eq "DateTime") {
			$options{$_} = $options{$_}->epoch();
		}
	}

	my @all_options = (@{$section->{optional}}, @{$section->{mandatory}});
	foreach my $opt (@all_options) {
		DEBUG("Processing optional option '$opt'");
		if (defined($options{$opt}) and not ref($options{$opt})) {
			push(@cmd, "--$opt", $options{$opt});
			DEBUG("[xport] Pushed option '--$opt' with value '$options{$opt}'");
		}
	}
	undef(@all_options);

	my %params = (
		def => [],
		cdef => [],
		xport => [],
	);

	my $string;
	foreach my $sec (keys(%params)) {
		next unless (defined($options{$sec}));
		LOGDIE("$sec section must be an array ref") unless (ref($options{$sec}) eq "ARRAY");
		foreach my $opts (@{$options{$sec}}) {
			LOGDIE("$sec/$opts section must be a hash ref") unless (ref($opts) eq "HASH");
			my @opts = %$opts;
			$this->check_options("$sname/$sec", \@opts);

			my $array = $params{$sec};

			# DEF
			if ($sec =~ /^def$/i) {
				$string = "DEF:";
				$string .= "$opts->{vname}=";
				$string .= "$opts->{file}:";
				$string .= "$opts->{dsname}:";
				$string .= $opts->{cfunc};
				push(@$array, $string);
				DEBUG("[xport] Pushed DEF '$string'");
			}
			# CDEF
			elsif ($sec =~ /^cdef$/i) {
				$string = "CDEF:";
				$string .= "$opts->{vname}=";
				$string .= $opts->{rpn};
				push(@$array, $string);
				DEBUG("[xport] Pushed CDEF '$string'");
			}
			# XPORT
			else {
				$string = "XPORT:";
				$string .= $opts->{vname};
				$string .= ":$opts->{legend}" if defined($opts->{legend});
				push(@$array, $string);
				DEBUG("[xport] Pushed XPORT '$string'");
			}
		}

	}

	# Order matters !
	foreach my $sec (qw(def cdef xport)) {
		push(@cmd, @{$params{$sec}}) if (defined($params{$sec}) and scalar @{$params{$sec}} != 0);
	}

	DEBUG("[xport] RRDs command: ".join(" ", @cmd));

	my @results = $this->RRDs_execute($sname, @cmd);
	LOGDIE("RRDs::xport() failed") unless (scalar @results > 0);

	my %meta_data = (
		start => $results[0], # Exactly start+step
		end => $results[1],
		step => $results[2],
		columns => $results[3],
		legend => $results[4],
	);

	my $time = $meta_data{start};

	my @data;
	foreach my $data (@{$results[5]}) {
		push(@data, [$time, @$data]);
		$time += $meta_data{step};
	}

	$meta_data{rows} = scalar @data;

    my $results = {
		meta => \%meta_data,
		data => \@data,
	};

    return $this->print_results($results);
}



##########################################
sub def_or($$) {
###########################################
    if(! defined $_[0]) {
        $_[0] = $_[1];
    }
}

1;

__END__

=head1 NAME

RRDTool::OO - Object-oriented interface to RRDTool

=head1 SYNOPSIS

    use RRDTool::OO;

        # Constructor     
    my $rrd = RRDTool::OO->new(
                 file => "myrrdfile.rrd" );

        # Create a round-robin database
    $rrd->create(
         step        => 1,  # one-second intervals
         data_source => { name      => "mydatasource",
                          type      => "GAUGE" },
         archive     => { rows      => 5 });

        # Update RRD with sample values, use current time.
    for(1..5) {
        $rrd->update($_);
        sleep(1);
    }

        # Start fetching values from one day back, 
        # but skip undefined ones first
    $rrd->fetch_start();
    $rrd->fetch_skip_undef();

        # Fetch stored values
    while(my($time, $value) = $rrd->fetch_next()) {
         print "$time: ", 
               defined $value ? $value : "[undef]", "\n";
    }

        # Draw a graph in a PNG image
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'My Salary',
      start          => time() - 10,
      draw           => {
          type   => "area",
          color  => '0000FF',
          legend => "Salary over Time",
      }
    );

        # Same using rrdtool's graphv
    $rrd->graphv(
      image          => "mygraph.png",
      [...]
    };

=head1 DESCRIPTION

=for html
<IMG SRC=/images/rrdtool/mygraph.png>

C<RRDTool::OO> is an object-oriented interface to Tobi Oetiker's 
round robin database tool I<rrdtool>. It uses I<rrdtool>'s 
C<RRDs> module to get access to I<rrdtool>'s shared library.

C<RRDTool::OO> tries to marry I<rrdtool>'s database engine with the
dwimminess and whipuptitude Perl programmers take for granted. Using
C<RRDTool::OO> abstracts away implementation details of the RRD engine,
uses easy to memorize named parameters and sets meaningful defaults 
for parameters not needed in simple cases.
For the experienced user, however, it provides full access to
I<rrdtool>'s API (if you find a feature that's not implemented, let
me know).

=head2 FUNCTIONS

=over 4

=item I<my $rrd = RRDTool::OO-E<gt>new( file =E<gt> $file )>

The constructor hooks up with an existing RRD database file C<$file>, 
but doesn't create a new one if none exists. That's what the C<create()>
methode is for. Returns a C<RRDTool::OO> object, which can be used to 
get access to the following methods.

=item I<$rrd-E<gt>create( ... )>

Creates a new round robin database (RRD). A RRD consists of one or more
data sources and one or more archives:

    $rrd->create(
         step        => 60,
         data_source => { name      => "mydatasource",
                          type      => "GAUGE" },
         archive     => { rows      => 5 });

This defines a RRD database with a step rate of 60 seconds in between
primary data points. Additionally, the RRD start time can be specified
by specifying a C<start> parameter.

It also sets up one data source named C<my_data_source>
of type C<GAUGE>, telling I<rrdtool> to use values of data samples 
as-is, without additional trickery.  

And it creates a single archive with a 1:1 mapping between primary data 
points and archive points, with a capacity to hold five data points.

The RRD's C<step> parameter is optional, and will be set to 300 seconds
by I<rrdtool> by default.

In addition to the mandatory settings for C<name> and C<type>,
C<data_source> parameter takes the following optional parameters:
C<min> (minimum input, defaults to C<U>),
C<max> (maximum input, defaults to C<U>), 
C<heartbeat> (defaults to twice the RRD's step rate).

Archives expect at least one parameter, C<rows> indicating the number
of data points the archive is configured to hold. If nothing else is
set, I<rrdtool> will store primary data points 1:1 in the archive.

If you want
to combine several primary data points into one archive point, specify
values for 
C<cpoints> (the number of points to combine) and C<cfunc> 
(the consolidation function) explicitly:

    $rrd->create(
         step        => 60,
         data_source => { name      => "mydatasource",
                          type      => "GAUGE" },
         archive     => { rows      => 5,
                          cpoints   => 10,
                          cfunc     => 'AVERAGE',
                        });

This will collect 10 data points to form one archive point, using
the calculated average, as indicated by the parameter C<cfunc>
(Consolidation Function, CF). Other options for C<cfunc> are 
C<MIN>, C<MAX>, and C<LAST>.

If you're defining multiple data sources or multiple archives, just
provide them in this manner:

       # Define the RRD
    my $rc = $rrd->create(
        step        => 60,
        data_source => { name      => 'load1',
                         type      => 'GAUGE',
                       },
        data_source => { name      => 'load2',
                         type      => 'GAUGE',
                       },
        archive     => { rows      => 5,
                         cpoints   => 10,
                         cfunc     => 'AVERAGE',
                        },
        archive     => { rows      => 5,
                         cpoints   => 10,
                         cfunc     => 'MAX',
                        },
    );

=item I<$rrd-E<gt>update( ... ) >

Update the round robin database with a new data sample, 
consisting of a value and an optional time stamp.
If called with a single parameter, like in

    $rrd->update($value);

then the current timestamp and the defined C<$value> will be used. 
If C<update> is called with a named parameter list like in

    $rrd->update(time => $time, value => $value);

then the given timestamp C<$time> is used along with the given value 
C<$value>.

When updating multiple data sources, use the C<values> parameter
(instead of C<value>) and pass an arrayref:

    $rrd->update(time => $time, values => [$val1, $val2, ...]);

This way, I<rrdtool> expects you to pass in the data values in 
exactly the same order as the data sources were defined in the
C<create> method. If that's not the case,
then the C<values> parameter also accepts a hashref, mapping data source
names to values:

    $rrd->update(time => $time, 
                 values => { $dsname1 => $val1, 
                             $dsname2 => $val2, ...});

C<RRDTool::OO> will transform this automagically
into C<RRDTool's> I<template> syntax.

=item I<$rrd-E<gt>updatev( ... )>

This is identical to C<update>, but uses rrdtool's updatev function internally.
The only difference is when using the C<print_results> method described 
below, which then contains additional information.

=item I<$rrd-E<gt>fetch_start( ... )>

Initializes the iterator to fetch data from the RRD. This works nicely without
any parameters if
your archives are using a single consolidation function (e.g. C<MAX>).
If there's several archives in the RRD using different consolidation
functions, you have to specify which one you want:

    $rrd->fetch_start(cfunc => "MAX");

Other options for C<cfunc> are C<MIN>, C<AVERAGE>, and C<LAST>.

C<fetch_start> features a number of optional parameters: 
C<start>, C<end> and C<resolution>.

If the C<start>
time parameter is omitted, the fetch starts 24 hours before the end of the 
archive. Also, an C<end> time can be specified:

    $rrd->fetch_start(start => time()-10*60,
                      end   => time());

The third optional parameter,
C<resolution> defaults to the highest resolution available and can
be set to a value in seconds, specifying the time interval between
the data samples extracted from the RRD.
See the C<rrdtool fetch> manual page for details.

Development note: The current implementation
fetches I<all> values from the RRA in one swoop 
and caches them in memory. This might 
change in the future, to cache only the last timestamp and keep fetching
from the RRD with every C<fetch_next()> call.

=item I<$rrd-E<gt>fetch_skip_undef()>

I<rrdtool> doesn't remember the time the first data sample went into the
archive. So if you run a I<rrdtool fetch> with a start time of 24 hours
ago and you've only submitted a couple of samples to the archive, you'll
see many C<undef> values.

Starting from the current iterator position (or at the specified C<start>
time immediately after a C<fetch_start()>), C<fetch_skip_undef()>
will skip all C<undef> values in the RRA and
positions the iterator right before the first defined value.
If all values in the RRA are undefined, the
a following C<$rrd-E<gt>fetch_next()> will return C<undef>.

=item I<($time, $value, ...) = $rrd-E<gt>fetch_next()>

Gets the next row from the RRD iterator, initialized by a previous call
to C<$rrd-E<gt>fetch_start()>. Returns the time of the archive point
along with all values as a list.

Note that there might be more than one value coming back from C<fetch_next>
if the RRA defines more than one datasource):

    I<($time, @values_of_all_ds) = $rrd-E<gt>fetch_next()>

It is not possible to fetch only a specific datasource, as rrdtool 
doesn't provide this.

=item I<($time, $value, ...) = $rrd-E<gt>fetch_next()>

=item I<$rrd-E<gt>graph( ... )>

If there's only one data source in the RRD, drawing a nice graph in
an image file on disk is as easy as

    $rrd->graph(
      image          => $image_file_name,
      vertical_label => 'My Salary',
      draw           => { thickness => 2,
                          color     => 'FF0000',
                          legend    => 'Salary over Time',
                        },
    );

This will assume a start time of 24 hours before now and an
end time of now. Specify C<start> and C<end> explicitly to
be clear:

    $rrd->graph(
      image          => $image_file_name,
      vertical_label => 'My Salary',
      start          => time() - 24*3600,
      end            => time(),
      draw           => { thickness => 2,
                          color     => 'FF0000',
                          legend    => 'Salary over Time',
                        },
    );

As always, C<RRDTool::OO> will pick reasonable defaults for parameters
not specified. The values for data source and consolidation function
default to the first values it finds in the RRD.
If there are multiple datasources in the RRD or multiple archives
with different values for C<cfunc>, just specify explicitly which
one to draw:

    $rrd->graph(
      image          => $image_file_name,
      vertical_label => 'My Salary',
      draw           => {
        thickness => 2,
        color     => 'FF0000',
        dsname    => "load",
        cfunc     => 'MAX'},
    );

If C<draw> doesn't define a C<type>, it defaults to C<"line">. If
you don't want to define a type (because the graph shouldn't be drawn), 
use C<type =E<gt> "hidden">. Other
values are C<"area"> for solid colored areas. The C<"stack"> type
(for graphical values stacked on top of each other)
has been deprecated sind rrdtool-1.2, but RRDTool::OO still supports it
by transforming it into an 'area' type with a 'stack' option.

And you can certainly have more than one graph in the picture:

    $rrd->graph(
      image          => $image_file_name,
      vertical_label => 'My Salary',
      draw           => {
        type      => 'area',
        color     => 'FF0000', # red area
        dsname    => "load",
        cfunc     => 'MAX'},
      draw        => {
        type      => 'area',
        stack     => 1,
        color     => '00FF00', # a green area stacked on top of the red one 
        dsname    => "load",
        cfunc     => 'AVERAGE'},
    );

Graphs may assemble data from different RRD files. Just specify
which file you want to draw the data from, using C<draw>:

    $rrd->graph(
      image          => $image_file_name,
      vertical_label => 'Network Traffic',
      draw           => {
        file      => "file1.rrd",
        legend    => "First Source",
      },
      draw        => {
        file      => "file2.rrd",
        type      => 'area',
        stack     => 1,
        color     => '00FF00', # a green area stacked on top of the red one 
        dsname    => "load",
        legend    => "Second Source",
        cfunc     => 'AVERAGE'
      },
    );

If a C<file> parameter is specified per C<draw>, the defaults for C<dsname>
and C<cfunc> are fetched from this file, not from the file that's attached
to the C<RRDTool::OO> object C<$rrd> used.

Graphs may also consist of algebraic calculations of previously defined 
graphs. In this case, graphs derived from real data sources need to be named,
so that subsequent C<cdef> definitions can refer to them and calculate
new graphs, based on the previously defined graph:

    $rrd->graph(
      image          => $image_file_name,
      vertical_label => 'Network Traffic',
      draw           => {
        type      => 'line',
        color     => 'FF0000', # red line
        dsname    => 'load',
        name      => 'firstgraph',
        legend    => 'Unmodified Load',
      },
      draw        => {
        type      => 'line',
        color     => '00FF00', # green line
        cdef      => "firstgraph,2,*",
        legend    => 'Load Doubled Up',
      },
    );

Note that the second C<draw> doesn't refer to a datasource C<dsname>
(nor does it fall back to the default data source), but 
defines a C<cdef>, performing calculations on a previously defined 
draw named C<firstgraph>. The calculation is specified using 
RRDTool's reverse polish notation, where instructions are separated by commas
(C<"firstgraph,2,*"> simply multiplies C<firstgraph>'s values by 2).

On a global level, in addition to the C<vertical_label> parameter shown
in the examples above, C<graph> offers a plethora of parameters:

C<vertical_label>, 
C<title>, 
C<start>, 
C<end>, 
C<x_grid>, 
C<y_grid>, 
C<alt_y_grid>, 
C<no_minor>, 
C<alt_y_mrtg>, 
C<alt_autoscale>, 
C<alt_autoscale_max>, 
C<base>, 
C<units_exponent>, 
C<units_length>, 
C<width>, 
C<height>, 
C<interlaced>, 
C<imginfo>, 
C<imgformat>, 
C<overlay>, 
C<unit>, 
C<lazy>, 
C<rigid>,
C<lower_limit>, 
C<upper_limit>, 
C<logarithmic>, 
C<color>, 
C<no_legend>, 
C<only_graph>, 
C<force_rules_legend>, 
C<title>, 
C<step>.

Some options (e.g. C<alt_y_grid>) don't expect values, they need to
be specified like

    alt_y_grid => undef

in order to be passed properly to RRDTool.

The C<color> option expects a reference to a hash with various settings
for the different graph areas:
C<back> (background), 
C<canvas>, 
C<shadea> (left/top border), 
C<shadeb> (right/bottom border), 
C<grid>, C<mgrid> major grid, 
C<font>, 
C<frame> and C<arrow>:

    $rrd->graph(
      ...
      color          => { back   => '#0e0e0e',
                          arrow  => '#ff0000',
                          canvas => '#eebbbb',
                        },
      ...
    );

Fonts for various graph elements may be specified in C<font> blocks,
which must either name a TrueType font file or a PDF/Postscript font name.
You may optionally specify a size and element name (defaults to DEFAULT,
which to RRD means "use this font for everything).  Example:

    font  => {
        name => "/usr/openwin/lib/X11/fonts/TrueType/GillSans.ttf",
        size => 16,
        element => "title"
    }

Please check the RRDTool documentation for a detailed description
on what each option is used for:

    http://people.ee.ethz.ch/~oetiker/webtools/rrdtool/manual/rrdgraph.html

Sometimes it's useful to print max, min or average values of
a given graph at the bottom of the chart or to STDOUT. That's what
C<gprint> and C<print> options are for. They are printing variables
which are defined as C<vdef>s somewhere else:

    $rrd->graph(
      image          => $image_file_name,
          # Real graph
      draw           => {
        name      => "first_draw",
        dsname    => "load",
        cfunc     => 'MAX'
      },

        # vdef for calculating average of real graph
      draw           => {
        type      => "hidden",
        name      => "average_of_first_draw",
        vdef      => "first_draw,AVERAGE"
      },

      gprint         => {
        draw      => 'average_of_first_draw',
        format    => 'Average=%lf',
      },
    );

The C<vdef> performs a calculation, specified in RPN notation, on 
a real graph, which it refers to. It uses a hidden graph for this.

The C<gprint> option then refers to the C<vdef> virtual graph and prints
"Average=x.xx" at the bottom of the graph, showing what the
average value of graph C<first_draw> is.

To write comments to the graph (like gprints, but with no associated
RRD data source) use C<comment>, like this:

    $rrd->graph(
      image          => $image_file_name,
      draw           => {
        name      => "first_draw",
        dsname    => "load",
        cfunc     => 'MAX'},
      comment        => "Remember, 83% of all statistics are made up",
    );

Multiple comment lines can be specified in a single comment specification
like this:

     comment => [ "All the king's horses and all the king's men\\n",
                  "couldn't put Humpty together again.\\n",
                ],

Vertical rules (lines) may be placed into the graph by using a C<vrule>
block like so:

       vrule => { time => time()-3600, }

These can be useful for indicating when the most recent day on the graph
started, for example.

vrules can have a color specification (they default to black) and also
an optional legend string specified:

      vrule => { time => $first_thing_today,
                 color => "#0000ff",
                 legend => "When we crossed midnight"
               },

hrules can have a color specification (they default to black) and also
an optional legend string specified:

      hrule => { value => $numeric_value,
                 color => "#0000ff",
                 legend => "a static line at your value"
               },

Horizontal rules can be added by using a C<line> block
like in

    line => { 
        value   => "fixed num value or draw name",
        color   => "#0000ff",
        legend  => "a blue horizontal line",
        width   => 120,
        stack   => 1,
    }

If instead of a horizontal line, a rectangular area is supposed to
be added to the graph, use an C<area> block:

    area => { 
        value   => "fixed num value or draw name",
        color   => "#0000ff",
        legend  => "a blue horizontal line",
        stack   => 1,
    }

The C<graph> method can also generate tickmarks (vertical lines)
for every defined value, using the C<tick> option:

    tick => {
        draw    => "drawname",
        color   => "#0000ff",
        legend  => "a blue horizontal line",
        stack   => 1,
    }

The graph may be shifted relative to the time axis:

    shift => {
        draw    => "drawname",
        offset  => $offset,
    }

=item I<$rrd-E<gt>graphv( ... )>

This is identical to C<graph>, but uses rrdtool's graphv function internally.
The only difference is when using the C<print_results> method described below, which
then contains additional information.
Be aware that rrdtool 1.3 is required for C<graphv> to work.

=item I<$rrd-E<gt>dump()>

I<Available as of rrdtool 1.0.49>.

Dumps the RRD in XML format to STDOUT. If you want to dump it into a file
instead, do this:

    my $pid;

    unless ($pid = open DUMP, "-|") {
      die "Can't fork: $!" unless defined $pid;
      $rrd->dump();
      exit 0;
    }

    waitpid($pid, 0);

    open OUT, ">out";
    print OUT $_ for <DUMP>;
    close OUT;

=item I<my $hashref = $rrd-E<gt>xport(...)>

Feed a perl structure with RRA data (Cf. rrdxport man page).

    my $results = $rrd->xport(
        start => $start_time,
        end => $end_time ,
        step => $step,
        def => [{
            vname => "load1_vname",
            file => "foo",
            dsname => "load1",
            cfunc => "MAX",
        },
        {
            vname => "load2_vname",
            file => "foo",
            dsname => "load2",
            cfunc => "MIN",
        }],

        cdef => [{
            vname => "load2_vname_multiply",
            rpn => "load2_vname,2,*",
        }],

        xport => [{
            vname => "load1_vname",
            legend => "it_s_gonna_be_legend_",
        },
        {
            vname => "load2_vname",
            legend => "wait_for_it",
        },
        {
            vname => "load2_vname_multiply",
            legend => "___dary",
        }],
    );

    my $data = $results->{data};
    my $metadata = $results->{meta};

    print "### METADATA ###\n";
    print "StartTime: $metadata->{start}\n";
    print "EndTime: $metadata->{end}\n";
    print "Step: $metadata->{step}\n";
    print "Number of data columns: $metadata->{columns}\n";
    print "Number of data rows: $metadata->{rows}\n";
    print "Legend: ", join(", ", @{$metadata->{legend}}), "\n";

    print "\n### DATA ###\n";
    foreach my $entry (@$data) {
        my $entry_timestamp = shift(@$entry);
        print "[$entry_timestamp] ", join(" ", @$entry), "\n";
    }

=item I<my $hashref = $rrd-E<gt>info()>

Grabs the RRD's meta data and returns it as a hashref, holding a
map of parameter names and their values.

=item I<my $time = $rrd-E<gt>first()>

Return the RRD's first update time.

=item I<my $time = $rrd-E<gt>last()>

Return the RRD's last update time.

=item I<$rrd-E<gt>restore(xml =E<gt> "file.xml")>

I<Available as of rrdtool 1.0.49>.

Restore a RRD from a C<dump>. The C<xml> parameter specifies the name
of the XML file containing the dump. If the optional flag C<range_check>
is set to a true value, C<restore> will make sure the values in the 
RRAs do not exceed the limits defined for the different datasources:

    $rrd->restore(xml => "file.xml", range_check => 1);

=item I<$rrd-E<gt>tune( ... )>

Alter a RRD's data source configuration values:

        # Set the heartbeat of the RRD's only datasource to 100
    $rrd->tune(heartbeat => 100);

        # Set the minimum of DS 'load' to 1
    $rrd->tune(dsname => 'load', minimum => 1);

        # Set the maximum of DS 'load' to 10
    $rrd->tune(dsname => 'load', maximum => 10);

        # Set the type of DS 'load' to AVERAGE
    $rrd->tune(dsname => 'load', type => 'AVERAGE');

        # Set the name of DS 'load' to 'load2'
    $rrd->tune(dsname => 'load', name => 'load2');

=item I<$rrd-E<gt>error_message()>

Return the message of the last error that occurred while interacting
with C<RRDTool::OO>.

=back

=head2 Aberrant behavior detection

RRDTool supports aberrant behavior detection (ABD), which takes a data
source, stuffs its values into a special RRA, smoothes the data stream,
tries to predict future values and triggers an alert if actual values
are way off the predicted values.

Using a fairly elaborate algorithm not only allows it to find out if
a data source produces a value that exceeds a certain fixed threshold. 
The algorithm constantly adapts its parameters to the input data and 
acts dynamically on slowly changing values.

The C<alpha> parameter specifies the baseline and
lies between 0 and 1. Values close to 1 specify 
that most recent values have the most weight on the prediction, whereas
values close to 0 indicate that past values carry higher weight.

On top of that, ABD can deal with data input that displays continuously
rising values (slope). The C<beta> parameters, again between 0 and 1,
specifies whether past values or more recent values carry the most
weight.

And, furthermore, it deals with seasonal cycles, so it won't freak out if 
there's a daily peak at noon. The C<gamma> parameter indicates this, if
you don't specify it, it defaults to the value of C<alpha>.

In the easiest case, an RRA with aberrant behavior detection can be
created like

        # Create a round-robin database
    $rrd->create(
         step        => 1,  # one-second intervals
         data_source => { name      => "mydatasource",
                          type      => "GAUGE" },
         hwpredict   => { rows => 3600,
                        },
    );

where C<alpha> and C<beta> default to 0.5, and the C<seasonal_period>
defaults to 1/5 of the rows number.

C<rows> is the number of primary data points that are stored in the RRA
before a wrap-around happens. Note that with ABD enabled, RRDTool won't 
consolidate the data from a data source before stuffing it into 
the HWPREDICT RRAs, as the whole point of ABD is to smooth unfiltered
data and predict future values.

A violation happens if a new measured value falls outside of the
prediction. If C<threshold> or more violations happen within
C<window_length>, an error is reported to the FAILURES RRA.
C<threshold> defaults to 7, C<window_length> to 9.

A more elaborate RRD could be defined as

        # Create a round-robin database
    $rrd->create(
         step        => 1,  # one-second intervals
         data_source => { name      => "mydatasource",
                          type      => "GAUGE" },
         hwpredict   => { rows          => 3600,
                          alpha         => 0.1,
                          beta          => 0.1,
                          gamma         => 0.1,
                          threshold     => 7,
                          window_length => 9,
                        },
    );

If you want to peek under the hood (not that you need to, just
for your entertainment), with the specification above, RRDTool::OO will 
create the following five RRAs according to the RRDtool
specification and fill in these values:

    * RRA:HWPREDICT:rows:alpha:beta:seasonal_period:rra-num
    * RRA:SEASONAL:seasonal period:gamma:rra-num
    * RRA:DEVSEASONAL:seasonal period:gamma:rra-num
    * RRA:DEVPREDICT:rows:rra-num
    * RRA:FAILURES:rows:threshold:window_length:rra-num

The C<rra-num> argument is an internal index referencing other
RRAs (for example, HWPREDICT references SEASONAL), but this will 
be taken care of automatically by RRDTool::OO with no user
interaction required whatsoever.

=head2 Development Status

The following methods are not yet implemented:

C<rrdresize>, C<xport>, C<rrdcgi>.

=head2 Print Output

The C<graph> method can be configured to have RRDTool's C<graph>
function to print data. Calling rrdtool on the command line, this
data ends up on STDOUT, but calling something like

    $rrd->graph(
      image          => "mygraph.png",
      start          => $start_time,

      # ...

      draw           => {
          type      => "hidden",
          name      => "in95precent",
          vdef      => "firstdraw,95,PERCENT"
      },

      print         => {
          draw      => 'in95percent',
          format    => "95 Percent Result = %3.2lf",
        },

      # ...

captures the print data internally. To get access to a reference to the array
containing the different pieces of data written in this way, call

    my $array_ref = $rrd->print_results();

If no print output is available, the array referenced by C<$array_ref>
is empty.

If the C<graphv> function is used instead of C<graph>, the return value of
print_results is a hashref containing the same information in the C<print> keys,
along with additional keys containing detailed information on the graph. See C<rrdtool>
documentation for more detail. Here is an example: 

    use Data::Dumper;

    $rrd -> graphv (
      image          => "-",
      start          => $start_time,

      # ...

    my $hash_ref = $rrd->print_results();

    print Dumper $hash_ref;
    $VAR1 = {
          'print[2]' => '1600.00',
          'value_min' => '200',
          'image_height' => 64,
          'graph_height' => 10,
          'print[1]' => '3010.18',
          'graph_end' => 1249391462,
          'print[3]' => '1600.00',
          'graph_left' => 51,
          'print[4]' => '2337.29',
          'print[0]' => '305.13',
          'value_max' => '10000',
          'graph_width' => 10,
          'image_width' => 91,
          'graph_top' => 22,
          'image' => '#PNG
                     [...lots of binary rubbish your terminal won't like...]
                     ',
          'graph_start' => 1217855462
        };

In this case, the option (image => "-") has been used to create the hash key
with the same name, the value of which actually contains the BLOB of the image itself.
This is useful when image needs to be passed to other modules (e.g. Image::Magick),
instead of writing it to disk.
Be aware that rrdtool 1.3 is required for C<graphv> to work.

=head2 Error Handling

By default, C<RRDTool::OO>'s methods will throw fatal errors (as in: 
they're calling C<die>) if the underlying C<RRDs::*> commands indicate
failure.

This behaviour can be overridden by calling the constructor with
the C<raise_error> flag set to false:

    my $rrd = RRDTool::OO->new(
        file        => "myrrdfile.rrd",
        raise_error => 0,
    );

In this mode, RRDTool's methods will just pass back values returned
from the underlying C<RRDs> functions if an error happens (usually
1 if successful and C<undef> if an error occurs).

=head2 Debugging

C<RRDTool::OO> is C<Log::Log4perl> enabled, so if you want to know 
what's going on under the hood, just turn it on:

    use Log::Log4perl qw(:easy);

    Log::Log4perl->easy_init({
        level    => $DEBUG
    }); 

If you're interested particularly in I<rrdtool> commands issued
by C<RRDTool::OO> while you're operating it, just enable the
category C<"rrdtool">:

    Log::Log4perl->easy_init({
        level    => $INFO, 
        category => 'rrdtool',
        layout   => '%m%n',
    }); 


This will display all C<rrdtool> commands that C<RRDTool::OO> submits
to the shared library. Let's turn it on for the code snippet in the
SYNOPSIS section of this manual page and watch the output:

    rrdtool create myrrdfile.rrd --step 1 \
            DS:mydatasource:GAUGE:2:U:U RRA:MAX:0.5:1:5
    rrdtool update myrrdfile.rrd N:1
    rrdtool update myrrdfile.rrd N:2
    rrdtool update myrrdfile.rrd N:3
    rrdtool fetch myrrdfile.rrd MAX

Often handy for cut-and-paste.

=head2 Allow New rrdtool Parameters

C<RRDTool::OO> tracks rrdtool's progress loosely, so it might happen
that at a given point in time, rrdtool introduces a new option that
C<RRDTool::OO> doesn't know about yet.

This might lead to problems, since default, C<RRDTool::OO> has its
C<strict> mode enabled, rejecting all unknown options. This mode is
usually helpful, because it catches typos (like C<"verical_label">),
but if you want to use a new rrdtool option, it's in the way.

To work around this problem until a new version of C<RRDTool::OO>
supports the new parameter, you can use

    $rrd->option_add("graph", "frobnication_level");

to add it to the optional parameter list of the C<graph> (or whatever)
rrd function. Note that some functions in C<RRDTool::OO> have 
sub-methods, which you can specify with the dash notation.
The C<graph> method with its various "graph/draw", "graph/color",
"graph/font" are notable examples.

And, as a band-aid, you can disable strict mode in these situation
by setting the C<strict> parameter to 0 in C<RRDTool::OO>'s
constructor call:

    my $rrd = RRDTool::OO->new(
        strict => 0,
        file   => "myrrdfile.rrd",
    ); 

Note that C<RRDTool::OO> follows the convention that parameters
names do not contain dashes, but underscores instead. So, you need
to say C<"vertical_label">, not C<"vertical-label">. The underlying
rrdtool layer, however, expects dashes, not underscores, which is why
C<RRDTool::OO> converts them automatically, e.g. transforming
C<"vertical_label"> to C<"--vertical-label"> before the 
underlying rrdtool call happens.

=head2 Dry Run Mode

If you want to use C<RRDTool::OO> to create RRD commands without
executing them directly, thanks to Jacquelin Charbonnel, there's the
I<dry run> mode. Here's how it works:

    my $rrd = RRDTool::OO->new(
        file => "myrrdfile.rrd",
        dry_run => 1
    );

With I<dry_run> set to a true value, you can run commands like

    $rrd->create(
          step        => 60,
          data_source => { name      => "mydatasource",
                           type      => "GAUGE" },
          archive     => { rows      => 5 });

but since I<dry_mode> is on, they won't be handed through to the
rrdtool layer anymore. Instead, RRDTool::OO allows you to retrieve
a reference to the RRDs function it was about to call including its
arguments:

    my ($subref, $args) = $rrd->get_exec_env();

You can now examine or modify the subroutine reference C<$subref> or
the arguments in the array reference C<$args>. Later, simply call

    $subref->(@$args);

to execute the RRDs function with the modified argument list later.
In this case, @$args would contain the following items:

    ("myrrdfile.rrd", "--step", "60", 
     "DS:mydatasource:GAUGE:120:U:U", "RRA:MAX:0.5:1:5")

If you're interested in the RRD function name to be executed, retrieve
the third parameter of C<get_exec_env>:

    my ($subref, $args, $funcname) = $rrd->get_exec_env();

=head1 INSTALLATION

C<RRDTool::OO> requires a I<rrdtool> installation with the
C<RRDs> Perl module, that comes with the C<rrdtool> distribution.

Download the tarball from

    http://oss.oetiker.ch/rrdtool/pub/rrdtool.tar.gz

and then unpack, compile and install:

    tar zxfv rrdtool.tar.gz
    cd rrdtool-1.2.26
    ./configure --enable-perl-site-install --prefix=/usr \
                --disable-tcl --disable-rrdcgi
    make
    make install

    cd bindings/perl-shared
    perl Makefile.PL
    ./configure
    make
    make test
    make install

=head1 SEE ALSO

=over 4

=item *

Tobi Oetiker's RRDTool homepage at 

    http://rrdtool.org

especially the manual page at 

        http://people.ee.ethz.ch/~oetiker/webtools/rrdtool/manual/index.html

=item *

My articles on rrdtool in
"Linux Magazine" (UK) and
"Linux Magazin" (Germany):

        (English)
    http://www.linux-magazine.com/issue/44/Perl_RDDtool.pdf
        (German)
    http://www.linux-magazin.de/Artikel/ausgabe/2004/06/perl/perl.html

=back

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2009 by Mike Schilli

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
