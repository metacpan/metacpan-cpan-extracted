package MooX::Options::Role;

use strictures 2;

## no critic (ProhibitExcessComplexity)

our $VERSION = "4.103";

=head1 NAME

MooX::Options::Role - role that is apply to your object

=head1 USAGE

Don't use MooX::Options::Role directly. It is used by L<MooX::Options> to upgrade your module. But it is useless alone.

=cut

use Carp qw/croak/;
use Module::Runtime qw(use_module);
use MooX::Options::Descriptive;
use Scalar::Util qw/blessed/;

### PRIVATE

sub _option_name {
    my ( $name, %data ) = @_;
    my $cmdline_name = join( '|', grep {defined} ( $name, $data{short} ) );
    ## no critic (RegularExpressions::RequireExtendedFormatting)
    $cmdline_name =~ m/[^\w]$/
        and croak
        "cmdline argument '$cmdline_name' should end with a word character";
    $cmdline_name .= '+' if $data{repeatable} && !defined $data{format};
    $cmdline_name .= '!' if $data{negativable};
    $cmdline_name .= '!' if $data{negatable};
    $cmdline_name .= '=' . $data{format} if defined $data{format};
    return $cmdline_name;
}

sub _options_prepare_descriptive {
    my ($options_data) = @_;

    my @options;
    my %all_options;
    my %has_to_split;

    my $data_record_loaded = 0;
    for my $name (
        sort {
            $options_data->{$a}{order}
                <=> $options_data->{$b}{order}    # sort by order
                or $a cmp $b                      # sort by attr name
        } keys %$options_data
        )
    {
        my %data = %{ $options_data->{$name} };
        my $doc  = $data{doc};
        $doc = "no doc for $name" if !defined $doc;
        my $option = {};
        $option->{hidden} = 1 if $data{hidden};

        push @options, [] if $data{spacer_before};
        push @options, [ _option_name( $name, %data ), $doc, $option ];
        push @options, [] if $data{spacer_after};

        push @{ $all_options{$name} }, $name;
        if ( $data{short} ) {
            ## no critic (RegularExpressions::RequireExtendedFormatting)
            my @shrt_list = split( m/\|/, $data{short} );
            foreach my $shrt (@shrt_list) {
                croak
                    "There is already an option '$shrt' - can't use it to shorten '$name'"
                    if exists $options_data->{$shrt};
                croak
                    "There is already an abbreviation '$shrt' - can't use it to shorten '$name'"
                    if defined $all_options{$shrt};
                push @{ $all_options{$shrt} }, $name;
            }
        }

        if ( defined $data{autosplit} ) {
            if ( !$data_record_loaded ) {
                use_module("Data::Record");
                use_module("Regexp::Common");
                Regexp::Common->import;
                $data_record_loaded = 1;
            }
            $has_to_split{$name} = Data::Record->new(
                {   split  => $data{autosplit},
                    unless => $Regexp::Common::RE{quoted}
                }
            );
        }
    }

    # singleton algorithm taken from List::MoreUtils
    my $k;
    my %abbrev_dd;
    ## no critic (BuiltinFunctions::ProhibitComplexMappings)
    foreach my $combo (
        grep { 1 == $abbrev_dd{ $k = $_->[1] } }
        grep { not $abbrev_dd{ $k = $_->[1] }++ }
        map {
            my $fa = $_;
            map { [ $fa => substr $fa, 0, $_ ] } 1 .. length($fa)
        } keys %all_options
        )
    {
        my ( $name, $long_short ) = @{$combo};
        $all_options{$name}->[0] eq $name
            or next;    # don't generate abbreviations for short
        defined $all_options{$long_short} and next;
        push @{ $all_options{$long_short} }, $name;
    }

    return \@options, \%has_to_split, \%all_options;
}

