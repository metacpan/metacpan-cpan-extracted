package Template::Plugin::Text::Widont;

use strict;
use warnings;

use base qw/ Template::Plugin::Filter /;

use Text::Widont ();

our $VERSION = '0.01';


=head1 NAME

Template::Plugin::Text::Widont - A Template Toolkit filter for removing typographic widows

=head1 SYNOPSIS

    [% USE Text::Widont nbsp => 'html' %]
    [% "If the world didn't suck, we'd all fall off" | widont %]


=head1 DESCRIPTION

C<Template::Plugin::Text::Widont> provides a simple
L<Template Toolkit|Template> filter interface to the L<Text::Widont> module.

See the L<NON-BREAKING SPACE TYPES|Text::Widont/NON-BREAKING SPACE TYPES>
section in L<Text::Widont>'s documentation for more information about
available values for C<nbsp>.


=head1 METHODS

=head2 init

Overrides the method from L<Template::Plugin::Filter>.


=cut


sub init {
    my $self = shift;
    
    # Determine the name to use for the filter - see Template::Plugin::Filter
    # for details...
    my $name = $self->{_CONFIG}->{name}  # name from the template config
            || $self->{_ARGS}->[0]       # from the template argument
            || 'widont';                 # or use widont by default
    
    $self->install_filter($name);
    return $self;
}


=head2 filter

Overrides the method from L<Template::Plugin::Filter>.


=cut


sub filter {
    my ( $self, $text, $args, $config ) = @_;
    
    $config = $self->merge_config($config);
    
    # If we haven't already created a Text::Widont object, do so...
    $self->{tw} ||= Text::Widont->new( nbsp => $config->{nbsp} );
    
    # Return the transformed string...
    return $self->{tw}->widont($text);
}



1;  # End of the module code; everything from here is documentation...
__END__

=head1 SEE ALSO

L<Template>, L<Template::Plugin::Filter>, L<Text::Widont>


=head1 DEPENDENCIES

=over

=item *

L<Template::Plugin::Filter>

=item *

L<Text::Widont>

=back


=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-plugin-text-widont at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Text-Widont>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plugin::Text::Widont

You may also look for information at:

=over 4

=item * Template::Plugin::Text::Widont

L<http://perlprogrammer.co.uk/modules/Template::Plugin::Text::Widont/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Plugin-Text-Widont/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Text-Widont>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Plugin-Text-Widont/>

=back


=head1 AUTHOR

Dave Cardwell <dcardwell@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Dave Cardwell. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.


=cut

