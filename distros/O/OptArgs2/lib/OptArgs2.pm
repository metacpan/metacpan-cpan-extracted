use strict;
use warnings;

package OptArgs2;
use Encode qw/decode/;
use Exporter::Tidy
  default => [qw/class_optargs cmd optargs subcmd arg opt/],
  other   => [qw/usage cols rows/];

our $VERSION  = '2.0.0';
our @CARP_NOT = (
    qw/
      OptArgs2
      OptArgs2::Arg
      OptArgs2::Cmd
      OptArgs2::CmdBase
      OptArgs2::Opt
      OptArgs2::OptArgBase
      OptArgs2::SubCmd
      /
);

# constants
sub STYLE_USAGE()       { 'Usage' }         # default
sub STYLE_HELP()        { 'Help' }
sub STYLE_HELPTREE()    { 'HelpTree' }
sub STYLE_HELPSUMMARY() { 'HelpSummary' }

our %CURRENT;                               # legacy interface
my %COMMAND;
my @chars;

sub _chars {
    if ( $^O eq 'MSWin32' ) {
        require Win32::Console;
        @chars = Win32::Console->new()->Size();
    }
    else {
        require Term::Size::Perl;
        @chars = Term::Size::Perl::chars();
    }
    \@chars;
}

sub cols {
    $chars[0] // _chars()->[0];
}

sub rows {
    $chars[1] // _chars()->[1];
}

my %error_types = (
    CmdExists         => undef,
    CmdNotFound       => undef,
    Conflict          => undef,
    InvalidIsa        => undef,
    ParentCmdNotFound => undef,
    SubCmdExists      => undef,
    UndefOptArg       => undef,
    Usage             => undef,
);

sub throw_error {
    require Carp;

    my $proto = shift;
    my $type  = shift // Carp::croak( 'Usage', 'error($TYPE, [$msg])' );
    my $pkg   = 'OptArgs2::Error::' . $type;
    my $msg   = shift // "($pkg)";
    $msg = sprintf( $msg, @_ ) if @_;

    Carp::croak( 'Usage', "unknown error type: $type" )
      unless exists $error_types{$type};

    $msg .= ' ' . Carp::longmess('');

    no strict 'refs';
    *{ $pkg . '::ISA' } = ['OptArgs2::Status'];

    die bless \$msg, $pkg;
}

my %usage_types = (
    ArgRequired      => undef,
    Help             => undef,
    HelpSummary      => undef,
    HelpTree         => undef,
    OptRequired      => undef,
    OptUnknown       => undef,
    SubCmdRequired   => undef,
    SubCmdUnknown    => undef,
    UnexpectedOptArg => undef,
);

sub throw_usage {
    my $proto = shift;
    my $type  = shift // $proto->error( 'Usage', 'usage($TYPE, $str)' );
    my $str   = shift // $proto->error( 'Usage', 'usage($type, $STR)' );
    my $pkg   = 'OptArgs2::Usage::' . $type;

    $proto->error( 'Usage', "unknown usage reason: $type" )
      unless exists $usage_types{$type};

    if ( -t STDERR ) {
        my $lines = scalar( split /\n/, $str );
        $lines++ if $str =~ m/\n\z/;

        if ( $lines >= OptArgs2::rows() ) {
            require OptArgs2::Pager;
            my $pager = OptArgs2::Pager->new( auto => 0 );
            local *STDERR = $pager->fh;

            no strict 'refs';
            *{ $pkg . '::ISA' } = ['OptArgs2::Status'];
            die bless \$str, $pkg;
        }
    }

    no strict 'refs';
    *{ $pkg . '::ISA' } = ['OptArgs2::Status'];
    die bless \$str, $pkg;
}

sub class_optargs {
    my $class = shift
      || OptArgs2->throw_error( 'Usage', 'class_optargs($CMD,[@argv])' );

    my $cmd = $COMMAND{$class}
      || OptArgs2->throw_error( 'CmdNotFound',
        'command class not found: ' . $class );

    my @source = @_;

    if ( !@_ and @ARGV ) {
        my $CODESET =
          eval { require I18N::Langinfo; I18N::Langinfo::CODESET() };

        if ($CODESET) {
            my $codeset = I18N::Langinfo::langinfo($CODESET);
            $_ = decode( $codeset, $_ ) for @ARGV;
        }

        @source = @ARGV;
    }

    $cmd->parse(@source);
}

sub cmd {
    my $class = shift || OptArgs2->throw_error( 'Usage', 'cmd($CLASS,@args)' );

    OptArgs2->throw_error( 'CmdExists', "command already defined: $class" )
      if exists $COMMAND{$class};

    $COMMAND{$class} = OptArgs2::Cmd->new( class => $class, @_ );
}

sub optargs {
    my $class = caller;
    cmd( $class, @_ );
    ( class_optargs($class) )[1];
}

sub subcmd {
    my $class =
      shift || OptArgs2->throw_error( 'Usage', 'subcmd($CLASS,%%args)' );

    OptArgs2->throw_error( 'SubCmdExists',
        "subcommand already defined: $class" )
      if exists $COMMAND{$class};

    OptArgs2->throw_error( 'ParentCmdNotFound',
        "no '::' in class '$class' - must have a parent" )
      unless $class =~ m/(.+)::(.+)/;

    my $parent_class = $1;

    OptArgs2->throw_error( 'ParentCmdNotFound',
        "parent class not found: " . $parent_class )
      unless exists $COMMAND{$parent_class};

    $COMMAND{$class} = $COMMAND{$parent_class}->add_cmd(
        class => $class,
        @_
    );
}

sub usage {
    my $class = shift || do {
        my ($pkg) = caller;
        $pkg;
    };
    my $style = shift;

    OptArgs2->throw_error( 'CmdNotFound', "command not found: $class" )
      unless exists $COMMAND{$class};

    return $COMMAND{$class}->usage_string($style);
}

# Legacy interface, no longer documented

sub arg {
    my $name = shift;

    $OptArgs2::CURRENT //= cmd( ( scalar caller ), comment => '' );
    $OptArgs2::CURRENT->add_arg(
        name => $name,
        @_,
    );
}

