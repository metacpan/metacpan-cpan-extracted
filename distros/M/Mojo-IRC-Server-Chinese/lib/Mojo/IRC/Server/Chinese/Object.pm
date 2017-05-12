package Mojo::IRC::Server::Chinese::Object;
use Mojo::IRC::Server::Chinese::Base 'Mojo::EventEmitter';
use Data::Dumper;
sub dump {
    my $s = shift;
    print Dumper $s;
}
sub servername{
    my $s = shift;
    $s->{_server}->servername;
}
sub serverident{
    my $s = shift;
    $s->{_server}->ident;
}

sub new_channel {
    my $s= shift;
    return $s->{_server}->new_channel(@_);
}
sub search_channel{
    my $s = shift;
    return $s->{_server}->search_channel(@_);
}
sub search_user{
    my $s = shift;
    return $s->{_server}->search_user(@_);
}

sub die{
    my $s = shift; 
    $s->{_server}->die(@_);
    $s;
}
sub info{
    my $s = shift;
    $s->{_server}->info(@_);
    $s;
}
sub warn{
    my $s = shift;
    $s->{_server}->warn(@_);
    $s;
}
sub error{
    my $s = shift;
    $s->{_server}->error(@_);
    $s;
}
sub fatal{
    my $s = shift;
    $s->{_server}->fatal(@_);
    $s;
}
sub debug{
    my $s = shift;
    $s->{_server}->debug(@_);
    $s;
}
1;
