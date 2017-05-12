package Trans2;

use strict;
use warnings;

use parent qw(PPI::Transform);

sub new
{
    my ($self, $arg) = @_;
    my $class = ref($self) || $self;
    return bless [ $arg ], $class;
}

sub document
{
    my ($self, $doc) = @_;
    my $count = 0;
    my $quotes = $doc->find('PPI::Token::Quote');
    foreach my $quote (@$quotes) {
        my $content = $quote->content;
        local $_ = $content;
        $self->[0]->();
        if($_ ne $content) {
            $quote->set_content($_);
            ++$count;
        }
    }
    return $count;
}

1;
