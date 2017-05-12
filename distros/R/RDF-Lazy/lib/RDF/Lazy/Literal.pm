package RDF::Lazy::Literal;
use v5.10;
use strict;
use warnings;

use base 'RDF::Lazy::Node';
use Scalar::Util qw(blessed);
use CGI qw(escapeHTML);

use overload '""' => sub { shift->str; };

# not very strict check for language tag look-alikes (see www.langtag.net)
our $LANGTAG = qr/^(([a-z]{2,8}|[a-z]{2,3}-[a-z]{3})(-[a-z0-9_]+)?-?)$/i;

sub new {
    my $class   = shift;
    my $graph   = shift || RDF::Lazy->new;
    my $literal = shift // '';

    my ($language, $datatype) = @_;

    if (defined $language) {
        if ($language =~ $LANGTAG) {
            $datatype = undef;
        } elsif( not defined $datatype ) {
            $datatype = $graph->uri($language)->trine;
            $language = undef;
        }
    }

    $literal = RDF::Trine::Node::Literal->new( $literal, $language, $datatype )
        unless blessed($literal) and $literal->isa('RDF::Trine::Node::Literal');
    return unless defined $literal;

    return bless [ $literal, $graph ], $class;
}

sub str {
    shift->trine->literal_value
}

sub lang {
    my $self = shift;
    my $lang = $self->trine->literal_value_language;
    return $lang if not @_ or not $lang;

    my $xxx = lc(shift || "");
    $xxx =~ s/_/-/g;
    return unless $xxx =~ $LANGTAG;

    if ( $xxx eq "$lang" or $xxx =~ s/-$// and index($lang, $xxx) == 0 ) {
        return $lang;
    }

    return;
}

sub datatype {
    my $self = shift;
    my $type = $self->graph->resource( $self->trine->literal_datatype );
    return $type unless @_ and $type;

    foreach (@_) {
        my $t = $self->graph->uri( $_ );
        return 1 if $t->is_resource and $t->str eq $type->str;
    }

    return;
}

sub _autoload {
    my $self   = shift;
    my $method = shift;

    return unless $method =~ /^is_(.+)$/;

    # We assume that no language is named 'blank', 'literal', or 'resource'
    return 1 if $self->lang($1);

    return;
}

1;
__END__

=head1 NAME

RDF::Lazy::Literal - Literal node in a RDF::Lazy graph

=head1 DESCRIPTION

You should not directly create instances of this class.
See L<RDF::Lazy::Node> for general node properties.

=head1 METHODS

=head2 str

Return the literal string value of this node.

=head2 esc

Return the HTML-encoded literal string value.

=head2 lang ( [ $pattern ] )

Return the language tag (a BCP 47 language tag locator), if this node has one,
or test whether the language tag matches a pattern. For instance use 'de' for
plain German (but not 'de-AT') or 'de-' for plain German or any German dialect.

=head2 is_...

Return whether this node matches a given language tag, for instance

    $node->is_en   # equivalent to $node->lang('en')
    $node->is_en_  # equivalent to $node->lang('en-')

=head2 datatype ( [ @types ] )

Return the datatype (as L<RDF::Lazy::Resource>, if this node has one.
Can also be used to checks whether the datatype matches, for instance:

    $node->datatype('xsd:integer','xsd:double');

=cut
