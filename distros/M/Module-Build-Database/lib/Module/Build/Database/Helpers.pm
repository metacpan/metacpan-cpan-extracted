package Module::Build::Database::Helpers;
use strict;
use warnings;
our $VERSION = '0.58';

use File::Which qw( which );

use Sub::Exporter -setup => {
    exports => [
        qw/do_system verify_bin info debug/
    ]
};

sub info($) { print STDERR shift(). "\n" unless $ENV{MBD_QUIET}; }
sub debug($) { print STDERR shift(). "\n" if $ENV{MBD_DEBUG}; }

sub do_system {
    my $silent = ($_[0] eq '_silent' ? shift : 0);
    my $cmd = $_[0];
    if ($ENV{MBD_FAKE} || $ENV{MBD_DEBUG}) {
        info "fake: system call : @_";
        return if $ENV{MBD_FAKE};
    }
    # Carp::cluck("doing------- @_\n");
    system("@_") == 0
      or do {
        return 0 if $silent && !$ENV{HARNESS_ACTIVE};
        warn "# Error with '@_' : $? " . ( ${^CHILD_ERROR_NATIVE} || '' ) . "\n";
        return 0;
      };
    return 1;
}

sub verify_bin {
    my $bin = shift;
    my $try = shift;
    for my $label (keys %$bin) {
        my @look_for = (ref $bin->{$label} eq 'ARRAY' ? @{ $bin->{$label} } : $bin->{$label});
        my $found;
        for my $potential_cmd (@look_for) {
            if(defined $try && -x "$try/$potential_cmd") {
                $found = "$try/$potential_cmd";
                last;
            }
            last if $found = which $potential_cmd;
        }
        unless ($found) {
            warn "could not find ".(join " or ",@look_for)." in current path\n" unless $label =~ /doc/;
            $found = "/bin/false";
        }
        chomp $found;
        $found = Win32::GetShortPathName($found) if $^O eq 'MSWin32' && $found =~ /\s/;
        $bin->{$label} = $found;
    }
}


1;