sub opt {
    my $name = shift;

    $OptArgs2::CURRENT //= cmd( ( scalar caller ), comment => '' );
    $OptArgs2::CURRENT->add_opt(
        name => $name,
        @_,
    );
}

package OptArgs2::Status {
    use overload
      bool     => sub { 1 },
      '""'     => sub { ${ $_[0] } },
      fallback => 1;
}

package OptArgs2::CODEREF {
    our @CARP_NOT = @OptArgs2::CARP_NOT;

    sub TIESCALAR {
        my $class = shift;
        ( 3 == @_ )
          or Optargs2->throw_error( 'Usage', 'args: optargs,name,sub' );
        return bless [@_], $class;
    }

    sub FETCH {
        my $self = shift;
        my ( $optargs, $name, $sub ) = @$self;
        untie $optargs->{$name};
        $optargs->{$name} = $sub->($optargs);
    }
}

package OptArgs2::OptArgBase {
    use OptArgs2::OptArgBase_CI
      abstract => 1,
      has      => {
        comment      => { required => 1, },
        default      => {},
        getopt       => {},
        isa          => { required => 1, },
        isa_name     => { is       => 'rw', },
        name         => { required => 1, },
        required     => {},
        show_default => {},
      },
      ;

    our @CARP_NOT = @OptArgs2::CARP_NOT;
    our %isa2name = (
        'ArrayRef' => 'Str',
        'Bool'     => '',
        'Counter'  => '',
        'Flag'     => '',
        'HashRef'  => 'Str',
        'Int'      => 'Int',
        'Num'      => 'Num',
        'Str'      => 'Str',
        'SubCmd'   => 'Str',
    );

}

package OptArgs2::Arg {
    use OptArgs2::Arg_CI
      isa => 'OptArgs2::OptArgBase',
      has => {
        cmd      => { is => 'rw', weaken => 1, },
        fallthru => {},
        greedy   => {},
      };

    our @CARP_NOT = @OptArgs2::CARP_NOT;
    my %arg2getopt = (
        'Str'      => '=s',
        'Int'      => '=i',
        'Num'      => '=f',
        'ArrayRef' => '=s@',
        'HashRef'  => '=s%',
        'SubCmd'   => '=s',
    );

    sub BUILD {
        my $self = shift;

        OptArgs2->throw_error( 'Conflict',
            q{'default' and 'required' conflict} )
          if $self->required and defined $self->default;
    }

    sub name_alias_type_comment {
        my $self  = shift;
        my $value = shift;

        my $deftype = '';
        if ( defined $value ) {
            $deftype = '[' . $value . ']';
        }
        else {
            $deftype = $self->isa_name
              // $OptArgs2::OptArgBase::isa2name{ $self->isa }
              // OptArgs2->throw_error( 'InvalidIsa',
                'invalid isa type: ' . $self->isa );
        }

        my $comment = $self->comment;
        if ( $self->required ) {
            $comment .= ' ' if length $comment;
            $comment .= '*required*';
        }

        return $self->name, '', $deftype, $comment;
    }

}

package OptArgs2::Opt {
    use OptArgs2::Opt_CI
      isa => 'OptArgs2::OptArgBase',
      has => {
        alias   => {},
        hidden  => {},
        trigger => {},
      };

    our @CARP_NOT = @OptArgs2::CARP_NOT;

    my %isa2getopt = (
        'ArrayRef' => '=s@',
        'Bool'     => '!',
        'Counter'  => '+',
        'Flag'     => '!',
        'HashRef'  => '=s%',
        'Int'      => '=i',
        'Num'      => '=f',
        'Str'      => '=s',
    );

    sub new_from {
        my $proto = shift;
        my $ref   = {@_};

        # legacy interface
        if ( exists $ref->{ishelp} ) {
            delete $ref->{ishelp};
            $ref->{isa} //= OptArgs2::STYLE_HELP;
        }

        if ( $ref->{isa} =~ m/^Help/ ) {    # one of the STYLE_HELPs
            my $style = $ref->{isa};
            my $name  = $style;
            $name =~ s/([a-z])([A-Z])/$1-$2/g;
            $ref->{isa} = 'Counter';
            $ref->{name}    //= lc $name;
            $ref->{alias}   //= lc substr $ref->{name}, 0, 1;
            $ref->{comment} //= "print a $style message and exit";
            $ref->{trigger} //= sub {
                my $cmd = shift;
                my $val = shift;

                if ( $val == 1 ) {
                    OptArgs2->throw_usage( OptArgs2::STYLE_HELP,
                        $cmd->usage_string(OptArgs2::STYLE_HELP) );
                }
                elsif ( $val == 2 ) {
                    OptArgs2->throw_usage( OptArgs2::STYLE_HELPTREE,
                        $cmd->usage_string(OptArgs2::STYLE_HELPTREE) );
                }
                else {
                    OptArgs2->throw_usage(
                        'UnexpectedOptArg',
                        $cmd->usage_string(
                            OptArgs2::STYLE_USAGE,
                            qq{"--$ref->{name}" used too many times}
                        )
                    );
                }
            };
        }

        if ( !exists $isa2getopt{ $ref->{isa} } ) {
            return OptArgs2->throw_error( 'InvalidIsa',
                'invalid isa "%s" for opt "%s"',
                $ref->{isa}, $ref->{name} );
        }

        $ref->{getopt} = $ref->{name};
        if ( $ref->{name} =~ m/_/ ) {
            ( my $x = $ref->{name} ) =~ s/_/-/g;
            $ref->{getopt} .= '|' . $x;
        }
        $ref->{getopt} .= '|' . $ref->{alias} if $ref->{alias};
        $ref->{getopt} .= $isa2getopt{ $ref->{isa} };

        return $proto->new(%$ref);
    }

    sub name_alias_type_comment {
        my $self  = shift;
        my $value = shift;

        ( my $opt = $self->name ) =~ s/_/-/g;
        if ( $self->isa eq 'Bool' ) {
            if ($value) {
                $opt = 'no-' . $opt;
            }
            elsif ( not defined $value ) {
                $opt = '[no-]' . $opt;
            }
        }
        $opt = '--' . $opt;

        my $alias = $self->alias // '';
        if ( length $alias ) {
            $opt .= ',';
            $alias = '-' . $alias;
        }

        my $deftype = '';
        if ( defined $value ) {
            if ( $self->isa eq 'Flag' ) {
                $deftype = '(set)';
            }
            elsif ( $self->isa eq 'Bool' ) {
                $deftype = '(' . ( $value ? 'true' : 'false' ) . ')';
            }
            elsif ( $self->isa eq 'Counter' ) {
                $deftype = '(' . $value . ')';
            }
            else {
                $deftype = '[' . $value . ']';
            }
        }
        else {
            $deftype = $self->isa_name
              // $OptArgs2::OptArgBase::isa2name{ $self->isa }
              // OptArgs2->throw_error( 'InvalidIsa',
                'invalid isa type: ' . $self->isa );
        }

        my $comment = $self->comment;
        if ( $self->required ) {
            $comment .= ' ' if length $comment;
            $comment .= '*required*';
        }

        return $opt, $alias, $deftype, $comment;
    }

}

