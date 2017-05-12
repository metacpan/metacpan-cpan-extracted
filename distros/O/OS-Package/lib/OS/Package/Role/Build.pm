use v5.14.0;
use warnings;

package OS::Package::Role::Build;

# ABSTRACT: Provides build method for OS::Package object.
our $VERSION = '0.2.7'; # VERSION

use OS::Package::Log;
use File::Basename qw( basename dirname );
use IPC::Cmd qw( can_run run );
use Env qw( $CC $HOME );
use File::Temp;
use Try::Tiny;
use Role::Tiny;
use Path::Tiny;
use Template;

sub build {
    my $self = shift;

    my $template = Path::Tiny->tempfile;

    my $temp_sh = sprintf '%s/install.sh', $self->artifact->workdir;

    my $vars = {
        FAKEROOT => $self->fakeroot,
        WORKDIR  => $self->artifact->workdir,
        PREFIX   => $self->prefix,
        DISTFILE => $self->artifact->distfile
    };

    if ( defined $self->install ) {
        $template->spew( $self->install );
    }
    else {
        return 1;
    }

    if ( ! path($self->fakeroot)->exists ) {
        path($self->fakeroot)->mkpath;
    }

    my $tt = Template->new( { INCLUDE_PATH => dirname($template) } );

    $tt->process( basename( $template->absolute ), $vars, $temp_sh );

    my $command = [ can_run('bash'), '-e', $temp_sh ];

    $LOGGER->info( sprintf 'building: %s', $self->name );

    if ( defined $self->artifact->archive ) {
        chdir path($self->artifact->archive->extract_path)->realpath;
    }

    my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
        run( command => $command );

    foreach ( @{$full_buf} ) {
        $LOGGER->debug($_);
    }

    chdir $HOME;

    if ( !$success ) {
        $LOGGER->logcroak( sprintf "install script failed: %s\n",
            $error_message );

        return 2;
    }

    return 1;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

OS::Package::Role::Build - Provides build method for OS::Package object.

=head1 VERSION

version 0.2.7

=head1 METHODS

=head2 build

Provides method to build the application.

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
