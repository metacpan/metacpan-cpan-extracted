#!/usr/bin/perl 
use Test::More;
#use Data::Dumper;
use SVN::Notify;
use Cwd;
use Config;
my $SECURE_PERL_PATH = $Config{perlpath};
if ($^O ne 'VMS') {
    $SECURE_PERL_PATH.= $Config{_exe}
	unless $SECURE_PERL_PATH =~ m/$Config{_exe}$/i;
}
my $PWD = getcwd;
my $USER = $ENV{USER};
my $SVNLOOK  = $ENV{SVNLOOK}  || SVN::Notify->find_exe('svnlook');
my $SVNADMIN = $ENV{SVNADMIN} || SVN::Notify->find_exe('svnadmin');

if ( !defined($SVNLOOK) ) {
    plan skip_all => "Cannot find svnlook!\n".
    "Please start the tests like this:\n".
    "  SVNLOOK=/path/to/svnlook make test";
}
elsif ( !defined($SVNADMIN) ) {
    plan skip_all => "Cannot find svnadmin!\n".
    "Please start the tests like this:\n".
    "  SVNADMIN=/path/to/svnadmin make test";
}
else {
    plan no_plan;
}

my $repos_path = "$PWD/t/test-repos";

my $wc_map = {
    'wc-trunk' =>
    	{
	    path => 'project1/trunk',
	    base_rev => 1,
	    command => 'update',
	},
    'wc-tag' =>
        {
	    path => 'project1/tags/TRUNK-1135534439',
	    base_rev => 3,
	    command => 'switch',
	    switch_rev => 7,
	    switch_path => 'project1/tags/TRUNK-1135538253',
	    tag_regex => 'TRUNK-',
	},
    'wc-branch' =>
    	{
	    path => 'project1/branches/branch1',
	    base_rev => 4,
	    command => 'update',
	},
};

my $wc_rsync_map;
foreach my $key ( keys %$wc_map ) {
    $wc_rsync_map->{$key.'-r'} = $wc_map->{$key};
}

my ($repos_history, $changes);
my $eval;
while (<DATA>) {
    $eval .= $_;
}
eval $eval;

my $maxrev = 7; # change this later to be the actual number of revs

sub reset_all_tests {
    create_test_repos();
    create_test_wcs();
    reset_test_wcs();
}

# Create a repository fill it with sample values the first time through
sub create_test_repos {
    unless ( -d $repos_path ) {
	system(<<"") == 0 or die "system failed: $?";
$SVNADMIN create $repos_path

	system(<<"") == 0 or die "system failed: $?";
$SVNADMIN load --quiet $repos_path < ${repos_path}.dump

    }
}

# Create test WC's before proceeding with tests the first time
sub create_test_wcs {
    unless ( -d "$PWD/t/wc-trunk" ) {
	foreach my $wc ( keys %{$wc_map} ) {
	    my $path = $wc_map->{$wc}->{'path'};
	    my $rev = $wc_map->{$wc}->{'base_rev'};

	    my $cmd = "svn checkout -q -r$rev ".
		"file://$repos_path/$path $PWD/t/$wc";
	    system($cmd) == 0 or die "system failed: $?";
	}
    }
}

# Reset the working copies
sub reset_test_wcs {
    foreach my $wc ( keys %{$wc_map} ) {
	my $path = $wc_map->{$wc}->{'path'};
	my $rev = $wc_map->{$wc}->{'base_rev'};
	my $command = $wc_map->{$wc}->{'command'};

	my $cmd = "svn $command -q -r$rev ";
	$cmd .= "file://$repos_path/$path " 
	   if ( $command =~ /switch/ ); # accomodate older svn's
	$cmd .= "$PWD/t/$wc";
	system($cmd) == 0 or die "system failed: $?";
    }
}

