package Search::Elasticsearch::Client::6_0::Direct::XPack::Rollup;
$Search::Elasticsearch::Client::6_0::Direct::XPack::Rollup::VERSION = '6.81';
use Moo;
with 'Search::Elasticsearch::Client::6_0::Role::API';
with 'Search::Elasticsearch::Role::Client::Direct';
use namespace::clean;

__PACKAGE__->_install_api('xpack.rollup');

1;

# ABSTRACT: Plugin providing Rollups for Search::Elasticsearch 6.x

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Client::6_0::Direct::XPack::Rollup - Plugin providing Rollups for Search::Elasticsearch 6.x

=head1 VERSION

version 6.81

=head1 SYNOPSIS

    my $response = $es->xpack->rollup->search( body => {...} )

=head2 DESCRIPTION

This class extends the L<Search::Elasticsearch> client with a C<rollup>
namespace, to support the
L<Rollup APIs|https://www.elastic.co/guide/en/elasticsearch/reference/current/rollup-apis.html>.

The full documentation for the Rollups feature is available here:
L<https://www.elastic.co/guide/en/elasticsearch/reference/current/xpack-rollup.html>

=head1 GENERAL METHODS

=head2 C<search()>

    $response = $es->xpack->rollup->search(
        index   => $index | \@indices,      # optional
        body    => {...}                    # optional
    )

The C<search()> method executes a normal search but can join the results from ordinary indices with
those from rolled up indices.

Query string parameters:
    C<error_trace>,
    C<filter_path>,
    C<human>,
    C<typed_keys>

See the L<rollup search docs|https://www.elastic.co/guide/en/elasticsearch/reference/current/rollup-search.html>
for more information.

=head1 JOB METHODS

=head2 C<put_job()>

    $response = $es->xpack->rollup->put_job(
        id      => $id,                     # required
        body    => {...}                    # optional
    )

The C<put_job()> method creates a rollup job which will rollup matching indices to a rolled up index
in the background.

Query string parameters:
    C<error_trace>,
    C<filter_path>,
    C<human>

See the L<rollup create job docs|https://www.elastic.co/guide/en/elasticsearch/reference/current/rollup-put-job.html>
for more information.

=head2 C<delete_job()>

    $response = $es->xpack->rollup->delete_job(
        id      => $id,                     # required
    )

The C<delete_job()> method deletes a rollup job by ID.

Query string parameters:
    C<error_trace>,
    C<filter_path>,
    C<human>

See the L<rollup delete job docs|https://www.elastic.co/guide/en/elasticsearch/reference/current/rollup-delete-job.html>
for more information.

=head2 C<get_jobs()>

    $response = $es->xpack->rollup->get_jobs(
        id      => $id,     # optional
    )

The C<get_job()> method retrieves a rollup job by ID, or all jobs if not specified.

Query string parameters:
    C<error_trace>,
    C<filter_path>,
    C<human>

See the L<rollup get jobs docs|https://www.elastic.co/guide/en/elasticsearch/reference/current/rollup-get-job.html>
for more information.

=head2 C<start_job()>

    $response = $es->xpack->rollup->start_job(
        id      => $id,     # required
    )

The C<start_job()> method starts the specified rollup job.

Query string parameters:
    C<error_trace>,
    C<filter_path>,
    C<human>

See the L<rollup start job docs|https://www.elastic.co/guide/en/elasticsearch/reference/current/rollup-start-job.html>
for more information.

=head2 C<stop_job()>

    $response = $es->xpack->rollup->stop_job(
        id      => $id,     # required
    )

The C<stop_job()> method stops the specified rollup job.

Query string parameters:
    C<error_trace>,
    C<filter_path>,
    C<human>

See the L<rollup stop job docs|https://www.elastic.co/guide/en/elasticsearch/reference/current/rollup-stop-job.html>
for more information.

=head1 DATA METHODS

=head2 C<get_rollup_caps()>

    $response = $es->xpack->rollup->get_rollup_caps(
        id => $index    # optional
    )

The C<get_rollup_caps()> method returns the capabilities of any rollup jobs that have been configured for a specific index or index pattern.

Query string parameters:
    C<error_trace>,
    C<filter_path>,
    C<human>

See the L<get rollup caps docs|https://www.elastic.co/guide/en/elasticsearch/reference/current/rollup-get-rollup-caps.html>
for more information.

=head2 C<get_rollup_index_caps()>

    $response = $es->xpack->rollup->get_rollup_index_caps(
        id => $index    # optional
    )

The C<get_rollup_index_caps()> method returns the rollup capabilities of all jobs inside of a rollup index.

Query string parameters:
    C<error_trace>,
    C<filter_path>,
    C<human>

See the L<get rollup index caps docs|https://www.elastic.co/guide/en/elasticsearch/reference/current/rollup-get-rollup-index-caps.html>
for more information.

=head1 AUTHOR

Enrico Zimuel <enrico.zimuel@elastic.co>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
