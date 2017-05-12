#
# This file is part of Template-Plugin-TwoStage
#
# This software is copyright (c) 2014 by Alexander Kühne.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Template::Plugin::TwoStage;
# ABSTRACT: two stage processing of template blocks with first stage caching
$Template::Plugin::TwoStage::VERSION = '0.08';

use warnings;
use strict;

use base qw( Template::Plugin Class::Data::Inheritable );
use Template 2.01 ();
use Template::Plugin ();
use Template::Parser ();
use Template::Exception ();
use Template::Provider ();

use File::Path qw( rmtree mkpath );
use File::Spec ();
use Digest::SHA1 qw( sha1_hex );
use Encode ();

# declare constants one by one - as opposed to a multiple constants declaration -
# in order to be compatible with constant.pm version 1.02 shipped with perl 5.6
use constant DEBUG => $ENV{TWOSTAGE_DEBUG} || 0;
use constant UNSAFE => '^A-Za-z0-9_';
use constant CACHE_DIR_NAME => 'TT_P_TwoStage';

BEGIN  { 
	eval {
		require URI::Escape::XS;
		URI::Escape::XS->import( qw( uri_escape ) );
	};

	if ($@) {
		print STDERR "URI::Escape::XS not available ($@)...\n" if DEBUG;
		require URI::Escape;
		URI::Escape->import( qw( uri_escape ) );
	} else {
		print STDERR "URI::Escape::XS available ...\n" if DEBUG;
	}
};

my $TAG_STYLE_unquotemeta = {
	map { 
		my @tags = @{$Template::Parser::TAG_STYLE->{$_}}; 
		( $_, [ map { $_ =~ s/\\([^A-Za-z_0-9]{1})/$1/g; $_ } @tags ] )
	} keys %$Template::Parser::TAG_STYLE
};

# declare options here
my @options = qw( caching_dir dev_mode namespace ttl dir_keys runtime_tag_style tt_cache_size );



__PACKAGE__->mk_classdata( caching_dir => File::Spec->tmpdir );


__PACKAGE__->mk_classdata( dev_mode => 0 );


__PACKAGE__->mk_classdata( ttl => 0 ); 


__PACKAGE__->mk_classdata( dir_keys => undef ); 


__PACKAGE__->mk_classdata( namespace => undef );


__PACKAGE__->mk_classdata( runtime_tag_style => 'star' );

__PACKAGE__->mk_classdata( precompile_tag_style => undef ); # is always the configured tag style of the Template object


__PACKAGE__->mk_classdata( tt_cache_size => undef );


sub extend_keys {
    my $self = shift;
    my $context = $self->{CONTEXT};
    my $stash = $context->stash();

    # hook method for adding standard keys - return the keys => value -hash by reference! 
    {};
}



# TT2 PLUGIN HOOK METHODS

sub load {
    my ($class, $context) = @_;
   
    my $config = $class->compile_options( $context );

    my $caching_dir = $config->{ caching_dir };
    eval { mkpath( $caching_dir, 0, 0700 ) };
    $class->error( "Couldn't create directory: $caching_dir. Error message: $@" ) if $@;
   
    # We choose to have a specific provider for the plugin, because we do not want 
    # to make any assumptions about which provider class is used by the user.
    
    # make include path

    my ($volume, $directories, $file) = File::Spec->splitpath( $caching_dir, 1 );
    # Strip off the class name from the caching directory 
    # (which itself contains the class name as the last directory).
    # The class name will be part of the template's relative path when calling process().
     
    my $inc_path = 
    File::Spec->catpath(
    	$volume,
	File::Spec->catdir( 
		do { my @dirs = File::Spec->splitdir( $directories ); pop @dirs; @dirs }
	),
	$file
    );

    my $p = Template::Provider->new(
  	{ 	%{$context->{ CONFIG }},
		INCLUDE_PATH => $inc_path,
		CACHE_SIZE => $config->{ tt_cache_size },
		COMPILE_EXT => '.ttc',
		COMPILE_DIR => _concat_path( $inc_path, 'tt_compiled' ) 
	}
    );
    push @{$context->{ LOAD_TEMPLATES }}, $p;

    $context->{ PREFIX_MAP }->{ twostage } = [ $p ];
    
    print STDERR "$class:\nwe use caching dir: $caching_dir\n" if DEBUG;

    $class;
}


