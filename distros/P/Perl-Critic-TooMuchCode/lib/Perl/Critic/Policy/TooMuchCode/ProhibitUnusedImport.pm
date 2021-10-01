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

    __get_symbol_usage(\%used, $doc);

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

sub __get_symbol_usage {
    my ($usage, $doc) = @_;

    ## Look for the signature of misparsed ternary operator.
    ## https://github.com/adamkennedy/PPI/issues/62
    ## Once PPI is fixed, this workaround can be eliminated.
    Perl::Critic::TooMuchCode::__get_terop_usage($usage, $doc);

    Perl::Critic::Policy::Variables::ProhibitUnusedVariables::_get_regexp_symbol_usage($usage, $doc);

    for my $e (@{ $doc->find('PPI::Token::Symbol') || [] }) {
        $usage->{ $e->symbol() }++;
    }

    for my $class (qw{
        PPI::Token::Quote::Double
        PPI::Token::Quote::Interpolate
        PPI::Token::QuoteLike::Backtick
        PPI::Token::QuoteLike::Command
        PPI::Token::QuoteLike::Readline
        PPI::Token::HereDoc
     }) {
        for my $e (@{ $doc->find( $class ) || [] }) {
            my $str = PPIx::QuoteLike->new( $e ) or next;
            for my $var ( $str->variables() ) {
                $usage->{ $var }++;
            }
        }
    }

    # Gather usages in the exact form of:
    #     our @EXPORT = qw( ... );
    #     our @EXPORT_OK = qw( ... );
    for my $st (@{ $doc->find('PPI::Statement::Variable') || [] }) {
        next unless $st->schildren == 5;

        my @children = $st->schildren;
        next unless $children[0]->content() eq 'our'
            && ($children[1]->content() eq '@EXPORT'
                || $children[1]->content() eq '@EXPORT_OK')
            && $children[2]->content() eq '='
            && $children[3]->isa('PPI::Token::QuoteLike::Words')
            && $children[4]->content() eq ';';

        for my $w ($children[3]->literal) {
            $usage->{ $w }++;
        }
    }

    return;
}

1;

=encoding utf-8

=head1 NAME

TooMuchCode::ProhibitUnusedImport -- Find unused imports

=head1 DESCRIPTION

An "Unused Import" is usually a subroutine name imported by a C<use> statement.
For example, the word C<Dumper> in the following statement:

    use Foo qw( baz );

The word C<baz> can be removed if it is not mentioned in the rest of this program.

Conventionally, this policy looks only for the C<use> statement with a C<qw()>
operator at the end. This syntax is easier to deal with. It also works with
the usage of C<Importer> module -- as long as a C<qw()> is there at the end:

    use Importer 'Foo' => qw( baz );

This may be adjusted to be a bit smarter, but it is a clear convention in the
beginning.

Modules which will be ignored, generally because the args of import do not mean
the symbols to be imported.

    [TooMuchCode::ProhibitUnusedImport]
    ignored_modules = Git::Sub Regexp::Common

=head2 Moose Types

When importing types from a Moose type library, you may run into the following
situation:

    use My::Type::Library::Numeric qw( PositiveInt );

    my $foo = 'bar';
    my $ok  = is_PositiveInt($foo);

In this case,  C<My::Type::Library::Numeric> exports C<is_PositiveInt> as well
as C<PositiveInt>.  Even though C<PositiveInt> has not specifically been called
by the code, it should be considered as being used. In order to allow for this case,
you can specify class names of Moose-like type libraries which you intend to
import from.

A similar case exists for coercions:

    use My::Type::Library::String qw( LowerCaseStr );
    my $foo   = 'Bar';
    my $lower = to_LowerCaseStr($foo);

In the above case, C<LowerCaseStr> has not specifically been called by the
code, but it should be considered as being used.

The imports of C<is_*> and C<to_*> from the following modules be handled by
default:

    * MooseX::Types::Moose
    * MooseX::Types::Common::Numeric
    * MooseX::Types::Common::String

You can configure this behaviour by adding more modules to the list:

    [TooMuchCode::ProhibitUnusedImport]
    moose_type_modules = My::Type::Library::Numeric My::Type::Library::String

=cut
