package Template::Plugin::YUI2::Loader;

use warnings;
use strict;

use base qw( Template::Plugin );

use Template::Exception;

=head1 NAME

Template::Plugin::YUI2::Loader - dependency management with YUI's loader util 

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

use 5.006;

=head1 SYNOPSIS

This module aims to ease the use of YUI's loader utility by providing means to collect the names of the YUI2 components to be loaded and the code to be run once those components have been successfully loaded anywhere in a nested template structure.

  # in a template A.tt :
  
  ...
  [% USE loader = YUI2.Loader;
     CALL loader.components( 'calendar', 'dragdrop' ).on_success( some_js_code ); 
  %]
  ...

  # in a template wrapper.tt :
  
  <head>
  ...
  </head>
  <body>
  ...

  [% # presumably quite late in the body insert the loader
     USE loader = YUI2.Loader; 
  %]
  
  <script src="http://yui.yahooapis.com/2.8.0r4/build/yuiloader/yuiloader-min.js"></script>
  <script type="text/javascript">
	var loader = 
	new YAHOO.util.YUILoader({
	    	require: [% loader.components %],
    		onSuccess: function() {
			[% loader.on_success %]
    		}
	});
	loader.insert();
  <script>
  </body>

  # in a template B.tt :

  [% WRAPPER wrapper.tt %]
     	...
	[% INCLUDE A.tt;
	   USE loader = YUI2.Loader;
     	   CALL loader.components( 'cookie' ).on_success( some_js_code );
	%]
	...
  [% END %]

=head1 EXPORT

Exported stash variable: YUI2Loader_

=head1 METHODS

=cut

sub new {      
    # called as Template::Plugin::YUI2::Loader->new($context)
    my ($class, $context, %params) = @_;

    my $self =
    bless {
	_CONTEXT => $context
    }, $class;

    $self;
}

sub error {
    my $proto = shift;
    die( ref( $_[0] ) ? @_ : do { $proto->SUPER::error(@_); Template::Exception->new( 'YUI2.Loader', $proto->SUPER::error ) } );
}

=head2 components

This plugin method is for requesting YUI components. 

It accepts (multiple) YUI module names. Please refer to Yahoo's online documentation of the YUI loader utility for the respective names of the components in this context. A repeated request of a component is silently ignored. In order to be able to chain calls to the loader plugin object, the plugin object itself is returned on write access.

With no parameters passed it will return the component list as a javascript data structure suitable to be used as a value for the loader's configuration option 'requires' (see SYNOPSIS).

=cut

sub components {
    my $self = shift;

    if ( @_ ) {
	@{$self->_data->{components}}{ @_ } = ( map { 1 } @_ );
    	return $self;
    } else {
        '[ '.( join ", ", map { "'$_'" } sort keys %{$self->_data->{components}} ).' ]';
    }
}

=head2 on_success

This plugin method is for scheduling code to run once the YUI components have been fully loaded. It accepts javascript code as a parameter. In order to be able to chain calls to the loader plugin object, the plugin object itself is returned on write access.

With no parameters passed it will return the javascript code snippets passed to the method on previous calls as a javascript code suitable to be used inside the function reference passed to the loader's configuration option 'onSuccess' (see SYNOPSIS). When stringifying the list of code snippets each code item is returned in the order of write calls to this method, and is wrapped in a call of an anonymous javascript function in order to prevent the conflicting of code.

=cut

sub on_success {
    my( $self ) = shift;

    if (@_) {
    	push @{$self->_data->{on_success}}, $_[0];
	return $self;
    } else {
    	join "\n",
	map { "(function() { $_ })();" } @{$self->_data->{on_success}}
    }
}

sub _data {
    my $self = shift;
    
    return $self->{data} if defined $self->{data};

    my $stash = $self->{_CONTEXT}->stash();

    $self->{data} = $stash->get( 'YUI2Loader_' ) || do {
    	my $data = { 
		components => {}, 
		on_success => [] 
	};
    	my $s = $stash;
	# We make the data available in all stashs up to the top scope (parent stash)!
	# This way one can call the plugin from any localised inner template 
	# for the first time within a processing run, and the data is still shared
	# with any further instantiations of this plugin in a possible template call chain.
    	while ( $s ) {
		$s->set( 'YUI2Loader_', $data );
		$s = $s->{_PARENT};
		last if !defined $s->{_PARENT};
	}
	$data;
    };

}

=head1 AUTHOR

Alexander Kühne, C<< <alexk at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-plugin-yui2-loader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-YUI2-Loader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::YUI2::Loader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-YUI2-Loader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Plugin-YUI2-Loader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Plugin-YUI2-Loader>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Plugin-YUI2-Loader/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Alexander Kühne, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Template::Plugin::YUI2::Loader
