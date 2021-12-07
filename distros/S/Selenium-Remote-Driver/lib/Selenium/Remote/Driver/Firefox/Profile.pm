package Selenium::Remote::Driver::Firefox::Profile;
$Selenium::Remote::Driver::Firefox::Profile::VERSION = '1.46';
# ABSTRACT: Use custom profiles with Selenium::Remote::Driver
use strict;
use warnings;

use Selenium::Firefox::Profile;

BEGIN {
    push our @ISA, 'Selenium::Firefox::Profile';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Remote::Driver::Firefox::Profile - Use custom profiles with Selenium::Remote::Driver

=head1 VERSION

version 1.46

=head1 DESCRIPTION

We've renamed this class to the slightly less wordy
L<Selenium::Firefox::Profile>. This is only around as an alias to
hopefully prevent old code from breaking.

=head1 SEE ALSO

Selenium::Firefox::Profile
http://kb.mozillazine.org/About:config_entries
https://developer.mozilla.org/en-US/docs/Mozilla/Preferences/A_brief_guide_to_Mozilla_preferences

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

Previous maintainers:

=over 4

=item *

Daniel Gempesaw <gempesaw@gmail.com>

=item *

Emmanuel Peroumalnaïk <peroumalnaik.emmanuel@gmail.com>

=item *

Luke Closs <cpan@5thplane.com>

=item *

Mark Stosberg <mark@stosberg.com>

=back

Original authors:

=over 4

=item *

Aditya Ivaturi <ivaturi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010-2011 Aditya Ivaturi, Gordon Child

Copyright (c) 2014-2017 Daniel Gempesaw

Copyright (c) 2018-2021 George S. Baugh

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
