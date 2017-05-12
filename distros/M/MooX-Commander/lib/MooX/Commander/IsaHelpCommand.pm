package MooX::Commander::IsaHelpCommand;

use Moo::Role;

use String::CamelSnakeKebab qw/upper_camel_case/;
use Class::Load qw/load_class/;

has argv => (is => 'lazy');

around 'usage' => sub { 
    my $orig = shift;
    my $self = shift;
    my $message = shift;
    print $message . "\n" if $message;
    print $self->$orig(@_);
    exit 1;
};

sub go {
    my ($self, $cmd) = @_;

    $self->usage unless $cmd;

    my $class  = ref($self);
    $class =~ s/::Help$/::/;
    $class  .= upper_camel_case $cmd;

    eval { load_class($class) };
    $self->usage if $@;

    $class->new(argv => $self->argv)->usage;
    die $@ if $@;
}

1;

=encoding utf-8

=head1 NAME

MooX::Commander::IsaHelpCommand - Add a help command to your command line app

=head1 SYNOPSIS

    package PieFactory::Cmd::Help;
    use Moo;
    with 'MooX::Commander::IsaHelpCommand';

    sub usage { 
        return >> EOF
    usage: pie-factory [options]

    You have inherited a pie factory.  Use your powers wisely.
    
    COMMANDS
    pie-factory recipe list             List pie recipes
    pie-factory recipe show <recipe>    Display a recipe
    pie-factory recipe add <recipe>     Add a recipe
    pie-factory recipe delete <recipe>  Delete a recipe
    pie-factory bake <pie>              Bake a pie
    pie-factory eat <pie>               Eat a pie
    pie-factory throw <pie> <target>    Throw a pie at something
    pie-factory help <cmd>              Get help with a command

    OPTIONS
    -v, --version  pie-factory version
    -h, --help     Show this message
    EOF
    }


=head1 DESCRIPTION

MooX::Commander::IsaHelpCommand is a simple Moo::Role for adding a help command
to your command line app.  

It loads and instantiates the command class that the user is requesting help
with and calls the C<usage()> method on that object.  C<usage()> works the same
way here as it does in L<MooX::Commander::HasOptions> -- it prints
the usage statement and exits the program unsuccessfuly.

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut

