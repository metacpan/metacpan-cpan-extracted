package REST::Application::Routes;
use strict;
use warnings;
use base 'REST::Application';

our $VERSION = $REST::Application::VERSION;

sub loadResource {
    my ($self, $path, @extraArgs) = @_;
    $path ||= $self->getMatchText();
    my $handler = sub { $self->defaultResourceHandler(@_) };
    my %vars;

    # Loop through the keys of the hash returned by resourceHooks().  Each of
    # the keys is a URI template, see if the current path info matches that
    # template.  Save the parent matches for passing into the handler.
    for my $template (keys %{ $self->resourceHooks() }) {
        my $regex = join "\\/",
                    map {/^:/ ? '([^\/]+)' : quotemeta $_}
                    split m{/}, $template;
        $regex = "^(?:$regex)\\/?\$";
        if ($self->checkMatch($path, $regex)) {
            $self->{__last_match_pattern} = $template;
            %vars = $self->getTemplateVars($template);
            $handler = $self->_getHandlerFromHook($template);
            last;
        }
    }

    return $self->callHandler($handler, \%vars, @extraArgs);
}

sub getHandlerArgs {
    my ($self, @extraArgs) = @_;
    my @args = ($self, @extraArgs, $self->extraHandlerArgs());

    # Don't make $self the first argument if the handler is a method on $self,
    # because in that case it'd be redundant.  Also see _getHandlerFromHook().
    shift @args if $self->{__handlerIsOurMethod};

    return @args;
}

sub _get_template_vars {
    my $self = shift;
    return $self->getTemplateVars(@_);
}

sub getTemplateVars {
    my ($self, $route) = @_;
    my @matches = $self->_getLastRegexMatches();
    my @vars = map {s/^://; $_} grep /^:/, split m{/}, $route;
    return map { $vars[$_] => $matches[$_] } (0 .. scalar(@matches)-1);
}

sub getLastMatchTemplate {
    my $self = shift;
    return $self->getLastMatchPattern();
}

1;
__END__

=head1 NAME

REST::Application::Routes - An implementation of Ruby on Rails type routes.

=head1 SYNOPSIS

    package MyApp;
    use base 'REST::Application::Routes';

    my $obj = REST::Application::Routes->new();
    $obj->loadResource(
        '/data/workspaces/:ws/pages/:page', => \&do_thing,
        # ... other routes here ...
    );

    sub do_thing {
        my %vars = @_;
        print $vars{ws} . " " . $vars{page} . "\n";
    }

    # Now, in some other place.  Maybe a CGI file or an Apache handler, do:
    use MyApp;
    MyApp->new->run("/data/workspaces/cows/pages/good"); # prints "cows good"

=head1 DESCRIPTION

Ruby on Rails has this concept of routes.  Routes are URI path info templates
which are tied to specific code (i.e. Controllers and Actions in Rails).  That
is routes consist of key value pairs, called the route map, where the key is
the path info template and the value is a code reference.

A template is of the form: C</foo/:variable/bar> where variables are always
prefaced with a colon.  When a given path is passed to C<run()> the code
reference which the template maps to will be passed a hash where the keys are
the variable names (sans colon) and the values are what was specified in place
of the variables.

The route map is ordered, so the most specific matching template is used and
so you should order your templates from least generic to most generic.

See L<REST::Application> for details.  The only difference between this module
and that one is that this one uses URI templates as keys in the
C<resourceHooks> rather than regexes.

=head1 METHODS

These are methods which L<REST::Application::Routes> has but its superclass
does not.

=head2 getTemplateVars()

Returns a hash whose keys are the C<:symbols> from the URI template and whose
values are what where matched to be there.  It is assumed that this method is
called either from within or after C<loadResource()> is called.  Otherwise
you're likely to get an empty hash back.

=head2 getLastMatchTemplate()

This is an alias for C<getLastMatchPattern()>, since this class is about
templates rather than regexes.

=head1 AUTHORS

Matthew O'Connor E<lt>matthew@canonical.orgE<gt>

=head1 LICENSE

This program is free software. It is subject to the same license as Perl itself.

=head1 SEE ALSO

L<REST::Application>, L<http://manuals.rubyonrails.com/read/chapter/65>

=cut
