#!/usr/bin/perl
package SQL::QueryBuilder::Pretty::Print;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw(croak);
use Data::Dumper;

sub new {
    my $class = shift;
    my %self  = (
        '-indent_ammount' => 4,
        '-indent_char'    => ' ',
        '-new_line'       => "\n",
        @_,
        'indent_level'      => 0,
        'indent_multiplier' => 1,
        'skip_next_space'   => 0,
        'query'             => undef,
    );

    return bless { %self }, ref $class || $class;
}

sub _generic_method {
    my $self = shift;
    my $key  = shift;

    $self->{ $key } = shift if defined $_[0];

    return $self->{ $key };
}

sub current_indent {
    my $self = shift;

    return  
        $self->indent_char x ( $self->indent_level * $self->indent_ammount );
}

sub indent {
    my $self = shift;
    my $multiplier = shift || 1;

    $self->indent_level(+1 * $multiplier);
    $self->var( $self->current_indent );

    return 1;
}

sub indent_ammount { return shift->{'-indent_ammount'}; }
sub indent_char    { return shift->{'-indent_char'};    }

sub indent_level {
    my $self = shift;

    $self->{'indent_level'} += shift if defined $_[0];

    return $self->{'indent_level'} >= 0 ? $self->{'indent_level'} : 0;
}

sub indent_multiplier { return shift->_generic_method( 'indent_multiplier',  @_ ); }

sub new_line {
    my $self = shift;
    $self->var( $self->{'-new_line'} );
    return 1;
}

sub query { return shift->{'query'}; }

sub unindent {
    my $self       = shift;
    my $multiplier = shift || 1;

    $self->indent_level(-1 * $multiplier);
    $self->var( $self->current_indent );

    return 1;
}

sub var {
    my $self = shift;
    $self->{'query'} .= shift;
    return 1;
}

sub skip_next_space  { 
    return shift->_generic_method( 'skip_next_space'  ,  @_ ); 
}

1;
__END__
=head1 NAME

SQL::QueryBuilder::Pretty::Print - Query construction object for
SQL::QueryBuilder::Pretty's rules.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use SQL::QueryBuilder::Pretty::Print;

    my $print = SQL::QueryBuilder::Pretty::Print->new(
        '-indent_ammount' => 4,
        '-indent_char'    => ' ',
        '-new_line'       => "\n",
    );

    $print->var('SELECT');
    $print->new_line;
    $print->indent(2);

    $print->var('*');
    $print->new_line;
    $print->unindent;
    
    $print->var('FROM');
    $print->new_line;
    $print->indent;

    $print->var('table_name`;');

=head1 DESCRIPTION

Query construction object for SQL::QueryBuilder::Pretty's rules.

=head2 METHODS

=over 4

=item I<PACKAGE>->new(I<%options>)

Initializes the object. See OPTIONS.

=item I<$obj>->current_indent

Returns the current indentation spaces.

=item I<$obj>->indent([$multiplier])

Increase the indentation level by 1 * $multiplier and appends the current 
indentation to the query. If no $multiplier is given it uses 1.

=item I<$obj>->indent_ammount

Returns the '-indent_amount' option value.

=item I<$obj>->indent_char

Returns the '-indent_char' option value.

=item I<$obj>->indent_level([$add])

Retturns the current indent level. Add $add to the indent level if set.

=item I<$obj>->indent_multiplier([$new_value])

Returns the current indent multiplier. Sets indent multiplier to $new_value
if set;

=item I<$obj>->new_line

Appends a new line to the query.

=item I<$obj>->query

Returns the constructed query.

=item I<$obj>->unindent([$multiplier])

Decrease the indentation level by 1 * $multiplier and appends the current 
indentation to the query. If no $multiplier is given it uses 1.

=item I<$obj>->var($value);

Appends $value to the query.

=item I<$obj>->skip_next_space([0|1])

Returns/sets skip next space variable.

=back

=head2 OPTIONS

=over 4

=item -indent_amount

The number of time '-indent_char' is repeated for each indentation. Default is 4.

=item -indent_char 

Indent char used. Default is ' '.

=item -new_line

New line char used. default is "\n", 

=back

=head1 SEE ALSO

L<SQL::QueryBuilder::Pretty> and L<SQL::QueryBuilder::Pretty::Rule>.

=head1 AUTHOR

André Rivotti Casimiro, C<< <rivotti at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by André Rivotti Casimiro. Published under the terms of 
the Artistic License 2.0.

=cut
