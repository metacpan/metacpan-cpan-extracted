package Perl6::Signature;

use warnings;

use Parse::RecDescent;
use Text::Balanced;
use Perl6::Signature::Val;

our $VERSION = '0.04';

#$::RD_TRACE = 1;
$::RD_HINT  = 1;

our $SIGNATURE_GRAMMAR = << '#\'END';
#\
    {
        use Text::Balanced qw(extract_bracketed);
        use Carp qw(croak);
    }

    Sig: Sig_colon | Sig_nocolon

    Sig_colon: ':' Sig_nocolon

    Sig_nocolon: '(' Sigbody ')'
        { $item{Sigbody} }

    Sigbody: Sigbody_inv | Sigbody_noinv

    Sigbody_inv: Invocant <skip:'\s*'> ':' Sigbody_noinv
        {
          my $sig = $item{Sigbody_noinv};
          die "invocant cannot be optional" unless $item{Invocant}->{required};
          $sig->s_invocant( $item{Invocant}->{param} );
          $return = $sig;
        }

    Sigbody_noinv: Param(s? /,/)
        {
          my @params = @{ $item{'Param(s?)'} };
          my @slurpies = map { $_->{param} } grep { $_->{slurpy} } @params;
          my @nonslurpies = grep { !$_->{slurpy} } @params;
          my @positionals = grep { $_->{style} eq 'positional' } @nonslurpies;
          my @named = grep { $_->{style} eq 'named' } @nonslurpies;

          my $seen_optional;
          my $requiredPositionalCount = 0;

          # calculate requiredPositionalCount, and make sure we don't have
          # :($optional?, $required!) -- that's invalid.
          for my $param (@positionals) {
              $seen_optional++ if ! $param->{required};
              die "can't place required positional after an optional one" if
                  $param->{required} && $seen_optional;
              $requiredPositionalCount++ if ! $seen_optional;
          }

          my %slurpies = map { $_->p_sigil => $_ } @slurpies;

          my ( $slurpy_array, $slurpy_hash ) = ( @slurpies{qw(@ %)} );

          croak "Only one slurpy of every type is allowed" if keys %slurpies != @slurpies;

          my $sig = Perl6::Signature::Val::Sig->new
              ( s_requiredPositionalCount => $requiredPositionalCount
              , s_positionalList          => [ map { $_->{param} } @positionals ]
              , s_namedList               => [ map { $_->{param} } @named ]
              , s_requiredNames           => { map { $_->{param}->p_label => 1 } grep { $_->{required} } @named }
              , ( $slurpy_array ? ( s_slurpyArray => $slurpy_array ) : () ),
              , ( $slurpy_hash  ? ( s_slurpyHash  => $slurpy_hash  ) : () ),
              );
          $return = $sig;
        }

    Invocant: Param

    Param: ParamType(s? /\|/)
           SlurpynessModifier(?)
           ParamIdentifier <skip:''>
           OptionalityModifier(?)
           <skip:'\s*'>
           Unpacking(?)
           DefaultValueSpec(?)
           <skip:'\s+'>
           Attrib(s?)
           <skip:'\s*'>
           Constraint(s?)
        {
          my ($variable, $label, $style) =
                @{$item{ParamIdentifier}}{qw/variable label style/};

          my ($hasAccess, $isRef, $isContext, $isLazy, @slots);
          # unfortunately, we can't use a hash and delete from it:
          # "is ro is rw" means "is rw". (Or maybe, a parse error.)
          ATTR: for (@{ $item{'Attrib(s?)'} }) {
            /^(ro|rw|copy)$/ && do { $hasAccess = $_; next ATTR };
            /^ref$/          && do { $isRef = 1;      next ATTR };
            /^context$/      && do { $isContext = 1;  next ATTR };
            /^lazy$/         && do { $isLazy = 1;     next ATTR };
            push @slots, $_;
          }

          my $param = Perl6::Signature::Val::SigParam->new
                ( p_types     => $item{'ParamType(s?)'}
                , p_variable  => $variable
                , p_label     => $label
                , ($item{'Unpacking(?)'} ? (p_unpacking => $item{'Unpacking(?)'}->[0]) : ())
                , (@{ $item{'DefaultValueSpec(?)'} } ?
                        (p_default => $item{'DefaultValueSpec(?)'}->[0]) : ())
                , (@{ $item{'Constraint(s?)'} } ?
                        (p_constraints => [ @{ $item{'Constraint(s?)'} } ]) : ())
                , ( $hasAccess ? ( p_hasAccess => $hasAccess ) : () ),
                , p_isRef     => $isRef
                , p_isContext => $isContext
                , p_isLazy    => $isLazy
                , p_slots     => { map { $_ => 1 } @slots }
                        # "is foo<42>" not supported yet.
                );
          my $slurpy      = 1 == @{ $item{'SlurpynessModifier(?)'} };
          my $optionality = $item{'OptionalityModifier(?)'}->[0] || '';
          my $optional = scalar @{ $item{'DefaultValueSpec(?)'} };
          die "required parameter can't have default value" if
              $optional && $optionality eq '!';
          $optional = 1 if $style eq 'named' && $optionality ne '!';
          $optional = 1 if $optionality eq '?';

          $return = { param    => $param
                    , required => !$optional
                    , style    => $style
                    , slurpy   => $slurpy
                    };
        }

    ParamType: /[a-zA-Z]\w+/

    ParamIdentifier: ParamIdentifier_positional
                   | ParamIdentifier_named
    
    # Perl 6 allows placeholder parameters, e.g. :($) - sub of arity 1 (scalar).
    ParamIdentifier_positional: Sigil <skip:''> Label(?)
        {
          my $label = @{ $item{'Label(?)'} } ? $item{'Label(?)'}->[0] : '';
          $return = { variable => $item{Sigil} . $label
                    , label    => $label
                    , style    => 'positional'
                    };
        }

    # TODO: L<S06/"Multiple name wrappings may be given">, whoa.
    ParamIdentifier_named:
            ':' <skip:''> Label ParamIdentifier_named_variablename
        {
            $return = { variable => $item{'ParamIdentifier_named_variablename'}
                      , label => $item{Label}
                      , style => 'named'
                      };
        }
            | ':' <skip:''> Sigil Label
        {
            $return = { variable => $item{Sigil} . $item{Label}
                      , label => $item{Label}
                      , style => 'named'
                      };
        }

    ParamIdentifier_named_variablename: '(' <perl_variable> ')'
        { $return = $item[2]; 1; }

    OptionalityModifier: /[!?]/

    SlurpynessModifier: /\*/

    Unpacking: Sig

    Constraint: 'where' <perl_codeblock>

    # default values are _unevaluated_.
    DefaultValueSpec: '=' ValueOrSomeStabAtOne

    ValueOrSomeStabAtOne: Value_numberLiteral
                        | Value_acceptableQuotelike
                        | Value_variable
                        | Value_looksBalanced
                        | Value_looksClosure

    # perlfaq4 ftw
    Value_numberLiteral: /([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?/ # float
                       | /-?(?:\d+(?:\.\d*)?|\.\d+)/                      # decimal
                       | /-?\d+\.?\d*/                                    # real
                       | /[+-]?\d+/                                       # +/- integer
                       | /-?\d+/                                          # integer
                       | /\d+/                                            # whole number
                       | /0x[0-9a-fA-F]+/                                 # hexadecimal
                       | /0b[01]+/                                        # binary
                       # note that octals will be captured by the "whole number"
                       # production. Our consumer will have to eval this (we don't
                       # want to do it for them because of roundtripping. But maybe
                       # we need annotation nodes anyway?

    Value_acceptableQuotelike: <perl_quotelike>
        {
            my $op = $item[1]->[0];  # q, qq etc.
            my %whitelist = map { $_ => 1 } qw(q qq qw qr);  # TODO: lift this up
            die "rejected quotelike operator: $op" unless $whitelist{$op};
            $return = join "", @{ $item[0] };
            1;
        }

    Value_variable: <perl_variable>

    Value_looksBalanced: { extract_bracketed($text, '()') }
                       | { extract_bracketed($text, '[]') }
                       | { extract_bracketed($text, '{}') }

    Value_looksClosure: 'sub' <perl_codeblock>

    Attrib: 'is' Label

    Sigil: /[\$\@\%]/

    Label: /\w+/

    # This one is a bummer: we don't want to provide a full parser for
    # Perl expressions here. If we are called in the context of Devel::Declare,
    # perhaps we can get a reference back to the real parser? Otherwise, we're
    # stuck with doing some half-assed parsing that would preclude e.g.
    # :($pi = 22/7)
    Literal: /\S+/
#'END

my $parser = Parse::RecDescent->new($SIGNATURE_GRAMMAR) || die "GRAMMAR NO WORKY *CWY* *CWY*";

sub parse {
    my($self, $sig_str) = @_;

    my $res = $parser->Sig($sig_str);

    die "Unparsable signature"
        unless $res;

    return $res;
}

# These are my favorite debugging tools. Share and enjoy.
#sub ::Y  { require YAML::Syck; YAML::Syck::Dump(@_) }
#sub ::YY { require Carp; Carp::confess(::Y(@_)) }

6;

__END__
=head1 NAME

Perl6::Signature - Parse, query, and pretty-print Perl 6 signatures

=head1 SYNOPSIS

    use Perl6::Signature;

    my $sig = Perl6::Signature->parse(
        ':($self: $x, Int $y = 42 where { $_ % 2 == 0 }, :$z is copy)');

    print $sig->s_requiredPositionalCount;      # 1
    print $sig->s_positionalList->[0]->p_label  # "x"
    print $sig->s_namedList->[0]->p_hasAccess;  # "copy"

    print $sig->to_string;
        # ":($self: $x, Int $y = 42 where { $_ % 2 == 0 }, :$z is copy)"

=head1 DESCRIPTION

I<Alpha release - everything here is subject to change>

B<Perl6::Signature> models routine signatures as specified in Synopsis 6 of
the Perl 6 documentation. These signatures offer a rich language for
expressing type constraints, default values, and the optionality (among other
things) of routine parameters.

Included is a parser for the Signature language, accessors and convenience
methods for querying Signature objects, and a pretty-printer for producing
their canonical textual representation.

=head1 MODULE LAYOUT OVERVIEW

B<Perl6::Signature> contains a B<Parse::RecDescent>-based parser for
signatures.

B<Perl6::Signature::Val> is our local base class for Perl 6 values.
It doesn't do anything interested in itself, but if this distribution is
bridged to another Perl 6-modeling distribution, this could be the first
insertion point for glue methods. The next two modules subclass it.

B<Perl6::Signature::Val::Sig> and B<Perl6::Signature::Val::SigParam>
model full signatures and their consituent parameters. This is where you
go to quiery and pretty-print your parsed objects.

=head1 FUNCTIONS

=head2 Perl6::Signature

=over 4

=item Perl6::Signature->parse(STRING)

Parse a well-formed signature specification into a
B<Perl6::Signature::Val::Sig> object. Returns undef on failure, and
in some cases can die. (This needs to be regularized.)

CAVEAT #1: we do "best effort" parsing for default values. Simple
literals are okay; complex expressions may not be.

CAVEAT #2: default value specifications are not evaluated by
B<Perl6::Signature>, not-in-scope errors are not raised, and constant
folding is not performed. There may be semantic implications to this.

CAVEAT #3: we similarly do "best effort" to parse dynamic constraints
(C<"where {....}"> blocks). Funky code might well fail to parse correctly.

=back

=head2 Perl6::Signature::Val::Sig

=over 4

=item $sig->to_string

Pretty-print a Sig object into canonical textual form.

"Canonical form" means regualar whitespace, implicit "!" on mandatory
positional parameters, impicit "?" on optional named parameters, and
so on. Code from dynamic constraints is reproduced verbatim.

=item has 's_invocant' => (is => 'rw', isa => 'Perl6::Signature::Val::SigParam', required => 0);

=item has 's_requiredPositionalCount' => (is => 'rw', isa => 'Int');

=item has 's_requiredNames' => (is => 'rw', isa => 'HashRef');   # Set of names

=item has 's_positionalList' => (is => 'rw', isa => 'ArrayRef[Perl6::Signature::Val::SigParam]');

=item has 's_namedList' => (is => 'rw', isa => 'ArrayRef[Perl6::Signature::Val::SigParam]');

=item has 's_slurpyScalarList' => (is => 'rw', isa => 'ArrayRef', required => 0);

=item has 's_slurpyArray' => (is => 'rw', isa => 'Perl6::Signature::Val::SigParam', required => 0);

=item has 's_slurpyHash' => (is => 'rw', isa => 'Perl6::Signature::Val::SigParam', required => 0);

=item has 's_slurpyCode' => (is => 'rw', isa => 'Perl6::Signature::Val::SigParam', required => 0);

=item has 's_slurpyCapture' => (is => 'rw', isa => 'Perl6::Signature::Val::SigParam', required => 0);

=back

=head2 Perl6::Signature::Val::SigParam

=over 4

=item $param->to_string(%args)

Pretty-print a SigParam object into canonical form. Note that a SigParam
doesn't know whether it is required or optional; nor whether it is positional
or named. This must be supplied by the Sig container.

=item has 'p_variable' =>    (is => 'rw', isa => 'Str');

=item has 'p_types' =>       (is => 'rw', isa => 'ArrayRef');  # of types

=item has 'p_constraints' => (is => 'rw', isa => 'ArrayRef');  # of code

=item has 'p_unpacking' =>   (is => 'rw', isa => 'Perl6::Signature::Val::Sig|Undef', required => 0);

=item has 'p_default' =>     (is => 'rw', required => 0);

=item has 'p_label' =>       (is => 'rw', isa => 'Str');

=item has 'p_slots' =>       (is => 'rw', isa => 'HashRef');

=item has 'p_hasAccess' =>   (is => 'rw', );  # ro/rw/copy

=item has 'p_isRef' =>       (is => 'rw', isa => 'Bool');

=item has 'p_isContext' =>   (is => 'rw', isa => 'Bool');

=item has 'p_isLazy' =>      (is => 'rw', isa => 'Bool');

=back

=head1 SEE ALSO

=over 4

=item L<http://perlcabal.org/syn/S06.html#Parameters_and_arguments>

=item L<Moose>

=item L<Parse::RecDescent>

=back

=head1 AUTHORS

Gaal Yahas, C<< <gaal at forum2.org> >>

Contributions by:

Yuval Kogman, CC< <nothingmuch@woobling.org> >>

Florian Ragwitz, CC< <rafl@debian.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-perl6-signature at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl6-Signature>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perl6::Signature

You can also contact the maintainer at the address above or look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perl6-Signature/>

=item * Search CPAN

L<http://search.cpan.org/dist/Perl6-Signature/>

=item * Source repository

L<https://github.com/gaal/perl6-signature/>

=back

=head1 COPYRIGHT (The "MIT" License)

Copyright 2008 Gaal Yahas.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

