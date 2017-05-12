use 5.001001;
package Mojolicious::Plugin::MySQLViewerLite::Base;
use Mojo::Base 'Mojolicious::Plugin';
use DBIx::Custom;
use Validator::Custom;
use File::Basename 'dirname';
use Cwd 'abs_path';
use Carp 'croak';

has 'prefix';
has validator => sub {
  my $validator = Validator::Custom->new;
  $validator->register_constraint(
    safety_name => sub {
      my $name = shift;
      return ($name || '') =~ /^\w+$/ ? 1 : 0;
    }
  );
  return $validator;
};

has dbi => sub { DBIx::Custom->new };

has command => sub { croak "Unimplemented" };

sub register { croak "Unimplemented" }

sub add_template_path {
  my ($self, $renderer, $class) = @_;
  $class =~ s/::/\//g;
  $class .= '.pm';
  my $public = abs_path $INC{$class};
  $public =~ s/\.pm$//;
  push @{$renderer->paths}, "$public/templates";
}

sub add_static_path {
  my ($self, $static, $class) = @_;
  $class =~ s/::/\//g;
  $class .= '.pm';
  my $public = abs_path $INC{$class};
  $public =~ s/\.pm$//;
  push @{$static->paths}, "$public/public";
}

1;
