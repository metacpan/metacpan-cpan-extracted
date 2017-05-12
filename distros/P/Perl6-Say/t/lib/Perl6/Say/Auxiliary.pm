package Perl6::Say::Auxiliary;
#$Id: Auxiliary.pm 1344 2009-03-16 03:27:56Z jimk $
# Contains test subroutines for distribution with Perl6::Say
# As of:  March 29, 2009
use strict;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
    _validate
    capture_say
    capture_say_file
    capture_say_scalar
    $capture_fail_message
);
use Carp;
*is = *Test::More::is;

our $capture_fail_message;
eval qq{ require IO::CaptureOutput; };
$capture_fail_message="tests require IO::CaptureOutput" if $@;

sub _validate {
    my $pred = shift;
    croak "2nd argument to capture_STDOUT must be integer"
        unless $pred =~ m/^\d+$/;
    return ($pred == 1) ? q{line} : q{lines};
}

sub capture_say {
    my $argsref = shift;
    my ($str, @list);
    if (ref($argsref->{data}) eq q{ARRAY}) {
        @list = @{$argsref->{data}};
    } else {
        $str  = $argsref->{data};
    }
    my $pred  = $argsref->{pred};
    my $l = _validate($pred);
    my $cat;
    #IO::CaptureOutput->import('capture');
    IO::CaptureOutput::capture(sub { &{$argsref->{eval}}; },\$cat);
    #my $capture = IO::Capture::Stdout->new();
    #$capture->start;
    #&{$argsref->{eval}};
    #$capture->stop;
    #my $cat = join q{}, $capture->read();
    unless ($str) {
        $str = join q{}, @list;
    }
    is($cat, "$str\n", "$pred $l $argsref->{msg}");
}

sub capture_say_file {
    my $argsref = shift;
    my $pred    = $argsref->{pred};
    my $l       = _validate($pred);
    {
        my $tmp = File::Temp->new( DIR => "./t" );
        my $tmpfile = $tmp->filename;
        &{$argsref->{eval}}($tmpfile, $argsref->{data});
        my $slurp;
        open READ, $tmpfile or croak "Cannot open tempfile for reading";
        {
            local $/ = undef;
            $slurp = <READ>;
        }
        close READ or croak "Cannot close tempfile after reading"; 
        my $str;
        (ref($argsref->{data}) eq q{ARRAY})
            ? $str = join q{}, @{$argsref->{data}}
            : $str = $argsref->{data};
        is($slurp, "$str\n", "$pred $l $argsref->{msg}");
    }
}

sub capture_say_scalar {
    my $argsref = shift;
    my $pred    = $argsref->{pred};
    my $l       = _validate($pred);
    my $got = &{$argsref->{eval}}($argsref->{data});
    my $str;
    (ref($argsref->{data}) eq q{ARRAY})
        ? $str = join q{}, @{$argsref->{data}}
        : $str = $argsref->{data};
    is($got, "$str\n", "$pred $l $argsref->{msg}");
}

1;
