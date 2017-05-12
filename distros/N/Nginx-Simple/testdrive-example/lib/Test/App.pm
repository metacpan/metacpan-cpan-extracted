package Test::App;

use strict;

use Nginx::Simple::Dispatch( app_path => '/foo', auto_import => 1 );

sub primary :Index
{
    my $self = shift;

    $self->print('Good morning, sir (or madam)!<br>');
    $self->print('Learn <a href="./about/">about</a> our project!<br>');
    $self->print('Enter the <a href="./members/">members</a> area.');
}

sub about :Action
{
    my $self = shift;
    $self->print('Who knows..');   
}

####### methods

sub init
{
    my $self = shift;

}

sub cleanup
{
    my $self = shift;

    my $time = localtime;
    my $page = $self->uri;
    my $status = $self->status;

    my $ftime = sprintf("%f", $self->elapsed_time);

    warn "[$time]\t$ftime\t$status\t$page\n";
}

sub bad_dispatch
{
    my $self = shift;

    $self->{not_found} = 1;

    $self->status(404);
    $self->print('Path not found');
}

sub error
{
    my $self  = shift;
    my $error = $self->get_error;
    my @stack = $self->error_stack;

    $self->status(500);
    $self->print('Holy smokes it went kaboooom!');
}

1;
