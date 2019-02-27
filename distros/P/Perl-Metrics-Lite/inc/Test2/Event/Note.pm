#line 1
package Test2::Event::Note;
use strict;
use warnings;

our $VERSION = '1.302073';


BEGIN { require Test2::Event; our @ISA = qw(Test2::Event) }
use Test2::Util::HashBase qw/message/;

sub init {
    $_[0]->{+MESSAGE} = 'undef' unless defined $_[0]->{+MESSAGE};
}

sub summary { $_[0]->{+MESSAGE} }

1;

__END__

#line 81
