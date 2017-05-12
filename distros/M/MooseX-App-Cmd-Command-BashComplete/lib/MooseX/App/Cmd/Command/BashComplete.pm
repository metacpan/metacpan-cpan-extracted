package MooseX::App::Cmd::Command::BashComplete;
use Moose;
extends 'MooseX::App::Cmd::Command';

our $VERSION = '0.04';

use MooseX::Getopt;

sub execute {
    my ($self, $opts, $args) = @_;

    my @commands = grep {
        !/bashcomplete|-h|--help|-\?|help|commands/
    } $self->app->command_names;

    my %command_map = ();
    for my $cmd (@commands) {
        $command_map{$cmd} 
            = [$self->app->plugin_for($cmd)->_attrs_to_options()];
    }

    my $cmd_list = join ' ', @commands;
    my $package  = __PACKAGE__;
    my $prefix = $self->app->arg0;
    $prefix =~ tr/./_/;

    print <<"EOT";
#!/bin/bash

# Built with $package;

${prefix}_COMMANDS='help commands bashcomplete $cmd_list'

_${prefix}_macc_help() {
    if [ \$COMP_CWORD = 2 ]; then
        _${prefix}_compreply "\$${prefix}_COMMANDS"
    else
        COMPREPLY=()
    fi
}

_${prefix}_macc_commands() {
    COMPREPLY=()
}

_${prefix}_macc_bashcomplete() {
    COMPREPLY=()
}

EOT

    while (my ($c, $o) = each %command_map) {
        print "_${prefix}_macc_$c() {\n    _compreply \"",
            join(" ", map {"--" . $_->{name}} @$o),
                "\"\n}\n\n";
    }


print <<"EOT";

_${prefix}_compreply() {
    COMPREPLY=(\$(compgen -W "\$1" -- \${COMP_WORDS[COMP_CWORD]}))
}

_${prefix}_macc() {
    case \$COMP_CWORD in
        0)
            ;;
        1)
            _${prefix}_compreply "\$${prefix}_COMMANDS"
            ;;
        *)
            eval _${prefix}_macc_\${COMP_WORDS[1]}
            
    esac
}

EOT

    print "complete -o default -F _${prefix}_macc ", $self->app->arg0, "\n";
}


1;
__END__

=head1 NAME

MooseX::App::Cmd::Command::BashComplete - Bash completion for your MooseX::App::Cmd programs.


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

 package MyApp::Command::BashComplete;
 use Moose;
 extends 'MooseX::App::Cmd::Command::BashComplete';

 ...

 bash$ myapp bashcomplete > myapp-complete.sh
 bash$ source myapp-complete.sh

=head1 DESCRIPTION

This package provides you with a way for getting bash auto completion
for your MooseX::App::Cmd programs. What you have to do is to add a
module under the same namespace as the other MooseX::App::Cmd::Command
modules that extends MooseX::App::Cmd::Command::BashComplete (See the
synopsis). Doing so will give you a command that outputs a shell
script to STDOUT. This script can be saved and then sourced by bash
(again, see the synopsis).

=head1 AUTHOR

Kjell-Magne Øierud, C<< <kjellm at acm.org> >>


=head1 BUGS

Please report any bugs or feature requests to
C<bug-moosex-app-cmd-command-bashcomplete at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-App-Cmd-Command-BashComplete>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Copyright 2009 Kjell-Magne Øierud.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
