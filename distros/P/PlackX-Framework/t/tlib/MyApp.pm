use strict;
use warnings;
use experimental 'signatures';

package MyApp {
	use PlackX::Framework;
	use MyApp::Router;
	route '/' => sub {
		my $html = '<html><head><title>Hello World</title></head><body><h1>Hello World</h1><p>Hello from a PSGI raw arrayref response.</p></body></html>';
		return [200, [], [$html]];
	};
}

package MyApp2 {
	use PlackX::Framework;
	use MyApp2::Router;
	route '/app2' => sub {
		die "We should not be able to get here, as it's using MyApp2::Router instead of MyApp::Router";
	}
}

package MyApp::Controller::Main {
	use MyApp::Router;

	route '/plackx-response' => sub ($request, $response) {
		$response->print('<html>');
		$response->print('<head><title>Hello World2</title></head>');
		$response->print('<body><h1>Hello World2!</h1><p>Hello from a PlackX::Response object! Using print statements like it is the 90s again!</p></body>');
		$response->print('</html>');
		return $response;
	};

	route '/not-found' => sub {
		# Empty - not returning a response will result in a 404 not found.
	};

	route '/not-found-custom' => sub ($request, $response) {
		$response->status(404);
		$response->body('<html><head><title>NOT FOUND</title></head><body><h1>Oh no :(</h1><p>This is a custom 404 response.</p></body></html>');
		return $response;
	};

	route '/template' => sub ($request, $response) {
		# The following sets up templating manually with Template Toolkit (Template.pm)
		# Normally this could be automatically loaded via subclassing PlackX::Framework::Template
		# It has been enclosed into its own scope here to simulate use with auto-loading
		{
			require Template;
			my $templating_system = Template->new;
			my $template          = PlackX::Framework::Template->new($response, $templating_system);
			$response->template($template);
		}

		my $template_source = '<html><head><title>[% title %]</title></head><body><h1>[% title %]</h1><p>[% para1 %]</p></body></html>';
		$response->template->use(\$template_source);
		$response->template->set(title => 'Hello with Template Toolkit!');
		$response->template->set(para1 => 'Greetings from inside of a template using PlackX::Framework.');
		return $response->template->render;	
	};
}

package MyApp::Controller::MoreExamples {
	use MyApp::Router;
	base '/more-examples';

	filter 'before' => sub ($request, $response) {
		$response->print('<html><head><style type="text/css">body { font-family: Verdana, Helvetica; background: #333; color: #eee; }</style></head><body>');
		return;
    };

	filter 'before' => sub ($request, $response) {
		$response->print('<h1>I am a chained filter</h1>');
		return;
    };

	filter 'after' => sub ($request, $response) {
		$response->print('</body></html>');
		return;
    };

	route '/request-dump' => sub ($request, $response) {
		require Data::Dumper;
		$response->no_cache;
		$response->print('<pre>', Data::Dumper->Dump([$request]), '</pre>');
		return $response;
	};

	route '/response-dump' => sub ($request, $response) {
		require Data::Dumper;
		$response->no_cache;
		$response->print('<pre>', Data::Dumper->Dump([$response]), '</pre>');
		return $response;
	};

	route '/extra-slash' => sub ($request, $response) {
		$response->print('Extra slash?');
		return $response;
	};

	route 'route_param/{somename}' => sub ($request, $response) {
		$response->print('Hello ', $request->route_param('somename'));
		return $response;
	};

	route { get => ['form', 'form/get'] } => sub ($request, $response) {
		$response->print('<form method="POST"><input type="text" name="input"><input type="submit" value="Submit"></form></body>');
		return $response;
	};

	route { post => 'form' } => sub ($request, $response) {
		$response->print(q{You posted: "}, $request->param('input'), q{".});
		return $response;
	};

	route 'reroute' => sub ($request, $response) {
		return $request->reroute('/template');
	};

	route 'extra-filter' => sub ($request, $response) {
		$response->print('And here is the request response.');
		return $response;
	};
}

1;

