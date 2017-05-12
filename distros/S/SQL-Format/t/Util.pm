package t::Util;
use strict;
use warnings;
use Exporter 'import';
use IO::Handle;
use SQL::Format ();
use Tie::IxHash;
use Test::More;

our @EXPORT = qw(capture_warn mk_errstr mk_test ordered_hashref);

sub capture_warn(&) {
    my $code = shift;

    open my $fh, '>', \my $content;
    $fh->autoflush(1);
    local *STDERR = $fh;
    $code->();
    close $fh;
    
    return $content;
}

sub mk_errstr {
    my ($num, $spec) = @_;
    $spec = quotemeta $spec;
    return qr/missing arguments nummber of $num and '$spec' format in sqlf/;
}

sub mk_test {
    my $method = shift;
    sub {
        local $Test::Builder::Level = $Test::Builder::Level + 2;
        my %specs = @_;
        my ($input, $expects, $desc, $instance) =
            @specs{qw/input expects desc instance/};

        $instance ||= SQL::Format->new;
        subtest "$method(): $desc" => sub {
            my ($stmt, @bind) = $instance->$method(@$input);
            is $stmt, $expects->{stmt};
            is_deeply \@bind, $expects->{bind};
        };
    };
}

sub ordered_hashref {
    tie my %params, Tie::IxHash::, @_;
    return \%params;
}

1;
