package Object::Benchmark::BlessedRef;
use strict;
use warnings;

    sub new
        {
            my $self = shift;
            
            my $obj = { title => 'Book title',
                        authors => [ qw/Alice Bob/ ],
                        text => 'text' };
            
            bless $obj, $self;
        }

1;
