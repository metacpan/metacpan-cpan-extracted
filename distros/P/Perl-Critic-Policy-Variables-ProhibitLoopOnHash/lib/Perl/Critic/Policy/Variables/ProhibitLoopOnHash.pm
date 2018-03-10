package Perl::Critic::Policy::Variables::ProhibitLoopOnHash;
our $AUTHORITY = 'cpan:XSAWYERX';
# ABSTRACT: Don't write loops on hashes, only on keys and values of hashes

use strict;
use warnings;
use parent 'Perl::Critic::Policy';

use Carp qw< croak >;
use Perl::Critic::Utils qw< :severities :classification :ppi >;
use List::Util 'first';

our $VERSION = '0.001';

use constant 'DESC' => 'Looping over hash instead of hash keys or values';
use constant 'EXPL' => 'You are accidentally looping over the hash itself '
                   . '(both keys and values) '
                   . 'instead of only keys or only values';

# \bfor(each)?(\s+my)?\s*\$\w+\s*\(\s*%
sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'bugs' }
sub applies_to { 'PPI::Token::Word' }

sub violates {
    my ($self, $elem) = @_;

    $elem->isa('PPI::Token::Word')
        and first { $elem eq $_ } qw< for foreach map grep >
        or  return ();

    # This is how we do it:
    # * First, we clear out scoping (like "my" for "foreach my ...")
    # * Second, we clear out topical variables ("foreach $foo (...)")
    # * Then we check if it's a postfix without parenthesis
    # * Lastly, we handle the remaining cases

    # for my $foo (%hash)
    # we simply skip the "my"
    if ( ( my $scope = $elem->snext_sibling )->isa('PPI::Token::Word') ) {
        if ( first { $scope eq $_ } qw< my our local state > ) {
            $elem = $scope->snext_sibling;
        } else {
            # for keys %hash
        }
    }

    # for $foo (%hash)
    # we simply skip the "$foo"
    if ( ( my $topical = $elem->snext_sibling )->isa('PPI::Token::Symbol') ) {
        if ( $topical->snext_sibling->isa('PPI::Structure::List') ) {
            $elem = $topical;
        } else {
            # for $foo (%hash);
        }
    }

    # for %hash
    # (postfix without parens)
    _check_symbol_or_cast( $elem->snext_sibling )
        and return $self->violation( DESC(), EXPL(), $elem );

    # for (%hash)
    if ( ( my $list = $elem->snext_sibling )->isa('PPI::Structure::List') ) {
        my @children = $list->schildren;
        @children > 1
            and croak "List has multiple significant children ($list)";

        if ( ( my $statement = $children[0] )->isa('PPI::Statement') ) {
            my @statement_args = $statement->schildren;

            _check_symbol_or_cast( $statement_args[0] )
                and return $self->violation( DESC(), EXPL(), $statement );
        }
    }

    return ();
}

sub _check_symbol_or_cast {
    my $arg = shift;

    # This is either a variable
    # or casting from a variable (or from a statement)
    $arg->isa('PPI::Token::Symbol') && $arg =~ /^%/xms
        or $arg->isa('PPI::Token::Cast') && $arg eq '%'
        or return;

    my $next_op = $arg->snext_sibling;

    # If this is a cast, we want to exhaust the block
    # the block could include anything, really...
    if ( $arg->isa('PPI::Token::Cast') && $next_op->isa('PPI::Structure::Block') ) {
        $next_op = $next_op->snext_sibling;
    }

    # Safe guard against operators
    # for ( %hash ? ... : ... );
    $next_op && $next_op->isa('PPI::Token::Operator')
        and return;

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Variables::ProhibitLoopOnHash - Don't write loops on hashes, only on keys and values of hashes

=head1 VERSION

version 0.001

=head1 DESCRIPTION

When "looping over hashes," we mean looping over hash keys or hash values. If
you forgot to call C<keys> or C<values> you will accidentally loop over both.

    foreach my $foo (%hash) {...} # not ok
    action() for %hash;           # not ok

An effort is made to detect expressions:

    action() for %hash ? keys %hash : ();                        # ok
    action() for %{ keys $hash{'stuff'} ? $hash{'stuff'} : {} }; # ok

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 AUTHOR

Sawyer X, C<xsaawyerx@cpan.org>

=head1 THANKS

Thank you to Rudd H.G. Van Tol.

=head1 SEE ALSO

L<Perl::Critic>

=head1 AUTHOR

Sawyer X

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
