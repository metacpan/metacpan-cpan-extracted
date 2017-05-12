#============================================================================
#
# Template::Plugin::SSI
#
# DESCRIPTION
#
#   Plugin to use SSI in Template Toolkit (wrapper for CGI::SSI)
#
# AUTHORS
#   Corey Wilson           <cwilson@sbgnet.com>
#   Mike Kralec            <mkralec@sbgnet.com>
#
# COPYRIGHT
#   Copyright (C) 2005 Sinclair Broadcast Group
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#============================================================================

package Template::Plugin::SSI;

use strict;
use vars qw( $VERSION );
use base qw( Template::Plugin );
use Template::Plugin;
use CGI::SSI;

$VERSION = sprintf("%d.%02d", q$Revision: 0.11 $ =~ /(\d+)\.(\d+)/);

sub new {
    my $class   = shift;
    my $context = shift;
    my $self = {};

    $self->{'ssi'} = CGI::SSI->new();

    bless $self, $class;

    return $self;
}

sub include {
    my $self = shift;
    my $action = shift;
    my $filename = shift;
    my $ssi = $self->ssi;

    return $ssi->include(virtual => $filename) if $action eq 'virtual';
    return $ssi->include(file => $filename) if $action eq 'file';

    $self->throw("first parameter of SSI::include must be 'virtual' or 'file'"); 
}

sub exec {
    my $self = shift;
    my $action = shift;
    my $filepath = shift;
    my $ssi = $self->ssi;

    return $ssi->exec(cgi => $filepath) if $action eq 'cgi';
    return $ssi->exec(cmd => $filepath) if $action eq 'cmd';

    $self->throw("first parameter of SSI::exec must be 'cgi' or 'cmd'"); 
}

sub config {
    my $self = shift;
    my $type = shift;
    my $arg = shift;
    my $ssi = $self->ssi;

    $self->throw("first parameter of SSI::config must be 'timefmt', 'errormsg', or 'sizefmt'")
        unless $type =~ /timefmt|errormsg|sizefmt/;

    $ssi->config($type, $arg);

    return;
}

sub echo {
    my $self = shift;
    my $var = shift;
    my $ssi = $self->ssi;

    return $ssi->echo($var);
}

sub set {
    my $self = shift;
    my $var = shift;
    my $val = shift;
    my $ssi = $self->ssi;

    $ssi->set($var => $val);

    return;
}

sub flastmod {
    my $self = shift;
    my $type = shift;
    my $filename = shift;
    my $ssi = $self->ssi;

    return $ssi->flastmod(virtual => $filename) if $type eq 'virtual';
    return $ssi->flastmod(file => $filename) if $type eq 'file';

    $self->throw("first parameter of SSI::flastmod must be 'virtual' or 'file'"); 
}

sub fsize {
    my $self = shift;
    my $type = shift;
    my $filename = shift;
    my $ssi = $self->ssi;

    return $ssi->fsize(virtual => $filename) if $type eq 'virtual';
    return $ssi->fsize(file => $filename) if $type eq 'file';

    $self->throw("first parameter of SSI::fsize must be 'virtual' or 'file'"); 
}

sub ssi {
    my $self = shift;

    return $self->{'ssi'};
}

sub throw {
    my $self = shift;
    die (Template::Exception->new('Template::Plugin::SSI', join(', ', @_)));
}

1;

__END__



=head1 NAME

Template::Plugin::SSI - Plugin to use SSI in Template Toolkit (wrapper for CGI::SSI)

