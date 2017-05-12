use strict;
use warnings;

use Test::More 0.96;
use IO::Uncompress::Gunzip qw( gunzip );
use Paludis::ResumeState::Serialization::Grammar;

my (%files) = (
  'resume-1293352490.gz'     => 46,
  'resume-1293483679.gz'     => 34,
  'resumefile-1293138973.gz' => 34,
);

my $grammar = Paludis::ResumeState::Serialization::Grammar->grammar();

my %classes;

for ( keys %files ) {
  gunzip "t/tfiles/$_", \my $data;
  my $callback_called;
  local $Paludis::ResumeState::Serialization::Grammar::CLASS_CALLBACK = sub {
    my $class      = shift(@_);
    my $params     = shift(@_);
    my $listparams = shift(@_);
    my $extras     = shift(@_);
    $classes{$class} = {} unless defined $classes{$class};
    for ( keys %{$params}, map { '_' . $_ } keys %{$extras} ) {
      $classes{$class}->{$_}++;
    }
    $callback_called++;
    $params->{_classname} = $class;
    for ( keys %$extras ) {
      $params->{ '_' . $_ } = $extras->{$_};
    }
    return bless $params, 'Paludis::ResumeState::Serialization::Grammar::FakeClass';

  };
  ok( $data =~ $grammar, "$_ matches the grammar(+callback)" );
  is( $callback_called, $files{$_}, "Callback was called expected $files{$_} times" );
}

is_deeply(
  \%classes,
  {
    JobSkippedState => {},
    FetchJob        => { map { $_ => 17 } qw( origin_id_spec requirements state ) },
    InstallJob =>
      { map { $_ => 17 } qw( destination_type origin_id_spec destination_repository_name replacing_specs requirements state ) },
    PretendJob        => { map { $_ => 17 } qw( destination_type origin_id_spec destination_repository_name ) },
    JobFailedState    => {},
    JobLists          => { map { $_ => 3 } qw( pretend_job_list execute_job_list ) },
    JobSucceededState => {},
    ResumeData =>
      { map { $_ => 3 } qw( targets world_specs job_lists preserve_world target_set _pid removed_if_dependent_names ) },
    JobList        => { map { $_ => 6 } qw( items ) },
    JobRequirement => { map { $_ => 17 } qw( job_number required_if ) },
  },
  "Callbacks can properly track parameters"
);

#use Data::Dumper qw( Dumper ); $Data::Dumper::Indent=1 ; print Dumper \%/;
done_testing();
