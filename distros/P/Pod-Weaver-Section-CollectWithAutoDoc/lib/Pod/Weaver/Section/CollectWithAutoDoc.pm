use 5.008;
use strict;
use warnings;

package Pod::Weaver::Section::CollectWithAutoDoc;
BEGIN {
  $Pod::Weaver::Section::CollectWithAutoDoc::VERSION = '1.100980';
}

# ABSTRACT: Section to gather specific commands and add auto-generated documentation
use Moose;
extends 'Pod::Weaver::Section::Collect';
with 'Pod::Weaver::Role::Preparer';
use Moose::Autobox;
use Sub::Documentation ':all';
use Pod::Elemental::Element::Pod5::Command;
use Pod::Elemental::Element::Pod5::Ordinary;
use Pod::Elemental::Element::Pod5::Verbatim;

sub prepare_input {
    my ($self, $input) = @_;

    # Load the module file so it can auto-generated documentation
    my $file = $input->{filename};
    return unless defined $file;
    (my $inc_key = $file) =~ s!^lib/!!;
    if ($INC{$inc_key}) {
        $self->log("$file appears to have been already loaded, skipping");
        return;
    }
    unless (my $return = do $file) {
        $self->log("couldn't parse $file: $@") if $@;
        $self->log("couldn't do $file: $!") unless defined $return;
        $self->log("couldn't run $file") unless $return;
    }

    # Some modules define a UNIVERSAL::AUTOLOAD, this can be unwelcome for our
    # circumstances, so we shoot it. :)
    undef *UNIVERSAL::AUTOLOAD;
}

sub get_package_name {
    my ($self, $input) = @_;
    return unless my $ppi_document = $input->{ppi_document};
    my $pkg_node = $ppi_document->find_first('PPI::Statement::Package');
    my $filename = $input->{filename} || 'file';
    Carp::croak sprintf "couldn't find package declaration in %s", $filename
      unless $pkg_node;
    $pkg_node->namespace;
}

sub pod_ordinary {
    my ($self, $content) = @_;
    Pod::Elemental::Element::Pod5::Ordinary->new(content => $content,);
}

sub pod_verbatim {
    my ($self, $content) = @_;
    Pod::Elemental::Element::Pod5::Verbatim->new(content => $content,);
}

sub pod_command {
    my ($self, $command, $content) = @_;
    Pod::Elemental::Element::Pod5::Command->new(
        content => $content,
        command => $command,
      ),
      ;
}

sub add_examples {
    my ($self, %args) = @_;
    my @examples = search_documentation(
        glob_type => 'CODE',
        type      => 'examples',
        %args,
    );
    if (@examples) {
        my @count = map { @{ $_->{documentation} } } @examples;
        $_->children->push(
            $self->pod_ordinary(
                @count == 1
                ? 'Example:'
                : 'Examples:'
            )
        );
        for my $example_doc (@examples) {
            for my $example (@{ $example_doc->{documentation} }) {
                $_->children->push($self->pod_verbatim("  $example"));
            }
        }
    }
}
override weave_section => sub {
    my ($self, $document, $input) = @_;
    my $package = $self->get_package_name($input);
    if ($self->__used_container) {
        $self->__used_container->children->each_value(
            sub {
                my @main_purposes = search_documentation(
                    package   => $package,
                    glob_type => 'CODE',
                    type      => 'purpose',
                    name      => $_->{content},
                );
                if (@main_purposes) {
                    for my $main_purpose (@main_purposes) {
                        $_->children->push(
                            $self->pod_ordinary($main_purpose->{documentation})
                        );
                        $self->add_examples(
                            package => $package,
                            name    => $_->{content},
                        );
                    }
                }
                my @helper_purposes = search_documentation(
                    package    => $package,
                    glob_type  => 'CODE',
                    type       => 'purpose',
                    belongs_to => $_->{content}
                );
                if (@helper_purposes) {
                    $_->children->push(
                        $self->pod_ordinary(
'There are also the following helper methods for this accessor:',
                        )
                    );
                    $_->children->push($self->pod_command(over => 4));
                    for my $helper_purpose (@helper_purposes) {
                        for my $name (@{ $helper_purpose->{name} }) {
                            $_->children->push(
                                $self->pod_command(item => "C<$name>"));
                        }
                        $_->children->push(
                            $self->pod_ordinary(
                                $helper_purpose->{documentation}
                            )
                        );
                        $self->add_examples(
                            package    => $package,
                            name       => $helper_purpose->{name}[0],
                            belongs_to => $_->{content},
                        );
                    }
                    $_->children->push($self->pod_command(back => ''));
                }
            }
        );
    }
    super;
};
__PACKAGE__->meta->make_immutable;
no Moose;
1;


__END__
=pod

=head1 NAME

Pod::Weaver::Section::CollectWithAutoDoc - Section to gather specific commands and add auto-generated documentation

=head1 VERSION

version 1.100980

=head1 SYNOPSIS

In C<weaver.ini>:

    [CollectWithAutoDoc / METHODS]
    command = method

=head1 OVERVIEW

Given the configuration from the synopsis, this plugin will start off by
gathering and nesting any C<=method> commands found in the document. Those
commands, along with their nestable content, will be collected under a
C<=head1 METHODS> header and placed in the correct location in the output
stream. Their order will be preserved as it was in the source document.

Additionally, this plugin can add auto-generated method documentation
collected via L<Sub::Documentation>. L<Class::Accessor::Installer> supports
L<Sub::Documentation>, and L<Class::Accessor::Complex>, for example, uses
L<Class::Accessor::Installer>.

This auto-documentation is expected to be generated at run-time, when the
module is loaded. So this plugin loads the module that is being documented,
inspects the generated documentation, and adds them to the appropriate
C<=method> elements.

This plugin subclasses L<Pod::Weaver::Section::Collect>.

=head1 METHODS

=head2 add_examples

FIXME

=head2 get_package_name

FIXME

=head2 pod_command

FIXME

=head2 pod_ordinary

FIXME

=head2 pod_verbatim

FIXME

=head2 prepare_input

FIXME

=head1 FUNCTIONS

=head2 transform_document

Traverses the document and adds the auto-generated method documentation to the
appropriate C<=method> nodes.

=for test_synopsis 1;
__END__

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Section-CollectWithAutoDoc>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Pod-Weaver-Section-CollectWithAutoDoc/>.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

