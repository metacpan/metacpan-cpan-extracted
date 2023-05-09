package Perl::Critic::TooMuchCode;
use strict;
our $VERSION='0.19';

## Look for the signature of misparsed ternary operator.
## https://github.com/adamkennedy/PPI/issues/62
## Once PPI is fixed, this workaround can be eliminated.
sub __get_terop_usage {
    my ($used, $doc) = @_;
    for my $question_mark (@{ $doc->find( sub { $_[1]->isa('PPI::Token::Operator') && $_[1]->content eq '?' }) ||[]}) {
        my $el = $question_mark->snext_sibling;
        next unless $el->isa('PPI::Token::Label');

        my $tok = $el->content;
        $tok =~ s/\s*:\z//;

        $used->{$tok}++;
    }
}

sub __get_symbol_usage {
    my ($usage, $doc) = @_;

    __get_terop_usage($usage, $doc);

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
__END__

=head1 NAME

Perl::Critic::TooMuchCode - perlcritic add-ons that generally check for dead code.

=head1 DESCRIPTION

This add-on for L<Perl::Critic> is aiming for identifying trivial dead
code. Either the ones that has no use, or the one that produce no
effect. Having dead code floating around causes maintenance burden. Some
might prefer not to generate them in the first place.

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 LICENSE

MIT

=cut
