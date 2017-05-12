package MooseX::Templated::View::TT;

=head1 NAME

MooseX::Templated::View::TT - Template Toolkit View for MooseX::Templated

=head1 SYNOPSIS

See L<MooseX::Templated::View>

=cut

use Moose;
use Template;
use Carp;
use namespace::autoclean;

with 'MooseX::Templated::View';

my %TT_DEFAULT_CONFIG = (
    'ABSOLUTE' => 1,        # required for using default module name
);

=head2 build_default_template_suffix

=cut

sub build_default_template_suffix { '.tt' }

=head2 build_renderer

=cut

sub build_renderer {
    my $self = shift;
    return Template->new( %TT_DEFAULT_CONFIG );
}

=head2 process( $source, $model )

Processes the model using the TT source and returns the output as a string

=cut

sub process {
    my ($self, $source, $model) = @_;

    croak "! Error: expected 'source'" unless $source;
    croak "! Error: expected 'model' to be Moose object"
      if ( ! $model || ! blessed $model );

    my $tt_output = '';

    my %stash = ( self => $model );

    $self->renderer->process( \$source, \%stash, \$tt_output )
        or croak( "couldn't process template (module: ".($self->view_class).")\n".
                  "\t".$self->renderer->error() );

    return $tt_output;
}

1; # Magic true value required at end of module
__END__

=head1 DEPENDENCIES

L<Template>

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
