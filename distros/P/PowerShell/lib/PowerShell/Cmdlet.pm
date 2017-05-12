use strict;
use warnings;

package PowerShell::Cmdlet;
$PowerShell::Cmdlet::VERSION = '1.00';
# ABSTRACT: Wraps a generic cmdlet
# PODNAME: PowerShell::Cmdlet

sub new {
    return bless( {}, shift )->_init(@_);
}

sub command {
    my ($self) = @_;

    unless ( $self->{command} ) {
        my @parts = ( $self->{name} );
        foreach my $parameter ( @{ $self->{parameters} } ) {
            if ( scalar(@$parameter) == 2 ) {
                push( @parts, "-$parameter->[0] '$parameter->[1]'" );
            }
            else {
                push( @parts, "'$parameter->[0]'" );
            }
        }
        $self->{command} = join( ' ', @parts );
    }

    return $self->{command};
}

sub _init {
    my ( $self, $name ) = @_;

    $self->{name}       = $name;
    $self->{parameters} = [];

    return $self;
}

sub parameter {
    my ( $self, @parameter ) = @_;

    my $parts = scalar(@parameter);
    if ( $parts == 1 ) {
        push( @{ $self->{parameters} }, [ $parameter[0] ] );
    }
    elsif ( $parts == 2 ) {
        push( @{ $self->{parameters} }, [ $parameter[0] => $parameter[1] ] );
    }

    return $self;
}

1;

__END__

=pod

=head1 NAME

PowerShell::Cmdlet - Wraps a generic cmdlet

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    use PowerShell::Cmdlet;

    # Minimally
    my $command = PowerShell::Cmdlet->new('Mount-DiskImage') 
        ->parameter('Image', 'C:\\tmp\\foo.iso')
        ->parameter('StorageType', 'ISO');

    # Then add it to a pipeline
    $pipeline->add($command);

    # Or pipe a powershell pipeline to it
    $powershell->pipe_to($command);

    # Or just print it out
    print('running [', $command->command(), "]\n");

=head1 DESCRIPTION

Represents a generic cmdlet.  Can be used as is for most situations, or can be
extended to provide a cmdlet specific interface.

=head1 CONSTRUCTORS

=head2 new($name)

Creates a new cmdlet for C<$name>.

=head1 METHODS

=head2 command()

Returns a string form of the command.

=head2 parameter([$name], $value)

Adds a parameter to the cmdlet.  If name is supplied, it will be a named 
parameter.  For example:

    PowerShell::Cmdlet('Mount-DiskImage')
        ->parameter('Image' => 'C:\\tmp\\foo.iso');

would result in:

    Mount-DiskImage -Image 'C:\tmp\foo.iso'

If C<$name> is not supplied, the value will be added by itself:

    PowerShell::Cmdlet('Get-Volume')
        ->parameter('E');

would result in:

    Get-Volume 'E'

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<PowerShell|PowerShell>

=item *

L<PowerShell|PowerShell>

=item *

L<PowerShell::Pipeline|PowerShell::Pipeline>

=item *

L<https://msdn.microsoft.com/en-us/powershell/scripting/powershell-scripting|https://msdn.microsoft.com/en-us/powershell/scripting/powershell-scripting>

=back

=cut