sub _options_fix_argv {
    my ( $option_data, $has_to_split, $all_options ) = @_;

    my @new_argv;

    #parse all argv
    while ( defined( my $arg = shift @ARGV ) ) {
        if ( $arg eq '--' ) {
            push @new_argv, $arg, @ARGV;
            last;
        }
        if ( index( $arg, '-' ) != 0 ) {
            push @new_argv, $arg;
            next;
        }

        my ( $arg_name_with_dash, $arg_values ) = split( /=/x, $arg, 2 );
        if ( index( $arg_name_with_dash, '--' ) < 0 && !defined $arg_values )
        {
            $arg_values
                = length($arg_name_with_dash) > 2
                ? substr( $arg_name_with_dash, 2 )
                : undef;
            $arg_name_with_dash = substr( $arg_name_with_dash, 0, 2 );
        }
        unshift @ARGV, $arg_values if defined $arg_values;

        my ( $dash, $negative, $arg_name_without_dash )
            = $arg_name_with_dash =~ /^(\-+)(no\-)?(.*)$/x;
        $arg_name_without_dash =~ s/\-/_/gx;

        my $original_long_option = $all_options->{$arg_name_without_dash};
        if ( defined $original_long_option ) {
            ## no critic (ErrorHandling::RequireCarping)
            # uncoverable branch false
            @$original_long_option == 1
                or die
                "Internal error, duplicate map for abbreviation detected for '$arg_name_without_dash'!";
            $original_long_option = $original_long_option->[0];
        }

        my $arg_name = $dash;

        if ( defined $negative && defined $original_long_option ) {
            $arg_name .=
                $option_data->{$original_long_option}{negatable}
                ? 'no-'
                : 'no_';
        }

        $arg_name .= $arg_name_without_dash;

        if ( defined $original_long_option
            && ( defined( my $arg_value = shift @ARGV ) ) )
        {
            my $autorange = $option_data->{$original_long_option}{autorange};
            my $argv_processor = sub {

                #remove the quoted if exist to chain
                $_[0] =~ s/^['"]|['"]$//gx;
                if ($autorange) {
                    push @new_argv,
                        map { $arg_name => $_ } _expand_autorange( $_[0] );
                }
                else {
                    push @new_argv, $arg_name, $_[0];
                }

            };

            if ( my $rec = $has_to_split->{$original_long_option} ) {
                foreach my $record ( $rec->records($arg_value) ) {
                    $argv_processor->($record);
                }
            }
            else {
                $argv_processor->($arg_value);
            }
        }
        else {
            push @new_argv, $arg_name;
        }
    }

    return @new_argv;
}

sub _expand_autorange {
    my ($arg_value) = @_;

    my @expanded_arg_value;
    my ( $left_figure, $autorange_found, $right_figure )
        = $arg_value =~ /^(\d*)(\.\.)(\d*)$/x;
    if ($autorange_found) {
        $left_figure  = $right_figure unless length($left_figure);
        $right_figure = $left_figure  unless length($right_figure);
        if ( length $left_figure && length $right_figure ) {
            push @expanded_arg_value, $left_figure .. $right_figure;
        }
    }
    return @expanded_arg_value ? @expanded_arg_value : $arg_value;
}

### PRIVATE

use Moo::Role;
with "MooX::Locale::Passthrough";

requires qw/_options_data _options_config/;

=head1 METHODS

These methods will be composed into your class

=head2 new_with_options

Same as new but parse ARGV with L<Getopt::Long::Descriptive>

Check full doc L<MooX::Options> for more details.

=cut

sub new_with_options {
    my ( $class, %params ) = @_;

    #save subcommand

    if ( ref( my $command_chain = $params{command_chain} ) eq 'ARRAY' ) {
        $class->can('around')->(
            _options_prog_name => sub {
                my $prog_name = Getopt::Long::Descriptive::prog_name;
                for my $cmd (@$command_chain) {
                    next if !blessed $cmd || !$cmd->can('command_name');
                    if ( defined( my $cmd_name = $cmd->command_name ) ) {
                        $prog_name .= ' ' . $cmd_name;
                    }
                }

                return $prog_name;
            }
        );
    }

    if ( ref( my $command_commands = $params{command_commands} ) eq 'HASH' ) {
        $class->can('around')->(
            _options_sub_commands => sub {
                return [
                    ## no critic (BuiltinFunctions::RequireBlockMap)
                    map +{
                        name    => $_,
                        command => $command_commands->{$_},
                    },
                    sort keys %$command_commands
                ];
            }
        );
    }

    my %cmdline_params = $class->parse_options(%params);

    if ( $cmdline_params{h} ) {
        return $class->options_usage( $params{h}, $cmdline_params{h} );
    }
    if ( $cmdline_params{help} ) {
        return $class->options_help( $params{help}, $cmdline_params{help} );
    }
    if ( $cmdline_params{man} ) {
        return $class->options_man( $cmdline_params{man} );
    }
    if ( $cmdline_params{usage} ) {
        return $class->options_short_usage( $params{usage},
            $cmdline_params{usage} );
    }

    my $self;
    return $self
        if eval { $self = $class->new(%cmdline_params); 1 };
    if ( $@ =~ /^Attribute\s\((.*?)\)\sis\srequired/x ) {
        print STDERR "$1 is missing\n";
    }
    elsif ( $@ =~ /^Missing\srequired\sarguments:\s(.*)\sat\s/x ) {
        my @missing_required = split /,\s/x, $1;
        print STDERR
            join( "\n",
            ( map { $_ . " is missing" } @missing_required ), '' );
    }
    elsif ( $@ =~ /^(.*?)\srequired/x ) {
        print STDERR "$1 is missing\n";
    }
    elsif ( $@ =~ /^isa\scheck.*?failed:\s/x ) {
        print STDERR substr( $@, index( $@, ':' ) + 2 );
    }
    else {
        print STDERR $@;
    }
    %cmdline_params = $class->parse_options( h => 1 );
    return $class->options_usage( 1, $cmdline_params{h} );
}

=head2 parse_options

Parse your options, call L<Getopt::Long::Descriptive> and convert the result for the "new" method.

It is use by "new_with_options".

=cut

my $decode_json;

sub parse_options {
    my ( $class, %params ) = @_;

    my %options_data   = $class->_options_data;
    my %options_config = $class->_options_config;
    if ( defined $options_config{skip_options} ) {
        delete @options_data{ @{ $options_config{skip_options} } };
    }

    my ( $options, $has_to_split, $all_options )
        = _options_prepare_descriptive( \%options_data );

    local @ARGV = @ARGV if $options_config{protect_argv};
    @ARGV = _options_fix_argv( \%options_data, $has_to_split, $all_options );

    my @flavour;
    if ( defined $options_config{flavour} ) {
        push @flavour, { getopt_conf => $options_config{flavour} };
    }

    my $prog_name = $class->_options_prog_name();

    # create usage str
    my $usage_str = $options_config{usage_string};
    $usage_str = sprintf( $class->__("USAGE: %s %s"),
        $prog_name, " [-h] [" . $class->__("long options ...") . "]" )
        if !defined $usage_str;

    my ( $opt, $usage ) = describe_options(
        ($usage_str),
        @$options,
        [],
        [ 'usage', $class->__("show a short help message") ],
        [ 'h',     $class->__("show a compact help message") ],
        [ 'help',  $class->__("show a long help message") ],
        [ 'man',   $class->__("show the manual") ],
        ,
        @flavour
    );

    $usage->{prog_name} = $prog_name;
    $usage->{target}    = $class;

    if ( $usage->{should_die} ) {
        return $class->options_usage( 1, $usage );
    }

    my %cmdline_params = %params;
    for my $name ( keys %options_data ) {
        my %data = %{ $options_data{$name} };
        if ( !defined $cmdline_params{$name}
            || $options_config{prefer_commandline} )
        {
            my $val = $opt->$name();
            if ( defined $val ) {
                if ( $data{json} ) {
                    defined $decode_json
                        or $decode_json = eval {
                        use_module("JSON::MaybeXS");
                        JSON::MaybeXS->can("decode_json");
                        };
                    defined $decode_json
                        or $decode_json = eval {
                        use_module("JSON::PP");
                        JSON::PP->can("decode_json");
                        };
                    ## no critic (ErrorHandling::RequireCarping)
                    $@ and die $@;
                    if (!eval {
                            $cmdline_params{$name} = $decode_json->($val);
                            1;
                        }
                        )
                    {
                        print STDERR $@;
                        return $class->options_usage( 1, $usage );
                    }
                }
                else {
                    $cmdline_params{$name} = $val;
                }
            }
        }
    }

    if ( $opt->h() || defined $params{h} ) {
        $cmdline_params{h} = $usage;
    }

    if ( $opt->help() || defined $params{help} ) {
        $cmdline_params{help} = $usage;
    }

    if ( $opt->man() || defined $params{man} ) {
        $cmdline_params{man} = $usage;
    }

    if ( $opt->usage() || defined $params{usage} ) {
        $cmdline_params{usage} = $usage;
    }

    return %cmdline_params;
}

=head2 options_usage

Display help message.

Check full doc L<MooX::Options> for more details.

=cut

sub options_usage {
    my ( $class, $code, @messages ) = @_;
    my $usage;
    if ( @messages
        && ref $messages[-1] eq 'MooX::Options::Descriptive::Usage' )
    {
        $usage = shift @messages;
    }
    $code = 0 if !defined $code;
    if ( !$usage ) {
        local @ARGV = ();
        my %cmdline_params = $class->parse_options( help => $code );
        $usage = $cmdline_params{help};
    }
    my $message = "";
    $message .= join( "\n", @messages, '' ) if @messages;
    $message .= $usage . "\n";
    if ( $code > 0 ) {
        CORE::warn $message;
    }
    else {
        print $message;
    }
    exit($code) if $code >= 0;
    return;
}

=head2 options_help

Display long usage message

=cut

sub options_help {
    my ( $class, $code, $usage ) = @_;
    $code = 0 if !defined $code;

    if ( !defined $usage || !ref $usage ) {
        local @ARGV = ();
        my %cmdline_params = $class->parse_options( help => $code );
        $usage = $cmdline_params{help};
    }
    my $message = $usage->option_help . "\n";
    if ( $code > 0 ) {
        CORE::warn $message;
    }
    else {
        print $message;
    }
    exit($code) if $code >= 0;
    return;
}

=head2 options_short_usage

Display quick usage message, with only the list of options

=cut

sub options_short_usage {
    my ( $class, $code, $usage ) = @_;
    $code = 0 if !defined $code;

    if ( !defined $usage || !ref $usage ) {
        local @ARGV = ();
        my %cmdline_params = $class->parse_options( help => $code );
        $usage = $cmdline_params{help};
    }
    my $message = "USAGE: " . $usage->option_short_usage . "\n";
    if ( $code > 0 ) {
        CORE::warn $message;
    }
    else {
        print $message;
    }
    exit($code) if $code >= 0;
    return;
}

=head2 options_man

Display a pod like a manual

=cut

sub options_man {
    my ( $class, $usage, $output ) = @_;
    local @ARGV = ();
    if ( !$usage ) {
        local @ARGV = ();
        my %cmdline_params = $class->parse_options( man => 1 );
        $usage = $cmdline_params{man};
    }

    use_module( "Path::Class", "0.32" );
    my $man_file
        = Path::Class::file( Path::Class::tempdir( CLEANUP => 1 ),
        'help.pod' );
    $man_file->spew( iomode => '>:encoding(UTF-8)', $usage->option_pod );

    use_module("Pod::Usage");
    Pod::Usage::pod2usage(
        -verbose => 2,
        -input   => $man_file->stringify,
        -exitval => 'NOEXIT',
        -output  => $output
    );

    exit(0);
}

### PRIVATE NEED TO BE EXPORTED

sub _options_prog_name {
    return Getopt::Long::Descriptive::prog_name;
}

sub _options_sub_commands {
    return;
}

### PRIVATE NEED TO BE EXPORTED

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::ConfigFromFile

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-ConfigFromFile>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-ConfigFromFile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooX-ConfigFromFile>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-ConfigFromFile/>

=back

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This software is copyright (c) 2017 by Jens Rehsack.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

1;
