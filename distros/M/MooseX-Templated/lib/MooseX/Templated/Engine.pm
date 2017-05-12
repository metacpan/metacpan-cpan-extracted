package MooseX::Templated::Engine;

=head1 NAME

MooseX::Templated::Engine - connects MooseX::Templated object to template

=head1 SYNOPSIS

Internal docs - see L<MooseX::Templated> for usage.

    my $engine = MooseX::Templated::Engine->new(
      model                => My::Module->new( ... ),
      view_class           => 'MooseX::Templated::View::TT',
      view_config          => \%config,
      template_suffix      => '.tt',
      template_root        => '__LIB__/root/src',
      template_method_stub => '_template',
    );

    $engine->render();
    # source:
    #   @INC/root/src/My/Module.tt
    #   My::Module::_template

    $engine->render( source => "xml" );
    # source:
    #   @INC/root/src/My/Module.xml.tt
    #   My::Module::_template_xml

    $engine->render( source => "/path/to/file.ext" );
    # source:
    #   /path/to/file.ext

    $engine->render( source => \"[% template %]" );
    # source:
    #   <inline>

=cut

use Moose;
use MooseX::Templated::View::TT;
use MooseX::Templated::Util qw/ where_pm /;
use MooseX::Types::Path::Class qw/ Dir /;
use Path::Class qw/ file /;
use Carp qw/ carp croak /;

our $VERSION = $MooseX::Templated::VERSION; # CPAN complained when VERSION moved to MX::T

has 'view' => (
    is       => 'ro',
    does     => 'MooseX::Templated::View',
    lazy     => 1,
    builder  => '_build_view',
);

sub _build_view {
  my $self = shift;
  return $self->view_class->new( model => $self->model );
}

has 'view_class' => (
    is       => 'ro',
    isa      => 'ClassName',
    default  => 'MooseX::Templated::View::TT',
    required => 1,
);

has 'template_method_stub' => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    default  => '_template',
);

has 'template_suffix' => (
    is       => 'rw',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_template_suffix',
);

sub _build_template_suffix {
  my $self = shift;
  return $self->view->default_template_suffix;
}

has 'template_root' => (
    is       => 'rw',
    isa      => Dir,
    coerce   => 1,
    default  => '__LIB__',
);

has 'model' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

=head2 render()

=head2 render( source => $source )

=cut

# implemented as sub (rather than handles) so it can be
# 'excluded' in any consuming objects
sub render {
  my $self = shift;
  my $args = scalar @_ == 1 ? $_[0] : { @_ };

  # if this is a single string and looks like a shortcut then
  # we'll allow this for the moment
  if ( !ref $args && $args =~ /^[a-zA-Z0-9_]+$/ ) {

    # https://rt.cpan.org/Public/Bug/Display.html?id=109631
    local $Carp::Internal{ 'Moose::Meta::Method::Delegation' } = 1;

    carp "DEPRECATED USAGE: render('$args') should be written render(source => '$args')";
    $args = { source => $args };
  }
  if ( ref $args ne 'HASH' ) {
    croak "ERROR: unexpected arguments to render ($args)";
  }
  my $source_arg = $args->{source};

  my $source = $self->get_source( $source_arg );

  my $model = $self->model;

  return $self->view->process( $source, $model );
}

=head2 get_source()

=head2 get_source( $shortcut )

=head2 get_source( \$template )

A shortcut is a simple string such as C<"xml">.

Called from the module C<Farm::Cow>, this will attempt to find the file:

  @INC/Farm/Cow.xml.tt

based on:

  ${template_root}/Farm/Cow.${shortcut}.${template_suffix}

Otherwise it will check with the calling object has a method:

  Farm::Cow::_template_xml

=cut

