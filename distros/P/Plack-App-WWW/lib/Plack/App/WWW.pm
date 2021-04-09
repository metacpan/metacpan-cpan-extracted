package Plack::App::WWW;
use strict;
use warnings;
use parent qw/Plack::App::CGIBin/;
use Plack::App::File;
use Plack::App::WrapCGI;
use Plack::App::Directory;

our $VERSION = '0.02';

sub call {
    my $self = shift;
    my $env  = shift;

    # check if path info is a folder, if true add directory index
    return Plack::App::Directory->new(
        root => $self->root
    )->to_app->($env) if -d $self->root . $env->{PATH_INFO};

    my ($file, $path_info) = $self->locate_file($env);
    return $file if ref $file eq 'ARRAY';

    if ($path_info) {
        $env->{'plack.file.SCRIPT_NAME'} = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
        $env->{'plack.file.SCRIPT_NAME'} =~ s/\Q$path_info\E$//;
        $env->{'plack.file.PATH_INFO'}   = $path_info;
    } else {
        $env->{'plack.file.SCRIPT_NAME'} = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
        $env->{'plack.file.PATH_INFO'}   = '';
    }

    return $self->serve_path($env, $file);
}

sub serve_path {
    my($self, $env, $file) = @_;

    local @{$env}{qw(SCRIPT_NAME PATH_INFO)} = @{$env}{qw( plack.file.SCRIPT_NAME plack.file.PATH_INFO )};

    if ($self->_valid_file_perl($file)) {
        my $app = $self->{_compiled}->{$file} ||= Plack::App::WrapCGI->new(
            script => $file, execute => $self->would_exec($file)
        )->to_app;
        $app->($env);
    } else {
        Plack::App::File->new(file => $file)->to_app->($env);
    }
}

sub _valid_file_perl {
    my ($self, $file) = @_;

    return 1 if $file =~ /.(pl|cgi)$/i;
    return 1 if $self->shebang_for($file) =~ /^\#\!.*perl/;

    return;
}

1;

__END__

=encoding utf8

=head1 NAME

Plack::App::WWW - Serve cgi-bin and static files from root directory

=head1 SYNOPSIS

  use Plack::App::WWW;
  use Plack::Builder;

  my $app = Plack::App::WWW->new(root => "/path/to/www")->to_app;
  builder {
      mount "/" => $app;
  };

  # Or from the command line
  plackup -MPlack::App::WWW -e 'Plack::App::WWW->new(root => "/path/to/www")->to_app'

=head1 DESCRIPTION

Plack::App::WWW allows you to load CGI scripts and static files. This module use L<Plack::App::CGIBin> as a base,
L<Plack::App::WrapCGI> to load CGI scripts and L<Plack::App::File> to load static files and L<Plack::App::Directory> to directory index.

=head1 CONFIGURATION

=head3 root

Document root directory. Defaults to C<.> (current directory)

=head1 SEE ALSO

L<Plack>, L<Plack::App::CGIBin>, L<Plack::App::WrapCGI>, L<Plack::App::File>, L<Plack::App::Directory>.

=head1 AUTHOR

Lucas Tiago de Moraes C<lucastiagodemoraes@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
