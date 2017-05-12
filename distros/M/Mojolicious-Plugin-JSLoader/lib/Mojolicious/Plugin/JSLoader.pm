package Mojolicious::Plugin::JSLoader;

# ABSTRACT: move js loading to the end of the document

use strict;
use warnings;

use parent 'Mojolicious::Plugin';

use HTML::ParseBrowser;
use Mojo::ByteStream;
use version 0.77;

our $VERSION = 0.06;

sub register {
    my ($self, $app, $config) = @_;

    my $base = $config->{base} || '';

    if ( $base and substr( $base, -1 ) ne '/' ) {
        $base .= '/';
    }

    $app->helper( js_load => sub {
        my $c = shift;

        return '' unless _match_browser($c, @_);

        if ( $_[1]->{check} ) {
            my $asset = $c->app->static->file(
                $_[1]->{no_base} ? $_[0] : "$base$_[0]"
            );

            return '' if !$asset;
        }

        if ( $_[1] && $_[1]->{inplace} ) {
            my ($file,$config) = @_;
            my $local_base = $config->{no_base} ? '' : $base;

            $local_base = $c->url_for( $local_base ) if $local_base;

            my $js = $config->{no_file} ? 
                qq~<script type="text/javascript">$file</script>~ :
                qq~<script type="text/javascript" src="$local_base$file"></script>~;
            return Mojo::ByteStream->new( $js );
        }

        push @{ $c->stash->{__JSLOADERFILES__} }, [ @_ ];
    } );

    $app->hook( after_render => sub {
        my ($c, $content, $format) = @_;

        return if $format ne 'html';
        return if !$c->stash->{__JSLOADERFILES__};

        my $load_js = join "\n", 
                      map{
                          my ($file,$config) = @{ $_ };
                          my $local_base = $config->{no_base} ? '' : $base;

                          $local_base = $c->url_for( $local_base ) if $local_base;

                          if ( $config->{no_file} and $config->{on_ready} ) {
                              $file = sprintf '$(document).ready( function(){%s});', $file;
                          }

                          $config->{no_file} ? 
                              qq~<script type="text/javascript">$file</script>~ :
                              qq~<script type="text/javascript" src="$local_base$file"></script>~;
                      }
                      @{ $c->stash->{__JSLOADERFILES__} || [] };

        return if !$load_js;

        ${$content} =~ s!(</body(?:\s|>)|\z)!$load_js$1!;
    });
}

