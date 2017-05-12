package Net::SSH::Any::SCP::Getter::Content;

use strict;
use warnings;

require Net::SSH::Any::SCP::Getter;
our @ISA = qw(Net::SSH::Any::SCP::Getter);

sub _new {
    my ($class, $any, $opts, @srcs) = @_;
    my $g = $class->SUPER::_new($any, $opts, @srcs);
    $g->{content} = '';
    $g;
}

sub on_write {
    my $g = shift;
    $g->{content} .= $_[1];
    1;
}

sub run {
    my $g = shift;
    $g->SUPER::run(@_);
    return $g->{content};
}

1;
