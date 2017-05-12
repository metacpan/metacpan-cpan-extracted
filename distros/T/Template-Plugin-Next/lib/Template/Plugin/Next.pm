#
# This file is part of Template-Plugin-Next
#
# This software is copyright (c) 2017 by Alexander Kühne.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Template::Plugin::Next;
# ABSTRACT: include the 'next' template file with identical relative path
$Template::Plugin::Next::VERSION = '0.04';
use warnings;
use strict;

use base qw( Template::Plugin );
use Template::Plugin ();
use Template::Exception ();

use File::Spec ();


sub new {      
    # called as Template::Plugin::Next->new($context)
    my ($class, $context, %params) = @_;

    my $self =
    bless {
	_CONTEXT => $context
    }, $class;

    $self;
}

sub error {
    my $proto = shift;
    die( ref( $_[0] ) ? @_ : do { $proto->SUPER::error(@_); Template::Exception->new( 'Next', $proto->SUPER::error ) } );
}


sub process {
    my $self = shift;
    my $params = shift;
    my $localise = shift || 0;
    my $context = $self->{_CONTEXT};
    my $stash = $context->stash();

    my $name = $stash->get( 'component.name' ); # template file path not file name

    my $providers =  $context->{ PREFIX_MAP }->{ default } || $context->{ LOAD_TEMPLATES };

    foreach my $provider ( grep { ref( $_ ) eq 'Template::Provider' } @$providers ) { 
    	# we know only how to handle the standard behaviour of providers

	my $rel_path = $name;
	my @include_paths = @{$provider->paths}; 
		# include paths are returned in a list even if 
		# multiple include paths have been specified via a colon separated scalar

    	$self->error( 'Not applicable. There is no second include path!' ) if scalar(@include_paths) == 1; 
	
	if ( File::Spec->file_name_is_absolute( my $abs_path = $rel_path ) ) {
		# this is for subsequent calls to NEXT
		( my( $include_path ), $rel_path ) = 
		@{
		    (	( $stash->get( 'Next_' ) || $self->error( 'Could not find Next_ stash entry!' ) )->{$abs_path}
			|| 
			$self->error( "Could not find abs path $abs_path in Next_ map!" )
		    )
		};

		while ( @include_paths ) {
			last if ( shift @include_paths ) eq $include_path; 
		}
		$rel_path =~ s/^\///;

	} else {
		# this is for the initial call to NEXT
		while ( @include_paths ) {
			last if scalar stat( _concat_path( (shift @include_paths ), $rel_path ) );
		}
	}

	foreach my $include_path ( @include_paths ) {
		my $path = _concat_path( $include_path, $rel_path );

		if( scalar stat( $path ) ) {
			my $template;
			{
				# make abs. template paths local to this template retrieval
				local $provider->{ABSOLUTE} = 1;
				$template = $context->template($path);
			}
			defined $template || $self->error( $context->error );
			my $map = $stash->get( 'Next_' ) || {};
			$map->{$path} = [ $include_path, $rel_path ];
			$stash->set( 'Next_' => $map );
			return $context->process( $template, $params, $localise );
		}
	}
    }

    $self->error( "No 'Next' template!" );
}


sub include {
    my $self = shift;
    $self->process( @_, 1 );
}

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


1; # End of Template::Plugin::Next

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Plugin::Next - include the 'next' template file with identical relative path

=head1 VERSION

version 0.04

=head1 SYNOPSIS

This is a plugin for the Template Toolkit distribution that allows the inclusion of template files with identical relative paths like the present template. Those templates are 'hidden' by the present template, because their respective INCLUDE_PATH entries are dominated by the one of the including template.

The functionality provided by this plugin might come handy in multi skin situations where default templates are selectively redefined by a skin using a dominating INCLUDE_PATH entry for the skin and identical relative paths to the templates as with the default templates - thus hiding them. 

The Next-plugin allows to include the dominated default templates from inside the hiding template in order to decorate the default template or include a parameterized version of it. 

Example:

  # We assume: INCLUDE_PATH='/templates/c:/templates/b:/templates/a'

  # template a/test.tt (note this template accepts a "parameter" called 'repeat'):
  [% repeat = repeat || 1; 'a' | repeat(repeat) %]
  
  # template b/test.tt:
  b
  [% USE Next; Next.include( repeat => 3 ); %]
  b
  
  # template c/test.tt:
  c
  [% USE Next; Next.include(); %]
  c

  # a call to template test.tt
  [% INCLUDE test.tt %]
  
  # would yield something like the following (with POST_CHOMP set to 1):
  
  c
  b
  aaa
  b
  c

=head1 EXPORT

Exported stash variable: Next_

=head1 METHODS

=head2 process

Includes the 'next' dominated template with an identical relative path like the one this plugin method is called from. It accepts named parameters like its TT directive counterpart PROCESS that will result in stash variables.

=head2 include

Same as process() but with stash localisation. 

=head1 CAVEATS

=over 4 

=item * INCLUDE_PATH stability is required during a single call to Template::process().

=item * Only template providers of class Template::Provider are supported.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-plugin-next at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Next>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::Next

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-Next>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Plugin-Next>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Plugin-Next>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Plugin-Next/>

=back

=head1 AUTHOR

Alexander Kühne <alexk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Alexander Kühne.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
