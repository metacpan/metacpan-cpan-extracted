package MooX::Commander;

use Moo;

use Class::Load qw/load_class/;
use String::CamelSnakeKebab qw/upper_camel_case/;
use Syntax::Keyword::Junction qw/any/;
use Path::Tiny;

our $VERSION = "0.03";

has base_class   => (is => 'rw');
has class_prefix => (is => 'rw', default => sub { "Cmd" });
has version      => (is => 'lazy');

sub _build_version {
    my $self = shift;
    load_class($self->base_class);
    my $program = path($0);
    my $version = $self->base_class . "::VERSION";
    no strict 'refs';
    print $program->basename . " $${version}\n";
    exit;
}

sub dispatch {
    my ($self, %params) = @_;
    my $argv = [@{ $params{argv} }]; # make a copy of the array

    (print($self->version->(), "\n") && exit 1)
        if $argv->[0]
        && $argv->[0] eq any(qw/-v --version/);

    unshift @$argv, 'help' if $argv->[0] && $argv->[0] eq any(qw/-h --help/);
    unshift @$argv, 'help' unless $argv->[0];

    my @args;
    while (my $arg = shift @$argv) {
        last if $arg =~ /^--?/;
        push @args, $arg;
    }

    my $action = upper_camel_case shift @args;
    my $class = $self->base_class . "::" . $self->class_prefix . "::" . $action;
    eval { load_class($class) };
    if ($@) {
        eval {
            my $start = $self->base_class . "::" . $self->class_prefix;
            my $class =  "${start}::Help";
            eval { load_class($class) };
            if ($@) {
                print "subcommand not found\n";
                exit 1;
            }

            $class->new(argv => $params{argv})->usage;
        };
    };

    $class->new(argv => $params{argv})->go(@args);
    die $@ if $@;
}

1;
__END__

=encoding utf-8

=head1 NAME

MooX::Commander - Build command line apps with subcommands and option parsing

=head1 SYNOPSIS

    # EXAMPLE
    # MooX::Commander helps you build a command line app like this:
    $ bin/pie-factory --help
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
      -v, --version  Show version
      -h, --help     Show this message

    
    # HOW TO DISPATCH TO COMMAND CLASSES
    # inside bin/pie-factory:
    my $commander = MooX::Commander->new(
        base_class   => 'PieFactory',
        class_prefix => 'Cmd',  # optional, default value is 'Cmd'
        version      => 'v1.0', # optional. default lazy loads $PieFactory::VERSION
    );
    $commander->dispatch(argv => \@ARGV);

    # HOW TO BUILD A COMMAND CLASS
    # inside lib/PieFactory/Cmd/Throw.pm
    package PieFactory::Cmd::Throw;
    sub go {
        my ($self, $pie, $target) = @_;
        # throw $pie at the $target
    }

    # HOW TO ADD OPTION PARSING TO A COMMAND CLASS
    # See L<MooX::Command::HasOptions>

    # HOW TO BUILD A HELP SUBCOMMAND
    # See L<MooX::Command::IsaHelpCommand>

    # HOW TO BUILD A SUBSUBCOMMAND
    # See L<MooX::Command::HasSubcommands>


=head1 DESCRIPTION

MooX::Commander makes it easy to add commands and option parsing to your
command line application a la git.  

This module instantiates the command class requested by the user and calls the
C<go()> method on the object.  C<@ARGV> is passed to the command class
and saved in the C<argv> attribute.

If a user passes in no args or C<--help> or C<-h> the C<help> command class is 
instantiated and the C<usage()> method is called on that object.

=head1 WHAT THIS MODULE DOES NOT DO

This module doesn't dynamically generate usage/help statements.  I wasn't
interested in solving that problem.  I think its not possible or very difficult
to do well and usually leads to a very complex and verbose user interface and a
one size fits all usage/help output that is inflexible and poorly formatted.  

I also suspect people who really care about the usability of their command line
applications want to tweak help output based on the situation and their
personal preferences.  Or maybe thats just me.

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut

