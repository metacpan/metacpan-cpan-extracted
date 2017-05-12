package Plack::App::PHPCGIFile;

use strict;
use warnings;
use parent qw(Plack::App::File);
use Plack::Util::Accessor qw(php_cgi);
use Plack::App::PHPCGI;
use File::Which;
use File::Spec;
use Carp;

our $VERSION = '0.05';

sub prepare_app {
    my $self = shift;
    my $php_cgi = $self->php_cgi;
    $php_cgi ||= which('php-cgi');
    croak "cannot find 'php-cgi' command" unless -x $php_cgi;
    $self->php_cgi($php_cgi);
}

sub allow_path_info { 1 }

sub serve_path {
    my($self, $env, $file) = @_;
    if ( $file =~ m!\.php$! ) {
        my $script = File::Spec->rel2abs($file);
        my $app = $self->{_wrap}->{$script} ||= Plack::App::PHPCGI::wrap_php($self->php_cgi, $script);
        local @{$env}{qw(SCRIPT_NAME PATH_INFO)} = @{$env}{qw( plack.file.SCRIPT_NAME plack.file.PATH_INFO )};
        return $app->($env);
    }
    $self->SUPER::serve_path($env,$file);
}

1;

__END__

=head1 NAME

Plack::App::PHPCGIFile - serve PHP and static files from a directory

=head1 SYNOPSIS

  use Plack::App::PHPCGIFile;

  my $app = Plack::App::PHPCGIFile->new(
      root => '/path/to/htdocs'
  )->to_psgi;


=head1 DESCRIPTION

Plack::App::PHPCGIFile is subclass of Plack::App::File.
This module serves static file and PHP script from a directory. 
PHP script executed as CGI by Plack::App::PHPCGI.

=head1 METHODS

=over 4

=item new

  my $app = Plack::App::PHPCGIFile->new(%args);

Creates a new PSGI application using the given script. I<%args> has two
parameters:

=over 8

=item root

Document root directory. Defaults to C<.> (current directory)

=item php_cgi

An optional parameter. path for php-cgi command

=back

=back

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

L<Plack::App::PHPCGI>, L<Plack::App::File>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

