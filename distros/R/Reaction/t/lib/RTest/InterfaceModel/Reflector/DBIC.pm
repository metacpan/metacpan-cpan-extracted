package RTest::InterfaceModel::Reflector::DBIC;

use base qw/Reaction::Test::WithDB Reaction::Object/;
use Reaction::Class;
use Class::MOP ();
use ComponentUI::TestModel;
use Test::More ();
use Reaction::InterfaceModel::Reflector::DBIC;

has '+schema_class' => (default => sub { 'RTest::TestDB' });

has im_schema => (is =>'ro', isa => 'RTest::TestIM', lazy_build => 1);

#at the moment I am only testing with the "reflect all" functionality
#when I have time I will write test cases that cover all the other bases
#it's just kind of a pain in the ass right now and I am behind on a lot of other shit.

sub _build_im_schema{
  my $self = shift;

  my $reflector = Reaction::InterfaceModel::Reflector::DBIC->new;

  $reflector->reflect_schema(
                             model_class  => 'RTest::TestIM',
                             schema_class => 'RTest::TestDB',
                             sources => [qw/Foo Bar Baz/]
                           );
  my (@dm) = RTest::TestIM->domain_models;
  Test::More::ok(@dm == 1, 'Correct number of Domain Models');
  my $dm = shift @dm;
  RTest::TestIM->new($dm->name => $self->schema);
}

sub test_classnames : Tests{
  my $self = shift;

  my $reflector = Reaction::InterfaceModel::Reflector::DBIC->new;


  Test::More::is(
                 $reflector->class_name_from_source_name('RTest::__TestIM','Foo'),
                 'RTest::__TestIM::Foo',
                 'Correct naming scheme for submodels'
                );
  Test::More::is(
                 $reflector->class_name_for_collection_of('RTest::__TestIM::Foo'),
                 'RTest::__TestIM::Foo::Collection',
                 'Correct naming scheme for submodel collections'
                );
}

sub test_reflect_schema :Tests {
  my $self = shift;
  my $s = $self->im_schema;

  Test::More::isa_ok( $s, 'Reaction::InterfaceModel::Object', 'Correct base' );

  my %pa = map{$_->name => $_ } $s->parameter_attributes;
  Test::More::ok(keys %pa == 3,  'Correct number of Parameter Attributes');

  Test::More::ok($pa{Foo} && $pa{'Bar'} && $pa{'Baz'},
                 'Parameter Attributes named correctly');

  for my $submodel (values %pa){
    Test::More::ok(
                   $submodel->_isa_metadata->isa('Reaction::InterfaceModel::Collection::Virtual::ResultSet'),
                   'Parameter Attribute typed correctly'
                  );
  }

  Test::More::can_ok($s, qw/foo_collection bar_collection baz_collection/);

  for ( qw/Foo Bar Baz/ ){
    Test::More::ok(
                   Class::MOP::is_class_loaded("RTest::TestIM::${_}"),
                   "Successfully created ${_} IM class"
                  );
    Test::More::ok(
                   Class::MOP::is_class_loaded("RTest::TestIM::${_}::Collection"),
                   "Successfully created ${_} IM class Collection"
                  );
  }
}


sub test_add_source_to_model :Tests {
  my $self = shift;
  my $s = $self->im_schema;

  for (qw/Foo Bar Baz /) {
    my $attr = $s->meta->find_attribute_by_name($_);
    my $reader = $_;
    $reader =~ s/([a-z0-9])([A-Z])/${1}_${2}/g ;
    $reader = lc($reader) . "_collection";

    Test::More::ok( $attr->is_required,           "${_} is required");
    Test::More::ok( $attr->has_reader,            "${_} has a reader");
    Test::More::ok( $attr->has_predicate,         "${_} has a predicate");
    Test::More::ok( $attr->has_domain_model,      "${_} has a domain_model");
    Test::More::ok( $attr->has_default,           "${_} has a default");
    Test::More::ok( $attr->is_default_a_coderef,  "${_}'s defaultis a coderef");
    Test::More::is( $attr->reader,   $reader,     "Correct ${_} reader");
    SKIP: {
      Test::More::skip "Not working", 1;
      Test::More::is( $attr->domain_model, "_rtest_testdb_store", "Correct ${_} domain_model");
    }
    Test::More::isa_ok(
                       $s->$reader,
                       "RTest::TestIM::${_}::Collection",
                       "${_} default method works"
                      );

  }
}

