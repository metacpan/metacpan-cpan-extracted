package Getopt::Args;
use strict;
use warnings;
use Carp qw/croak carp/;
use Encode qw/decode/;
use Exporter::Tidy
  default => [qw/opt arg optargs usage subcmd/],
  other   => [qw/dispatch class_optargs/];
use Getopt::Long qw/GetOptionsFromArray/;
use List::Util qw/max/;

our $VERSION       = '0.1.20';
our $COLOUR        = 0;
our $ABBREV        = 0;
our $SORT          = 0;
our $PRINT_DEFAULT = 0;
our $PRINT_ISA     = 0;

my %seen;           # hash of hashes keyed by 'caller', then opt/arg name
my %opts;           # option configuration keyed by 'caller'
my %args;           # argument configuration keyed by 'caller'
my %caller;         # current 'caller' keyed by real caller
my %desc;           # sub-command descriptions
my %dispatching;    # track optargs() calls from dispatch classes
my %hidden;         # subcmd hiding by default

# internal function for App::optargs
sub _cmdlist {
    return sort grep { $_ ne 'App::optargs' } keys %seen;
}

# ------------------------------------------------------------------------
# Sub-command definition
#
# This works by faking caller context in opt() and arg()
# ------------------------------------------------------------------------
my %subcmd_params = (
    cmd     => undef,
    comment => undef,
    hidden  => undef,

    #    alias   => '',
    #    ishelp  => undef,
);

my @subcmd_required = (qw/cmd comment/);

sub subcmd {
    my $params = {@_};
    my $caller = caller;

    if ( my @missing = grep { !exists $params->{$_} } @subcmd_required ) {
        croak "missing required parameter(s): @missing";
    }

    if ( my @invalid = grep { !exists $subcmd_params{$_} } keys %$params ) {
        my @valid = keys %subcmd_params;
        croak "invalid parameter(s): @invalid (valid: @valid)";
    }

    #    croak "'ishelp' can only be applied to Bool opts"
    #      if $params->{ishelp} and $params->{isa} ne 'Bool';

    my @cmd =
      ref $params->{cmd} eq 'ARRAY'
      ? @{ $params->{cmd} }
      : ( $params->{cmd} );
    croak 'missing cmd elements' unless @cmd;

    my $name = pop @cmd;
    my $parent = join( '::', $caller, @cmd );
    $parent =~ s/-/_/g;

    croak "parent command not found: @cmd" unless $seen{$parent};

    my $package = $parent . '::' . $name;
    $package =~ s/-/_/g;

    croak "sub command already defined: @cmd $name" if $seen{$package};

    $caller{$caller}  = $package;
    $desc{$package}   = $params->{comment};
    $seen{$package}   = {};
    $opts{$package}   = [];
    $args{$package}   = [];
    $hidden{$package} = $params->{hidden};

    my $parent_arg = ( grep { $_->{isa} eq 'SubCmd' } @{ $args{$parent} } )[0];
    push( @{ $parent_arg->{subcommands} }, $name );

    return;
}

# ------------------------------------------------------------------------
# Option definition
# ------------------------------------------------------------------------
my %opt_params = (
    isa      => undef,
    isa_name => undef,
    comment  => undef,
    default  => undef,
    alias    => '',
    ishelp   => undef,
    hidden   => undef,
);

my @opt_required = (qw/isa comment/);

my %opt_isa = (
    'Bool'     => '!',
    'Counter'  => '+',
    'Str'      => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%',
);

sub opt {
    my $name    = shift;
    my $params  = {@_};
    my $caller  = caller;
    my $package = $caller{$caller} || $caller;

    croak 'usage: opt $name => (%parameters)' unless $name;
    croak "'$name' already defined" if $seen{$package}->{$name};

    if ( my @missing = grep { !exists $params->{$_} } @opt_required ) {
        croak "missing required parameter(s): @missing";
    }

    if ( my @invalid = grep { !exists $opt_params{$_} } keys %$params ) {
        my @valid = keys %opt_params;
        croak "invalid parameter(s): @invalid (valid: @valid)";
    }

    croak "'ishelp' can only be applied to Bool opts"
      if $params->{ishelp} and $params->{isa} ne 'Bool';

    croak "unknown type: $params->{isa}"
      unless exists $opt_isa{ $params->{isa} };

    $params = { %opt_params, %$params };
    $params->{package} = $package;
    $params->{name}    = $name;
    $params->{length}  = length $name;
    $params->{acount}  = do { my @tmp = split( '|', $params->{alias} ) };
    $params->{type}    = 'opt';
    $params->{ISA}     = $params->{name};

    if ( ( my $dashed = $params->{name} ) =~ s/_/-/g ) {
        $params->{dashed} = $dashed;
        $params->{ISA} .= '|' . $dashed;
    }

    $params->{ISA} .= '|' . $params->{alias} if $params->{alias};
    $params->{ISA} .= $opt_isa{ $params->{isa} };

    push( @{ $opts{$package} }, $params );
    $args{$package} ||= [];
    $seen{$package}->{$name}++;

    return;
}

