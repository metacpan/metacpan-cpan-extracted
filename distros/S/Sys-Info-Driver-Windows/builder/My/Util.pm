package My::Util;
use strict;
use warnings;
use vars qw( @EXPORT_OK );
use base qw( Exporter   );
use Carp qw( croak      );

@EXPORT_OK = qw( is_gcc4 write_detect_h );

sub write_detect_h {
    # for some reason, mingw bundled with strawberry returns 3
    # if you check the major version macro in XS
    require IO::File;
    my $FH = IO::File->new;
    $FH->open( 'detect.h', '>' ) or croak "Can't open detect.h for writing: $!";
    print {$FH} _detect_h_content() or croak "Can't print to FH: $!";
    $FH->close;
    return 1;
}

sub _detect_h_content {
    my $gcc4 = is_gcc4() ? 1 : 0;
    my $raw  = <<"RAW";
#define GCC4 $gcc4

#if defined(__MINGW32__) && (!GCC4)
#include "include/mingw32/intrin.h"
#else
#include <intrin.h>
#endif

RAW
    return $raw;
}

sub is_gcc4 {
    require Config;
    my $cc = $Config::Config{cc} || return;
    return if $cc !~ m{ gcc(?:[.]exe)? \z }xmsi;
    my $v = capture($cc, '-v');
    return if ! $v;
    my @buf = split m{\n}xms, $v;
    my $vline = pop @buf;
    return if ! $vline;
    if ( $vline =~ m{gcc \s version \s ([\d.]+) \s }xms ) {
        my $version = $1;
        return $version ge '4.0';
    }
    return;
}

sub capture {
    my @cmd = @_;
    require Capture::Tiny;
    warn "CAPTURE: @cmd\n";
    return Capture::Tiny::capture_merged( sub { qx{@cmd} } );
}

1;

__END__
