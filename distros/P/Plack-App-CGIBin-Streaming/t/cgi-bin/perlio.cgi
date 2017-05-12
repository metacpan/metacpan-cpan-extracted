#!/usr/bin/perl

{
    package Test::IO;

    use 5.014;
    use strict;
    use warnings;

    sub PUSHED {
        my ($class, $mode, $fh) = @_;

        return bless {buf=>[]}, $class;
    }

    sub POPPED {
        my ($self, $fh) = @_;

        # warn "the other POPPED ($self)";
        delete $self->{buf};

        return;
    }

    sub WRITE {
        my ($self, $stuff, $fh) = @_;

        return length $stuff unless defined $self->{buf};

        # warn "the other WRITE ($self)";
        push @{$self->{buf}}, $stuff;

        return length $stuff;
    }

    sub FLUSH {
        my ($self, $fh) = @_;

        # warn "the other FLUSH 1 ($self)";
        return 0 unless defined $self->{buf};

        # warn "the other FLUSH 2";
        print $fh join('', @{$self->{buf}}, "\nbuffered\n") if @{$self->{buf}};

        return 0;
    }

    sub FILL {
        die "This layer supports write operations only";
    }
}

BEGIN {push @main::loaded, __FILE__}

if ($ENV{QUERY_STRING} eq 'buffer') {
    binmode STDOUT, ':via(Test::IO)';
}

my $output=<<"EOF";
Content-Type: text/plain; charset=$cs

a bit of content
EOF

print $output;
