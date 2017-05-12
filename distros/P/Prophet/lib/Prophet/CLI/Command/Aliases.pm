package Prophet::CLI::Command::Aliases;
{
  $Prophet::CLI::Command::Aliases::VERSION = '0.751';
}
use Any::Moose;
use Params::Validate qw/validate/;

extends 'Prophet::CLI::Command::Config';

sub ARG_TRANSLATIONS { shift->SUPER::ARG_TRANSLATIONS(), s => 'show' }

sub usage_msg {
    my $self = shift;
    my $cmd  = $self->cli->get_script_name;

    return <<"END_USAGE";
usage: ${cmd}aliases [show]
       ${cmd}aliases edit [--global|--user]
       ${cmd}alias <alias text> [<text to translate to>]
END_USAGE
}

sub run {
    my $self = shift;

    $self->print_usage if $self->has_arg('h');

    my $config = $self->config;

    my $template = $self->make_template;

    # alias.pull --from http://foo-bar.com/
    # add is the same as set
    if ( $self->context->has_arg('add') && !$self->has_arg('set') ) {
        $self->context->set_arg( 'set', $self->arg('add') );
    }

    if (
        !(
               $self->has_arg('set')
            || $self->has_arg('delete')
            || $self->has_arg('edit')
        )
      )
    {
        print $template. "\n";
        return;
    } else {
        $self->set_arg( 'set', 'alias.' . $self->arg('set') )
          if $self->has_arg('set');
        $self->set_arg( 'delete', 'alias.' . $self->arg('delete') )
          if $self->has_arg('delete');
        $self->SUPER::run(@_);
    }
}

sub make_template {
    my $self = shift;

    my $content = '';

    $content .=
      $self->context->has_arg('edit')
      ? "# Editing aliases in config file "
      . $self->config_filename . "\n\n"
      . "# Format: new_cmd = cmd\n"
      : "Active aliases for the current repository (including user-wide and"
      . " global\naliases if not overridden):\n\n";

    # get aliases from the config file we're going to edit, or all of them if
    # we're just displaying
    my $aliases =
        $self->has_arg('edit')
      ? $self->app_handle->config->aliases( $self->config_filename )
      : $self->app_handle->config->aliases;

    if (%$aliases) {
        for my $key ( keys %$aliases ) {
            $content .= "$key = $aliases->{$key}\n";
        }
    } elsif ( !$self->has_arg('edit') ) {
        $content = "No aliases for the current repository.\n";
    }

    return $content;
}

sub parse_template {
    my $self     = shift;
    my $template = shift;

    my %parsed;
    for my $line ( split( /\n/, $template ) ) {
        if ( $line =~ /^\s*([^#].*?)\s*=\s*(.+?)\s*$/ ) {
            $parsed{$1} = $2;
        }
    }

    return \%parsed;
}

sub process_template {
    my $self = shift;
    my %args = validate( @_, { template => 1, edited => 1, record => 0 } );

    my $updated = $args{edited};
    my ($config) = $self->parse_template($updated);

    my $aliases = $self->app_handle->config->aliases( $self->config_filename );
    my $c       = $self->app_handle->config;

    my @added = grep { !$aliases->{$_} } sort keys %$config;

    my @changed =
      grep { $config->{$_} && $aliases->{$_} ne $config->{$_} }
      sort keys %$aliases;

    my @deleted = grep { !$config->{$_} } sort keys %$aliases;

    # attempt to set all added/changed/deleted aliases at once
    my @to_set = (
        (
            map { { key => "alias.'$_'", value => $config->{$_} } }
              ( @added, @changed )
        ),
        ( map { { key => "alias.'$_'" } } @deleted ),
    );

    eval { $c->group_set( $self->config_filename, \@to_set, ); };

    # if we fail, prompt the user to re-edit
    #
    # one of the few ways to trigger this is to try to create an alias
    # that starts with a [ character
    if ($@) {
        chomp $@;
        my $error = "# Error: '$@'";
        $self->handle_template_errors(
            rtype          => 'aliases',
            template_ref   => $args{template},
            bad_template   => $args{edited},
            errors_pattern => '',
            error          => $error,
            old_errors     => $self->old_errors,
        );
        $self->old_errors($error);
        return 0;
    }

    # otherwise, print out what changed and return happily
    else {
        for my $add (@added) {
            print 'Added alias ' . "'$add' = '$config->{$add}'\n";
        }
        for my $change (@changed) {
            print "Changed alias '$change' from '$aliases->{$change}'"
              . "to '$config->{$change}'\n";
        }
        for my $delete (@deleted) {
            print "Deleted alias '$delete'\n";
        }

        return 1;
    }
}

# override the messages from Config module with messages w/better context for
# Aliases
override delete_usage_msg => sub {
    my $self    = shift;
    my $app_cmd = $self->cli->get_script_name;
    my $cmd     = shift;

    qq{usage: ${app_cmd}${cmd} "alias text"\n};
};

override add_usage_msg => sub {
    my $self    = shift;
    my $app_cmd = $self->cli->get_script_name;
    my ( $cmd, $subcmd ) = @_;

    qq{usage: ${app_cmd}$cmd $subcmd "alias text" "cmd to translate to"\n};
};

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::CLI::Command::Aliases

=head1 VERSION

version 0.751

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
