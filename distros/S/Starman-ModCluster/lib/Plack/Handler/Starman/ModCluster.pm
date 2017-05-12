package Plack::Handler::Starman::ModCluster;

use 5.008_001;
use strict;
use warnings;
use Starman::Server::ModCluster;

use base 'Plack::Handler::Starman';

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub run {
    my($self, $app) = @_; 

    if ($ENV{SERVER_STARTER_PORT}) {
        require Net::Server::SS::PreFork;
        @Starman::Server::ModCluster::ISA = qw(Net::Server::SS::PreFork);
    }   
    
    Starman::Server::ModCluster->new->run($app, {%$self});
}

1;

__END__
=head1 NAME

Plack::Handler::Starman::ModCluster - Plack adapter Starman::ModCluster

=head1 SYNOPSIS

  plackup -s Starman::ModCluster --mc-node-name=myapp1 --mc-uri=http://127.0.0.1:6666 --mc-context="/myapp" --mc-alias="localhost" --mc-host=127.0.0.1


=head1 DESCRIPTION

This handler exists for the C<plackup> compatibility. Essentially,
C<plackup -s Starman::ModCluster> is equivalent to C<starman-modcluster --preload-app>,
because the C<starman-modcluster> executable delay loads the application by
default. See L<starman-modcluster> for more details.

=head1 AUTHOR

Roman Jurkov

=head1 SEE ALSO

L<Starman::ModCluster>

=cut
