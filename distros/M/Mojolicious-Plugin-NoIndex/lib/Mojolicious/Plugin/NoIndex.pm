package Mojolicious::Plugin::NoIndex;

# ABSTRACT: add meta tag to HTML output to define a policy for robots

use Mojo::Base 'Mojolicious::Plugin';

use Carp qw(croak);

our $VERSION = '0.02';

my %routes;
my %routes_special;


sub register {
    my ($self, $app, $config) = @_;

    if ( !$config || !%{$config} ) {
        $config = { all_routes => 1 };
    }

    my $default_value = $config->{default} // 'noindex';

    %routes         = ();
    %routes_special = ();

    ROUTENAME:
    for my $route_name ( keys %{ $config->{routes} || {} } ) {
        my $value = $config->{routes}->{$route_name};
        $value    = $default_value if $value eq '1';

        if ( $route_name =~ m{\A(.*?)\#\#\#(.*)}xms ) {
            my %conditions = map{ my ($param, $regex) = split /=/, $_; $param => qr/\A(?:$regex)\z/  } split /\&/, $2 // '';
            push @{ $routes_special{$1}->{conditions} }, \%conditions;
            $routes_special{$1}->{value} = $value;
            
            next ROUTENAME;
        }

        $routes{$route_name} = $value;
    }

    for my $value ( keys %{ $config->{by_value} || {} } ) {

        ROUTE:
        for my $route_name ( @{ $config->{by_value}->{$value} || [] } ) {
            if ( $route_name =~ m{\A(.*?)\#\#\#(.*)}xms ) {
                my %conditions = map{ my ($param, $regex) = split /=/, $_; $param => qr/\A(?:$regex)\z/  } split /\&/, $2 // '';
                push @{ $routes_special{$1}->{conditions} }, \%conditions;
                $routes_special{$1}->{value} = $value;
                
                next ROUTE;
            }

            $routes{$route_name} = $value;
        }
    }

    $app->hook(
        after_render => sub {
            my ($c, $content, $format) = @_;

            return if !$format;
            return if $format ne 'html';

            my $route = $c->current_route;
            my $value;

            if ( $routes{$route} ) {
                $value = $routes{$route} // $default_value;
            }

            if ( $routes_special{$route} ) {
                my $matched;

                CONDITION:
                for my $conditions ( @{ $routes_special{$route}->{conditions} || [] } ) {
                    for my $param ( keys %{ $conditions || {} } ) {
                        if ( $c->param( $param ) !~ $conditions->{$param} ) {
                            next CONDITION;
                        }
                    }

                    $value = $routes_special{$route}->{value} // $default_value;
                    last CONDITION;
                }
            }

            if ( $config->{all_routes} && !$value ) {
                $value = $default_value;
            }

            return if !$value;

            $$content =~ s{<meta [^>]+ name="robots" [^>]+ >}{}x;
            $$content =~ s{<head>\K}{<meta name="robots" content="$value">};
        }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::NoIndex - add meta tag to HTML output to define a policy for robots

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('NoIndex');

  # Mojolicious::Lite
  plugin 'NoIndex';

  # to allow sending referrer information to the origin
  plugin 'NoIndex' => { content => 'same-origin' };

=head1 DESCRIPTION

L<Mojolicious::Plugin::NoIndex> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::NoIndex> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head2 HOOKS INSTALLED

This plugin adds one C<after_render> hook to add the <meta> tag.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
