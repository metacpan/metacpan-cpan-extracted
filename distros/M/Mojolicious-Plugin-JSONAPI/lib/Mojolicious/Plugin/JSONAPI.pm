package Mojolicious::Plugin::JSONAPI;
$Mojolicious::Plugin::JSONAPI::VERSION = '2.6';
use Mojo::Base 'Mojolicious::Plugin';

use JSONAPI::Document;
use Carp                  ();
use Lingua::EN::Inflexion ();

# ABSTRACT: Mojolicious Plugin for building JSON API compliant applications.

sub register {
    my ($self, $app, $args) = @_;
    $args ||= {};

    my %jsonapi_args;
    if (defined($args->{kebab_case_attrs})) {
        $jsonapi_args{kebab_case_attrs} = $args->{kebab_case_attrs};
    }
    if (defined($args->{namespace})) {

        # It's not really a JSONAPI::Document arg, but it's as close as
        # we'll get to defining a base URL at startup time.
        $jsonapi_args{namespace} = $args->{namespace};
    }

    # Detect application/vnd.api+json content type, fallback to application/json
    $app->types->type(json => ['application/vnd.api+json', 'application/json']);

    $self->create_route_helpers($app, $args->{namespace});
    $self->create_data_helpers($app,    {%jsonapi_args});
    $self->create_request_helpers($app, {%jsonapi_args});
    $self->create_error_helpers($app);
}

sub create_route_helpers {
    my ($self, $app, $namespace) = @_;

    my $DEV_MODE = $app->mode eq 'development';

    $app->helper(
        resource_routes => sub {
            my ($c, $spec) = @_;
            $spec->{resource} || Carp::confess('resource is a required param');
            $spec->{relationships} ||= [];
            my $http_verbs = $spec->{http_verbs} // ['get', 'post', 'patch', 'delete'];
            my @DEV_LOGS;

            my $resource          = Lingua::EN::Inflexion::noun($spec->{resource});
            my $resource_singular = $resource->singular;
            my $resource_plural   = $resource->plural;

            my $action_singular = $resource->singular;
            my $action_plural   = $resource->plural;
            $_ =~ s/-/_/g for ($action_singular, $action_plural);

            my $base_path = (!$spec->{router} && $namespace) ? "/$namespace/$resource_plural" : "/$resource_plural";
            my $router = $spec->{router} ? $spec->{router} : $app->routes;
            my $controller = $spec->{controller} || "api-$action_plural";

            my $r = $router->any($base_path)->to(controller => $controller);

            # use the allowed verbs to create the main resources routes.
            if (grep { $_ eq 'get' } @$http_verbs) {
                $r->get('/')->to(action => "fetch_${action_plural}");
                push @DEV_LOGS, "GET $base_path/ -> ${controller}#fetch_${action_plural}";
            }
            if (grep { $_ eq 'post' } @$http_verbs) {
                $r->post('/')->to(action => "post_${action_singular}");
                push @DEV_LOGS, "POST $base_path/ -> ${controller}#post_${action_singular}";
            }
            foreach my $method (grep { $_ =~ m/\A(?:get|patch|delete)\z/ } @$http_verbs) {
                $r->$method("/:${action_singular}_id")->to(action => "${method}_${action_singular}");
                push @DEV_LOGS,
                    uc($method) . " $base_path/:${action_singular}_id -> ${controller}#${method}_${action_singular}";
            }

            # Make routes that JSON API link URLs can point to.
            # Note that both self and related links point to the same action
            # because I think they're for the same purpose.
            foreach my $relationship (@{ $spec->{relationships} }) {
                my $path_for_self       = "/:${action_singular}_id/relationships/${relationship}";
                my $path_for_related    = "/:${action_singular}_id/${relationship}";
                my $relationship_action = $relationship;
                $relationship_action =~ s/-/_/g;
                foreach my $method (qw/get post patch delete/) {
                    push @DEV_LOGS,
                        uc($method)
                        . " ${base_path}${path_for_self} -> ${controller}#${method}_related_${relationship_action}";
                    push @DEV_LOGS,
                        uc($method)
                        . " ${base_path}${path_for_related} -> ${controller}#${method}_related_${relationship_action}";
                    $r->$method($path_for_self)->to(action => "${method}_related_${relationship_action}");
                    $r->$method($path_for_related)->to(action => "${method}_related_${relationship_action}");
                }
            }

            if ($DEV_MODE) {
                $app->log->debug('Created the following JSONAPI routes:');
                $app->log->debug("\n\t" . join("\n\t", @DEV_LOGS));
            }
        });
}