# ------------------------------------------------------------------------
# Argument definition
# ------------------------------------------------------------------------
my %arg_params = (
    isa      => undef,
    comment  => undef,
    required => undef,
    default  => undef,
    greedy   => undef,
    fallback => undef,
);

my @arg_required = (qw/isa comment/);

my %arg_isa = (
    'Str'      => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%',
    'SubCmd'   => '=s',
);

sub arg {
    my $name    = shift;
    my $params  = {@_};
    my $caller  = caller;
    my $package = $caller{$caller} || $caller;

    croak 'usage: arg $name => (%parameters)' unless $name;
    croak "'$name' already defined" if $seen{$package}->{$name};

    if ( my @missing = grep { !exists $params->{$_} } @arg_required ) {
        croak "missing required parameter(s): @missing";
    }

    if ( my @invalid = grep { !exists $arg_params{$_} } keys %$params ) {
        my @valid = keys %arg_params;
        croak "invalid parameter(s): @invalid (valid: @valid)";
    }

    croak "unknown type: $params->{isa}"
      unless exists $arg_isa{ $params->{isa} };

    croak "'default' and 'required' cannot be used together"
      if defined $params->{default} and defined $params->{required};

    croak "'fallback' only valid with isa 'SubCmd'"
      if $params->{fallback} and $params->{isa} ne 'SubCmd';

    croak "fallback must be a hashref"
      if defined $params->{fallback} && ref $params->{fallback} ne 'HASH';

    $params->{package} = $package;
    $params->{name}    = $name;
    $params->{length}  = length $name;
    $params->{acount}  = 0;
    $params->{type}    = 'arg';
    $params->{ISA}     = $params->{name} . $arg_isa{ $params->{isa} };

    push( @{ $args{$package} }, $params );
    $opts{$package} ||= [];
    $seen{$package}->{$name}++;

    if ( $params->{fallback} ) {
        my $p = $package . '::' . uc $params->{fallback}->{name};
        $p =~ s/-/_/g;
        $opts{$p} = [];
        $args{$p} = [];
        $desc{$p} = $params->{fallback}->{comment};
    }

    return;
}

# ------------------------------------------------------------------------
# Usage message generation
# ------------------------------------------------------------------------

