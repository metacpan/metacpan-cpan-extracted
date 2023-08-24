package Namespace::Subroutines;
use v5.18;
use strict;
use warnings;
use attributes;
use Carp       qw( carp );
use File::Find ();
use feature 'say';

our $VERSION = '0.02';

my %skip = (
    AUTOLOAD               => 1,
    BEGIN                  => 1,
    MODIFY_CODE_ATTRIBUTES => 1,
    FETCH_CODE_ATTRIBUTES  => 1,
);

sub find {
    my ( $ns, $cb ) = @_;

    # 'My::App::Controller' -> 'My/App/Controller'
    my $ns2 = $ns =~ s/::/\//gr;

    my @modules;
    foreach my $path (@INC) {
        next unless -d $path;
        File::Find::find(
            sub {
                return unless /\.pm$/;
                my $name = $File::Find::name =~ s/$path\///r;
                return unless $name =~ /^$ns2/;
                push @modules, [ $name, $File::Find::name ];
            },
            $path
        );
    }

    foreach my $m (@modules) {
        my ( $modname, $path ) = @$m;

        # 'Data/Dumper.pm' -> qw(Data Dumper.pm)
        my @a = split( m{/}, $modname );
        pop @a;                             # qw(Data)
        my $namespace = join( '/', @a );    # 'Data'

        # 'My/App/Controller/Users.pm', 'My/App/Controller/Inventory.pm', etc.
        next             unless $namespace =~ /^$ns2/;
        require $modname unless defined $INC{$modname};

        my $module = $modname;              # 'My/App/Controller/Users.pm'
        $module =~ s/\.pm$//;               # 'My/App/Controller/Users'
        $module =~ s/\//::/g;               # 'My::App::Controller::Users'
        $module .= '::';                    # 'My::App::Controller::Users::'
        my $table = '%' . $module;          # '%My::App::Controller::Users::'

        ## no critic (BuiltinFunctions::ProhibitStringyEval)
        my @symbols     = split( /\|/, eval "join('|', keys $table)" );
        my @subroutines = grep { defined &{ $module . $_ } } @symbols;
        my %subroutines;

        open my $fh, '<', $path or ( carp "unable to open $!" and next );
        while ( my $line = <$fh> ) {
            next unless $line =~ /^sub\s+(\w+)[\:\(\s]/;
            $subroutines{$1} = 1;
        }
        close $fh or ( carp "error closing $!" and next );

        # 'My::App::Controller::Users::' -> 'Users'
        $module =~ s/^$ns\::(.+)::$/$1/;

        foreach my $sub (@subroutines) {
            next if $skip{$sub};
            next unless $subroutines{$sub};
            my $name  = join( '::', $ns, $module, $sub );
            my $ref   = \&$name;
            my @attrs = attributes::get( \&$name );
            $cb->( [ split( /::/, $module ) ], $sub, $ref, \@attrs );
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Namespace::Subroutines - Finds subroutines in namespace (attributes included).

=head1 SYNOPSIS

    use Namespace::Subroutines;

    Namespace::Subroutines::find(
        'My::App::Controller',
        sub ( $mod, $subname, $subref, $attrs ) {
            # $mod     = [qw( My App Controller Home )]
            # $subname = 'foo'
            # $subref  = sub {...}
            # $attrs   = [qw( GET )]
        }
    );

    package My::App::Controller::Home;
    sub foo :GET {}

=head1 DESCRIPTION

Namespace::Subroutines is a module that explores your @INC in order
to seek out every module placed within the given namespace. Then,
invokes your callback once for every subroutine found in each module.

=head2 Considerations

There is one thing to be aware of.
This module uses a very simple strategy to decide which subroutines to pick:
From all the subroutines present in the module's symbol table,
Namespace::Subroutines will keep only those that are explicitly defined.
Basically, this module will check each line in the module's source code file
and if it starts with a subroutine definition, that subroutine is picked.
(regex: $line =~ /^sub\s+(\w+)[\:\(\s]/)

=head2 Use case: Autogenerate Mojolicious application routes

    my $r = $self->routes;
    Namespace::Subroutines::find(
        'My::App::Controller',
        sub ( $mod, $subname, $subref, $attrs ) {
            my $controller = join( '::', $mod->@* );
            my $path       = '/' . lc join( '/', $mod->@*, $subname );
            foreach my $verb ( $attrs->@* ) {
                $verb = lc $verb;
                $r->$verb($path)
                  ->to( controller => $controller, action => $subname );
            }
        }
    );

    package My::App::Controller::Home;

    sub welcome :GET ($self) { # <-- GET is defined in My::App domain
        $self->render( msg => 'Hello, world!' );
    }

=head1 LICENSE

Copyright (C) José Manuel Rodríguez D..

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

José Manuel Rodríguez D. E<lt>nyrdz@cpan.orgE<gt>

=cut

