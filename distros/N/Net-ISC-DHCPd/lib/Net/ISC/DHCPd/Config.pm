package Net::ISC::DHCPd::Config;

=head1 NAME

Net::ISC::DHCPd::Config - Parse and create ISC DHCPd config

=head1 SYNOPSIS

    use Net::ISC::DHCPd::Config;

    my $config = Net::ISC::DHCPd::Config->new(
                     file => '/etc/dhcpd3/dhcpd.conf',
                 );

    # parse the config
    $config->parse;

    # parsing includes are lazy
    for my $include ($config->includes) {
        $include->parse;
    }

    print $config->includes->[0]->hosts->[0]->dump;

    $config->add_host({
        name => 'foo',
        filenames => [{ file => 'pxelinux.0' }],
    });

    if($config->find_hosts({ name => 'foo' })) {
        say "Found host by name='foo'";
    }
    if($config->remove_includes({ file => 'some/file' })) {
        say "Removed included file by file='some/file'";
    }

    print $config->generate;

=head1 DESCRIPTION

An object constructed from this class represents the config for a
given dhcpd server. The L<config file|/file> passed on to the construted
can either be read or written to. As shown in the L</SYNOPSIS>, the
object has the method C<parse>, which will read the config (line by line)
and create the appropriate objects representing each part of the config.
The result is an object L<graph|http://en.wikipedia.org/wiki/Graph_theory>
where the objects has pointer back to the L</parent> and any number of
children of different types. (Ex: L</hosts>, L</subnets>, ...)

It is also possible to start from scratch with an empty object, and
use any of the C<add_foo> methods to create the object graph. After
creating/modifying the graph, the actual config text can be retrieved
using L</generate>.

This class does the role L<Net::ISC::DHCPd::Config::Root>.

=head1 POSSIBLE CONFIG GRAPH

 Config
  |- Config::Authoritative
  |- Config::Class
  |- Config::SubClass
  |- Config::Include
  |- Config::Conditional
  |- Config::FailoverPeer
  |- Config::Subnet
  |  |- Config::Option
  |  |- Config::Declaration
  |  |- Config::Range
  |  |- Config::Host
  |  |  |- ...
  |  |- Config::Filename
  |  '- Config::Pool
  |     |- Option
  |     |- Range
  |     '- KeyValue
  |
  |- Config::SharedNetwork
  |  |- Config::Subnet
  |  |  |- ...
  |  |- Config::Declaration
  |  '- Config::KeyValue
  |
  |- Config::Group
  |  |- Config::Host
  |  |  |- ...
  |  |- Config::Option
  |  |- Config::Declaration
  |  '- Config::KeyValue
  |
  |- Config::Host
  |  |- Config::Option
  |  |- Config::Filename
  |  |- Config::Declaration
  |  '- Config::KeyValue
  |
  |- Config::OptionSpace
  |- Config::OptionCode
  |
  |- Config::Option
  |- Config::Declaration *
  |- Config::Function
  |- Config::KeyValue
  '- Config::Single      *

=cut

use Moose;

with 'Net::ISC::DHCPd::Config::Root';

# need to put this somewhere everyone has access to it and we don't need to
# "use N:I:D:Config;"
sub children {
    return qw/
        Net::ISC::DHCPd::Config::Host
        Net::ISC::DHCPd::Config::Class
        Net::ISC::DHCPd::Config::Conditional
        Net::ISC::DHCPd::Config::SubClass
        Net::ISC::DHCPd::Config::Subnet
        Net::ISC::DHCPd::Config::Subnet6
        Net::ISC::DHCPd::Config::Include
        Net::ISC::DHCPd::Config::SharedNetwork
        Net::ISC::DHCPd::Config::Function
        Net::ISC::DHCPd::Config::OptionSpace
        Net::ISC::DHCPd::Config::OptionCode
        Net::ISC::DHCPd::Config::Option
        Net::ISC::DHCPd::Config::Key
        Net::ISC::DHCPd::Config::Group
        Net::ISC::DHCPd::Config::Zone
        Net::ISC::DHCPd::Config::FailoverPeer
        Net::ISC::DHCPd::Config::Authoritative
        Net::ISC::DHCPd::Config::Block
        Net::ISC::DHCPd::Config::KeyValue/;
}

__PACKAGE__->create_children(__PACKAGE__->children());

sub _build_root { $_[0] }

=head2 regex

See L<Net::ISC::DHCPd::Config::Role/regex>.

=cut

sub regex { qr{\x00} } # should not be used

__PACKAGE__->meta->add_method(filehandle => sub {
    Carp::cluck('->filehandle is replaced with private attribute _filehandle');
    shift->_filehandle;
});

=head1 ATTRIBUTES

=head2 file

See L<Net::ISC::DHCPd::Config::Root/file>.

=head2 parent

See L<Net::ISC::DHCPd::Config::Role/parent>.

=head2 root

See L<Net::ISC::DHCPd::Config::Role/root>.

=head2 parent

This attribute is different from L<Net::ISC::DHCPd::Config::Role/parent>:
It holds an undefined value, which is used to indicate that this object
is the top node in the tree. See L<Net::ISC::DHCPd::Config::Include>
if you want a different behavior.

=cut

has parent => (
    is => 'ro',
    isa => 'Undef',
    default => sub { undef },
);

=head2 children

See L<Net::ISC::DHCPd::Config::Role/children>.

=head2 hosts

List of parsed L<Net::ISC::DHCPd::Config::Host> objects.
See L<Net::ISC::DHCPd::Config::Role/children> for details on how to
add, update or remove these objects.

=head2 subnets

List of parsed L<Net::ISC::DHCPd::Config::Subnet> objects.
See L<Net::ISC::DHCPd::Config::Role/children> for details on how to
add, update or remove these objects.

=head2 sharednetworks

List of parsed L<Net::ISC::DHCPd::Config::SharedNetwork> objects.
See L<Net::ISC::DHCPd::Config::Role/children> for details on how to
add, update or remove these objects.

=head2 functions

List of parsed L<Net::ISC::DHCPd::Config::Function> objects.
See L<Net::ISC::DHCPd::Config::Role/children> for details on how to
add, update or remove these objects.

=head2 optionspaces

List of parsed L<Net::ISC::DHCPd::Config::OptionSpace> objects.
See L<Net::ISC::DHCPd::Config::Role/children> for details on how to
add, update or remove these objects.

=head2 options

List of parsed L<Net::ISC::DHCPd::Config::Option> objects.
See L<Net::ISC::DHCPd::Config::Role/children> for details on how to
add, update or remove these objects.

=head2 includes

List of parsed L<Net::ISC::DHCPd::Config::Include> objects.
See L<Net::ISC::DHCPd::Config::Role/children> for details on how to
add, update or remove these objects.

=head2 classes

List of parsed L<Net::ISC::DHCPd::Config::Class> objects.
See L<Net::ISC::DHCPd::Config::Role/children> for details on how to
add, update or remove these objects.

=head2 subclasses

List of parsed L<Net::ISC::DHCPd::Config::SubClass> objects.
See L<Net::ISC::DHCPd::Config::Role/children> for details on how to
add, update or remove these objects.

=head2 keyvalues

List of parsed L<Net::ISC::DHCPd::Config::KeyValue> objects.
See L<Net::ISC::DHCPd::Config::Role/children> for details on how to
add, update or remove these objects.

=head1 METHODS

=head2 parse

See L<Net::ISC::DHCPd::Config::Role/parse>.

=head2 generate

See L<Net::ISC::DHCPd::Config::Root/generate>.

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
