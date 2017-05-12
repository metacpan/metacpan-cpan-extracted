package SomeLib;

our @Plugins = qw[ funky fresh ];

sub new {bless{},shift}

sub factory {
    my $package = shift;
    my $driver  = shift;
    $package->new({ driver => $driver, @_ })
};

sub AUTOLOAD {
    my $self = shift;
    die "I can't help you with $AUTOLOAD, sorry"
        unless  grep $AUTOLOAD =~ /$_$/, qw[ 
            frobulate  init  configure 
            configuration_for_plugin  DESTROY
            ];
}

=pod

check out C< exmaple/somelib-example > to see how to render more than one 
set of commands with C<ExampleRunner>

This is SomeLib v1.09, we have 2 sets of scripts in this distribution,
we have some utility scripts in C< bin/ > that will be installed globally on the system (these are run/included by =helper)
and we have some additional scripts in C< example/ > (which are included with =example)

this is the script that we would expand this pod with: (the =outside command is here so we can include it too):

=outside source somelib-examples

Once we've seen this script, it's easy to see how the following 2 sets of scripts can be used in the pod for C<SomeLib>

=head2 helper scripts

when creating a new C< SomeLib > application, you can use the helper script to get you started, you'll see a message something like this:

=helper run somelib-util.pl

Once you've got your framework created, you can start on L< SomeApp::Manual >

=head2 Examples

C<SomeLib> also ships with several example scripts, they can be found in the tarball along with this module.

You will want to start with the interactive tutorial, found in C<example/somelib-for-learing.pl>, which looks like this:

=example run somelib-for-learing.pl

=cut

"smells like victory"

