package Perl::Critic::Policy::Variables::RequireHungarianNotation;

use strict;
use warnings;
use parent 'Perl::Critic::Policy';
use Perl::Critic::Utils ':severities';

$Perl::Critic::Policy::Variables::RequireHungarianNotation::VERSION = '0.0.7';

sub desc {
    return 'Non hungarian notation';
}

sub expl {
    return q{Use hungarian notation for variable declararions!};
}

sub supported_parameters {
    return (
        { name => 'array',       description => 'Prefix for Array vars',    default_string => q/a_/, },
        { name => 'hash',        description => 'Prefix for Hash vars',     default_string => q/h_/, },
        { name => 'array_ref',   description => 'Prefix for Arrayref vars', default_string => q/ar_/, },
        { name => 'hash_ref',    description => 'Prefix for Hashref vars',  default_string => q/hr_/, },
        { name => 'code_ref',    description => 'Prefix for Coderef vars',  default_string => q/cr_/, },
        { name => 'file_handle', description => 'Prefix for file handles',  default_string => q/fh_/, },
        { name => 'object',      description => 'Prefix for Object vars',   default_string => q/o_/, },
        { name => 'integer',     description => 'Prefix for Integer vars',  default_string => q/i_/, },
        { name => 'float',       description => 'Prefix for Float vars',    default_string => q/f_/, },
        { name => 'string',      description => 'Prefix for String vars',   default_string => q/s_/, },
        { name => 'boolean',     description => 'Prefix for boolean vars',  default_string => q/b_/ },
        { name => 'regex',  description => 'Prefix for predefined regular expressions', default_string => q/rx_/ },
        { name => 'self',   description => 'Ingore self variable',                      default_string => q/self/ },
        { name => 'custom', description => 'Custom prefixes', },
    );
}

sub default_severity {
    return $SEVERITY_LOW;
}

sub default_themes {
    return qw(cosmetic readability);
}

sub applies_to {
    return qw(
      PPI::Statement::Include
      PPI::Statement::Variable
    );
}

sub violates {
    my ( $self, $o_statement, undef ) = @_;
    if ( $o_statement->isa('PPI::Statement::Include') ) {
        return if not scalar grep { $o_statement->module eq $_ } qw/vars/;
        my @a_quoteLike_word_literals =
          map { $_->literal } grep { $_->isa('PPI::Token::QuoteLike::Words') } $o_statement->schildren;
        for (@a_quoteLike_word_literals) {
            my $o_variable = PPI::Statement::Variable->new( PPI::Token::Symbol->new($_) );
            if ( $self->_violates_scalar($o_variable) || $self->_violates_list($o_variable) ) {
                return $self->violation( desc(), expl(), $o_statement );
            }
        }
        return;
    }
    return if not scalar grep { $o_statement->type eq $_ } qw/my our local state/;
    if ( $self->_violates_scalar($o_statement) || $self->_violates_list($o_statement) ) {
        return $self->violation( desc(), expl(), $o_statement );
    }
    return $self->violation( desc(), expl(), $o_statement ) if $self->_check_sub_variables($o_statement);
    return;
}

sub _violates_list {
    my ( $self, $o_statement ) = @_;
    my @a_childrens = $o_statement->schildren;                                      # "significant" children
    my $o_children = scalar @a_childrens > 1 ? $a_childrens[1] : $a_childrens[0];
    if ( $o_children->isa('PPI::Token::Symbol') && $o_children->raw_type =~ /^[@%]$/ ) {
        return 1 if !$self->_b_check_list( $o_children->symbol, $o_children->raw_type );
    }
    return;
}

sub _violates_scalar {
    my ( $self, $o_statement ) = @_;
    my @a_childrens = $o_statement->schildren;                                      # "significant" children
    my $o_children = scalar @a_childrens > 1 ? $a_childrens[1] : $a_childrens[0];
    if ( $o_children->isa('PPI::Token::Symbol') && $o_children->raw_type eq q{$} ) {
        return 1 if !$self->_b_check_scalar( $o_children->symbol );
    }
    return;
}

sub _get_custom_prefixes {
    my ($self) = @_;
    return join q/|/, split / /, $self->{_custom};
}

sub _check_sub_variables {
    my ( $self, $o_statement ) = @_;
    return if not $o_statement->variables > 1;

    for ( map { $_->schildren } grep { $_->isa('PPI::Structure::List') } $o_statement->schildren ) {
        for ( grep { $_->isa('PPI::Token::Symbol') } $_->schildren ) {
            return 1
              if !(
                  $_->raw_type =~ /^[@%]$/
                ? $self->_b_check_list( $_->symbol, $_->raw_type )
                : $self->_b_check_scalar( $_->symbol, $_->raw_type )
              );
        }
    }
    return;
}