sub new {     
    my ($class, $context, @params) = @_;
    
    print STDERR "new $class\n" if DEBUG;
    $class->create($context, @params); 
}    	

sub error {
    my $proto = shift;
    die( ref( $_[0] ) ? @_ : do { $proto->SUPER::error(@_); Template::Exception->new( 'TwoStage', $proto->SUPER::error ) } );
}

sub create {
    my ($class, $context, $params) = @_;

    print STDERR "create \n" if DEBUG;

    # let parameters overwrite a selected set of the compiled options 
    bless {
 	CONTEXT => $context,
	CONFIG => {
		%{$class->compiled_options( $context )},
		precompile_tag_style => ( $class->precompile_tag_style || $context->{CONFIG}->{TAG_STYLE} || 'default' ),
		( 	defined $params ?
			# specify invalid options for plugin construction
			do { delete @$params{ qw( caching_dir tt_cache_size ) }; %$params } : 
			() 
		)
	}
    }, $class;
}

sub compile_options {
    my ($class, $context) = @_;

    my %config;
    @config{ @options } = map { $class->$_ } @options;

    $config{ extend_keys } = \&Template::Plugin::TwoStage::extend_keys;

    if ( $class eq __PACKAGE__ && ( my $c = $context->{ CONFIG }->{ TwoStage } ) ) {

    	my @ack_opts = grep { scalar grep /^$_$/, @options } keys %$c;
	# slurp in all options from TT2 main configuration hash
	@config{ @ack_opts } = @$c{ @ack_opts };
	my $xk = $c->{ extend_keys };
	if ( defined $xk && ref $xk eq 'CODE' ) {
		# xk() as configuration option in TT2 main configuration hash
		$config{ extend_keys } = $xk;
	}

    } elsif ( $class ne __PACKAGE__ ) {

    	no strict 'refs';
	my $meth_name = "${class}::extend_keys";
    	if ( defined &{$meth_name} ) {
		# xk() as redefined callback method in derived class
		$config{ extend_keys } = \&{$meth_name};
	}

    }

    $config{ caching_dir } = 
    &_concat_path( $config{ caching_dir }, [ CACHE_DIR_NAME, do { uri_escape( $class, UNSAFE ) } ] );

    print STDERR join( ', ', ( %config ) )."\n" if DEBUG;

    $context->{ CONFIG }->{ _TwoStage }->{ compiled_options }->{ $class } = \%config;   
}

sub compiled_options {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $context = ref $proto ? $proto->{ CONTEXT } : shift;
    my $name = shift;

    my $c = $context->{ CONFIG }->{ _TwoStage }->{ compiled_options }->{ $class };
    defined $name ? $c->{ $name } : $c;
}

sub dump_options {
    my $self = shift;
	
    my $options_dump = '';
    map { 
	if ( $_ ne 'extend_keys' ) { 
		$options_dump.= "$_: ".( defined $self->{CONFIG}->{$_} ? $self->{CONFIG}->{$_} : '' )."\n" 
	} 
    } sort keys %{$self->{CONFIG}};

    $options_dump;
}


