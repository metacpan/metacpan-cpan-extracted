package Sys::Info::Driver::Unknown::OS;
use strict;
use warnings;
use vars qw( $VERSION );
use POSIX ();
use Sys::Info::Constants qw( :unknown );

$VERSION = '0.78';

# So, we don't support $^O yet, but we can try to emulate some features

BEGIN {
    *is_root     = *uptime
                 = *tick_count
                 = sub { 0 }
                 ;
    *domain_name = *edition
                 = *logon_server
                 = sub {}
                 ;
}

sub meta {
    my $self = shift;
    my %info;

    $info{manufacturer}              = undef;
    $info{build_type}                = undef;
    $info{owner}                     = undef;
    $info{organization}              = undef;
    $info{product_id}                = undef;
    $info{install_date}              = undef;
    $info{boot_device}               = undef;
    $info{physical_memory_total}     = undef;
    $info{physical_memory_available} = undef;
    $info{page_file_total}           = undef;
    $info{page_file_available}       = undef;
    # windows specific
    $info{windows_dir}               = undef;
    $info{system_dir}                = undef;
    $info{system_manufacturer}       = undef;
    $info{system_model}              = undef;
    $info{system_type}               = undef;
    $info{page_file_path}            = undef;

    return %info;
}

sub tz {
    my $self = shift;
    return exists $ENV{TZ}
         ? $ENV{TZ}
         : do {
               require POSIX;
               POSIX::strftime('%Z', localtime);
           };
}

sub fs {
    my $self = shift;
    return(
        unknown => 1,
    );
}

sub name {
    my($self, @args) = @_;
    my %opt   = @args % 2 ? () : @args;
    my $uname = $self->uname;
    my $rv    = $opt{long} ? join(q{ }, $uname->{sysname}, $uname->{release})
              :              $uname->{sysname}
              ;
    return $rv;
}

sub version { return shift->uname->{release} }

sub build {
    my $build = shift->uname->{version} || return;
    if ( $build =~ UN_RE_BUILD ) {
        return $1;
    }
    return $build;
}

sub node_name { return shift->uname->{nodename} }

sub login_name {
    my $name;
    my $eok = eval { $name = getlogin };
    return $name;
}

sub bitness {
    my $self = shift;
    return;
}

1;

__END__

=head1 NAME

Sys::Info::Driver::Unknown::OS - Compatibility layer for unsupported platforms

=head1 SYNOPSIS

-

=head1 DESCRIPTION

This document describes version C<0.78> of C<Sys::Info::Driver::Unknown::OS>
released on C<17 April 2011>.

-

=head1 METHODS

Please see L<Sys::Info::OS> for definitions of these methods and more.

=head2 build

=head2 domain_name

=head2 edition

=head2 fs

=head2 is_root

=head2 login_name

=head2 logon_server

=head2 meta

=head2 name

=head2 node_name

=head2 tick_count

=head2 tz

=head2 uptime

=head2 version

=head2 bitness

=head1 SEE ALSO

L<Sys::Info>, L<Sys::Info::OS>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 - 2011 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.12.3 or, 
at your option, any later version of Perl 5 you may have available.

=cut
