package OptArgs2::CmdBase;
use strict;
use warnings;

use overload
  bool     => sub { 1 },
  '""'     => sub { shift->class },
  fallback => 1;

use Getopt::Long qw/GetOptionsFromArray/;
use List::Util   qw/max/;
use OptArgs2::Arg;
use OptArgs2::Opt;
use OptArgs2::SubCmd;

### START Class::Inline ### v0.0.1 Wed Dec  3 10:44:51 2025
require Scalar::Util;
require Carp;
our ( @_CLASS, $_FIELDS, %_NEW );

sub _NEW {
    CORE::state $fix_FIELDS = do {
        $_FIELDS = { @_CLASS > 1 ? @_CLASS : %{ $_CLASS[0] } };
        $_FIELDS = $_FIELDS->{'FIELDS'} if exists $_FIELDS->{'FIELDS'};
    };
    if ( my @missing = grep { not exists $_[0]->{$_} } 'class', 'comment' ) {
        Carp::croak( 'OptArgs2::CmdBase required initial argument(s): '
              . join( ', ', @missing ) );
    }
    Scalar::Util::weaken( $_[0]{'parent'} )
      if exists $_[0]{'parent'} && ref $_[0]{'parent'};
    map { delete $_[1]->{$_} } '_subcmds', '_values', 'abbrev', 'args',
      'class', 'comment', 'hidden', 'optargs', 'opts', 'parent', 'show_color',
      'show_default', 'subcmds';
}

sub __RO {
    my ( undef, undef, undef, $sub ) = caller(1);
    Carp::confess("attribute $sub is read-only");
}

sub _subcmds {
    __RO() if @_ > 1;
    $_[0]{'_subcmds'} //= $_FIELDS->{'_subcmds'}->{'default'}->( $_[0] );
}

sub _values {
    if ( @_ > 1 ) { $_[0]{'_values'} = $_[1] }
    $_[0]{'_values'} // undef;
}

sub abbrev {
    if ( @_ > 1 ) { $_[0]{'abbrev'} = $_[1] }
    $_[0]{'abbrev'} // undef;
}