sub process {
    my( $self, $params, $localize ) = @_;
    $localize ||= 0;
    my $context = $self->{CONTEXT};
    my $stash = $context->stash();

    exists( $params->{template} ) || $self->error( "Pass template => \$name !" );
    $self->{prec_template} = {}; # store for properties of current template processed
    $self->{params} = $params; # parameters handed to process()
    $self->{params}->{keys} = $self->_complement_keys( $params->{keys} || {} );

    # make the config options local to this call
    local $self->{CONFIG} = 
    { 
    	%{$self->{CONFIG}},
	do { 
	    	my %p = %$params;
		# specify invalid options as parameters to process()/include()
		delete @p{ qw( caching_dir tt_cache_size ) };
	    	%p 
	} 
    }; 

    if ( $stash->get( 'TwoStage_precompile_mode') ) {   

    	# don't do runtime phase processing if the template is called in precompilation mode
    	print STDERR "$params->{template}: precompile_mode ack..." if DEBUG;
	return $context->process( $params->{template}, {}, 1 );	
    }


    print STDERR 
    "try using cached version of component ($params->{template}) ".$self->_signature."\n"
    ."dev_mode: ".$self->{CONFIG}->{dev_mode}."\n"
    ."INCLUDE_PATH: ".join( ' : ', @{$context->{CONFIG}->{INCLUDE_PATH}} )."\n" 
    ."keys: \n".( join "\n", map { "$_ -> $self->{params}->{keys}->{$_}" } keys %{$self->{params}->{keys}} )."\n\n" 
    	if DEBUG;

    # stat() the cached precompiled version to play safely with negative 
    # caching of TT2 introduced in recent versions!
    # Else requesting for a not yet existing precompiled version 
    # would lead to an immediate decline of a future request for the same precompiled template without 
    # further stat() checks by the provider - even if it has been created on disk in the meantime.

    my @stat = stat( $self->_file_path );

    print STDERR "template.modtime: ".$stash->get( 'template.modtime' )." - ttl: $self->{CONFIG}->{ttl} ".time()." <= ".( $stat[9] + $self->{CONFIG}->{ttl})."\n" 
	if DEBUG && scalar( @stat ); 

    if ( scalar( @stat )
     	 && 
	 $stash->get( 'template.modtime' ) <= $stat[9] # cached version outdated?
    	 &&
    	 !$self->{CONFIG}->{dev_mode} # forces in cases of nested TwoStage processed templates a refresh also for modified inner templates
    	 && 
	 ( !$self->{CONFIG}->{ttl} || time() <= ($stat[9] + $self->{CONFIG}->{ttl}) ) 

    ) {

	print STDERR "file ".$self->_file_path." successfully stat()ed\n" if DEBUG;
	
	my $output;
	eval {
		$output = 
		$context->process(
			'twostage:' # prefix for provider selection
				.uri_escape( ref($self), UNSAFE ).'/'
				.( do { my $dirs = join( '/', @{$self->_dynamic_dir_segments} ); $dirs ? $dirs.'/' : '' } )
				.$self->_signature, 
			{},
			$localize
		);  
	};
	
	$self->error( "Retrieval though stat()'ed successfully (".$self->_file_path."): FAILED ($@)\n" ) if $@;
	print STDERR "Using cached output:\n\n $output\n\n" if DEBUG;

	return $output;
    }

    # process precompiled component
    $context->process( $self->_precompile, {}, $localize ); 
}

sub include {
    (shift)->process( @_, 1 );
}


sub purge {
    my $self = shift;
    my $class = ref($self);
   
    my $CACHE_DIR_NAME = CACHE_DIR_NAME;
    my $caching_dir = $self->compiled_options( 'caching_dir' );

    if ( 
	do { my $class_ue = uri_escape($class, UNSAFE ); $caching_dir =~ /$class_ue/; } && 
	$caching_dir =~ /${CACHE_DIR_NAME}/ &&
	-e $caching_dir &&
	-d $caching_dir # kind of paranoia
    ) {
	eval { rmtree( $caching_dir, 0, 1 ) };
	if ( $@ ) {
    		$class->error( "Couldn't remove directory tree: $caching_dir. Error message: $@" );
	}
    }

    '';
}


sub _complement_keys {
    my $self = shift;
    my $keys = shift;

    my $callers = $self->{CONTEXT}->stash->get( 'component.callers' );

    +{ 
	%{ $self->{CONFIG}->{extend_keys}->( $self ) }, 
	%{$keys}, 
	'_file_scope' => 
	( ref($callers) ? join( '\\', @{$callers} ) : '' )
	.$self->{CONTEXT}->stash->get( 'component.name' ) 
		# For making BLOCK name in template file scoped we need a unique identifier:
		# component.callers + component.name 
		# This approach introduces the drawback that a BLOCK defined in a template being 
		# included in different other templates as an "intra" is cached for each call stack
		# path seperately! But it is a feasable workaround as we don't know how to figure
		# out the name of the template the BLOCK was defined in.
    }; 
}

