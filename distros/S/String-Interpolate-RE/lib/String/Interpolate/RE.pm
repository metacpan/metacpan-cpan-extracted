package String::Interpolate::RE;

# ABSTRACT: interpolate variables into strings using regular expressions

use v5.10;

use strict;
use warnings;

use Exporter::Shiny qw[ strinterp ];

our $VERSION = '0.12';

my %Opt = (
    variable_re        => qr/\w+/,
    raiseundef         => !!0,
    emptyundef         => !!0,
    useenv             => !!1,
    format             => !!0,
    recurse            => !!0,
    recurse_limit      => 0,
    recurse_fail_limit => 100,
    fallback           => undef,
);
my %Defaults = map { $_ => $Opt{$_} } grep { defined $Opt{$_} } keys %Opt;


*strinterp = _mk_strinterp( \%Defaults );

sub _croak {
    require Carp;
    goto &Carp::croak;
}

sub _generate_strinterp {

    my ( undef, undef, $args ) = @_;

    return \&strinterp
      if !defined $args || !defined $args->{opts};

    my %opt = %Defaults;
    $opt{ lc $_ } = $args->{opts}{$_} foreach keys %{ $args->{opts} };
    if ( my @bad = grep !exists $Opt{$_}, keys %opt ) {
        _croak( 'unrecognized option(s): ' . join( ', ', @bad ) );
    }

    _croak( q{'fallback' option must be a coderef} )
      if exists $opt{fallback} && ref( $opt{fallback} ) ne 'CODE';

    return _mk_strinterp( \%opt );
}

sub _mk_strinterp {

    my $default_opt = shift;

    return sub {

        my ( $text, $var, $opts ) = @_;

        $var = {} unless defined $var;

        my %opt = %$default_opt;

        if ( defined $opts ) {
            $opt{ lc $_ } = $opts->{$_} foreach keys %$opts;
            if ( my @bad = grep !exists $Opt{$_}, keys %opt ) {
                _croak( 'unrecognized option(s): ' . join( ', ', @bad ) );
            }
            _croak( q{'fallback' option must be a coderef} )
              if exists $opt{fallback} && ref( $opt{fallback} ) ne 'CODE';
        }

        my $fmt = $opt{format} ? ':([^}]+)' : '()';

        $opt{track} = {};
        $opt{loop}  = 0;
        $opt{fmt}   = $fmt;

        _strinterp( $text, $var, \%opt );

        return $text;
    };
}

sub _strinterp {

    my $var = $_[1];
    my $opt = $_[2];
    my $fmt = $opt->{fmt};
    my $re  = $opt->{variable_re};

    # The following code pulls things out of the hash to reduce the
    # number of hash lookups in the code in the RE.  Unfortunately, iqt
    # doesn't seem to make much of a difference, but it does clean
    # that code up a bit.

    my ( $useenv, $raiseundef, $recurse, $fallback, $emptyundef, $track,
        $recurse_limit, $recurse_fail_limit )
      = @{$opt}{
        qw( useenv raiseundef recurse fallback emptyundef track
          recurse_limit recurse_fail_limit
        ) };

    my $rloop   = \( $opt->{loop} );
    my $is_code = 'CODE' eq ref $var;

    $_[0] =~ s{
               \$                    # find a literal dollar sign
              (                      # followed by either
               [{] ($re)(?:$fmt)? [}]  #  a variable name in curly brackets ($2)
                                     #  and an optional sprintf format
               |                     # or
                (\w+)                #   a bareword ($3)
              )
            }{
                my $t = defined $4 ? $4 : $2;

                my $user_value
                  = $is_code          ? $var->( $t )
                  : exists $var->{$t} ? $var->{$t}
                  : $fallback         ? $fallback->( $t )
                  :                     undef;

                #<<<
                my $v =
                  # user provided?
                  defined $user_value          ? $user_value

                  # maybe in the environment
                  : $useenv && exists $ENV{$t} ? $ENV{$t}

                  # undefined: throw an error  ?
                  : $raiseundef                ? _croak( "undefined variable: $t\n" )

                  # undefined
                  : undef;
                #>>>

                if ( $recurse && defined $v ) {

                  RECURSE:
                    {
                        _croak( "circular interpolation loop detected with repeated interpolation of <\$$t>\n" )
                          if $track->{$t}++;

                        my $loop = ++$$rloop;

                        last RECURSE if $recurse_limit && $loop > $recurse_limit;

                        _croak( "recursion fail-safe limit ($recurse_fail_limit) reached at interpolation of <\$$t>\n" )
                          if $recurse_fail_limit && $loop > $recurse_fail_limit;

                        _strinterp( $v, $_[1], $_[2] );
                    }

                    delete $track->{$t};
                    --$$rloop;
                }

                # if not defined:
                #   if emptyundef, replace with an empty string
                #   otherwise,     just put it back into the string
                !defined $v
                  ? ( $emptyundef ? '' : '$' . $1 )

                  # no format? return as is
                  : !defined $3 || $3 eq '' ? $v

                  # format it
                  : sprintf( $3, $v )

                  ;
        }egx;
}

1;

#
# This file is part of String-Interpolate-RE
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory useenv

=head1 NAME

String::Interpolate::RE - interpolate variables into strings using regular expressions

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  # default formulation
  use String::Interpolate::RE qw( strinterp );

  $str = strinterp( "${Var1} $Var2", $vars, \%opts );

  # import with different default options.
  use String::Interpolate::RE strinterp => { opts => { useENV => 0 } };

