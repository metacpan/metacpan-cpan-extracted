#!/usr/bin/perl
package SQL::QueryBuilder::Pretty::Rule;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw(croak);
use Data::Dumper;

sub new {
    my $class = shift;
    return bless { @_ }, ref $class || $class;
}

sub action {
    my $self  = shift;
    my $print = shift;
    my $token = shift;

    $print->var($token);

    return 1;
}

sub match { croak 'Must subclass match!'; }
sub name  { return ( ref shift ) =~ /::([^:]+)$/; }
sub order { return 999 }
sub type  { croak 'Must subclass type!'; }

1;
__END__
=head1 NAME

SQL::QueryBuilder::Pretty::Rule - Base module for 
SQL::QueryBuilder::Pretty's rules.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    package SQL::QueryBuilder::Pretty::Database::ANSI::LogicOperator;
    use base qw(SQL::QueryBuilder::Pretty::Rule);

    sub order { return 70 }

    sub match { 
        return qr/
            AND|OR
        /x;
    }

    sub action {
        my $self  = shift;
        my $print = shift;
        my $token = shift;

        $print->new_line;
        $print->var( $print->current_indent );
        $print->var($token);

        return 1;
    }

    1;

=head1 DESCRIPTION

Base object for SQL::QueryBuilder::Pretty's rules.

=head2 METHODS

=over 4

=item I<PACKAGE>->new()

Initializes the object.

=item I<$obj>->action($print_object, $token)

THe action to be executed on match. Must return 1 to skip the next rules.

$print_object is a L<SQL::QueryBuilder::Pretty::Print> object.

$token is the result of the match.

=item I<$obj>->match

Returns the match regular expression for this rule.

=item I<$obj>->name

Returns the name of the rule. By default the pm file. Not used yet.

=item I<$obj>->order

Returns the order value for this rule. Default is 999.

=item I<$obj>->type

Returns the type of this rule. Not used yet.

=back

=head1 SEE ALSO

L<SQL::QueryBuilder::Pretty> and L<SQL::QueryBuilder::Pretty::Print>.

=head1 AUTHOR

André Rivotti Casimiro, C<< <rivotti at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by André Rivotti Casimiro. Published under the terms of 
the Artistic License 2.0.

=cut
