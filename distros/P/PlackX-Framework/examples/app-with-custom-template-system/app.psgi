#!perl
use v5.36;

package Example::TemplateEngine {
  use Role::Tiny::With;
  with 'PlackX::Framework::Role::TemplateEngine';

  use FindBin;
  my $template_dir = $FindBin::Bin . '/percent-templates/';

  # This trivial example of a Template Engine class does not need to store
  # any data, so we will just bless a reference to the name of the class.
  sub new ($class) { bless \$class, $class }

  # We implement a partially TT-compatible process() method, which in this case
  # takes a file name, a params hash, and an object with a print() method.
  # Our very simple template language replaces %%%var%%% with the value of var
  # This module does not HAVE to have a TT-compatible interface, but if not
  # will require more work to integrate.
  sub process ($self, $file, $params, $printer) {
    $file = "$template_dir/$file.html";
    if (open(my $fh, '<', $file)) {
      while (my $line = <$fh>) {
        while (my ($varname) = $line =~ m/%%%(\w+)%%%/) {
          my $value = $params->{$varname} // '';
          $line =~ s/%%%\w+%%%/$value/;
        }
        $printer->print($line);
      }
      close $fh;
      return $self;
    }
    die "Cannot open template $file, $!";
  }
}

package MyApp {
  # Use PXF and enable optional template feature (or use :all)
  use PlackX::Framework qw(:template);

  # Set up templating, using method 1 below.
  # There are several ways to use our own engine:
  # 1. Pass the :manual tag, then call set_engine with the desired engine object
  #    (this requires that the engine have a TT-compatible process() method).
  # 2. Manually subclass PlackX::Framework::Template, and override
  #    engine_class to return the name of the class of our template engine
  #    and engine_default_options to return an appropriate hashref; this isn't
  #    much different from option 1.
  # 3. Write an engine and PlackX::Framework::Template subclass almost from
  #    scratch, overriding as much as necessary. This method is very flexible.
  use MyApp::Template qw(:manual);
  MyApp::Template->set_engine(Example::TemplateEngine->new);

  # Import routing
  use MyApp::Router;

  # Add routes
  route ['/', '/{page}'] => sub ($request, $response) {
    $response->template->set(
      page    => $request->route_param('page') || 'index',
      somevar => $request->param('somevar'),
      pid     => $$,
    );
    return $response->template->render('main');
  };
}

# Return app coderef
MyApp->app;
