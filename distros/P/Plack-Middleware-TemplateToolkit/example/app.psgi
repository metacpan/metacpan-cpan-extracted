use strict;
use warnings;

use Plack::Builder;
use Plack::Middleware::TemplateToolkit;
use Plack::Request;
use File::Basename;
use Encode;
use Cwd;

my $is_devel = ($ENV{PLACK_ENV}||'') eq 'development';
my $root     = Cwd::realpath( dirname($0) );
my $title    = "Sample application";

my $app = sub {
    [   404,
        [ 'Content-Type' => 'text/html' ],
        ['<html><body>not found</body></html>']
    ];
};

builder {
    enable_if { $is_devel } 'Debug';
    enable_if { $is_devel } 'Debug::TemplateToolkit';

    enable 'Static',
	    root => $root,
	    path => qr{\.(png|gif|jpg|js|css)$};
 
    enable 'TemplateToolkit',
        INCLUDE_PATH => $root,
        INTERPOLATE  => 1,      
		extension    => 'html',
        vars         => { title => $title },
        request_vars => [qw(parameters base)],
        pass_through => 1;

    # this middleware shows how to set tt.vars
	enable sub {
		my $app = shift;
		sub {
			my $env = shift;
			my $text = Plack::Request->new($env)->param('text');
			$text = decode('utf8',$text);
			$text = substr($text,0,15)."..." if length($text) > 18;
			$env->{'tt.vars'} = {
				text  => $text,
				xpos  => 150 - 7*length($text)
			};
			$app->($env);
		}
	};

	# another use of TemplateToolkit
	enable 'TemplateToolkit',
	    INCLUDE_PATH   => $root,
		INTERPOLATE    => 1,
		extension      => 'svg',
		pass_through   => 1;

    $app;
};
