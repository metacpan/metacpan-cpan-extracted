package Su::Model;

use strict;
use warnings;
use Exporter;
use File::Path;
use Data::Dumper;
use Test::More;
use Carp;
use Storable qw(dclone);

use Su::Template;
use Su::Log;

our @ISA = qw(Exporter);

our @EXPORT = qw(generate_model load_model );

our $MODEL_DIR = "Models";

our $MODEL_BASE_DIR = "./";

our $MODEL_CACHE_HREF = {};

=pod

=head1 NAME

Su::Model - A module to treat user data.

=head1 SYNOPSYS

  Su::Model::load_model('Pkg::SomeModel', {share => 1} )->{field_A} = $value;

  my $value  = Su::Model::load_model('Pkg::SomeModel')->{field_A};

=head1 DESCRIPTION

Su::Model holds the data used in your application.
For convenience, Su provides method to generate Model class.

 use Su::Model;
 generate_model('NewModel');

=head1 ATTRIBUTES

=cut

our $_attr = {};

=head1 FUNCTIONS

=over

=cut

sub import {
  my $self         = shift;
  my %tmp_h        = @_;
  my $imports_aref = $tmp_h{import};
  delete $tmp_h{import};
  my $base = $tmp_h{base};
  my $dir  = $tmp_h{dir};

  #  print "base:" . Dumper($base) . "\n";
  #  print "dir:" . Dumper($dir) . "\n";

  $MODEL_BASE_DIR = $base if $base;
  $MODEL_DIR      = $dir  if $dir;

  if ( $base || $dir ) {
    $self->export_to_level( 1, $self, @{$imports_aref} );
  } else {

# If '' or '' is not passed, then all of the parameters are required method names.
    $self->export_to_level( 1, $self, @_ );
  }

} ## end sub import

=item attr()

Save the passed data in application scope.

 Su::Model->attr( 'key1', 'value1' );
 my $value = Su::Model->attr('key1');

 Su::Model->attr->{key4} = 'value4';
 my $value = Su::Model->attr->{key4};

=cut

sub attr {
  my $self  = shift if ( ref $_[0] eq __PACKAGE__ or $_[0] eq __PACKAGE__ );
  my $key   = shift;
  my $value = shift;
  if ( !defined $key ) {

    # If no argment is passed, return hash ref itself.
    return $_attr;
  } elsif ( defined $value ) {
    $_attr->{$key} = $value;
  } else {
    return $_attr->{$key};
  }
} ## end sub attr

=item new()

A Constructor.

=cut

sub new {
  my $self = shift;
  my %h    = @_;
  my $log  = Su::Log->new;
  $h{logger} = $log;
  $h{models} = {};
  return bless \%h, $self;
} ## end sub new

=item generate_model()

  generate_model('SomeModel', qw(field1 string field2 number field3 date));
  $mdl->generate_model('Nest/Mdl2');
  $mdl->generate_model('Nest::Mdl3');
  $mdl->generate_model('Nest::Mdl4',"field1",{"key1"=>"value1","key2"=>"value2"},"field2","value3");

  generate_model(NAME, &rest @(FIELD, VALUE));

Generate the model class using the passed model name.
If the optional parameters are passed, then generate the model class
using the passed parameter as the value of the model field of the
Model.
VALUE can be specified as scalar or hash reference.

The model field of the generated Model is like the following.

  my $model=
    {
      field1 =>  "value1",
      field2 => {somekey => "hashvalue"},
  };


You can generate Model class from command line using the following command.

  perl -I../lib -MSu::Model -e '{generate_model("ModelClass",field1,"value1",field2,"value2")}'
  perl -I../lib -MSu::Model -e '{generate_model("Pkg::ModelClass",field1,"value1",field2,"value2")}'

If you want to specify the directory to generate the Model class, then
pass the C<base> parameter like the following sample.

  perl -MSu::Model=base,lib -e '{generate_model("ModelClass",field1,value1,field2,value2)}'

You can specify the package name using the C<dir> parameter.

  perl -MSu::Model=dir,PkgName -e '{generate_model("ModelClass",field1,value1,field2,value2)}'

Note that if the model name is specified with qualified package name,
then this C<dir> parameter not effect.

If generation is success, this subroutine return the generated file
name, else should die or return undef.

=cut

sub generate_model {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $logger = $self->{logger} ? $self->{logger} : Su::Log->new;

  # NOTE: No need this safe guard.
  #  $self = {} unless $self;
  my $MODEL_BASE_DIR = $self->{base} ? $self->{base} : $MODEL_BASE_DIR;
  my $MODEL_DIR      = $self->{dir}  ? $self->{dir}  : $MODEL_DIR;

  #diag('$MODEL_BASE_DIR:' . $MODEL_BASE_DIR);
  #diag('$MODEL_DIR:' . $MODEL_DIR);
  $logger->trace( '$MODEL_BASE_DIR:' . $MODEL_BASE_DIR );
  $logger->trace( '$MODEL_DIR:' . $MODEL_DIR );
  my $comp_id = shift;
  my @rest    = @_;

  # Make directory path.
  my @arr = split( '/|::', $comp_id );
  my $comp_base_name = '';
  if ( scalar @arr > 1 ) {
    $comp_base_name = join( '/', @arr[ 0 .. scalar @arr - 2 ] );
  }

  my $dir;
  if ( $comp_id =~ /::|\// ) {
    $dir = $MODEL_BASE_DIR . "/" . $comp_base_name;
  } else {
    $dir = $MODEL_BASE_DIR . "/" . $MODEL_DIR . "/" . $comp_base_name;
  }

  # Prepare directory for generate file.
  mkpath $dir unless ( -d $dir );

  # '$!' can't judge error correctly.
  #  $! and die "$!:" . $dir;
  if ( !-d $dir ) {
    die "Can't make dir:" . $!;
  }

  my $comp_id_filepath = $comp_id;
  $comp_id_filepath =~ s!::!/!g;

  # Generate file.
  my $fpath;
  if ( $comp_id =~ /::|\// ) {
    $fpath = $MODEL_BASE_DIR . "/" . $comp_id_filepath . ".pm";
  } else {
    $fpath =
      $MODEL_BASE_DIR . "/" . $MODEL_DIR . "/" . $comp_id_filepath . ".pm";
  }

  open( my $file, '>', $fpath ) or carp "Can't open file:$fpath:" . $!;

  $comp_id =~ s/\//::/g;

  if ( $comp_id !~ /::/ ) {
    my $model_dir_for_package = $MODEL_DIR;
    $model_dir_for_package =~ s!/!::!g;

    #Note: Automatically add the default package Models.
    $comp_id = $model_dir_for_package . '::' . $comp_id;
  } ## end if ( $comp_id !~ /::/ )

  my $contents = _gen_contents( $comp_id, @_ );

  my $ret = print $file $contents;

  if ( $ret == 1 ) {
    print "generated:$fpath\n";
    return $fpath;
  } else {
    print "output fail:$fpath\n";
    return undef;
  }

} ## end sub generate_model

