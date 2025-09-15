use Mojolicious::Lite;
use Mojo::Util qw(md5_sum);
use lib '../lib';

plugin 'Inertia', {
    version => md5_sum( app->home->child('dist', '.vite', 'manifest.json')->slurp ),
    layout  => app->home->child('dist', 'index.html')
};

# Serve only assets from dist directory
push @{app->static->paths}, app->home->child('dist', 'assets');

# Route for /assets/* to serve static files
get '/assets/*file' => sub {
    my $c = shift;
    my $file = $c->param('file');
    return $c->reply->static($file);
};

# Sample todo data (in production, use a database)
my @todos = (
  { id => 1, title => 'Learn Mojolicious', completed => 1 },
  { id => 2, title => 'Build with Inertia.js', completed => 0 },
  { id => 3, title => 'Deploy the app', completed => 0 },
);
my $next_id = 4;

get '/' => sub {
    my $c = shift;
    $c->inertia('Index', {});
};

get '/hello' => sub {
    my $c = shift;
    $c->inertia('Hello', {
        user => { name => 'Mojolicious' }
    });
};

# Todo routes
get '/todos' => sub {
    my $c = shift;
    $c->inertia('Todos/Index', {
        todos => \@todos,
        errors => {},
        values => {}
    });
};

get '/todos/:id' => sub {
    my $c = shift;
    my $id = $c->param('id');
    my ($todo) = grep { $_->{id} == $id } @todos;

    unless ($todo) {
        $c->res->code(404);
        return $c->inertia('Todos/Detail', {
            todo => undef,
            errors => {
                todo => 'Todo not found with ID: ' . $id
            }
        });
    }

    $c->inertia('Todos/Detail', {
        todo => $todo,
        errors => {}
    });
};

post '/todos' => sub {
    my $c = shift;
    my $json = $c->req->json;
    my $errors = {};

    unless ($json) {
        $errors->{request} = 'Invalid JSON request';
    }

    unless ($json->{title}) {
        $errors->{title} = 'Title is required';
    }

    if (length($json->{title} || '') > 100) {
        $errors->{title} = 'Title must be less than 100 characters';
    }

    if (keys %$errors) {
        $c->res->code(422);
        return $c->inertia('Todos/Index', {
            todos => \@todos,
            errors => $errors,
            values => $json || {}
        });
    }

    my $new_todo = {
        id => $next_id++,
        title => $json->{title},
        completed => $json->{completed} || 0
    };

    push @todos, $new_todo;

    $c->redirect_to('/todos');
};

post '/todos/:id' => sub {
    my $c = shift;
    my $id = $c->param('id');
    my $json = $c->req->json;
    my $errors = {};

    unless ($json) {
        $errors->{request} = 'Invalid JSON request';
    }

    my ($todo) = grep { $_->{id} == $id } @todos;
    unless ($todo) {
        $errors->{todo} = 'Todo not found with ID: ' . $id;
    }

    if ($json->{title} && length($json->{title}) > 100) {
        $errors->{title} = 'Title must be less than 100 characters';
    }

    if (keys %$errors) {
        $c->res->code($todo ? 422 : 404);
        return $c->inertia('Todos/Detail', {
            todo => $todo,
            errors => $errors,
            values => $json || {}
        });
    }

    $todo->{title} = $json->{title} if defined $json->{title};
    $todo->{completed} = $json->{completed} ? 1 : 0 if defined $json->{completed};

    $c->redirect_to('/todos');
};

# Dashboard with partial reload support
get '/dashboard' => sub {
    my $c = shift;

    # Load stats only if requested or if no partial data specified
    my $stats = sub {
        return {
            total_todos => scalar(@todos),
            completed_todos => scalar(grep { $_->{completed} == 1 } @todos),
            pending_todos => scalar(grep { $_->{completed} == 0 } @todos),
        };
    };

    # Load metrics only if requested or if no partial data specified
    my $metrics = sub {
        my $current_time = time();
        return {
            last_updated => scalar(localtime($current_time)),
            random_metric => int(rand(100)),
            server_load => sprintf("%.2f", rand(4)),
        };
    };

    # Load recent todos only if requested or if no partial data specified
    my $recent_todos = sub {
        return [ grep { defined } (reverse @todos)[0..2] ];
    };

    $c->inertia('Dashboard', {
        stats => $stats,
        metrics => $metrics,
        recent_todos => $recent_todos,
    });
};

app->start;
