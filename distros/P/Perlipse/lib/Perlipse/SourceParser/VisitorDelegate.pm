package Perlipse::SourceParser::VisitorDelegate;

use strict;
use fields qw(cache);

use Module::Pluggable
  require     => 1,
  except      => 'Perlipse::SourceParser::Visitors::Visitor',
  search_path => ['Perlipse::SourceParser::Visitors'];

=head1 NAME

Perlipse::SourceParser::VisitorDelegate -- parser visitor delegate

=cut

sub new
{
    my $class = shift;
    my $self  = fields::new($class);

    $self->{cache} = {};

    return $self;
}

sub endVisit
{
    my $self = shift;
}

sub visit
{
    my $self = shift;
    my ($element, $ast) = @_;

    my $visitor = _find_visitor($self, $element);

    if ($visitor)
    {
        return $visitor->visit($element, $ast);
    }

    return;
}

## private

sub _find_visitor
{
    my $self = shift;
    my ($element) = @_;

    my $class = $element->class;

    if (!exists $self->{cache}->{$class})
    {
        foreach my $plugin ($self->plugins)
        {
            # printf "plugin: %s\n", $plugin;
            
            if (!$plugin->accepts($element))
            {
                next;
            }

            $self->{cache}->{$class} = $plugin;
            last;
        }
    }

    return $self->{cache}->{$class};
}

1;
