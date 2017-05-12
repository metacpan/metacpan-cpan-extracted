use 5.008;
use strict;
use warnings;

package Template::Plugin::Filter::Pipe;
our $VERSION = '1.100860';
# ABSTRACT: Filter plugin adapter for Text::Pipe
use Text::Pipe;
use parent qw(Template::Plugin::Filter);

sub init {
    my $self = shift;
    $self->{_DYNAMIC} = 1;
    $self->install_filter($self->{_ARGS}[0] || 'pipe');
    $self;
}

sub filter {
    my ($self, $text, $args, $config) = @_;
    die "pipe name?\n" unless defined $args->[0];
    my $pipe = Text::Pipe->new($args->[0], %$config);
    $pipe->filter($text);
}
1;


__END__
=pod

=for test_synopsis 1;
__END__

=head1 NAME

Template::Plugin::Filter::Pipe - Filter plugin adapter for Text::Pipe

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

    [%- USE Filter.Pipe -%]
    [%- 'a test' | pipe("Uppercase") |
        pipe("Repeat", times => 2, join => " = ") |
        pipe("Reverse") -%]
    EOTMPL

=head1 DESCRIPTION

This Template Toolkit filter plugin is an adapter for L<Text::Pipe>. The
default filter name is C<pipe>, but you can override this with the C<USE>
directive.

When using the filter, you need to pass the name of the pipe segment you would
like to create, and optionally named arguments to be passed to the pipe.

See L<Text::Pipe> and its derived distributions for more detail on which pipe
segments are available and which arguments they take.

=head1 METHODS

=head2 init

Overridden method - see L<Template::Plugin::Filter> for details.

=head2 filter

Overridden method - see L<Template::Plugin::Filter> for details.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Template-Plugin-Filter-Pipe>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Template-Plugin-Filter-Pipe/>.

The development version lives at
L<http://github.com/hanekomu/Template-Plugin-Filter-Pipe/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