sub _precompile {
    my $self = shift;
    my $context = $self->{CONTEXT};
    my $stash = $context->stash();
    
    my $TAGS_tag = 
    $TAG_STYLE_unquotemeta->{ $self->{CONFIG}->{precompile_tag_style}  }->[0]
    .' TAGS '.$self->{CONFIG}->{runtime_tag_style}.' '
    .$TAG_STYLE_unquotemeta->{ $self->{CONFIG}->{precompile_tag_style} }->[1]."\n";

    print STDERR "We are using tag style: $self->{CONFIG}->{precompile_tag_style}\n" if DEBUG;

    my $template;
    eval {
	$template = $context->process( $self->{params}->{template}, { TwoStage_precompile_mode => 1 }, 1 );
    };

    if ( $@ ) {
	print STDERR "\tFAILED ($@)\n"  if DEBUG;
	$self->error( ref($@) ? $@ : "Precompilation of module $self->{params}->{template}: $@ \n" );
    }

    print STDERR "storing ".$self->_signature."\n\n" if DEBUG;

    eval { mkpath( $self->_file_dir, 0, 0700 ) };
    if ($@) {
    	$self->error( "Couldn't create ".$self->_file_dir.": $@" );
    }

    open( my $fh, "> ", $self->_file_path ) || $self->error( "Could not get a filehandle! Error: $!" );

    my $out = 
    $TAGS_tag
    .( 	$self->{CONFIG}->{dev_mode} 
    	&& 
    	$TAG_STYLE_unquotemeta->{ $self->{CONFIG}->{runtime_tag_style} }->[0]
	."# This precompiled template ( $self->{params}->{template} ) is stored together with the following keys:\n\t"
	.join( "\n\t", map { "$_ => ".( defined $self->{params}->{keys}->{$_} ? $self->{params}->{keys}->{$_} : 'undef' ) } keys %{$self->{params}->{keys}} )."\n "
	.$TAG_STYLE_unquotemeta->{ $self->{CONFIG}->{runtime_tag_style} }->[1]."\n"
	|| 
	'' 
    )
    .$template; 
    

    if ( Encode::is_utf8( $template ) ) {

    	print STDERR "_precompile: encode\n" if DEBUG;
    	$out = Encode::decode_utf8( "\x{ef}\x{bb}\x{bf}" ).$out; # utf8 bom is stripped off again on load by Template::Provider
	binmode( $fh ); # turn off crlf io layer!?
	binmode( $fh, ':encoding(utf8)' );

    } else {

    	print STDERR "_precompile: octets\n" if DEBUG;
	binmode( $fh );
    }
     
    print $fh $out; 
    close $fh;

    return \($TAGS_tag.$template);
}

sub _signature {
    my $self = shift;
    # produce signature
  
    $self->{prec_template}->{signature} 
    ||=
    sha1_hex(
    	join(
        	':',
            	(
                	$self->{params}->{template},
                	map { "$_=".( $self->{params}->{keys}->{$_} || '' ) } sort keys %{$self->{params}->{keys}}
            	)
    	)
    ).'.tt';
} 

sub _dynamic_dir_segments {
    my $self = shift;
   
    $self->{prec_template}->{dynamic_dir_segments}
    ||=
    [
	# include a possible namespace
	( $self->{CONFIG}->{namespace} ? $self->{CONFIG}->{namespace} : () ),
	# include dir_keys - we offer this feature only in testing mode!
	( 	$self->{CONFIG}->{dev_mode} && $self->{CONFIG}->{dir_keys}
 		?
  		(	
			$self->{params}->{template},
			map { 	uri_escape( $_, UNSAFE ),
		      		uri_escape( 'value-'.$self->{params}->{keys}->{$_}, UNSAFE ) 
			} 		
			( ref( $self->{CONFIG}->{dir_keys} ) 
			  ? 
			  grep( { exists $self->{params}->{keys}->{$_} } @{$self->{CONFIG}->{dir_keys}} ) 
			  : 
			  keys %{$self->{params}->{keys}} 
			)
		)
  		:
	  	()
	)
    ];
}

sub _rel_file_path {
    my $self = shift; 

    $self->{prec_template}->{rel_file_path} ||= &_concat_path( $self->_rel_file_dir, $self->_signature );
}

