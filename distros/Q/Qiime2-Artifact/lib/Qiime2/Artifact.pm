package Qiime2::Artifact;
#ABSTRACT: A parser for Qiime2 artifact files

use 5.016;
use warnings;
use autodie;
use Carp qw(confess);
use Cwd qw();
use Term::ANSIColor qw(:constants);
use Data::Dumper;
use YAML::PP;
use Capture::Tiny ':all';
use File::Basename;

$Qiime2::Artifact::VERSION = '0.10.6';

sub crash($);

sub new {
    my ($class, $args) = @_;

    # Check for misspelled parameters
    my %accepted_args = (
      'filename' => 'Path to the artifact',
      'unzip'    => 'Path to the unzip program (default: search in PATH)',
      'debug'    => 'Enable debug mode (not implemented)',
      'verbose'  => 'Enable verbose mode (not implemented)'
    );
    for my $parameter (keys %{ $args }) {
      crash("Parameter <$parameter> is not a valid Qiime2::Artifact->new() attribute.\nValid options: " .
        join(', ', sort keys %accepted_args)) if (not $accepted_args{$parameter});
    }



    my $abs_path = Cwd::abs_path($args->{filename});
   	my $unzip_path = $args->{unzip} // 'unzip';
    chomp($unzip_path);

   	# Check supplied filename (abs_path uses the filesystem and return undef if file not found)
    crash "Filename not found: $args->{filename}" unless defined $abs_path;
    # Check unzip
    crash "UnZip not found as <$unzip_path>.\n" unless _check_unzip($unzip_path);

    my $self = {

        filename_arg  => $args->{filename},
        debug         => $args->{debug} // 0,
        verbose       => $args->{verbose} // 0,
        filename      => $abs_path,
        unzip_path    => $unzip_path,
    };

    my $object = bless $self, $class;


    _read_artifact($object);


    return $object;
}

sub id {
	my ($self) = @_;
  if (defined $self->{id}) {
	   return $self->{id};
  } else {
    return 0;
  }
}