sub create_data_helpers {
    my ($self, $app, $args) = @_;

    my $namespace  = delete $args->{namespace} // '';
    my $api_path   = $namespace ? '/' . $namespace : '/';
    my $jsonapi_cb = sub {
        my ($c) = @_;
        my $api_url = $c->url_for($api_path)->to_abs;
        if ($api_url =~ m|/$|) {
            chop($api_url);
        }
        $args->{api_url} = $api_url;
        return JSONAPI::Document->new($args);
    };

    $app->helper(
        resource_document => sub {
            my ($c, $row, $options) = @_;
            return $jsonapi_cb->($c)->resource_document($row, $options);
        });

    $app->helper(
        compound_resource_document => sub {
            my ($c, $row, $options) = @_;
            return $jsonapi_cb->($c)->compound_resource_document($row, $options);
        });

    $app->helper(
        resource_documents => sub {
            my ($c, $resultset, $options) = @_;
            return $jsonapi_cb->($c)->resource_documents($resultset, $options);
        });
}

sub create_error_helpers {
    my ($self, $app) = @_;

    $app->helper(
        render_error => sub {
            my ($c, $status, $errors, $meta) = @_;

            unless (defined($errors) && ref($errors) eq 'ARRAY') {
                $errors = [{
                        status => $status || 500,
                        title  => $errors || 'Error processing request',
                    }];
            }

            return $c->render(
                status => $status || 500,
                json => {
                    errors => $errors,
                    ($meta ? (meta => $meta) : ()),
                });
        });
}