sub _file_path {
    my $self = shift; 

    $self->{prec_template}->{file_path} ||= &_concat_path( $self->compiled_options( 'caching_dir' ), $self->_rel_file_path );
}

sub _rel_file_dir {
    my $self = shift;
    
    $self->{prec_template}->{rel_file_dir} ||= File::Spec->catdir( @{$self->_dynamic_dir_segments} );
}

sub _file_dir {
    my $self = shift;

    $self->{prec_template}->{file_dir} ||= &_concat_path( $self->compiled_options( 'caching_dir' ), $self->_rel_file_dir );
}

# helpers

sub _concat_path {
    my ( $base_path, $append_dirs ) = @_;
    # $base_dir: base path (no filename) as string
    # $append_dirs: directories to append as string or an array reference
    
    my ($base_volume, $base_directories, $base_file) = File::Spec->splitpath( $base_path, 1 );
    File::Spec->catpath(
    	$base_volume,
		File::Spec->catdir( 
			File::Spec->splitdir( $base_directories ),
			( ref($append_dirs) ? @{$append_dirs} : File::Spec->splitdir( $append_dirs ) )
		) 
    	,
	$base_file
    );
}


1; # End of Template::Plugin::TwoStage

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Plugin::TwoStage - two stage processing of template blocks with first stage caching

=head1 VERSION

version 0.08

=head1 SYNOPSIS

This is a plugin for the Template Toolkit that facilitates a two stage processing of BLOCKs/templates with first stage caching. Processing results of the first (precompilation) stage are cached away for subsequent repeated processing in the second (runtime) stage. Precompilation and runtime tags are seperated by using different tag styles.

Sample Configuration via TT configuration:

   Template->new( { ..., TwoStage => { caching_dir => My::Application->path_to_tmp(), ... } } );

