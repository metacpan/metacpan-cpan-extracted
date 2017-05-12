package Sub::Timekeeper;

use 5.008_001;

use strict;
use warnings;

require Exporter;
use Time::HiRes ();

our $VERSION = '0.01';

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(timekeeper);
our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ],
);

sub timekeeper {
    my $guard = Sub::Timekeeper::Guard->new(\$_[0]); shift;
    my $subref = shift;

    return $subref->(@_);
}

# utility class
{
    package # hide from pause
        Sub::Timekeeper::Guard;
    sub new {
        my ($klass, $elapsed) = @_;
        bless [ $elapsed, Time::HiRes::time ], $klass;
    }
    sub DESTROY {
        my $self = shift;
        ${$self->[0]} = Time::HiRes::time - $self->[1];
    }
}

1;
__END__

=head1 NAME

Sub::Timekeeper - calls a function with a stopwatch

=head1 SYNOPSIS

    use Sub::Timekeeper qw(timekeeper);

    my $val = timekeeper(my $elapsed, sub {
        ...
        return $retval;
    });

    my @arr = timekeeper(my $elapsed, sub {
        ...
        return @retarr;
    });

=head1 DESCRIPTION

The module exports the C<timekeeper> function, that can be used to measure the time spent to execute a function.  The duration is set to the first argument in seconds (as a floating point value).

The duration is set regardless of whether the called function returned normally or by an exception.  In other words the following snippet will report the correct duration.

    my $elapsed;
    eval {
        timekeeper($elapsed, sub {
            ...
        }
    };
    if ($@) {
        warn "got error $@ after $elapsed seconds";
    }

=head1 AUTHOR

Kazuho Oku

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
