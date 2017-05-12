#
# This file is part of Plack-App-TemplatedDirectory
#
# This software is copyright (c) 2014 by Kaare Rasmussen.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Plack::App::TemplatedDirectory;
$Plack::App::TemplatedDirectory::VERSION = '0.001';
use parent qw/Plack::App::File/;
use strict;
use warnings;
use Plack::Util;
use HTTP::Date;
use Plack::MIME;
use DirHandle;
use URI::Escape;
use Plack::Request;
use Text::Xslate;

use Plack::Util::Accessor qw/template template_path/;
 
sub should_handle {
    my($self, $file) = @_;
    return -d $file || -f $file;
}
 
sub return_dir_redirect {
    my ($self, $env) = @_;
    my $uri = Plack::Request->new($env)->uri;
    return [ 301,
        [
            'Location' => $uri . '/',
            'Content-Type' => 'text/plain',
            'Content-Length' => 8,
        ],
        [ 'Redirect' ],
    ];
}
 
sub serve_path {
    my($self, $env, $dir, $fullpath) = @_;
 
    if (-f $dir) {
        return $self->SUPER::serve_path($env, $dir, $fullpath);
    }
 
    my $dir_url = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
 
    if ($dir_url !~ m{/$}) {
        return $self->return_dir_redirect($env);
    }
 
    my @files = ({
		url => '../',
		name => 'Parent Directory',
		ext => '', 
		size => '',
		mime_type => 'directory',
		modified_time => '',
	});
 
    my $dh = DirHandle->new($dir);
    my @children;
    while (defined(my $ent = $dh->read)) {
        next if $ent eq '.' or $ent eq '..';
        push @children, $ent;
    }
 
    for my $basename (sort { $a cmp $b } @children) {
        my $file = "$dir/$basename";
        my $url = $dir_url . $basename;
		my ($ext) = $basename =~m/\.(\w*)$/;
 
        my $is_dir = -d $file;
        my @stat = stat _;
 
        $url = join '/', map {uri_escape($_)} split m{/}, $url;
 
        if ($is_dir) {
            $basename .= "/";
            $url      .= "/";
        }
 
        my $mime_type = $is_dir ? 'directory' : ( Plack::MIME->mime_type($file) || 'text/plain' );
        push @files, {
			url => $url,
			name => $basename,
			ext => lc($ext // ''),
			size => $stat[7],
			mime_type => $mime_type,
			modified_time => HTTP::Date::time2str($stat[9])
		};
    }
 
	my $template_path = $self->template_path || 'templates';
	my $app_root = app_root();

	my $tx = Text::Xslate->new(
		path => [ map {$_ . '/' . $template_path} ('.', $app_root) ],
	);

	my $template = $self->template || 'apache.tx';
	my $page = $tx->render($template, {
		path => $env->{PATH_INFO},
		files =>  \@files,
	});
 
    return [ 200, ['Content-Type' => 'text/html; charset=utf-8'], [ $page ] ];
}

sub app_root {
	my $path = __FILE__;
	$path =~ s|lib/+Plack/App/TemplatedDirectory.pm||;
	return $path;
}
 
1;
 
__END__
 
=head1 NAME
 
Plack::App::TemplatedDirectory - Serve static files from document root with directory index
 
=head1 SYNOPSIS
 
  # app.psgi
  use Plack::App::TemplatedDirectory;
  my $app = Plack::App::TemplatedDirectory->new({ root => "/path/to/htdocs" })->to_app;
 
=head1 DESCRIPTION
 
This is a static file server PSGI application with directory index served through templates.
 
=head1 CONFIGURATION
 
=over 4
 
=item root
 
Document root directory. Defaults to the current directory.
 
=item template
 
The template. Currently two templates are included, apache.tx and jqueryFileTree.tx.

Defaults to 'apache.tx'.
 
=back
 
=head1 AUTHOR
 
Kaare Rasmussen
 
=head1 SEE ALSO
 
L<Plack::App::Directory>
 
=cut

1;
