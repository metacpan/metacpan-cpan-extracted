package Sys::Info::Base;
$Sys::Info::Base::VERSION = '0.7807';
use strict;
use warnings;

use IO::File;
use Carp qw( croak );
use File::Spec;
use Sys::Info::Constants qw( :date OSID );
use constant DRIVER_FAIL_MSG => q{Operating system identified as: '%s'. }
                              . q{Native driver can not be loaded: %s. }
                              . q{Falling back to compatibility mode};
use constant YEAR_DIFF => 1900;

my %LOAD_MODULE; # cache
my %UNAME;       # cache

sub load_subclass { # hybrid: static+dynamic
    my $self     = shift;
    my $template = shift || croak 'Template missing for load_subclass()';
    my $class;

    my $eok = eval { $class = $self->load_module( sprintf $template, OSID ); };

    if ( $@ || ! $eok ) {
        my $msg = sprintf DRIVER_FAIL_MSG, OSID, $@;
        warn "$msg\n";
        $class = $self->load_module( sprintf $template, 'Unknown' );
    }

    return $class;
}

sub load_module {
    my $self  = shift;
    my $class = shift || croak 'No class name specified for load_module()';
    return $class if $LOAD_MODULE{ $class };
    croak "Invalid class name: $class" if ref $class;
    (my $check = $class) =~ tr/a-zA-Z0-9_://d;
    croak "Invalid class name: $class" if $check;
    my @raw_file = split /::/xms, $class;
    my $inc_file = join( q{/}, @raw_file) . '.pm';
    return $class if exists $INC{ $inc_file };
    my $file = File::Spec->catfile( @raw_file ) . '.pm';
    my $eok  = eval { require $file; };
    croak "Error loading $class: $@" if $@ || ! $eok;
    $LOAD_MODULE{ $class } = 1;
    $INC{ $inc_file } = $file;
    return $class;
}

sub trim {
    my($self, $str) = @_;
    return $str if ! $str;
    $str =~ s{ \A \s+    }{}xms;
    $str =~ s{    \s+ \z }{}xms;
    return $str;
}

sub slurp { # fetches all data inside a flat file
    my $self   = shift;
    my $file   = shift;
    my $msgerr = shift || 'I can not open file %s for reading: ';
    my $FH     = IO::File->new;
    $FH->open( $file ) or croak sprintf($msgerr, $file) . $!;
    my $slurped = do {
       local $/;
       my $rv = <$FH>;
       $rv;
    };
    $FH->close;
    return $slurped;
}

sub read_file {
    my $self   = shift;
    my $file   = shift;
    my $msgerr = shift || 'I can not open file %s for reading: ';
    my $FH     = IO::File->new;
    $FH->open( $file ) or croak sprintf( $msgerr, $file ) . $!;
    my @flat   = <$FH>;
    $FH->close;
    return @flat;
}

sub date2time { # date stamp to unix time stamp conversion
    my $self   = shift;
    my $stamp  = shift || croak 'No date input specified';
    my($i, $j) = (0,0); # index counters
    my %wdays  = map { $_ => $i++ } DATE_WEEKDAYS;
    my %months = map { $_ => $j++ } DATE_MONTHS;
    my @junk   = split /\s+/xms, $stamp;
    my $reg    = join q{|}, keys %wdays;

    # remove until ve get a day name
    while ( @junk && $junk[0] !~ m{ \A $reg \z }xmsi ) {
       shift @junk;
    }
    return q{} if ! @junk;

    my($wday, $month, $mday, $time, $zone, $year) = @junk;
    my($hour,   $min, $sec)                       = split /:/xms, $time;

    require POSIX;
    my $unix =  POSIX::mktime(
                    $sec,
                    $min,
                    $hour,
                    $mday,
                    $months{$month},
                    $year - YEAR_DIFF,
                    $wdays{$wday},
                    DATE_MKTIME_YDAY,
                    DATE_MKTIME_ISDST,
                );

    return $unix;
}

sub uname {
    my $self = shift;
    %UNAME   = do {
        require POSIX;
        my %u;
        @u{ qw( sysname nodename release version machine ) } = POSIX::uname();
        %u;
    } if ! %UNAME;
    return { %UNAME };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Info::Base

=head1 VERSION

version 0.7807

=head1 SYNOPSIS

    use base qw(Sys::Info::Base);
    #...
    sub foo {
        my $self = shift;
        my $data = $self->slurp("/foo/bar.txt");
    }

=head1 DESCRIPTION

Includes some common methods.

=head1 NAME

Sys::Info::Base - Base class for Sys::Info

=head1 METHODS

=head2 load_module CLASS

Loads the module named with C<CLASS>.

=head2 load_subclass TEMPLATE

Loads the specified class via C<TEMPLATE>:

    my $class = __PACKAGE__->load_subclass('Sys::Info::Driver::%s::OS');

C<%s> will be replaced with C<OSID>. Apart from the template usage, it is
the same as C<load_module>.

=head2 trim STRING

Returns the trimmed version of C<STRING>.

=head2 slurp FILE

Caches all contents of C<FILE> into a scalar and then returns it.

=head2 read_file FILE

Caches all contents of C<FILE> into an array and then returns it.

=head2 date2time DATE_STRING

Converts C<DATE_STRING> into unix timestamp.

=head2 uname

Returns a hashref built from C<POSIX::uname>.

=head1 SEE ALSO

L<Sys::Info>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
