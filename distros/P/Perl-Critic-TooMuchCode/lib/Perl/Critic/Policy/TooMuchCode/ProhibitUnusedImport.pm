package Perl::Critic::Policy::TooMuchCode::ProhibitUnusedImport;

use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

our $VERSION = '0.01';

sub default_themes       { return qw( maintenance )     }
sub applies_to           { return 'PPI::Document' }

#---------------------------------------------------------------------------

# special modules, where the args of import do not mean the symbols to be imported.
my %is_special = map { $_ => 1 } qw(Getopt::Long MooseX::Foreign MouseX::Foreign);

sub violates {
    my ( $self, $elem, $doc ) = @_;
    my @violations = $self->gather_violations_generic($elem, $doc);
    return @violations;
}

sub gather_violations_generic {
    my ( $self, $elem, $doc ) = @_;

    my %imported;

    my $include_statements = $elem->find(sub { $_[1]->isa('PPI::Statement::Include') }) || [];
    for my $st (@$include_statements) {
        next if $st->schild(0) eq 'no';
        my $expr_qw = $st->find( sub { $_[1]->isa('PPI::Token::QuoteLike::Words'); }) or next;

        my $included_module = $st->schild(1);
        next if $included_module =~ /\A[a-z:]*\z/ || $is_special{$included_module};

        if (@$expr_qw == 1) {
            my $expr = $expr_qw->[0];

            my $expr_str = "$expr";

            # Given that both PPI and PPR parse this correctly, I don't care about what are the characters used for quoting. We can remove the characters at the position that are supposed to be quoting characters.
            substr($expr_str, 0, 3) = '';
            substr($expr_str, -1, 1) = '';

            my @words = split /\s+/, $expr_str;
            for my $w (@words) {
                next if $w =~ /\A [:\-]/x;
                push @{ $imported{$w} //=[] }, $included_module;
            }
        }
    }

    my %used;
    for my $el_word (@{ $elem->find( sub { $_[1]->isa('PPI::Token::Word') }) ||[]}) {
        $used{"$el_word"}++;
    }

    my @violations;
    my @to_report = grep { !$used{$_} } (sort keys %imported);
    for my $tok (@to_report) {
        for my $inc_mod (@{ $imported{$tok} }) {
            push @violations, $self->violation( 'Unused import', "A token <$tok> is imported but not used in the same code.", $inc_mod );
        }
    }

    return @violations;
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitUnusedImport -- Find unused imports

=head1 DESCRIPTION

An "Unused Import" is usually a subroutine name imported by a C<use> statement.
For example, the word C<Dumper> in the following statement:

    use Data::Dumper qw<Dumper>;

If the rest of program has not mentioned the word C<Dumper>, then it can be deleted.

=cut
