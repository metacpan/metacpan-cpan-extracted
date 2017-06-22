package Test::DB::Shared;
$Test::DB::Shared::VERSION = '0.004';
use strict;
use warnings;

# ABSTRACT: Share DB cluster instance accross processes for faster tests

=head1 NAME

Test::DB::Shared - Umbrella package for shared test databases instances

=head1 SYNOPSIS

See L<Test::DB::Shared::mysqld> for MySQL.

=head1 AUTHOR

Current author: Jerome Eteve ( JETEVE )

=head1 COPYRIGHT

Copyright 2017 Jerome Eteve. All rights Reserved.

=head1 SEE ALSO

L<Test::mysqld> L<App::Prove::Plugin::MySQLPool>

=head1 ACKNOWLEDGEMENTS

This package as been released with the support of L<http://broadbean.com>

=head1 LICENSE

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
