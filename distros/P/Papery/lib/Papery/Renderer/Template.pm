package Papery::Renderer::Template;

use strict;
use warnings;

use Papery::Renderer;
our @ISA = qw( Papery::Renderer );

use Template;

sub render {
    my ( $class, $pulp, @args ) = @_;
    my $template
        = Template->new( @args, INCLUDE_PATH => $pulp->{meta}{_templates} )
        or die Template->error();

    die "No _layout for $pulp->{meta}{__source_file}"
        if !$pulp->{meta}{_layout};

    local $Template::Stash::PRIVATE;    # we want to see "private" vars
    $template->process( $pulp->{meta}{_layout},
        $pulp->{meta}, \( $pulp->{meta}{_output} = '' ) )
        or die $template->error;

    return $pulp;
}

1;

__END__

=head1 NAME

Papery::Renderer::Template - Papery renderer based on Template

=head1 SYNOPSIS

    # _config.yml
    _renderer: Template

    # metadata
    _renderer: Template

=head1 DESCRIPTION

C<Papery::Renderer::Temlate> will render the C<_content> of a C<Papery::Pulp>
object with C<Template>, and put the result  in the C<_output>.

=head1 METHODS

This class provides a single method:

=over 4

=item render( $pulp )

Simply proces the template defined in C<_layout> to produce the C<_output>.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book at cpan.org> >>

=head1 COPYRIGHT

Copyright 2010 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