sub run_tests {
    my $command = shift;
    my $TESTER;
    my $rsync_test = 0;

    for (my $rev = 1; $rev <= $maxrev; $rev++) {
	foreach my $wc ( keys %{$wc_map} ) {
	    next unless $rev >= $wc_map->{$wc}->{'base_rev'};
	    my %args = @_;
	    # Common to all tests
	    $args{'repos-path'} = $repos_path;
	    $args{'handler'} = defined $args{'ssh-host'}
	                       ? 'Mirror::SSH'
			       : defined $args{'rsync-host'}
			       ? 'Mirror::Rsync'
			       : 'Mirror';


	    $args{'to'}       = "$PWD/t/$wc";
	    $args{'revision'} = $rev;

	    my $path = $wc_map->{$wc}->{'path'};
	    my $change = $changes->[$rev]->{$path} 
	    	if exists $changes->[$rev]->{$path};
	    next unless $change;
	    
	    # special case the switched directories
	    if ( $wc_map->{$wc}->{'command'} eq 'switch'
		&& $rev >= $wc_map->{$wc}->{'switch_rev'} ) {
		$path = $wc_map->{$wc}->{'switch_path'};
		$args{'tag-regex'} = $wc_map->{$wc}->{'tag_regex'};
	    }

	    # need to specify destination for rsync tests
	    if ( defined $args{'rsync-host'} ) {
		$rsync_test = 1;
		$args{'rsync-dest'} = "$PWD/t/$wc\-r";
	    }

	    _test(
		$change, 
		$path,
		$command, 
		%args
	    );
	}
	_compare_directories($rev, $wc_map);

	if ($rsync_test) {
	    _compare_directories($rev, $wc_rsync_map);
	    $rsync_test = 0;
	}
    }

}

sub _test {
    my ($expected, $prefix, $command, %args) = @_;
    my $test = {};

    open $TESTER, '-|', _build_command($command, %args);
    while (<$TESTER>) {
	chomp;
	next if ( /^Updating '.+':/ );
	if ( /^At revision (\d+)\./ ) {
	    ok ( $1 == $args{revision} , "No changes in $prefix at revision: "
	    	. $args{revision} );
	    last; # no need to read any more input
	}
	elsif ( /^Updated to revision (\d+)\./ ) {
	    ok ( $1 == $args{revision} , "Updated $prefix to correct revision: "
	    	. $args{revision} );
	}
	else {
	    my ($status, $target) = split;
	    $test->{$prefix.'/'.$target} = $status;
	}
    }
    close $TESTER;
    is_deeply(
    	$test,
	$expected, 
	"Correct files updated in $prefix at rev: " . $args{revision}
    ) if scalar(keys %$test) > 0;
}

sub _build_command {
    my ($command, %args) = @_;
    my @commandline = split " ", $command;

    if ( $command =~ /svnnotify/ ) {
	# hate to hardcode this, but what else can we do
	foreach my $key ( keys(%args) ) {
	    push @commandline, "\-\-$key", $args{$key};
	}
    }
    else {
	push @commandline, $args{'repos-path'}, $args{'revision'};
    }
    return @commandline;
}

sub _compare_directories {
    my ($rev, $wc_hash) = @_;
    my $history = $repos_history->[$rev];
    my $this_rev = {};

    foreach my $wc ( keys %$wc_hash ) {
	next unless $rev >= $wc_hash->{$wc}->{'base_rev'};
	my $subhistory = _expand_path($history, $wc_hash->{$wc}->{'path'});
	$this_rev = _scan_dir("t/$wc");
	is_deeply(
	    $subhistory,
	    $this_rev,
	    "Directories are consistent at rev: $rev"
	);
    }
}

sub _expand_path {
    my ($tree, $path) = @_;
    my @paths = split('/',$path);
    my $eval = "\$tree->{'".join("'}->{'", @paths)."'}";
    return eval $eval;
}

sub _scan_dir {
    my ($dir) = @_;
    my $fsize;
    my $this_rev = {};

    opendir my($DIR), $dir;
    my @directory = grep !/^\..*/, readdir $DIR;
    closedir $DIR;

    foreach my $file ( @directory ) {
	if ( -d "$dir/$file" ) {
	    $this_rev->{$file} = _scan_dir( "$dir/$file" );
	}
	elsif ( ( -f "$dir/$file" )  && ( my $size = -s "$dir/$file" ) ) {
	    $this_rev->{$file} = $size;
	}
    }
    return defined $this_rev ? $this_rev : {};
}

