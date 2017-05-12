package Template::Sandbox::Library;

use strict;
use warnings;

use Carp;

use Template::Sandbox;

my %function_library = ();
my %function_tags    = ();

BEGIN
{
    $Template::Sandbox::Library::VERSION = '1.04';
}

sub import
{
    my $pkg = shift;

    export_template_functions( $pkg, 'Template::Sandbox', @_ ) if @_;
}

sub export_template_functions
{
    my ( $this, $template, @imports ) = @_;
    my ( $pkg, $library, $tags, %export, @functions, $existing );

    $pkg = ref( $this ) || $this;

    croak "\"$pkg\" does not appear to be a template function library."
        unless $function_library{ $pkg };

    $library = $function_library{ $pkg };
    $tags    = $function_tags{ $pkg };

    %export = ();
    foreach my $import ( @imports )
    {
        foreach my $word ( split( /\s+/, $import ) )
        {
            my ( $delete );

            $delete = 1 if $word =~ s/^!//;

            if( $word =~ s/^:// )
            {
                my ( @names );

                if( exists $tags->{ $word } )
                {
                    @names = @{$tags->{ $word }};
                }
                elsif( $word eq 'all' )
                {
                    @names = keys( %{$library} );
                }
                else
                {
                    croak "\"$word\" is not a template library tag in $pkg";
                }

                if( $delete )
                {
                    delete $export{ $_ } foreach ( @names );
                }
                else
                {
                    $export{ $_ } = 1 foreach ( @names );
                }
            }
            else
            {
                if( $delete )
                {
                    delete $export{ $word };
                }
                else
                {
                    $export{ $word } = 1;
                }
            }
        }
    }

    $existing = $template->_find_local_functions();

    @functions = ();
    foreach my $name ( keys( %export ) )
    {
        croak "\"$name\" is not a template library function in $pkg"
            unless $library->{ $name };

        push @functions, $name => $library->{ $name }
            unless exists $existing->{ $name };
    }

    $template->register_template_function( @functions ) if @functions;
}

sub set_library_functions
{
    my ( $this, %functions ) = @_;
    my ( $pkg );

    $pkg = ref( $this ) || $this;

    $function_library{ $pkg } = \%functions;
    $function_tags{ $pkg } ||= {};
}

sub set_library_tags
{
    my ( $this, %tags ) = @_;
    my ( $pkg );

    $pkg = ref( $this ) || $this;

    $function_tags{ $pkg } = \%tags;
}

1;

__END__

=pod

=head1 NAME

Template::Sandbox::Library - Base library object for Template::Sandbox functions.

=head1 SYNOPSIS

  package MyApp::TemplateMaths;

  use base qw/Template::Sandbox::Library/;

  use Template::Sandbox qw/:function_sugar/;

  __PACKAGE__->set_library_functions(
        tan     => ( one_arg sub { sin( $_[ 0 ] ) / cos( $_[ 0 ] ) } ),
        atan    => ( two_args sub { atan2( $_[ 0 ], $_[ 1 ] ) } ),
        sin     => ( one_arg sub { sin( $_[ 0 ] ) } ),
        cos     => ( one_arg sub { cos( $_[ 0 ] ) } ),

        exp     => ( one_arg sub { exp( $_[ 0 ] ) } ),
        log     => ( one_arg sub { log( $_[ 0 ] ) } ),
        pow     => ( two_args sub { $_[ 0 ] ** $_[ 1 ] } ),
        sqrt    => ( one_arg sub { sqrt( $_[ 0 ] ) } ),
        );
  __PACKAGE__->set_library_tags(
        trig => [ qw/tan atan sin cos/ ],
        );

  1;

  #  Elsewhere in your app.

  #  Registers all my trig template functions (tan, tan sig cos)
  #  with Template::Sandbox at the class level (for every template)
  use Template::Sandbox;
  use MyApp::TemplateMaths qw/:trig/;

  #  or for registering to a template instance individually:
  use Template::Sandbox;
  use MyApp::TemplateMaths;

  my $template = Template::Sandbox->new();
  MyApp::TemplateMaths->export_template_functions(
      $template, qw/:trig/ );

  #  or more conveniently:
  my $template = Template::Sandbox->new(
      library => [ MyApp::TemplateMaths => qw/:trig/ ],
      );

  #  or for several libraries:
  my $template = Template::Sandbox->new(
      library => [ MyApp::TemplateMaths => qw/:trig/ ],
      library => [ MyApp::TemplateHTML  => qw/uri_escape html_escape/ ],
      );

  #  but NOT this:
  my $template = Template::Sandbox->new(
      library => [
          #  WRONG!  Everything after this next => will be taken as
          #  a function name or tag to try to export to your template.
          MyApp::TemplateMaths => qw/:trig/,
          MyApp::TemplateHTML  => qw/uri_escape html_escape/,
        ],
      );

=head1 DESCRIPTION

L<Template::Sandbox::Library> is a base class for easily defining
libraries of I<template functions> to add to the sandbox your
L<Template::Sandbox> runs in.

It works by storing a hash of function names to functions definitions,
and a hash of tag names to function names, then you can export individual
functions or groups of functions into a L<Template::Sandbox> instance
(or the entire class) in a similar way to importing functions into a
package via L<Exporter>.

=head1 FUNCTIONS AND METHODS

Note that these functions and methods are not to be called
directly on L<Template::Sandbox::Library>, they should be called
on subclasses of it.

=over

=item B<< import() >>

Called automatically by C<use>, this will take the L<Exporter> style
arguments to C<use> and build a list of functions to register with
L<Template::Sandbox> at the class level (global to all templates):

  use Template::Sandbox::NumberFunctions qw/:all/;

You probably shouldn't call import() directly yourself, you should
only access it via C<use>, if you want to manually export template
functions, use C<< export_template_functions() >> detailed below.

=item B<< $library->export_template_functions( >> I<$template>, I<@names> B<)>

Exports the given names into C<$template> as template functions.

Each entry in C<< @names >> should follow a form familiar to users of
L<Exporter>, it's either a literal function name, or if it starts
with a ':' it's a tag name for a list of functions, or if it starts
with a '!' it means to remove the name from the list of things to export,
some examples make this clearer:

  'atan'     #  The function named 'atan'
  ':trig'    #  The functions in the group tagged 'trig'
  '!atan'    #  Remove the function named 'atan' from the list to export
  '!:trig'   #  Remove the 'trig' group of functions from the list

So to import all trig functions except atan you could do the following:

  MyApp::TemplateMaths->export_template_functions(
      $template, qw/:trig !atan/,
      );

Or for all functions, except trig functions, but including atan:

  MyApp::TemplateMaths->export_template_functions(
      $template, qw/:all !:trig atan/,
      );

For convenience this method can automatically be called as part of
your template constructor with the C<library> option, for example
the previous example could be written as:

  use Template::Sandbox;
  use MyApp::TemplateMaths;

  $template = Template::Sandbox->new(
      library => [ 'MyApp::TemplateMaths' => qw/:all !:trig atan/ ],
      );

=item B<< $library->set_library_functions( >> I<%functions> B<)>

Sets the I<template functions> that this library knows about, overwriting
any previous definitions and removing any existing functions from the
library that don't exist in the new hash.

The C<%functions> hash should be a list of function names to function
definitions, either as subroutine references or, preferably, as function
definitions produced by the C<function sugar> functions provided by
L<Template::Sandbox>.

See the L</"SYNOPSIS"> for some examples.

=item B<< $library->set_library_tags( >> I<%tags> B<)>

Sets the export tags that this library knows about, overwriting
any previous definitions and removing any existing tags from the
library that don't exist in the new hash.

The C<%tags> hash should be a hash of tag names to a list of function
names that exist in the C<%functions> passed to
C<< $library->set_library_functions() >>.

The 'all' group is automatically created for you if you haven't set it
already.

=back

=head1 KNOWN ISSUES AND BUGS

=over

=item None currently known.

=back

=head1 SEE ALSO

L<Template::Sandbox>, L<Template::Sandbox::StringFunctions>,
L<Template::Sandbox::NumberFunctions>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Sandbox::Library


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Sandbox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Sandbox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Sandbox>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Sandbox>

=back

=head1 AUTHORS

Original author: Sam Graham <libtemplate-sandbox-perl BLAHBLAH illusori.co.uk>

Last author:     $Author: illusori $

=head1 COPYRIGHT & LICENSE

Copyright 2005-2010 Sam Graham, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
