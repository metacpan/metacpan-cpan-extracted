package Mojolicious::Plugin::Restify::OtherActions;

use Mojo::Base 'Mojolicious::Plugin::Restify';

sub register() {
    my $s = shift;
    my ($app, $conf) = @_;
    $s->SUPER::register(@_);
    my $original_code = $app->routes->shortcuts->{collection};
    $app->routes->add_shortcut(
        # replace original shortcut
        collection => sub {
            my $coll    = $original_code->(@_);
            my $r       = shift;
            my $path    = shift;
            my $options = ref $_[0] eq 'HASH' ? shift : {@_};
            my $rname   = $options->{route_name};
            my $or      = $r->find($rname);
            if ($or->to_string =~ /:${rname}_id/) {
                # M::P::Restify give same name to /accounts and /accounts/:accounts_id
                # if I'm here my proposed patch
                # https://github.com/kwakwaversal/mojolicious-plugin-restify/pull/19
                # has not been still accepted, so I rename :accounts_id route
                $or->name("${rname}_id");
                # and find route again to match /accounts
                $or      = $r->find("$options->{route_name}")
            }
            $or->get("list/:query/*opt")->to(action => 'list',
                opt => undef)->name($options->{route_name} . "_otheractions");
            return $coll;

        }
    );
}

1;

=pod

=head1 NAME

Mojolicious::Plugin::Restify::OtherActions - Mojolicious plug-in which extends Restify with more actions

=for html <p><img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/EmilianoBruni/Mojolicious-Plugin-Restify-OtherActions?style=plastic"> <a href="https://travis-ci.com/EmilianoBruni/mojolicious-plugin-mongodbv2"><img alt="Travis tests" src="https://img.shields.io/travis/com/EmilianoBruni/Mojolicious-Plugin-Restify-OtherActions?label=Travis%20tests&style=plastic"></a></p>

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    plugin 'Restify::OtherActions';

=head1 DESCRIPTION

Extends L<Mojolicious::Plugin::Restify> allowing to call other methods over REST collection

=encoding UTF-8

=head1 USAGE

When you create your controller (see L<Mojolicious::Plugin::Restify> documentation),
you can use, as an example, this list method

  sub list {
    my $c		= shift;
    my $query =  $c->stash('query');
    return $c->$query if ($query);
    ...your original list code ...
  }

to redirect your call to an alternative C<$query> method.

As an example, if your endpoint is C</accounts> then C</accounts/list/my_method/other/parameters>
is redirect to C<< $c->my_method >> and remaining url is available in C<< $c->stash->('opt') >>.

In addition to standard routes added by L<Mojolicious::Plugin::Restify>, a new route is added

    # Pattern             Methods   Name                        Class::Method Name
    # -------             -------   ----                        ------------------
    # ....
    # +/list/:query/*opt  GET       accounts_otheractions       Accounts::list

=head1 Notes about Mojolicious::Plugin::Restify

This module extends L<Mojolicious::Plugin::Restify> but solves also a little bug in route naming.

In L<Mojolicious::Plugin::Restify> /accounts and /accounts/:accounts_id have the same name (accounts).

This module replace the second route appending "_id" so that in original module where there is

  # Pattern           Methods   Name                        Class::Method Name
  # -------           -------   ----                        ------------------
  # ...
  #   +/:accounts_id  *         "accounts"

here there is

  #   +/:accounts_id  *         "accounts_id".

There is a pull request in github repository for this little problem

L<https://github.com/kwakwaversal/mojolicious-plugin-restify/pull/19>

=head1 BUGS/CONTRIBUTING

Please report any bugs through the web interface at L<https://github.com/EmilianoBruni/Mojolicious-Plugin-Restify-OtherActions/issues>
If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from
L<https://github.com/EmilianoBruni/Mojolicious-Plugin-Restify-OtherActions/>.

=head1 SUPPORT

You can find this documentation with the perldoc command too.

    perldoc Mojolicious::Plugin::Restify::OtherActions

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Mojolicious plug-in which extends Restify with more actions

