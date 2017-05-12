package Template::Plugin::File::StaticURL;

=head1 NAME

Template::Plugin::File::StaticURL - Appends mtime and file size to the URL of static files to ensure freshness.

=head1 SYNOPSIS

   [% USE Static.Stat file_root='/var/www' %]
   
   <script src="[% Static.Stat.url('/js/script.js') %]">
   <!-- Generates: /js/script.js/$mtime/$size -->

   <style>@import url([% Static.Stat.url('/css/styles.css') %]);</style>
   <!-- Generates: /css/styles.css/$mtime/$size -->

NOTE: You might need to configure your web server to accept path info to use this module with default settings. Please read the "SERVER CONFIGURATION" section for more information.

=head1 DESCRIPTION

This plugin stats static files and generates a URL with it's modification time and file size appended. The hack ensures that changed static files (such as javascript and css) are reloaded by the client if they are changed on the server, regardless of caching in the HTTP chain.

It is particularly useful for deploying deploy new releases of a web application into production, and need to make sure that updated javascript and css files are served fresh to the client.

=head1 PARAMETERS


 [% USE Static.Stat 
        file_root        = '/var/www/'   # The root of the files. (Required)

        url_root         = 'http://foo/' # Url prefix. (Optional)

        graceful         = 0             # Don't fatal if stat() fails.

        postfix_filename = 0             # Prepends filename to the end of the URL. 
                                         # Useful for debugging with Firebug. 

        prefix           = '/'           # Prefix that follows base url.

 %]



=head1 SERVER CONFIGURATION

Since we're appending meta information to the end of the URL, it is important that the webserver "ignores" the appended path information. There are a couple of ways of ensuring this.

=head2 Using the '/' prefix, and enabling Path Info.

To use the default '/' prefix, you would need to set the server to accept path info. In Apache 2, add the following configuration to the relevant section:

  AcceptPathInfo on

=head2 Using the '?' prefix placing the meta in the query string.

Alternatively, you can use the '?' prefix to set the meta information in the query string to the static object. This is not optimal because some HTTP proxy servers might refuse to cache any elements that have '?' in the URL.

To migitate this issue, you should configure caching headers to be set in the directories where the static files are served. In Apache (using mod_expires), you could set the following parameters:

  ExpiresActive   On
  ExpiresDefault  "access plus 90 days"

NOTE: Be careful just to set this in the location where your static content is served. And note that any URL will now be cached for a long time.

=head1 METHODS

=head2 url

Takes the path to the static file as the only argument, and returns by default a relative URL of the form:

   /js/script.js/1252815667/15564

Set the 'url_prefix' option if you need a prefix.

=head1 BUGS

Bugs probably exists. Email me if you find any.

=head1 AUTHOR

Stig Palmquist <stigtsp@gmail.com>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

use strict;
use warnings;

use Carp;
use File::stat;
use File::Spec::Functions;

use base 'Template::Plugin';
use Template::Exception;

our $VERSION = 0.02;

sub new {
    my ($class, $context, $params) = @_;
    

    my $self = bless { 
	   _CONTEXT   => $context,
	   file_root  => $params->{file_root},
	   base_url   => $params->{base_url}   || '',
           prefix     => $params->{prefix}     || '/',
	   graceful   => $params->{graceful}   || 0,
	   postfix_filename => $params->{postfix_filename},

	   separator  => '/',
	  }, $class;

    unless ($params->{file_root} && -d $params->{file_root}) {
	$self->{_CONTEXT}->throw("file_root $params->{file_root} does not exist or is not defined");
	return;
    }
    return $self;
}

sub url {
    my ($self, $file) = @_;

    my $path = catfile($self->{file_root}, $file);
    my $stat = stat($path);

    if (!$stat && !$self->{graceful}) {
	$self->{_CONTEXT}->throw("stat failed on $path");
    }

    my $url = '';

    if ($stat) {
	$url .= $self->{prefix} . join($self->{separator}, ($stat->mtime, $stat->size));
	$url .= $file if $self->{postfix_filename};

	# Clear out double slashes from the URL, as they can mess up
	# relative URLs by triggering the '//' shorthand for current
	# schema when at the start. And it's not nice.
    }

    return  $self->{base_url} . $file . $url;
}

42;