sub _match_browser {
    my ($c,$file,$config) = @_;

    return 1 if !$config;
    return 1 if ref $config ne 'HASH';
    return 1 if !$config->{browser};
    return 1 if ref $config->{browser} ne 'HASH';

    my $ua_string = $c->req->headers->user_agent;
    my $ua        = HTML::ParseBrowser->new( $ua_string );

    return if !$ua;

    my $name    = $ua->name; 
    my $browser = $config->{browser};

    if ( !exists $browser->{$name} && !exists $browser->{default} ) {
        return;
    }
    elsif ( !exists $browser->{$name} && exists $browser->{default} ) {
        return 1;
    }

    my ($op,$version) = $browser->{$name} =~ m{\A\s*([lg]t|!)?\s*([0-9\.]+)};

    return if !defined $version;

    if ( !$op || ( $op ne 'gt' and $op ne 'lt' and $op ne '!' ) ) {
        return version->parse( $ua->v ) == version->parse( $version );
    }
    elsif ( $op eq 'gt' ) {
        return version->parse( $version ) <= version->parse( $ua->v );
    }
    elsif ( $op eq 'lt' ) {
        return version->parse( $version ) >= version->parse( $ua->v );
    }
    elsif ( $op eq '!' ) {
        return version->parse( $version ) != version->parse( $ua->v );
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::JSLoader - move js loading to the end of the document

=head1 VERSION

version 0.06

=head1 SYNOPSIS

In your C<startup>:

    sub startup {
        my $self = shift;
  
        # do some Mojolicious stuff
        $self->plugin( 'JSLoader' );

        # more Mojolicious stuff
    }

In your template:

    <% js_load('js_file.js') %>

=head1 HELPERS

This plugin adds a helper method to your web application:

=head2 js_load

This method requires at least one parameter: The path to the JavaScript file to load.
An optional second parameter is the configuration. You can switch off the I<base> for
this JavaScript file this way:

  # <script type="text/javascript" src="$base/js_file.js"></script>
  <% js_load('js_file.js') %>
  
  # <script type="text/javascript" src="http://domain/js_file.js"></script>
  <% js_load('http://domain/js_file.js', {no_base => 1}); %>

=head3 config for js_load

There are several config options for C<js_load>:

=over 4

=item * no_base

Do not use the base url configured on startup when I<no_base> is set to a true value.

  # <script type="text/javascript" src="http://domain/js_file.js"></script>
  <% js_load('http://domain/js_file.js', {no_base => 1}); %>

=item * no_file

If set to a true value, you have to pass pure JavaScript

  # <script type="text/javascript">alert('test');</script>
  <% js_load("alert('test')", {no_file => 1}); %>

=item * on_ready

If set to a true value - in combination with a true value for I<no_file> - the javascript
code is wrapped in C<$(document).ready( function(){...});>. This is quite handy when you
have jquery installed and you want to run some javascript when the document is loaded.

  # <script type="text/javascript">alert('test');</script>
  <% js_load("alert('test')", {no_file => 1}); %>

=item * inplace

Do not load the javascript at the end of the page, but where C<js_load> is called.

  # <script type="text/javascript" src="http://domain/js_file.js"></script>
  <%= js_load('http://domain/js_file.js', {no_base => 1, inplace => 1}); %>

=item * browser

Load the javascript when a specific browser is used.

  # Load the javascript when Internet Explorer 8 is used
  # <script type="text/javascript" src="http://domain/js_file.js"></script>
  <%= js_load('http://domain/js_file.js', {inplace => 1, browser => { "Internet Explorer" => 8 }}); %>

  # Load the javascript when Internet Explorer lower than 8 or Opera 6 is used
  # <script type="text/javascript" src="http://domain/js_file.js"></script>
  <%= js_load('http://domain/js_file.js', {inplace => 1, browser => {"Internet Explorer" => 'lt 8', Opera => 6} }); %>

  # Load the javascript when Internet Explorer is not version 8
  <%= js_load('http://domain/js_file.js', {inplace => 1, browser => {"Internet Explorer" => '!8' } } ); %>

There's the "special" browser default. So you are able to load javascript for e.g. everything but IE6

  # Load the javascript when Internet Explorer is not version 6
  <%= js_load('http://domain/js_file.js', {inplace => 1, browser => {"Internet Explorer" => '!6', default => 1 } } ); %>

=item * check

If you want to avoid 404 errors that might occur when the filname is built dynamically, you can pass C<check> in the
config options:

 # <public>/test.js exists, <public>/tester.js doesn't
 % js_load( 'tester.js' );
 % js_load( 'test.js' );
 
 # -> you'll get a 404 error for "tester.js"

 # <public>/test.js exists, <public>/tester.js doesn't
 % js_load( 'tester.js', { check => 1 } );
 % js_load( 'test.js', { check => 1 } );
 
 # -> no 404 error, the javascript tag for tester.js isn't added to the HTML

When you pass C<check>, it is checked whether Mojolicious can create a L<static file|Mojolicious::Static/file> or not.
So the "file" doesn't have to be a file on disk, but a "file" in the C<__DATA__> section is ok, too.

Your class

  __DATA__
  @@ checktest.js
  $(document).ready( function(){ alert('check') } );

Your template:

  % js_load( 'checktest.js' ); # works
  % js_load( 'checktest.js', { check => 1 } ); # works
  % js_load( 'checktest2.js', { check => 1 } ); # tag is not added as checktest2.js doesn't exist

=back

=head1 HOOKS

When you use this module, a hook for I<after_render> is installed. That hook inserts
the C<< <script> >> tag at the end of the document or right before the closing
C<< <body> >> tag.

To avoid that late loading, you can use I<inplace> in the config:

  <%= js_load( 'test.js', {inplace => 1} ) %>

=head1 METHODS

=head2 register

Called when registering the plugin. On creation, the plugin accepts a hashref to configure the plugin.

    # load plugin, alerts are dismissable by default
    $self->plugin( 'JSLoader' );

=head3 Configuration

    $self->plugin( 'JSLoader' => {
        base => 'http://domain/js',  # base for all <script> tags
    });

=head1 NOTES

This plugin uses the I<stash> key C<__JSLOADERFILES__>, so you should avoid using
this stash key for your own purposes.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
