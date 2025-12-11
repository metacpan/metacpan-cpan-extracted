package OptArgs2::Opt;
use strict;
use warnings;
use parent 'OptArgs2::OptArgBase';

my %isa2name = (
    'ArrayRef' => 'Str',
    'Bool'     => '',
    'Counter'  => '',
    'Flag'     => '',
    'HashRef'  => 'Str',
    'Int'      => 'Int',
    'Input'    => 'Str',
    'Num'      => 'Num',
    'Str'      => 'Str',
);

my %isa2getopt = (
    'ArrayRef' => '=s@',
    'Bool'     => '!',
    'Counter'  => '+',
    'Flag'     => '!',
    'HashRef'  => '=s%',
    'Int'      => '=i',
    'Input'    => '=s',
    'Num'      => '=f',
    'Str'      => '=s',
);

### START Class::Inline ### v0.0.1 Wed Dec  3 10:44:52 2025
require Carp;
our ( @_CLASS, $_FIELDS, %_NEW );

sub new {
    my $class = shift;
    my $CLASS = ref $class || $class;
    $_NEW{$CLASS} //= do {
        my ( %seen, @new, @build );
        my @possible = ($CLASS);
        while (@possible) {
            my $c = shift @possible;
            no strict 'refs';
            push @new,   $c . '::_NEW'  if exists &{ $c . '::_NEW' };
            push @build, $c . '::BUILD' if exists &{ $c . '::BUILD' };
            $seen{$c}++;
            if ( exists &{ $c . '::DOES' } ) {
                push @possible, grep { not $seen{$_}++ } $c->DOES('*');
            }
            push @possible, grep { not $seen{$_}++ } @{ $c . '::ISA' };
        }
        [ [ reverse(@new) ], [ reverse(@build) ] ];
    };
    my $self = { @_ ? @_ > 1 ? @_ : %{ $_[0] } : () };
    bless $self, $CLASS;
    my $attrs = { map { ( $_ => 1 ) } keys %$self };
    map { $self->$_($attrs) } @{ $_NEW{$CLASS}->[0] };
    {
        local $Carp::CarpLevel = 3;
        Carp::carp("OptArgs2::Opt: unexpected argument '$_'") for keys %$attrs
    }
    map { $self->$_ } @{ $_NEW{$CLASS}->[1] };
    $self;
}

sub _NEW {
    CORE::state $fix_FIELDS = do {
        $_FIELDS = { @_CLASS > 1 ? @_CLASS : %{ $_CLASS[0] } };
        $_FIELDS = $_FIELDS->{'FIELDS'} if exists $_FIELDS->{'FIELDS'};
    };
    if ( my @missing = grep { not exists $_[0]->{$_} } 'isa' ) {
        Carp::croak( 'OptArgs2::Opt required initial argument(s): '
              . join( ', ', @missing ) );
    }
    $_[0]{'isa'} = eval { $_FIELDS->{'isa'}->{'isa'}->( $_[0]{'isa'} ) };
    Carp::confess( 'OptArgs2::Opt isa: ' . $@ ) if $@;
    map { delete $_[1]->{$_} } 'alias', 'hidden', 'isa', 'isa_name', 'trigger';
}

sub __RO {
    my ( undef, undef, undef, $sub ) = caller(1);
    Carp::confess("attribute $sub is read-only");
}
sub alias  { __RO() if @_ > 1; $_[0]{'alias'}  // undef }
sub hidden { __RO() if @_ > 1; $_[0]{'hidden'} // undef }
sub isa    { __RO() if @_ > 1; $_[0]{'isa'}    // undef }

sub isa_name {
    __RO() if @_ > 1;
    $_[0]{'isa_name'} //= $_FIELDS->{'isa_name'}->{'default'}->( $_[0] );
}
sub trigger { __RO() if @_ > 1; $_[0]{'trigger'} // undef }
@_CLASS = grep 1,    ### END Class::Inline ###
  alias   => {},
  hidden  => {},
  trigger => {},
  isa     => {
    required => 1,
    isa      => sub {
        $isa2name{ $_[0] }
          // OptArgs2::croak( 'InvalidIsa', 'invalid isa type: ' . $_[0] );
        $_[0];
    },
  },
  isa_name => {
    default => sub {
        '(' . $isa2name{ $_[0]->isa } . ')';
    },
  },
  ;

our @CARP_NOT = @OptArgs2::CARP_NOT;

sub new_from {
    my $proto = shift;
    my $ref   = {@_};

    # legacy interface
    if ( exists $ref->{ishelp} ) {
        delete $ref->{ishelp};
        $ref->{isa} //= OptArgs2::USAGE_HELP();
    }

    if ( $ref->{isa} =~ m/^Help/ ) {    # one of the USAGE_HELPs
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
                $cmd->throw( OptArgs2::USAGE_HELP() );
            }
            elsif ( $val == 2 ) {
                $cmd->throw( OptArgs2::USAGE_HELPTREE() );
            }
            else {
                $cmd->throw( OptArgs2::USAGE_USAGE(), 'UnexpectedOptArg',
                    qq{"--$ref->{name}" used too many times} );
            }
        };
    }

    if ( !exists $isa2getopt{ $ref->{isa} } ) {
        return OptArgs2::croak( 'InvalidIsa', 'invalid isa "%s" for opt "%s"',
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

    my $isa     = $self->isa;
    my $deftype = '';
    if ( $isa ne 'Flag' and $isa ne 'Bool' and $isa ne 'Counter' ) {
        $deftype = defined $value ? '[' . $value . ']' : $self->isa_name;
    }

    my $comment = $self->comment;
    if ( $self->required ) {
        $comment .= ' ' if length $comment;
        $comment .= '*required*';
    }

    return $opt, $alias, $deftype, $comment;
}

1;

__END__

=head1 NAME

OptArgs2::Opt - A class representing a command option

=head1 SYNOPSIS

  use OptArgs2::Cmd;

  my $opt = OptArgs2::Cmd->new(...)->add_opt(
    name     => 'opt_name',
    isa      => 'Str',
    required => 1,
    default  => 'default_value',
    alias    => 'o',
  );

=head1 DESCRIPTION

The C<OptArgs2::Opt> class is internal to L<OptArgs2>.

=head1 AUTHOR

Mark Lawrence <mark@rekudos.net>

=head1 LICENSE

Copyright 2016-2025 Mark Lawrence <mark@rekudos.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