sub _b_check_scalar {
    my ( $self, $s_symbol, $s_raw_type ) = @_;
    return 1 if $s_symbol eq q/$/ . $self->{_self};
    for (qw/array_ref hash_ref object integer float string boolean regex code_ref file_handle/) {
        return 1 if $self->_check_prefix( $s_symbol, q/$/, $_ );
    }
    if ( $self->{_custom} ) {
        my $s_custom_prefixes = $self->_get_custom_prefixes;
        return 1 if $self->_check_prefix( $s_symbol, q/$/, qq/($s_custom_prefixes)/ );
    }
    return 0;
}

sub _b_check_list {
    my ( $self, $s_symbol, $s_raw_type ) = @_;
    return 1 if $s_symbol =~ /\@ARGV/;
    for (qw/array hash/) {
        next if !$self->_check_prefix( $s_symbol, $s_raw_type, $_ );
        return $_ eq 'hash' && $s_raw_type ne '%' ? 0 : $_ eq 'array' && $s_raw_type ne '@' ? 0 : 1;
    }
    return 0;
}

sub _check_prefix {
    my ( $self, $s_symbol, $s_raw_type, $s_key ) = @_;
    my $s_rx_scalar = q/\\/ . $s_raw_type . ( $self->{ q/_/ . $s_key } // $s_key );
    return $s_symbol =~ /^$s_rx_scalar/ ? 1 : 0;
}

1;    # Magic true value required at end of module

__END__

=head1 NAME

Perl::Critic::Policy::Variables::RequireHungarianNotation - Critic policy for hungarian notation.

=head1 VERSION

Version 0.0.7

=head1 SYNOPSIS

=head1 DESCRIPTION

Don't let anyone guess which type you expect in your code:

    my @array    = ();    # don't do this
    my %hash     = ();    # or this
    my $hashref  = {};    # or this
    my $arrayref = [];    # or this
    my $string   = '';    # or this

The policy is also running through sub declarations.    

    # won't work
    sub some_sub {
        my ($self, $arrayref, $string) = @_;
        ...
    }

Instead, do this:

    my @a_array     = (); # do this
    my %h_hash      = (); # and this
    my $hr_hashref  = {}; # and this
    my $ar_arrayref = []; # and this
    my $s_string    = ''; # and this

    # this will (hopefuly)
    sub some_sub {
        my ($self, $ar_arrayref, $s_string) = @_;
        ...
    }

$self as variable is excluded.

=head1 SUBROUTINES/METHODS

=head2 expl()

Returns a string containing an explanation of this policy.

=head2 supported_parameters
 
Return an array with information about the parameters supported.
 
    my @supported_parameters = $policy->supported_parameters();

=head2 default_severity

Returns a numeric constant defining the severity of violating this policy.

=head2 default_themes

Returns a list of strings defining the themes for this policy.

=head2 applies_to

Returns a string describing the elements to which this policy applies.

=head2 violates

Check an element for violations against this policy.
 
    my $o_policy->violates( $o_element, $o_document );

=head2 desc()

Returns a string containing a sort description of this policy.

=head1 INTERFACE 

L<Perl::Critic::Policy|Perl::Critic::Policy>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Each prefix is full configurable for it's own

=head2 array

Prefix for Array vars.

    [Variables::RequireHungarianNotation]
    array = a_

=head2 hash

Prefix for Hash vars.

    [Variables::RequireHungarianNotation]
    hash = h_

=head2 array_ref

Prefix for Arrayref vars.

    [Variables::RequireHungarianNotation]
    array_ref = ar_

=head2 hash_ref

Prefix for Hashref vars.

    [Variables::RequireHungarianNotation]
    hash_ref = hr_

=head2 code_ref

Prefix for Coderef vars.

    [Variables::RequireHungarianNotation]
    code_ref = cr_

=head2 object

Prefix for Object vars.

    [Variables::RequireHungarianNotation]
    object = o_

=head2 integer

Prefix for Integer vars.

    [Variables::RequireHungarianNotation]
    integer = i_

=head2 float

Prefix for Float vars.

    [Variables::RequireHungarianNotation]
    float = f_

=head2 string

Prefix for String vars.

    [Variables::RequireHungarianNotation]
    string = s_

=head2 boolean

Prefix for Boolean vars.

    [Variables::RequireHungarianNotation]
    boolean = b_

=head2 regex

Prefix for predefined regular expressions.

    [Variables::RequireHungarianNotation]
    regex = rx_

=head2 self

Ingore self is the class variable for it's own.

    [Variables::RequireHungarianNotation]
    self = this

=head2 custom

A space-separated list of possible types you can append by your own style.

    [Variables::RequireHungarianNotation]
    custom = inv obj any


=head1 DEPENDENCIES

L<Perl::Critic::Policy|Perl::Critic::Policy>, L<Perl::Critic::Utils|Perl::Critic::Utils>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to 
L<https://gitlab.com/mziescha/Perl-Critic-Policy-Variables-RequireHungarianNotation/issues>.

=head1 AUTHOR

Mario Zieschang  C<< <mziescha -at - cpan -dot- org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018, Mario Zieschang. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic|perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