1; # magic return
__DATA__
$repos_history = [
  {},
  {
    'project2' => {
      'trunk' => {},
      'branches' => {},
      'tags' => {}
    },
    'project1' => {
      'trunk' => {},
      'branches' => {},
      'tags' => {}
    }
  },
  {
    'project2' => {
      'trunk' => {},
      'branches' => {},
      'tags' => {}
    },
    'project1' => {
      'trunk' => {
        'file1' => '6',
        'dir1' => {
          'file2' => '6'
        }
      },
      'branches' => {},
      'tags' => {}
    }
  },
  {
    'project2' => {
      'trunk' => {},
      'branches' => {},
      'tags' => {}
    },
    'project1' => {
      'trunk' => {
        'file1' => '6',
        'dir1' => {
          'file2' => '6'
        }
      },
      'branches' => {},
      'tags' => {
        'TRUNK-1135534439' => {
          'file1' => '6',
          'dir1' => {
            'file2' => '6'
          }
        }
      }
    }
  },
  {
    'project2' => {
      'trunk' => {},
      'branches' => {},
      'tags' => {}
    },
    'project1' => {
      'trunk' => {
        'file1' => '6',
        'dir1' => {
          'file2' => '6'
        }
      },
      'branches' => {
        'branch1' => {
          'file1' => '6',
          'dir1' => {
            'file2' => '6'
          }
        }
      },
      'tags' => {
        'TRUNK-1135534439' => {
          'file1' => '6',
          'dir1' => {
            'file2' => '6'
          }
        }
      }
    }
  },
  {
    'project2' => {
      'trunk' => {},
      'branches' => {},
      'tags' => {}
    },
    'project1' => {
      'trunk' => {
        'file1' => '6',
        'dir1' => {
          'file2' => '6'
        }
      },
      'branches' => {
        'branch1' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        }
      },
      'tags' => {
        'TRUNK-1135534439' => {
          'file1' => '6',
          'dir1' => {
            'file2' => '6'
          }
        }
      }
    }
  },
  {
    'project2' => {
      'trunk' => {},
      'branches' => {},
      'tags' => {}
    },
    'project1' => {
      'trunk' => {
        'file1' => '6',
        'file3' => '6',
        'dir2' => {
          'file4' => '6'
        },
        'dir1' => {
          'file2' => '6'
        }
      },
      'branches' => {
        'branch1' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        }
      },
      'tags' => {
        'TRUNK-1135534439' => {
          'file1' => '6',
          'dir1' => {
            'file2' => '6'
          }
        }
      }
    }
  },
  {
    'project2' => {
      'trunk' => {},
      'branches' => {},
      'tags' => {}
    },
    'project1' => {
      'trunk' => {
        'file1' => '6',
        'file3' => '6',
        'dir2' => {
          'file4' => '6'
        },
        'dir1' => {
          'file2' => '6'
        }
      },
      'branches' => {
        'branch1' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        }
      },
      'tags' => {
        'TRUNK-1135538253' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        },
        'TRUNK-1135534439' => {
          'file1' => '6',
          'dir1' => {
            'file2' => '6'
          }
        }
      }
    }
  },
  {
    'project2' => {
      'trunk' => {
        'dir3' => {
          'file6' => '6'
        },
        'file5' => '6',
        'dir4' => {
          'file7' => '6',
          'file8' => '6'
        }
      },
      'branches' => {},
      'tags' => {}
    },
    'project1' => {
      'trunk' => {
        'file1' => '6',
        'file3' => '6',
        'dir2' => {
          'file4' => '6'
        },
        'dir1' => {
          'file2' => '6'
        }
      },
      'branches' => {
        'branch1' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        }
      },
      'tags' => {
        'TRUNK-1135538253' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        },
        'TRUNK-1135534439' => {
          'file1' => '6',
          'dir1' => {
            'file2' => '6'
          }
        }
      }
    }
  },
  {
    'project2' => {
      'trunk' => {
        'dir3' => {
          'file6' => '6'
        },
        'file5' => '6',
        'dir4' => {
          'file7' => '6',
          'file8' => '6'
        }
      },
      'branches' => {},
      'tags' => {
        'TRUNK-1135538991' => {
          'dir3' => {
            'file6' => '6'
          },
          'file5' => '6',
          'dir4' => {
            'file7' => '6',
            'file8' => '6'
          }
        }
      }
    },
    'project1' => {
      'trunk' => {
        'file1' => '6',
        'file3' => '6',
        'dir2' => {
          'file4' => '6'
        },
        'dir1' => {
          'file2' => '6'
        }
      },
      'branches' => {
        'branch1' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        }
      },
      'tags' => {
        'TRUNK-1135538253' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        },
        'TRUNK-1135534439' => {
          'file1' => '6',
          'dir1' => {
            'file2' => '6'
          }
        }
      }
    }
  },
  {
    'project2' => {
      'trunk' => {
        'dir3' => {
          'file6' => '6'
        },
        'file5' => '6',
        'dir4' => {
          'file7' => '6',
          'file8' => '6'
        }
      },
      'branches' => {
        'branch2' => {
          'dir3' => {
            'file6' => '6'
          },
          'file5' => '6',
          'dir4' => {
            'file7' => '6',
            'file8' => '6'
          }
        }
      },
      'tags' => {
        'TRUNK-1135538991' => {
          'dir3' => {
            'file6' => '6'
          },
          'file5' => '6',
          'dir4' => {
            'file7' => '6',
            'file8' => '6'
          }
        }
      }
    },
    'project1' => {
      'trunk' => {
        'file1' => '6',
        'file3' => '6',
        'dir2' => {
          'file4' => '6'
        },
        'dir1' => {
          'file2' => '6'
        }
      },
      'branches' => {
        'branch1' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        }
      },
      'tags' => {
        'TRUNK-1135538253' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        },
        'TRUNK-1135534439' => {
          'file1' => '6',
          'dir1' => {
            'file2' => '6'
          }
        }
      }
    }
  },
  {
    'project2' => {
      'trunk' => {
        'dir3' => {
          'file6' => '6'
        },
        'file5' => '6',
        'dir4' => {
          'file7' => '6',
          'file8' => '6'
        }
      },
      'branches' => {
        'branch2' => {
          'file5.new' => '6',
          'dir5' => {
            'file6' => '6'
          },
          'dir4' => {
            'file7' => '6',
            'file8' => '6'
          }
        }
      },
      'tags' => {
        'TRUNK-1135538991' => {
          'dir3' => {
            'file6' => '6'
          },
          'file5' => '6',
          'dir4' => {
            'file7' => '6',
            'file8' => '6'
          }
        }
      }
    },
    'project1' => {
      'trunk' => {
        'file1' => '6',
        'file3' => '6',
        'dir2' => {
          'file4' => '6'
        },
        'dir1' => {
          'file2' => '6'
        }
      },
      'branches' => {
        'branch1' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        }
      },
      'tags' => {
        'TRUNK-1135538253' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        },
        'TRUNK-1135534439' => {
          'file1' => '6',
          'dir1' => {
            'file2' => '6'
          }
        }
      }
    }
  },
  {
    'project2' => {
      'trunk' => {
        'dir3' => {
          'file6' => '6'
        },
        'file5' => '6',
        'dir4' => {
          'file7' => '6',
          'file8' => '6'
        }
      },
      'branches' => {
        'branch2' => {
          'file5.new' => '6',
          'dir5' => {
            'file6' => '6'
          },
          'dir4' => {
            'file7' => '6',
            'file8' => '6'
          }
        }
      },
      'tags' => {
        'TRUNK-1135539568' => {
          'dir3' => {
            'file6' => '6'
          },
          'file5' => '6',
          'dir4' => {
            'file7' => '6',
            'file8' => '6'
          }
        },
        'TRUNK-1135538991' => {
          'dir3' => {
            'file6' => '6'
          },
          'file5' => '6',
          'dir4' => {
            'file7' => '6',
            'file8' => '6'
          }
        }
      }
    },
    'project1' => {
      'trunk' => {
        'file1' => '6',
        'file3' => '6',
        'dir2' => {
          'file4' => '6'
        },
        'dir1' => {
          'file2' => '6'
        }
      },
      'branches' => {
        'branch1' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        }
      },
      'tags' => {
        'TRUNK-1135538253' => {
          'file1' => '6',
          'file3' => '6',
          'dir2' => {
            'file4' => '6'
          },
          'dir1' => {
            'file2' => '6'
          }
        },
        'TRUNK-1135534439' => {
          'file1' => '6',
          'dir1' => {
            'file2' => '6'
          }
        }
      }
    }
  }
];
$changes = [
  {},
  { '' =>
      {
	'project2' => 'A',
	'project1' => 'A',
	'project2/tags' => 'A',
	'project1/trunk' => 'A',
	'project2/branches' => 'A',
	'project2/trunk' => 'A',
	'project1/branches' => 'A',
	'project1/tags' => 'A'
      },
  },
  { 
    'project1/trunk' =>
      {
	'project1/trunk/file1' => 'A',
	'project1/trunk/dir1/file2' => 'A',
	'project1/trunk/dir1' => 'A'
      },
  },
  { 
    'project1/trunk' => {},
    'project1/tags/TRUNK-1135534439' =>
      {
	'project1/tags/TRUNK-1135534439/file1' => 'A',
	'project1/tags/TRUNK-1135534439/dir1/file2' => 'A',
	'project1/tags/TRUNK-1135534439/dir1' => 'A'
      },
  },
  { 
    'project1/trunk' => {},
    'project1/tags/TRUNK-1135534439' => {},
    'project1/branches/branch1',
      {
	'project1/branches/branch1/file1' => 'A',
	'project1/branches/branch1/dir1/file2' => 'A',
	'project1/branches/branch1/dir1' => 'A'
      },
  },
  { 'project1/branches/branch1' =>
      {
	'project1/branches/branch1/dir2/file4' => 'A',
	'project1/branches/branch1/file3' => 'A',
	'project1/branches/branch1/dir2' => 'A'
      },
  },
  { 'project1/trunk' =>
      {
	'project1/trunk/file3' => 'A',
	'project1/trunk/dir2' => 'A',
	'project1/trunk/dir2/file4' => 'A'
      },
  },
  { 'project1/tags/TRUNK-1135538253' =>
      {
	'project1/tags/TRUNK-1135538253/file3' => 'A',
	'project1/tags/TRUNK-1135538253/dir2' => 'A',
	'project1/tags/TRUNK-1135538253/dir2/file4' => 'A'
      },
  },
  { 'project2/trunk' =>
      {
	'project2/trunk/dir4/file7' => 'A',
	'project2/trunk/dir4/file8' => 'A',
	'project2/trunk/dir3/file6' => 'A',
	'project2/trunk/dir3' => 'A',
	'project2/trunk/file5' => 'A',
	'project2/trunk/dir4' => 'A'
      },
  },
  { 'project2/tags/TRUNK-1135538991' =>
      {
	'project2/tags/TRUNK-1135538991/dir4/file7' => 'A',
	'project2/tags/TRUNK-1135538991/dir4/file8' => 'A',
	'project2/tags/TRUNK-1135538991/dir3/file6' => 'A',
	'project2/tags/TRUNK-1135538991/dir3' => 'A',
	'project2/tags/TRUNK-1135538991/file5' => 'A',
	'project2/tags/TRUNK-1135538991/dir4' => 'A'
      },
  },
  { 'project2/branches/branch2' =>
      {
	'project2/branches/branch2' => 'A'
      },
  },
  { 'project2/branches/branch2' =>
      {
	'project2/branches/branch2/dir5' => 'A',
	'project2/branches/branch2/file5' => 'D',
	'project2/branches/branch2/dir3' => 'D',
	'project2/branches/branch2/file5.new' => 'A'
      },
  },
  { 'project2/tags/TRUNK-1135539568' =>
      {
	'project2/tags/TRUNK-1135539568' => 'A'
      }
  },
];
