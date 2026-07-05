# OpenSearch::Client is an unofficial client for OpenSearch. 
# It is derived from Search::Elasticsearch version 7.714
# License details from the original work are contained in the
# NOTICE file distributed with this work.
#
#-----------------------------------------------------------------------
# OpenSearch::Client
#-----------------------------------------------------------------------
# Copyright 2026 Mark Dootson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

package OpenSearch::Client::Serializer::JSON;
$OpenSearch::Client::Serializer::JSON::VERSION = '3.007005';
use Moo;
use JSON::MaybeXS 1.002002 ();

has 'JSON' => ( is => 'ro', default => sub { JSON::MaybeXS->new->utf8(1) } );

with 'OpenSearch::Client::Role::Serializer::JSON';
use namespace::clean;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Serializer::JSON - The default JSON Serializer, using JSON::MaybeXS

=head1 VERSION

version 3.007005

=head1 SYNOPSIS

    $os = OpenSearch::Client->new(
        # serializer => 'JSON'
    );

=head1 DESCRIPTION

This default Serializer class chooses between:

=over

=item * L<Cpanel::JSON::XS>

=item * L<JSON::XS>

=item * L<JSON::PP>

=back

First it checks if either L<Cpanel::JSON::XS> or L<JSON::XS> is already
loaded and, if so, uses the appropriate backend.  Otherwise it tries
to load L<Cpanel::JSON::XS>, then L<JSON::XS> and finally L<JSON::PP>.

If you would prefer to specify a particular JSON backend, then you can
do so by using one of these modules:

=over

=item * L<OpenSearch::Client::Serializer::JSON::Cpanel>

=item * L<OpenSearch::Client::Serializer::JSON::XS>

=item * L<OpenSearch::Client::Serializer::JSON::PP>

=back

See their documentation for details.

=head1 MANUAL

Documentation index L<OpenSearch::Client::Manual>

=head1 HISTORY

This distribution is derived from L<Search::Elasticsearch> version 7.714.
All subsequent changes are unique to this distribution.

=head1 AUTHOR

Mark Dootson E<lt>mdootson@cpan.orgE<gt> ( current maintainer )

=head1 CREDITS

L<OpenSearch::Client> is based on L<Search::Elasticsearch> version 7.714
by Enrico Zimuel E<lt>enrico.zimuel@elastic.coE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Mark Dootson ( this distribution )

Copyright (C) 2021 by Elasticsearch BV ( original distribution ) 

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004


=cut

