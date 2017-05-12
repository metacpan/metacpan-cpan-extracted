package MooX::Commander::HasSubcommands;

use Moo::Role;
use String::CamelSnakeKebab qw/upper_camel_case/;
use Class::Load qw/load_class/;

has argv => (is => 'rw', required => 1);

around 'usage' => sub { 
    my $orig = shift;
    my $self = shift;
    my $message = shift;
    print $message . "\n" if $message;
    print $self->$orig(@_);
    exit 1;
};

sub go {
    my ($self, @args) = @_;

    my $action = upper_camel_case shift @args || $self->usage;
    my $class  = ref($self) . "::" . $action;
    eval { load_class($class) };
    #die $@ if $@;
    $self->usage if $@;

    $class->new(argv => $self->argv)->go(@args);
    die $@ if $@;
}

1;

=encoding utf-8

=head1 NAME

MooX::Commander::HasSubcommands - Moo role to add subcommands to your command line app

=head1 SYNOPSIS

    # inside lib/PieFactory/Cmd/Recipes.pm:
    package PieFactory::Cmd::Recipes;
    use Moo;
    with 'MooX::Commander::HasSubcommands';

    usage {
       return <<EOF
    Subcommands for: piefactory recipes

    piefactory recipe list             List pie recipes
    piefactory recipe add <recipe>     Display a recipe
    piefactory recipe delete <recipe>  Add a recipe
    piefactory recipe show <recipe>    Delete a recipe

    EOF
    }

    # Create these classes the same way you would build any command class.
    # For details see MooX::Commander and MooX::Commander::HasOptions.
    # lib/PieFactory/Cmd/Recipes/List.pm
    # lib/PieFactory/Cmd/Recipes/Show.pm
    # lib/PieFactory/Cmd/Recipes/Add.pm
    # lib/PieFactory/Cmd/Recipes/Delete.pm


=head1 DESCRIPTION

MooX::Commander::HasSubcommands is a simple Moo::Role thats subcommands to your
command line application.  You can also create sub-subcommands and
sub-sub-subcommands, etc.

It loads and instantiates the subcommand class the user requested
calls the C<go()> method on that object.  C<usage()> works the same
way here as it does in L<MooX::Commander::HasOptions> -- it prints
the usage statement and exits the program unsuccessfuly.

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut

