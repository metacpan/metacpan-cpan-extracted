package Plucene::Plugin::WeightedQueryParser;
use 5.006;
use strict;
use warnings;
our $VERSION = '1.0';
use base 'Plucene::QueryParser';
__PACKAGE__->mk_accessors("weights");

=head1 NAME

Plucene::Plugin::WeightedQueryParser - Specify weights for unqualified terms

=head1 SYNOPSIS

  use Plucene::Plugin::WeightedQueryParser;
  my $parser = Plucene::WeightedQueryParser->new({
          analyzer => Plucene::Plugin::Analyzer::PorterAnalyzer->new(),
          weights  => {
            title => 5,
            subtitle => 2,
            body => 1
          }
  });
  $parser->parse($q); 

=head1 DESCRIPTION

Quite often, you want unqualified search terms (C<hello>) to search in 
either the title, the body or some other part of you document. The usual
way to do this is to create another field, C<content>, and throw everything
in that, then make that the default field for unqualified terms.

That's fine, until you want to add different weighting for terms - so terms
found in the title of a document come first, then those in the subtitle,
then the body of the document.

This module automatically remaps unqualified search terms, such as C<hello>
to C<(title:hello^5 OR subtitle:hello^2 OR body:hello^1)>, based on the
weights passed in to the constructor.

=cut

sub new {
    my ($self, $args) = @_;
    $args->{default} = "unused";
    $self->SUPER::new($args);
}

sub parse {
    my ($self, $thing) = @_;
    my $ast = $self->SUPER::parse($thing, 1);
    # First, rebless the AST into our derived class.
    (ref $self)->rebless($ast);
    $ast->to_plucene($self->{weights});
}

sub rebless {
    my ($class, $t) = @_;
    if ($t->isa("Plucene::QueryParser::Subquery")) {
        $class->rebless($_) for @{$t->{subquery}};
    } elsif ($t->isa("Plucene::QueryParser::TopLevel")) {
        $class->rebless($_) for @$t;
    }
    my $new_class = ref $t;
    $new_class =~ s/Plucene::QueryParser/$class/;
    bless $t, $new_class;
}

package Plucene::Plugin::WeightedQueryParser::TopLevel;
use base 'Plucene::QueryParser::TopLevel';

package Plucene::Plugin::WeightedQueryParser::Subquery;
use base 'Plucene::QueryParser::Subquery';

package Plucene::Plugin::WeightedQueryParser::Term;
use base 'Plucene::QueryParser::Term';
sub to_plucene {
    my ($self, $weights) = @_;
    return $self->SUPER::to_plucene() if exists $self->{field};
    require Plucene::Search::BooleanQuery;
    require Plucene::Search::BooleanClause;
    my $query = new Plucene::Search::BooleanQuery;

    for my $field (keys %$weights) {
        my $q = $self->SUPER::to_plucene($field);
        $q->boost($weights->{$field});
        $query->add_clause(Plucene::Search::BooleanClause->new({
            prohibited => 0, required => 0, query => $q
        }));
    }
    $query;
}

package Plucene::Plugin::WeightedQueryParser::Phrase;
use base 'Plucene::QueryParser::Phrase';
sub to_plucene {
    my ($self, $weights) = @_;
    return $self->SUPER::to_plucene() if exists $self->{field};
    require Plucene::Search::BooleanQuery;
    require Plucene::Search::BooleanClause;
    my $query = new Plucene::Search::BooleanQuery;

    for my $field (keys %$weights) {
        my $q = $self->SUPER::to_plucene($field);
        $q->boost($weights->{$field});
        $query->add_clause(Plucene::Search::BooleanClause->new({
            prohibited => 0, required => 0, query => $q
        }));
    }
    $query;
}

package Plucene::Plugin::WeightedQueryParser::Prefix;
use base 'Plucene::QueryParser::Prefix';
sub to_plucene {
    my ($self, $weights) = @_;
    return $self->SUPER::to_plucene() if exists $self->{field};
    require Plucene::Search::BooleanQuery;
    require Plucene::Search::BooleanClause;
    my $query = new Plucene::Search::BooleanQuery;

    for my $field (keys %$weights) {
        my $q = $self->SUPER::to_plucene($field);
        $q->boost($weights->{$field});
        $query->add_clause(Plucene::Search::BooleanClause->new({
            prohibited => 0, required => 0, query => $q
        }));
    }
    $query;
}

1;

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

Development of this module was made possible by the generous sponsorship
of Text Matters, http://www.textmatters.com/

This module may be distributed under the same terms as Plucene itself.

=head1 SEE ALSO

L<perl>.

=cut

1;
