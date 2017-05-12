package Mojolicious::Plugin::ExposeControllerMethod;
use Mojo::Base 'Mojolicious::Plugin';

use Mojolicious::Plugin::ExposeControllerMethod::Proxy;

our $VERSION = '1.000001';
my $PROXY_BASE_CLASS = 'Mojolicious::Plugin::ExposeControllerMethod::Proxy';

sub register {
    my ( $self, $app ) = @_;

    $app->helper(
        'ctrl',
        sub {
            my $c = shift;

            my $proxy_class = $PROXY_BASE_CLASS . '::' . ref $c;
            my $isa_name    = $proxy_class . '::ISA';
            {
                ## no critic (TestingAndDebugging::ProhibitNoStrict)
                no strict 'refs';
                *{$isa_name} = [$PROXY_BASE_CLASS]
                    ## use critic
            }

            return bless \$c, $proxy_class;
        }
    );

    return;
}

1;

=head1 NAME

Mojolicious::Plugin::ExposeControllerMethod - expose controller method

=head1 SYNOPSIS

    # in your app
    $app->plugin('ExposeControllerMethod');

    # Then in a template:
    Hi <%= ctrl->name %>

=head1 DESCRIPTION

This module is for advanced use.  C<$c>/C<$self> are already made available in
templates and are likely sufficient for the majority of use cases.  This module
was created in order to expose L<Moose> attributes in a way where you don't
have to stash them every single time you want to use them.

This module exposes I<selected> methods from the current controller to
Mojolicious templates via the C<ctrl> helper.

In order to expose methods to Mojolicious templates your controller must
implement the C<controller_method_name> method which will be passed the name of
the method Mojolicious wishes to call on the controller.  This method should
return either false (if the method cannot be called), or the name the method
that should be called ( which is probably the same as the name of the method
passed in.)

For example:

  package MyApp::Controller::Example;
  use Mojo::Base 'Mojolicious::Controller';

  sub name           { return "Mark Fowler" }
  sub any_other_name { return "Still smells sweet" }
  sub reverse        { my $self = shift; return scalar reverse join '', @_ }

  sub controller_method_name {
      my $self = shift;
      my $what = shift;

      return $what if $what =~ /\A(test1|reverse)\z/;
      return 'any_other_name' if $what eq 'rose';
      return;
  }

  ...

The results of C<controller_method_name> are expected to be consistent for
a given Mojolicious Controller class for a given method name (this module
is optimized on this assumption, caching method name calculations.)

=head1 SUPPORT

Please report all issues with this code using the GitHub issue tracker at
L<https://github.com/maxmind/Mojolicious-Plugin-ExposeControllerMethod/issues>.

=head1 SEE ALSO

L<MooseX::MojoControllerExposingAttributes> - uses this mechanism to expose
attributes marked with a trait from Moose Mojolicious controllers

L<Mojolicious>
