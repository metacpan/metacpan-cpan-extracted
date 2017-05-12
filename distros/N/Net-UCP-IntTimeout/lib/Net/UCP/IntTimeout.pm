package Net::UCP::IntTimeout;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw();

our $VERSION = '0.05';

use constant MIN_TIMEOUT     => 0;           # No timeout at all!
use constant DEFAULT_TIMEOUT => 15;
use constant MAX_TIMEOUT     => 60;

sub new { bless({}, shift())->_init(@_); }

sub _init {
    my $self = shift;
    my %opt = @_;

    $self->set($opt{timeout}) if (exists $opt{timeout});
    return $self;
}

sub set {
    my $self = shift;
    my $timeout = shift || DEFAULT_TIMEOUT;

    if ($timeout > MAX_TIMEOUT) {
        $timeout = MAX_TIMEOUT;
    }
    elsif ($timeout < MIN_TIMEOUT) {
        $timeout = MIN_TIMEOUT;
    }
    
    return $self->{timeout} = $timeout;
}

sub get {
    my $self = shift;
    return $self->{timeout};
}

1;
__END__

=head1 NAME

Net::UCP::IntTimeout - Perl Timeout Manager for Net::UCP Module

=head1 SYNOPSIS

  use Net::UCP::IntTimeout;
 
=head1 DESCRIPTION

This module is used by Net::UCP to manage timeout during message transmission

=head2 EXPORT

None 

=head1 SEE ALSO

Net::UCP

=head1 AUTHOR

Marco Romano, E<lt>nemux@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Marco Romano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
