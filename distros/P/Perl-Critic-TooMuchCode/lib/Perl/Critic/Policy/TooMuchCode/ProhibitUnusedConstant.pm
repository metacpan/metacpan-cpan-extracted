package Perl::Critic::Policy::TooMuchCode::ProhibitUnusedConstant;

use strict;
use warnings;
use Perl::Critic::Utils;
use PPIx::Utils::Traversal qw(get_constant_name_elements_from_declaring_statement);
use Scalar::Util qw(refaddr);
use parent 'Perl::Critic::Policy';

use Perl::Critic::TooMuchCode;

sub default_themes       { return qw( maintenance )     }
sub applies_to           { return 'PPI::Document' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my %defined_constants;
    my %used;

    my $include_statements = $elem->find(sub { $_[1]->isa('PPI::Statement::Include') }) || [];
    for my $st (@$include_statements) {
        next unless $st->schild(0) eq 'use' && $st->module eq 'constant';
        my @constants = get_constant_name_elements_from_declaring_statement( $st );
        for my $tok (@constants) {
            push @{ $defined_constants{"$tok"} }, $st;
        }
    }

    for my $el_word (@{ $elem->find( sub { $_[1]->isa('PPI::Token::Word') }) ||[]}) {
        my $st = $el_word->statement;
        if ($defined_constants{"$el_word"}) {
            for my $st (@{ $defined_constants{"$el_word"} }) {
                unless ($el_word->descendant_of($st)) {
                    $used{"$el_word"}++;
                }
            }
        }
    }

    ## Look for the signature of misparsed ternary operator.
    ## https://github.com/adamkennedy/PPI/issues/62
    ## Once PPI is fixed, this workaround can be eliminated.
    Perl::Critic::TooMuchCode::__get_terop_usage(\%used, $doc);

    my @violations;
    my @to_report = grep { !$used{$_} } (sort keys %defined_constants);
    for my $tok (@to_report) {
        for my $el (@{ $defined_constants{$tok} }) {
            push @violations, $self->violation( 'Unused constant', "A constant <$tok> is defined but not used.", $el );
        }
    }

    return @violations;
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitUnusedConstant -- Find unused constants.

=head1 DESCRIPTION

This policy finds constant declarations by "constant" pragma, and further looks to see if they exist in the rest of the code.
(The scope of searching is within the same file.)

It identifies constants defined in two simple forms, such as:

    use constant PI => 3.14;

... and

    use constant { PI => 3.14, TAU => 6.28 };

=cut
