package Panda::Lib;
use parent 'Panda::Export';
use 5.012;
use Encode();
use Time::HiRes();

our $VERSION = '1.3.5';

use Panda::Export
    MERGE_ARRAY_CONCAT => 1,
    MERGE_ARRAY_MERGE  => 2,
    MERGE_COPY_DEST    => 4,
    MERGE_LAZY         => 8,
    MERGE_SKIP_UNDEF   => 16,
    MERGE_DELETE_UNDEF => 32,
    MERGE_COPY_SOURCE  => 64;
use Panda::Export
    MERGE_COPY => MERGE_COPY_DEST | MERGE_COPY_SOURCE;
    
require Panda::XSLoader;
Panda::XSLoader::bootstrap();

*hash_cmp = *compare; # for compability

sub timeout {
    my ($sub, $timeout) = @_;
    if (state $in_debugger = defined $DB::header) { $sub->(); return 1 }
    my ($ok, $alarm, $error);
    local $SIG{ALRM} = sub {$alarm = 1; die "ALARM!"};
    Time::HiRes::alarm($timeout || 1);
    eval {
        eval { $sub->(); 1 } or do { $error = $@ };
        Time::HiRes::alarm(0);
    };
    return if $alarm;
    die $error if $error;
    return 1;
}

sub encode_utf8_struct {
    my $data = shift;
    if (ref($data) eq 'HASH') {
        foreach my $v (values %$data) {
            if (ref $v) { encode_utf8_struct($v) }
            elsif (utf8::is_utf8($v)) { $v = Encode::encode_utf8($v) }
        }
    }
    elsif (ref($data) eq 'ARRAY') {
        map {
            if (ref $_) { encode_utf8_struct($_) }
            elsif (utf8::is_utf8($_)) { $_ = Encode::encode_utf8($_) }
        } @$data;
    }
}


sub decode_utf8_struct {
    my $data = shift;
    if (ref($data) eq 'HASH') {
        foreach my $v (values %$data) {
            if (ref $v) { decode_utf8_struct($v) }
            elsif (!utf8::is_utf8($v)) { $v = Encode::decode_utf8($v) }
        }
    }
    elsif (ref($data) eq 'ARRAY') {
        map {
            if (ref $_) { decode_utf8_struct($_) }
            elsif (!utf8::is_utf8($_)) { $_ = Encode::decode_utf8($_) }
        } @$data;
    }
}

1;