sub test_reflect_collection_for :Tests{
  my $self = shift;
  my $s = $self->im_schema;

  for ( qw/Foo Bar Baz/ ){
    my $reader = $s->meta->find_attribute_by_name($_)->reader;
    my $collection = $s->$reader;

    Test::More::is(
                   $collection->meta->name,
                   "RTest::TestIM::${_}::Collection",
                   "Correct Classname"
                  );
    Test::More::isa_ok(
                       $collection,
                       'Reaction::InterfaceModel::Collection',
                       "Collection ISA Collection"
                      );
    Test::More::isa_ok(
                       $collection,
                       'Reaction::InterfaceModel::Collection::Virtual',
                       "Collection ISA virtual collection"
                      );
    Test::More::isa_ok(
                       $collection,
                       'Reaction::InterfaceModel::Collection::Virtual::ResultSet',
                       "Collection ISA virtual resultset"
                      );
    SKIP: {
      Test::More::skip 'Does not work', 2;
      Test::More::can_ok($collection, '_build__im_class');
      Test::More::is(
                   $collection->_build__im_class,
                   "RTest::TestIM::${_}",
                   "Collection has correct _im_class"
                  );
    }
  }
}

sub test_reflect_submodel :Tests{
  my $self = shift;
  my $s = $self->im_schema;

  for my $sm ( qw/Foo Bar Baz/ ){
    my $reader = $s->meta->find_attribute_by_name($sm)->reader;
    my $collection = $s->$reader;
    my ($member) = $collection->members;
    Test::More::ok($member, "Successfully retrieved member");
    Test::More::isa_ok(
                       $member,
                       "Reaction::InterfaceModel::Object",
                       "Member isa IM::Object"
                      );
    SKIP: {
      Test::More::skip 'Attribute does not exist', 1;
      Test::More::isa_ok($member, $collection->_im_class);
    }
    
    my (@dm) = $member->domain_models;
    Test::More::ok(@dm == 1, 'Correct number of Domain Models');
    my $dm = shift @dm;

    my $dm_name = Reaction::InterfaceModel::Reflector::DBIC
      ->dm_name_from_source_name($sm);

    Test::More::is($dm->_is_metadata, "rw", "Correct is metadata");
    Test::More::ok($dm->is_required,  "DM is_required");
    Test::More::is($dm->name, $dm_name, "Correct DM name");
    Test::More::can_ok($member, "inflate_result");
    SKIP: {
      Test::More::skip 'Does not exist', 1;
      Test::More::is(
                   $dm->_isa_metadata,
                   "RTest::TestDB::${sm}",
                   "Correct isa metadata"
                  );
    }

    my %attrs = map { $_->name => $_ } $member->parameter_attributes;
    my $target;
    if(   $sm eq "Bar"){$target = 4; }
    elsif($sm eq "Baz"){$target = 5; }
    elsif($sm eq "Foo"){$target = 5; }
    Test::More::is( scalar keys %attrs, $target, "Correct # of attributes for $sm");

    for my $attr_name (keys %attrs){
      my $attr = $attrs{$attr_name};
      Test::More::ok($attr->is_lazy,                "is lazy");
      Test::More::ok($attr->is_required,            "is required");
      Test::More::ok($attr->has_clearer,            "has clearer");
      Test::More::ok($attr->has_default,            "has defau;t");
      Test::More::ok($attr->has_predicate,          "has predicate");
      Test::More::ok($attr->has_domain_model,       "has domain model");
      Test::More::ok($attr->has_orig_attr_name,     "has orig attr name");
      Test::More::ok($attr->is_default_a_coderef,   "default is coderef");
      Test::More::is($attr->_is_metadata,  "ro",    "Correct is metadata");
      Test::More::is($attr->domain_model, $dm_name, "Correct domain model");
      Test::More::is($attr->orig_attr_name, $attr_name, "Correct orig attr name");
    }

    SKIP: {
      if($sm eq "Foo"){
        Test::More::skip '_isa_metadata does not exist', 4;
        
        Test::More::is($attrs{id}->_isa_metadata, "Int", "Correct id isa metadata");
        Test::More::is($attrs{first_name}->_isa_metadata, "Reaction::Types::Core::NonEmptySimpleStr", "Correct first_name isa metadata");
        Test::More::is($attrs{last_name}->_isa_metadata,  "Reaction::Types::Core::NonEmptySimpleStr", "Correct last_name isa metadata");
        Test::More::is(
                       $attrs{baz_list}->_isa_metadata,
                       "RTest::TestIM::Baz::Collection",
                       "Correct baz_list isa metadata"
                      );
      } elsif($sm eq 'Bar'){
        Test::More::skip '_isa_metadata does not exist', 4;
        
        Test::More::is($attrs{name}->_isa_metadata, "Reaction::Types::Core::NonEmptySimpleStr", "Correct name isa metadata");
        Test::More::is($attrs{foo}->_isa_metadata, "RTest::TestIM::Foo", "Correct foo isa metadata");
        Test::More::is($attrs{published_at}->_isa_metadata, "DateTime",  "Correct published_at isa metadata");
        Test::More::is($attrs{avatar}->_isa_metadata, "File",            "Correct avatar isa metadata");
      } elsif($sm eq "Baz"){
        Test::More::skip '_isa_metadata does not exist', 3;
        
        Test::More::is($attrs{id}->_isa_metadata, "Int", "Correct id isa metadata");
        Test::More::is($attrs{name}->_isa_metadata, "Reaction::Types::Core::NonEmptySimpleStr", "Correct name isa metadata");
        Test::More::is(
                       $attrs{foo_list}->_isa_metadata,
                       "RTest::TestIM::Foo::Collection",
                       "Correct foo_list isa metadata"
                      );
      }
    }

  }
}

