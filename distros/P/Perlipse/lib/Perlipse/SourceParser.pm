package Perlipse::SourceParser;

use strict;
use fields qw(visitor);

use Hash::Util;

use PPI::Dumper;
use PPI::Document;

use Perlipse::SourceParser::AST;
use Perlipse::SourceParser::VisitorDelegate;

sub new
{
    my $class = shift;

    my $self = fields::new($class);

    $self->{visitor} = Perlipse::SourceParser::VisitorDelegate->new;

    return $self;
}

sub parse
{
    my $self = shift;
    my %args = @_;
    Hash::Util::lock_keys(%args);

    my $ast  = Perlipse::SourceParser::AST->new;
    my $pdom = PPI::Document->new(\$args{source});
    bless $pdom, 'Perlipse::SourceParser::Document';

    _walk($self, $pdom, $ast);
    _closeout($self, $pdom->last_element, $ast);

    return $ast;
}

sub _closeout
{
    my $self = shift;
    my ($element, $ast) = @_;

    my $last = $element;
    while (!$last->isa('PPI::Statement'))
    {
        $last = $last->previous_sibling;
    }

    if ($last->content !~ /^1/)
    {
        $last = $element;
    }

    my $sEnd = $last->location->[3] - 1;
    $ast->curPkg->sourceEnd($sEnd);
}

sub _walk
{
    my $self = shift;
    my ($element, $ast) = @_;

    foreach my $child ($element->children)
    {
        if ($self->{visitor}->visit($child, $ast))
        {
            if ($child->can('children'))
            {
                $self->_walk($child, $ast);
            }

            $self->{visitor}->endVisit;
        }
    }
}

package Perlipse::SourceParser::Document;
use base qw(PPI::Document);

use strict;

sub index_locations
{
    my $self   = shift;
    my @Tokens = $self->tokens;

    # Whenever we hit a heredoc we will need to increment by
    # the number of lines in it's content section when when we
    # encounter the next token with a newline in it.
    my $heredoc = 0;

    # Find the first Token without a location
    my ($first, $location) = ();
    foreach (0 .. $#Tokens)
    {
        my $Token = $Tokens[$_];
        next if $Token->{_location};

        # Found the first Token without a location
        # Calculate the new location if needed.
        $location =
            $_
          ? $self->_add_location($location, $Tokens[$_ - 1], \$heredoc)
          : [1, 1, 1, 0];
        $first = $_;
        last;
    }

    # Calculate locations for the rest
    foreach ($first .. $#Tokens)
    {
        my $Token = $Tokens[$_];
        $Token->{_location} = $location;
        $location = $self->_add_location($location, $Token, \$heredoc);

        # Add any here-doc lines to the counter
        if ($Token->isa('PPI::Token::HereDoc'))
        {
            $heredoc += $Token->heredoc + 1;
        }
    }

    1;
}

sub _add_location
{
    my ($self, $start, $Token, $heredoc) = @_;
    my $content = $Token->{content};

    $self->{offset} += length($content);

    # Does the content contain any newlines
    my $newlines = () = $content =~ /\n/g;
    unless ($newlines)
    {
        # Handle the simple case
        return [
            $start->[0],
            $start->[1] + length($content),
            $start->[2] + $self->_visual_length($content, $start->[2]),
            $self->{offset},
        ];
    }

    # This is the more complex case where we hit or
    # span a newline boundary.
    my $location = [$start->[0] + $newlines, 1, 1, $self->{offset}];
    if ($heredoc and $$heredoc)
    {
        $location->[0] += $$heredoc;
        $$heredoc = 0;
    }

    # Does the token have additional characters
    # after their last newline.
    if ($content =~ /\n([^\n]+?)\z/)
    {
        $location->[1] += length($1);
        $location->[2] += $self->_visual_length($1, $location->[2]);
        $location->[3] += length($1);
    }

    $location;
}

1;

