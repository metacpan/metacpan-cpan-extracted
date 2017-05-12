package Prophet::CLI::Command::Settings;
{
  $Prophet::CLI::Command::Settings::VERSION = '0.751';
}
use Any::Moose;
use Params::Validate qw/validate/;
use JSON;

extends 'Prophet::CLI::Command';
with 'Prophet::CLI::TextEditorCommand';

sub ARG_TRANSLATIONS { shift->SUPER::ARG_TRANSLATIONS(), s => 'show' }

sub usage_msg {
    my $self = shift;
    my $cmd  = $self->cli->get_script_name;

    return <<"END_USAGE";
usage: ${cmd}settings [show]
       ${cmd}settings edit
       ${cmd}settings set -- setting "new value"

Note that setting values must be valid JSON.
END_USAGE
}

sub run {
    my $self = shift;

    $self->print_usage if $self->has_arg('h');

    my $settings = $self->app_handle->database_settings;

    my $template = $self->make_template;

    if ( $self->has_arg('edit') ) {
        my $done = 0;

        while ( !$done ) {
            Prophet::CLI->end_pager();
            $done = $self->try_to_edit( template => \$template );
        }
    } elsif ( $self->context->has_arg('set') ) {
        for my $name ( $self->context->prop_names ) {
            my $uuid;
            if ( $settings->{$name} ) {
                $uuid = $settings->{$name}->[0];
            } else {
                print "Setting \"$name\" does not exist, skipping.\n";
                next;
            }
            my $s         = $self->app_handle->setting( uuid => $uuid );
            my $old_value = $s->get_raw;
            my $new_value = $self->context->props->{$name};
            print "Trying to change " . $name
              . " from $old_value to $new_value.\n";
            if ( $old_value ne $new_value ) {
                $s->set( from_json( $new_value, { utf8 => 1 } ) );
                print " -> Changed.\n";
            } else {
                print " -> No change needed.\n";
            }
        }
        return;
    } else {
        print $template. "\n";
        return;
    }
}

sub make_template {
    my $self = shift;

    my $content = '';

    # get all settings records (the defaults, not the
    # ones in the DB) -- current values from the DB are retrieved in
    # _make_template_entry)
    my $settings = $self->app_handle->database_settings;
    for my $name ( keys %$settings ) {
        my @metadata = @{ $settings->{$name} };
        my $s        = $self->app_handle->setting(
            label   => $name,
            uuid    => ( shift @metadata ),
            default => [@metadata]
        );

        $content .= $self->_make_template_entry($s) . "\n\n";

    }

    return $content;
}

sub _make_template_entry {
    my $self    = shift;
    my $setting = shift;

    # format each settings record as
    #
    #  # uuid: uuid
    #  key: value, value, value
    #

    return "# uuid: " . $setting->uuid . "\n" . $setting->label . ": "

      # this is what does the actual loading of settings
      # in the database to override the defaults
      . to_json( $setting->get,
        { canonical => 1, pretty => 0, utf8 => 1, allow_nonref => 0 } );

}

sub parse_template {
    my $self     = shift;
    my $template = shift;

    my $uuid = 'NONE';
    my %content;
    my %parsed;
    for my $line ( split( /\n/, $template ) ) {
        if ( $line =~ /^\s*\#\s*uuid\:\s*(.*?)\s*$/ ) {
            $uuid = $1;
        } else {
            push @{ $content{$uuid} }, $line;
        }

    }

    for my $uuid ( keys %content ) {
        my $data = join( "\n", @{ $content{$uuid} } );
        if ( $data =~ /^(.*?)\s*:\s*(.*)\s*$/ms ) {
            my $label   = $1;
            my $content = $2;
            $parsed{$uuid} = [ $label, $content ];
        }
    }

    return \%parsed;
}

sub process_template {
    my $self = shift;
    my %args = validate( @_, { template => 1, edited => 1, record => 0 } );

    my $updated = $args{edited};
    my ($config) = $self->parse_template($updated);

    no warnings 'uninitialized';
    my $settings = $self->app_handle->database_settings;
    my %settings_by_uuid =
      map { uc( $settings->{$_}->[0] ) => $_ } keys %$settings;

    my $settings_changed = 0;

    for my $uuid ( keys %$config ) {

        # the parsed template could conceivably contain nonexistent uuids
        my $s;
        if ( $settings_by_uuid{ uc($uuid) } ) {
            $s = $self->app_handle->setting( uuid => $uuid );
        } else {
            print "Setting with uuid \"$uuid\" does not exist.\n";
            next;
        }
        my $old_value = $s->get_raw;
        my $new_value = $config->{$uuid}->[1];
        chomp $new_value;
        if ( $old_value ne $new_value ) {
            eval {
                $s->set( from_json( $new_value, { utf8 => 1 } ) );
                print "Changed "
                  . $config->{$uuid}->[0]
                  . " from $old_value to $new_value.\n";
                $settings_changed++;
            };
            if ($@) {

                # error parsing the JSON
                print 'An error occured setting '
                  . $settings_by_uuid{$uuid}
                  . " to $new_value: $@";
            }
        }

    }
    print "No settings changed.\n" unless $settings_changed;
    return 1;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::CLI::Command::Settings

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
