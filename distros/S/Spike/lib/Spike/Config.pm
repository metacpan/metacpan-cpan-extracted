package Spike::Config;

use strict;
use warnings;

use feature 'state';

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %args = @_;

    my $handler = sub {
        state $config ||= bless { %args }, "${class}::Section";

        if (@_) {
            my $section = shift;
            return $config->$section(@_);
        }

        return $config;
    };

    return bless $handler, "${class}::Accessor";
}

package Spike::Config::Parse;

sub set         { $_[0] = $_[1] }

sub defined     { $_[0] // $_[1] // '' }
sub def         { $_[0] // $_[1] // '' }

sub integer     { no warnings 'numeric'; CORE::int($_[0] // $_[1] // 0) }
sub int         { no warnings 'numeric'; CORE::int($_[0] // $_[1] // 0) }

sub number      { no warnings 'numeric'; 0 + ($_[0] // $_[1] // 0) }
sub num         { no warnings 'numeric'; 0 + ($_[0] // $_[1] // 0) }

sub boolean     { !!($_[0] // $_[1]) }
sub bool        { !!($_[0] // $_[1]) }

sub string      { ''.($_[0] // $_[1] // '') }
sub str         { ''.($_[0] // $_[1] // '') }

package Spike::Config::Accessor;

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;

    (my $key = $AUTOLOAD)   =~ s/^.*:://;
    (my $class = ref $self) =~ s/::[^:]*$//;

    return $self->()->$key(@_);
}

sub DESTROY {}

package Spike::Config::Section;

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;

    (my $key = $AUTOLOAD)   =~ s/^.*:://;
    (my $class = ref $self) =~ s/::[^:]*$//;

    my $section = bless $self->{$key} ||= {}, "${class}::Value";

    if (@_) {
        my $value = shift;
        return $section->$value(@_);
    }

    return $section;
}

sub DESTROY {}

package Spike::Config::Value;

use Carp;

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;

    (my $key = $AUTOLOAD)   =~ s/^.*:://;
    (my $class = ref $self) =~ s/::[^:]*$//;

    if (@_) {
        my $format = shift;
        my $method = "${class}::Parse::${format}";

        if (defined *{$method}) {
            no strict 'refs';
            return $method->($self->{$key}, @_);
        }
        else {
            carp "Unknown format: $format";
        }
    }

    return $self->{$key};
}

sub DESTROY {}

1;
