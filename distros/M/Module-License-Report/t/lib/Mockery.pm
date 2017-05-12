package Mockery;

use Test::MockObject::Extends;

sub create
{
   my $class = shift;

   return bless {}, $class;
}

package Mockery::CPANPLUS::Backend;

{
   my $tree;
   my $author;

   sub module_tree
   {
      my $self = shift;
      my $name = shift;

      my $id = 1;

      $author ||= CPANPLUS::Module::Author->new(
         author  => 'Fred',
         email   => 'fred@example.com',
         cpanid  => 'FREDFRED',
         _id     => $id,
      );

      if (!$tree)
      {
         my @list = (
            CPANPLUS::Module->new(
               author  => $author,
               module  => 'Module::License::Report',
               version => $Module::License::Report::VERSION,
               path    => '.',
               package => "Module-License-Report-$Module::License::Report::VERSION.tgz",
               dslip   => '',
               _id     => $id,
            ),
            CPANPLUS::Module->new(
               author  => $author,
               module  => 'CPANPLUS',
               version => '0.0562',
               path    => 't/sample/CPANPLUS',
               package => 'CPANPLUS-0.0562.tgz',
               dslip   => '....p',
               _id     => $id,
            ),
            CPANPLUS::Module->new(
               author  => $author,
               module  => 'YAML',
               version => '0.1111',
               path    => 't/sample/YAML',
               package => 'YAML-0.1111.tgz',
               dslip   => '',
               _id     => $id,
            ),
            CPANPLUS::Module->new(
               author  => $author,
               module  => 'File::Slurp',
               version => '9999.09',
               path    => 't/sample/File-Slurp',
               package => 'File-Slurp-9999.09.tgz',
               dslip   => '',
               _id     => $id,
            ),
            CPANPLUS::Module->new(
               author  => $author,
               module  => 'No::License',
               version => '0.01',
               path    => 't/sample/No-License',
               package => 'No-License-0.01.zip',
               dslip   => 'capn?',
               _id     => $id,
            ),
            CPANPLUS::Module->new(
               author  => $author,
               module  => 'Unknown::License',
               version => '0.01',
               path    => 't/sample/Unknown-License',
               package => 'Unknown-License-0.01.zip',
               dslip   => '',
               _id     => $id,
            ),
         );

         for (@list)
         {
            $_ = Test::MockObject::Extends->new($_);
            $_->mock('status',  sub { return $_[0]; });
            $_->mock('extract', sub { return $_[0]->{path}; });
            $_->mock('fetch',   sub { return $_[0]->{path}; });
         }

         $tree = { map {$_->{module} => $_} @list };
      }

      return $name ? $tree->{$name} : $tree;
   }

}

sub search
{
   my $self = shift;
   my %opts = @_;

   my $tree = $self->module_tree();
   my @list = values %$tree;
   for my $re (@{$opts{allow}})
   {
      @list = grep {$_->{$opts{type}} =~ $re} @list;
   }
   return @list;
}

{
   my @last;
   sub configure_object { my $self = shift; @last = @_; return $self; }
   sub set_conf         { my $self = shift; @last = @_; return $self; }
   sub __get_last_args  { my @l = @last; @last = (); return @l; }
}

1;
