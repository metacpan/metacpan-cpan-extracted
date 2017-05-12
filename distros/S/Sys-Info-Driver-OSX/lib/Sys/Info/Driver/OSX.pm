package Sys::Info::Driver::OSX;
use strict;
use warnings;
use base qw( Exporter Sys::Info::Base );
use constant SYSCTL_NOT_EXISTS  =>
    qr{top    \s level \s name .+? in .+? is \s invalid}xms,
    qr{second \s level \s name .+? in .+? is \s invalid}xms,
    qr{name                    .+? in .+? is \s unknown}xms,
;
use constant RE_SYSCTL_SPLIT   => qr{\n+}xms;
use constant RE_SYSCTL_ROW     => qr{
    \A
    ([a-zA-Z0-9_.]+) # this must be capturing parenthesis
    (?:\s+)?         # optional space
    [:=]             # the key name termination character
                     # new sysctl uses ":" to separate key/value pairs
}xms;

use Capture::Tiny qw( capture );
use Carp          qw( croak   );
use Mac::PropertyList;

our $VERSION = '0.7958';
our @EXPORT  = qw(
    fsysctl
    nsysctl
    plist
    sw_vers
    system_profiler
    vm_stat
);

sub plist {
    my $thing = shift;
    my $raw   = $thing !~ m{\n}xms && -e $thing
              ? __PACKAGE__->slurp( $thing )
              : $thing;
    my($prop, $fatal);
    eval {
        $prop = Mac::PropertyList::parse_plist( $raw );
        1;
    } or do {
        $fatal = $@ || 'unknown error';
    };

    if ( ! $prop || $fatal ) {
        my $fmt = $fatal ? 'Unable to parse plist(%s): %s'
                :          'Unable to parse plist(%s)'
                ;
        croak sprintf $fmt, $thing, $fatal ? $fatal : ();
    }

    return $prop->as_perl;
}

#
# TODO: https://github.com/aosm/system_cmds/blob/master/vm_stat.tproj/vm_stat.c
#
sub vm_stat {
    my $success;
    my($out, $error) = capture {
        $success = ! system q{/usr/bin/vm_stat};
    };

    warn "vm_stat: $error\n"                   if $error;
    croak "vm_stat call failed!"               if ! $success;
    croak "vm_stat didn't generate any output" if ! $out;

    my @lines     = split m{\n+}, $out;
    my $page_size = shift @lines;

    if ( $page_size =~ m{
            \QMach Virtual Memory Statistics: (page size of\E
                \s (.+?) \s
            bytes\)
        }xms
    ) {
        $page_size = $1;
    }
    else {
        croak "Unable to determine page size from input";
    }

    pop @lines; # some junk info line

    my %rv;

    for my $line ( @lines ) {
        my($k, $v) = split m{[:]}xms, $line, 2;
        $_ = __PACKAGE__->trim( $_ ) for $k, $v;
        $k =~ s{ \A ["']    }{}xms;
        $k =~ s{    ["'] \z }{}xms;
        $k =~ s{    [\s\-]  }{_}xmsg;
        $v =~ s{    [.]  \z }{}xms;
        $rv{lc $k} = $v;
    }

    $rv{page_size}   = $page_size;

    $rv{memory_free} = (  $rv{pages_speculative}
                        + $rv{pages_free}
                        )
                        * $rv{page_size};

    $rv{memory_used} = (  $rv{pages_wired_down}
                        + $rv{pages_inactive}
                        + $rv{pages_active}
                        )
                        * $rv{page_size};
    return %rv;
}

sub system_profiler {
    # SPSoftwareDataType -> os version. user
    # SPHardwareDataType -> cpu
    # SPMemoryDataType   -> ram
    my(@types) = @_;

    my $success;
    my($out, $error) = capture {
        $success = ! system '/usr/sbin/system_profiler' => '-xml', (@types ? @types : ())
    };

    croak "system_profiler(@types) failed!"                      if ! $success;
    croak "system_profiler(@types) did not generate any output!" if ! $out;

    my $raw = plist( $out );

    my %rv;
    foreach my $e ( @{ $raw } ) {
        next if ref $e ne 'HASH' || ! (keys %{ $e });
        my $key     = delete $e->{_dataType};
        my $value   = delete $e->{_items};
        $rv{ $key } = @{ $value } == 1 ? $value->[0] : $value;
    }

    return @types && @types == 1 ? values %rv : %rv;
}

sub sw_vers {
    my $success;
    my($out, $error) = capture {
        $success = ! system '/usr/bin/sw_vers';
    };

    $_ = __PACKAGE__->trim( $_ ) for $out, $error;

    croak "Unable to capture `sw_vers`: $error" if $error || ! $success;

    return map { split m{:\s+?}xms, $_ }
                 split m{\n}xms, $out;
}

sub fsysctl {
    my $key = shift || croak 'Key is missing';
    my $rv  = _sysctl( $key );
    my $val = $rv->{bogus} ? croak "sysctl: $key is not defined"
            : $rv->{error} ? croak "Error fetching $key: $rv->{error}"
            :                $rv->{value}
            ;
    return $val;
}

sub nsysctl {
    my $key = shift || croak 'Key is missing';
    return _sysctl($key)->{value};
}

sub _sysctl {
    my($key) = @_;

    my $success;
    my($out, $error) = capture {
        $success = ! system '/usr/sbin/sysctl' => $key;
    };

    my %rv;
    if ( $out ) {
        foreach my $row ( split RE_SYSCTL_SPLIT, $out ) {
            chomp $row;
            next if ! $row;
            my($name, $value) = _parse_sysctl_row( $row, $key );
            $rv{ $name } = $value;
        }
    }

    my $total = keys %rv;

    $error = __PACKAGE__->trim( $error ) if $error;

    return {
        value   => $total > 1 ? { %rv } : $rv{ $key },
        error   => $error,
        bogus   => $error ? _sysctl_not_exists( $error ) : 0,
        success => $success,
    };
}

sub _parse_sysctl_row {
    my($row, $key) = @_;
    my(undef, $name, $value) = split RE_SYSCTL_ROW, $row, 2;

    if ( ! defined $value || $value eq q{} ) {
        croak sprintf q(Can't happen: No value in output for property )
                     . q('%s' inside row '%s' collected from key '%s'),
                        $name || q([no name]),
                        $row,
                        $key;
    }

    return map { __PACKAGE__->trim( $_ ) } $name, $value;
}

sub _sysctl_not_exists {
    my($error) = @_;
    return if ! $error;
    foreach my $test ( SYSCTL_NOT_EXISTS ) {
        return 1 if $error =~ $test;
    }
    return 0;
}

1;

__END__

=head1 NAME

Sys::Info::Driver::OSX - OSX driver for Sys::Info

=head1 SYNOPSIS

    use Sys::Info::Driver::OSX;

=head1 DESCRIPTION

This document describes version C<0.7958> of C<Sys::Info::Driver::OSX>
released on C<23 October 2013>.

This is the main module in the C<OSX> driver collection.

=head1 METHODS

None.

=head1 FUNCTIONS

=head2 fsysctl

f(atal)sysctl().

=head2 nsysctl

n(ormal)sysctl.

=head2 system_profiler

System call to system_profiler.

=head2 sw_vers

System call to sw_vers.

=head2 vm_stat

System call to vm_stat

=head2 plist

Converts a file or raw plist data into a Perl structure.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2010 - 2013 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.
=cut