Basic usage in the a TT2-template:

   [% 	USE TwoStage; 
   	TwoStage.process( 
		template => 'cached_page', 
		keys => { bar => bar  }, 
		ttl => 60 * 60 
	);

   	BLOCK cached_page; 
		# use precompile tags or runtime tags here
   %]
		[* foo # runtime stage evaluation *]	
   [% 		   IF bar; # precompilation stage evaluation 
			# ... 
		   ELSE;
		   	# ...
		   END;
   	END 
   %]

=for Pod::Coverage load new error create include process compile_options compiled_options dump_options

=head1 FEATURES 

=over

=item * parameterized precompilation of a single block

Pass keys as additional identifiers of a BLOCK/template, based upon which the BLOCK/template produces a different precompiled output/version. 

=item * expiration 

Give the precompiled BLOCKs/templates a 'time to live' before they expire.

=item * namespaces

Distinguish different e.g. applications sharing a common TwoStage plugin (sub)class and/or caching directory by the use of namespaces.

=item * development mode

Edit your templates with caching turned off. The development mode also gives you convenient access to the precompiled versions produced for validation of your separation of precompilation and runtime directives.

=item * flexible configuration

Set your basic configuration in the TT configuration, or in a subclass of this plugin, and override any configuration option on plugin construction or even on single plugin method calls to include() or process() in the templates.

=back

=head1 USE CASES

You might benefit from this module if ... 

=over 4

=item

... you have static external content e.g. from databases or .po-files that you want to pull into your templates only once while still being able to insert dynamic data into the same template

=item

... you are following the DRY principle by having a central BLOCK library that you use to style your GUI HTML components

=item

... you do not want to use ttree because you prefer "lazy" precompilation (only on demand), and you want to see your changes to the template without running an external program first

=back

=head1 CONFIGURATION 

Plugin behaviour can be controlled using following options:

=head2 Options

=head3 caching_dir

The TwoStage plugin will store the resulting precompiled templates from the first stage on disk in a 'caching directory', that can be specified with the 'caching_dir' option.

The directory 'TT_P_TwoStage' in your platform specific tmp-directory determined with the help of File::Spec->tmpdir() is the default setting for this option. Pass a path in order to change it to some other directory - it will also be automatically extended by the subdirectories 'TT_P_TwoStage' and the plugin's class name. 

This option can NOT be set on plugin construction or calls to include()/process().

=head3 dev_mode

Set this configuration option to a TRUE value in order to disable the use of cached - precompiled - files, and see your changes to cached BLOCKs/templates immediately while still having access to the precompiled versions on disk for their validation.

See also the configuration option 'dir_keys' as another interesting feature for development.

=head3 ttl

Specify the "time to live" for the precompiled versions of the BLOCKs/templates in seconds - 0 is 'no expiration' and the default setting.

=head3 dir_keys

Usually the keys connected to a precompiled version are included among other things into the file name of a BLOCK/template in order to identify a precompiled cached BLOCK/template on disk. This is accomplished by using the SHA1 hash function.

To make the retrieval of a certain caching file easier for humans, the configuration parameter 'dir_keys' lets you include the keys into the file path of the precompiled cached BLOCK/template. This behaviour might be handy in cases where one wants to inspect the precompiled versions produced.

Set 'dir_keys' either to an array reference holding a selection of keys or a scalar holding a TRUE value for all keys. This feature is available in development mode only! See also configuration option 'dev_mode'.   

See also the section 'Caching with plugin object methods process() and include()' for more on the 'keys' parameter.

=head3 namespace

This option can come to rescue in situations where identities of cached BLOCK/template versions on disk can be ambigious relying only on the standard measures taken by this plugin in order to disambiguate cached disk versions (see section 'Avoiding disk cache overlaps' below). 

If e.g. you choose not to subclass this module for an application you can ensure the segmentation of applications by setting the 'namespace' configuration option accordingly. In this example however this approach has the drawback that you need to set this configuration option in each template on plugin construction: 

    USE TwoStage( namespace => application_name );

=head3 runtime_tag_style

Set this option to one of the predefined tag styles TT is offering like 'php', 'mason', 'html', ..., and that are accepted by TT as a value to its 'TAG_STYLE' configuration option or 'TAGS' directive. Default is: star ([* *]).

Excursus: precompilation tag style

The precompilation tag style is always the tag style set in the TT configuration or 'default'. A tag style defined local to the file the plugin is being called in ( by means of the 'TAGS'-directive at the beginning of the file) will be handled correctly - this file scoped tag style will also be used in the BLOCK to be precompiled as precompilation tag style.

Changing the tag style only for a certain BLOCK that is to be precompiled is not possible, as the 'TAGS' directive can be set only on per template file basis. A centralized configuration of the precompilation tag style to be used is not available to date.

=head3 tt_cache_size

As one can produce a lot of precompiled versions of a single BLOCK/template controlled by this plugin using the 'keys' feature of process()/include(), it might be advisable in some situations to set the CACHE_SIZE TT configuration option to a positive value in order to curb memory consumption when having a TT singleton object around in a persistent environment.

As the plugin uses a provider object specific to the plugin it will not respect the CACHE_SIZE configuration property possibly set in your main TT configuration. Use this method in order to set the CACHE_SIZE configuration property for the plugin's specific provider object. By default all precompiled templates are cached. 

In contrast to all the other configuration options - except 'caching_dir' - this option can only be set as class data.

=head2 Setting options

Configuration options may be set in different ways and with different scopes.

=head3 Setting options in TT configuration

This plugin can be configured using the configuration hash provided to the Template Toolkit-constructor. Put your plugin configuration options in a hash, and reference it in the TT configuration hash using the key 'TwoStage'.

Sample code:

   Template->new( { ..., TwoStage => { namespace => 'My::Application', ... } } );

The configuration options will apply to all TwoStage plugin-objects created in this TT object. Note that this does NOT hold true for derived classes of the plugin!

Note! In order to avoid disk cache overlaps of applications using the TwoStage plugin without subclassing, configure a unique namespace or a separate caching directory. See also 'Avoiding disk cache overlaps' below.

=head3 Setting options via subclassing 

This plugin is subclassable. Configuration with scope restricted to the subclass can be achieved by using the inheritable class data accessors provided (see sample code below).

Subclassing allows you to customize your plugin behaviour at a single place, and to complement the caching keys via a possible callback method extend_keys(). At the same time it avoids disk cache overlaps for applications sharing the same caching directory as long as the derived plugin is not used in different applications. 

Subclasses will not read the plugin options specified in the TT configuration hash when configuring.

Sample code: 

   # sample code is based on an imaginary Catalyst application Your::Application

   package Your::Application::Template::Plugin::TwoStage;
   use base qw( Template::Plugin::TwoStage );

   __PACKAGE__->caching_dir( Your::Application->config->{home}.'/tmp' );
   __PACKAGE__->dev_mode( 1 );
   __PACKAGE__->ttl( 60 * 60 ); # 1 h
   __PACKAGE__->dir_keys( 1 );
   __PACKAGE__->runtime_tag_style( 'html' );

   sub extend_keys {
        my $plugin = shift; # the callback receives the plugin object as 1st parameter
	
	my $s = $plugin->{CONTEXT}->stash;

	# get Catalyst context from stash
	my $c = $s->get( 'c' );
	my $r = $c->request;

        # hook method for adding standard keys - return the keys => value -hash by reference!
        { domain => $r->uri->authority,
	  method => $r->method,
	  logged_in => $c->user_exists
	};

   }

Don't forget to add your subclass to the plugin base of your TT2-configuration:

	PLUGIN_BASE => [ 'Your::Application::Template::Plugin' ]

or declare it via the PLUGINS TT2-configuration option

	PLUGINS => { TwoStage => 'Your::Application::Template::Plugin::TwoStage', ... }

=head3 Setting options as named parameters to USE or include()/process()

Any option set via subclassing or the TT configuration hash can be overridden on plugin construction ( 'USE TwoStage()' ) or even on the call of the include() or precompile()-methods at your will with only restricted scope. Configuration provided on plugin construction will apply to this specific plugin object only; configuration provided as parameters to include()/process() only to the specific plugin object call.

Sample code:

   USE TwoStage( ttl => 1000 );
   TwoStage.process( template => 'some', ttl => 0 );

Note! The following options can not be overridden this way: caching_dir, tt_cache_size

=head2 Object hook methods 

=head3 extend_keys

With this callback method it is possible to merge some default keys into the template signature. The values of the keys introduced this way will be dominated by the values of identical keys passed to process() or include(). Return a hash reference mapping standard signature keys to its values! 

Have a look at the sample code above (section 'Setting options via subclassing').

When setting options in the TT configuration hash simply add a reference to your extend_keys-function with key 'extend_keys'. It will receive the plugin object as the first parameter when being called.

   Template->new( 
   	{ ..., 
	  TwoStage => { 
		extend_keys => sub { 
			my $plugin = shift; 
					
			return { key => $value };  
		}, ... 
   
   	  } 
	} 
   );

=head2 Avoiding disk cache overlaps

Having precompiled a BLOCK/template the TwoStage plugin tries to assign an unique as possible identity to it - refered to as 'signature' later -, and writes it to disk into the configured caching directory (see also corresponding option 'caching_dir') using a SHA1 fingerprint of the signature as its file name. 

=head3 What is the unique signature made up of and how unique is it?

=over 2

=item * template path

If the component processed with the TwoStage plugin is a template, the template's path is included in the signature.

Template paths are relative to a template provider object configured and might also be relative to some entry in the provider's INCLUDE_PATH or an equivalent (this does not apply to providers configured to serve templates by absolute path obviously).

=item * BLOCK name

If the component processed with the TwoStage plugin is a BLOCK its name is included into the signature. In order to make the BLOCK name template spanning unique we augment the BLOCK name with the values of TT meta variables 'component.callers' and 'component.name' - which in turn is the call stack of BLOCKs and templates to the BLOCK from the outermost file the BLOCK was included in.

The uniqueness of BLOCK names achieved however is limited as it is still relative to the template providers and their configuration (see previous item).

=item * plugin class name

The precompiled BLOCK/template versions will be saved in a subdirectory under the caching directory specified and named after the class/package name of the TwoStage plugin.

=item * keys passed to process()/include()

See section 'CACHING / Caching with process() and include()' below.

=back

=head3 Implications

=over 2

=item

Unless you really know about the consequences always set the configuration option 'caching_dir' to a filesystem directory specific to the TwoStage plugin subclasses used or to the TT object in case the plugin is used directly.

=item

Use the namespace option or add an equivalent key via the extend_keys() callback function if you have dynamic entries in the INCLUDE_PATH or an equivalent that reflects the current state auf the INCLUDE_PATH. 

=back

=head1 CACHING 

=head2 Caching with plugin object methods process() and include()

Once the plugin object has been pulled into the template by means of the 'USE' directive, calling the plugin object methods include() or process() against it will insert the BLOCK/template content with all the precompilation and caching magic delivered by this plugin into the template.

Named parameters of process/include:

=over 4

=item * template 

Specify the name of the BLOCK/template to be processed/included into the template here. Its name does not have to be template spanning unique. The plugin takes care that the name is local to the template it is defined in. 

=item * keys (optional)

Use this parameter in situations where you want to evaluate a certain stash variable in the precompilation stage, and that variable can take on only a limited set of discrete values in the runtime stage but has considerable influence on the precompiled versions. Examples for such variables might be: template language, user preferences, user privileges, ...

Each combination of the values of the variables passed as 'keys' parameter will produce a distinct precompiled version of the BLOCK/template in question. Take care not to choose to many keys with to many values in order to produce only a reasonable number of precompiled versions.

If you find some keys are supposed to be added to each and every call to process() or include() consider using the extend_keys() hook method (see also above).

=item * all of the available configuration options (optional)

For more on those options see section "Configuration Options" in this documentation.

=back

include() is exposing an identical behaviour as process() with the exception that it does stash localisation in the runtime stage.

=head2 Reset cached content with purge() 

In order to set back caching remove the cached templates from your caching directory. Maybe a script to assist you in this task will be shipped together with a future version of this plugin.

Using purge() you remove all files from the caching directory of the class - use this to set back caching from within templates. This method is used mainly in the self tests of this module. Maybe there are even more useful applications for it - so it became a public class method.

	[% TwoStage = USE TwoStage; 
	   TwoStage.purge;
	%]

=head2 STAT_TTL and caching

Please note that the STAT_TTL configuration of TT will not work for cached BLOCKs/templates as you make modifications to the "source" BLOCKS/templates of those cached templates. You should turn off caching instead using the plugin option 'dev_mode'.

=head1 EXPORTS

=head2 TT configuration

The compiled plugin configuration is saved with key '_TwoStage' in the main TT configuration hash.

=head2 TT stash

There is a temporary stash entry 'TwoStage_precompile_mode = 1;' in the precompilation stage of template processing.

=head1 HEURISTICS 

In order to avoid common pitfalls when using this module you find some tips and reminders below:

=over

=item * 

Templates used as fragments with runtime directives ought to be controlled by the TwoStage plugin themselves! This ensures that such templates can be included into another template either at runtime or at precompilation stage.

=item * 

Upstream keys from included templates ( fragments ) must be incorporated into the 'keys' option of the including template! Explanation: They have to be known ex ante meaning prior to a test for a cached version of a template and can therefor not easily be collected from upstream templates automatically!

=item * 

Situation: A template A includes another template B while both are using the TwoStage plugin. In addition you pass parameters on invocation of INCLUDE, PROCESS to template B. Add those parameters to the 'keys' option when calling the TwoStage plugin in template B and use them at precompilation stage. This way you can include template B at runtime and at precompilation at your will.

=item * 

Ensure there are no BLOCK definitions inside the BLOCK to be TwoStage processed! This is nothing specific to the TwoStage plugin really, but is a common mistake. Simply put those BLOCKs outside the BLOCK to be TwoStage processed. They will be visible to it anyway.

=item *

When altering option 'dev_mode' on plugin object construction or on calls to the methods process()/include() one has to be cautious in situations where calls to the TwoStage plugin methods process()/include() are nested: Remember to alter the option in the outermost call to achieve the desired effect!

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-plugin-twostage at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-TwoStage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::TwoStage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-TwoStage>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Plugin-TwoStage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Plugin-TwoStage>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Plugin-TwoStage>

=back

=head1 ACKNOWLEDGEMENTS

This module was inspired to some extent by Perrin Harkins L<http://search.cpan.org/dist/Template-Plugin-Cache> and not least by my CO2 footprint.

=head1 SEE ALSO

Template::Plugin, L<http://search.cpan.org/dist/Template-Plugin-Cache>

=head1 AUTHOR

Alexander Kühne <alexk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Alexander Kühne.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