sub get_source {
    my $self            = shift;
    my $source_type     = shift || '';

    if ( ref $source_type eq 'SCALAR' ) {
        return ${ $source_type };
    }

    my $method_stub = $self->template_method_stub;

    my $source_type_lc  = lc( $source_type );

    my $method =
            $source_type
            ? $method_stub . "_" . $source_type_lc # _template_xml()
            : $method_stub;                        # _template()

    my $file_suffix =
            $source_type
            ? "." . $source_type_lc . $self->template_suffix        # .xml.tt
            : $self->template_suffix;                               # .tt

    my $default_file = $self->build_src_path( suffix => $file_suffix );

    my $source = $self->model->can( $method ) ? $self->model->$method()
                 : -e $default_file           ? file( $default_file )->slurp
                 : -e $source_type            ? file( $source_type )->slurp
                 : undef;

    if ( ! defined $source ) {
        croak "[error] ".__PACKAGE__.": couldn't set source:\n".
          ( ($source_type =~ /\n/xms)
              ? ' - looks like you passed source as "template source" (try \"template source")'."\n"
              : (
                  " - tried the following tests:\n".
                  join( "", map { "    $_\n" }
                      "METHOD: ".blessed( $self->model ) . "::" . $method,
                      "FILE:   ".$default_file,
                      "FILE:   ".$source_type,
                  ) .
                  ' - maybe you passed the source as "SCALAR" (try \"SCALAR")'."\n"
              )
          );
    }

    return $source;
}

=head2 build_src_path( %options )

Builds the default filename to be used the template source

    Farm::Cow => /path/to/Farm/Cow.tt

    template_root      class_name    template_suffix
    /path/to/          Farm/Cow      .tt

=head3 options

Explicitly passed options override defaults

=over 8

=item 'root' => '/alt/path'

=item 'suffix' => '.ext'

=back

=cut

sub build_src_path {
    my $self        = shift;
    my $args        = @_ == 1 ? $_[0] : { @_ };

    my $model_class = blessed $self->model;

    my ($abs_file, $inc_path, $require)
      = MooseX::Templated::Util::where_pm( $model_class );

    my $root   = exists $args->{ root }   ? $args->{ root }   : $self->template_root;
    my $suffix = exists $args->{ suffix } ? $args->{ suffix } : $self->template_suffix;

    $root =~ s/__LIB__/$inc_path/mg;

    my $path = Path::Class::File->new( $root, $require ) . "";

    $path =~ s{ .pm $ }{$suffix}xms;

    return $path;
}


1; # Magic true value required at end of module
__END__


=head1 METHODS

=head2 render( %options )

This renders the module consuming this role and returns the output as a string. This
method accepts the following optional key/values (either as %options or \%options):

=head3 source

Specifies the template source to be used for the rendering process. For
flexibility, the source can be specified in a number of different ways - the
intention is for it to Do What You Mean (DWYM).

How the source is interpreted will depend partly on the default options specified by the
L<template_view_class> that you are using (the default view is L<MooseX::Templated::View::TT>).
However, for consistency across your application, the recommended usage is to allow the
template source to be decided by using 'shortcuts'.

Default:

    Farm::Cow->new->render()

    # CHECKS FOR:
    #   - Farm::Cow::_template()
    #   - /path/to/Farm/Cow.tt

Using shortcuts:

    Farm::Cow->new->render( source => 'xml' )

    # CHECKS FOR:
    #   - Farm::Cow::_template_xml()
    #   - /path/to/Farm/Cow.xml.tt

These alternatives will also work:

    Farm::Cow->new->render( source => '/other/path/cow.tt' );

    Farm::Cow->new->render( source => \'Cow goes [% self.moo %]' );

See L<Setting the template source> for more information on the logic behind
choosing how to interpret this string.

=head2 view

Provides access to the underlying MooseX::Templated::View object

=head2 view_class

Can be passed in the constructor to specify which MooseX::Templated::View to use.

By default this is set to use the view based on Template Toolkit:

    'view_class' => 'MooseX::Templated::View::TT'

However, it is entirely possible that views will be written for different templating
engines in the future (contribs welcome!).

See L<MooseX::Templated::View> for details on implementing your own view.

=head2 view_config( \%options )

Config options to be passed to the template view class when creating the template
engine. These will be merged with any default parameters set by the view engine.

=head1 DEPENDENCIES

L<Moose>, L<Template>, L<Readonly>, L<File::Slurp>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-moosex-templated@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 ACKNOWLEDGEMENTS

Chris Prather (perigrin)

=head1 AUTHOR

Ian Sillitoe  C<< <isillitoe@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Ian Sillitoe C<< <isillitoe@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