=head1 DESCRIPTION

This module interpolates variables into strings using regular
expression matching rather than Perl's built-in interpolation
mechanism and thus hopefully does not suffer from the security
problems inherent in using B<eval> to interpolate into strings of
suspect ancestry.

=head2 Changing the default option values

The default values for L</strinterp>'s options were not all well
thought out.  B<String::Interpolate::RE> uses L<Exporter::Tiny>,
allowing a version of L</strinterp> with saner defaults to be
exported.  Simply specify them when importing:

  use String::Interpolate::RE strinterp => { opts => { useenv => 0 } };

The subroutine may be renamed using the C<-as> option:

  use String::Interpolate::RE strinterp => { -as => strinterp_noenv,
                                             opts => { useenv => 0 } };

  strinterp_noenv( ... );

=head1 INTERFACE

=over

=item strinterp

    $str = strinterp( $template );
    $str = strinterp( $template, $vars );
    $str = strinterp( $template, $vars, \%opts );

Interpolate variables into a template string, returning the
resultant string.  The template string is scanned for tokens of the
form

    $VAR
    ${VAR}

where C<VAR> is composed of one or more characters specified by the
L</variable_re> option (which has a reasonable default).

=over

=item 1

If C<$vars> is a code reference, it is passed C<VAR> as its sole
argument and should return its value (or B<undef>)

=item 2

Otherwise, C<$vars> should be a hash reference.  If C<VAR> is a
key in C<$vars>, its value is used.

If C<VAR> is I<not> in C<$vars>, and if the L</fallback> option was
specified, that coderef is called with C<VAR> as its sole argument,
and should return C<VAR>'s value (or B<undef>).

=back

If the value returned for C<VAR> is defined, it will be interpolated
into the string at that point.  If it is I<not> defined, it will be
left as is in the string (see the L</raiseundef> and
L</emptyundef> options for alternative behaviors).

The C<%opts> parameter may be used to modify the behavior of this
function.  The following (case insensitive) keys are recognized:

=over

=item fallback I<coderef>

If provided, this coderef is passed the variable name if C<$vars> is a
hash reference and does not contain an entry with a key matching the
variable name.

=item format I<boolean>

If this flag is true, the template string may provide a C<sprintf>
compatible format which will be used to generate the interpolated
value.  The format should be appended to the variable name with
an intervening C<:> character, e.g.

    ${VAR:fmt}

For example,

    %var = ( foo => 3 );
    print strinterp( '${foo:%03d}', \%var, { format => 1 } );

would result in

    003

=item raiseundef I<boolean>

If true, a variable which has not been defined will result in an
exception being raised.  This defaults to false.

=item emptyundef I<boolean>

If true, a variable which has not been defined will be replaced with
the empty string.  This defaults to false.

=item useenv I<boolean>

If true, the C<%ENV> hash will be searched for variables which are not
defined in the passed C<%var> hash.  This defaults to true.

=item recurse I<boolean>

If true, derived values are themselves scanned for variables to
interpolate.  To specify a limit to the number of levels of recursions
to attempt, set the C<recurse_limit> option.  Circular dependencies
are caught, but just to be safe there's a limit of recursion levels
specified by C<recurse_fail_limit>, beyond which an exception is
thrown.

For example,

  my %var = ( a => '$b', b => '$c', c => 'd' );
  strinterp( '$a', \%var ) => '$b'
  strinterp( '$a', \%var, { recurse => 1 } ) => 'd'
  strinterp( '$a', \%var, { recurse => 1, recurse_limit => 1 } ) => '$c'

  strinterp( '$a', { a => '$b', b => '$a' } , { recurse => 1 }
        recursive interpolation loop detected with repeated
        interpolation of $a

=item recurse_limit I<integer>

The number of recursion levels to descend when recursing into a
variable's value before stopping.  The default is C<0>, which means no
limit.

=item recurse_fail_limit I<integer>

The number of recursion levels to descend when recursing into a
variable's value before giving up and croaking.  The default is C<100>.
Setting this to C<0> means no limit.

=item variable_re I<regular expression>

This specifies the regular expression (created with the C<qr>
operator) which will match a variable name.  It defaults to
C<qr/\w+/>. Don't use C<:>, C<{>, or C<}> in the regex, or things may
break.

=back

=back

=head1 DIAGNOSTICS

=over

=item C<< undefined variable: %s >>

This string is thrown if the C<RaiseUndef> option is set and the
variable C<%s> is not defined.

=item C<< unrecognized option(s): %s >>

One or more of the passed options isn't something this module recognizes

=item C<< 'fallback' option must be a coderef >>

As noted.

=item C<< recursive interpolation loop detected with repeated interpolation of <%s> >>

When resolving nested interpolated values (with the C<recurse> option
true ) a circular loop was found.

=item C<< recursion fail-safe limit (%d) reached at interpolation of <%s> >>

The recursion fail safe limit (C<recurse_fail_limit>) was reached while
interpolating nested variable values (with the C<recurse> option true ).

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-string-interpolate-re@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=String-Interpolate-RE>

=head2 Source

Source is available at

  https://gitlab.com/djerius/string-interpolate-re

and may be cloned from

  https://gitlab.com/djerius/string-interpolate-re.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
