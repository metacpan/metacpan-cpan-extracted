package Plucene::Plugin::Analyzer::PorterAnalyzer;
use base 'Plucene::Analysis::Analyzer';
use 5.006;
use strict;
use warnings;
our $VERSION = '1.0';
use Plucene::Analysis::PorterStemFilter;
use Plucene::Analysis::LowerCaseTokenizer;

=head1 NAME 

Plucene::Plugin::Analysis::PorterAnalyzer - the Porter Stemmed analyzer

=head1 DESCRIPTION

Filters LowerCaseTokenizer with PorterStemFilter.

=cut

sub tokenstream {
    my $self = shift;
    return Plucene::Analysis::PorterStemFilter->new({
            input    => Plucene::Analysis::LowerCaseTokenizer->new(@_),
        });
}

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 LICENSE

You may distribute this code under the same terms as Plucene himself.

