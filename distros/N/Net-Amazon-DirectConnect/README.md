# Net-Amazon-DirectConnect

This is a simple Perl interface to the Amazon Direct Connect API.

## Usage

```perl
use Net::Amazon::DirectConnect;

my $dc = Net::Amazon::DirectConnect->new;
# List connections
my $connections = $dc->action('DescribeConnections');

foreach my $dxcon (@{$connections->{connections}}) {
    say "$dxcon->{connectionId} -> $dxcon->{connectionName}";

    # List Virtual Interfaces
    my $virtual_interfaces = $dc->action('DescribeVirtualInterfaces', connectionId => $dxcon->{connectionId});
    foreach my $vif (@{$virtual_interfaces->{virtualInterfaces}}) {
        say "  $vif->{connectionId}";
    }
}
```

## TODO

* Better documentation
* More tests
* Package for CPAN

## INSTALLATION

To install this module, run the following commands:

```bash
perl Build.PL
./Build
./Build test
./Build install
```

## SUPPORT AND DOCUMENTATION

After installing, you *might be able to* find documentation for this module with the
perldoc command.

```bash
perldoc Net::Amazon::DirectConnect
```
