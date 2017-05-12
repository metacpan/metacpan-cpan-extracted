package TodoTagger;

# an example subclass

use strict; use warnings;
use Data::Dumper;
use lib qw( ../lib );
use Perl::Tags;
use parent 'Perl::Tags::Naive';

sub get_parsers {
    my $self = shift;
    return (
        $self->can('todo_line'),
        $self->SUPER::get_parsers()
    );
}

sub todo_line {
    # has to be put before 'trim' parser, otherwise the comment line will have gone!
    my ($self, $line, $statement, $file) = @_;

    return unless $statement;
    if ($statement =~ /^\s*#?\s*TODO/) {
       return My::Tag::Todo->new(
                name => 'TODO',
                file => $file,
                line => $line,
                linenum => $.,
       )
    }
    return;
}

package My::Tag::Todo;
our @ISA = qw/Perl::Tags::Tag/;

sub type { 'TODO' }

1;

