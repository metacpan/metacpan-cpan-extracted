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

$Qiime2::Artifact::VERSION = '0.10.5';

sub crash($);

sub new {
    # Instantiate object
    my ($class, $args) = @_;

    my $abs_path = Cwd::abs_path($args->{filename});
   	my $unzip_path = $args->{unzip} // 'unzip';

   	# Check supplied filename (abs_path uses the filesystem and return undef if file not found)
    crash "Filename not found: $args->{filename}" unless defined $abs_path;
    # Check unzip
    crash "UnZip not found as <$unzip_path>.\n" unless _check_output($unzip_path, 'UnZip 6.00');

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

  # Read files content in the artifact
  my $artifact_raw = _run( qq(unzip -t "$self->{filename}" ));
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

  $self->{version} = 'Unknown';$self->{version} = 'archive';

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

  say ">>> @{$self->{ancestry}[-1]}";
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

sub _check_output {
  # check if a command has a string in the output
  my ($cmd, $pattern) = @_;
  my $output = _run($cmd);

  if ($output->{status} != 0) {
      crash("Unable to test <$cmd>, execution returned $output->{status}");
  }

  if ($output->{stdout} =~/$pattern/) {
    return 1;
  } elsif ($output->{stderr} =~/$pattern/) {
    return 2;
  } else {
    return 0;
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
  my $command = qq(unzip -p "$self->{filename}" "$file" );
  my $out = _run($command);


  return $out->{stdout};
}

sub _run {
  my ($command, $opt) = @_;
  return 0 unless defined $command;

  # Perpare output data
  my $out = undef;

  my ($STDOUT, $STDERR, $OK) = capture {
    system($command);
  };

  $out->{cmd} = $command;
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

version 0.10.5

=head1 Synopsis

  use Qiime2::Artifact;

  my $artifact = Qiime2::Artifact->new( {
        filename => 'tree.qza'
    } );

  print "Artifact_ID: ",  $artifact->{id};

=head1 Methods

=over 4

=item B<new()>

Load artifact from file. Parameters are: I<filename> (required).

=back

=head1 Artifact object

=over 4

=item B<id> I<(string)>

Artifact ID (example: C<cfdc04fb-9c26-40c1-a03b-88f79e5735f1>)

=item B<version> I<(string)>

Artifact ID (example: C<2019.10.0>), from the VERSION file

=item B<archive> I<(int)>

Artifact archive version, from the VERSION file

=item B<filename> I<(string)>

Full path of the input artifact.

=item B<visualizazion> I<(bool)>

Whether the artifact looks like a visualization artifact.
True (1) if the data contains C<index.html>.

=item B<data> I<(array)>

list of the files included in the 'data' directory

=item B<ancestry> I<(array of array)>

A list of levels of ancestry, each containing a list of Artifact IDs.
The first element is a list with the Artifact self ID. The last should contain the source artifact.
See also B<parents>.
Example:

  "ancestry" : [
      [
         "cfdc04fb-9c26-40c1-a03b-88f79e5735f1"
      ],
      [
         "96a220d6-107a-43c8-8d81-93ac4d111e3e",
         "3575de92-f7e7-4808-b0fa-b1a621ab984e"
      ],
      [
         "39771507-f226-4e18-aa30-cde40c3ea247"
      ]
   ],

=item B<parents> I<Hash>

Hash with all the provenance artifacts. Each parent has as key an Artifact ID, having as attributes:

=over 4

=item B<from>

List of artifact IDs originating the parent.

=item B<metadata>

Hash with C<key>, C<format>, C<uuid>.

=item B<action>

Structure containing C<citations>, C<parameters>, C<inputs> and other attributes.

=back

=back

=head1 AUTHOR

Andrea Telatin <andrea@telatin.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Andrea Telatin.

This is free software, licensed under:

  The MIT (X11) License

=cut