sub _usage {
    my $caller   = shift;
    my $error    = shift;
    my $ishelp   = shift;
    my $terminal = -t STDOUT;
    my $red      = ( $COLOUR && $terminal ) ? "\e[0;31m" : '';
    my $yellow = '';    #( $COLOUR && $terminal ) ? "\e[0;33m" : '';
    my $grey   = '';    #( $COLOUR && $terminal ) ? "\e[1;30m" : '';
    my $reset  = ( $COLOUR && $terminal ) ? "\e[0m" : '';
    my $parent = $caller;
    my @args   = @{ $args{$caller} };
    my @opts   = @{ $opts{$caller} };
    my @parents;
    my @usage;
    my @uargs;
    my @uopts;
    my $usage;

    require File::Basename;
    my $me = File::Basename::basename( defined &static::list ? $^X : $0 );

    if ($error) {
        $usage .= "${red}error:$reset $error\n\n";
    }

    $usage .= $yellow . ( $ishelp ? 'help:' : 'usage:' ) . $reset . ' ' . $me;

    while ( $parent =~ s/(.*)::(.*)/$1/ ) {
        last unless $seen{$parent};
        ( my $name = $2 ) =~ s/_/-/g;
        unshift( @parents, $name );
        unshift( @opts,    @{ $opts{$parent} } );
    }

    $usage .= ' ' . join( ' ', @parents ) if @parents;

    my $last = $args[$#args];

    if ($last) {
        foreach my $def (@args) {
            $usage .= ' ';
            $usage .= '[' unless $def->{required};
            $usage .= uc $def->{name};
            $usage .= '...' if $def->{greedy};
            $usage .= ']' unless $def->{required};
            push( @uargs, [ uc $def->{name}, $def->{comment} ] );
        }
    }

    $usage .= ' [OPTIONS...]' if @opts;

    $usage .= "\n";

    $usage .= "\n  ${grey}Synopsis:$reset\n    $desc{$caller}\n"
      if $ishelp and $desc{$caller};

    if ( $ishelp and my $version = $caller->VERSION ) {
        $usage .= "\n  ${grey}Version:$reset\n    $version\n";
    }

    if ( $last && $last->{isa} eq 'SubCmd' ) {
        $usage .= "\n  ${grey}" . ucfirst( $last->{name} ) . ":$reset\n";

        my @subcommands = @{ $last->{subcommands} };

        push( @subcommands, uc $last->{fallback}->{name} )
          if (
            exists $last->{fallback}
            && ( $ishelp
                or !$last->{fallback}->{hidden} )
          );

        @subcommands = sort @subcommands if $SORT;

        foreach my $subcommand (@subcommands) {
            my $pkg = $last->{package} . '::' . $subcommand;
            $pkg =~ s/-/_/g;
            next if $hidden{$pkg} and !$ishelp;
            push( @usage, [ $subcommand, $desc{$pkg} ] );
        }

    }

    @opts = sort { $a->{name} cmp $b->{name} } @opts if $SORT;

    foreach my $opt (@opts) {
        next if $opt->{hidden} and !$ishelp;

        ( my $name = $opt->{name} ) =~ s/_/-/g;

        if ( $opt->{isa} eq 'Bool' and $opt->{default} ) {
            $name = 'no-' . $name;
        }

        my $default = '';
        if ( $PRINT_DEFAULT && defined $opt->{default} and !$opt->{ishelp} ) {
            my $value =
              ref $opt->{default} eq 'CODE'
              ? $opt->{default}->( {%$opt} )
              : $opt->{default};
            if ( $opt->{isa} eq 'Bool' ) {
                $value = $value ? 'true' : 'false';
            }
            $default = " [default: $value]";
        }

        if ($PRINT_ISA) {
            if ( $opt->{isa_name} ) {
                $name .= '=' . uc $opt->{isa_name};
            }
            elsif ($opt->{isa} eq 'Str'
                || $opt->{isa} eq 'HashRef'
                || $opt->{isa} eq 'ArrayRef' )
            {
                $name .= '=STR';
            }
            elsif ( $opt->{isa} eq 'Int' ) {
                $name .= '=INT';
            }
            elsif ( $opt->{isa} eq 'Num' ) {
                $name .= '=NUM';
            }
        }

        $name .= ',' if $opt->{alias};
        push(
            @uopts,
            [
                '--' . $name,
                $opt->{alias}
                ? '-' . $opt->{alias}
                : '',
                $opt->{comment} . $default
            ]
        );
    }

    if (@uopts) {
        my $w1 = max( map { length $_->[0] } @uopts );
        my $fmt = '%-' . $w1 . "s %s";

        @uopts = map { [ sprintf( $fmt, $_->[0], $_->[1] ), $_->[2] ] } @uopts;
    }

    my $w1 = max( map { length $_->[0] } @usage, @uargs, @uopts );
    my $format = '    %-' . $w1 . "s   %s\n";

    if (@usage) {
        foreach my $row (@usage) {
            $usage .= sprintf( $format, @$row );
        }
    }
    if ( @uargs and $last->{isa} ne 'SubCmd' ) {
        $usage .= "\n  ${grey}Arguments:$reset\n";
        foreach my $row (@uargs) {
            $usage .= sprintf( $format, @$row );
        }
    }
    if (@uopts) {
        $usage .= "\n  ${grey}Options:$reset\n";
        foreach my $row (@uopts) {
            $usage .= sprintf( $format, @$row );
        }
    }

    $usage .= "\n";
    return bless( \$usage, 'Getopt::Args::Usage' );
}

sub _synopsis {
    my $caller = shift;
    my $parent = $caller;
    my @args   = @{ $args{$caller} };
    my @parents;

    require File::Basename;
    my $usage = File::Basename::basename($0);

    while ( $parent =~ s/(.*)::(.*)/$1/ ) {
        last unless $seen{$parent};
        ( my $name = $2 ) =~ s/_/-/g;
        unshift( @parents, $name );
    }

    $usage .= ' ' . join( ' ', @parents ) if @parents;

    if ( my $last = $args[$#args] ) {
        foreach my $def (@args) {
            $usage .= ' ';
            $usage .= '[' unless $def->{required};
            $usage .= uc $def->{name};
            $usage .= '...' if $def->{greedy};
            $usage .= ']' unless $def->{required};
        }
    }

    return 'usage: ' . $usage . "\n";
}

sub usage {
    my $caller = caller;
    return _usage( $caller, @_ );
}

# ------------------------------------------------------------------------
# Option/Argument processing
# ------------------------------------------------------------------------
sub _optargs {
    my $caller      = shift;
    my $source      = \@_;
    my $source_hash = {};
    my $package     = $caller;

    if ( !@_ and @ARGV ) {
        my $CODESET =
          eval { require I18N::Langinfo; I18N::Langinfo::CODESET() };

        if ($CODESET) {
            my $codeset = I18N::Langinfo::langinfo($CODESET);
            $_ = decode( $codeset, $_ ) for @ARGV;
        }

        $source = \@ARGV;
    }
    else {
        $source_hash = { map { %$_ } grep { ref $_ eq 'HASH' } @$source };
        $source = [ grep { ref $_ ne 'HASH' } @$source ];
    }

    map { Carp::croak('_optargs argument undefined!') if !defined $_ } @$source;

    croak "no option or argument defined for $caller"
      unless exists $opts{$package}
      or exists $args{$package};

    Getopt::Long::Configure(qw/pass_through no_auto_abbrev no_ignore_case/);

    my @config = ( @{ $opts{$package} }, @{ $args{$package} } );

    my $ishelp;
    my $missing_required;
    my $optargs = {};
    my @coderef_default_keys;

    while ( my $try = shift @config ) {
        my $result;

        if ( $try->{type} eq 'opt' ) {
            if ( exists $source_hash->{ $try->{name} } ) {
                $result = delete $source_hash->{ $try->{name} };
            }
            else {
                GetOptionsFromArray( $source, $try->{ISA} => \$result );
            }
        }
        elsif ( $try->{type} eq 'arg' ) {
            if (@$source) {
                die _usage( $package, qq{Unknown option "$source->[0]"} )
                  if $source->[0] =~ m/^--\S/;

                die _usage( $package, qq{Unknown option "$source->[0]"} )
                  if $source->[0] =~ m/^-\S/
                  and !(
                    $source->[0] =~ m/^-\d/ and ( $try->{isa} ne 'Num'
                        or $try->{isa} ne 'Int' )
                  );

                if ( $try->{greedy} ) {
                    my @later;
                    if ( @config and @$source > @config ) {
                        push( @later, pop @$source ) for @config;
                    }

                    if ( $try->{isa} eq 'ArrayRef' ) {
                        $result = [@$source];
                    }
                    elsif ( $try->{isa} eq 'HashRef' ) {
                        $result = { map { split /=/, $_ } @$source };
                    }
                    else {
                        $result = "@$source";
                    }

                    shift @$source while @$source;
                    push( @$source, @later );
                }
                else {
                    if ( $try->{isa} eq 'ArrayRef' ) {
                        $result = [ shift @$source ];
                    }
                    elsif ( $try->{isa} eq 'HashRef' ) {
                        $result = { split /=/, shift @$source };
                    }
                    else {
                        $result = shift @$source;
                    }
                }

                # TODO: type check using Param::Utils?
            }
            elsif ( exists $source_hash->{ $try->{name} } ) {
                $result = delete $source_hash->{ $try->{name} };
            }
            elsif ( $try->{required} and !$ishelp ) {
                $missing_required++;
                next;
            }

            if ( $try->{isa} eq 'SubCmd' and $result ) {

                # look up abbreviated words
                if ($ABBREV) {
                    require Text::Abbrev;
                    my %words =
                      map { m/^$package\:\:(\w+)$/; $1 => 1 }
                      grep { m/^$package\:\:(\w+)$/ }
                      keys %seen;
                    my %abbrev = Text::Abbrev::abbrev( keys %words );
                    $result = $abbrev{$result} if defined $abbrev{$result};
                }

                my $newpackage = $package . '::' . $result;
                $newpackage =~ s/-/_/g;

                if ( exists $seen{$newpackage} ) {
                    $package = $newpackage;
                    @config = grep { $_->{type} eq 'opt' } @config;
                    push( @config, @{ $opts{$package} }, @{ $args{$package} } );
                }
                elsif ( !$ishelp ) {
                    if ( $try->{fallback} ) {
                        unshift @$source, $result;
                        $try->{fallback}->{type} = 'arg';
                        unshift( @config, $try->{fallback} );
                        next;
                    }
                    else {
                        die _usage( $package,
                            "Unknown " . uc( $try->{name} ) . qq{ "$result"} );
                    }
                }

                $result = undef;
            }

        }

        if ( defined $result ) {
            $optargs->{ $try->{name} } = $result;
        }
        elsif ( defined $try->{default} ) {
            push( @coderef_default_keys, $try->{name} )
              if ref $try->{default} eq 'CODE';
            $optargs->{ $try->{name} } = $result = $try->{default};
        }

        $ishelp = 1 if $result and $try->{ishelp};

    }

    if ($ishelp) {
        die _usage( $package, undef, 1 );
    }
    elsif ($missing_required) {
        die _usage($package);
    }
    elsif (@$source) {
        die _usage( $package, "Unexpected options or arguments: @$source" );
    }
    elsif ( my @unexpected = keys %$source_hash ) {
        die _usage( $package,
            "Unexpected HASH options or arguments: @unexpected" );
    }

    # Re-calculate the default if it was a subref
    foreach my $key (@coderef_default_keys) {
        $optargs->{$key} = $optargs->{$key}->( {%$optargs} );
    }

    return ( $package, $optargs );
}

sub optargs {
    my $caller = caller;

    carp "optargs() called from dispatch handler"
      if $dispatching{$caller};

    my ( $package, $optargs ) = _optargs( $caller, @_ );
    return $optargs;
}

sub class_optargs {
    my $caller = shift;

    croak 'dispatch($class, [@argv])' unless $caller;
    carp "optargs_class() called from dispatch handler"
      if $dispatching{$caller};

    die $@ unless eval "require $caller;";

    my ( $class, $optargs ) = _optargs( $caller, @_ );

    croak $@ unless eval "require $class;1;";
    return ( $class, $optargs );
}

sub dispatch {
    my $method = shift;
    my $class  = shift;

    croak 'dispatch($method, $class, [@argv])' unless $method and $class;
    croak $@ unless eval "require $class;1;";

    my ( $package, $optargs ) = class_optargs( $class, @_ );

    my $sub = $package->can($method);
    die "Can't find method $method via package $package" unless $sub;

    $dispatching{$class}++;
    my @results = $sub->($optargs);
    $dispatching{$class}--;
    return @results if wantarray;
    return $results[0];
}

package Getopt::Args::Usage;
use overload
  bool     => sub { 1 },
  '""'     => sub { ${ $_[0] } },
  fallback => 1;

1;

__END__

=head1 NAME

Getopt::Args - integrated argument and option processing

=head1 VERSION

0.1.20 (2016-04-11)

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use Getopt::Args;

    opt quiet => (
        isa     => 'Bool',
        alias   => 'q',
        comment => 'output nothing while working',
    );

    arg item => (
        isa      => 'Str',
        required => 1,
        comment  => 'the item to paint',
    );

    my $ref = optargs;

    print "Painting $ref->{item}\n" unless $ref->{quiet};

=head1 DESCRIPTION

B<Getopt::Args> processes Perl script I<options> and I<arguments>.  This is
in contrast with most modules in the Getopt::* namespace, which deal
with options only. This module is duplicated as L<OptArgs>, to
cover both its original name and yet still be found in the mess that is
Getopt::*.

The following model is assumed by B<Getopt::Args> for command-line
applications:

=over

=item Command

The program name - i.e. the filename be executed by the shell.

=item Options

Options are parameters that affect the way a command runs. They are
generally not required to be present, but that is configurable. All
options have a long form prefixed by '--', and may have a single letter
alias prefixed by '-'.

=item Arguments

Arguments are positional parameters that that a command needs know in
order to do its work. Confusingly, arguments can be optional.

=item Sub-commands

From a users point of view a sub-command is simply one or more
arguments given to a Command that result in a particular action.
However from a code perspective they are implemented as separate,
stand-alone programs which are called by a dispatcher when the
appropriate arguments are given.

=back

=head2 Simple Scripts

To demonstrate lets put the code from the synopsis in a file called
C<paint> and observe the following interactions from the shell:

    $ ./paint
    usage: paint ITEM

      arguments:
        ITEM          the item to paint

      options:
        --quiet, -q   output nothing while working

The C<optargs()> function parses the commands arguments according to
the C<opt> and C<arg> declarations and returns a single HASH reference.
If the command is not called correctly then an exception is thrown (an
C<Getopt::Args::Usage> object) with an automatically generated usage message
as shown above.

Because B<Getopt::Args> knows about arguments it can detect errors relating
to them:

    $ ./paint house red
    error: unexpected option or argument: red

So let's add that missing argument definition:

    arg colour => (
        isa     => 'Str',
        default => 'blue',
        comment => 'the colour to use',
    );

And then check the usage again:

    $ ./paint
    usage: paint ITEM [COLOUR]

      arguments:
        ITEM          the item to paint
        COLOUR        the colour to use

      options:
        --quiet, -q   output nothing while working

It can be seen that the non-required argument C<colour> appears inside
square brackets indicating its optional nature.

Let's add another argument with a positive value for the C<greedy>
parameter:

    arg message => (
        isa     => 'Str',
        comment => 'the message to paint on the item',
        greedy  => 1,
    );

And check the new usage output:

    usage: paint ITEM [COLOUR] [MESSAGE...]

      arguments:
        ITEM          the item to paint
        COLOUR        the colour to use
        MESSAGE       the message to paint on the item

      options:
        --quiet, -q   output nothing while working

Three dots (...) are postfixed to usage message for greedy arguments.
By being greedy, the C<message> argument will swallow whatever is left
on the comand line:

    $ ./paint house blue Perl is great
    Painting in blue on house: "Perl is great".

Note that it doesn't make sense to define any more arguments once you
have a greedy argument.

The order in which options and arguments (and sub-commands - see below)
are defined is the order in which they appear in usage messsages, and
is also the order in which the command line is parsed for them.

=head2 Sub-Command Scripts

Sub-commands are useful when your script performs different actions
based on the value of a particular argument. To use sub-commands you
build your application with the following structure:

=over

=item Command Class

The Command Class defines the options and arguments for your I<entire>
application. The module is written the same way as a simple script but
additionally specifies an argument of type 'SubCmd':

    package My::Cmd;
    use Getopt::Args;

    arg command => (
        isa     => 'SubCmd',
        comment => 'sub command to run',
    );

    opt help => (
        isa     => 'Bool',
        comment => 'print a help message and exit',
        ishelp  => 1,
    );

    opt dry_run => (
        isa     => 'Bool',
        comment => 'do nothing',
    );

The C<subcmd> function call is then used to define sub-command names
and descriptions, and separate each sub-commands arguments and options:

    subcmd(
        cmd     => 'start',
        comment => 'start a machine'
    );

    arg machine => (
        isa     => 'Str',
        comment => 'the machine to start',
    );

    opt quickly => (
        isa     => 'Bool',
        comment => 'start the machine quickly',
    );

    subcmd(
        cmd     => 'stop',
        comment => 'start the machine'
    );

    arg machine => (
        isa     => 'Str',
        comment => 'the machine to stop',
    );

    opt plug => (
        isa     => 'Bool',
        comment => 'stop the machine by pulling the plug',
    );

One nice thing about B<Getopt::Args> is that options are I<inherited>. You
only need to specify something like a C<dry-run> option once at the top
level, and all sub-commands will see it if it has been set.

Additionally, and this is the main reason why I wrote B<Getopt::Args>, you
do not have to load a whole bunch of slow-to-start modules ( I'm
looking at you, L<Moose>) just to get a help message.

=item Sub-Command Classes

These classes do the actual work. The usual entry point would be a
method or a function, typically called something like C<run>, which
takes a HASHref argument:

    package My::Cmd::start;

    sub run {
        my $self = shift;
        my $opts = shift;
        print "Starting $opts->{machine}\n";
    }


    package My::Cmd::stop;

    sub run {
        my $self = shift;
        my $opts = shift;
        print "Stoping $opts->{machine}\n";
    }

=item Command Script

The command script is what the user runs, and does nothing more than
dispatch to your Command Class, and eventually a Sub-Command Class.

    #!/usr/bin/perl
    use Getopt::Args qw/class_optargs/;
    my ($class, $opts) = class_optargs('My::Cmd');

    # Run object based sub-command classes
    $class->new->run($opts);

    # Or function based sub-command classes
    $class->can('run')->($opts);

One advantage to having a separate Command Class (and not defining
everything inside a Command script) is that it is easy to run tests
against your various Sub-Command Classes as follows:

    use Test::More;
    use Test::Output;
    use Getopt::Args qw/class_optargs/;

    stdout_is(
        sub {
            my ($class,$opts) = class_optargs('My::Cmd','start','A');
            $class->new->run($opts);
        },
        "Starting A\n", 'start'
    );

    eval { class_optargs('My::Cmd', '--invalid-option') };
    isa_ok $@, 'Getopt::Args::Usage';

    done_testing();

It is much easier to catch and measure exceptions when the code is
running inside your test script, instead of having to fork and parse
stderr strings.

=back

=head1 FUNCTIONS

The following functions are exported (by default except for
C<dispatch>) using L<Exporter::Tidy>.

=over

=item arg( $name, %parameters )

Define a Command Argument with the following parameters:

=over

=item isa

Required. Is mapped to a L<Getopt::Long> type according to the
following table:

     optargs         Getopt::Long
    ------------------------------
     'Str'           '=s'
     'Int'           '=i'
     'Num'           '=f'
     'ArrayRef'      's@'
     'HashRef'       's%'
     'SubCmd'        '=s'

=item comment

Required. Used to generate the usage/help message.

=item required

Set to a true value when the caller must specify this argument.  Can
not be used if a 'default' is given.

=item default

The value set when the argument is not given. Can not be used if
'required' is set.

If this is a subroutine reference it will be called with a hashref
containg all option/argument values after parsing the source has
finished.  The value to be set must be returned, and any changes to the
hashref are ignored.

=item greedy

If true the argument swallows the rest of the command line. It doesn't
make sense to define any more arguments once you have used this as they
will never be seen.

=item fallback

A hashref containing an argument definition for the event that a
sub-command match is not found. This parameter is only valid when
C<isa> is a C<SubCmd>. The hashref must contain "isa", "name" and
"comment" key/value pairs, and may contain a "greedy" key/value pair.
The Command Class "run" function will be called with the fallback
argument integrated into the first argument like a regular sub-command.

This is generally useful when you want to calculate a command alias
from a configuration file at runtime, or otherwise run commands which
don't easily fall into the Getopt::Args sub-command model.

=back

=item class_optargs( $rootclass, [ @argv ] ) -> ($class, $opts)

This is a more general version of the C<optargs> function described in
detail below.  It parses C<@ARGV> (or C<@argv> if given) according to
the options and arguments as defined in C<$rootclass>, and returns two
values:

=over

=item $class

The class name of the matching sub-command.

=item $opts

The matching argument and options for the sub-command.

=back

As an aid for testing, if the passed in argument C<@argv> (not @ARGV)
contains a HASH reference, the key/value combinations of the hash will
be added as options. An undefined value means a boolean option.

=item dispatch( $function, $rootclass, [ @argv ] )

[ NOTE: This function is badly designed and is depreciated. It will be
removed at some point before version 1.0.0]

Parse C<@ARGV> (or C<@argv> if given) and dispatch to C<$function> in
the appropriate package name constructed from C<$rootclass>.

As an aid for testing, if the passed in argument C<@argv> (not @ARGV)
contains a HASH reference, the key/value combinations of the hash will
be added as options. An undefined value means a boolean option.

=item opt( $name, %parameters )

Define a Command Option. If C<$name> contains underscores then aliases
with the underscores replaced by dashes (-) will be created. The
following parameters are accepted:

=over

=item isa

Required. Is mapped to a L<Getopt::Long> type according to the
following table:

     optargs         Getopt::Long
    ------------------------------
     'Bool'          '!'
     'Counter'       '+'
     'Str'           '=s'
     'Int'           '=i'
     'Num'           '=f'
     'ArrayRef'      's@'
     'HashRef'       's%'

=item isa_name

When C<$Getopt::Args::PRINT_ISA> is set to a true value, this value will be
printed instead of the generic value from C<isa>.

=item comment

Required. Used to generate the usage/help message.

=item default

The value set when the option is not used.

If this is a subroutine reference it will be called with a hashref
containg all option/argument values after parsing the source has
finished.  The value to be set must be returned, and any changes to the
hashref are ignored.

For "Bool" options setting "default" to a true has a special effect:
the the usage message formats it as "--no-option" instead of
"--option". If you do use a true default value for Bool options you
probably want to reverse the normal meaning of your "comment" value as
well.

=item alias

A single character alias.

=item ishelp

When true flags this option as a help option, which when given on the
command line results in a usage message exception.  This flag is
basically a cleaner way of doing the following in each (sub) command:

    my $opts = optargs;
    if ( $opts->{help} ) {
        die usage('help requested');
    }

=item hidden

When true this option will not appear in usage messages unless the
usage message is a help request.

This is handy if you have developer-only options, or options that are
very rarely used that you don't want cluttering up your normal usage
message.

=item arg_name

When C<$Getopt::Args::PRINT_OPT_ARG> is set to a true value, this value will
be printed instead of the generic value from C<isa>.

=back

=item optargs( [ @argv ] ) -> HashRef

Parse @ARGV by default (or @argv when given) for the arguments and
options defined in the I<current package>, and returns a hashref
containing key/value pairs for options and arguments I<combined>.  An
error / usage exception object (C<Getopt::Args::Usage>) is thrown if an
invalid combination of options and arguments is given.

Note that C<@ARGV> will be decoded into UTF-8 (if necessary) from
whatever L<I18N::Langinfo> says your current locale codeset is.

=item subcmd( %parameters )

Create a sub-command. After this function is called further calls to
C<opt> and C<arg> define options and arguments respectively for the
sub-command.  The following parameters are accepted:

=over

=item cmd

Required. Either a scalar or an ARRAY reference containing the sub
command name.

=item comment

Required. Used to generate the usage/help message.

=item hidden

When true this sub command will not appear in usage messages unless the
usage message is a help request.

This is handy if you have developer-only or rarely-used commands that
you don't want cluttering up your normal usage message.

=back

=item usage( [$message] ) -> Str

Returns a usage string prefixed with $message if given.

=back

=head1 OPTIONAL BEHAVIOUR

Certain B<Getopt::Args> behaviour and/or output can be changed by setting
the following package-level variables:

=over

=item $Getopt::Args::ABBREV

If C<$Getopt::Args::ABBREV> is a true value then sub-commands can be
abbreviated, up to their shortest, unique values.

=item $Getopt::Args::COLOUR

If C<$Getopt::Args::COLOUR> is a true value and C<STDOUT> is connected to a
terminal then usage and error messages will be colourized using
terminal escape codes.

=item $Getopt::Args::SORT

If C<$Getopt::Args::SORT> is a true value then sub-commands will be listed
in usage messages alphabetically instead of in the order they were
defined.

=item $Getopt::Args::PRINT_DEFAULT

If C<$Getopt::Args::PRINT_DEFAULT> is a true value then usage will print the
default value of all options.

=item $Getopt::Args::PRINT_ISA

If C<$Getopt::Args::PRINT_ISA> is a true value then usage will print the
type of argument a options expects.

=back

=head1 SEE ALSO

L<Getopt::Long>, L<Exporter::Tidy>

=head1 SUPPORT & DEVELOPMENT


This distribution is managed via github:

    https://github.com/mlawren/p5-OptArgs/tree/devel

This distribution follows the semantic versioning model:

    http://semver.org/

Code is tidied up on Git commit using githook-perltidy:

    http://github.com/mlawren/githook-perltidy

=head1 AUTHOR

Mark Lawrence <nomad@null.net>

=head1 LICENSE

Copyright 2012-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

