use utf8;

package SemanticWeb::Schema::APIReference;

# ABSTRACT: Reference documentation for application programming interfaces (APIs).

use Moo;

extends qw/ SemanticWeb::Schema::TechArticle /;


use MooX::JSON_LD 'APIReference';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has assembly => (
    is        => 'rw',
    predicate => '_has_assembly',
    json_ld   => 'assembly',
);



has assembly_version => (
    is        => 'rw',
    predicate => '_has_assembly_version',
    json_ld   => 'assemblyVersion',
);



has executable_library_name => (
    is        => 'rw',
    predicate => '_has_executable_library_name',
    json_ld   => 'executableLibraryName',
);



has programming_model => (
    is        => 'rw',
    predicate => '_has_programming_model',
    json_ld   => 'programmingModel',
);



has target_platform => (
    is        => 'rw',
    predicate => '_has_target_platform',
    json_ld   => 'targetPlatform',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::APIReference - Reference documentation for application programming interfaces (APIs).

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

Reference documentation for application programming interfaces (APIs).

=head1 ATTRIBUTES

=head2 C<assembly>

Library file name e.g., mscorlib.dll, system.web.dll.

A assembly should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_assembly>

A predicate for the L</assembly> attribute.

=head2 C<assembly_version>

C<assemblyVersion>

Associated product/technology version. e.g., .NET Framework 4.5.

A assembly_version should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_assembly_version>

A predicate for the L</assembly_version> attribute.

=head2 C<executable_library_name>

C<executableLibraryName>

Library file name e.g., mscorlib.dll, system.web.dll.

A executable_library_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_executable_library_name>

A predicate for the L</executable_library_name> attribute.

=head2 C<programming_model>

C<programmingModel>

Indicates whether API is managed or unmanaged.

A programming_model should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_programming_model>

A predicate for the L</programming_model> attribute.

=head2 C<target_platform>

C<targetPlatform>

Type of app development: phone, Metro style, desktop, XBox, etc.

A target_platform should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_target_platform>

A predicate for the L</target_platform> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::TechArticle>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