package OptArgs2::CmdBase {
    use overload
      bool     => sub { 1 },
      '""'     => sub { shift->class },
      fallback => 1;
    use Getopt::Long qw/GetOptionsFromArray/;
    use List::Util qw/max/;
    use OptArgs2::CmdBase_CI
      abstract => 1,
      has      => {
        abbrev  => { is       => 'rw', },
        args    => { default  => sub { [] }, },
        class   => { required => 1, },
        comment => { required => 1, },
        hidden  => {},
        optargs => {
            is      => 'rw',
            default => sub { [] }
        },
        opts   => { default => sub { [] }, },
        parent => { weaken  => 1, },
        _opts  => {
            default => sub { {} }
        },
        _args => {
            default => sub { {} }
        },
        _subcmds => {
            default => sub { {} }
        },
        show_default => { default => 0, },
        show_color   => { default => sub { -t STDERR }, },
        subcmds      => { default => sub { [] }, },
        _values      => { is      => 'rw' },
      },
      ;

    our @CARP_NOT = @OptArgs2::CARP_NOT;

    sub BUILD {
        my $self = shift;

        # legacy interface
        if ( 'CODE' eq ref $self->optargs ) {
            local $OptArgs2::CURRENT = $self;
            $self->optargs->();
            return;
        }

        while ( my ( $name, $args ) = splice @{ $self->optargs }, 0, 2 ) {
            if ( $args->{isa} =~ s/^--// ) {
                $self->add_opt(
                    name => $name,
                    %$args,
                );
            }
            else {
                $self->add_arg(
                    name => $name,
                    %$args,
                );
            }
        }
    }

    sub add_arg {
        my $self = shift;
        my $arg  = OptArgs2::Arg->new(
            cmd          => $self,
            show_default => $self->show_default,
            @_,
        );

        push( @{ $self->args }, $arg );
        $arg;
    }

    sub add_cmd {
        my $self   = shift;
        my $subcmd = OptArgs2::SubCmd->new(
            abbrev       => $self->abbrev,
            show_default => $self->show_default,
            @_,
            parent => $self,
        );

        OptArgs2->throw_error( 'CmdExists', 'cmd exists' )
          if exists $self->_subcmds->{ $subcmd->name };

        $self->_subcmds->{ $subcmd->name } = $subcmd;
        push( @{ $self->subcmds }, $subcmd );

        return $subcmd;
    }

    sub add_opt {
        my $self = shift;
        my $opt  = OptArgs2::Opt->new_from(
            show_default => $self->show_default,
            @_,
        );

        push( @{ $self->opts }, $opt );
        $opt;
    }

    sub parents {
        my $self = shift;
        return unless $self->parent;
        return ( $self->parent->parents, $self->parent );
    }

    sub parse {
        my $self   = shift;
        my $source = \@_;

        map {
            OptArgs2->throw_error( 'UndefOptArg',
                'optargs argument undefined!' )
              if !defined $_
        } @$source;

        my $source_hash = { map { %$_ } grep { ref $_ eq 'HASH' } @$source };
        $source = [ grep { ref $_ ne 'HASH' } @$source ];

        Getopt::Long::Configure(qw/pass_through no_auto_abbrev no_ignore_case/);

        my $reason;
        my $optargs = {};
        my @trigger;

        my $cmd = $self;

        # Start with the parents options
        my @opts = map { @{ $_->opts } } $cmd->parents, $cmd;
        my @args = @{ $cmd->args };

      OPTARGS: while ( @opts or @args ) {
            while ( my $try = shift @opts ) {
                my $result;
                my $name = $try->name;

                if ( exists $source_hash->{$name} ) {
                    $result = delete $source_hash->{$name};
                }
                else {
                    GetOptionsFromArray( $source, $try->getopt => \$result );
                }

                if ( defined($result) and my $t = $try->trigger ) {
                    push @trigger, [ $t, $name ];
                }

                if ( defined( $result //= $try->default ) ) {

                    if ( 'CODE' eq ref $result ) {
                        tie $optargs->{$name}, 'OptArgs2::CODEREF', $optargs,
                          $name,
                          $result;
                    }
                    else {
                        $optargs->{$name} = $result;
                    }
                }
                elsif ( $try->required ) {
                    $name =~ s/_/-/g;
                    $reason //=
                      [ 'OptRequired', qq{missing required option "--$name"} ];
                }
            }

            # Sub command check
            if ( @$source and my @subcmds = @{ $cmd->subcmds } ) {
                my $result = $source->[0];
                if ( $cmd->abbrev ) {
                    require Text::Abbrev;
                    my %abbrev =
                      Text::Abbrev::abbrev( map { $_->name } @subcmds );
                    $result = $abbrev{$result} // $result;
                }

                if ( exists $cmd->_subcmds->{$result} ) {
                    shift @$source;
                    $cmd = $cmd->_subcmds->{$result};
                    push( @opts, @{ $cmd->opts } );

                    # Ignoring any remaining arguments
                    @args = @{ $cmd->args };

                    next OPTARGS;
                }
            }

            while ( my $try = shift @args ) {
                my $result;
                my $name = $try->name;

                if (@$source) {
                    if (
                        #                        $try->isa ne 'SubCmd'
                        #                        and (
                        ( $source->[0] =~ m/^--\S/ )
                        or (
                            $source->[0] =~ m/^-\S/
                            and !(
                                $source->[0] =~ m/^-\d/
                                and (  $try->isa ne 'Num'
                                    or $try->isa ne 'Int' )
                            )
                        )
                      )

                      #                      )
                    {
                        my $o = shift @$source;
                        $reason //= [ 'OptUnknown', qq{unknown option "$o"} ];
                        last OPTARGS;
                    }

                    if ( $try->greedy ) {

                        # Interesting feature or not? "GREEDY... LATER"
                        # my @later;
                        # if ( @args and @$source > @args ) {
                        #     push( @later, pop @$source ) for @args;
                        # }
                        # Should also possibly check early for post-greedy arg,
                        # except they might be wanted for display
                        # purposes

                        if ( $try->isa eq 'ArrayRef' or $try->isa eq 'SubCmd' )
                        {
                            $result = [@$source];
                        }
                        elsif ( $try->isa eq 'HashRef' ) {
                            $result = {
                                map { split /=/, $_ }
                                  split /,/, @$source
                            };
                        }
                        else {
                            $result = "@$source";
                        }

                        $source = [];

                        #                        $source = \@later;
                    }
                    elsif ( $try->isa eq 'ArrayRef' ) {
                        $result = [ shift @$source ];
                    }
                    elsif ( $try->isa eq 'HashRef' ) {
                        $result =
                          { map { split /=/, $_ } split /,/, shift @$source };
                    }
                    else {
                        $result = shift @$source;
                    }

                    # TODO: type check using Param::Utils?
                }
                elsif ( exists $source_hash->{$name} ) {
                    $result = delete $source_hash->{$name};
                }

                if ( defined( $result //= $try->default ) ) {
                    $reason //= [
                        'SubCmdUnknown',
                        "unknown $name: "
                          . (
                            ( 'ARRAY' eq ref $result )  ? $result->[0]
                            : ( 'HASH' eq ref $result ) ? (
                                join ',',
                                map { "$_=$result->{$_}" } keys %$result
                              )
                            : $result
                          )
                      ]
                      if $try->isa eq 'SubCmd' and not $try->fallthru;

                    if ( 'CODE' eq ref $result ) {
                        tie $optargs->{$name}, 'OptArgs2::CODEREF', $optargs,
                          $name,
                          $result;
                    }
                    else {
                        $optargs->{$name} = $result;
                    }
                }
                elsif ( $try->required ) {
                    $reason //= ['ArgRequired'];
                }
            }
        }

        if (@$source) {
            $reason //= [
                'UnexpectedOptArg',
                "unexpected option(s) or argument(s): @$source"
            ];
        }
        elsif ( my @unexpected = keys %$source_hash ) {
            $reason //= [
                'UnexpectedHashOptArg',
                "unexpected HASH option(s) or argument(s): @unexpected"
            ];
        }

        $cmd->_values($optargs);

        map { $_->[0]->( $cmd, $optargs->{ $_->[1] } ) } @trigger;

        OptArgs2->throw_usage( $reason->[0],
            $cmd->usage_string( OptArgs2::STYLE_USAGE, $reason->[1] ) )
          if $reason;

        return ( $cmd->class, $optargs, ( $cmd->class . '.pm' ) =~ s!::!/!gr );
    }

    sub _usage_tree {
        my $self  = shift;
        my $depth = shift || 0;

        return [
            $depth, $self->usage_string(OptArgs2::STYLE_HELPSUMMARY),
            $self->comment
          ],
          map { $_->_usage_tree( $depth + 1 ) }
          sort { $a->name cmp $b->name } @{ $self->subcmds };
    }

    sub usage_string {
        my $self  = shift;
        my $style = shift || OptArgs2::STYLE_USAGE;
        my $error = shift // '';
        my $usage = '';

        if ( $style eq OptArgs2::STYLE_HELPTREE ) {
            my ( @w1, @w2 );
            my @items = map {
                $_->[0] = ' ' x ( $_->[0] * 3 );
                push @w1, length( $_->[1] ) + length( $_->[0] );
                push @w2, length $_->[2];
                $_
            } $self->_usage_tree;
            my ( $w1, $w2 ) = ( max(@w1), max(@w2) );

            my $paged  = OptArgs2::rows() < scalar @items;
            my $cols   = OptArgs2::cols();
            my $usage  = '';
            my $spacew = 3;
            my $space  = ' ' x $spacew;

            foreach my $i ( 0 .. $#items ) {
                my $overlap = $w1 + $spacew + $w2[$i] - $cols;
                if ( $overlap > 0 and not $paged ) {
                    $items[$i]->[2] =
                      sprintf '%-.' . ( $w2[$i] - $overlap - 3 ) . 's%s',
                      $items[$i]->[2], '.' x 3;
                }
                $usage .= sprintf "%-${w1}s${space}%-s\n",
                  $items[$i]->[0] . $items[$i]->[1],
                  $items[$i]->[2];
            }
            return $usage;
        }

        my @parents = $self->parents;
        my @args    = @{ $self->args };
        my @opts =
          sort { $a->name cmp $b->name } map { @{ $_->opts } } @parents,
          $self;

        my $optargs = $self->_values;

        # Summary line
        $usage .= join( ' ', map { $_->name } @parents ) . ' '
          if @parents and $style ne OptArgs2::STYLE_HELPSUMMARY;
        $usage .= $self->name;

        my ( $red, $grey, $reset ) = ( '', '', '' );
        if ( $self->show_color ) {
            $red   = "\e[0;31m";
            $grey  = "\e[1;30m";
            $reset = "\e[0m";

            # $red      = "\e[0;31m";
            # $yellow = "\e[0;33m";
        }

        $error = $red . 'error:' . $reset . ' ' . $error . "\n\n"
          if length $error;

        foreach my $arg (@args) {
            $usage .= ' ';
            $usage .= '[' unless $arg->required;
            $usage .= uc $arg->name;
            $usage .= '...' if $arg->greedy;
            $usage .= ']' unless $arg->required;
        }

        return $usage if $style eq OptArgs2::STYLE_HELPSUMMARY;

        $usage .= ' [OPTIONS...]' if @opts;
        $usage .= "\n";

        # Synopsis
        $usage .= "\n  Synopsis:\n    " . $self->comment . "\n"
          if $style eq OptArgs2::STYLE_HELP and length $self->comment;

        # Build arguments
        my @sargs;
        my @uargs;
        my $have_subcmd;

        if (@args) {
            my $i = 0;
          ARG: foreach my $arg (@args) {
                if ( $arg->isa eq 'SubCmd' ) {
                    my ( $n, undef, undef, $c ) =
                      $arg->name_alias_type_comment(
                        $arg->show_default
                        ? eval { $optargs->{ $arg->name } // undef }
                        : ()
                      );
                    push( @sargs, [ '  ' . ucfirst($n) . ':', $c ] );
                    my @sorted_subs =
                      map  { $_->[1] }
                      sort { $a->[0] cmp $b->[0] }
                      map  { [ $_->name, $_ ] }
                      grep { $style eq OptArgs2::STYLE_HELP or !$_->hidden }
                      @{ $arg->cmd->subcmds };

                    foreach my $subcmd (@sorted_subs) {
                        push(
                            @sargs,
                            [
                                '    '
                                  . $subcmd->usage_string(
                                    OptArgs2::STYLE_HELPSUMMARY),
                                $subcmd->comment
                            ]
                        );
                    }

                    $have_subcmd++;
                    last ARG;
                }
                else {
                    push( @uargs, [ '  Arguments:', '', '', '' ] ) if !$i;
                    my ( $n, $a, $t, $c ) = $arg->name_alias_type_comment(
                        $arg->show_default
                        ? eval { $optargs->{ $arg->name } // undef }
                        : ()
                    );
                    push( @uargs, [ '    ' . uc($n), $a, $t, $c ] );
                }
                $i++;
            }
        }

        # Build options
        my @uopts;
        if (@opts) {
            push( @uopts, [ "  Options:", '', '', '' ] );
            foreach my $opt (@opts) {
                next if $style ne OptArgs2::STYLE_HELP and $opt->hidden;
                my ( $n, $a, $t, $c ) = $opt->name_alias_type_comment(
                    $opt->show_default
                    ? eval { $optargs->{ $opt->name } // undef }
                    : ()
                );
                push( @uopts, [ '    ' . $n, $a, $t, $c ] );
            }
        }

        # Width calculation for args and opts combined
        my $w1 = max( 0,               map { length $_->[0] } @uargs, @uopts );
        my $w2 = max( 0,               map { length $_->[1] } @uargs, @uopts );
        my $w3 = max( 0,               map { length $_->[2] } @uargs, @uopts );
        my $w4 = max( 0,               map { length $_->[0] } @sargs );
        my $w5 = max( $w1 + $w2 + $w3, $w4 );

        my $format1 = "%-${w5}s  %s\n";
        my $format2 = "%-${w1}s %-${w2}s %-${w3}s";

        # Output Arguments
        if (@sargs) {
            $usage .= "\n";
            foreach my $row (@sargs) {
                $usage .= sprintf( $format1, @$row ) =~
                  s/^(\s+\w+\s)(.*?)(\s\s)/$1$grey$2$reset$3/r;
            }
        }

        if (@uargs) {
            $usage .= "\n";
            foreach my $row (@uargs) {
                my $l = pop @$row;
                $usage .= sprintf( $format1, sprintf( $format2, @$row ), $l );
            }
        }

        # Output Options
        if (@uopts) {
            $usage .= "\n";
            foreach my $row (@uopts) {
                my $l = pop @$row;
                $usage .= sprintf( $format1, sprintf( $format2, @$row ), $l );
            }
        }

        return $error . 'usage: ' . $usage . "\n";
    }

}

package OptArgs2::Cmd {
    use OptArgs2::Cmd_CI
      isa => 'OptArgs2::CmdBase',
      has => {
        name => {
            default => sub {
                my $x = $_[0]->class;

                # once legacy code goes move this into optargs()
                if ( $x eq 'main' ) {
                    require File::Basename;
                    File::Basename::basename($0),;
                }
                else {
                    $x =~ s/.*://;
                    $x =~ s/_/-/g;
                    $x;
                }
            },
        },
        no_help => { default => 0 },
      };

    our @CARP_NOT = @OptArgs2::CARP_NOT;

    sub BUILD {
        my $self = shift;

        $self->add_opt(
            isa          => OptArgs2::STYLE_HELP,
            show_default => 0,
          )
          unless $self->no_help
          or 'CODE' eq ref $self->optargs;    # legacy interface
    }
}

package OptArgs2::SubCmd {
    use OptArgs2::SubCmd_CI
      isa => 'OptArgs2::CmdBase',
      has => {
        name => {    # once legacy code goes move this into CmdBase
            init_arg => undef,
            default  => sub {
                my $x = $_[0]->class;
                $x =~ s/.*://;
                $x =~ s/_/-/g;
                $x;
            },
        },
        parent => { required => 1, },
      };

    our @CARP_NOT = @OptArgs2::CARP_NOT;
}

1;

__END__

=head1 NAME

OptArgs2 - command-line argument and option processor

=head1 VERSION

2.0.0 (2022-10-05)

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use OptArgs2;

    # For simple scripts use optargs()

    my $args = optargs(
        comment => 'script to paint things',
        optargs => [
            item => {
                isa      => 'Str',
                required => 1,
                comment  => 'the item to paint',
            },
            quiet => {
                isa     => '--Flag',
                alias   => 'q',
                comment => 'output nothing while working',
            },
        ],
    );

    print "Painting $args->{item}\n" unless $args->{quiet};

    # For complex multi-command applications
    # use cmd(), subcmd() and class_optargs()

    cmd 'My::app' => (
        comment => 'handy work app',
        optargs => [
            command => {
                isa      => 'Str',
                required => 1,
                comment  => 'the action to take',
            },
            quiet => {
                isa     => '--Flag',
                alias   => 'q',
                comment => 'output nothing while working',
            },
        ],
    );

    subcmd 'My::app::prepare' => (
        comment => 'prepare something',
        optargs => [
            item => {
                isa      => 'Str',
                required => 1,
                comment  => 'the item to prepare',
            },
        ],
    );

    subcmd 'My::app::paint' => (
        comment => 'paint something',
        optargs => [
            item => {
                isa      => 'Str',
                required => 1,
                comment  => 'the item to paint',
            },
            color => {
                isa     => '--Str',
                alias   => 'c',
                comment => 'your faviourite',
                default => 'blue',
            },
        ],
    );

    my ( $class, $opts, $file ) = class_optargs('My::app');
    require $file;
    $class->new($opts);

=head1 DESCRIPTION

B<OptArgs2> processes command line arguments, options, and subcommands
according to the following definitions:

=over

=item Command

A program run from the command line to perform a task.

=item Arguments

Arguments are positional parameters that pass information to a command.
Arguments can be optional, but they should not be confused with Options
below.

=item Options

Options are non-positional parameters that pass information to a
command.  They are generally not required to be present (hence the name
Option) but that is configurable. All options have a long form prefixed
by '--', and may have a single letter alias prefixed by '-'.

=item Subcommands

From the users point of view a subcommand is a special argument with
its own set of arguments and options.  However from a code authoring
perspective subcommands are often implemented as stand-alone programs,
called from the main script when the appropriate command arguments are
given.

=back

=head2 Differences with Earlier Releases

B<OptArgs2> version 2.0.0 was a large re-write to improve the API and
code.  Users upgrading from version 0.0.11 or B<OptArgs> need to be
aware of the following:

=over

=item API changes: optargs(), cmd(), subcmd()

Commands and subcommands are now explicitly defined using C<optargs()>,
C<cmd()> and C<subcmd()>. The arguments to C<optargs()> have changed to
match C<cmd()>.

=item Deprecated: arg(), opt(), fallback arguments

Optargs definitions must now be defined in an array reference
containing key/value pairs as shown in the synopsis. Fallback arguments
have been replaced with a new C<fallthru> option.

=item class_optargs() no longer loads the class

Users must specifically require the class if they want to use it
afterwards.

=item Bool options with no default display as "--[no-]bool"

A Bool option without a default is now displayed with the "[no-]"
prefix. What this means in practise is that many of your existing Bool
options most likely would become Flag options instead.

=back

=head2 Simple Commands

To demonstrate the simple use case (i.e. with no subcommands) lets put
the code from the synopsis in a file called C<paint> and observe the
following interactions from the shell:

    $ ./paint
    usage: paint ITEM [OPTIONS...]

      arguments:
        ITEM          the item to paint *required*

      options:
        --help,  -h   print a usage message and exit
        --quiet, -q   output nothing while working

The C<optargs()> function parses the command line (C<@ARGV>) according
to the included declarations and returns a single HASH reference.  If
the command is not called correctly then an exception is thrown
containing an automatically generated usage message as shown above.
Because B<OptArgs2> fully knows the valid arguments and options it can
detect a wide range of errors:

    $ ./paint wall Perl is great
    error: unexpected option or argument: Perl

So let's add that missing argument definition inside the optargs ref

    optargs => [
        ...
        message => {
            isa      => 'Str',
            comment  => 'the message to paint on the item',
            greedy   => 1,
        },
    ],

And then check the usage again:

    $ ./paint
    usage: paint ITEM [MESSAGE...] [OPTIONS...]

      arguments:
        ITEM          the item to paint, *required*
        MESSAGE       the message to paint on the item

      options:
        --help,  -h   print a usage message and exit
        --quiet, -q   output nothing while working

Note that optional arguments are surrounded by square brackets, and
that three dots (...) are postfixed to greedy arguments. A greedy
argument will swallow whatever is left on the comand line:

    $ ./paint wall Perl is great
    Painting on wall: "Perl is great".

Note that it probably doesn't make sense to define any more arguments
once you have a greedy argument. Let's imagine you now want the user to
be able to choose the colour if they don't like the default. An option
might make sense here, specified by a leading '--' type:

    optargs => [
        ...
        colour => {
            isa           => '--Str',
            default       => 'blue',
            comment       => 'the colour to use',
        },
    ],

This now produces the following usage output:

    usage: paint ITEM [MESSAGE...] [OPTIONS...]

      arguments:
        ITEM               the item to paint
        MESSAGE            the message to paint on the item

      options:
        --colour=STR, -c   the colour to use [blue]
        --help,       -h   print a usage message and exit
        --quiet,      -q   output nothing while working

=head2 Multi-Level Commands

Commands with subcommands require a different coding model and syntax
which we will describe over three phases:

=over

=item Definitions

Your command structure is defined using calls to the C<cmd()> and
C<subcmd()> functions. The first argument to both functions is the name
of the Perl class that implements the (sub-)command.

    cmd 'App::demo' => (
        comment => 'the demo command',
        optargs => [
            command => {
                isa      => 'SubCmd',
                required => 1,
                comment  => 'command to run',
            },
            quiet => {
                isa     => '--Flag',
                alias   => 'q',
                comment => 'run quietly',
            },
        ],
    );

    subcmd 'App::demo::foo' => (
        comment => 'demo foo',
        optargs => [
            action => {
                isa      => 'Str',
                required => 1,
                comment  => 'command to run',
            },
        ],
    );

    subcmd 'App::demo::bar' => (
        comment => 'demo bar',
        optargs => [
            baz => {
                isa => '--Counter',
                comment => '+1',
            },
        ],
    );

    # Command hierarchy for the above code,
    # printed by using '-h' twice:
    #
    #     demo COMMAND [OPTIONS...]
    #         demo foo ACTION [OPTIONS...]
    #         demo bar [OPTIONS...]

An argument of type 'SubCmd' is an explicit indication that subcommands
can occur in that position. The command hierarchy is based upon the
natural parent/child structure of the class names.  This definition can
be done in your main script, or in one or more separate packages or
plugins, as you like.

=item Parsing

The C<class_optargs()> function is called to parse the C<@ARGV> array
and call the appropriate C<arg()> and C<opt()> definitions as needed.
It's first argument is generally the top-level command name you used in
your first C<cmd()> call.

    my ($class, $opts, $file) = class_optargs('App::demo');
    require $file;
    printf "Running %s with %s\n", $class, Dumper($opts)
      unless $opts->{quiet};

The additional return value C<$class> is the name of the actual
(sub-)command to which the C<$opts> HASHref applies. Usage exceptions
are raised just the same as with the C<optargs()> function.

    error: unknown option "--invalid"

    usage: demo COMMAND [OPTIONS...]

        COMMAND       command to run
          bar           demo bar
          foo           demo foo

        --quiet, -q   run quietly

Note that options are inherited by subcommands.

=item Dispatch/Execution

Once you have the subcommand name and the option/argument hashref you
can either execute the action or dispatch to the appropriate
class/package as you like.

There are probably several ways to layout command classes when you have
lots of subcommands. Here is one way that seems to work for this
module's author.

=over

=item lib/App/demo.pm, lib/App/demo/subcmd.pm

I typically put the actual (sub-)command implementations in
F<lib/App/demo.pm> and F<lib/App/demo/subcmd.pm>. App::demo itself only
needs to exists if the root command does something. However I tend to
also make App::demo the base class for all subcommands so it is often a
non-trivial piece of code.

=item lib/App/demo/OptArgs.pm

App::demo::OptArgs is where I put all of my command definitions with
names that match the actual implementation modules.

    package App::demo::OptArgs;
    use OptArgs2;

    cmd 'App::demo' => {
        comment => 'the demo app',
        optargs => [
            # arg => 'Type, ...
            # opt => '--Type, ...
        ],
    }

The reason for keeping this separate from lib/App/demo.pm is speed of
loading. I don't want to have to load all of the modules that App::demo
itself uses just to find out that I called the command incorrectly.

=item bin/demo

The command script itself is then usually fairly short:

    #!/usr/bin/env perl
    use OptArgs2 'class_optargs';
    use App::demo::OptArgs;

    my ($class, $opts, $file) = class_optargs('App::demo');
    require $file;
    $class->new($opts)->run;

=back

=back

=head2 Argument Definition

Arguments are key/hashref pairs defined inside an optargs => arrayref
like so:

    optargs => [
        name => {
            isa      => 'Str',
            comment  => 'the file to parse',
            default  => '-',
            greedy   => 0,
            # required => 0 | 1,
            # fallthru => 0 | 1,
        },
    ],

Any underscores in the name (i.e. the optargs "key") are replaced by
dashes (-) for presentation and command-line parsing.  The following
parameters are accepted:

=over

=item comment

Required. Used to generate the usage/help message.

=item default

The value set when the argument is not given. Conflicts with the
'required' parameter.

If this is a subroutine reference it will be called with a hashref
containg all option/argument values after parsing the source has
finished.  The value to be set must be returned, and any changes to the
hashref are ignored.

=item greedy

If true the argument swallows the rest of the command line.

=item fallthru

Only relevant for SubCmd types. Normally, a "required" SubCmd will
raise an error when the given argument doesn't match any subcommand.
However, when fallthru is true the non-subcommand-matching argument
will be passed back to the C<class_optargs()> caller.

This is typically useful when you have aliases that you can expand into
real subcommands.

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

=item isa_name

When provided this parameter will be presented instead of the generic
presentation for the 'isa' parameter.

=item required

Set to a true value when the caller must specify this argument.
Conflicts with the 'default' parameter.

=item show_default

Boolean to indicate if the default value should be shown in usage
messages. Overrides the (sub-)command's C<show_default> setting.

=back


=head2 Option Definition

Options are defined like arguments inside an optargs => arrayref like
so, the key difference being the leading "--" for the "isa" parameter:

    optargs => [
        colour => {
            isa          => '--Str',
            alias        => 'c',
            comment      => 'the colour to paint',
            default      => 'blue',
            show_default => 1,
        },
    ],

Any underscores in the name (i.e. the optargs "key") are replaced by
dashes (-) for presentation and command-line parsing.  The following
parameters are accepted:

=over

=item alias

A single character alias.

=item comment

Required. Used to generate the usage/help message.

=item default

The value set when the option is not given. Conflicts with the
'required' parameter.

If this is a subroutine reference it will be called with a hashref
containing all option/argument values after parsing the source has
finished.  The value to be set must be returned, and any changes to the
hashref are ignored.

=item required

Set to a true value when the caller must specify this option. Conflicts
with the 'default' parameter.

=item hidden

When true this option will not appear in usage messages unless the
usage message is a help request.

This is handy if you have developer-only options, or options that are
very rarely used that you don't want cluttering up your normal usage
message.

=item isa

Required. Is mapped to a L<Getopt::Long> type according to the
following table:

    isa                             Getopt::Long
    ---                             ------------
     '--ArrayRef'                     's@'
     '--Flag'                         '!'
     '--Bool'                         '!'
     '--Counter'                      '+'
     '--HashRef'                      's%'
     '--Int'                          '=i'
     '--Num'                          '=f'
     '--Str'                          '=s'

=item isa_name

When provided this parameter will be presented instead of the generic
presentation for the 'isa' parameter.

=item show_default

Boolean to indicate if the default value should be shown in usage
messages. Overrides the (sub-)command's C<show_default> setting.

=item trigger

The trigger parameter lets you define a subroutine that is called after
processing before usage exceptions are raised.  This is primarily to
support --help or --version options which would typically override
usage errors.

    opt version => (
        isa     => 'Flag',
        alias   => 'V',
        comment => 'print version string and exit',
        trigger => sub {
            my ( $cmd, $value ) = @_;
            die "$cmd version $VERSION\n";
        }
    );

The trigger subref is passed two parameters: a OptArgs2::Cmd object and
the value (if any) of the option. The OptArgs2::Cmd object is an
internal one.

=back

=head2 Formatting of Usage Messages

Usage messages attempt to present as much information as possible to
the caller. Here is a brief overview of how the various types look
and/or change depending on things like defaults.

The presentation of Bool options in usage messages is as follows:

    Name        Type        Default         Presentation
    ----        ----        -------         ------------
    option      Bool        undef           --[no-]option
    option      Bool        true            --no-option
    option      Bool        false           --option
    option      Counter     *               --option

The Flag option type is like a Bool that can only be set to true or
left undefined. This makes sense for things such as C<--help> or
C<--version> for which you never need to see a "--no" prefix.

    Name        Type        Default         Presentation
    ----        ----        -------         ------------
    option      Flag        always undef    --option

Note that Flags also makes sense for "negative" options which will only
ever turn things off:

    Name        Type        Default         Presentation
    ----        ----        -------         ------------
    no_option   Flag        always undef    --no-option

    # In Perl
    no_foo => {
        isa     => '--Flag',
        comment => 'disable the foo feature',
    }

    # Then later do { } unless $opts->{no_foo}

The remaining types are presented as follows:

    Name        Type        isa_name        Presentation
    ----        ----        --------        ------------
    option      ArrayRef    -               --option Str
    option      HashRef     -               --option Str
    option      Int         -               --option Int
    option      Num         -               --option Num
    option      Str         -               --option Str
    option      *           XX              --option XX

Defaults TO BE COMPLETED.

=head1 FUNCTIONS

The following functions are exported by default.

=over

=item class_optargs( $class, [ @argv ] ) -> ($subclass, $opts, $file)

Parse @ARGV by default (or @argv when given) for the arguments and
options defined for command C<$class>.  C<@ARGV> will first be decoded
into UTF-8 (if necessary) from whatever L<I18N::Langinfo> says your
current locale codeset is.

Returns the following values:

=over

=item $subclass

The actual subcommand name that was matched by parsing the arguments.
This may be the same as C<$class>.

=item $opts

a hashref containing combined key/value pairs for options and
arguments.

=item $require_file

A file fragment (matching C<$subclass>) suitable for passing to
C<require>.

=back

Throws an error / usage exception object (typically
C<OptArgs2::Usage::*>) for missing or invalid arguments/options. Uses
L<OptArgs2::Pager> for Help output.

As an aid for testing, if the passed in argument C<@argv> (not @ARGV)
contains a HASH reference, the key/value combinations of the hash will
be added as options. An undefined value means a boolean option.

=item cols() -> Integer

Returns the terminal column width. Only exported on request.

=item cmd( $class, %parameters ) -> OptArgs2::Cmd

Define a top-level command identified by C<$class> which is typically a
Perl package name. The following parameters are accepted:

=for comment
=item name
A display name of the command. Optional - if it is not provided then the
last part of the command name is used is usage messages.

=over

=item abbrev

When set to true then subcommands can be abbreviated, up to their
shortest, unique values.

=item comment

A description of the command. Required.

=item optargs

An arrayref containing argument and option definitions. Note that
options are inherited by subcommands so you don't need to define them
again in child subcommands.

=item no_help

By default C<cmd()> automatically adds a default '--help' option. When
used once a standard help message is displayed. When used twice a help
tree showing subcommands is displayed. To disable the automatic help
set C<no_help> to a true value.

=item show_color

Boolean indicating if usage messages should use ANSI terminal color
codes to highlight different elements. True by default.

=item show_default

Boolean indicating if default values for options and arguments should
be shown in usage messages. Can be overriden by sub-commands, args and
opts. Off by default.

=for comment
By default this subref is only called on demand when the
C<class_optargs()> function sees arguments for that particular
subcommand. However for testing it is useful to know immediately if you
have an error. For this purpose the OPTARGS2_IMMEDIATE environment
variable can be set to trigger it at definition time.

=for comment
=item colour
If $OptArgs::COLOUR is a true value and "STDOUT" is connected to a
terminal then usage and error messages will be colourized using
terminal escape codes.

=for comment
=item sort
If $OptArgs::SORT is a true value then subcommands will be listed in
usage messages alphabetically instead of in the order they were
defined.

=for comment
=item usage
Valid for C<cmd()> only. A subref for generating a custom usage
message. See XXX befow for the structure this subref receives.

=back

=item optargs( @cmd_optargs ) -> HASHref

This is a convenience function for single-level commands that:

=over

=item * passes it's arguments directly to C<cmd()>,

=item * calls C<class_optargs()> to parse '@ARGV' and returns the
C<$opts> HASHref result directly.

=back

=item rows() -> Integer

Returns the terminal row height. Only exported on request.

=item subcmd( $subclass, %parameters ) -> OptArgs2::Cmd

Defines the subcommand C<$subclass> of a previously defined
(sub-)command.

Accepts the same parameters as C<cmd()> in addition to the following:

=over

=item hidden

Hide the existence of this subcommand in non-help usage messages.  This
is handy if you have developer-only or rarely-used commands that you
don't want cluttering up your normal usage message.

=back

=item usage( [$class] ) -> Str

Only exported on request, this function returns the usage string for
the command C<$class> or the class of the calling package (.e.g
"main").

=back

=head1 SEE ALSO

L<OptArgs2::Pager>, L<OptArgs2::StatusLine>, L<Getopt::Long>

This module used to duplicate itself on CPAN as L<Getopt::Args2>, but
as of the version 2 series that is no longer the case.

=head1 SUPPORT & DEVELOPMENT

This distribution is managed via github:

    https://github.com/mlawren/p5-OptArgs/

This distribution follows the semantic versioning model:

    http://semver.org/

Code is tidied up on Git commit using githook-perltidy:

    http://github.com/mlawren/githook-perltidy

=head1 AUTHOR

Mark Lawrence <nomad@null.net>

=head1 LICENSE

Copyright 2016-2022 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

