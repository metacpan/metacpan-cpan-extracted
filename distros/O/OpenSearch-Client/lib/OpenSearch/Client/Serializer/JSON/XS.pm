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

package OpenSearch::Client::Serializer::JSON::XS;
$OpenSearch::Client::Serializer::JSON::XS::VERSION = '3.007007';
use Moo;
use JSON::XS 2.26;

has 'JSON' => ( is => 'ro', default => sub { JSON::XS->new->utf8(1) } );

with 'OpenSearch::Client::Role::Serializer::JSON';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSearch::Client::Serializer::JSON::XS - A JSON Serializer using JSON::XS

=head1 VERSION

version 3.007007

=head1 SYNOPSIS

    $os = OpenSearch::Client->new(
        serializer => 'JSON::XS'
    );

=head1 DESCRIPTION

While the default serializer, L<OpenSearch::Client::Serializer::JSON>,
tries to choose the appropriate JSON backend, this module allows you to
choose the L<JSON::XS> backend specifically.

This class does L<OpenSearch::Client::Role::Serializer::JSON>.

=head1 SEE ALSO

=over

=item * L<OpenSearch::Client::Serializer::JSON>

=item * L<OpenSearch::Client::Serializer::JSON::Cpanel>

=item * L<OpenSearch::Client::Serializer::JSON::PP>

=back

=head1 AUTHOR

Mark Dootson ( also see the NOTICE file included with this distribution )

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Mark Dootson

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__