sub _read_artifact {
	my ($self) = @_;

  # Initialize attributes
  $self->{visualization} = 0  ;

	if (not defined $self->{filename}) {
		crash "_read_artifact: filename not defined $self";
	}
  if (not defined $self->{unzip_path}) {
		crash "_read_artifact: <unzip> path not defined $self";
	}  # Read files content in the artifact
  my $artifact_raw = _run( [$self->{unzip_path}, '-t', $self->{filename}] );

      if ($artifact_raw->{status} != 0) {
        # Unzip -t failed: not a zip file
        crash("$self->{filename} is not a ZIP file");
      }

  my $artifact_id;
	my @artifact_data;
	my %artifact_parents;
	my %artifact_files;

  # Read all files
  for my $line ( @{$artifact_raw->{'lines'}} ) {
    chomp($line);
    if ($line=~/testing:\s+(.+?)\s+OK/) {
        my ($id, $root, @path) = split /\//, $1;

        crash "$self->{filename} is not a valid artifact:\n  \"{id}/directory/data\" structure expected, found:\n  \"$1\"" unless (defined $root);
        my $stripped_path = $root;
        $stripped_path.= '/' . join('/', @path) if ($path[0]);
        $artifact_files{$stripped_path} = $1;

        if (! defined $artifact_id) {
          $artifact_id = $id;
        } elsif ($artifact_id ne $id) {
          crash "Artifact format error: Artifact $self->{filename} has multiple roots ($artifact_id but also $id).\n";
        }
        if ($root eq 'data') {
          if (basename($stripped_path) eq 'index.html') {
            $self->{visualization} = 1;
          }
          push(@artifact_data, basename($stripped_path));


        } elsif ($root eq 'provenance') {
          if ($path[0] eq 'artifacts') {
            $artifact_parents{$path[1]}++;
          }

        }

    }
  }

  $self->{data} = \@artifact_data;

  if (not defined $self->{data}[0]) {
    crash("No data found in artifact $self->{filename}");
  }
  $self->{id} = $artifact_id;
  my $auto = _YAMLLoad( $self->_getArtifactText($self->{id} .'/provenance/action/action.yaml') , $self->{id} .'/provenance/action/action.yaml' );
  $self->{parents}->{self} = $auto->{action};

  crash("No self parent") if (not defined $self->{parents}->{self});

  for my $key (keys %artifact_parents) {    # key=fa0cb712-1940-4971-9e7c-a08581e948ed
    my $parent = $self->_get_parent($key);
    $self->{parents}->{$key} = $parent;
  }


  $self->{ancestry} = _getAncestry($self);
  $self->{version} = 'Unknown';
  $self->{version} = 'archive';

  my $root_version = _getArtifactText($self, $self->{id}.'/VERSION');
  $self->{version} = $1 if ($root_version=~/framework:\s*\"?(.+)\"?/);
  $self->{archive} = $1 if ($root_version=~/archive:\s*\"?(.+)\"?/);
  $self->{loaded} = 1;
  $self->{parents_number} = scalar( keys %{ $self->{parents} } ) - 1  ;

}


sub _getAncestry {
  my ($self) = @_;
  my $output;
  my %found = ();

  # Direct parents
  $output->{objects}[0] = [ $self->{id} ];

  $self->{imported} = 0;
  if ($self->{parents}->{self}->{type} eq 'import' ) {
      $self->{imported} = 1;

  }


  # Hack for taxonomy.qzv
  if ($self->{parents}->{self}->{type} eq 'visualizer') {
        for my $hash (@{ $self->{parents}->{self}->{parameters} }) {
          if (defined $hash->{input} ) {
            my ($id) = split /:/, $hash->{input};
            push @{$output->{objects}[1]}, $id if (defined $id);
          }
        }
  }

  for my $input (@{$self->{parents}->{self}->{inputs}}) {

     for my $key (sort keys %{ $input }) {
       push @{ $output->{objects}[1] }, $$input{ $key } if (defined $$input{ $key });
     }
  }

  # Loop
  my $parents = 1;

  while ($parents) {
    $parents = 0;
    my $last_index = $#{ $output->{objects} };
    for my $item ( @{ $output->{objects}[$last_index] } ) {


      if ( defined $self->{parents}->{$item}->{from} ) {
        $parents++;
        foreach my $child ( @{ $self->{parents}->{$item}->{from} } ) {
          if (defined $child) {
            push( @{ $output->{objects}[$last_index + 1 ] }, $child) if ($found{$child});
            $found{$child}++;
          }
        }
      } else {
        $parents = 0;
      }
    }
  }
  return $output;
}

sub _tree {
  my $self = $_[0];

  my $last_array = $self->{ancestry}[-1];
  return 0 unless ( ${ $last_array}[0] );


  foreach my $item (@{$self->{ancestry}[-1]}) {
    if (defined $self->{parents}->{$item}->{from}) {
      push @{$self->{ancestry}}, $self->{parents}->{$item}->{from};
      return 1;
    } else {
      return 0;
    }
  }
  return 0;
}

sub _check_unzip {
  my ($cmd_list, $pattern) = ([$_[0]], 'UnZip 6.00');
  if ($^O eq 'linux' or $^O eq 'darwin') {
    # check if a command has a string in the output
    my $output = _run($cmd_list);

    if ($output->{status} != 0) {
        crash("Unable to test <$$cmd_list[0]>, execution returned $output->{status}.\n".
        "Under Linux and macOS $$cmd_list[0] is expected to print its help when invoked.\n");
    }

    if ($output->{stdout} =~/$pattern/) {
      # Pattern found in STDOUT invoking the command
      return 1;
    } elsif ($output->{stderr} =~/$pattern/) {
      # Pattern found in STDERR invoking the command
      return 2;
    } else {
      # Pattern NOT found
      return 0;
    }
  } else {
    if (-e "$$cmd_list[0]") {
      return 3;
    } else {
      # First try to check for Linux-like UnZip
      my $output = _run($cmd_list);
      return 1 if ($output->{stdout} =~/$pattern/);
      return 2 if ($output->{stderr} =~/$pattern/);

      # Try at least checking if unzip if installed
      system(['which', $$cmd_list[0]]);
      if ($?) {
        crash("Trying under non Linux/MacOS: <which $$cmd_list[0]> returned $?.\n".
        "#Debug: $output->{stdout}\n#Debug: $output->{stderr}\n");
      } else {
        # Binary is present, non tested for Version
        return 10;
      }
    }
  }
}

sub _get_parent {
  my ($self, $key) = @_;
  my $parent;

  my $metadata;
  my $action;
  # metadata= [id]/provenance/artifacts/[key]/metadata.yaml
  my $metadata_file = $self->{id} . "/provenance/artifacts/" . $key . '/metadata.yaml';
  $metadata = _YAMLLoad( $self->_getArtifactText($metadata_file), $metadata_file );

  # action = [id]/provenance/artifacts/[key]/action/action.yaml
  my $action_file = $self->{id} . "/provenance/artifacts/" . $key . '/action/action.yaml';
  $action = _YAMLLoad( $self->_getArtifactText($action_file), $action_file );

  $parent->{metadata} = $metadata;

  $parent->{action} = $action->{action};


  for my $input (@{$action->{action}->{inputs}}) {
      for my $key (sort keys %{ $input }) {
        push @{ $parent->{from} }, $$input{ $key };
      }
  }

  return $parent;
}

sub _getArtifactText {
  my ($self, $file) = @_;
  my @command_list = ($self->{unzip_path}, '-p', $self->{filename}, $file);

  my $out = _run(\@command_list);


  return $out->{stdout};
}

sub _run {
  my ($command_list, $opt) = @_;

  return 0 unless defined ${ $command_list }[0];

  # Perpare output data
  my $out = undef;

  my ($STDOUT, $STDERR, $OK) = capture {
    system(@{ $command_list });
  };

  $out->{cmd} = join(' ', @{ $command_list });
  $out->{status} = $OK;
  $out->{stdout} = $STDOUT;
  $out->{stderr} = $STDERR;
  my @output = split /\n/, $STDOUT;
  $out->{lines} = \@output;

  return $out;
}


sub debug {
  my ($self, $msg, $opt) = @_;
  return 0 if not defined $self->{debug};
  say STDERR GREEN, BOLD, '| ', RESET, $msg;
}

sub _YAMLLoad {
  my ($string, $info) = @_;
  my $ypp = YAML::PP->new;

  unless (length($string)) {
    crash "YAML string empty: unexpected error";
  }

  my $result = eval {
    $ypp->load_string($string);
  };

  if ($@) {
    crash "YAMLLoad failed on string $info:\n------------------------------------------------\n$string";
  } else {
    return $result;
  }
}

sub crash($) {
  chomp($_[0]);
	print STDERR BOLD RED " [Qiime2::Reader ERROR]",RESET,"\n";
	print STDERR RED " $_[0]\n ", '-' x 60, "\n", RESET;
	confess();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Qiime2::Artifact - A parser for Qiime2 artifact files

=head1 VERSION

version 0.10.6

=head1 Wiki

This module is a work-in-progress and the documentation of the API can
be found in the GitHub wiki: L<https://github.com/telatin/qiime2tools/wiki/Qiime2::Artifact-API-documentation>.

=head1 Synopsis

  use Qiime2::Artifact;

  my $artifact = Qiime2::Artifact->new( {
        filename => 'tree.qza'
    } );

  print "Artifact_ID: ",  $artifact->{id};

=head1 Methods

=over 4

=item B<new()>

Load artifact from file. Parameters are:

=over 4

=item I<filename> (path, required)

Path to the artifact file to be imported (typical extensions are qza and qzv, but they are not enforced)

=item I<unzip> (path)

To specify the absolute path to C<unzip> binary. By default system unzip will be used.

=item I<verbose> (bool)

Enable verbose reporting (for developers)

=back

=back

=head1 Artifact object

=over 4

See L<https://github.com/telatin/qiime2tools/wiki> for API documentation

=back

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
