package OpusVL::AppKit;


use strict;
use warnings;
use OpusVL::AppKit::Builder;
our $VERSION = '2.29';

my $builder = OpusVL::AppKit::Builder->new( appname => __PACKAGE__, version => $VERSION );
$builder->bootstrap;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit

=head1 VERSION

version 2.29

=head1 DESCRIPTION

AppKit is based on L<CatalystX::AppBuilder>, and includes some modules for
common tasks. The idea is that you produce a thin AppKit application, and stick
multiple modules together.

We recommend L<Dist::Zilla> to get you started on AppKit. That's because we've
made minting profiles so we don't have to explain how it works.

    $ dzil new -PAppKit MyApp
    $ dzil new -PAppKitX MyApp::AppKitX::NewModularFeature

See L<Dist::Zilla::MintingProfile::AppKit> and L<Dist::Zilla::MintingProfile::AppKitX>.

Whenever you mint a new AppKit application, you'll end up with a common set of files:

F<MyApp.pm>:

    package MyApp;
    use strict;
    use warnings;
    use MyApp::Builder;

    our $VERSION='0.001';
    
    my $builder = MyApp::Builder->new(
        appname => __PACKAGE__,
        version => $VERSION
    );
    
    $builder->bootstrap;

    1;

F<MyApp/Builder.pm>:

(see also L</Builder>)

    package MyApp::Builder;
    use Moose;
    extends 'OpusVL::AppKit::Builder';
    override _build_superclasses => sub 
    {
        return [ 'OpusVL::AppKit' ]
    };

    override _build_config => sub
    {
        my $self   = shift;
        my $config = super();

        $config->{'Controller::Login'} =
        {
            traits => '+OpusVL::AppKit::TraitFor::Controller::Login::NewSessionIdOnLogin',
        };

        $config->{'View::CMS::Page'}->{AUTO_FILTER} = 'html';

        return $config;
    };

F<myapp.conf>:

    name MyApp

    <Model::CMS>
        connect_info dbi:SQLite:t/db/test.db
        connect_info username
        connect_info password
    </Model::CMS>

    <Model::AppKitAuthDB>
        connect_info dbi:SQLite:t/db/test.db
        connect_info username
        connect_info password
    </Model::AppKitAuthDB>

=head1 NAME

OpusVL::AppKit - Catalyst based application

=head1 AppKitX

AppKitX is the namespace we use for the individual modules from which your
application is built. Each of this is almost an entire Catalyst application per
se; except that it doesn't inherit from Catalyst itself, and requires
marshalling by means of a Builder class.

We generally recommend keeping things as separate as possible, so we normally have:

=over

=item An C<AppKitX> distribution for each logical chunk of the site

=item A C<DB> distribution, usually a L<DBIx::Class> distribution that stands
independently of the application itself

=item An C<AppKitX::DB> distribution, which provides the L<Catalyst::Model> for
the aforementioned C<DB> distribution.

=back

For example, once we've created C<MyApp>, we would create
C<MyApp::AppKitX::SomeModule>, C<MyApp::DB>, and C<MyApp::AppKitX::DB>.

There will be many C<MyApp::AppKitX::SomeModule> style distributions; and
possibly some C<MyCompany::AppKitX::SomeModule> distributions, for common
modules.

=head1 Builder

The builder is provided as a skeleton, but this is where you decide which
modules get loaded. To do so, you override a method in C<MyApp/Builder.pm>.

    override _build_plugins => sub {
        my $plugins = super();
        return [ @$plugins, qw/
            MyApp::AppKitX::Plugin1
            MyApp::AppKitX::Plugin2
        / ];
    }

This is all that's required to connect those plugins together - an app with a
builder with this method, listing them.

=head1 SEE ALSO

=over

=item L<OpusVL::AppKit::Plugin::AppKit>

=item L<OpusVL::AppKit::Base::Controller::GUI>

=item L<OpusVL::AppKit::Controller::Root>

=item L<Catalyst>

=back

=head1 SUPPORT

Support can be garnered by use of the GitHub issue tracker at
L<https://github.com/OpusVL/OpusVL-AppKit/issues>

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
