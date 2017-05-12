package Sprocket::Logger::Basic;

use strict;
use warnings;

sub new {
    my $class = shift;
    bless( {}, ref $class || $class );
}

sub put {
    my ($self, $sprocket, $opts) = @_;

    return unless ( $opts->{v} <= $sprocket->{opts}->{log_level} );
    my $con = $sprocket->{heap};
    my $sender = ( $con )
        ? ( $con->peer_addr ? $con->peer_addr : '' )."(".$con->ID.")" : "?";
    my $l = $opts->{l} ? $opts->{l}+2 : 2;
    my $caller = $opts->{call} ? $opts->{call} : ( caller($l) )[3] || '?';
    $caller =~ s/^POE::Component/PoCo/o;
    $caller =~ s/^Sprocket::Plugin/SPlugin/o;
    print STDERR '['.localtime()."][pid:$$][$sprocket->{connections}][$caller][$sender] $opts->{msg}\n";
}

1;

__END__

=pod

=head1 NAME

Sprocket::Logger::Basic - Basic logging for Sprocket

=head1 SYNOPSIS

my $log = Sprocket::Logger::Basic->new();
$log->put( $server, { v => 4, msg => 'Hello world' } );

=head1 ABSTRACT

Sprocket::Logger::Basic logs to STDERR and 

=head1 METHODS

=over 4

=item put( $sprocket_component => { v => $log_level, msg => $log_msg } );

$sprocket_component is either a client or server object.  This will write a log line
out to STDERR.

=back

=head1 SEE ALSO

L<Sprocket>

=head1 AUTHOR

David Davis E<lt>xantus@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2007 by David Davis

Same as Perl, see the L<LICENSE> file

=cut


