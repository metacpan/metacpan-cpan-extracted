package Mojolicious::Plugin::ModeHelpers;
use Mojo::Base 'Mojolicious::Plugin';
use Carp       ();
use Mojo::Util ();

our $VERSION = '0.04';

sub register {
	my (undef, $app, $config) = @_;
	$config = {
        prod_helper_name => 'in_prod',
        dev_helper_name => 'in_dev',
        modes => [],
        %$config,
    };

    my %config_copy = %$config;
    delete @config_copy{qw(prod_helper_name dev_helper_name modes)};
    Carp::croak "Unknown config options provided: @{[join ', ', sort keys %config_copy]}" if %config_copy;

    if (not defined $config->{prod_helper_name} or $config->{prod_helper_name} eq '') {
        Carp::croak 'prod_helper_name must not be empty';
    }
    if (not defined $config->{dev_helper_name} or $config->{dev_helper_name} eq '') {
        Carp::croak 'dev_helper_name must not be empty';
    }

    $app->helper($config->{prod_helper_name} => sub {
        state $in_prod = $_[0]->app->mode eq 'production';
    });

    $app->helper($config->{dev_helper_name} => sub {
        state $in_dev = $_[0]->app->mode ne 'production';
    });

    my $modes = $config->{modes};
    Carp::croak 'modes must be an arrayref' unless ref $modes eq 'ARRAY';

    for my $mode (@$modes) {
        my $helper_name;
        my $mode_ref = ref $mode;
        if (not $mode_ref) {
            Carp::croak 'empty value for mode' unless defined $mode and $mode ne '';
            $helper_name = Mojo::Util::slugify($mode);
            $helper_name =~ tr/-/_/;
            $helper_name = "in_$helper_name";
        } elsif ($mode_ref eq 'HASH') {
            Carp::croak 'helper name and mode pair must be a hashref with exactly one key and one value'
                unless keys %$mode == 1;

            ($helper_name, $mode) = (keys %$mode, values %$mode);
            Carp::croak 'empty value for helper name in key-value pair' unless defined $helper_name and $helper_name ne '';
            Carp::croak 'empty value for mode in key-value pair' unless defined $mode and $mode ne '';
        } else {
            Carp::croak 'mode must be a scalar (valid subroutine name) or a hashref with one key-value pair';
        }

        $app->helper($helper_name => sub {
            state $in_mode = $_[0]->app->mode eq $mode;
        });
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::ModeHelpers - Mojolicious Plugin that adds helpers to determine the mode and avoid typos

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojolicious-Plugin-ModeHelpers"><img src="https://travis-ci.org/srchulo/Mojolicious-Plugin-ModeHelpers.svg?branch=master"></a>

=head1 SYNOPSIS

  use Mojolicious::Lite;
  plugin 'ModeHelpers';

  if (app->in_prod) { # true if app->mode eq 'production'
    # do prod stuff
  } elsif (app->in_dev) { # true if app->mode ne 'production'
    # do dev stuff
  }

  # rename in_prod and in_dev
  plugin ModeHelpers => { prod_helper_name => 'in_production_mode', dev_helper_name => 'in_development_mode' };
  if (app->in_production_mode) { # true if app->mode eq 'production'
    # do prod stuff
  } elsif (app->in_development_mode) { # true if app->mode ne 'production'
    # do dev stuff
  }

  # provide your own custom modes to generate helpers
  plugin ModeHelpers => { modes => ['alpha', 'beta'] };
  if (app->in_alpha) { # true if app->mode eq 'alpha'
    # do alpha stuff
  } elsif (app->in_beta) { # true if app->mode eq 'beta'
    # do beta stuff
  }

  # weird modes get valid perl subroutine names
  plugin ModeHelpers => { modes => ['my strange mode!'] };
  if (app->in_my_strange_mode) { # true if app->mode eq 'my strange mode!'
    # do strange things
  }

  # provide your own helper name and mode pairs
  plugin ModeHelpers => { modes => [{ in_alpha_mode => 'alpha' }, 'beta'] };
  if (app->in_alpha_mode) { # true if app->mode eq 'alpha'
    # do alpha stuff
  } elsif (app->in_beta) { # true if app->mode eq 'beta'
    # do beta stuff
  }

  # use Mojolicious helper dot notation
  plugin ModeHelpers => {
    prod_helper_name => 'modes.prod',
    dev_helper_name => 'modes.dev',
    modes => [{ 'modes.alpha' => 'alpha' }]
  };

  if (app->modes->prod) { # true if app->mode eq 'production'
    # do prod stuff
  }
  if (app->modes->dev) { # true if app->mode ne 'production'
    # do dev stuff
  }

  if (app->modes->alpha) { # true if app->mode eq 'alpha'
    # do alpha stuff
  }

=head1 DESCRIPTION

L<Mojolicious::Plugin::ModeHelpers> is a L<Mojolicious::Plugin> that adds helpers so that you can know what mode
you are in via a method call instead of comparing to the string returned by L<Mojolicious/mode>. This can help with typos, and
is often more compact. You may use the built-in L</in_prod> and L</in_dev> methods, or you can add helpers for your custom L</modes>.

=head1 METHODS

=head2 in_prod

Returns true if L<Mojolicious/mode> is C<production>. Otherwise, returns false.

  if (app->in_prod) { # true if app->mode eq 'production'
    # do prod stuff
  }

L</in_prod> can be renamed via L</prod_helper_name>.

=head2 in_dev

Returns true if L<Mojolicious/mode> does not equal C<production>. Otherwise, returns false.

  if (app->in_dev) { # true if app->mode ne 'production'
    # do dev stuff
  }

L</in_dev> can be renamed via L</dev_helper_name>.

=head2 register

  my $config = $plugin->register($app);
  my $config = $plugin->register($app, { modes => ['alpha', 'beta', 'gamma'] });

Register plugin in L<Mojolicious> application and create helpers.

=head1 OPTIONS

=head2 prod_helper_name

L</prod_helper_name> allows you to change the name of the L</in_prod> helper:

  plugin ModeHelpers => { prod_helper_name => 'in_production_mode' };

  if (app->in_production_mode) { # true if app->mode eq 'production'
    # do prod stuff
  }

You can also use the L<Mojolicious/helper> dot notation:

  plugin ModeHelpers => { prod_helper_name => 'modes.prod' };

  if (app->modes->prod) {
    # do prod stuff
  }

=head2 dev_helper_name

L</dev_helper_name> allows you to change the name of the L</in_dev> helper:

  plugin ModeHelpers => { dev_helper_name => 'in_development_mode' };

  if (app->in_development_mode) { # true if app->mode ne 'production'
    # do dev stuff
  }

You can also use the L<Mojolicious/helper> dot notation:

  plugin ModeHelpers => { dev_helper_name => 'modes.dev' };

  if (app->modes->dev) {
    # do dev stuff
  }

=head2 mode

L</modes> allows you to pass in custom modes that will have their own helpers that return true
if L<Mojolicious/mode> equals their mode. Modes can either be a non-empty scalar, or a hash that has
a key-value pair of helper_name => mode.

  plugin ModeHelpers => {
    modes => [
      'alpha', # generates helper in_alpha for mode 'alpha'
      { in_beta_mode => 'beta' }, # generates helper in_beta_mode for mode 'beta'
      'my strange mode!', # generates helper in_my_strange_mode for mode 'my strange mode!'
    ],
  };

  if (app->in_alpha) { # true if app->mode eq 'alpha'
    # do alpha stuff
  } elsif (app->in_beta_mode) { # true if app->mode eq 'beta'
    # do beta stuff
  } elsif (app->in_my_strange_mode) { # true if app->mode eq 'my strange mode!'
    # do strange things
  }

=head3 SCALAR

Non-empty strings can be passed into L</modes>. The helper name is generated with these steps:

=over

=item

Pass the mode to L<Mojo::Util/slugify>.

=item

Replace all dashes with underscores.

=item

Append the resulting value to the string "in_".

=back

  plugin ModeHelpers => { modes => ['alpha', 'my strange mode!'] };

  if (app->in_alpha) { # true if app->mode eq 'alpha'
    # do alpha stuff
  } elsif (app->in_my_strange_mode) { # true if app->mode eq 'my strange mode!'
    # do strange things
  }

=head3 HASH

A key-value pair can be provided as a hash, where the key is the helper name and the value is the mode.

  plugin ModeHelpers => { modes => [ { in_alpha_mode => 'alpha' } ] };

  if (app->in_alpha_mode) { # true if app->mode eq 'alpha'
    # do alpha stuff
  }

You can also use the L<Mojolicious/helper> dot notation:

  plugin ModeHelpers => { modes => [ { 'modes.alpha' => 'alpha' } ] };

  if (app->modes->alpha) { # true if app->mode eq 'alpha'
    # do alpha stuff
  }

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Adam Hopkins

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
