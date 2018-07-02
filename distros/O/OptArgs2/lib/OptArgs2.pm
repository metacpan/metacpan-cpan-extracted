# constants
sub OptArgs2::STYLE_SUMMARY { 1 }
sub OptArgs2::STYLE_NORMAL  { 2 }
sub OptArgs2::STYLE_FULL    { 3 }

package OptArgs2::Mo;
our $VERSION = '0.0.10';

BEGIN {
#<<< do not perltidy
# use Mo qw/required build default is import/;
#   The following line of code was produced from the previous line by
#   Mo::Inline version 0.39
no warnings;my$M=__PACKAGE__.'::';*{$M.Object::new}=sub{my$c=shift;my$s=bless{@_},$c;my%n=%{$c.::.':E'};map{$s->{$_}=$n{$_}->()if!exists$s->{$_}}keys%n;$s};*{$M.import}=sub{import warnings;$^H|=1538;my($P,%e,%o)=caller.'::';shift;eval"no Mo::$_",&{$M.$_.::e}($P,\%e,\%o,\@_)for@_;return if$e{M};%e=(extends,sub{eval"no $_[0]()";@{$P.ISA}=$_[0]},has,sub{my$n=shift;my$m=sub{$#_?$_[0]{$n}=$_[1]:$_[0]{$n}};@_=(default,@_)if!($#_%2);$m=$o{$_}->($m,$n,@_)for sort keys%o;*{$P.$n}=$m},%e,);*{$P.$_}=$e{$_}for keys%e;@{$P.ISA}=$M.Object};*{$M.'required::e'}=sub{my($P,$e,$o)=@_;$o->{required}=sub{my($m,$n,%a)=@_;if($a{required}){my$C=*{$P."new"}{CODE}||*{$M.Object::new}{CODE};no warnings 'redefine';*{$P."new"}=sub{my$s=$C->(@_);my%a=@_[1..$#_];if(!exists$a{$n}){require Carp;Carp::croak($n." required")}$s}}$m}};*{$M.'build::e'}=sub{my($P,$e)=@_;$e->{new}=sub{$c=shift;my$s=&{$M.Object::new}($c,@_);my@B;do{@B=($c.::BUILD,@B)}while($c)=@{$c.::ISA};exists&$_&&&$_($s)for@B;$s}};*{$M.'default::e'}=sub{my($P,$e,$o)=@_;$o->{default}=sub{my($m,$n,%a)=@_;exists$a{default}or return$m;my($d,$r)=$a{default};my$g='HASH'eq($r=ref$d)?sub{+{%$d}}:'ARRAY'eq$r?sub{[@$d]}:'CODE'eq$r?$d:sub{$d};my$i=exists$a{lazy}?$a{lazy}:!${$P.':N'};$i or ${$P.':E'}{$n}=$g and return$m;sub{$#_?$m->(@_):!exists$_[0]{$n}?$_[0]{$n}=$g->(@_):$m->(@_)}}};*{$M.'is::e'}=sub{my($P,$e,$o)=@_;$o->{is}=sub{my($m,$n,%a)=@_;$a{is}or return$m;sub{$#_&&$a{is}eq'ro'&&caller ne'Mo::coerce'?die$n.' is ro':$m->(@_)}}};my$i=\&import;*{$M.import}=sub{(@_==2 and not$_[1])?pop@_:@_==1?push@_,grep!/import/,@f:();goto&$i};@f=qw[required build default is import];use strict;use warnings;
#>>>
    $INC{'OptArgs2/Mo.pm'} = __FILE__;
}
1;

package OptArgs2::Result;
use overload
  bool     => sub { 1 },
  '""'     => 'as_string',
  fallback => 1;

our $VERSION = '0.0.10';

sub new {
    my $proto = shift;
    my $type  = shift || Carp::croak( $proto . '->new($TYPE,[@args])' );
    my $class = $proto . '::' . $type;

    {
        no strict 'refs';
        *{ $class . '::ISA' } = [$proto];
    }
    return bless [@_], $class;
}

sub as_string {
    ( my $type = ref( $_[0] ) ) =~ s/^OptArgs2::Result::(.*)/$1/;
    my @x = @{ $_[0] };
    if ( my $str = shift @x ) {
        return sprintf( "$str (%s)", @x, $type )
          unless $str =~ m/\n/;
        return sprintf( $str, @x );
    }
    return ref $_[0];
}

1;

package OptArgs2::Util;
use strict;
use warnings;
use OptArgs2::Mo;
use Carp ();

our $VERSION = '0.0.10';

sub result {
    my $self = shift;
    return OptArgs2::Result->new(@_);
}

sub croak {
    my $self   = shift;
    my $result = OptArgs2::Result->new(@_);

    {
        # Internal packages we don't want to see for user-related errors
        local @OptArgs2::Util::CARP_NOT = (
            qw/
              OptArgs2
              OptArgs2::Arg
              OptArgs2::Cmd
              OptArgs2::Opt
              OptArgs2::Util
              /
        );

        # Carp::croak has a bug when first argument is a reference
        Carp::croak( '', $result );
    }
}

1;

package OptArgs2::Arg;
use strict;
use warnings;
use OptArgs2::Mo;

our $VERSION = '0.0.10';

has cmd => (
    is       => 'rw',
    weak_ref => 1,
);

has comment => (
    is       => 'ro',
    required => 1,
);

# Can be re-set by CODEref defaults
has default => ( is => 'rw', );

has fallback => ( is => 'rw', );

has isa => ( required => 1, );

has getopt => ( is => 'rw', );

has greedy => ( is => 'ro', );

has name => (
    is       => 'ro',
    required => 1,
);

has required => ( is => 'ro', );

has show_default => ( is => 'ro', );

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
    $self->fallback( OptArgs2::Fallback->new( %{ $self->fallback } ) )
      if $self->fallback;
}

sub name_comment {
    my $self = shift;

    $self->default( $self->default->( {%$self} ) )
      if 'CODE' eq ref $self->default;

    my $comment = $self->comment;
    if ( $self->show_default && defined( my $value = $self->default ) ) {
        $comment .= ' [default: ' . $value . ']';
    }

    return $self->name, $comment;
}

1;

package OptArgs2::Fallback;
use strict;
use warnings;
use OptArgs2::Mo;

our $VERSION = '0.0.10';

extends 'OptArgs2::Arg';

has hidden => ( is => 'ro', );

1;

package OptArgs2::Opt;
use strict;
use warnings;
use OptArgs2::Mo;

our $VERSION = '0.0.10';

has alias => ( is => 'ro', );

has comment => (
    is       => 'ro',
    required => 1,
);

# Can be re-set by CODEref defaults
has default => ( is => 'rw', );

has getopt => ( is => 'ro', );

has hidden => ( is => 'ro', );

has isa => (
    is       => 'ro',
    required => 1,
);

has isa_name => ( is => 'rw', );

has name => (
    is       => 'ro',
    required => 1,
);

has trigger => ( is => 'ro', );

has show_default => ( is => 'ro', );

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

    if ( delete $ref->{ishelp} ) {
        return OptArgs2::Util->croak( 'Define::IshelpTrigger',
            'ishelp and trigger conflict' )
          if exists $ref->{trigger};

        $ref->{trigger} = sub { die shift->usage(OptArgs2::STYLE_FULL) };
    }

    if ( !exists $isa2getopt{ $ref->{isa} } ) {
        return OptArgs2::Util->croak( 'Define::IsaInvalid',
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

my %isa2name = (
    'ArrayRef' => 'STR',
    'Bool'     => '',
    'Counter'  => '',
    'Flag'     => '',
    'HashRef'  => 'STR',
    'Int'      => 'INT',
    'Num'      => 'NUM',
    'Str'      => 'STR',
);

sub name_alias_comment {
    my $self = shift;

    $self->default( $self->default->( {%$self} ) )
      if 'CODE' eq ref $self->default;

    ( my $opt = $self->name ) =~ s/_/-/g;
    if ( $self->isa eq 'Bool' ) {
        if ( $self->default ) {
            $opt = 'no-' . $opt;
        }
        elsif ( not defined $self->default ) {
            $opt = '[no-]' . $opt;
        }
    }
    elsif ( $self->isa ne 'Flag' and $self->isa ne 'Counter' ) {
        $opt .= '=' . ( $self->isa_name || $isa2name{ $self->isa } );
    }

    $opt = '--' . $opt;

    my $alias = $self->alias;
    if ( length $alias ) {
        $alias = '-' . $alias;
        $opt .= ',';
    }
    else {
        $alias = '';
    }

    my $comment = $self->comment;
    if ( $self->show_default && defined( my $value = $self->default ) ) {
        $value = $value ? 'true' : 'false' if $self->isa eq 'Bool';
        $comment .= ' [default: ' . $value . ']';
    }

    return $opt, $alias, $comment;
}

1;

package OptArgs2::Cmd;
use strict;
use warnings;
use overload
  bool     => sub { 1 },
  '""'     => sub { shift->class },
  fallback => 1;
use OptArgs2::Mo;
use List::Util qw/max/;
use Scalar::Util qw/weaken/;

our $VERSION = '0.0.10';

sub BUILD {
    my $self = shift;

    unless ( $self->name ) {
        ( my $x = $self->class ) =~ s/.*://;
        $x =~ s/_/-/g;
        $self->name($x);
    }
}

has abbrev => ( is => 'rw', );

has args => (
    is      => 'ro',
    default => sub { [] },
);

has class => (
    is       => 'ro',
    required => 1,
);

has comment => (
    is       => 'ro',
    required => 1,
);

has hidden => ( is => 'ro', );

has name => ( is => 'rw', );

has optargs => ( is => 'rw', );

has opts => (
    is      => 'ro',
    default => sub { [] },
);

has parent => (
    is       => 'rw',
    weak_ref => 1,
);

has subcmds => (
    is      => 'ro',
    default => sub { [] },
);

has usage_style => (
    is      => 'rw',
    default => OptArgs2::STYLE_NORMAL,
);

our $CURRENT;

sub add_arg {
    my $self = shift;
    my $arg  = shift;

    push( @{ $self->args }, $arg );
    $arg->cmd($self);

    # A hack until Mo gets weaken support
    weaken $arg->{cmd};
    return $arg;
}

sub add_cmd {
    my $self   = shift;
    my $subcmd = shift;

    push( @{ $self->subcmds }, $subcmd );
    $subcmd->parent($self);
    $subcmd->abbrev( $self->abbrev );

    # A hack until Mo gets weaken support
    weaken $subcmd->{parent};
    return $subcmd;
}

sub add_opt {
    push( @{ $_[0]->opts }, $_[1] );
    $_[1];
}

sub parents {
    my $self = shift;
    return unless $self->parent;
    return ( $self->parent->parents, $self->parent );
}

sub run_optargs {
    my $self = shift;
    return unless ref $self->optargs eq 'CODE';
    local $CURRENT = $self;
    $self->optargs->();
    $self->optargs(undef);
}

sub usage {
    my $self = shift;
    my $style = shift || $self->usage_style;

    $self->run_optargs;

    my $usage   = '';
    my @parents = $self->parents;
    my @args    = @{ $self->args };
    my @opts    = sort { $a->name cmp $b->name } map { @{ $_->opts } } @parents,
      $self;

    # Summary line
    $usage .= join( ' ', map { $_->name } @parents ) . ' ' if @parents;
    $usage .= $self->name;

    foreach my $arg (@args) {
        $usage .= ' ';
        $usage .= '[' unless $arg->required;
        $usage .= uc $arg->name;
        $usage .= '...' if $arg->greedy;
        $usage .= ']' unless $arg->required;
    }

    $usage .= ' [OPTIONS...]' if @opts;
    $usage .= "\n";

    return OptArgs2::Util->result( 'Usage::Summary', $usage )
      if $style == OptArgs2::STYLE_SUMMARY;

    # Synopsis
    $usage .= "\n  Synopsis:\n    " . $self->comment . "\n"
      if $style == OptArgs2::STYLE_FULL and length $self->comment;

    # Build arguments
    my @uargs;
    my $have_subcmd;

    if (@args) {
        my $i = 0;
        foreach my $arg (@args) {
            if ( $arg->isa eq 'SubCmd' ) {
                push( @uargs,
                    [ '  ' . ucfirst( $arg->name ) . ':', $arg->comment ] );
                my @sorted_subs =
                  sort { $a->name cmp $b->name }
                  grep { $style == OptArgs2::STYLE_FULL or !$_->hidden }
                  @{ $arg->cmd->subcmds },
                  $arg->fallback ? $arg->fallback : ();

                my $prefix = length( $arg->comment ) ? '  ' : '';
                foreach my $subcmd (@sorted_subs) {
                    push(
                        @uargs,
                        [
                            '    '
                              . (
                                ref $subcmd eq 'OptArgs2::Fallback'
                                ? uc( $subcmd->name )
                                : $subcmd->name
                              ),
                            $prefix . $subcmd->comment
                        ]
                    );
                }

                $have_subcmd++;
            }
            elsif ( !$i ) {
                push( @uargs, [ '  Arguments:', '' ] );
                my ( $n, $c ) = $arg->name_comment;
                push( @uargs, [ '    ' . uc($n), $c ] );
            }
            else {
                my ( $n, $c ) = $arg->name_comment;
                push( @uargs, [ '    ' . uc($n), $c ] ) if length($c);
            }
            $i++;
        }
    }

    my @sargs;
    if ( !$have_subcmd ) {
        my @sorted_subs =
          sort { $a->name cmp $b->name }
          grep { $style == OptArgs2::STYLE_FULL or !$_->hidden }
          @{ $self->subcmds };

        if (@sorted_subs) {
            push( @sargs, [ '  Sub-Commands:', '' ] );

            foreach my $subcmd (@sorted_subs) {
                push( @sargs, [ '    ' . $subcmd->name, $subcmd->comment ] );
            }
        }
    }

    # Build options
    my @uopts;
    if (@opts) {
        push( @uopts, [ "  Options:", '', '' ] );
        foreach my $opt (@opts) {
            next if $style != OptArgs2::STYLE_FULL and $opt->hidden;
            my ( $n, $a, $c ) = $opt->name_alias_comment;
            push( @uopts, [ '    ' . $n, $a, $c ] );
        }

        # Width calculation: turn 3 option fields into 2:
        my $w1 = max( map { length $_->[0] } @uopts );
        my $fmt = '%-' . $w1 . "s %s";

        @uopts = map { [ sprintf( $fmt, $_->[0], $_->[1] ), $_->[2] ] } @uopts;
    }

    # Width calculation for args and opts combined
    my $w1 = max( map { length $_->[0] } @uargs, @sargs, @uopts );
    my $format = '%-' . $w1 . "s   %s\n";

    # Output Arguments
    if (@uargs) {
        $usage .= "\n";
        foreach my $row (@uargs) {
            $usage .= sprintf( $format, @$row );
        }
    }

    # Output Options
    if (@uopts) {
        $usage .= "\n";
        foreach my $row (@uopts) {
            $usage .= sprintf( $format, @$row );
        }
    }

    # Output Subcommands
    if (@sargs) {
        $usage .= "\n";
        foreach my $row (@sargs) {
            $usage .= sprintf( $format, @$row );
        }
    }

    return OptArgs2::Util->result( 'Usage::Full', 'usage: ' . $usage . "\n" );
}

sub _usage_tree {
    my $self  = shift;
    my $style = shift;
    my $depth = shift || '';

    ( my $str = $self->usage($style) ) =~ s/^/$depth/gsm;

    foreach my $subcmd ( sort { $a->name cmp $b->name } @{ $self->subcmds } ) {
        $str .= $subcmd->_usage_tree( $style, $depth . '    ' );
    }

    return $str;
}

sub usage_tree {
    my $self = shift;
    my $style = shift || OptArgs2::STYLE_SUMMARY;
    return OptArgs2::Util->result( 'Usage::Tree', $self->_usage_tree($style) );
}

1;

package OptArgs2;
use 5.010;
use strict;
use warnings;
use Encode qw/decode/;
use Getopt::Long qw/GetOptionsFromArray/;
use Exporter qw/import/;
use OptArgs2::Mo;

our $VERSION   = '0.0.10';
our @EXPORT    = (qw/arg class_optargs cmd opt optargs subcmd/);
our @EXPORT_OK = (qw/usage/);

my %command;

sub _default_command {
    my $caller = shift;
    require File::Basename;
    cmd( $caller, name => File::Basename::basename($0), comment => '', );
}

sub arg {
    my $name = shift;

    $OptArgs2::Cmd::CURRENT //= _default_command(caller);
    $OptArgs2::Cmd::CURRENT->add_arg( OptArgs2::Arg->new( name => $name, @_ ) );
}

sub class_optargs {
    my $class = shift
      || OptArgs2::Util->croak( 'Parse::CmdRequired',
        'class_optargs($CMD,[@argv])' );

    my $cmd = $command{$class}
      || OptArgs2::Util->croak( 'Parse::CmdNotFound',
        'command class not found: ' . $class );

    my $source      = \@_;
    my $source_hash = {};

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

    map {
        OptArgs2::Util->croak( 'Parse::Undefined',
            '_optargs argument undefined!' )
          if !defined $_
    } @$source;

    Getopt::Long::Configure(qw/pass_through no_auto_abbrev no_ignore_case/);

    my $optargs = {};
    my @coderef_default_keys;
    my @trigger;
    my @errors;

    # Start with the parents options
    map { $_->run_optargs } $cmd->parents, $cmd;
    my @opts = map { @{ $_->opts } } $cmd->parents, $cmd;
    my @args = @{ $cmd->args };

  OPTARGS: while ( @opts or @args ) {

        while ( my $try = shift @opts ) {
            my $result;
            if ( exists $source_hash->{ $try->name } ) {
                $result = delete $source_hash->{ $try->name };
            }
            else {
                GetOptionsFromArray( $source, $try->getopt => \$result );
            }

            if ( defined $result ) {
                $optargs->{ $try->name } = $result;
                if ( my $ref = $try->trigger ) {
                    push( @trigger, $ref, $result );
                }
            }
            elsif ( defined $try->default ) {
                push( @coderef_default_keys, $try->name )
                  if ref $try->default eq 'CODE';
                $optargs->{ $try->name } = $result = $try->default;
            }
        }

        # Sub command check
        if ( @$source and my @subcmds = $cmd->subcmds ) {
            my $result = $source->[0];
            if ( $cmd->abbrev ) {
                require Text::Abbrev;
                my %abbrev = Text::Abbrev::abbrev( map { $_->name } @subcmds );
                $result = $abbrev{$result} // $result;
            }

            ( my $new_class = $class . '::' . $result ) =~ s/-/_/g;

            if ( exists $command{$new_class} ) {
                shift @$source;
                $class = $new_class;
                $cmd   = $command{$new_class};
                $cmd->run_optargs;
                push( @opts, @{ $cmd->opts } );

                # Ignoring any remaining arguments
                @args = @{ $cmd->args };

                next OPTARGS;
            }
        }

        while ( my $try = shift @args ) {
            my $result;
            if (@$source) {

                push(
                    @errors,
                    OptArgs2::Util->result(
                        'Parse::UnknownOption',
                        qq{error: unknown option "$source->[0]"\n\n}
                          . $cmd->usage
                    )
                ) if $source->[0] =~ m/^--\S/;

                push(
                    @errors,
                    OptArgs2::Util->result(
                        'Parse::UnknownOption',
                        qq{error: unknown option "$source->[0]"\n\n}
                          . $cmd->usage
                    )
                  )
                  if $source->[0] =~ m/^-\S/
                  and !(
                    $source->[0] =~ m/^-\d/ and ( $try->isa ne 'Num'
                        or $try->isa ne 'Int' )
                  );

                if ( $try->greedy ) {
                    my @later;
                    if ( @args and @$source > @args ) {
                        push( @later, pop @$source ) for @args;
                    }

                    if ( $try->isa eq 'ArrayRef' ) {
                        $result = [@$source];
                    }
                    elsif ( $try->isa eq 'HashRef' ) {
                        $result = { map { split /=/, $_ } @$source };
                    }
                    else {
                        $result = "@$source";
                    }

                    shift @$source while @$source;
                    push( @$source, @later );
                }
                else {
                    if ( $try->isa eq 'ArrayRef' ) {
                        $result = [ shift @$source ];
                    }
                    elsif ( $try->isa eq 'HashRef' ) {
                        $result = { split /=/, shift @$source };
                    }
                    else {
                        $result = shift @$source;
                    }
                }

                # TODO: type check using Param::Utils?
            }
            elsif ( exists $source_hash->{ $try->name } ) {
                $result = delete $source_hash->{ $try->name };
            }
            elsif ( $try->required ) {
                push( @errors,
                    OptArgs2::Util->result( 'Parse::ArgRequired', $cmd->usage )
                );
                next;
            }

            if ( defined $result ) {
                $optargs->{ $try->name } = $result;
            }
            elsif ( defined $try->default ) {
                push( @coderef_default_keys, $try->name )
                  if ref $try->default eq 'CODE';
                $optargs->{ $try->name } = $result = $try->default;
            }

        }
    }

    while ( my $trigger = shift @trigger ) {
        $trigger->( $cmd, shift @trigger );
    }

    if (@errors) {
        die $errors[0];
    }
    elsif (@$source) {
        die OptArgs2::Util->result( 'Parse::UnexpectedOptArgs',
            "error: unexpected option(s) or argument(s): @$source\n\n"
              . $cmd->usage );
    }
    elsif ( my @unexpected = keys %$source_hash ) {
        die OptArgs2::Util->result( 'Parse::UnexpectedHashOptArgs',
            "error: unexpected HASH options or arguments: @unexpected\n\n"
              . $cmd->usage );
    }

    # Re-calculate the default if it was a subref
    foreach my $key (@coderef_default_keys) {
        $optargs->{$key} = $optargs->{$key}->( {%$optargs} );
    }

    return ( $cmd->class, $optargs );
}

sub cmd {
    my $class = shift || Carp::confess('cmd($CLASS,@args)');

    OptArgs2::Util->croak( 'Define::CommandDefined',
        "command already defined: $class" )
      if exists $command{$class};

    my $cmd = OptArgs2::Cmd->new( class => $class, @_ );
    $command{$class} = $cmd;

    # If this check is not performed we end up adding ourselves
    if ( $class =~ m/:/ ) {
        ( my $parent_class = $class ) =~ s/(.*)::/$1/;
        if ( exists $command{$parent_class} ) {
            $command{$parent_class}->add_cmd($cmd);
        }
    }

    return $cmd;
}

sub opt {
    my $name = shift;

    $OptArgs2::Cmd::CURRENT //= _default_command(caller);
    $OptArgs2::Cmd::CURRENT->add_opt(
        OptArgs2::Opt->new_from( name => $name, @_ ) );
}

sub optargs {
    my ( undef, $opts ) = class_optargs( scalar(caller), @_ );
    return $opts;
}

sub subcmd {
    my $class =
      shift || OptArgs2::Util->croak( 'Define::Usage', 'subcmd($CLASS,%args)' );

    OptArgs2::Util->croak( 'Define::SubcommandDefined',
        "subcommand already defined: $class" )
      if exists $command{$class};

    OptArgs2::Util->croak( 'Define::SubcmdNoParent',
        "no '::' in class '$class' - must have a parent" )
      unless $class =~ m/::/;

    ( my $parent_class = $class ) =~ s/(.*)::.*/$1/;

    OptArgs2::Util->croak( 'Define::ParentNotFound',
        "parent class not found: " . $parent_class )
      unless exists $command{$parent_class};

    $command{$class} = OptArgs2::Cmd->new(
        class => $class,
        @_
    );

    return $command{$parent_class}->add_cmd( $command{$class} );
}

sub usage {
    my $class = shift || Carp::confess('usage($CLASS,[$style])');
    my $style = shift;

    Carp::confess("command not found: $class")
      unless exists $command{$class};

    return $command{$class}->usage($style);
}

1;

__END__

=head1 NAME

OptArgs2 - command-line argument and option processor

=head1 VERSION

0.0.10 (2018-06-26)

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use OptArgs2;

    arg item => (
        isa      => 'Str',
        required => 1,
        comment  => 'the item to paint',
    );

    opt quiet => (
        isa     => 'Flag',
        alias   => 'q',
        comment => 'output nothing while working',
    );

    my $ref = optargs;

    print "Painting $ref->{item}\n" unless $ref->{quiet};


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

B<OptArgs2> is a re-write of the original L<OptArgs> module with a
cleaner code base and improved API. It should be preferred over
L<OptArgs> for new projects however L<OptArgs> is not likely to
disappear from CPAN anytime soon.  Users converting to B<OptArgs2> from
L<OptArgs> need to be aware of the following:

=over

=item Obvious API changes: cmd(), subcmd()

Commands and subcommands must now be explicitly defined using C<cmd()>
and C<subcmd()>.

=item class_optargs() no longer loads the class

Users must specifically require the class if they want to use it
afterwards:

    my ($class, $opts) = class_optargs('App::demo');
    eval "require $class" or die $@; # new requirement

=item Bool options with no default display as "--[no-]bool"

A Bool option without a default is now displayed with the "[no-]"
prefix. What this means in practise is that many of your existing Bool
options should likely become Flag options instead.

=back

=head2 Simple Commands

To demonstrate the simple use case (i.e. with no subcommands) lets put
the code from the synopsis in a file called C<paint> and observe the
following interactions from the shell:

    $ ./paint
    usage: paint ITEM [OPTIONS...]

      arguments:
        ITEM          the item to paint

      options:
        --quiet, -q   output nothing while working

The C<optargs()> function parses the command line according to the
previous C<opt()> and C<arg()> declarations and returns a single HASH
reference.  If the command is not called correctly then an exception is
thrown containing an automatically generated usage message as shown
above.  Because B<OptArgs2> fully knows the valid arguments and options
it can detect a wide range of errors:

    $ ./paint wall message
    error: unexpected option or argument: red

So let's add that missing argument definition:

    arg message => (
        isa      => 'Str',
        comment  => 'the message to paint on the item',
        greedy   => 1,
    );

And then check the usage again:

    $ ./paint
    usage: paint ITEM [MESSAGE...] [OPTIONS...]

      arguments:
        ITEM          the item to paint
        MESSAGE       the message to paint on the item

      options:
        --quiet, -q   output nothing while working

Note that optional arguments are surrounded by square brackets, and
that three dots (...) are postfixed to greedy arguments. A greedy
argument will swallow whatever is left on the comand line:

    $ ./paint wall Perl is great
    Painting on wall: "Perl is great".

Note that it probably doesn't make sense to define any more arguments
once you have a greedy argument. Let's imagine you now want the user to
be able to choose the colour if they don't like the default. An option
might make sense here:

    opt colour => (
        isa           => 'Str',
        default       => 'blue',
        show_default  => 1,
        comment       => 'the colour to use',
    );

This now produces the following usage output:

    usage: paint ITEM [MESSAGE...] [OPTIONS...]

      arguments:
        ITEM               the item to paint
        MESSAGE            the message to paint on the item
 
      options:
        --colour=STR, -c   the colour to use [default: blue]
        --quiet,      -q   output nothing while working

The command line is parsed first for arguments, then for options, in
the same order in which they are defined. This probably only of
interest if you are using trigger actions on your options (see
FUNCTIONS below for details).

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
        optargs => sub {
            arg command => (
                isa      => 'SubCmd',
                required => 1,
                comment  => 'command to run',
            );

            opt quiet => (
                isa     => 'Flag',
                alias   => 'q',
                comment => 'run quietly',
            );
        },
    );

    subcmd 'App::demo::foo' => (
        comment => 'demo foo',
        optargs => sub {
            arg action => (
                isa      => 'Str',
                required => 1,
                comment  => 'command to run',
            );
        },
    );

    subcmd 'App::demo::bar' => (
        comment => 'demo bar',
        optargs => sub {
            opt baz => (
                isa => 'Counter',
                comment => '+1',
            );
        },
    );

    # Command hierarchy for the above code:
    # demo COMMAND [OPTIONS...]
    #     demo foo ACTION [OPTIONS...]
    #     demo bar [OPTIONS...]

An argument of type 'SubCmd' is an explicit indication that subcommands
can occur in that position. The command hierarchy is based upon the
natural parent/child structure of the class names.  This definition can
be done in your main script, or in one or more separate packages or
plugins, as you like.

=item Parsing

The C<class_optargs()> function is called instead of C<optargs()> to
parse the C<@ARGV> array and call the appropriate C<arg()> and C<opt()>
definitions as needed. It's first argument is generally the top-level
command name you used in your first C<cmd()> call.

    my ($class, $opts) = class_optargs('App::demo');

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

    cmd 'App::demo' => (
        comment => 'the demo app',
        optargs => sub {
            #...
        },
    )

The reason for keeping this separate from lib/App/demo.pm is speed of
loading. I don't want to have to load all of the modules that App::demo
itself uses just to find out that I called the command incorrectly.

=item bin/demo

The command script itself is then usually fairly short:

    #!/usr/bin/env perl
    use OptArgs2 'class_optargs';
    use App::demo::OptArgs;

    my ($class, $opts) = class_optargs('App::demo');
    eval "require $class" or die $@;
    $class->new->run($opts);

The above does nothing more than load the definitions from
App::demo::OptArgs, obtain the command name and options hashref, and
then loads the appropriate package to run the command.

=back

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
    opt no_foo => (
        isa     => 'Flag',
        comment => 'disable the foo feature',
    );

    # Then later do { } unless $opts->{no_foo}

The remaining types are presented as follows:

    Name        Type        isa_name        Presentation
    ----        ----        --------        ------------
    option      ArrayRef    -               --option=STR
    option      HashRef     -               --option=STR
    option      Int         -               --option=INT
    option      Num         -               --option=NUM
    option      Str         -               --option=STR
    option      *           XX              --option=XX

Defaults TO BE COMPLETED.

=head1 FUNCTIONS

The following functions are exported by default.

=over

=item arg( $name, %parameters )

Define a command argument, for example:

    arg name => (
        comment  => 'the file to parse',
        default  => '-',
        greedy   => 0,
        isa      => 'Str',
        required => 1,
    );

The C<arg()> function accepts the following parameters:

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

=item fallback

A hashref containing an argument definition for the event that a
subcommand match is not found. This parameter is only valid when C<isa>
is a C<SubCmd>. The hashref must contain "isa", "name" and "comment"
key/value pairs, and may contain a "greedy" key/value pair.

This is generally useful when you want to calculate a command alias
from a configuration file at runtime, or otherwise run commands which
don't easily fall into the OptArgs2 subcommand model.

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

=item required

Set to a true value when the caller must specify this argument.
Conflicts with the 'default' parameter.

=item show_default

If set to a true value then usage messages will show the default value.

=back

=item class_optargs( $class, [ @argv ] ) -> ($subclass, $opts)

Parse @ARGV by default (or @argv when given) for the arguments and
options defined for command C<$class>.  C<@ARGV> will first be decoded
into UTF-8 (if necessary) from whatever L<I18N::Langinfo> says your
current locale codeset is.

Throws an error / usage exception object (typically C<OptArgs2::Usage>)
for missing or invalid arguments/options.

Returns the following two values:

=over

=item $subclass

The actual subcommand name that was matched by parsing the arguments.
This may be the same as C<$class>.

=item $opts

a hashref containing key/value pairs for options and arguments
I<combined>.

=back

As an aid for testing, if the passed in argument C<@argv> (not @ARGV)
contains a HASH reference, the key/value combinations of the hash will
be added as options. An undefined value means a boolean option.

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

A subref containing calls to C<arg()> and C<opt>. Note that options are
inherited by subcommands so you don't need to define them again in
child subcommands.

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

=item opt( $name, %parameters )

Define a command option, for example:

    opt colour => (
        alias        => 'c',
        comment      => 'the colour to paint',
        default      => 'blue',
        show_default => 1,
        isa          => 'Str',
    );

Any underscores in C<$name> are be replaced by dashes (-) for
presentation and command-line parsing.  The C<arg()> function accepts
the following parameters:

=over

=item alias

A single character alias.

=item comment

Required. Used to generate the usage/help message.

=item default

The value set when the option is not used.

If this is a subroutine reference it will be called with a hashref
containg all option/argument values after parsing the source has
finished.  The value to be set must be returned, and any changes to the
hashref are ignored.

=item hidden

When true this option will not appear in usage messages unless the
usage message is a help request.

This is handy if you have developer-only options, or options that are
very rarely used that you don't want cluttering up your normal usage
message.

=item isa

Required. Is mapped to a L<Getopt::Long> type according to the
following table:

    isa              Getopt::Long
    ---              ------------
     'ArrayRef'      's@'
     'Flag'          '!'
     'Bool'          '!'
     'Counter'       '+'
     'HashRef'       's%'
     'Int'           '=i'
     'Num'           '=f'
     'Str'           '=s'

=item isa_name

When provided this parameter will be presented instead of the generic
presentation for the 'isa' parameter.

=item ishelp

When true creates a trigger parameter that generates a usage message
exception. In other words it is just a shortcut for the following:

    opt help => (
        isa     => 'Flag',
        alias   => 'h',
        comment => 'print help message and exit',
        trigger => sub {
            my ( $cmd, $value ) = @_;
            die $cmd->usage(OptArgs2::STYLE_FULL);
        }
    );

Note that this option conflicts with the trigger parameter.

=item show_default

If set to a true value then usage messages will show the default value.

=item trigger

The trigger parameter lets you define a subroutine that is called
I<immediately> as soon as the option presence is detected. This is
primarily to support --help or --version options which typically don't
need the full command line to be processed before generating a
response.

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
internal one, but one public interface is has (in addition to the
usage() method described in 'ishelp' above) is the usage_tree() method
which gives a usage overview of all subcommands in the command
hierarchy.

    opt usage_tree => (
        isa     => 'Flag',
        alias   => 'U',
        comment => 'print usage tree and exit',
        trigger => sub {
            my ( $cmd, $value ) = @_;
            die $cmd->usage_tree;
        }
    );

    # demo COMMAND [OPTIONS...]
    #     demo foo ACTION [OPTIONS...]
    #     demo bar [OPTIONS...]

=back

=item optargs( [@argv] ) -> HASHref

Parse @ARGV by default (or @argv when given) for the arguments and
options defined for the I<default global> command. Argument decoding
and exceptions are the same as for C<class_optargs>, but this function
returns only the combined argument/option values HASHref.

=item subcmd( $class, %parameters ) -> OptArgs2::Cmd

Defines a subcommand identified by C<$class> which must include the
name of a previously defined (sub)command + '::'.

Accepts the same parameters as C<cmd()> in addition to the following:

=over

=item hidden

Hide the existence of this subcommand in usage messages created with
OptArgs2::STYLE_NORMAL.  This is handy if you have developer-only or
rarely-used commands that you don't want cluttering up your normal
usage message.

=back

=item usage( $class, [STYLE] ) -> Str

Only exported on request, this function returns the usage string for
the command C<$class>.

=back

=head1 SEE ALSO

L<Getopt::Long>

This module is duplicated on CPAN as L<Getopt::Args2>, to cover both
its original name and yet still be found in the mess that is Getopt::*.

=head1 SUPPORT & DEVELOPMENT

This distribution is managed via github:

    https://github.com/mlawren/p5-OptArgs2/tree/devel

This distribution follows the semantic versioning model:

    http://semver.org/

Code is tidied up on Git commit using githook-perltidy:

    http://github.com/mlawren/githook-perltidy

=head1 AUTHOR

Mark Lawrence <nomad@null.net>

=head1 LICENSE

Copyright 2016 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

