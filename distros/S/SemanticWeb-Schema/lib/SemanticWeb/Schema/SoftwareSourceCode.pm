use utf8;

package SemanticWeb::Schema::SoftwareSourceCode;

# ABSTRACT: Computer programming source code

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'SoftwareSourceCode';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has code_repository => (
    is        => 'rw',
    predicate => '_has_code_repository',
    json_ld   => 'codeRepository',
);



has code_sample_type => (
    is        => 'rw',
    predicate => '_has_code_sample_type',
    json_ld   => 'codeSampleType',
);



has programming_language => (
    is        => 'rw',
    predicate => '_has_programming_language',
    json_ld   => 'programmingLanguage',
);



has runtime => (
    is        => 'rw',
    predicate => '_has_runtime',
    json_ld   => 'runtime',
);



has runtime_platform => (
    is        => 'rw',
    predicate => '_has_runtime_platform',
    json_ld   => 'runtimePlatform',
);



has sample_type => (
    is        => 'rw',
    predicate => '_has_sample_type',
    json_ld   => 'sampleType',
);



has target_product => (
    is        => 'rw',
    predicate => '_has_target_product',
    json_ld   => 'targetProduct',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::SoftwareSourceCode - Computer programming source code

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

Computer programming source code. Example: Full (compile ready) solutions,
code snippet samples, scripts, templates.

=head1 ATTRIBUTES

=head2 C<code_repository>

C<codeRepository>

Link to the repository where the un-compiled, human readable code and
related code is located (SVN, github, CodePlex).

A code_repository should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_code_repository>

A predicate for the L</code_repository> attribute.

=head2 C<code_sample_type>

C<codeSampleType>

What type of code sample: full (compile ready) solution, code snippet,
inline code, scripts, template.

A code_sample_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_code_sample_type>

A predicate for the L</code_sample_type> attribute.

=head2 C<programming_language>

C<programmingLanguage>

The computer programming language.

A programming_language should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ComputerLanguage']>

=item C<Str>

=back

=head2 C<_has_programming_language>

A predicate for the L</programming_language> attribute.

=head2 C<runtime>

Runtime platform or script interpreter dependencies (Example - Java v1,
Python2.3, .Net Framework 3.0).

A runtime should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_runtime>

A predicate for the L</runtime> attribute.

=head2 C<runtime_platform>

C<runtimePlatform>

Runtime platform or script interpreter dependencies (Example - Java v1,
Python2.3, .Net Framework 3.0).

A runtime_platform should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_runtime_platform>

A predicate for the L</runtime_platform> attribute.

=head2 C<sample_type>

C<sampleType>

What type of code sample: full (compile ready) solution, code snippet,
inline code, scripts, template.

A sample_type should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_sample_type>

A predicate for the L</sample_type> attribute.

=head2 C<target_product>

C<targetProduct>

Target Operating System / Product to which the code applies. If applies to
several versions, just the product name can be used.

A target_product should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SoftwareApplication']>

=back

=head2 C<_has_target_product>

A predicate for the L</target_product> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