=item load_model()

Loat the Model object from the passed model name and return it's model field.
Note that this mothod do not return the instance of the loaded model object itself.

Functional style usage is like the following.

 my $model_href = Su::Model::load_model('SomeModel');

OO Style usage is like the following.

 my $mdl = Su::Model->new;
 $model_href = $mdl->load_model('Pkg/Mdl2');
 $model_href = $mdl->load_model('Pkg::Mdl3');

If you want to set some data to the model and access the data from the
model, then the sample code becomes as follwings:

  Su::Model::load_model('Pkg::SomeModel')->{value} = $value;

  my $value  = Su::Model::load_model('Pkg::SomeModel')->{value};

If you want to suppress dying because of module require error, then pass
the second parameter like the following.

  my $model = $mdl->load_model( 'Pkg::SomeModel', {suppress_error => 1} );

When the second parameter is passed and load error occured, then this
method return undef.

If you want to share and reuse model data, then pass the share parameter as
the second parameter.

  my $model = $mdl->load_model( 'Pkg::SomeModel', {share => 1} );

=cut

sub load_model {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );

  my $model_id         = shift;
  my $opt_href         = shift;
  my $MODEL_CACHE_HREF = $self ? $self->{models} : $MODEL_CACHE_HREF;

  # Return the cacned data if cache exists.
  return $MODEL_CACHE_HREF->{$model_id}
    if ( $MODEL_CACHE_HREF->{$model_id} ) && $opt_href->{share};

  # NOTE: No need this safe guard.
  #  $self = {} unless $self;
  my $MODEL_BASE_DIR = $self->{base} ? $self->{base} : $MODEL_BASE_DIR;
  my $MODEL_DIR      = $self->{dir}  ? $self->{dir}  : $MODEL_DIR;

  my $model_path = $model_id;

  # Convert package separator to file path separator.
  $model_path =~ s!::!/!g;
  $model_path .= ".pm";

  # Trim the head of dot slash(./) of the file path.
  $model_path =~ s!^\./(.+)!$1!;

  eval { require($model_path); };
  if ($@) {
    if ( $opt_href->{suppress_error} ) {
      return undef;
    } else {
      die $@;
    }
  } ## end if ($@)

  # Recover separator to use as model package separator.
  $model_id =~ s!/!::!g;
  my $model_href;
  if ( exists &{ ( $model_id . "::new" ) } ) {
    my $model_inst = $model_id->new;
    $model_href = $model_inst->{model};
  } else {
    $model_href = $model_id->can('model') ? $model_id->model : undef;
  }

  die "Model has no model field:" . $model_path unless $model_href;

  # Cache the model data.
  $self->{models}->{$model_id} = $model_href;

  if ( $opt_href->{share} ) {
    return $model_href;
  } else {

# To prevent destructive effect to this model data, we need to replicate the instance.
    return dclone($model_href);
  }
} ## end sub load_model

=begin comment

Return the contents of the new Model.

=end comment

=cut

sub _gen_contents {
  shift if ( ref $_[0] eq __PACKAGE__ );

  my $comp_id = shift;
  my %h       = @_;

  my $ft = Su::Template->new;
  my $ret = $ft->expand( <<'__TMPL__', $comp_id, \%h );
% my $comp_id = shift;
% my $href = shift;
package <%=$comp_id%>;
use strict;
use warnings;

my $model=
  {
%  while(my ($k,$v) = each(%{$href})){
%    if(ref $v eq 'HASH'){
    <%=$k%> =>
      {
%      while(my ($kk,$vv) = each(%{$v})){
        <%=$kk%> => "<%=$vv%>",
%      }
      },
%    }else{
    <%=$k%> => "<%=$v%>",
%    }
%  }
};

sub model{
  if($_[0] eq __PACKAGE__){
    shift;
  }
  my $arg = shift;
  if($arg){
    $model = $arg;
  }else{
    return $model;
  }

}

1;

__TMPL__

  return $ret;

} ## end sub _gen_contents

=pod

=back

=cut

#sub tmpl_test{
#
#  my $ret = tmpl(<<'__HERE__');
#% my $tmp = "tmpval";
#one
#hoge<% foreach my $v ("a","b","c"){%>fuga
#looping
#<%= $v%>
#<%} %>
#<%= $tmp%>
#two
#three
#__HERE__
#
#  return $ret;
#
#}

1;
