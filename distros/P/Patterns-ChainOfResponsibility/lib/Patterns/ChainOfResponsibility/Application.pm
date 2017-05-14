package Patterns::ChainOfResponsibility::Application;
 
use Moose;

has handlers => (
    is => 'ro',
    isa => 'ArrayRef[Object]',
    required => 1,
);

sub process {
    my ($self, @args) = @_;
    my ($first, @rest) =  @{$self->handlers};
    $first
      ->next_handlers(@rest)
      ->process(@args);
}
 
=head1 NAME
 
Patterns::ChainOfResponsibility::Application - Chain of Responsiblity application

=head1 SYNOPSIS

    use Patterns::ChainOfResponsibility::Application;
    use MyApp::HanderOne;
    use MyApp::HanderTwo;

    my %opts = (
        handlers => [
            MyApp::HandlerOne->new(),
            MyApp::HandlerTwo->new(),
        ],
    );

    my $application = Patterns::ChainOfResponsibility::Application->new(%opts);
    $application->process(@args);

=head1 DESCRIPTION

A wrapper application that contains a bunch of instances of
L<Patterns::ChainOfResponsibility::Role::Handler>.
 
=head1 AUTHOR

John Napiorkowski C<< <jnapiork@cpan.org> >> 
 
=head1 LICENSE & COPYRIGHT
 
Copyright 2011, John Napiorkowski C<< <jjnapiork@cpan.org> >>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=cut

1;
