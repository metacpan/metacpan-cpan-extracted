#!/usr/bin/perl
#!C:\perl\bin\perl.exe
#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#print "Content-type: text/html;charset=utf-8\n\n";
	use Data::Dumper;
	use utf8;
	
	#use Getopt::Long;
	#use Pod::Usage;
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	# push the local Nile module folder on Perl @INC, remove if Nile module installed
	use File::Spec;
	use File::Basename;
	BEGIN {
		push @INC, File::Spec->catfile(dirname(dirname(File::Spec->rel2abs(__FILE__))), "lib");
	}
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	use Nile;

	my $app = Nile->new();

	$app->init({
		# base application path, auto detected if not set
		path		=>	dirname(File::Spec->rel2abs(__FILE__)),
		
		# load config files, default extension is xml
		config		=> [ qw(config) ],

		# force run mode if not auto detected by default. modes: "psgi", "fcgi" (direct), "cgi" (direct)
		#mode	=>	"fcgi", # psgi, cgi, fcgi
	});
    
	# inline actions, return content. url: /forum/home
	$app->action("get", "/forum/home", sub {
		my ($self) = @_;
		# $self is set to the application context object same as $self->app in plugins
		my $content = "Host: " . ($self->request->virtual_host || "") ."<br>\n";
		$content .= "Request method: " . ($self->request->request_method || "") . "<br>\n";
		$content .= "App Mode: " . $self->mode . "<br>\n";
		$content .= "Time: ". time . "<br>\n";
		$content .= "Hello world from inline action /forum/home" ."<br>\n";
		$content .= "أحمد الششتاوى" ."<br>\n";
		$self->response->encoded(0); # encode content
		return $content;
	});

	# inline actions, capture print statements, ignore the return value. url: /accounts/login
	$app->capture("get", "/accounts/login", sub {
		my ($self) = @_;
		# $self is set to the application context object same as $self->app in plugins
		say "Host: " . ($self->request->virtual_host || "") . "<br>\n";
		say "Request method: " . ($self->request->request_method || "") . "<br>\n";
		say "App Mode: " . $self->mode . "<br>\n";
		say "Time: ". time . "<br>\n";
		say "Hello world from inline action with capture /accounts/login", "<br>\n";
		say $self->encode("أحمد الششتاوى ") ."<br>\n";
		$self->response->encoded(1); # content already encoded
	});

    # inline actions, capture print statements and the return value. url: /blog/new
    $app->command("get", "/blog/new", sub {
        my ($self) = @_;
        # $self is set to the application context object same as $self->app in plugins
        say "Host: " . ($self->request->virtual_host || "") . "<br>\n";
        say "Request method: " . ($self->request->request_method || "") . "<br>\n";
        say "App Mode: " . $self->mode . "<br>\n";
        say "Time: ". time . "<br>\n";
        say "Hello world from inline action with capture /blog/new and return value.", "<br>\n";
        say $self->encode("أحمد الششتاوى ") ."<br>\n";
        $self->response->encoded(1); # content already encoded
        return " This value is returned from the command.";
    });

	# run the application and return the PSGI response or print to the output
	# the run process will also run plugins with matched routes files loaded
	$app->run();
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
