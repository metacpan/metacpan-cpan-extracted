package Pod::Weaver::Section::Template;
BEGIN {
  $Pod::Weaver::Section::Template::AUTHORITY = 'cpan:DOY';
}
{
  $Pod::Weaver::Section::Template::VERSION = '0.04';
}
use Moose;
# ABSTRACT: add pod section from a Text::Template template

with 'Pod::Weaver::Role::Section';

use Text::Template 'fill_in_file';


use Moose::Util::TypeConstraints;

subtype 'PWST::File',
    as 'Str',
    where { !m+^~/+ && -r },
    message { "Couldn't read file $_" };
coerce 'PWST::File',
    from 'Str',
    via { s+^~/+$ENV{HOME}/+; $_ };

no Moose::Util::TypeConstraints;


has template => (
    is       => 'ro',
    isa      => 'PWST::File',
    required => 1,
    coerce   => 1,
);


has header => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { shift->plugin_name },
);


has main_module_only => (
    is  => 'ro',
    isa => 'Bool',
);

has delim => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { ['{{', '}}'] },
);

has extra_args => (
    is  => 'rw',
    isa => 'HashRef',
);

sub BUILD {
    my $self = shift;
    my ($args) = @_;
    my $copy = {%$args};
    delete $copy->{$_}
        for map { $_->init_arg } $self->meta->get_all_attributes;
    $self->extra_args($copy);
}

sub _main_module_name {
    my $self = shift;
    my ($zilla) = @_;
    return unless $zilla;

    my $main_module_name = $zilla->main_module->name;
    my $root = $zilla->root->stringify;
    $main_module_name =~ s:^\Q$root::;
    $main_module_name =~ s:lib/::;
    $main_module_name =~ s+/+::+g;
    $main_module_name =~ s/\.pm//;

    return $main_module_name;
}

sub _parse_pod {
    my $self = shift;
    my ($pod) = @_;

    # ensure it's a valid pod document
    $pod = "=pod\n\n$pod\n";

    my $children = Pod::Elemental->read_string($pod)->children;

    # but strip off the bits we had to add
    shift @$children
        while $children->[0]->isa('Pod::Elemental::Element::Generic::Blank')
           || ($children->[0]->isa('Pod::Elemental::Element::Generic::Command')
            && $children->[0]->command eq 'pod');
    my $blank;
    $blank = pop @$children
        while $children->[-1]->isa('Pod::Elemental::Element::Generic::Blank');
    push @$children, $blank
        if $blank;

    return $children;
}

sub _get_zilla_hash {
    my $self = shift;
    my ($zilla) = @_;
    my %zilla_hash;
    for my $attr ($zilla->meta->get_all_attributes) {
        next if $attr->get_read_method =~ /^_/;
        my $value = $attr->get_value($zilla);
        $zilla_hash{$attr->name} = blessed($value) ? \$value : $value;
    }
    $zilla_hash{main_module_name} = $self->_main_module_name($zilla);
    return %zilla_hash;
}

sub _template_error
{
  my ($self, %e) = @_;

  # Put the template's filename into the error message:
  $e{error} =~ s/(?<= at )template(?= line \d)/ $self->template /eg;

  $self->log_fatal($e{error});
}

sub weave_section {
    my $self = shift;
    my ($document, $input) = @_;

    my $zilla = $input->{zilla};

    if ($self->main_module_only) {
        return if $zilla && $zilla->main_module->name ne $input->{filename};
    }

    die "Couldn't find file " . $self->template
        unless -r $self->template;
    my $pod = fill_in_file(
        $self->template,
        BROKEN     => sub { $self->_template_error(@_) },
        DELIMITERS => $self->delim,
        HASH       => {
            $zilla ? ($self->_get_zilla_hash($zilla)) : (),
            filename => $input->{filename},
            plugin   => \$self,
            %{ $self->extra_args },
        },
    );

    push @{ $document->children },
        Pod::Elemental::Element::Nested->new(
            command  => 'head1',
            content  => $self->header,
            children => $self->_parse_pod($pod),
        );
}

__PACKAGE__->meta->make_immutable;
no Moose;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Template - add pod section from a Text::Template template

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  # weaver.ini
  [Template / SUPPORT]
  template = ~/.dzil/pod_templates/support.section
  main_module_only = 1

=head1 DESCRIPTION

This plugin generates a pod section based on the contents of a template file.
The template is parsed using L<Text::Template>, and is then interpreted as pod.
When parsing the template, C<$filename> will be the name of the file being
woven (if that was passed to L<Pod::Weaver>), and C<$plugin> will be this
plugin. Any options specified in the plugin configuration
which aren't configuration options for this plugin will be provided as
variables for the template. Also, if this is being run as part of a
L<Dist::Zilla> build process, the values of all of the attributes on the
C<zilla> object will be available as variables, and the additional variable
C<$main_module_name> will be defined as the module name for the C<main_module>
file.

=head1 ATTRIBUTES

=head2 template

The file to be run through Text::Template and added as a pod section. Required.

=head2 header

The section header. Defaults to the plugin name.

=head2 main_module_only

If L<Pod::Weaver> is being run through L<Dist::Zilla>, this option determines
whether to add the section to each module in the distribution, or to just the
distribution's main module. Defaults to false.

=head1 SEE ALSO

L<Text::Template>
L<Pod::Weaver>
L<Dist::Zilla>

=for Pod::Coverage   BUILD
  weave_section

=head1 AUTHORS

=over 4

=item *

Jesse Luehrs <doy at tozt dot net>

=item *

Christopher J. Madsen <perl at cjmweb dot net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
