package Perl::Critic::Policy::TooMuchCode::ProhibitUnusedImport;

use strict;
use warnings;
use Perl::Critic::Utils;
use parent 'Perl::Critic::Policy';

use Perl::Critic::TooMuchCode;
use Perl::Critic::Policy::Variables::ProhibitUnusedVariables;

sub default_themes       { return qw( maintenance )     }
sub applies_to           { return 'PPI::Document' }
sub supported_parameters {
    return (
        {
            name        => 'ignored_modules',
            description => 'Modules which will be ignored by this policy.',
            behavior    => 'string list',
            list_always_present_values => [
                'Exporter',
                'Getopt::Long',
                'Git::Sub',
                'MooseX::Foreign',
                'MouseX::Foreign',
                'Test::Needs',
                'Test::Requires',
                'Test::RequiresInternet',
            ],
        },
        {
            name        => 'moose_type_modules',
            description => 'Modules which import Moose-like types.',
            behavior    => 'string list',
            list_always_present_values => [
                'MooseX::Types::Moose',
                'MooseX::Types::Common::Numeric',
                'MooseX::Types::Common::String',
            ],
        },
    );
}

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $moose_types =  $self->{_moose_type_modules};

    my %imported;
    $self->gather_imports_generic( \%imported, $elem, $doc );

    my %used;
    for my $el_word (
        @{
            $elem->find(
                sub {
                    $_[1]->isa('PPI::Token::Word')
                        || ( $_[1]->isa('PPI::Token::Symbol')
                        && $_[1]->symbol_type eq '&' );
                }
                )
                || []
        }
    ) {
        if ( $el_word->isa('PPI::Token::Symbol') ) {
            $el_word =~ s{^&}{};
        }
        $used{"$el_word"}++;
    }

    Perl::Critic::TooMuchCode::__get_symbol_usage(\%used, $doc);

    my @violations;
    my @to_report = grep { !$used{$_} } (keys %imported);

    # Maybe filter out Moose types.
    if ( @to_report ) {
        my %to_report = map { $_ => 1 } @to_report;

        for my $import ( keys %to_report ) {
            if ( exists $used{ 'is_' . $import } || exists $used { 'to_' . $import }
                && exists $moose_types->{$imported{$import}->[0]} ) {
                delete $to_report{$import};
            }
        }
        @to_report = keys %to_report;
    }
    @to_report = sort { $a cmp $b } @to_report;

    for my $tok (@to_report) {
        for my $inc_mod (@{ $imported{$tok} }) {
            push @violations, $self->violation( "Unused import: $tok", "A token is imported but not used in the same code.", $inc_mod );
        }
    }

    return @violations;
}

sub gather_imports_generic {
    my ( $self, $imported, $elem, $doc ) = @_;

    my $is_ignored =  $self->{_ignored_modules};
    my $include_statements = $elem->find(sub { $_[1]->isa('PPI::Statement::Include') && !$_[1]->pragma }) || [];
    for my $st (@$include_statements) {
        next if $st->schild(0) eq 'no';
        my $expr_qw = $st->find( sub { $_[1]->isa('PPI::Token::QuoteLike::Words'); }) or next;

        my $included_module = $st->schild(1);
        next if exists $is_ignored->{$included_module};

        if (@$expr_qw == 1) {
            my $expr = $expr_qw->[0];
            my @words = $expr_qw->[0]->literal;
            for my $w (@words) {
                next if $w =~ /\A [:\-\+]/x;

                push @{ $imported->{$w} //=[] }, $included_module;
            }
        }
    }
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitUnusedImport -- Find unused imports

=head1 DESCRIPTION

An "import" is a subroutine brought by a C<use> statement.

From the documentation of L<use>, there are several forms of calling `use`. This policy scans for the following two forms:

    use Module VERSION LIST
    use Module LIST

... and only the one with LIST written in C<qw()>.

Conventionally the LIST after c<use Module> is known as arguments and
conventionally when it is written with C<qw()>, the LIST is treated as
a import list -- which is a list of symbols that becomes avaiable in
the current namespace.

For example, the word C<baz> in the following statement is one of such:

    use Foo qw( baz );

Symbols in the import list are often subroutine names or variable
names. If they are not used in the following program, they do not neet
to be imported.

Although an experienced perl programmer would know that the
description above is only true by convention, there are many modules
on CPAN that already follows such convetion. Which is a good one to
follow, and I recommend you to follow.

This policy checks only import lists written in C<qw()>, other forms
are ignored, or rather, too complicated to be correctly supported.

The syntax of C<Importer> module is also supported, but only the ones
with C<qw()> at the end.

    use Importer 'Foo' => qw( baz );

Modules with non-trivial form of arguments may have nothing to with
symbol-importing. But it might be used with a C<qw()> LIST at the end.
Should you wish to do so, you may let chose to let perlcritic to
ignore certain modules by setting the C<ignored_modules> in
C<.perlcriticrc>. For example:

    [TooMuchCode::ProhibitUnusedImport]
    ignored_modules = Git::Sub Regexp::Common

Alternatively, you may choose not to write the module arguments as a
C<qw()> list.

=head2 Moose Types

Moose Types can also be imported, but their symbols may not be used
as-is. Instead, some other helper functions are generated with names
based on the Type. For example:

    use My::Type::Library::Numeric qw( PositiveInt );
    use My::Type::Library::String qw( LowerCaseStr );

    my $foo = 'Bar';
    my $ok  = is_PositiveInt($foo);
    my $lower = to_LowerCaseStr($foo);

The module C<My::Type::Library::Numeric> exports
C<is_PositiveInt> as well as C<PositiveInt>. While C<PositiveInt> is
not directly used in the following code, is should be considered as
being used. Similar for C<LowerCaseStr>.

When importing from a Type library, subroutines named like C<is_*> and C<to_*>
are not in the import list, but they are also imported.

By default, the following modules are treated as Type libraries

    * MooseX::Types::Moose
    * MooseX::Types::Common::Numeric
    * MooseX::Types::Common::String

The list can be grown by including your module names to the
C<moose_type_modules> in the C<.perlcriticrc>:

    [TooMuchCode::ProhibitUnusedImport]
    moose_type_modules = My::Type::Library::Numeric My::Type::Library::String

=cut
