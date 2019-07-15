use utf8;

package SemanticWeb::Schema::LiveBlogPosting;

# ABSTRACT: A blog post intended to provide a rolling textual coverage of an ongoing event through continuous updates.

use Moo;

extends qw/ SemanticWeb::Schema::BlogPosting /;


use MooX::JSON_LD 'LiveBlogPosting';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has coverage_end_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'coverageEndTime',
);



has coverage_start_time => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'coverageStartTime',
);



has live_blog_update => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'liveBlogUpdate',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::LiveBlogPosting - A blog post intended to provide a rolling textual coverage of an ongoing event through continuous updates.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A blog post intended to provide a rolling textual coverage of an ongoing
event through continuous updates.

=head1 ATTRIBUTES

=head2 C<coverage_end_time>

C<coverageEndTime>

The time when the live blog will stop covering the Event. Note that
coverage may continue after the Event concludes.

A coverage_end_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<coverage_start_time>

C<coverageStartTime>

The time when the live blog will begin covering the Event. Note that
coverage may begin before the Event's start time. The LiveBlogPosting may
also be created before coverage begins.

A coverage_start_time should be one of the following types:

=over

=item C<Str>

=back

=head2 C<live_blog_update>

C<liveBlogUpdate>

An update to the LiveBlog.

A live_blog_update should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BlogPosting']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::BlogPosting>

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
