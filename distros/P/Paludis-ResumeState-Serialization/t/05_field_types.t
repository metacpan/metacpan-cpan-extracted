use strict;
use warnings;

use Test::More 0.96;
use IO::Uncompress::Gunzip qw( gunzip );
use Scalar::Util qw( blessed );
use Paludis::ResumeState::Serialization::Grammar;

my (%files) = (
  'resume-1293352490.gz'     => 46,
  'resume-1293483679.gz'     => 34,
  'resumefile-1293138973.gz' => 34,
);

my $grammar = Paludis::ResumeState::Serialization::Grammar->grammar();

my %classes;

sub identify_param {
  my ($param) = shift;
  if ( not blessed($param) ) {
    if ( ref $param ) {
      return 'REF:' . ref $param;
    }
    else {
      return 'String';
    }
  }
  if ( blessed($param) eq 'Paludis::ResumeState::Serialization::Grammar::FakeClass' ) {
    return 'FakeClass[' . $param->{_classname} . ']';
  }
  if ( blessed($param) eq 'Paludis::ResumeState::Serialization::Grammar::FakeArray' ) {
    my %types;
    for ( @{$param} ) {
      my $id = identify_param($_);
      $types{$id}++;
    }
    return 'FakeArray[' . join( q{,}, sort keys %types ) . ']';
  }
  return '?';
}

for ( keys %files ) {
  gunzip "t/tfiles/$_", \my $data;
  my $callback_called;
  local $Paludis::ResumeState::Serialization::Grammar::CLASS_CALLBACK = sub {
    my $class      = shift(@_);
    my $params     = shift(@_);
    my $paramslist = shift(@_);
    my $extras     = shift(@_);
    $classes{$class} = {} unless defined $classes{$class};
    for ( keys %{$params} ) {
      my $type = identify_param( $params->{$_} );
      $classes{$class}->{$_} = {} unless defined $classes{$class}->{$_};
      $classes{$class}->{$_}->{$type}++;
    }
    for ( keys %{$extras} ) {
      my $type  = identify_param( $extras->{$_} );
      my $label = "_" . $_;
      $classes{$class}->{$label} = {} unless defined $classes{$class}->{$label};
      $classes{$class}->{$label}->{$type}++;
    }

    $callback_called++;
    $params->{_classname} = $class;
    return bless $params, 'Paludis::ResumeState::Serialization::Grammar::FakeClass';

  };
  ok( $data =~ $grammar, "$_ matches the grammar(+callback)" );
  is( $callback_called, $files{$_}, "Callback was called expected $files{$_} times" );
}

is_deeply(
  \%classes,
  {
    JobSkippedState => {},
    FetchJob        => {
      'origin_id_spec' => { 'String'      => 17 },
      'requirements'   => { 'FakeArray[]' => 17 },
      'state'          => {
        'FakeClass[JobSucceededState]' => 14,
        'FakeClass[JobFailedState]'    => 3,
      },
    },
    InstallJob => {
      destination_type            => { String                                 => 17 },
      origin_id_spec              => { String                                 => 17 },
      destination_repository_name => { String                                 => 17 },
      replacing_specs             => { 'FakeArray[String]'                    => 17 },
      requirements                => { 'FakeArray[FakeClass[JobRequirement]]' => 17 },
      state                       => {
        'FakeClass[JobSkippedState]'   => 3,
        'FakeClass[JobSucceededState]' => 9,
        'FakeClass[JobFailedState]'    => 5
      },
    },
    PretendJob => {
      'destination_type'            => { 'String' => 17 },
      'origin_id_spec'              => { 'String' => 17 },
      'destination_repository_name' => { 'String' => 17 },
    },
    JobFailedState => {},
    JobLists       => {
      'pretend_job_list' => { 'FakeClass[JobList]' => 3 },
      'execute_job_list' => { 'FakeClass[JobList]' => 3 }
    },
    JobSucceededState => {},
    ResumeData        => {
      'targets'                    => { 'FakeArray[String]'   => 3 },
      'world_specs'                => { 'FakeArray[String]'   => 3 },
      'job_lists'                  => { 'FakeClass[JobLists]' => 3 },
      'preserve_world'             => { 'String'              => 3 },
      'target_set'                 => { 'String'              => 3 },
      '_pid'                       => { 'String'              => 3 },
      'removed_if_dependent_names' => { 'FakeArray[]'         => 3 },
    },
    JobList => {
      'items' => {
        'FakeArray[FakeClass[PretendJob]]'                     => 3,
        'FakeArray[FakeClass[FetchJob],FakeClass[InstallJob]]' => 3,
      }
    },
    JobRequirement => {
      'job_number'  => { 'String' => 17 },
      'required_if' => { 'String' => 17 }
    },
  },
  "Callbacks can properly track types"
);

#use Data::Dumper qw( Dumper );
#$Data::Dumper::Indent = 1;
#print Dumper \%classes;
done_testing();
