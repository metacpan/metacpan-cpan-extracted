# Copyright (c) 2015 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING); if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#
package Net::OBS::Client::Roles::BuildStatus;

use Moose::Role;
use Net::OBS::Client::DTD;
use XML::Structured;

requires 'code';

has project => (
  is      =>    'rw',
  isa     =>    'Str',
);

has package => (
  is      =>    'rw',
  isa     =>    'Str',
);

has dtd => (
  is      =>    'rw',
  isa     =>    'Object',
  lazy    =>    1,
  default => sub {
    Net::OBS::Client::DTD->new()
  },
);

has name => (
  is => 'ro',
  isa => 'Str',
);

1;
