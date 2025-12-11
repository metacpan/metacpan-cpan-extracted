package OptArgs2::Arg;
use strict;
use warnings;
use parent 'OptArgs2::OptArgBase';

my %isa2name = (
    'ArrayRef' => 'Str',
    'HashRef'  => 'Str',
    'Input'    => 'Str',
    'Int'      => 'Int',
    'Num'      => 'Num',
    'Str'      => 'Str',
    'SubCmd'   => 'Str',
);

my %arg2getopt = (
    'Str'      => '=s',
    'Input'    => '=s',
    'Int'      => '=i',
    'Num'      => '=f',
    'ArrayRef' => '=s@',
    'HashRef'  => '=s%',
    'SubCmd'   => '=s',
);

### START Class::Inline ### v0.0.1 Wed Dec  3 10:44:53 2025
require Scalar::Util;
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
        Carp::carp("OptArgs2::Arg: unexpected argument '$_'") for keys %$attrs
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
        Carp::croak( 'OptArgs2::Arg required initial argument(s): '
              . join( ', ', @missing ) );
    }
    Scalar::Util::weaken( $_[0]{'cmd'} )
      if exists $_[0]{'cmd'} && ref $_[0]{'cmd'};
    $_[0]{'isa'} = eval { $_FIELDS->{'isa'}->{'isa'}->( $_[0]{'isa'} ) };
    Carp::confess( 'OptArgs2::Arg isa: ' . $@ ) if $@;
    map { delete $_[1]->{$_} } 'cmd', 'fallthru', 'greedy', 'isa', 'isa_name';
}

sub __RO {
    my ( undef, undef, undef, $sub ) = caller(1);
    Carp::confess("attribute $sub is read-only");
}

sub cmd {
    if ( @_ > 1 ) {
        $_[0]{'cmd'} = $_[1];
        Scalar::Util::weaken( $_[0]{'cmd'} ) if ref $_[0]{'cmd'};
    }
    $_[0]{'cmd'} // undef;
}
sub fallthru { __RO() if @_ > 1; $_[0]{'fallthru'} // undef }
sub greedy   { __RO() if @_ > 1; $_[0]{'greedy'}   // undef }
sub isa      { __RO() if @_ > 1; $_[0]{'isa'}      // undef }

sub isa_name {
    __RO() if @_ > 1;
    $_[0]{'isa_name'} //= $_FIELDS->{'isa_name'}->{'default'}->( $_[0] );
}
@_CLASS = grep 1,    ### END Class::Inline ###
  cmd      => { is => 'rw', weaken => 1, },
  fallthru => {},
  greedy   => {},
  isa      => {
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

sub BUILD {
    my $self = shift;

    OptArgs2::croak( 'Conflict', q{'default' and 'required' conflict} )
      if $self->required and defined $self->default;

    OptArgs2::croak( 'Conflict', q{'isa SubCmd' and 'greedy' conflict} )
      if $self->greedy and $self->isa eq 'SubCmd';
}

sub name_alias_type_comment {
    my $self  = shift;
    my $value = shift;

    my $deftype = ( defined $value ) ? '[' . $value . ']' : $self->isa_name;
    my $comment = $self->comment;

    if ( $self->required ) {
        $comment .= ' ' if length $comment;
        $comment .= '*required*';
    }

    return $self->name, '', $deftype, $comment;
}

1;

__END__

=head1 NAME

OptArgs2::Arg - A class representing a command positional argument

=head1 SYNOPSIS

  use OptArgs2::Cmd;

  my $arg = OptArgs2::Cmd->new(...)->add_arg(
    name     => 'arg_name',
    isa      => 'Str',
    required => 1,
    default  => 'default_value',
  );

=head1 DESCRIPTION

The C<OptArgs2::Arg> class is internal to L<OptArgs2>.

=head1 AUTHOR

Mark Lawrence <mark@rekudos.net>

=head1 LICENSE

Copyright 2016-2025 Mark Lawrence <mark@rekudos.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

=cut
