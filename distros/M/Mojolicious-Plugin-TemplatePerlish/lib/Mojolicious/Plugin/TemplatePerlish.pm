package Mojolicious::Plugin::TemplatePerlish;

use strict;
use warnings;
use English qw< -no_match_vars >;
{ our $VERSION = '0.002'; }

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw(encode md5_sum);
use Template::Perlish;

sub _resolve {
   my ($renderer, $options, $binmode) = @_;

   return (undef, inline => $options->{inline})
     if defined $options->{inline};

   my $name = $renderer->template_name($options);
   if (defined(my $path = $renderer->template_path($options))) {
      return ($name, path => _slurp($path, $binmode));
   }

   if (defined(my $tmpl = $renderer->get_data_template($options))) {
      return ($name, data => $tmpl);
   }

   return $name;
} ## end sub _resolve

sub _slurp {
   my ($path, $binmode) = @_;
   open my $fh, '<', $path
     or die "Error opening '$path': $OS_ERROR";
   binmode $fh, $binmode;
   local $/;
   return scalar <$fh>;
} ## end sub _slurp

sub register {
   my ($self, $app, $conf) = @_;

   # this is how we're going to slurp templates
   my $binmode = delete($conf->{read_binmode}) || ':encoding(UTF-8)';

   # caching of templates can be disabled if needed
   my $cache_for = exists($conf->{cache}) ? $conf->{cache} : 1;
   $cache_for = {} if $cache_for && ref($cache_for) ne 'HASH';

   my $name = $conf->{name} || 'tp';

   my $tp = Template::Perlish->new($conf->{template_perlish} || {});

   $app->renderer->add_handler(
      $name => sub {
         my ($renderer, $c, $output, $options) = @_;
         my $logger = $c->app()->log();

         my ($name, $type, $template) =
           _resolve($renderer, $options, $binmode);

         if (!defined $type) {
            $name = '(unknown name)' unless defined $name;
            $logger->debug("Template '$name' not found");
            return undef;
         }

         my $sub;
         if ($cache_for) {
            my $key = md5_sum(encode('UTF-8', $template));
            $sub = $cache_for->{$key} ||= $tp->compile_as_sub($template);
            $name = $key unless defined $name;
         }
         else {
            $sub = $tp->compile_as_sub($template);
            $name = md5_sum(encode('UTF-8', $template))
              unless defined $name;
         }

         my $helpers        = $renderer->helpers();
         my %helpers_params = map {
            my $method = $helpers->{$_};
            $_ => sub { $c->$method(@_) };
         } keys %$helpers;
         my %params = (
            %helpers_params,
            %{$c->stash()},
            self => $c,
            c    => $c,
         );

         $logger->debug("Rendering $type template '$name'");
         $$output = $sub->(\%params);

         return 1;
      }
   );
} ## end sub register

1;
__END__
