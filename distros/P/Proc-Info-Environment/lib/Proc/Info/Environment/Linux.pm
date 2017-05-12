###########################################
package Proc::Info::Environment::Linux;
###########################################
use strict;
use warnings;
use base qw(Proc::Info::Environment);

###########################################
sub env {
###########################################
    my($self, $pid) = @_;

    if(!defined $pid) {
        die "Variable \$pid not defined";
    }

    my $file = "/proc/$pid/environ";

    if(! open FILE, "<$file") {
        $self->error( "Cannot open $file ($!)" );
        return undef;
    }

    local $/ = undef;

    my $data = <FILE>;
    close FILE;

    my %found = ();

    for my $chunk (split /\0/, $data) {
        my($key, $value) = split /=/, $chunk, 2;

        ###l4p DEBUG("Found in env of pid=$pid: key=$key value=$value");

        $found{ $key } = $value;
    }

    return \%found;
}

1;

__END__

=head1 NAME

Procinfo::Environment::Linux

=head1 SYNOPSIS

    Not used directly.

=head1 DESCRIPTION

Subclass of Procinfo::Environment providing support for Linux.

=head1 LEGALESE

Copyright 2010 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2010, Mike Schilli <cpan@perlmeister.com>