sub create_request_helpers {
    my ($self, $app, $args) = @_;

    my $namespace = $args->{namespace} // '';

    $app->helper(
        requested_resources => sub {
            my ($c) = @_;
            my $param = $c->param('include') // '';
            $param =~ s/-/_/g;
            my @include = split(',', $param);
            my @relationships;
            foreach my $inc (@include) {
                if ($inc =~ m/\./g) {
                    my @nested = split(/\./, $inc);
                    push @relationships, { shift @nested => [shift @nested] };
                } else {
                    push @relationships, $inc;
                }
            }
            return \@relationships;
        });

    $app->helper(
        requested_fields => sub {
            my ($c) = @_;

            my $params_ref = $c->tx->req->query_params->to_hash;
            unless (%$params_ref) {
                return {};
            }

            my %fields = map {
                my $orig = $_;
                $orig =~ m/\[(\w+)\]/;
                ($1 => [split(',', $params_ref->{$_})])
            } grep {
                $_ =~ m/^fields\[/
            } keys(%$params_ref);

            my $path          = $c->tx->req->url->path;
            my $main_resource = $path->parts->[0];
            if ($namespace) {
                my $idx = split('/', $namespace) - 1;
                $main_resource = $path->parts->[$idx + 1];
            }

            if ($main_resource) {
                return {
                    fields => delete($fields{$main_resource}),
                    %fields ? (related_fields => \%fields) : (),
                };
            }

            return { related_fields => \%fields };
        });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::JSONAPI - Mojolicious Plugin for building JSON API compliant applications

=head1 VERSION

version 2.6

=head1 SYNOPSIS

    # Mojolicious

    # Using route helpers

    sub startup {
        my ($self) = @_;

        $self->plugin('JSONAPI', {
            namespace => 'api',
            kebab_case_attrs => 1,
        });

        $self->resource_routes({
            resource => 'post',
            relationships => ['author', 'comments', 'email-templates'],
        });

        # Now the following routes are available:

        # GET '/api/posts' -> to('api-posts#fetch_posts')
        # POST '/api/posts' -> to('api-posts#post_posts')
        # GET '/api/posts/:post_id -> to('api-posts#get_post')
        # PATCH '/api/posts/:post_id -> to('api-posts#patch_post')
        # DELETE '/api/posts/:post_id -> to('api-posts#delete_post')

        # GET '/api/posts/:post_id/relationships/author' -> to('api-posts#get_related_author')
        # POST '/api/posts/:post_id/relationships/author' -> to('api-posts#post_related_author')
        # PATCH '/api/posts/:post_id/relationships/author' -> to('api-posts#patch_related_author')
        # DELETE '/api/posts/:post_id/relationships/author' -> to('api-posts#delete_related_author')

        # GET '/api/posts/:post_id/relationships/comments' -> to('api-posts#get_related_comments')
        # POST '/api/posts/:post_id/relationships/comments' -> to('api-posts#post_related_comments')
        # PATCH '/api/posts/:post_id/relationships/comments' -> to('api-posts#patch_related_comments')
        # DELETE '/api/posts/:post_id/relationships/comments' -> to('api-posts#delete_related_comments')

        # GET '/api/posts/:post_id/relationships/email-templates' -> to('api-posts#get_related_email_templates')
        # POST '/api/posts/:post_id/relationships/email-templates' -> to('api-posts#post_related_email_templates')
        # PATCH '/api/posts/:post_id/relationships/email-templates' -> to('api-posts#patch_related_email_templates')
        # DELETE '/api/posts/:post_id/relationships/email-templates' -> to('api-posts#delete_related_email_templates')

        # If you're in development mode (e.g. MOJO_MODE eq 'development'), your $app->log will show the created routes. Useful!

        # You can use the following helpers too:

        $self->resource_document($dbic_row, $options);

        $self->compound_resource_document($dbic_row, $options);

        $self->resource_documents($dbic_resultset, $options);
    }

=head1 DESCRIPTION

This module intends to supply the user with helper methods that can be used to build a JSON API
compliant API using Mojolicious. It helps create routes for your resources that conform with the
specification, along with supplying helper methods to use when responding to requests.

See L<http://jsonapi.org/> for the JSON API specification. At the time of writing, the version was 1.0.

=head1 OPTIONS

=over

=item C<namespace>

The prefix that's added to all routes, defaults to 'api'. You can also provided an empty string as the namespace,
meaning no prefix will be added.

=item C<kebab_case_attrs>

This is passed to the constructor of C<JSONAPI::Document> which will kebab case the attribute keys of each
record (i.e. '_' to '-').

=back

=head1 HELPERS

=head2 resource_routes(I<HashRef> $spec)

Creates a set of routes for the given resource. C<$spec> is a hash reference that can consist of the following:

    {
        resource        => 'post', # name of resource, required
        controller      => 'api-posts', # name of controller, defaults to "api-{resource_plural}"
        relationships   => ['author', 'comments'], # default is []
        http_verbs      => ['get', 'post'], # default is ['get', 'post', 'patch', 'delete']
    }

=over

=item C<resource I<Str>>

The resources name. Should be a singular noun, which will be turned into it's pluralised
version (e.g. "post" -> "posts") automatically where necessary.

=item C<controller I<Str>>

The controller name where the actions are to be stored. Defaults to C<api-{resource}>, where
resource is in its pluralised form.

Routes will point to controller actions, the names of which follow the pattern C<{http_method}_{resource}>, with
dashes replaced with underscores (i.e. 'email-templates' -> 'email_templates').

=item C<router I<Mojolicious::Routes>>

The parent route to use for the resource. Optional.

Provide your own router if you plan to use L<under|http://mojolicious.org/perldoc/Mojolicious/Routes/Route#under>
for your resource.

B<NOTE>: Providing your own router assumes that the router is under the same namespace already, so the resource
routes won't specify the namespace themselves.

Usage:

 my $under_api = $r->under('/api')->to('OAuth#is_authenticated');
 $self->resource_routes({
     router => $under_api,
     resource => 'post',
 });

=item C<relationships I<ArrayRef>>

The relationships belonging to the resource. Defaults to an empty array ref.

Specifying C<relationships> will create additional routes that fall under the resource. These
can then be used to reference L<self|https://jsonapi.org/format/#document-resource-object-relationships>
I<or> L<related|https://jsonapi.org/format/#document-resource-object-related-resource-links> routes, as
both will point to the same controller action i.e. C</api/posts/1/relationships/author> and
C</api/posts/1/author> will go to C<Api::Posts::{http_method}_related_author>. This is because in my
opinion they're different routes with the same purpose, which is to action on the related resource.

B<NOTE>: Your relationships should be in the correct form (singular/plural) based on the relationship in your
schema management system. For example, if you have a resource called 'post' and it has many 'comments', make
sure comments is passed in as a plural noun here.

=item C<http_verbs I<ArrayRef>>

The HTTP verbs/methods to use when creating the resources routes. Defaults to C<GET>, C<POST>, C<PATCH> and C<DELETE>, where
C<GET> is both for the collection route as well as the single resource route (e.g. C</api/authors> and C</api/authors/:author_id>).

Specifying this will not, if provided, affect the relationship routes that will be created. Those will have routes created for
all verbs regardless.

=back

=head2 render_error(I<Str> $status, I<ArrayRef|Str> $errors, I<HashRef> $meta?)

Renders a JSON response under the required top-level C<errors> key. C<errors> should be an array reference of error objects
as described in the specification, or a string that will be the content of I<title>.
See L<Error Objects|http://jsonapi.org/format/#error-objects>.

Can optionally provide meta information, which will be added to the response as-is.

=head2 requested_resources

Convenience helper for controllers. Takes the query param C<include>, used to indicate what relationships to include in the
response, and splits it by ',' to return an ArrayRef.

 GET /api/posts?include=comments,author
 my $include = $c->requested_resources(); # ['comments', 'author']

Can also include nested relationships:

 GET /api/posts?include=comments,author.notes
 my $include = $c->requested_resources(); # ['comments', { author => ['notes'] }]

B<NOTE>: Only one level of nesting is supported at the moment, so requests like C<author.notes.notes_relation> won't
give back what you expect. Stick with C<author.notes> and lazy loading C<notes_relation>.

=head2 requested_fields

Takes each query param C<fields[TYPE]> and creates a HashRef containing all its requested fields along with
any relationship fields. This is useful if you only want to return a subset of attributes for a resource.

The HashRef produced is suitable to pass directly to the options of C<JSONAPI::Document::resource_document>.

Included fields should be direct attributes of the resource, not its relationships. See C<requested_resources>
for that use case.

The main resource should be in the plural form inside the param (i.e. 'posts', not 'post'), and related resources
in their correct form.

 GET /api/posts?fields[posts]=slug,title&fields[comments]=likes&fields[author]=name,email

 my $fields = $c->requested_fields();

 # Out:
 {
    fields => ['slug', 'title'],
    related_fields => {
        comments => ['likes'],
        author => ['name', 'email']
    }
 }

=head2 resource_document

Available in controllers:

 $c->resource_document($dbix_row, $options);

See L<resource_document|https://metacpan.org/pod/JSONAPI::Document#resource_document(DBIx::Class::Row-$row,-HashRef-$options)> for usage.

=head2 compound_resource_document

Available in controllers:

 $c->compound_resource_document($dbix_row, $options);

See L<compound_resource_document|https://metacpan.org/pod/JSONAPI::Document#compound_resource_document(DBIx::Class::Row-$row,-HashRef-$options)> for usage.

=head2 resource_documents

Available in controllers:

 $c->resource_documents($dbix_resultset, $options);

See L<resource_documents|https://metacpan.org/pod/JSONAPI::Document#resource_documents(DBIx::Class::Row-$row,-HashRef-$options)> for usage.

=head1 TODO

=over

=item *

Allow specifying C<http_verbs> in the C<resource_routes> helper for relationships.

=back

=head1 LICENSE

This code is available under the Perl 5 License.

=cut
