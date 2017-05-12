package Scrapar::Extractor::_fromsub;

use strict;
use warnings;
use base qw(Scrapar::Extractor::_base);

sub new {
    my $class = shift;
    my $code_ref = shift;

    die "Only code-ref is accepted" unless ref $code_ref eq 'CODE';

    bless {
	code_ref => $code_ref,
    } => ref($class) || $class;
}

sub extract {
    my $self = shift;
    my $content = shift;
    return $self->{code_ref}->($content);
}

1;
