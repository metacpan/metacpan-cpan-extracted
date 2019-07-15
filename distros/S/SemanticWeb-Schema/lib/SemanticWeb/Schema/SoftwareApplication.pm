use utf8;

package SemanticWeb::Schema::SoftwareApplication;

# ABSTRACT: A software application.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'SoftwareApplication';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has application_category => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'applicationCategory',
);



has application_sub_category => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'applicationSubCategory',
);



has application_suite => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'applicationSuite',
);



has available_on_device => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availableOnDevice',
);



has countries_not_supported => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'countriesNotSupported',
);



has countries_supported => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'countriesSupported',
);



has device => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'device',
);



has download_url => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'downloadUrl',
);



has feature_list => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'featureList',
);



has file_size => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'fileSize',
);



has install_url => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'installUrl',
);



has memory_requirements => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'memoryRequirements',
);



has operating_system => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'operatingSystem',
);



has permissions => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'permissions',
);



has processor_requirements => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'processorRequirements',
);



has release_notes => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'releaseNotes',
);



has requirements => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'requirements',
);



has screenshot => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'screenshot',
);



has software_add_on => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'softwareAddOn',
);



has software_help => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'softwareHelp',
);



has software_requirements => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'softwareRequirements',
);



has software_version => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'softwareVersion',
);



has storage_requirements => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'storageRequirements',
);



has supporting_data => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'supportingData',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::SoftwareApplication - A software application.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A software application.

=head1 ATTRIBUTES

=head2 C<application_category>

C<applicationCategory>

Type of software application, e.g. 'Game, Multimedia'.

A application_category should be one of the following types:

=over

=item C<Str>

=back

=head2 C<application_sub_category>

C<applicationSubCategory>

Subcategory of the application, e.g. 'Arcade Game'.

A application_sub_category should be one of the following types:

=over

=item C<Str>

=back

=head2 C<application_suite>

C<applicationSuite>

The name of the application suite to which the application belongs (e.g.
Excel belongs to Office).

A application_suite should be one of the following types:

=over

=item C<Str>

=back

=head2 C<available_on_device>

C<availableOnDevice>

Device required to run the application. Used in cases where a specific
make/model is required to run the application.

A available_on_device should be one of the following types:

=over

=item C<Str>

=back

=head2 C<countries_not_supported>

C<countriesNotSupported>

Countries for which the application is not supported. You can also provide
the two-letter ISO 3166-1 alpha-2 country code.

A countries_not_supported should be one of the following types:

=over

=item C<Str>

=back

=head2 C<countries_supported>

C<countriesSupported>

Countries for which the application is supported. You can also provide the
two-letter ISO 3166-1 alpha-2 country code.

A countries_supported should be one of the following types:

=over

=item C<Str>

=back

=head2 C<device>

Device required to run the application. Used in cases where a specific
make/model is required to run the application.

A device should be one of the following types:

=over

=item C<Str>

=back

=head2 C<download_url>

C<downloadUrl>

If the file can be downloaded, URL to download the binary.

A download_url should be one of the following types:

=over

=item C<Str>

=back

=head2 C<feature_list>

C<featureList>

Features or modules provided by this application (and possibly required by
other applications).

A feature_list should be one of the following types:

=over

=item C<Str>

=back

=head2 C<file_size>

C<fileSize>

Size of the application / package (e.g. 18MB). In the absence of a unit
(MB, KB etc.), KB will be assumed.

A file_size should be one of the following types:

=over

=item C<Str>

=back

=head2 C<install_url>

C<installUrl>

URL at which the app may be installed, if different from the URL of the
item.

A install_url should be one of the following types:

=over

=item C<Str>

=back

=head2 C<memory_requirements>

C<memoryRequirements>

Minimum memory requirements.

A memory_requirements should be one of the following types:

=over

=item C<Str>

=back

=head2 C<operating_system>

C<operatingSystem>

Operating systems supported (Windows 7, OSX 10.6, Android 1.6).

A operating_system should be one of the following types:

=over

=item C<Str>

=back

=head2 C<permissions>

Permission(s) required to run the app (for example, a mobile app may
require full internet access or may run only on wifi).

A permissions should be one of the following types:

=over

=item C<Str>

=back

=head2 C<processor_requirements>

C<processorRequirements>

Processor architecture required to run the application (e.g. IA64).

A processor_requirements should be one of the following types:

=over

=item C<Str>

=back

=head2 C<release_notes>

C<releaseNotes>

Description of what changed in this version.

A release_notes should be one of the following types:

=over

=item C<Str>

=back

=head2 C<requirements>

Component dependency requirements for application. This includes runtime
environments and shared libraries that are not included in the application
distribution package, but required to run the application (Examples:
DirectX, Java or .NET runtime).

A requirements should be one of the following types:

=over

=item C<Str>

=back

=head2 C<screenshot>

A link to a screenshot image of the app.

A screenshot should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ImageObject']>

=item C<Str>

=back

=head2 C<software_add_on>

C<softwareAddOn>

Additional content for a software application.

A software_add_on should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::SoftwareApplication']>

=back

=head2 C<software_help>

C<softwareHelp>

Software application help.

A software_help should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

=head2 C<software_requirements>

C<softwareRequirements>

Component dependency requirements for application. This includes runtime
environments and shared libraries that are not included in the application
distribution package, but required to run the application (Examples:
DirectX, Java or .NET runtime).

A software_requirements should be one of the following types:

=over

=item C<Str>

=back

=head2 C<software_version>

C<softwareVersion>

Version of the software instance.

A software_version should be one of the following types:

=over

=item C<Str>

=back

=head2 C<storage_requirements>

C<storageRequirements>

Storage requirements (free space required).

A storage_requirements should be one of the following types:

=over

=item C<Str>

=back

=head2 C<supporting_data>

C<supportingData>

Supporting data for a SoftwareApplication.

A supporting_data should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DataFeed']>

=back

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
