#line 1
package Test2::Event::Exception;
use strict;
use warnings;

our $VERSION = '1.302073';


BEGIN { require Test2::Event; our @ISA = qw(Test2::Event) }
use Test2::Util::HashBase qw{error};

sub causes_fail { 1 }

sub summary {
    my $self = shift;
    chomp(my $msg = "Exception: " . $self->{+ERROR});
    return $msg;
}

sub diagnostics { 1 }

1;

__END__

#line 88