sub test_reflect_submodel_action :Tests{
  my $self = shift;
  my $s = $self->im_schema;

  for my $sm ( qw/Foo Bar Baz/ ){
    my $reader = $s->meta->find_attribute_by_name($sm)->reader;
    my $collection = $s->$reader;
    my ($member) = $collection->members;
    Test::More::ok($member, "Successfully retrieved member");
    Test::More::isa_ok(
                       $member,
                       "Reaction::InterfaceModel::Object",
                       "Member isa IM::Object"
                      );
    SKIP: {
      Test::More::skip 'Does not exist any more', 1;
      Test::More::isa_ok($member, $collection->_im_class);
    }
    
    my $ctx = $self->simple_mock_context;
    foreach my $action_name (qw/Update Delete DeleteAll Create/){

      my $target_im = $action_name =~ /(?:Create|DeleteAll)/ ? $collection : $member;
      my $action = $target_im->action_for($action_name, ctx => $ctx);

      Test::More::isa_ok( $action, "Reaction::InterfaceModel::Action",
                          "Create action isa Action" );
      Test::More::is(
                     $action->meta->name,
                     "RTest::TestIM::${sm}::Action::${action_name}",
                     "${action_name} action has correct name"
                    );

      my $base = 'Reaction::InterfaceModel::Action::DBIC'.
        ($action_name =~ /(?:Create|DeleteAll)/
         ? "::ResultSet::${action_name}" : "::Result::${action_name}");
      Test::More::isa_ok($action, $base, "${action_name} has correct base");


      my %attrs = map { $_->name => $_ } $action->parameter_attributes;
      my $attr_num;
      if($action_name =~ /Delete/){next; }
      elsif($sm eq "Bar"){$attr_num = 4; }
      elsif($sm eq "Baz"){$attr_num = 4; }
      elsif($sm eq "Foo"){$attr_num = 3; }
      Test::More::is( scalar keys %attrs, $attr_num, "Correct # of attributes for $sm");
      if($attr_num != keys %attrs ){
        print STDERR "\t..." . join ", ", keys %attrs, "\n";
      }

      for my $attr_name (keys %attrs){
        my $attr = $attrs{$attr_name};
        Test::More::ok($attr->has_predicate,        "has predicate");
        Test::More::is($attr->_is_metadata,  "rw",  "Correct is metadata");
        if ($attr->is_required){
          Test::More::ok($attr->is_lazy,     "is lazy");
          Test::More::ok($attr->has_default, "has default");
          Test::More::ok($attr->is_default_a_coderef, "default is coderef");
        }
      }

      SKIP: {
        if($sm eq "Foo"){
          Test::More::skip '_isa_metadata no longer exists', 3;
          
          Test::More::is($attrs{first_name}->_isa_metadata, "Reaction::Types::Core::NonEmptySimpleStr", "Correct first_name isa metadata");
          Test::More::is($attrs{last_name}->_isa_metadata,  "Reaction::Types::Core::NonEmptySimpleStr", "Correct last_name isa metadata");
          Test::More::is($attrs{baz_list}->_isa_metadata,  "ArrayRef", "Correct baz_list isa metadata");
        } elsif($sm eq 'Bar'){
          Test::More::skip '_isa_metadata no longer exists', 4;
          
          Test::More::is($attrs{name}->_isa_metadata, "Reaction::Types::Core::NonEmptySimpleStr",  "Correct name isa metadata");
          Test::More::is($attrs{foo}->_isa_metadata,  "RTest::TestDB::Foo", "Correct foo isa metadata");
          Test::More::is($attrs{published_at}->_isa_metadata, "DateTime",   "Correct published_at isa metadata");
          Test::More::is($attrs{avatar}->_isa_metadata, "File",             "Correct avatar isa metadata");
        } elsif($sm eq "Baz"){
          Test::More::skip '_isa_metadata no longer exists', 1;
          
          Test::More::is($attrs{name}->_isa_metadata, "Reaction::Types::Core::NonEmptySimpleStr",  "Correct name isa metadata");
        }
      }
    }
  }
}

1;
