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
package Net::OBS::Client::DTD;

use Moose;

has buildstatus =>(
  is  => 'rw',
  isa => 'ArrayRef',
  default => sub {
    return [
      'status' =>
      'package',
      'code',
      'status',   # obsolete, now code
      'error',    # obsolete, now details
      'versrel',  # for withversrel result call
      [],
      'details',

      'workerid', # last build data
      'hostarch',
      'readytime',
      'starttime',
      'endtime',

      'job',      # internal, job when building

      'uri',      # obsolete
      'arch',     # obsolete
    ];
  },
);


has binarylist => (
  is  => 'rw',
  isa => 'ArrayRef',
  default => sub {
    [
        'binarylist' =>
        'package',
         [[ 'binary' =>
            'filename',
            'md5',
            'size',
            'mtime',
         ]],
    ];
  },
);

has summary => (
  is  => 'rw',
  isa => 'ArrayRef',
  default => sub {
    [
        'summary' =>
            [[ 'statuscount' =>
               'code',
               'count',
            ]],
    ];
  },
);


has schedulerstats => (
  is  => 'rw',
  isa => 'ArrayRef',
  default => sub {
    [
        'stats' =>
            'lastchecked',
            'checktime',
            'lastfinished',
            'lastpublished',
    ];
  },
);

has result => (
  is  => 'rw',
  isa => 'ArrayRef',
  lazy => 1,
  default => sub {
    [
        'result' =>
            'project',
            'repository',
            'arch',
            'code', # pra state, can be "unknown", "broken", "scheduling", "blocked", "building", "finished", "publishing", "published" or "unpublished"
            'state', # old name of 'code', to be removed
            'details',
            'dirty', # marked for re-scheduling if element exists, state might not be correct anymore
              [ $_[0]->buildstatus ],
              [ $_[0]->binarylist ],
                $_[0]->summary,
            $_[0]->schedulerstats,
    ];
  },
);

has resultlist => (
  is  => 'rw',
  isa => 'ArrayRef',
  lazy => 1,
  default => sub {
    [
      'resultlist' =>
        'state',
        'retryafter',
          [ $_[0]->result ],
    ];
  },
);

has fileinfo => (
  is  => 'rw',
  isa => 'ArrayRef',
  lazy => 1,
  default => sub {
    [
        'fileinfo' =>
        'filename',
        [],
        'name',
            'epoch',
        'version',
        'release',
        'arch',
        'source',
        'summary',
        'description',
        'size',
        'mtime',
          [ 'provides' ],
          [ 'requires' ],
          [ 'prerequires' ],
          [ 'conflicts' ],
          [ 'obsoletes' ],
          [ 'recommends' ],
          [ 'supplements' ],
          [ 'suggests' ],
          [ 'enhances' ],

         [[ 'provides_ext' =>
            'dep',
         [[ 'requiredby' =>
            'name',
            'epoch',
            'version',
            'release',
            'arch',
            'project',
            'repository',
         ]],
         ]],
         [[ 'requires_ext' =>
            'dep',
         [[ 'providedby' =>
            'name',
            'epoch',
            'version',
            'release',
            'arch',
            'project',
            'repository',
         ]],
         ]],
    ];
  },
);

__PACKAGE__->meta->make_immutable();


1;
