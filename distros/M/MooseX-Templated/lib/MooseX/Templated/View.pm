package MooseX::Templated::View;

=head1 NAME

MooseX::Templated::View - Interface for MooseX::Templated views

=head1 SYNOPSIS

    package MooseX::Templated::View::MyRenderer;

    use Moose;
    use My::Renderer;

    with 'MooseX::Templated::View';

    my %CONFIG = ( FOO => 1 );

    sub build_default_template_suffix { '.tpl' }
    sub build_renderer { My::Renderer->new( option => 1 ) }

    # return rendered output as string
    sub process {
        my $self = shift;

        # instantiated from view_class and view_config
        my $view = $self->view;

        # source will be provided by defaults
        my $source = $self->source;

        # get rendered output from backend
        my $output = $engine->some_render_method(
                        src   => $source,
                        stash => { self => $self },
                    );

        return $output;
    }

=cut

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class qw/ Dir /;
use Carp;
use Path::Class;
use namespace::autoclean;

subtype 'TemplateSource'
    => as 'Str';

requires qw/
  build_default_template_suffix
  build_renderer
/;

has default_template_suffix => (
    isa     => 'Str',
    is      => 'ro',
    builder => 'build_default_template_suffix',
);

has 'renderer' => (
    isa     => 'Object',
    is      => 'ro',
    lazy    => 1,
    builder => 'build_renderer',
);

=head1 INTERFACE

=head2 process( $source, $model_object )

The individual view needs to implement this method to actually process the template.

=cut

requires 'process';

1;
__END__

=head1 DESCRIPTION

This role provides a general interface for backend template systems (e.g. L<MooseX::Templated::View::TT>)

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
