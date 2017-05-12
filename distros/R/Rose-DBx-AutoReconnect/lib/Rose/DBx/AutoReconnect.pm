package Rose::DBx::AutoReconnect;
use strict;
use warnings;
use Carp;
use base qw( Rose::DB );
use Rose::DBx::Cache::Anywhere;

our $VERSION = '0.04';

__PACKAGE__->db_cache_class('Rose::DBx::Cache::Anywhere');
__PACKAGE__->use_private_registry(1);

DBI->trace(1) if $ENV{PERL_DEBUG} && $ENV{PERL_DEBUG} > 1;

use Rose::Object::MakeMethods::Generic (
    'scalar --get_set_init' => [qw( debug logfh )], );


=head1 NAME

Rose::DBx::AutoReconnect - Rose::DB with auto-reconnect to server

=head1 SYNOPSIS

 use Rose::DBx::AutoReconnect;
 my $db = Rose::DBx::AutoReconnect->new;
 $db->logger('hello world');

=head1 DESCRIPTION

Rose::DBx::AutoReconnect is a subclass of Rose::DB. Additional features
include:

=over

=item

If using new_or_cached() method, will ping() dbh on every fetch from
cache to ensure that the dbh is connected. This extends
the basic Rose::DB::Cache behaviour beyond mod_perl/Apache::DBI.

=item

Convenient logger() method for debugging.

=item

Always uses DBI connect_cached() method when creating handles.

=back

Rose::DBx::AutoReconnect was written to allow new_or_cached() to
work with MySQL's "morning bug" and to allow for restarting
your database without restarting your application. 
See also Rose::DBx::Cache::Anywhere.

=head1 METHODS

=cut

=head2 init_logfh

Defaults to STDERR. Get/set it with logfh().

=cut

sub init_logfh { *STDERR{IO} }

=head2 init_debug

Defaults to value of PERL_DEBUG env var (if set) or 0 (false).
Get/set it with debug().

=cut

sub init_debug { $ENV{PERL_DEBUG} || 0 }

=head2 logger( I<msg> )

Writes I<msg> to the filehandle set with logfh().

=cut

sub logger {
    my $self = shift;
    my @msg  = @_;
    for my $m (@msg) {
        print { $self->logfh } join( ' ', $self->loglabel, $m, "\n" );
    }
}

=head2 loglabel

Returns a pretty timestamp and label. Used by logger().

=cut

sub loglabel {
    my $self = shift;
    my $time = localtime();
    return '[' . $time . '] ' . '[' . $self->nick . '] ';
}

=head2 nick

Returns pretty label unique to this DB object. Used by loglabel().

=cut

sub nick {
    my $self = shift;
    return join( '.',
        $self->domain, $self->type, $self->database . '@' . ($self->host||'localhost') );
}

=head2 dbi_connect

Override base method to use DBI connect_cached() method.

=cut

sub dbi_connect {
    my $self = shift;
    $self->logger("   ---------> dbi->connect") if $self->debug;
    return DBI->connect_cached(@_);
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-dbx-autoreconnect at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rose-DBx-AutoReconnect>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rose::DBx::AutoReconnect

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rose-DBx-AutoReconnect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rose-DBx-AutoReconnect>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-DBx-AutoReconnect>

=item * Search CPAN

L<http://search.cpan.org/dist/Rose-DBx-AutoReconnect>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT

Copyright 2008 by the Regents of the University of Minnesota.
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