=head1 SYNOPSIS

 [% USE SSI %]

 # virtual include of the file /foo/bar.inc.html
 [% SSI.include('virtual', '/foo/bar.inc.html') %]

 # file include of the file /foo/bar.inc.html
 [% SSI.include('file', '/var/www/html/foo/bar.inc.html') %]

 # execute a command
 [% SSI.exec('cmd', 'ls') %]

 # execute a cgi script
 [% SSI.exec('cgi', '/cgi-bin/foo.cgi') %]

 # set a config variable ('sizefmt', 'timefmt', or 'errmsg')
 [% SSI.config('timefmt', "%Y") %]

 # echo a set or environment variable
 # Environment Variable Examples:
 #  DOCUMENT_URI  - the URI of this document
 #  DOCUMENT_NAME - the name of the current document
 #  DATE_GMT      - the same as 'gmtime'
 #  DATE_LOCAL    - the same as 'localtime'
 #  FLASTMOD      - the last time this script was modified
 [% SSI.echo('DATE_LOCAL') %]

 # set a local variable ($name = 'Corey')
 [% SSI.set('name', 'Corey') %]

 # print when 'index.html' was last modified
 [% SSI.flastmod('file', 'index.html') %]

 # print the file size of 'index.html'
 [% SSI.fsize('file', 'index.html') %]

=head1 DESCRIPTION

A Template Toolkit Plugin that provides an easy way to include Apache's 
SSI within a template. (acts as a wrapper to CGI::SSI)

The plugin can be loaded via the familiar USE directive.

    [% USE SSI %]

This creates a plugin object with the name of 'SSI'.

The following SSI directives have been implemented:

include($type, $filepath) - Include a file from within your template.
                            ($type must be either 'virutal' or 'file')
    
    # Apache SSI example:
    #<!--#include virtual="/footer.html" -->
    #<!--#include file="/var/www/html/footer.html" -->
    #
    # Template::Plugin::SSI example:
    # when using $type == 'virutal', $filepath is relative
    # + to the document being served
    [% SSI.include('virtual', '/path/to/file') %]

    # when using $type == 'file', $filepath is relative 
    # + to the current directory
    [% SSI.include('file', '/var/www/path/to/file') %]


exec($type, $filepath) - Execute a file/cgi and print the output.
                         ($type must be either 'cmd' or 'cgi')
    
    # Apache SSI example:
    #<!--#exec cmd="ls" -->
    #
    # Template::Plugin::SSI example:
    # Output a list of files in the current directoy
    [% SSI.exec('cmd', 'ls') %]


config($var, $value) - Set a config variable
                       ($var must be 'timefmt', 'errormsg' or 'sizefmt')
    
    # Apache SSI example:
    #<!--#config timefmt="%A %B %d, %Y" -->
    #<!--#config errmsg="[Uh-oh]" -->
    #
    # Template::Plugin::SSI example:
    # Change all dates to only print the year 
    # + timefmt uses the strftime() syntax
    [% SSI.config('timefmt', "%Y") %]


echo($var) - Echo an environment or previously set variable
    
    # Apache SSI example:
    #<!--#echo var="DATE_LOCAL" -->
    #
    # Template::Plugin::SSI example:
    # Print the current date
    [% SSI.echo('DATE_LOCAL') %]


set($var, $val) - Set a local variable
    
    # Apache SSI example:
    #<!--#set var="name" value="Corey" -->
    #
    # Template::Plugin::SSI example:
    # Set the variable "name" with the value "Corey"
    [% SSI.set('name', 'Corey') %]


flastmod($type, $filepath) - Print the modification date of $filepath
                             ($type must be either 'virutal' or 'file')
    
    # Apache SSI example:
    #<!--#flastmod file="index.html" -->
    #
    # Template::Plugin::SSI example:
    # Output when index.html was last modified
    [% SSI.flastmod('file', 'index.html') %]


fsize($type, $filepath) - Print the filesize of $filepath
                          ($type must be either 'virutal' or 'file')
    
    # Apache SSI example:
    #<!--#fsize file="index.html" -->
    #
    # Template::Plugin::SSI example:
    # Output the size of index.html
    [% SSI.fsize('file', 'index.html') %]


=head1 AUTHORS

   Corey Wilson E<lt>cwilson_a.t_sbgnet_d.o.t_comE<gt>  
   Mike Kralec E<lt>mkralec_a.t_sbgnet_d.o.t_comE<gt> 
   James Tolley E<lt>james_a.t_bitperfect_d.o.t_comE<gt> created CGI::SSI.

=head1 COPYRIGHT

   Copyright (C) 2005 Sinclair Broadcast Group

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>, L<CGI::SSI|CGI::SSI>
