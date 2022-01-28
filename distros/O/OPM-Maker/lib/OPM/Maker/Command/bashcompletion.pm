package OPM::Maker::Command::bashcompletion;
$OPM::Maker::Command::bashcompletion::VERSION = '1.17';
use strict;
use warnings;

# ABSTRACT: build bash completion script

use Carp qw(croak);
use Path::Class;

use OPM::Maker -command;

sub abstract {
    return "create bash completion script and enable it for the user";
}

sub opt_spec {
    return ();
}

sub usage_desc {
    return "opmbuild bashcompletion";
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $app = $self->app;

    my %commands = map {
        my ($short) = (split /::/, $_)[-1];
        $short => $_;
    } grep {
        $_ =~ m{\AOPM::Maker::Command};
    } $app->command_plugins;

    my %completion_data;

    CMD:
    for my $cmd ( sort keys %commands ) {
        my $module = $commands{$cmd};

        my @opts = map {
            my $opt_spec = $_->[0] // '';
            my $opt_name = ( split /=/, $opt_spec )[0];
            $opt_name ? '--' . $opt_name : ();
        } $module->opt_spec;

        $completion_data{$cmd} = \@opts;
    }

    my $bash_completion = $self->_bash_completion( %completion_data );
    $self->_create_bash_completion_files( $bash_completion );
}

sub _create_bash_completion_files {
    my ($self, $content) = @_;

    my $base = dir( $ENV{HOME} );
    my $completion = $base->file( '.bash_completion' );
    if ( !-f $completion->stringify ) {
        my $completion_content = q!
for bcfile in ~/.bash_completion.d/* ; do
  . $bcfile
done
        !;

        $completion->spew( $completion_content );
    }

    my $dir = $base->subdir( '.bash_completion.d' );
    if ( !-d $dir->stringify ) {
        $dir->mkpath;
    }

    my $opmbuild_completion = $dir->file('opmbuild');
    $opmbuild_completion->spew( $content );
}

sub _bash_completion {
    my ($self, %data) = @_;

    my $subcommands = join ' ', sort keys %data;

    my @subcommand_data;

    CMD:
    for my $cmd ( sort keys %data ) {
        next CMD if !@{ $data{$cmd} || [] };

        my $case = sprintf q~        %s)
            local %s_opts="%s"
            COMPREPLY=( $(compgen -W "${%s_opts}" -- ${cur}) )
            return 0
            ;;~,
            $cmd,
            $cmd,
            ( join ' ', @{ $data{$cmd} || [] } ),
            $cmd
        ;

        push @subcommand_data, $case;
    }

    my $subcommand_opts = join "\n", @subcommand_data;

    my $completion_script = sprintf q~
_opmbuild()
{
    local cur prev opts base

    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    opts="%s"

    case "${prev}" in
        opmbuild)
            ;;
%s
        *)
            compopt -o nospace
            COMPREPLY=( $( compgen -d -f -- $cur ) )
            return 0
            ;;
    esac

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0;
}

complete -F _opmbuild opmbuild
    ~,
        $subcommands,
        $subcommand_opts
    ;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Maker::Command::bashcompletion - build bash completion script

=head1 VERSION

version 1.17

=head1 DESCRIPTION

This command will create a bash completion script for I<opmbuild>
and its installed subcommands.

It generates a I<~user/.bash_completion> script if it doesn't exist and
create a I<~user/.bash_completion.d/opmbuild> file. The latter describes
all the subcommands and their options.

The command assumes, that the user's home directory is in C<$ENV{HOME}>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
