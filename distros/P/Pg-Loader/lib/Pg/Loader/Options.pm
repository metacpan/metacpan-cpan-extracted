package Pg::Loader::Options;
# Copyright (C) 2011, Ioannis

use Getopt::Compact;
use warnings;
use 5.010000;
use base 'Exporter';
use strict;

our $VERSION = '0.1';

our @EXPORT = qw( get_options );


sub get_options {
	new Getopt::Compact
	         args   => '[section]...',
                 modes  => [qw(quiet debug verbose )],
                 struct =>  [ [ [qw(c config)],  'config file',   '=s'        ],
                            [ [qw(t relation)],'schema.table' , '=s'          ],
                            [ [qw(l loglevel)],'loglevel',      '=i'          ],
                            [ [qw(L Logfile)], 'Logfile',       '=s'          ],
                            [ [qw(s summary)], 'summary'                      ],
                            [ [qw(e every)],   'sets  copy_every=1'           ],
                            [ [qw(n dry_run)], 'dry_run'                      ],
                            [ [qw(D disable_triggers)],'disable triggers'     ],
                            [ [qw(T truncate)],'truncate table before loading'],
                            [ [qw(V vacuum)],  'vacuum analyze'               ],
                            [ [qw(C count)],   'num of lines to process','=s' ],
                            [ [qw(  version)],  'version'  , ],
                            [ [qw(F from)],    'process from this line number'],
                            [ [qw(i indexes)], 'disable indexes during COPY  '],
                            [ [qw(sample)],    'generate sample config file'  ],
                        ]
}

1;
__END__
=pod
