# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

package Search::Elasticsearch::Role::Is_Sync;
$Search::Elasticsearch::Role::Is_Sync::VERSION = '7.30';
use Moo::Role;
use namespace::clean;

1;

# ABSTRACT: A role to mark classes which should be used with other sync classes

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Role::Is_Sync - A role to mark classes which should be used with other sync classes

=head1 VERSION

version 7.30

=head1 AUTHOR

Enrico Zimuel <enrico.zimuel@elastic.co>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
