#!perl
use v5.36;
use Test::More;
our $verbose = grep { $_ eq '-v' or $_ eq '--verbose' } @ARGV;

do_tests();
done_testing();

#######################################################################

sub do_tests {
  my $class = 'PlackX::Framework::Template';
  require_ok($class);

  my $ok = eval {
    package MyTestApp {
      use PlackX::Framework qw(:Template);
    }
    1;
  };
  ok($ok, 'Created an empty app with Template feature');

  ok($INC{'MyTestApp/Template.pm'}, 'MyTestApp::Template class created');

  ok(MyTestApp::Template->isa('PlackX::Framework::Template'), 'MyTestApp::Template is proper subclass');

  unless (eval { require Template; 1}) {
    say "Template Toolkit not installed, ending $class test early";
    return;
  }

  my $http_response = MyTestApp::Response->new;
  my $template = MyTestApp::Template->new($http_response, Template->new);
  ok($template, 'Created a new MyTestApp::Template object');

  $template->set(param1 => 'value1');
  $template->set(param2 => 'value2', param3 => 'value3');
  is($template->get_param('param1') => 'value1', 'Template param param1 set successfully');
  is($template->get_param('param2') => 'value2', 'Template param param2 set successfully (multi-set in single call)');
  is($template->get_param('param3') => 'value3', 'Template param param3 set successfully (multi-set in single call)');

  my $tt_content = '[% param1 %][% param2 %][% param3 %]';
  $template->render(\$tt_content);
  is_deeply($http_response->body => ['value1value2value3'], 'Template parsed and rendered successfully');
}
