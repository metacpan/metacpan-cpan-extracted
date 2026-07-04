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

package OpenSearch::Client::Serializer::JSON::PP;
$OpenSearch::Client::Serializer::JSON::PP::VERSION = '3.007002';
use Moo;
use JSON::PP;

has 'JSON' => ( is => 'ro', default => sub { JSON::PP->new->utf8(1) } );

with 'OpenSearch::Client::Role::Serializer::JSON';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Serializer::JSON::PP - A JSON Serializer using JSON::PP

=head1 VERSION

version 3.00700

=head1 SYNOPSIS

    $os = OpenSearch::Client->new(
        serializer => 'JSON::PP'
    );

=head1 DESCRIPTION

While the default serializer, L<OpenSearch::Client::Serializer::JSON>,
tries to choose the appropriate JSON backend, this module allows you to
choose the L<JSON::PP> backend specifically.

B<NOTE:> You should really install and use either L<JSON::XS> or
L<Cpanel::JSON::XS> as they are much much faster than L<JSON::PP>.

This class does L<OpenSearch::Client::Role::Serializer::JSON>.

=head1 SEE ALSO

=over

=item * L<OpenSearch::Client::Serializer::JSON>

=item * L<OpenSearch::Client::Serializer::JSON::XS>

=item * L<OpenSearch::Client::Serializer::JSON::Cpanel>

=back

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