sub args {
    __RO() if @_ > 1;
    $_[0]{'args'} //= $_FIELDS->{'args'}->{'default'}->( $_[0] );
}
sub class   { __RO() if @_ > 1; $_[0]{'class'}   // undef }
sub comment { __RO() if @_ > 1; $_[0]{'comment'} // undef }
sub hidden  { __RO() if @_ > 1; $_[0]{'hidden'}  // undef }

sub optargs {
    if ( @_ > 1 ) { $_[0]{'optargs'} = $_[1] }
    $_[0]{'optargs'} //= $_FIELDS->{'optargs'}->{'default'}->( $_[0] );
}

sub opts {
    __RO() if @_ > 1;
    $_[0]{'opts'} //= $_FIELDS->{'opts'}->{'default'}->( $_[0] );
}
sub parent { __RO() if @_ > 1; $_[0]{'parent'} // undef }

sub show_color {
    __RO() if @_ > 1;
    $_[0]{'show_color'} //= $_FIELDS->{'show_color'}->{'default'}->( $_[0] );
}

sub show_default {
    __RO() if @_ > 1;
    $_[0]{'show_default'} //= $_FIELDS->{'show_default'}->{'default'};
}

sub subcmds {
    __RO() if @_ > 1;
    $_[0]{'subcmds'} //= $_FIELDS->{'subcmds'}->{'default'}->( $_[0] );
}
@_CLASS = grep 1,    ### END Class::Inline ###
  abstract => 1,
  FIELDS   => {
    abbrev  => { is       => 'rw', },
    args    => { default  => sub { [] }, },
    class   => { required => 1, },
    comment => { required => 1, },
    hidden  => {},
    optargs => {
        is      => 'rw',
        default => sub { [] }
    },
    opts     => { default => sub { [] }, },
    parent   => { weaken  => 1, },
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

    my %aliases;
    while ( my ( $name, $args ) = splice @{ $self->optargs }, 0, 2 ) {
        if ( $args->{isa} =~ s/^--// ) {
            if ( length( my $alias = $args->{alias} //= undef ) ) {
                OptArgs2::croak( 'DuplicateAlias',
                    "duplicate '-$alias' alias by --$name" )
                  if $aliases{$alias}++;
            }

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

my %usage_why = (
    ArgRequired      => undef,
    GetOptError      => undef,
    Help             => undef,
    HelpSummary      => undef,
    HelpTree         => undef,
    OptRequired      => undef,
    OptUnknown       => undef,
    SubCmdRequired   => undef,
    SubCmdUnknown    => undef,
    UnexpectedOptArg => undef,
);

sub throw {
    my $self = shift;
    my $type = shift // OptArgs2::croak( 'Usage', 'throw($TYPE,$why,$info)' );
    my $why  = shift // $type;
    my $info = shift // '';
    my $pkg  = 'OptArgs2::Usage::' . $why;

    OptArgs2::croak( 'Usage', "unknown usage why: $why" )
      unless exists $usage_why{$why};

    no strict 'refs';
    *{ $pkg . '::ISA' } = ['OptArgs2::Status'];

    my $usage = $self->usage_string( $type, $info );
    OptArgs2::die_paged( bless \$usage, $pkg );
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

    OptArgs2::croak( 'CmdExists', 'cmd exists' )
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

package OptArgs2::CODEREF {
    our @CARP_NOT = @OptArgs2::CARP_NOT;

    sub TIESCALAR {
        my $class = shift;
        ( 3 == @_ )
          or OptArgs2::croak( 'Usage', 'args: optargs,name,sub' );
        return bless [@_], $class;
    }

    sub FETCH {
        my $self = shift;
        my ( $optargs, $name, $sub ) = @$self;
        untie $optargs->{$name};
        $optargs->{$name} = $sub->($optargs);
    }

}

sub parse {
    my $self   = shift;
    my $source = \@_;

    map {
        OptArgs2::croak( 'UndefOptArg', 'optargs argument undefined!' )
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
        while ( my $opt = shift @opts ) {
            my $result;
            my $name = $opt->name;

            if ( exists $source_hash->{$name} ) {
                $result = delete $source_hash->{$name};
            }
            else {
                my @errors;
                local $SIG{__WARN__} = sub { push @errors, $_[0] };

                my $ok = eval {
                    GetOptionsFromArray( $source, $opt->getopt => \$result );
                };
                if ( !$ok ) {
                    my $error =
                        length $@ ? $@
                      : @errors   ? join( "\n", @errors )
                      :             'unknown';

                    $reason //= [ GetOptError => $error ];
                }
            }

            if ( defined($result) and my $t = $opt->trigger ) {
                push @trigger, [ $t, $name ];
            }

            if ( defined( $result //= $opt->default ) ) {

                if ( 'CODE' eq ref $result ) {
                    tie $optargs->{$name}, 'OptArgs2::CODEREF', $optargs,
                      $name,
                      $result;
                }
                elsif ( $opt->isa eq 'Input' ) {
                    my $enc = $opt->encoding;
                    tie $optargs->{$name}, 'OptArgs2::CODEREF', $optargs,
                      $name, $result eq '-'
                      ? sub {
                        binmode STDIN, $enc;
                        local $/;
                        <STDIN>;
                      }
                      : sub {
                        open my $fh, '<', $result
                          or die sprintf "open(%s): %s\n", $result, $!;
                        binmode $fh, $enc;
                        local $/;
                        <$fh>;
                    }
                }
                else {
                    $optargs->{$name} = $result;
                }
            }
            elsif ( $opt->required ) {
                $name =~ s/_/-/g;
                $reason //=
                  [ 'OptRequired', qq{missing required option "--$name"} ];
            }
        }

        while ( my $arg = shift @args ) {
            my $result;
            my $name = $arg->name;
            my $isa  = $arg->isa;

            if (@$source) {

                # TODO: do this check for every element in
                # @$source, which means moving this down
                # somewhere...
                if (
                    ( $source->[0] =~ m/^--\S/ )
                    or (
                        $source->[0] =~ m/^-\S/
                        and !(
                            $source->[0] =~ m/^-\d/ and ( $arg->isa ne 'Num'
                                or $arg->isa ne 'Int' )
                        )
                    )
                  )
                {
                    my $o = shift @$source;
                    $reason //= [ 'OptUnknown', qq{unknown option "$o"} ];
                    last OPTARGS;
                }

#                    if ( $arg->greedy ) {
#
#                        # Interesting feature or not? "GREEDY... LATER"
#                        # my @later;
#                        # if ( @args and @$source > @args ) {
#                        #     push( @later, pop @$source ) for @args;
#                        # }
#                        # Should also possibly check early for post-greedy arg,
#                        # except they might be wanted for display
#                        # purposes
#
#                        if ( $arg->isa eq 'ArrayRef' )
#                        {
#                            $result = [@$source];
#                        }
#                        elsif ( $arg->isa eq 'HashRef' ) {
#                            $result = {
#                                map { split /=/, $_ }
#                                  split /,/, @$source
#                            };
#                        }
#                        else {
#                            $result = "@$source";
#                        }
#
#                        $source = [];
#
#                        #                        $source = \@later;
#                    }
                if ( $isa eq 'SubCmd' ) {
                    my $test = $source->[0];

                    if ( $cmd->abbrev
                        and my @subcmds = @{ $cmd->subcmds } )
                    {
                        require Text::Abbrev;
                        my %abbrev =
                          Text::Abbrev::abbrev( map { $_->name } @subcmds );
                        $test = $abbrev{$test} // $test;
                    }

                    if ( exists $cmd->_subcmds->{$test} ) {
                        shift @$source;
                        $cmd = $cmd->_subcmds->{$test};
                        push( @opts, @{ $cmd->opts } );

                        # Replace rest of current cmd arguments with new
                        @args = @{ $cmd->args };
                        if ( @{ $cmd->args }
                            && $cmd->args->[0]->isa ne 'SubCmd' )
                        {
                            # Add a fake Arg to the list to check
                            # for subcommands.
                            unshift @args,
                              OptArgs2::Arg->new(
                                isa     => 'SubCmd',
                                name    => '__internal',
                                comment => '__internal',
                              );
                        }
                        next OPTARGS;
                    }
                    next OPTARGS if $arg->name eq '__internal';

                    $result = shift @$source;
                    if ( $arg->fallthru ) {
                        $optargs->{$name} = $result;
                    }
                    else {
                        $reason //=
                          [ 'SubCmdUnknown', "unknown $name: $result" ];
                    }
                }
                elsif ( $isa eq 'ArrayRef' ) {
                    $result = [ $arg->greedy ? @$source : shift @$source ];
                }
                elsif ( $isa eq 'HashRef' ) {
                    $result = {
                        map { split /=/, $_ } split /,/,
                        $arg->greedy ? @$source : shift @$source
                    };
                }
                else {
                    $result = $arg->greedy ? "@$source" : shift @$source;
                }

                $source = [] if $arg->greedy;

            }
            elsif ( exists $source_hash->{$name} ) {
                $result = delete $source_hash->{$name};
            }

            # TODO: type check using Param::Utils?

            if ( defined( $result //= $arg->default ) ) {
                if ( 'CODE' eq ref $result ) {
                    tie $optargs->{$name}, 'OptArgs2::CODEREF', $optargs,
                      $name,
                      $result;
                }
                elsif ( $isa eq 'Input' ) {
                    my $enc = $arg->encoding;
                    tie $optargs->{$name}, 'OptArgs2::CODEREF', $optargs,
                      $name, $result eq '-'
                      ? sub {
                        binmode STDIN, $enc;
                        local $/;
                        <STDIN>;
                      }
                      : sub {
                        open my $fh, '<', $result
                          or die sprintf "open(%s): %s\n", $result, $!;
                        binmode $fh, $enc;
                        local $/;
                        <$fh>;
                    }
                }
                else {
                    $optargs->{$name} = $result;
                }
            }
            elsif ( $arg->required ) {
                $reason //= ['ArgRequired'];
            }
        }
    }

    if (@$source) {
        $reason //= [
            'UnexpectedOptArg', "unexpected option(s) or argument(s): @$source"
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

    $cmd->throw( OptArgs2::USAGE_USAGE(), @$reason )
      if $reason;

    return ( $cmd->class, $optargs, ( $cmd->class . '.pm' ) =~ s!::!/!gr );
}

sub _usage_tree {
    my $self  = shift;
    my $depth = shift || 0;

    return [
        $depth, $self->usage_string( OptArgs2::USAGE_HELPSUMMARY() ),
        $self->comment
      ],
      map { $_->_usage_tree( $depth + 1 ) }
      sort { $a->name cmp $b->name } @{ $self->subcmds };
}

sub usage_string {
    my $self  = shift;
    my $style = shift || OptArgs2::USAGE_USAGE();
    my $error = shift // '';
    my $usage = '';

    if ( $style eq OptArgs2::USAGE_HELPTREE() ) {
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
      if @parents and $style ne OptArgs2::USAGE_HELPSUMMARY();
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

    return $usage if $style eq OptArgs2::USAGE_HELPSUMMARY();

    $usage .= ' [OPTIONS...]' if @opts;
    $usage .= "\n";

    # Synopsis
    $usage .= "\n  Synopsis:\n    " . $self->comment . "\n"
      if $style eq OptArgs2::USAGE_HELP()
      and length $self->comment;

    # Build arguments
    my @sargs;
    my @uargs;
    my $have_subcmd;

    if (@args) {
        my $i = 0;
      ARG: foreach my $arg (@args) {
            if ( $arg->isa eq 'SubCmd' ) {
                my ( $n, undef, undef, $c ) = $arg->name_alias_type_comment(
                    $arg->show_default
                    ? eval { $optargs->{ $arg->name } // undef }
                    : ()
                );
                push( @sargs, [ '  ' . ucfirst($n) . ':', $c ] );
                my @sorted_subs =
                  map  { $_->[1] }
                  sort { $a->[0] cmp $b->[0] }
                  map  { [ $_->name, $_ ] }
                  grep { $style eq OptArgs2::USAGE_HELP() or !$_->hidden }
                  @{ $arg->cmd->subcmds };

                foreach my $subcmd (@sorted_subs) {
                    push(
                        @sargs,
                        [
                            '    '
                              . $subcmd->usage_string(
                                OptArgs2::USAGE_HELPSUMMARY()
                              ),
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
            next if $style ne OptArgs2::USAGE_HELP() and $opt->hidden;
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

1;

__END__

=head1 NAME

OptArgs2::CmdBase - Base class for (sub-)commands in OptArgs2

=head1 SYNOPSIS

    # Abstract class - inherit only
    package OptArgs2::Cmd;
    use parent 'OptArgs2::CmdBase';

=head1 DESCRIPTION

The C<OptArgs2::CmdBase> class is internal to L<OptArgs2>.

=head1 AUTHOR

Mark Lawrence <mark@rekudos.net>

=head1 LICENSE

Copyright 2016-2025 Mark Lawrence <mark@rekudos.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

